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

return 1;