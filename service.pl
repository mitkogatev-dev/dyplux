#!/usr/bin/perl -w
use strict;
use DBI;
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
my $dir=$RealBin;

package Service;
use Data::Dumper qw( Dumper );
#* import ref to router.cgi %input;
my ($input)=\%main::input;
my $cfg=Cfg::get_config();
my $debug=Cfg::get_debug();

sub init_db(){
my $dbh;

eval {
$dbh = DBI->connect("DBI:mysql:$cfg->{sql_db}:$cfg->{sql_host}:$cfg->{sql_port}", $cfg->{sql_user}, $cfg->{sql_pass},
{ RaiseError => 1, AutoCommit => 1,mysql_enable_utf8mb4 => 1 });
$dbh->do("SET NAMES 'utf8'");
};
if ( $@ ) {
# do something with the error
print $debug "\n$@\n" if $debug;
 return die if $cfg->{debug_cgi};
exit 1;
}
return $dbh;
}

sub get_dashboards{
    my $dbh=init_db();
    my $dashboards;
    if($input->{dashboard_id} && "" ne $input->{dashboard_id}){
        $dashboards=$dbh->selectall_arrayref(Query::get_dashboards($input->{dashboard_id}),{Slice=>{}},$input->{dashboard_id});
    }else{
        $dashboards=$dbh->selectall_arrayref(Query::get_dashboards(),{Slice=>{}});

    } 
    return $dashboards;
}
sub add_dashboard{
    my $dashboard_name=$input->{dashboard_name};
    if(!$dashboard_name || "" eq $dashboard_name){
        return Strings::error();
    }
    my $dbh=init_db();
    my $sth=$dbh->prepare(Query::dashboard());
    $sth->execute($dashboard_name);
    my $dashboard_id=$sth->{mysql_insertid};
    $dbh->disconnect();
    return "Created $dashboard_id";
}
sub rem_dashboard{
    my $dashboard_id=$input->{dashboard_id};
    if(!$dashboard_id || "" eq $dashboard_id){
        return Strings::error();
    }
    my $dbh=init_db();
    my $sth=$dbh->prepare(Query::del_dash());
    if($sth->execute($dashboard_id)){
        $dbh->disconnect();
        return "Del dash success";
    }
    $dbh->disconnect();
    return Strings::error();
 
}
sub add_dashboard_port{
    my $dashboard_id=$input->{dashboard_id};
    my $port_id=$input->{port_id};
    # my $dashboard_id=shift;
    # my $port_id=shift;
    my $dbh=init_db();
    my $sth=$dbh->prepare(Query::add_port_to_dashboard());
    $sth->execute($dashboard_id,$port_id);
    $dbh->disconnect();
    return 1;
}
sub show_dashboard_ports{
    my $dashboard_id=$input->{dashboard_id} || shift;
    my $dbh=init_db();
    my $ports=$dbh->selectall_arrayref(Query::get_dashboard_ports(),{Slice=>{}},$dashboard_id);
    $dbh->disconnect();
    return $ports;
}
sub rem_dashboard_port{
    my $dashboard_id=$input->{dashboard_id};
    my $port_id=$input->{port_id};
    my $dbh=init_db();
    my $sth=$dbh->prepare(Query::rem_port_from_dashboard());
    $sth->execute($dashboard_id,$port_id);
    $dbh->disconnect();
    return 1;
}
sub add_device{
    my $btn_val="add";
    my($ip,$dev_name,$community)=($input->{ip},$input->{dev_name},$input->{community});
    my $dbh=init_db();
    my $sth;
    my $dev_id="";


    if ($input->{device_id} || $input->{device_id} ne ""){
        #update!!!
        $btn_val="update";
        $sth=$dbh->prepare(Query::update_device());
        $sth->execute($ip,$dev_name,$community,$input->{device_id});
        $dev_id=$input->{device_id};
        # return;
    }else{

     $sth=$dbh->prepare(Query::add_device());
     $sth->execute($ip,$dev_name,$community);
     $dev_id=$sth->{mysql_insertid};
    }
     $dbh->disconnect();

    # my $dev_id=1;

    if(!$dev_id || "" eq $dev_id){
        return Strings::error();
    }
    $input->{device_id}=$dev_id;

    return Strings::add_dev_form() . Strings::dev_created($btn_val);
    # return "Device <b>$name</b> created";

    
}
sub del_device{
    my $device_id=shift;
    my $dbh=init_db();
    my $result;
    my $sth=$dbh->prepare(Query::rem_device());
    if($sth->execute($device_id)){
        $result=1;
    }
    else{$result=0;}
    $dbh->disconnect();
    return $result;
}
sub get_devices{
    my $dbh=init_db();
    #  my $sth=$dbh->prepare(Query::get_devices());
    #  $sth->execute();
     #foreach row print table wit ip name comm button edit dev show ports create ports
     my $devices=$dbh->selectall_arrayref(Query::get_devices(),{Slice=>{}}); 
    #  return Strings::device_list($devices);
    return $devices;
    
}
# sub add_port{
# my $str="INSERT INTO `ports`(`device_id`, `custom_name`, `ifindex`, `ifname`, `ifalias`, `ifdescr`) VALUES (?, ?, ?, ?, ?, ?)";
# return $str;
# }#endsub
sub get_ports{
    #** todo check if port is already creted in DB by ifindex
    #
    # my $result="<form name='fports' action='' method='post'><table>";#add form
    my ($ip,$community)=(shift || "", shift || "") ;
    if("" eq $ip || "" eq $community) {return Strings::error();}
    my $ports=Snmp::get_interfaces($ip,$community);
    return Strings::add_port_form($ports);
}
sub get_ports_db{
    my $dbh=init_db();
    my $device_id=$input->{device_id} || shift;
    my $ports=$dbh->selectall_arrayref(Query::device_ports(),{Slice=>{}},$device_id); 
    $dbh->disconnect();
    # return Strings::add_port_form($ports);
    return $ports;
}
sub get_port_data{
    my $port_id=shift;
    my $dbh=init_db();
    my $port;
    if($port_id){
     $port=$dbh->selectall_arrayref(Query::port_data($port_id),{Slice=>{}},$port_id);
    }else{
     $port=$dbh->selectall_arrayref(Query::port_data(),{Slice=>{}},);
    }
    $dbh->disconnect();
    return $port;
}
sub get_port_thresholds{
    my $port_id=shift;
    my $dbh=init_db();
    my $thresholds;
    if (!$port_id || "" eq $port_id){
     $thresholds=$dbh->selectall_arrayref(Query::port_thresholds(),{Slice=>{}},);
    }else{
    $thresholds=$dbh->selectall_arrayref(Query::port_thresholds($port_id),{Slice=>{}},$port_id);
    }
    return $thresholds;
}
sub get_alerts{
    my $port_id=shift;
    my $dbh=init_db();
    my $alerts;
    if (!$port_id || "" eq $port_id){
    $alerts=$dbh->selectall_arrayref(Query::get_port_alerts(),{Slice=>{},});
    }
    else
    {
    $alerts=$dbh->selectall_arrayref(Query::get_port_alerts($port_id),{Slice=>{}},$port_id);
    }
    return $alerts; 
}

sub rem_ports{
    my ($selected)=shift;
    my $counter=0;
    my $dbh=init_db();
    my $sth=$dbh->prepare(Query::del_port());
    foreach my $idx (@$selected) {
        $sth->execute($idx);
        $counter++;
    }
    $dbh->disconnect();
    return "Deleted $counter ports!!!";
}

sub create_ports{
    my $cgi=shift;
    my (@selected)=$cgi->param('sel');
    my ($device_id)=$cgi->param('device_id');
    my $dbh=init_db();
    my $sth=$dbh->prepare(Query::add_port());
    my $counter=0;
    foreach my $idx (@selected) {
        #passing last values second time for update
        $sth->execute($device_id,$idx,$cgi->param("ifname[$idx]"),$cgi->param("port_name[$idx]"),$cgi->param("ifname[$idx]"),$cgi->param("port_name[$idx]"));#|| die return error
        $counter++;
    }
    $dbh->disconnect();
    return "Done! Created $counter ports";
}
sub threshold_update{
    my $cgi=shift;
    my @port_ids=$cgi->param('port_ids');
    my $dbh=init_db();
    my $sth=$dbh->prepare(Query::update_port_threshold());
    my $counter=0;
    foreach my $idx (@port_ids) {
        # $result.="$idx--".$cgi->param("max_in[$idx]")."||";
        my $min_in=Parser::from_kmg($cgi->param("min_in[$idx]"));
        my $max_in=Parser::from_kmg($cgi->param("max_in[$idx]"));
        my $min_out=Parser::from_kmg($cgi->param("min_out[$idx]"));
        my $max_out=Parser::from_kmg($cgi->param("max_out[$idx]"));
        $sth->execute($idx,$min_in,$max_in,$min_out,$max_out,$min_in,$max_in,$min_out,$max_out);
        $counter++;
    }
    $dbh->disconnect();
    return "Updated $counter thresholds.";
}
sub update_ports{
    my $cgi=shift;
    my (@selected)=$cgi->param('sel');
    my ($device_id)=$cgi->param('device_id');
    my $dbh=init_db();
    my $sth=$dbh->prepare(Query::update_port());
    my $counter=0;
    foreach my $idx (@selected) {
        #passing last values second time for update
        $sth->execute($cgi->param("port_name[$idx]"),$idx);
        $counter++;
    }
    $dbh->disconnect();
    return "Done! Updated $counter ports";
}
sub get_port_formdata{
    my $cgi=shift;
    my (@selected)=$cgi->param('sel');
    my ($device_id)=$cgi->param('device_id');
    if($cgi->param('cmd') && $cgi->param('cmd') eq "update"){
        #* todo create and call update sub with $cgi,and @selected args
        # return "UPDATE!";
        return Dumper(@selected); 
    }
    my $dbh=init_db();
    my $sth=$dbh->prepare(Query::add_port());
    #my @port_data;
    my $counter=0;
    foreach my $idx (@selected) {
        #V#todo if $port_id exec update
    #push(@port_data,{ifindex=>$idx,ifname=>$cgi->param("ifdesc[$idx]"),device_id=>$device_id } );
    # $sth->execute($device_id,$idx,$cgi->param("ifname[$idx]"),$cgi->param("port_name[$idx]"));#|| die return error
    
    #passing last values second time for update
    $sth->execute($device_id,$idx,$cgi->param("ifname[$idx]"),$cgi->param("port_name[$idx]"),$cgi->param("ifname[$idx]"),$cgi->param("port_name[$idx]"));#|| die return error
    $counter++;
    }
    $dbh->disconnect();
    
        # return @selected;
        return "Done! Created $counter ports";
}
sub find_ports_by_name{
    my $srch=shift || "";
    my @found;
    if("" eq $srch) {return @found};
    my $ports=&get_port_data();
    #grep { $port->{port_id} == $_->{port_id} } @{$device->{thresholds}};
    @found=grep { $_->{port_name} =~m/$srch/i } @{$ports};
    return \@found;
}
sub collectors_get{
    my $dbh=init_db();
    my $collectors=$dbh->selectall_arrayref(Query::get_collectors(),{Slice=>{}} );
    $dbh->disconnect;
    return $collectors;
}
sub get_graphs_by_device{
    my $ports=get_ports_db();
# use lib $RealBin."/lib";

    # use InfluxDB::HTTP;

my $influx = InfluxDB::HTTP->new(host => '192.0.0.55',
        port => 8086);

my $ping_result = $influx->ping();
# print "$ping_result\n";
    if($ping_result){
        my $device_id=$input->{device_id};
        my $query = $influx->query(
    [ 'SELECT intraffic,outtraffic FROM interfaceTraffic WHERE device_id=~ /^'.$device_id.'$/ AND (time >= now() - 72h and time <= now()) GROUP BY port_id'],
    database => "traffic",
    
    
);



    # return "$ping_result";
    # return $query->results;
    return $query->results;
    }else{
        return "no conn";
    }

}
return 1;