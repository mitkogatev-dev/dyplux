#!/usr/bin/perl -w
#
use DBI;
use strict;
use warnings;
 
use Net::SNMP qw(:snmp);
use Data::Dumper qw( Dumper );
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
my $dir=$RealBin;

#Config
my $collector_id=1;
#
my ($config_file)="$dir/config.cfg" || "";
my $current_file = "$dir/current_results.tmp";
my $prev_file = "$dir/prev_results.tmp";
my $insert_file="$dir/results.txt";
my $alerts_file="$dir/alerts.txt";
my %cfg=(
   max_threads => 1,
   alert_on_port_down_only => 1,
   influx_binary => "/usr/sbin/influx",
   influx_bucket => "traffic",
   influx_url => "http://127.0.0.1:8086",
   influx_token => "AlAbala==",
   influx_org => "myorg",
   sql_host => "127.0.0.1",
   sql_port => "3306",
   sql_user => "myuser",
   sql_pass => "fakepassword",
   sql_db => "graphs"
);
#
if (open my $cfg_file, "< $config_file") {
    while (my $line = <$cfg_file>) {
        if ($line =~ /(\w+)[ \t]*=[ \t]*(.*)/) {
            $cfg{$1} = $2;
        }
    }
    close $cfg_file;
}
###

#Queries
my $qcollector_ping="UPDATE collectors SET active_host=(select host from information_schema.processlist WHERE ID=connection_id()),interval_seconds=IFNULL(TIMESTAMPDIFF(SECOND,last_run,NOW()),0), last_run=NOW() WHERE collector_id=?";
my $qcollector_config="SELECT collector_name,enabled,disable_alerts FROM collectors WHERE collector_id=?;";
my $qdev="SELECT `device_id`,`ip`,`community` FROM `devices` WHERE collector_id=?";
my $qports="SELECT `port_id`,`ifindex` FROM `ports` WHERE device_id=?";
my $qthresh="SELECT p.port_id,t.min_in,t.max_in,t.min_out,t.max_out FROM `ports` p JOIN thresholds t ON p.port_id=t.port_id WHERE p.device_id=?";
my $qtrunc="TRUNCATE TABLE alerts_tmp;";
my $qdisable_alert="UPDATE alerts a 
LEFT JOIN alerts_tmp t ON (a.port_id=t.port_id AND a.device_id = t.device_id AND a.alert_type_id=t.alert_type_id)
SET a.active=0 
WHERE a.active AND (t.port_id IS NULL or t.device_id IS NULL);";
my $qrise_alert="INSERT INTO `alerts`(`alert_type_id`,`device_id`, `port_id`) 
SELECT t.`alert_type_id`,t.`device_id`, t.`port_id` FROM alerts_tmp t 
LEFT JOIN alerts a ON (a.port_id=t.port_id AND a.device_id = t.device_id AND a.alert_type_id=t.alert_type_id AND a.active) 
WHERE (a.port_id IS NULL OR a.device_id IS NULL);";
#
#oids
my $in_oid="1.3.6.1.2.1.31.1.1.1.6";
my $out_oid="1.3.6.1.2.1.31.1.1.1.10";
my $sys_oid="1.3.6.1.2.1.1.1";
my $oper_oid="1.3.6.1.2.1.2.2.1.8";                                                                                                                                   
my $admin_oid="1.3.6.1.2.1.2.2.1.7";

#Create fh
open (my $current_fh,">", $current_file) or die $!;
open (my $insert_fh,">", $insert_file) or die $!;
open (my $alerts_fh,">", $alerts_file) or die $!;
#

#Create devices hash
my $dbh=init_db();
my $db_vars=$dbh->selectall_arrayref($qcollector_config,{Slice=>{}},$collector_id );
die "Undefined collector!\n" if !@$db_vars[0];

my $sth_alive=$dbh->prepare($qcollector_ping);

$sth_alive->execute($collector_id);
my $collector=( @{ $db_vars })[0];
die "This collector is disabled\n" if !$collector->{enabled};

my $devices=$dbh->selectall_arrayref($qdev,{Slice=>{}},$collector_id ); 
#
foreach my $device ( @{ $devices }) {
$device->{ports}=$dbh->selectall_arrayref($qports,{Slice=>{}},$device->{device_id} );
$device->{thresholds}=$dbh->selectall_arrayref($qthresh,{Slice=>{}},$device->{device_id} );
}
$dbh->disconnect();
##

#Threads block(fork)
#some debug optimisation
#https://www.perl.com/article/fork-yeah-/
#
my $threads_count=0;
foreach my $device ( @{ $devices }) {
   $threads_count++;
   wait unless $threads_count <= $cfg{max_threads};
   my $pid;
   next if $pid = fork;    # Parent goes to next server.
   die "fork failed: $!" unless defined $pid; 
   collect($device); #execute this inside fork
   exit;
}

my $child;
do {
  $child = waitpid -1, 0;
#   print $child ."\n";
} while ($child > 0);
#####

close $current_fh;
#* traffic has been exported so current data at this point is old data
my $cp=qx(cp $current_file $prev_file);
close $insert_fh;
close $alerts_fh;
#
&save_data();
#ALL DONE!
exit;

sub init_db{
   return DBI->connect("DBI:mysql:$cfg{sql_db}:$cfg{sql_host}:$cfg{sql_port}", $cfg{sql_user}, $cfg{sql_pass},{ RaiseError => 1, AutoCommit => 1 });
}
sub save_data{
   #save to Influx
   # ***********
   my $save=qx($cfg{influx_binary} write -b $cfg{influx_bucket} -f $insert_file --host $cfg{influx_url} -t $cfg{influx_token} -o $cfg{influx_org});
   #reconnect sql
   $dbh=init_db();
   #empty tmp
   my $sth_trunc=$dbh->prepare($qtrunc);
   $sth_trunc->execute();
   #insert new tmp
   my $sqlsave=qx(mysql --skip-ssl=1 -h$cfg{sql_host} -u$cfg{sql_user} -p$cfg{sql_pass} -P$cfg{sql_port} --local-infile=1 -e "LOAD DATA LOCAL INFILE '$alerts_file' INTO TABLE $cfg{sql_db}.alerts_tmp FIELDS TERMINATED BY ',' (alert_id,alert_type_id,device_id,port_id)");
   #update alerts
   my $sth_disable=$dbh->prepare($qdisable_alert);
   my $sth_rise=$dbh->prepare($qrise_alert);
   $sth_disable->execute();
   $sth_rise->execute();
   $dbh->disconnect;
}
#collect data
sub collect{
   my ($device)=shift;
   #* no ports no session
   if (scalar @{$device->{ports}} == 0){return;}
   my $device_has_thresholds=0;
   if( scalar @{$device->{thresholds}} > 0) {
      $device_has_thresholds=1;
   }

   #* define session
   my ($session, $error) = Net::SNMP->session(
      -hostname    => $device->{ip} || 'localhost',
      -community   => $device->{community} || 'public',
      -version     => 'snmpv2c',
      -timeout     => 1,
   );
    if (!defined $session) { printf "ERROR: %s.\n", $error; exit 1;}
   #check if session is alive
   my $ping=$session->get_table($sys_oid);
   #
   my $currts=time(); #get current run timestamp
   my $greptime="grep ^$device->{device_id}--ts= $prev_file";
   #get prev timestamp
   my $prevts=0;
   $prevts=(split('=',qx($greptime)))[1] || 0 if -e $prev_file;
   #calculate time diff
   my $time=$currts-eval($prevts);
   #
   print $current_fh "$device->{device_id}--ts=$currts\n";
   #
   if(!$ping){
      &output_empty($device);
      exit;
   }
   foreach my $port ( @{ $device->{ports} }) {
      my $device_id=$device->{device_id};
      my $port_id=$port->{port_id};
      my ($in_val,$out_val,$admin_val,$oper_val) = (get_current_vals($port,$session));#todo
      my ($prev_port,$prev_in,$prev_out,$prev_admin,$prev_oper)=get_prev_vals($port_id);#todo
      next if (!$prev_port || -1 eq $prev_port);
      #* if prev data found we can calculate current traffic
      my $traffic_in=((($in_val-$prev_in)*8)/$time);                                                                                                                                            
      my $traffic_out=((($out_val-$prev_out)*8)/$time);
      #set default traffic to 0 if this is first run
      if($prev_in eq -1 || $prev_out eq -1 || $in_val eq -1 || $out_val eq -1){
         $traffic_in=0;
         $traffic_out=0;
      } 

      #* export data
      print $insert_fh "interfaceTraffic,device_id=$device_id,port_id=$port_id intraffic=$traffic_in,outtraffic=$traffic_out\n";
      #oper
      &oper_check($device_id,$port_id,$admin_val,$oper_val,$prev_admin,$prev_oper) if !$collector->{disable_alerts};
      #thresholds 
      &threshold_check($device,$port_id,$traffic_in,$traffic_out) if ($device_has_thresholds && !$collector->{disable_alerts});
   }
}
sub oper_check{
   my $port_id=shift;
   my $device_id=shift;
   my $admin_val=shift;
   my $oper_val=shift;
   my $prev_admin=shift;
   my $prev_oper=shift;
   if($admin_val ne -1 || $oper_val ne -1 || $prev_admin ne -1 || $prev_oper ne -1){
         #rises alert on port change and disables it on second run
         #
         if($cfg{alert_on_port_down_only}){
            #rise alert if port is down, and disabe it on UP
            if($admin_val > 1){
               print $alerts_fh "null,2,$device_id,$port_id\n";
            }
            elsif($oper_val > 1){
               print $alerts_fh "null,1,$device_id,$port_id\n";
            }
         }
         else
         {
            my $oper_diff=(eval($oper_val-$prev_oper));
            my $admin_diff=(eval($admin_val-$prev_admin));
            #rise alert on every port change and disable it immediately
            if($admin_diff !=0){
               print $alerts_fh "null,2,$device_id,$port_id\n";
            }
            elsif($oper_diff !=0){
               print $alerts_fh "null,1,$device_id,$port_id\n";
            }
         }
      }
}
sub output_empty{
   my $device=shift;
   foreach my $port ( @{ $device->{ports} }) {
      print $insert_fh "interfaceTraffic,device_id=$device->{device_id},port_id=$port->{port_id} intraffic=0,outtraffic=0\n";
   }
   #rise alert
   print $alerts_fh "null,5,$device->{device_id},0\n";
}
sub get_current_vals{
   my $port=shift;
   my $session=shift;

   my $ifindex=$port->{ifindex};
   my $in_req="$in_oid.$ifindex";
   my $out_req="$out_oid.$ifindex";
   my $oper_req="$oper_oid.$ifindex";
   my $admin_req="$admin_oid.$ifindex";

   #get current vals
   my $result=$session->get_request($in_req,$out_req,$admin_req,$oper_req);
   my $in_val=$result->{$in_req} // "-1";
   my $out_val=$result->{$out_req} // "-1";
   my $admin_val=$result->{$admin_req} // "-1";
   my $oper_val=$result->{$oper_req} // "-1";
   # #
   #* save current vals to fh
   print $current_fh "port_id=$port->{port_id},$in_val,$out_val,$admin_val,$oper_val\n";
   #
   return $in_val,$out_val,$admin_val,$oper_val;
}
sub get_prev_vals{
   my $port_id=shift;
   
   # get prev data by port_id
   my $grep="grep port_id=$port_id, $prev_file"; 
   my ($prev_port,$prev_in,$prev_out,$prev_admin,$prev_oper)=split(',',qx($grep)) if -e $prev_file;
   $prev_port= "-1" if !$prev_port;
   $prev_in = "-1" if !$prev_in;
   $prev_out = "-1" if !$prev_out;
   $prev_admin = "-1" if !$prev_admin;
   $prev_oper = "-1" if !$prev_oper;
   return $prev_port,$prev_in,$prev_out,$prev_admin,$prev_oper;
}
sub threshold_check{
   my $device=shift;
   my $port_id=shift;
   my $traffic_in=shift;
   my $traffic_out=shift;
   # 
   my ($port_thresh) = grep { $port_id == $_->{port_id} } @{$device->{thresholds}};
   return if !$port_thresh;
   my $device_id=$device->{device_id};
   my $min_in=eval($port_thresh->{min_in} +0) // -1;
   my $max_in=eval($port_thresh->{max_in} +0) // -1;
   my $min_out=eval($port_thresh->{min_out} +0) // -1;
   my $max_out=eval($port_thresh->{max_out} +0) // -1;
   #alert_type_id,port_id
   #alrt_type_ids: 1-oper changed, 2-admin changed, 3-min thresh, 4-max thresh
   if ($min_in > -1 && $traffic_in < $min_in){
      print $alerts_fh "null,3,$device_id,$port_id\n";
   }
   elsif ($max_in > -1 && $traffic_in > $max_in){
      print $alerts_fh "null,4,$device_id,$port_id\n";
   }
   elsif ($min_out > -1 && $traffic_out < $min_out){
      print $alerts_fh "null,3,$device_id,$port_id\n";
   }
   elsif ($max_out > -1 && $traffic_out > $max_out){
      print $alerts_fh "null,4,$device_id,$port_id\n";
   }
}

exit;

