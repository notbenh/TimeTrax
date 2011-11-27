package TimeTrax::Report::All;
use strict;
use warnings;
use v5.10; 
use base qw{TimeTrax::Report};
use Data::Dumper;

sub report {
  my $self = shift;
  my $total={};
  foreach my $i ( $self->log->parse ) {
    $total->{$i->{project}} += $i->{seconds_spent};
  }

  my $format = sprintf q{%% %ds: %%s}
                     , length([sort{length($b) <=> length($a)} keys %$total]->[0]) # longest project name
                     ; 
  return join qq{\n}
            , map{ sprintf $format, $_, $self->sec2hm($total->{$_});
                 } sort { $total->{$a} <=> $total->{$b} } keys %$total ;
}


1;
