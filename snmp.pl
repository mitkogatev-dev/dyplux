#!/usr/bin/perl -w
use strict;
use Data::Dumper qw( Dumper );
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
my $dir=$RealBin;
#

package Snmp;
use Net::SNMP qw(:snmp);
#require "$dir/../func.pl";
require "$dir/strings.pl";

#
my $sys_oid="1.3.6.1.2.1.1.1";

my $ifname_oid="1.3.6.1.2.1.31.1.1.1.1";
my $ifalias_oid="1.3.6.1.2.1.31.1.1.1.18";
my $ifdescr_oid="1.3.6.1.2.1.2.2.1.2";
my $ifstate_oid="1.3.6.1.2.1.2.2.1.8";
my $ifspeed_oid="1.3.6.1.2.1.31.1.1.1.15";
my $cmd="snmpbulkwalk -O0sUXQ -v2c -Cc -c ";

sub open_session{
    my ($session, $error) = Net::SNMP->session(
   -hostname    => shift || 'localhost',
   -community   => shift || 'public',
   -version     => 'snmpv2c',
);
 
if (!defined $session) {
   printf "ERROR: %s.\n", $error;
   exit 1;
}
return $session;
}
sub test_device{
    my($ip,$community)=@_;
    my $session=open_session($ip,$community);
    my $table=$session->get_table($sys_oid);
die return Strings::add_dev_form() . "err:".$session->error unless(defined $table);
$session->close();
    #  return $table->{$sys_oid.".0"};
     return Strings::add_dev_form("ok") . "<br>".$table->{$sys_oid.".0"};

    # return Strings::error();
}
sub get_interfaces{
    my ($ip,$community)=(shift,shift);
my $session=open_session($ip,$community);

my $table=$session->get_table($ifname_oid);
die return "err:".$session->error unless(defined $table);
my $alias=$session->get_table($ifalias_oid);
my $state=$session->get_table($ifstate_oid);

my @ports;
my $i=0;
my $result;
foreach my $key ( sort keys %{ $table } ) {
my ($junk,$index)=split(/$ifname_oid./,$key);
#print "ifindex=$index value=$result->{$key}\n";

push(@ports,{
    ifindex =>$index,
    ifname=>$table->{$key},
    port_number=>$i+1,
    port_name =>$alias->{"$ifalias_oid.$index"},
    ifstate =>$state->{"$ifstate_oid.$index"}
    });
$i++;
}
#my @sorted=sort{lc($a) cmp lc($b)} @ports;

#$result->{snmp_ports}=\@ports;
#return $result;
return \@ports;
}
return 1;