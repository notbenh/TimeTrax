package TimeTrax::Config;
use v5.10;
require File::Spec;
use YAML qw{LoadFile DumpFile};

# ABSTRACT: TimeTrax Config how to interface with the config file
use Data::Dumper;


sub new {
  my $class = shift;
  my $self  = {file => File::Spec->rel2abs( shift 
                                         || $ENV{TIMETRAX_CONFIG_FILE} 
                                         || File::Spec->catfile($ENV{HOME}, '.timetrax.yaml' )
                                          )
              };
  die 'TimeTrax::Config requires a readable file' unless -r $self->{file};
  $self->{conf} = LoadFile($self->{file});
  return bless $self, $class;
}
sub file { shift->{file} };
sub conf { shift->{conf} };

sub report {
  my $self = shift;
  my $data = { %{ $self->{conf} } }; # CLONE
  foreach( @_ ) {
    die qq{ $_ was not found in your config file } unless $data->{$_};
    $data = $data->{$_};
  }
  return $data; 
}

sub set {
  my $self = shift;
  $self{conf} = ref($_[1]) eq 'HASH' ? $self->set_multi(@_)
                                     : $self->set_single(@_)
                                     ; 
  say 'updated' if DumpFile($self->{file}, $self->{conf});
}

sub set_multi { # set(project=>{key => value, key=> value})
  my ($self,$project,$data) = @_;
  $self->{conf}{$project} = $data;
}
sub set_single { # set(project => key => value)
  my ($self,$project,$key,$value) = @_;
  $self->{conf}{$project}{$key} = $value;
}


1;
