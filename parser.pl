#!/usr/bin/perl -w
use strict;
# use Data::Dumper qw( Dumper );
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;
my $dir=$RealBin;
my $debugFile = "$dir/debug.log";
# open (my $debug,">>", $debugFile) or die $!;
# my ($input)=\%main::input;

package Parser;
use Data::Dumper qw( Dumper );
#
#my ($input)=\%main::input;
#
sub to_kmg{
    my $num=shift;
    my $formatted="";
    my $kilo=1000;
    if (!$num){ return "-1"; }
    if($num < $kilo){
           $formatted=eval($num * 100) / 100;
        return int($formatted)."";
    }
    elsif($num >=$kilo && $num<($kilo*$kilo)){
        $formatted=eval($num/($kilo) * 100) / 100;
        return int($formatted)."K";
    }
    elsif($num >=($kilo*$kilo) && $num < ($kilo*$kilo*$kilo)){
        $formatted=eval($num/($kilo*$kilo) * 100) / 100;
        return int($formatted)."M";
    }
    elsif($num >=$kilo*$kilo*$kilo){
        $formatted=eval($num/($kilo*$kilo*$kilo) * 100) / 100;
        return int($formatted)."G";
    }
    #defaults to G 
    else {
        $formatted=eval($num/($kilo*$kilo*$kilo) * 100) / 100;
        return int($formatted)."G";
    }
    # return -1;
}
sub from_kmg{
    my $str=shift;
    my $kilo=1000;

    if($str !~ /[A-Z]/i){
        return eval($str);
    }
    my $letter=uc(chop $str);
    if("K" eq $letter){
        return $kilo * $str;
    }
    elsif("M" eq $letter){
        return $kilo * $kilo * $str;
    }
    elsif("G" eq $letter){
        return $kilo * $kilo * $kilo * $str;
    }
    else{
        return $kilo * $kilo * $kilo * $str;
    }
    return 0;
}


return 1;