#!/usr/bin/perl -w
use strict;
# use Data::Dumper qw( Dumper );
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
my $dir=$RealBin;
# my $debugFile = "$dir/debug.log";
# open (my $debug,">>", $debugFile) or die $!;
# my ($input)=\%main::input;

package Dispatch;
use Data::Dumper qw( Dumper );
my ($input)=\%main::input;
my $cfg=Cfg::get_config();
my $debug=Cfg::get_debug();

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
    my $title=qq(<h4>Showing graphs for device $input->{dev_name}</h4>);
    return $title . Strings::graph_filters() . Strings::grapher(Service::get_ports_db());
}
sub port_detail{
    my $ports=Service::get_port_data($input->{port_id});
    my $port=@$ports[0];
    my $title=qq(<h4>Details for port: $port->{device_name} $port->{ifname}($port->{port_name})</h4>);
    return $title . Strings::grapher($ports) . &threshold() . &show_alerts();
}
sub show_dashboard_graphs{
    my $ports=shift;
    if(!$ports || scalar @{ $ports } < 1){
        return "no ports found";
    }
    my $title=qq(<h4>Showing graphs for );
    if($input->{quick_find}){
        $title.=qq(find name ~ $input->{quick_find} </h4>);
    }else{
        $title.=qq(dashboard $input->{dashboard_name}</h4>);
    }
    return $title . Strings::graph_filters() . Strings::grapher($ports);
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
sub show_collectors{
    my $collectors=Service::collectors_get();
    my $title="<h4>Collectors</h4>";
    return $title . Strings::collectors_list($collectors);
}
return 1;