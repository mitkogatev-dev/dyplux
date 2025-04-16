#!/usr/bin/perl -w
use strict;
use Data::Dumper qw( Dumper );
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
my $dir=$RealBin;
#require "$dir/../../func.pl";
#require "$dir/../encrypt.pl";
#require "/var/www/htdocs/API/func.pl";
# my $debugFile = '/var/www/htdocs/API/debug.log';
# open (my $debug,">>", $debugFile) or die $!;

#require "func.pl";
package Query;
# require "$dir/../func.pl";
sub add_device{
    my $str = "INSERT INTO `devices`(ip,name,community) VALUES(?, ?, ?)";
    return $str;
}
sub update_device{
    my $str= "UPDATE devices SET ip=?, name=?, community=? WHERE device_id=?";
    return $str;
}
sub get_devices{
    my $device_id=shift || "";
    my $where="WHERE 1";
    if("" ne $device_id){
        $where="WHERE device_id = ?";
    }
    return "SELECT `device_id`,`ip`,`name`,`community` FROM devices $where";
}
sub dashboard{
    my $what=shift || "";
    my $str="";
    if(!$what || "" eq $what){
        # create
        $str="INSERT INTO dashboards(dashboard_name) VALUES(?);";
    }
    elsif("update" eq $what){
        #update
    }
    elsif("rem" eq $what){
        #delete
    }
    else {return 0};
    return $str;
}
sub get_dashboards{
    my $dashboard_id=shift || "";
    my $where="WHERE 1";
    if("" ne $dashboard_id){
        $where="WHERE dashboard_id = ?";
    }
    my $str="SELECT dashboard_id,dashboard_name FROM dashboards $where;";
    return $str;
}
sub get_dashboard_ports{
    # my $dashboard_id=shift || "";
    my $str="SELECT dp.dashboard_id,dp.port_id,d.name AS device_name,p.port_name,p.ifname 
        FROM dashboard_ports dp 
        JOIN ports p ON p.port_id=dp.port_id 
        JOIN devices d ON p.device_id=d.device_id
        WHERE dp.dashboard_id=?";
    return $str;
}
sub add_port_to_dashboard{
    return "INSERT IGNORE INTO dashboard_ports(dashboard_id,port_id) VALUES (?,?)";
}
sub del_dash{
    return "DELETE FROM dashboards WHERE dashboard_id=?";
}
sub add_port{
# my $str="INSERT INTO `ports`(`device_id`, `ifindex`, `ifname`, `port_name`) VALUES (?, ?, ?, ?)";
#updatae
my $str="INSERT INTO `ports`(`device_id`, `ifindex`, `ifname`, `port_name`) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE `ifname`=?, `port_name`=?;";
return $str;
}#endsub
sub update_port{
    my $str="UPDATE `ports` SET `port_name`=? WHERE `port_id`=? ";
}
sub del_port{
    my $str="DELETE FROM `ports` WHERE `port_id`=?";
    return $str;
}
sub device_ports{
    my $str="SELECT p.`port_id`,p.`device_id`,p.`ifindex`,p.`ifname`,p.`port_name`,d.name AS device_name FROM `ports` p JOIN devices d ON p.device_id=d.device_id WHERE p.device_id =?";
}
sub get_port_alerts{
    my $port_id=shift || "";
    my $where="WHERE 1";
    if("" ne $port_id){
        $where="WHERE p.port_id = ?";
    }
    my $str = "SELECT a.alert_id,a.port_id,a.dt,at.name FROM alerts a JOIN alert_types at ON a.alert_type_id=at.alert_type_id $where;";
    return $str;
}
sub port_data{
    my $port_id=shift || "";
    my $where="WHERE 1";
    if("" ne $port_id){
        $where="WHERE p.port_id = ?";
    }
    # my $str="SELECT p.`port_id`,p.`device_id`,p.`ifindex`,p.`ifname`,p.`port_name`,d.name,t.threshold_id,t.min_in,t.min_out,t.max_in,t.max_out FROM `ports` p JOIN devices d ON p.device_id=d.device_id LEFT JOIN thresholds t ON p.port_id=t.port_id $where;";
    my $str="SELECT p.`port_id`,p.`device_id`,p.`ifindex`,p.`ifname`,p.`port_name`,d.name AS device_name FROM `ports` p JOIN devices d ON p.device_id=d.device_id $where;";
    return $str;
}
sub port_thresholds{ #TODO!!!
    # my $port_id=shift;
    #my $str="SELECT t.port_id,t.threshold_id,t.min_in,t.min_out,t.max_in,t.max_out FROM thresholds t WHERE t.port_id=?";
    my $str="SELECT p.`port_id`,p.`device_id`,p.`ifindex`,p.`ifname`,p.`port_name`,d.name,t.threshold_id,t.min_in,t.min_out,t.max_in,t.max_out FROM `ports` p JOIN devices d ON p.device_id=d.device_id LEFT JOIN thresholds t ON p.port_id=t.port_id WHERE p.port_id=?;";
    
    return $str;

}
sub update_port_threshold{
    my $str="INSERT INTO `thresholds`(`port_id`,`min_in`,`max_in`,`min_out`,`max_out`) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE `min_in`=?,`max_in`=?,`min_out`=?,`max_out`=?";
}
return 1;