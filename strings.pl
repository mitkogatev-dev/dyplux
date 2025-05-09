#!/usr/bin/perl -w
use strict;
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
my $dir=$RealBin;
package Strings;
use Data::Dumper qw( Dumper );
use JSON;
my $cfg=Cfg::get_config();
my $debug=Cfg::get_debug();

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
    <input type="submit" value="delete" name="remove_device" onclick="sure(event);"/>
    
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
my $th=qq(<th>sel</th><th>ifname</th><th>port name</th><th>state</th>);
if($input->{edit_ports}){
    $what="Updating";
    $cmd="<input type='hidden' name='cmd' value='update'>";
    $del_btn=qq(<input type='submit' name='del_ports' value='Delete selected' onclick="sure(event);">);
    $port_identifier="port_id";
    $dashboard_select=&gen_dash_select(Service::get_dashboards());
    $th=qq(<th>sel</th><th>ifname</th><th>port name</th><th>dash</th><th>graph</th>);

}

    my $result="<form name='fports' action='' method='post'>";#add form
    $result.=qq(<h1>$what ports for $input->{dev_name}</h1>
        $cmd
        <input type='hidden' name='device_id' value='$input->{device_id}'>
        <table><tr>$th</tr>
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
    $result.=qq(<td><form action="" method="post" target="_blank"><input type="hidden" name="port_id" value="$port->{port_id}"/><input type="submit" value="show graph" name="single_graph"/></form></td>);
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
        <td><input type='submit' name='show_device_graphs' value='show graphs' onclick='printMsg();'></td>
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
sub grapher{
    my $result;
    my $ports=to_json(shift);
    my $json_data;
    if("js" ne $cfg->{influx_query_method}){
        $json_data=Influx_curl::get_data($input);
    }
    $result.="<div id='div_g'></div>";
    $result.=qq(<script>
        drawGraph([$ports,$json_data]);
            </script>
    );
    return $result;
}
sub graph_filters{
    my $result="";
    $result.="<div>filter max traffic > <input type='text' id='filterMax' value='0M'/> <button onclick='filterMax()'>filter</button></div>";
    $result.="<div>filter by title <input type='text' id='filterTitle' value=''/> <button onclick='filterByTitle()'>filter</button></div>";
    $result.="<div><button onclick='resetFilter()'>reset filters</button></div>";
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
    $result.=qq(<table><tr>
        <th>port</th><th>min in</th><th>max in</th><th>min out</th><th>max out</th>
        </tr>);
    foreach my $port ( @{ $ports }) {
        my $min_in=Parser::to_kmg($port->{min_in}) //  -1;
        my $max_in=Parser::to_kmg($port->{max_in}) //  -1;
        my $min_out=Parser::to_kmg($port->{min_out}) //  -1;
        my $max_out=Parser::to_kmg($port->{max_out})  //  -1;
        $result.=qq(<tr>
        <input type=hidden name="port_ids" value="$port->{port_id}" />
        <td>$port->{name} $port->{ifname}($port->{port_name})</td>
        <td><input type="text" name="min_in[$port->{port_id}]" value="$min_in" /></td>
        <td><input type="text" name="max_in[$port->{port_id}]" value="$max_in" /></td>
        <td><input type="text" name="min_out[$port->{port_id}]" value="$min_out" /></td>
        <td><input type="text" name="max_out[$port->{port_id}]" value="$max_out" /></td>
        </tr>);
    }
    $result.="</table>";
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
            <input type="hidden" name="dashboard_name" value="$dashboard->{dashboard_name}"/>
            <td>$dashboard->{dashboard_name}</td>
            <td><input type="submit" name="show_dashboard" value="show"/></td>
            <td><input type="submit" name="edit_dashboard" value="edit" /></td>
            <td><input type="submit" name="remove_dashboard" value="delete" onclick="sure(event);"/></td>
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
        $result.="<option value='$port->{port_id}'>$port->{device_name} $port->{ifname}($port->{port_name})</option>";
    }
    $result.="</select> <input type='submit' name='add_to_dash' value='add'/></form>";
    return $result;
}
sub dashboard_list_ports{
    my $ports=shift;
    my $result;
    if(!$ports || (scalar @{$ports} == 0)){ return "No ports defined for this dashboard!"; }
    $result.="<p>Current ports:</p>";
    foreach my $port ( @{ $ports }) {
        $result.=qq(
        <form action="" method="post">
        <input type="hidden" name="dashboard_id" value=$port->{dashboard_id} />
        <input type="hidden" name="port_id" value=$port->{port_id} />
        
        <div>
        $port->{device_name} - $port->{ifname}($port->{port_name}) 
        <input type='submit' name='rem_dash_port' value='delete' onclick="sure(event);">
        </div> 
        </form>);
    }
    return $result;
}
sub dashboard_edit{
    my $result;
    my $dashboard=Service::get_dashboards($input->{dashboard_id});
    $result=qq(<h4>Edit Dashboard: @$dashboard[0]->{dashboard_name} </h4>);
    $result.=&dashboard_add_port($dashboard,Service::get_port_data());
    $result.=&dashboard_list_ports(Service::show_dashboard_ports());
    return $result;
}
sub alerts{
    my $result;
    my $alerts=shift;
    $result.=qq(<table><tr><th>port</th><th>alert</th><th>created at</th><th>disabled at</th></tr>);
    foreach my $alert (@ {$alerts}){
        # my $port=Service::get_port_data($alert->{port_id})->[0];
        $result.=qq(<tr><td>$alert->{device_name} - $alert->{ifname}($alert->{port_name})</td><td>$alert->{name}</td><td>$alert->{created_at}</td><td>$alert->{disabled_at}</td></tr>);
    }
    $result.="</table>";
    return $result;
}
sub collectors_list{
    my $collectors=shift;
    # if(!$collectors || (scalar @{$collectors} == 0)){ return "No collectors defined!"; }
    my $result="<form action='' method='post'>";
    $result.=qq(name:<input name='new_collector_name' /><input type='submit' name='add_collector' value='add'/> <p></p>);
    $result.=qq(
        <table>
        <tr>
            <th>sel</th>
            <th>ID</th>
            <th>name</th>
            <th>enabled</th>
            <th>disable alerts</th>
            <th>current host</th>
            <th>last run</th>
            <th>interval</th>
            <th>devices</th>
        </tr>);
    foreach my $collector (@{$collectors}){
        my $id=$collector->{collector_id};
        my $en_check=$collector->{enabled} ? "checked" : "";
        my $al_check=$collector->{disable_alerts} ? "checked" : "";

        $result.=qq(
            <tr>
            <td><input type='checkbox' name='sel' value='$id' /></td>
            <td>$id</td>
            <td><input onfocus="selRow(this);" type='text' name='collector_name[$id]' value='$collector->{collector_name}'/></td>
            <td><input onfocus="selRow(this);" type='checkbox' name='enabled[$id]' value='1' $en_check /></td>
            <td><input onfocus="selRow(this);" type='checkbox' name='disable_alerts[$id]' value='1' $al_check /></td>
            <td>$collector->{active_host}</td>
            <td>$collector->{last_run}</td>
            <td>$collector->{interval_seconds} seconds</td>
            <td>$collector->{devices}</td>
            </tr>
            );
    }
    $result.=qq(
        </table>
        <input type='submit' name='save_collectors' value='save selected' />
        <input type='submit' name='del_collectors' value='delete selected' onclick="sure(event);" />
        </form>);

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