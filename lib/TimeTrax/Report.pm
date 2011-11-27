package TimeTrax::Report;
use strict;
use warnings;
require TimeTrax::Config;
require TimeTrax::Log;

sub new {
  my $class = shift;
  return bless { config => TimeTrax::Config->new()
               , log    => TimeTrax::Log->new()
               }, $class;
}

sub config{ shift->{config} }
sub log{shift->{log}}

sub parse_seconds {
  my $self = shift;
  my $seconds = shift;
  return { hours   => int( $seconds/60/60 )
         , minutes => int( ($seconds % 60*60) /60 )
         , seconds => int( $seconds % 60 )
         };
}

sub sec2hm {
  my $self = shift;
  my $in = $self->parse_seconds(shift || 0);
  return sprintf q{%d:%02d}, $in->{hours}, $in->{minutes};
};

sub sec2hms {
  my $self = shift;
  my $in = $self->parse_seconds(shift || 0);
  return sprintf q{%d:%02d:%02d}, $in->{hours}, $in->{minutes}, $in->{seconds};
};

