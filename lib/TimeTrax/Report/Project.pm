package TimeTrax::Report::Project;
use strict;
use warnings;
use v5.10; 
use base qw{TimeTrax::Report};
use Data::Dumper;
require Math::Round;
use Try::Tiny;
require POSIX;

=pod

08/14/11,    grading, 3.50
11/14/11,    grading, 1.00
11/15/11,    grading, 0.75
11/16/11,    grading, 1.00
11/17/11,    grading, 1.25
11/18/11,    grading, 0.75
11/20/11,    grading, 1.00
11/21/11,    grading, 0.50
11/22/11,    grading, 0.50
11/23/11,    grading, 1.25
11/25/11,    grading, 0.50
103 day TOTAL: 12.00 @ $30.00/h ($360.00)

=cut

sub report {
  my $self = shift;
  my $project = shift;
  my $config;
  try   { $config = $self->config->report($project) }
  catch { $config = $self->config->report('default')};
  my $total= {};

  # tally up all the given tasks for a day, combining any duplicates
  foreach my $i ( $self->log->parse( $project ) ) {
    if ($i->{task} =~ m/----/ ) {
      $total={};
      next;
    }
    $i->{task} =~ s/^\s*//;
    $i->{task} =~ s/\s*$//;
    my $date = POSIX::strftime( "%D", map{$i->{date_parsed}->[$_]} 0..5 );
    $total->{ $date }->{ $i->{task} } += $i->{seconds_spent};
  }
  my $hours_total=0;
  my $output = '';
  sub YMD($) { my @d = split m{/}, shift; join '', @d[2,0,1] }
  my @dates  = sort{YMD $a <=> YMD $b} keys %$total;
  foreach my $date ( @dates ) {
    foreach my $task ( sort keys %{ $total->{$date} } ) {
      my $hours = Math::Round::nhimult($config->{round}, $total->{$date}->{$task}/60/60 );
      $hours_total += $hours;
      $output .= sprintf qq{%s, %s, % 2.2f\n}
                       , $date
                       , $task
                       , $hours
                       ;
    }
  }

  use Date::Parse;
  $output .= sprintf qq{%d DAY TOTAL: % 2.2f @ \$%d => \$%0.2f\n}
                   , ( str2time($dates[-1]) - str2time($dates[0]) )/60/60/24 # convert last - first to days
                   , $hours_total
                   , $config->{rate}
                   , ($hours_total * $config->{rate})
                   ;
  return $output;

}


1;
