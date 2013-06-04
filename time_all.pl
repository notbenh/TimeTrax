#!/usr/bin/env perl 
use strict;
use warnings;
use File::Slurp;
use Date::Parse;
use List::Util qw{max sum};
use List::MoreUtils qw{natatime};
use Data::Dumper; sub D(@){warn Dumper(@_)}

sub note (@) {
  sprintf q{[%s] %s}, join( q{ }, split /\s+/, qx{date} ), join q{ }, @_;
}

sub parse ($) { 
  my ($time,$stuff) = shift =~ m{\[(.*?)\] (.*)};
  my ($proj,$note)  = split /\s+/, $stuff,2;
  return ($time,$proj,$note);
};

sub stime ($) { 
   my $in = shift;
   my $h = int($in);
   my $m = int(60 * ($in-$h));
   return sprintf q{%d:%02d}, $h, $m;
};

my $file = $ENV{TIMETRAX_FILE} || sprintf( q{%s/.timetrax}, $ENV{HOME} );

if (scalar(@ARGV)) {
   write_file( $file, {append => 1}, note(@ARGV,"\n"));
   print qq{Noted\n};
}
elsif ( -e $file) {
  my @data = grep{m/^./} read_file($file);
  push @data, note(automated => 'now'); # the placeholder for now so that we can get a running total

  my $report = {};
  my $total = 0;
  print "\nEVENT LOG:\n";
  for ( 0..scalar(@data)-2 ) { #this is look ahead, but we add a marker for now, we don't need to bother with that so we -2 to skip that
     print $data[$_];
     my ($tc,$pc,$nc) = parse( $data[$_] );
     my ($tn,$pn,$nn) = parse( $data[$_+1] );
     my $spend        = (str2time($tn) - str2time($tc))/60/60;
     #D {$_ => {$data[$_] => [$tc,$pc,$nc], $data[$_+1] => [$tn,$pn,$nn]},spent => $spend};
     $total+= $spend;
     my @topics = ($pc);
     push @topics,$pc while $pc =~ s/(.*):.*/$1/;
     $report->{$_}  += $spend for @topics;
  } 
 
  print "\nSUMMARY REPORT:\n";
  my $length = max( map{length($_)} keys %$report );
  printf qq{%*s : %s (%5.2f%%)\n}, -$length, $_, stime $report->{$_}, ($report->{$_}/$total)*100 
    for reverse sort {$report->{$a} <=> $report->{$b}} keys %$report ;

  printf qq{%*s : %s\n}, $length, 'TOTAL', stime $total ;
}
else {
  # TODO: this should create the file rather than do nothing
   printf qq{%s does not exist\n}, $file;
}


