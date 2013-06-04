#!/usr/bin/env perl 
use strict;
use warnings;
use File::Slurp;
use Date::Parse;
use List::Util qw{max sum};
use List::MoreUtils qw{natatime};
use Data::Dumper; sub D(@){warn Dumper(@_)}
our $VERSION=1.5;

sub note (@) {
  sprintf q{[%s] %s}, join( q{ }, split /\s+/, qx{date} ), join q{ }, @_;
}

sub parse ($) { 
  my ($time,$stuff) = shift =~ m{\[(.*?)\] (.*)};
  my ($proj,$note)  = split /\s+/, $stuff,2;
  return ($time,$proj,$note);
};

my $month_i= 1;
my %months = map{$_=>$month_i++} qw{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec};
sub d8 ($){
  # translate Fri May 31 17:25:52 PDT 2013 => 20130531
  $_ = shift;
  my ($y,$m,$d) = (split)[5,1,2];
  return sprintf q{%04d%02d%02d}, $y, $months{$m}, $d;
}
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
  my $data = {};
  # parse the existing log file in to a big hash
  for my $record ( grep{m/^./} read_file($file), note off => "now\n" ){
    my ($time,$project,$note) = parse $record;
    my $d8 = d8 $time;
    $data->{$d8}->{display}= join ' ', (split ' ', $time)[0,1,2] unless $data->{$d8}->{display};
    my @projects = ($project);
    push @projects,$project while $project=~ s/(.*):.*/$1/;
    push @{$data->{d8 $time}->{log}}
       , { time => $time
         , utime => str2time($time)
         , projects => \@projects
         , note => $note
         , record => $record
         };
  }

  # add in start/end day markers so the math works out
  # then parse over the day
  for my $d8 ( sort keys %$data) {
    my $log = $data->{$d8}->{log};
    next unless $log && @$log;
    my $fmt = $log->[0]->{time};
    $fmt =~ s/\d\d:\d\d:\d\d/%s/;
    my $start = sprintf $fmt, '00:00:00';
    my $end   = sprintf $fmt, '23:59:59';
    unshift @$log, {projects => ['off'], time => $start, utime => str2time($start), note => 'start of day', record => qq{[$start] off start of day\n}};
    push    @$log, {projects => ['off'], time => $end  , utime => str2time($end),   note => 'end of day'  , record => qq{[$end] off end of day\n}};

    my $report = {};
    my $total = 0;
    print "\nEVENT LOG:\n";
    for ( 0..($#$log -1) ) { #this is look ahead, but we add a marker for now, we don't need to bother with that so we -2 to skip that
      my ($THIS,$NEXT) = ($log->[$_], $log->[$_+1]);
       print $THIS->{record};
       my $spend = ($NEXT->{utime} - $THIS->{utime})/60/60;
       $total += $spend;
       $report->{$_} += $spend for @{$log->[$_]->{projects}}
    } 
    print $log->[-1]->{record}; # for completeness

    print "\nSUMMARY REPORT:\n";
    my $length = max( map{length($_)} keys %$report );
    printf qq{%*s : %5s (%5.2f%%)\n}, -$length, $_, stime $report->{$_}, ($report->{$_}/$total)*100 
      for reverse sort {$report->{$a} <=> $report->{$b}} keys %$report ;

    # now that each day is accounted for this is always 23:59
    #printf qq{%*s : %s\n}, $length, 'TOTAL', stime $total ;
    print "\n"; # end of day spacing
  }

}
else {
  # TODO: this should create the file rather than do nothing
   printf qq{%s does not exist\n}, $file;
}

__END__

=head1 SUMMARY

This is a stupid simple time tracking script. It helps make my life a
little better.

=head1 EXAMPLE

   > TIMETRAX_FILE=/tmp/trax time.pl testing is this thing on?
  Noted
   > TIMETRAX_FILE=/tmp/trax time.pl confirm it is
  Noted
   > TIMETRAX_FILE=/tmp/trax time.pl

  EVENT LOG:
  [Mon Jun 3 00:00:00 PDT 2013] off start of day
  [Mon Jun 3 21:10:12 PDT 2013] testing is this thing on?
  [Mon Jun 3 21:10:38 PDT 2013] confirm it is
  [Mon Jun 3 21:10:47 PDT 2013] off now
  [Mon Jun 3 23:59:59 PDT 2013] off end of day

  SUMMARY REPORT:
  off     : 23:59 (99.96%)
  testing :  0:00 ( 0.03%)
  confirm :  0:00 ( 0.01%)

=head1 SETUP

By default this expects to be able to write to ~/.timetrax though as
shown above in the example you can override this default with an
enviroment variable of TIMETRAX_FILE. Though with the way that the
report is inteneded to be processed it is recommend that you use only
one file to store the log.

Once this is done copy time.pl to some where in your path and enjoy!

=head1 SYNTAX

Anything passed via the command line is taken by time.pl as input to be
logged to your file. The first 'word' is intended to be the project you
are working on. Thus in the example you will note that the first action
was in the 'testing' project  The second is part of the 'confirm'
project. These are used in the aggrigaions in the SUMMARY REPORT.

If time.pl is called with out any input you get the report and nothing
is logged to the file. Though to make the math work out there is an
entry added for 'now' in the 'off' project. This allows you to get the
current time you have spent on what ever the last action is rather then
assume that you will be doing this for the rest of the day. 

=head1 WORKFLOW

Because this is really just tracking context changes the idea it to make
a note of any change at the time that it happens. Thus you will want to
mark that you are going to preform an action, then act. When you are
done then note what you are planning on doing next, or mark that you are
off. Thus all the slack time will be culled in to the same place.

Multiple days are grouped accordingly.

=head1 CODESMELL

Currently the code is a mess. This works for me but it is not really
ideal. I have a few ideas on ways that I want to improve things though
again as this is working for me who knows how much progress I will
really make on this. Feel free to fork and play!

=head1 TODOS

As I think of ideas I will log them in the issue tracker, feel free to
do the same.

