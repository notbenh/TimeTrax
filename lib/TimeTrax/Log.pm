package TimeTrax::Log;
use v5.10;
use File::Slurp;
use List::Util qw{max sum};
use Date::Parse;
use Data::Dumper;

# ABSTRACT: TimeTrax::Log all about that Log file

sub new {
  my $class = shift;
  my $self  = {file => File::Spec->rel2abs( shift 
                                         || $ENV{TIMETRAX_FILE} 
                                         || File::Spec->catfile($ENV{HOME}, '.timetrax.log' )
                                          )
              };
  die 'TimeTrax::Log requires a readable file' unless -r $self->{file};
  return bless $self, $class;
}
sub file { shift->{file} };

sub parse{
  my $self = shift;
  my $project_filter = shift;
  my @lines = ( read_file($self->{file})
              , _format(qw{automated NOW()}) 
              );

  for( my $i = 0; $i < scalar(@lines)-1; $i++) { # the -1 is due to us not wanting to parse the automated 'now' entry
    my ($date,$proj,$task) = $lines[$i] =~ m/^\[(.+?)\] \[(.+?)\] (.*)$/;
    my ($date_next) = $lines[$i+1] =~ m/\[(.+?)\]/; # grab only the next date
    $lines[$i] = { line => $lines[$i]
                 , project => $proj
                 , date => $date
                 , date_parsed => [strptime($date)]
                 , date_stamp  => str2time($date)
                 , date_next => $date_next
                 , seconds_spent => (str2time($date_next) - str2time($date))
                 , task => $task
                 } ;
  }
  pop @lines; # pull out our automated addition
  return $project_filter ? grep{$project_filter eq $_->{project}} @lines
                         : @lines; 
}

sub _format {
  sprintf qq{[%s] [%s] %s\n}
        , do{$_=qx{date}; chomp; $_}
        , @_
}


sub set {
  my $self = shift;
  say 'noted' if append_file( $self->{file}, _format(@_) );
}

1;
