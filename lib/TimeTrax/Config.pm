package TimeTrax::Config;
use v5.10;
require File::Spec;
use YAML qw{LoadFile DumpFile};

# ABSTRACT: TimeTrax Config how to interface with the config file

sub new {
  my $class = shift;
  my $self  = {file => File::Spec->rel2abs( shift 
                                         || $ENV{TIMETRAX_CONFIG} 
                                         || File::Spec->catfile($ENV{HOME}, '.timetrax.yaml' )
                                          )
              };
  die 'TimeTrax::Config requires a readable file' unless -r $self->{file};
  $self->{conf} = LoadFile($self->{file});
  return bless $self, $class;
}

sub report {
  my $self = shift;
  my $data = { %{ $self{data} } }; # CLONE
  foreach( @ARGV ) {
    die qq{ $_ was not found in your config file } unless $data->{$_};
    $data = $data->{$_};
  }
  use Data::Dumper;
  warn Dumper($data); # TODO this should be nicer
}

sub set {
  my ($self, $project, $key, $value) = @_;
  $self{data}{$project}{$key} = $value;
  say 'updated' if DumpFile($self{file}, $self{data});
}


our $AUTOLOAD; # need to scope AUTOLOAD
sub AUTOLOAD {
  my $self  = shift;
  my ($key) = $AUTOLOAD =~ m/.*::(.*?)$/; #pluck just the method name
  $self->{$key} = shift
    if @_;
  #die qq{$key does not exist in $self} unless (ref($self) && $self->{$key}) || $self->can($key) ;
  return $self->{$key};
}

1;
