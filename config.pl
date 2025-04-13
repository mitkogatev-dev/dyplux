#!/usr/bin/perl -w

################
#source: https://vocal.com/resources/development/how-can-i-implement-a-configuration-file-for-a-perl-script/
##########
package Cfg;

use strict;
use FindBin 1.51 qw( $RealBin );
my $dir=$RealBin;

#
# Default configuration
my %config;
my %sql_config = (
    sql_host => "127.0.0.1",
    sql_port => "3306",
    sql_user => "myuser",
    sql_pass => "fakepassword",
    sql_db => "graphs"
);
my %influx_config =(
    influx_url => "http://127.0.0.1",
    influx_port => "8086",
    influx_token => "InFluXtOkeN(or)Fake==",
    influx_bucket => "traffic",
    influx_query_method => "js" #curl || js
);
my %debug_config = (
    debug_enabled => 1,
    debug_file => "$dir/debug.log",
    debug_cgi => 1
);
my %project = (
    author => "mitkogatev",
    name => "DyPLux",
    description => "Dygraphs.js + InfluxDB + Perl + MariaDB = Traffic graphs",
);
##### COMBINE 
# %hash1 = (%hash1, %hash2)
#@hash1{keys %hash2} = values %hash2;
%config = (%sql_config,%influx_config,%debug_config);

my ($config_file)="$dir/config.cfg" || ""; #! can not comment lines in cfg file !!!
#
my ($db_pass_file)="/use/full/path/to/.junk_file" || ""; #todo: use separate file with db passwords
#
# Read in a config file and build the config hash

if (open my $cfg_file, "< $config_file") {
    while (my $line = <$cfg_file>) {
        if ($line =~ /(\w+)[ \t]*=[ \t]*(.*)/) {
            #eg: db_pass=pass
            #db_pass = pass
            $config{$1} = $2;
        }
    }
    close $cfg_file;
}

sub print_config{
    foreach my $key (keys %config){
        print "$key = $config{$key}\n";
    }
};
sub get_config{
    return \%config;
}
sub get_debug{
    if ($config{debug_enabled}){
        open (my $debug_fh,">>", $config{debug_file}) or die $!;
        return $debug_fh;
    }
    return 0;
}

return 1;