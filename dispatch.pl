#!/usr/bin/perl -w
use strict;
# use Data::Dumper qw( Dumper );
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
my $dir=$RealBin;
my $debugFile = "$dir/debug.log";
# open (my $debug,">>", $debugFile) or die $!;
# my ($input)=\%main::input;

package Dispatch;
use Data::Dumper qw( Dumper );
my ($input)=\%main::input;


sub get_dev{
    my $devices=Service::get_devices();
     return Strings::device_list($devices);
}
sub rem_dev{
    if(Service::del_device($input->{device_id})){
        return "Device deleted";
    }
    return Strings::error();
}
sub show_ports{
    my $ports=Service::get_ports_db();
    return Strings::add_port_form($ports);
}
sub rem_selected_ports{
    my $cgi=shift;
    my (@selected)=$cgi->param('sel');
    my ($device_id)=$cgi->param('device_id');
    if($cgi->param('cmd') && $cgi->param('cmd') eq "update"){
        # return "UP";
        if(scalar @selected == 0){
            return "No ports Selected";
        }
        return Service::rem_ports(\@selected);
    }
}
sub get_port_formdata{
    my $cgi=shift;
    #check input:
    # del create update...?
    my (@selected)=$cgi->param('sel');
    my ($device_id)=$cgi->param('device_id');
    if(scalar @selected == 0){
            return "No ports Selected !";
        }
    if($cgi->param('cmd') && $cgi->param('cmd') eq "update"){
        if($input->{del_ports}){
            # return "DElete selected!";
            return Service::rem_ports(\@selected);
        }
        elsif($input->{save_ports}){
            return Service::update_ports($cgi);
        }
    }
    #create ports
    # return "CREATE PORTS";
    return Service::create_ports($cgi);
    # return Dumper $input;

}
sub show_graphs{
    my $device_id=shift;
    return Strings::dygraph($device_id,Service::get_ports_db());
}
sub port_detail{
    # return "$input->{port_id}";
    # return Strings::port_details($input->{port_id},Service::get_port_data($input->{port_id})) . &threshold() . "<h2>Alerts:</h2> TODO!!!";
    my $port=Service::get_port_data($input->{port_id});
    return Strings::port_details($port) . &threshold() . &show_alerts();
}
sub show_dashboard_graphs{
    my $ports=shift;
    my $str="";
    foreach my $port ( @{ $ports }) {
        $str.="$port->{port_id}|";
    }
    chop($str);
    # return $str;
    return Strings::dashboard_graphs($str,$ports);

}
sub threshold{
    return Strings::port_thresh(Service::get_port_thresholds($input->{port_id}));
}
sub show_alerts{
    # return Dumper(Service::get_alerts($input->{port_id}));
    return Strings::alerts(Service::get_alerts($input->{port_id}));
}
sub show_dashboards{
    my $result=Strings::dashboard_form();
    $result.=Strings::dashboard_list(Service::get_dashboards());
    return $result;
}
return 1;