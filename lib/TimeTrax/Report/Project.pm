package TimeTrax::Report::Project;
use strict;
use warnings;
use v5.10; 
use base qw{TimeTrax::Report};
use Data::Dumper;
require Math::Round;

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
  my $config  = $self->config->report($project)
             || $self->config->report('default');
  my $total= {};
  
die Dumper($config);
  foreach my $i ( $self->log->parse( $project ) ) {
    $total->{ 
                       , Math::Round::nhimult(.25, ($data[$_+1][3] - $data[$_][3])/60/60 )

    
    
  }

  my $format = sprintf q{%% %ds: %%s}
                     , length([sort{length($b) <=> length($a)} keys %$total]->[0]) # longest project name
                     ; 
  return join qq{\n}
            , map{ sprintf $format, $_, $self->sec2hm($total->{$_});
                 } sort { $total->{$a} <=> $total->{$b} } keys %$total ;
}


1;
