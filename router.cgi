#!/usr/bin/perl -w
use strict;
use CGI qw(-utf8);
use CGI::Carp qw(fatalsToBrowser);
use JSON;
use Data::Dumper qw( Dumper );
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
# use lib $RealBin."/lib";
my $start_run=time();
my $dir=$RealBin;
my $clip=$ENV{REMOTE_ADDR};
my $debugFile = "$dir/debug.log";
# open (my $debug,">>", $debugFile) or die $!;
our %input;
my $cgi = new CGI;
$cgi->charset('utf-8');
$CGI::LIST_CONTEXT_WARN = 0 ;
my @params=$cgi->param();
my $request_method=$cgi->request_method();
my $input_str="";

for my $key ( $cgi->param() ) {
 $input{$key} = $cgi->param($key);
 #workaround to pass inputs to other cgi
 $input_str.="$key=".$cgi->param($key)."&";
}
my $html=""; 
require "$dir/config.pl";
require "$dir/strings.pl";
require "$dir/snmp.pl";
require "$dir/service.pl";
require "$dir/query.pl";
require "$dir/dispatch.pl";
require "$dir/parser.pl";
require "$dir/influx.pl";
#
my $cfg=Cfg::get_config();

if($request_method eq "POST"){
# print $debug Dumper($input{name});
if($input{dada}){
    $html="you pressed dada and came from $clip";
}
elsif($input{add_dev} || $input{edit_dev}){
    $html=Strings::add_dev_form();
}
elsif($input{submit_device}){
    $html=Service::add_device();
}
elsif($input{remove_device}){
    $html=Dispatch::rem_dev();
}
elsif($input{show_devices}){
    # $html=Service::get_devices();
    $html=Dispatch::get_dev();
}
elsif($input{test_snmp}){
    $html= Snmp::test_device($input{ip},$input{community});
}
elsif($input{index_ports}){
    $html=Service::get_ports($input{ip},$input{community});
}
elsif($input{save_ports}){
    $html=Dispatch::get_port_formdata($cgi);
}
elsif($input{edit_ports}){
    # $html=Service::get_ports_db();
    $html=Dispatch::show_ports();
}
elsif($input{del_ports}){
    # $html=Dispatch::rem_selected_ports($cgi);
    $html=Dispatch::get_port_formdata($cgi);

}
elsif($input{show_device_graphs}){
     $html=Dispatch::show_graphs($input{device_id});
}
elsif($input{single_graph}){
    $html=Dispatch::port_detail();
}
elsif($input{show_dashboard}){
    # $html="TODO!!! show port grapsh here";
    my $ports=Service::show_dashboard_ports();
    # $html.=Strings::dashboard_list_ports($ports);
    $html=Dispatch::show_dashboard_graphs($ports);
}
elsif($input{thresholds}){
    $html=Dispatch::threshold();
}
elsif($input{port_threshold}){
    $html=Dispatch::threshold();
}
elsif($input{upd_thresh}){
    $html=Service::threshold_update($cgi);
}
elsif($input{alerts}){
    # $html="TODO!!";
    $html=Dispatch::show_alerts();
}
elsif($input{dashboards}){
    $html=Dispatch::show_dashboards();
}
elsif($input{add_dashboard}){
    $html=Service::add_dashboard();
}
elsif($input{edit_dashboard}){
    $html=Strings::dashboard_edit();
    # my $dashboard=Service::get_dashboards($input{dashboard_id});
    # $html=qq(<h4>Edit Dashboard: @$dashboard[0]->{dashboard_name} </h4>);
    # $html.=Strings::dashboard_add_port($dashboard,Service::get_port_data());
    # $html.=Strings::dashboard_list_ports(Service::show_dashboard_ports());
}
elsif($input{remove_dashboard}){
    $html=Service::rem_dashboard();
}
elsif($input{add_to_dash}){
    # $html="dash:".$input{dashboard_id}."port:".$input{port_id};

    # Service::add_dashboard_port($input{dashboard_id},$input{port_id});
    Service::add_dashboard_port();
    # $html=Strings::dashboard_add_port(Service::get_dashboards($input{dashboard_id}),Service::get_port_data());
    # $html.=Strings::dashboard_list_ports(Service::show_dashboard_ports());
    $html=Strings::dashboard_edit();
}
elsif($input{rem_dash_port}){
    Service::rem_dashboard_port();
    $html=Strings::dashboard_edit();
}
elsif($input{quick_find}){
    # $html="<p>todo: show graphs</p>" . Dumper(Service::find_ports_by_name($input{quick_find}));
    $html=Dispatch::show_dashboard_graphs(Service::find_ports_by_name($input{quick_find}));
}
elsif($input{collectors}){
    $html=Dispatch::show_collectors();
}
elsif($input{save_collectors} || $input{del_collectors} || $input{add_collector}){
    $html=Dispatch::get_collectors_formdata($cgi);
}
else{ 
    # my @desc_arr=$cgi->param('sel');
    $html="<h2>Input not handled!!!</h2>" . Dumper($cgi);
    }
}elsif($request_method eq "GET"){
$html="<div>I'm sorry to inform you that the request you made is not supported by this platform!</div>";
$html.="<div>Please reconsider what you are trying to accomplish by doing this!</div>";
$html.="<div>There is a lot of things you can do with your life instead of sticking around here...</div>";
$html.="<div></div>";
}else{
    return 0;
}


### TODO:
#this loads in iframe
# create(copy...) js to update parent html with results
print $cgi->header("text/html;charset=UTF-8");
my $js="";
# if($input{show_grpahs} || $input{single_graph} || $input{show_dashboard}){
    $js="<script src='js/jquery.min.js'></script>
    <link rel='stylesheet' href='css/dygraph.css'>
    <script src='js/dygraph-combined.js'></script>
    <script src='js/filters.js'></script>";
# }

#*******************
#*   HEAD SECTION
#*******************
print qq(
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="css/style.css">
    <script src='js/script.js'></script>
   <script src='script.cgi?$input_str'></script>
    $js
    <title>Frame</title>
</head>
);
#*******************
#*  BODY SECTION
#*******************
print qq(
    <body>
    <div id='infobox'></div>
    <div id='mainframe'>
    $html
    </div>
    </body>
);
#DEBUG
my $end_run = time();
my $run_time = $end_run - $start_run;
print    "<div><h3>DEBUG cgi</h3> <div>Load time: $run_time seconds.</div>".Dumper($cgi)."</div>" if $cfg->{debug_cgi};
