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
#***************************
#V#1. SElect from db group by ports device 
#V#2. foreach device get_ports data in one session;
#?-#using fork for n devices at once#3. multisession spawn for fast get
#X#4. Decide use tmp file for last results or save them directly in db port->field last_vals;
#==
#******************************
#
my ($config_file)="$dir/config.cfg" || "";
my $current_file = "$dir/current_results.tmp";
my $prev_file = "$dir/prev_results.tmp";
my $insert_file="$dir/results.txt";
my $alerts_file="$dir/alerts.txt";
# my $time=60;
my %cfg=(
   max_threads => 4,
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


# my $dbh = DBI->connect("DBI:mysql:$cfg{sql_db}:$cfg{sql_host}:$cfg{sql_port}", $cfg{sql_user}, $cfg{sql_pass},                                                                                                                                                                                
# { RaiseError => 1, AutoCommit => 1 });   
my $dbh=init_db();
#get defined ports from db
my $qdev="SELECT `device_id`,`ip`,`community` FROM `devices` WHERE 1";
my $devices=$dbh->selectall_arrayref($qdev,{Slice=>{}} ); 
my $qports="SELECT `port_id`,`ifindex` FROM `ports` WHERE device_id=?";
# my $qports="SELECT p.`port_id`,p.`ifindex`,t.min_in,t.max_in,t.min_out,t.max_out FROM `ports` p LEFT JOIN thresholds t ON p.port_id=t.port_id WHERE p.device_id=?";
my $qthresh="SELECT p.port_id,t.min_in,t.max_in,t.min_out,t.max_out FROM `ports` p JOIN thresholds t ON p.port_id=t.port_id WHERE p.device_id=?";
my $qtrunc="TRUNCATE TABLE alerts_tmp;";
my $qdisable_alert="UPDATE alerts a 
LEFT JOIN alerts_tmp t ON (a.port_id=t.port_id AND a.alert_type_id=t.alert_type_id)
SET a.active=0 
WHERE a.active AND t.port_id IS NULL;";
my $qrise_alert="INSERT INTO `alerts`(`alert_type_id`, `port_id`) SELECT t.`alert_type_id`, t.`port_id` FROM alerts_tmp t LEFT JOIN alerts a ON (a.port_id=t.port_id AND a.alert_type_id=t.alert_type_id AND a.active) WHERE a.port_id IS NULL;";
foreach my $device ( @{ $devices }) {
$device->{ports}=$dbh->selectall_arrayref($qports,{Slice=>{}},$device->{device_id} );
$device->{thresholds}=$dbh->selectall_arrayref($qthresh,{Slice=>{}},$device->{device_id} );
}
$dbh->disconnect();

# print Dumper($devices);
#open current file to store data
open (my $current_fh,">", $current_file) or die $!;
open (my $insert_fh,">", $insert_file) or die $!;
# ** if not using thresholds this is not needed
open (my $alerts_fh,">", $alerts_file) or die $!;

#Threads block(fork)
#some debug optimisation
#https://www.perl.com/article/fork-yeah-/
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
#save to DB
# ***********
# *** !!! DISABLED FOR TEST
my $save=qx($cfg{influx_binary} write -b $cfg{influx_bucket} -f $insert_file --host $cfg{influx_url} -t $cfg{influx_token} -o $cfg{influx_org});
# ** TODO: insert alerts(thresholds)
#reconnect
$dbh=init_db();
#empty tmp
my $sth_trunc=$dbh->prepare($qtrunc);
$sth_trunc->execute();
#insert new tmp
my $sqlsave=qx(mysql --skip-ssl=1 -h$cfg{sql_host} -u$cfg{sql_user} -p$cfg{sql_pass} -P$cfg{sql_port} --local-infile=1 -e "LOAD DATA LOCAL INFILE '$alerts_file' INTO TABLE $cfg{sql_db}.alerts_tmp FIELDS TERMINATED BY ',' (alert_id,alert_type_id,port_id)");
#
my $sth_disable=$dbh->prepare($qdisable_alert);
my $sth_rise=$dbh->prepare($qrise_alert);
$sth_disable->execute();
$sth_rise->execute();
$dbh->disconnect;

exit;

sub init_db{
   return DBI->connect("DBI:mysql:$cfg{sql_db}:$cfg{sql_host}:$cfg{sql_port}", $cfg{sql_user}, $cfg{sql_pass},                                                                                                                                                                                
{ RaiseError => 1, AutoCommit => 1 });
}
#collect data
sub collect{
my ($device)=shift;

#* no ports no session
if (scalar @{$device->{ports}} == 0){return;}

my $in_oid="1.3.6.1.2.1.31.1.1.1.6";
my $out_oid="1.3.6.1.2.1.31.1.1.1.10";
my $sys_oid="1.3.6.1.2.1.1.1";

#* open sesson to device
my ($session, $error) = Net::SNMP->session(
   -hostname    => $device->{ip} || 'localhost',
   -community   => $device->{community} || 'public',
   -version     => 'snmpv2c',
   -timeout     => 1,
);
 if (!defined $session) {
   printf "ERROR: %s.\n", $error;
   exit 1;
}
#check if session is alive
#todo: can rise alert device is offline here
my $ping=$session->get_table($sys_oid) || die $session->error ;

##calculates per device time diff
my $currts=time(); #get current run timestamp
my $greptime="grep ^$device->{device_id}--ts= $prev_file";
my ($prevts)=(split('=',qx($greptime)))[1] || 0;
# print "prev=$prevts\n";
# my $time=$prevts+0-$currts;
my $time=$currts-eval($prevts);
# print "diff=$time\n\n";
print $current_fh "$device->{device_id}--ts=$currts\n";

foreach my $port ( @{ $device->{ports} }) {
my $ifindex=$port->{ifindex};
my $in_req="$in_oid.$ifindex";
my $out_req="$out_oid.$ifindex";

my $result=$session->get_request($in_req,$out_req);
#* parse results
my $in_val=$result->{$in_req} || 0;
my $out_val=$result->{$out_req} || 0;
#? move to separate sub calculate()??

#* get prev data by port_id
my $grep="grep port_id=$port->{port_id}, $prev_file"; #throws err firtst run as file doesn't exists
#* assign vals
my ($port_id,$prev_in,$prev_out)=split(',',qx($grep));
$prev_in = 0 if !$prev_in;
$prev_out = 0 if !$prev_out;
#* save to fh
print $current_fh "port_id=$port->{port_id},$in_val,$out_val\n";
#
#### calculate time
#

#* if prev data found we can calculate current traffic
if($port_id){
# *** TODO: check for empty values
my $trafficIn=((eval($in_val-$prev_in)*8)/$time);                                                                                                                                            
my $trafficOut=((eval($out_val-$prev_out)*8)/$time); 

#* export data
#? print to STDOUT ? replace with FH?
print $insert_fh "interfaceTraffic,device_id=$device->{device_id},port_id=$port->{port_id} intraffic=$trafficIn,outtraffic=$trafficOut\n";                                                                                                                                        

#** !!!
#can rise alert here
if (scalar @{$device->{thresholds}} > 0){ #if device has thresh
#  my $thresh = ( @{ $device->{thresholds} })->{port_id} == $port_id;
my ($thresh) = grep { $port->{port_id} == $_->{port_id} } @{$device->{thresholds}};
if($thresh){ 
# print "##########\n".$thresh->{max_in}."\n########\n";
threshold_check($thresh,$trafficIn,$trafficOut);

}
}


#threshold_check($port,$trafficIn,$trafficOut);
}

}

$session->close();

}
sub threshold_check{
   my $thresh=shift;
   my $traffic_in=shift;
   my $traffic_out=shift;
   my $min_in=eval($thresh->{min_in} +0) // -1;
   my $max_in=eval($thresh->{max_in} +0) // -1;
   my $min_out=eval($thresh->{min_out} +0) // -1;
   my $max_out=eval($thresh->{max_out} +0) // -1;
   #alert_type_id,port_id
   #alrt_type_ids: 1-oper changed, 2-admin changed, 3-min thresh, 4-max thresh
   if ($min_in > -1 && $traffic_in < $min_in){
      print $alerts_fh "null,3,$thresh->{port_id}\n";
   }
   elsif ($max_in > -1 && $traffic_in > $max_in){
      print $alerts_fh "null,4,$thresh->{port_id}\n";
   }
   elsif ($min_out > -1 && $traffic_out < $min_out){
      print $alerts_fh "null,3,$thresh->{port_id}\n";
   }
   elsif ($max_out > -1 && $traffic_out > $max_out){
      print $alerts_fh "null,4,$thresh->{port_id}\n";
   }
}

exit;

