#!/usr/bin/perl -w
use strict;
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
my $dir=$RealBin;


package Influx_curl;
use Data::Dumper qw( Dumper );
my $cfg=Cfg::get_config();
my $debug=Cfg::get_debug();

sub get_data{
    my $device_id=shift;
    my $influx_bucket=$cfg->{influx_bucket};
    my $influx_url=$cfg->{influx_url};
    my $influx_token=$cfg->{influx_token};
    my $query=qq(SELECT intraffic,outtraffic FROM interfaceTraffic WHERE device_id=~ \/\^$device_id\$\/ AND (time >= now() - 48h and time <= now()) GROUP BY device_id,port_id);
    my $cmd=qx(curl --silent --get $influx_url/query?db=$influx_bucket --header "Authorization: Token $influx_token" --data-urlencode "q=$query");
    
    return $cmd;
    # print $debug $cmd; ##ok returns JSON
    ###### DECIDE #####
    #data format can be done here
    #calculate min max values here
    #
}
sub query_builder{
    my $input=shift;
    my $query;
    print $debug Dumper($input);
    if($input->{show_device_graphs}){
        $query=qq(SELECT intraffic,outtraffic FROM interfaceTraffic WHERE device_id=~ \/\^$input->{device_id}\$\/ AND (time >= now() - 48h and time <= now()) GROUP BY device_id,port_id);
    }
    elsif($input->{single_graph}){
        $query=qq(SELECT intraffic,outtraffic FROM interfaceTraffic WHERE port_id=~ \/\^$input->{port_id}\$\/ GROUP BY device_id,port_id);
    }
    elsif($input->{show_dashboard}){
        #todo: combine port_ids
        my $ports=Service::show_dashboard_ports($input->{dashboard_id});
        # foreach my $port ( @{ $ports }) {
        # $arg.="$port->{port_id}|";
        # }
        # chop($arg);
        my $arg=&parse_port_ids($ports);
        $query=qq(SELECT intraffic,outtraffic FROM interfaceTraffic WHERE port_id=~ \/\^$arg\$\/ AND (time >= now() - 48h and time <= now()) GROUP BY device_id,port_id);
    }
    elsif($input->{quick_find}){
        my $ports=Service::find_ports_by_name($input->{quick_find});
        my $arg=&parse_port_ids($ports);
        $query=qq(SELECT intraffic,outtraffic FROM interfaceTraffic WHERE port_id=~ \/\^$arg\$\/ AND (time >= now() - 48h and time <= now()) GROUP BY device_id,port_id);
    }

    else { return 1;}
    return $query;
}
sub parse_port_ids{
    my $ports=shift;
    my $ids="";
    foreach my $port ( @{ $ports }) {
        $ids.="$port->{port_id}|";
        }
        chop($ids);
    return $ids;
}

return 1;