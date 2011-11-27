package TimeTrax;
use strict;
use warnings;
require TimeTrax::Config;
require TimeTrax::Log;

# ABSTRACT: TimeTrax Core, all work happens from here

sub new {
  my $class = shift;
  return bless { config => TimeTrax::Config->new()
               , log    => TimeTrax::Log->new()
               }, $class;
};

sub config { shift->{config} };
sub log    { shift->{log   } };

1;
