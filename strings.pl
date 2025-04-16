#!/usr/bin/perl -w
use strict;
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
my $dir=$RealBin;
package Strings;
use Data::Dumper qw( Dumper );
use JSON;
my $cfg=Cfg::get_config();

# use Encode qw(encode_utf8);

#* import ref to router.cgi %input;
my ($input)=\%main::input;


sub add_dev_form{
    # my ($ip,$dev_name,$community,$btn)=(shift || "",shift || "",shift || "",shift || "") ;
    my $msg=shift || "";

    my ($ip,$dev_name,$community,$btn)=($input->{ip} || "",$input->{dev_name} || "",$input->{community} || "", "") ;
    my $btn_val="add";
    
    if($input->{device_id}){
        $btn_val="update";
        $btn.=test_snmp_btn();
        $btn.="<input type='hidden' name='device_id' value='$input->{device_id}'>";
    }
    if("ok" eq $msg){$btn.=get_ports_btn();}

    my $form = qq(<form action="" method="post">
    <label for="ip">ip address:</label>
    <input type="text" name="ip" id="ip" value="$ip" required>
    <label for="dev_name">name:</label>
    <input type="text" name="dev_name" id="dev_name" value="$dev_name" required>
    <label for="community">comm</label>
    <input type="text" name="community" id="community" value="$community" required>

    <input type="submit" value="$btn_val" name="submit_device">
    
    $btn
</form>);
return $form;
}
sub get_ports_btn{
    return qq(
        <br>
    <input type="submit" value="get interfaces" name="index_ports" >
    );
}
sub test_snmp_btn{
    return qq(<input type="submit" value="test" name="test_snmp" >);
}

sub add_port_form{
    my $ports=shift;
if(!$ports || (scalar @{$ports} == 0)){return "<h1>No ports for device $input->{dev_name}</h1>";}
my $cmd="";
my $del_btn="";
my $port_identifier="ifindex";
my $what="Creating";
my $dashboard_select;
if($input->{edit_ports}){
    $what="Updating";
    $cmd="<input type='hidden' name='cmd' value='update'>";
    $del_btn="<input type='submit' name='del_ports' value='Delete selected'>";
    $port_identifier="port_id";
    $dashboard_select=&gen_dash_select(Service::get_dashboards());
}

    my $result="<form name='fports' action='' method='post'>";#add form
    $result.=qq(<h1>$what ports for $input->{dev_name}</h1>
        $cmd
        <input type='hidden' name='device_id' value='$input->{device_id}'>
        <table><tr><th>sel</th><th>ifname</th><th>port name</th><th>stuff</th></tr>
        );
foreach my $port ( @{ $ports }) {
    my $port_state="";
    if(!$port->{ifstate}){
        $port_state="n/a";
    }else{
    if("2" eq $port->{ifstate}){$port_state="Down";}else{$port_state="UP";}
    }
    my $port_name=$port->{port_name};
$result .= qq(
    <tr>
        <td><input type="checkbox" name="sel" value="$port->{$port_identifier}"></td>
        <td><input type="text" name="ifname[$port->{$port_identifier}]" value="$port->{ifname}"></td>
        <td><input onfocus="selRow(this);" type="text" name="port_name[$port->{$port_identifier}]" value="$port_name"></td>
 
);
if($input->{edit_ports}){
    $result.="<td>".&port_to_dashboard_form($port->{port_id},$dashboard_select)."</td>";
}
else {
    # $result.=qq(<td><input type="text" name="ifstate[$port->{$port_identifier}]" value="$port_state"></td>);
    $result.=qq(<td>ifstate: <b>$port_state</b></td>);
}
$result.="</tr>";
    
    }
$result= $result . "</table><input type='submit' name='save_ports' value='save'> $del_btn</form>";
return $result;
}
sub device_list{
    my $devices=shift;
    my $result="<table>";
    foreach my $device (@{$devices}){
        $result.="<form action='' method='post'><tr>
        <td>$device->{name}</td>
        <td>$device->{ip}</td>
        <td><input type='submit' name='show_grpahs' value='show graphs' onclick='printMsg();'></td>
        <td><input type='submit' name='edit_dev' value='edit'></td>
        <td><input type='submit' name='edit_ports' value='edit interfaces'></td>
        <td>
            <input type='hidden' name='device_id' value='$device->{device_id}'>
            <input type='hidden' name='ip' value='$device->{ip}'>
            <input type='hidden' name='community' value='$device->{community}'>
            <input type='hidden' name='dev_name' value='$device->{name}'>
        </td>
        </form></tr>";
    }
    $result.="</table>";
    return $result;

}
sub dygraph{
    my $result;
    # my $data=encode_json(shift);
    my $device_id=shift;
    # my $ports=encode_json(shift);
    my $ports=to_json(shift);
    my $json;
    if("js" ne $cfg->{influx_query_method}){
    $json=Influx_curl::get_data($device_id);
    }
    $result.="<h4>showing graphs for: $input->{dev_name}</h4>";
    $result.="<div>filter max traffic > <input type='text' id='filter' value='0M'/> <button onclick='filterMax()'>filter</button></div>";

    $result.="<div id='div_g'></div>";
    # $result.="<script>let data=$data;console.log(data)</script>";

    $result.=qq(<script>
    
        drawGraph(["device",$device_id,$ports,$json]);
            
            </script>
            
    );
    return $result;
}
sub port_details{
    my $result;
    # my $port_id=shift;
    # my $ports=to_json(shift);
    my $ports=shift;
    my $port_id=@$ports[0]->{port_id};
    my $ports_json=to_json($ports);
    $result.="<h4>showing details for port $port_id todo</h4>";
    $result.="<div id='div_g'></div>";
    $result.=qq(<script>
    
        drawGraph(["port",$port_id,$ports_json]);
            
            </script>
            
    );
    return $result;
}
sub dev_created{
    my $val=shift || "";
    my $what= "created";
    if ("update" eq $val){
        $what="updated";
    }
    return qq(Device $what!<br>Next test and create ports.);
}
sub port_thresh{
    my $ports=shift;
    # my $port=@{ $port_arr }[0];
    my $result="<form action='' method='post'>";
    foreach my $port ( @{ $ports }) {
        my $min_in=Parser::to_kmg($port->{min_in}) //  -1;
        my $max_in=Parser::to_kmg($port->{max_in}) //  -1;
        my $min_out=Parser::to_kmg($port->{min_out}) //  -1;
        my $max_out=Parser::to_kmg($port->{max_out})  //  -1;

    $result.=qq(
        <h4>Threshold for: $port->{name} $port->{ifname}($port->{port_name})</h4>
        <input type=hidden name="port_ids" value="$port->{port_id}" />
        minIn:<input type="text" name="min_in[$port->{port_id}]" value="$min_in" />
        maxIn:<input type="text" name="max_in[$port->{port_id}]" value="$max_in" />
        minOut:<input type="text" name="min_out[$port->{port_id}]" value="$min_out" />
        maxOut:<input type="text" name="max_out[$port->{port_id}]" value="$max_out" />
        );
    }
    $result.="<input type='submit' name='upd_thresh' value='update' />";
    return $result;

}
sub dashboard_form{
    my $result = "<h4>Dashboards</h4>";
    $result.=qq(<form action "" method='post'>
        name:<input type='text' name='dashboard_name' required />
        <input type='submit' name='add_dashboard' value='create' />
        </form>);
}
sub dashboard_list{
    my $dashboards=shift;
    my $result="<table>";
    if(!$dashboards || (scalar @{$dashboards} == 0)){ return "No dashboards defined!"; }
    foreach my $dashboard ( @{ $dashboards }) {
        $result.=qq(<tr>
            <form action="" method="post">
            <input type="hidden" name="dashboard_id" value="$dashboard->{dashboard_id}"/>
            <td>$dashboard->{dashboard_name}</td>
            <td><input type="submit" name="show_dashboard" value="show"/></td>
            <td><input type="submit" name="edit_dashboard" value="edit" /></td>
            <td><input type="submit" name="remove_dashboard" value="delete" /></td>
            </form>
            </tr>);
    }
    $result.="</table>";
    return $result;
}
sub dashboard_add_port{
    my $dashboards=shift;
    my $dashboard=@{$dashboards}[0];
    my $ports=shift;
    my $result="<form action='' method='post'>";
    $result.="<input type='hidden' name='dashboard_id' value='$dashboard->{dashboard_id}' />";
    $result.="<select name='port_id'>";
    foreach my $port ( @{ $ports }) {
        $result.="<option value='$port->{port_id}'>$port->{name} $port->{ifname}($port->{port_name})</option>";
    }
    $result.="</select> <input type='submit' name='add_to_dash' value='add'/></form>";
    return $result;
}
sub dashboard_list_ports{
    my $ports=shift;
    my $result;
    if(!$ports || (scalar @{$ports} == 0)){ return "No ports defined for this dashboard!"; }
    foreach my $port ( @{ $ports }) {
        $result.="<div>$port->{name} $port->{ifname}($port->{port_name})</div>";
    }
    return $result;
}
sub dashboard_graphs{
    my $result;
    my $port_ids=to_json(shift);#string
    my $ports=to_json(shift);
    $result.=$port_ids;
    $result.="<div id='div_g'></div>";
    $result.=qq(<script>
    
        drawGraph(["dashboard",$port_ids,$ports]);
            
            </script>
            
    );
    return $result;
}
sub port_to_dashboard_formNO{
    #todo:
    #cannot have form inside form
    #migrate to js
    #convert foreach block to sub so it gets called only once
    #target="inlineFrame" is invalid as it is not inside this iframe
    my $port_id=shift;
    my $dashboards=shift;
    my $result=qq(<form name="dash" action="router.cgi" target="inlineFrame">
        <input type="hidden" name="port_id" value="$port_id"/>
        <select name="dashboard_id">);
    foreach my $dashboard (@ {$dashboards}){
        $result.="<option value='$dashboard->{dashboard_id}'>$dashboard->{dashboard_name}</option>";
    }
    $result.="</select> <input type='submit' name='add_to_dash' value='add'/></form>";
    return $result;
}
sub gen_dash_select{
    my $dashboards=shift;
    my $result="<select name='dashboard_id'><option value=0>Dashboard</option>";
    foreach my $dashboard (@ {$dashboards}){
        $result.="<option value='$dashboard->{dashboard_id}'>$dashboard->{dashboard_name}</option>";
    }
    $result.="</select>";
}
sub port_to_dashboard_form{
    my $port_id=shift;
    my $select=shift;
    my $result=qq(<button type="button" port_id="$port_id" onclick="addToDash(this);">add to</button> $select);
    return $result;
}
sub error{
    return "<br>nooooooooooooo!!!!!!!!!!"
}
sub test {

 return   "<h2>Submit</h2>ip:$input->{ip}<br>comm:$input->{community}";
}

return 1;