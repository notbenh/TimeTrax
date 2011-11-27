package TimeTrax;
use Object::Tiny::XS qw{ config_file
                         config
                         log_file
                         log
                       };

# ABSTRACT: TimeTrax Core, all work happens from here

has config => 
  is => 'ro',
  isa => 'TimeTrax::Config',
  lazy => 1,
  default => sub{
    require TimeTrax::Config;
    TimeTrax::Config->new();
  },
;

has log => 
  is => 'ro', 
  isa => 'TimeTrax::Log',
  lazy => 1,
  default => sub{
    require TimeTrax::Log;
    TimeTrax::Log->new();
  },
;





1;


__END__
#!/usr/bin/perl 

use strict;
use warnings;
use File::Slurp;
use App::Rad qw{ConfigLoader TT};
use YAML qw{LoadFile DumpFile};
use Data::Dumper; sub D (@) {print Dumper(@_)};
use List::Util qw{max sum};
use Date::Parse;

#---------------------------------------------------------------------------
#  Setup, mostly documentation
#---------------------------------------------------------------------------
sub setup {
   my $c = shift;

   $c->stash->{config_file} = $ENV{TIMETRAX_CONFIG_FILE} || sprintf q{/home/%s/.timetrax.yaml}, $ENV{USER};
   $c->stash->{log_file} = $c->config->{log_file} || $ENV{TIMETRAX_FILE} || sprintf( q{/home/%s/.timetrax.log}, $ENV{USER} );

   for my $file (map{$c->stash->{$_}} qw{config_file log_file}) {
      `touch $file` unless -r $file;
   }

   $c->load_config($c->stash->{config_file});

   $c->register_commands( {
      config => 'interact with your config file.
                   If no options are given the current state of the config file is shown.
                   If options are given then they are saved to the config file and the new state is shown.
                    EXAMPLE: timetrax.pl config --email=ben@powells.com,amy@powells.com 
                   To delete set the value to blank: --email= ',
      add    => 'add an action to the log
                   --p => project 
                   EXAMPLE: timetrax.pl add --p=search building up new ui for bindings ',
      report => 'report overview of the time log, if no action is specified report is run.',
      email  => 'send log and report as an email. 
                  Requires "email" to be set in the config file.', 
      edit   => 'start up an editor to modify either the log or config
                  Will first look for an evn var EDITOR, you can also specify "editor" in the config file.
                  By default it picks log but if you "timetrax.pl edit config" then you will edit the config.',
   });
}

#set the report action as our default
sub default {
   shift->execute('report');
}

#---------------------------------------------------------------------------
#  Handle the config file
#---------------------------------------------------------------------------
sub config {
   my $c = shift;
   my $cf = $c->stash->{config_file};
   my $cfg = (-r $cf) ? LoadFile($cf) : {};
   if (scalar( keys %{ $c->options } || scalar(@{$c->argv}) ) ) {
      # edit mode
      # ADD OR EDIT VALUES
      foreach my $key ( keys %{$c->options} ) {
         $cfg->{$key} = $c->options->{$key};
      }

      # DELETE KEYS
      foreach my $key (map{s/--(.*)=/$1/;$_} grep{m/^--.*=$/} @{$c->argv} ) {
         delete $cfg->{$key};
      }

      `touch $cf` unless -e $cf;
      `chmod 666 $cf` unless -w $cf;
      DumpFile($cf, $cfg);
   } 
   
   my $fmt = sprintf q{   %% %ds : %%s}, max( map{length($_)} keys %$cfg);
   sprintf qq{YOUR CONFIG IS:\n%s},
           join qq{\n}, map{ sprintf $fmt, $_, $cfg->{$_} } keys %$cfg;
}

#---------------------------------------------------------------------------
#  Add to the log
#---------------------------------------------------------------------------
sub add {
   my $c = shift;
   my $add = join q{ },
                  sprintf( q{[%s]}, join q{ },split /\s+/, qx{date} ),
                  sprintf( q{[%s]}, $c->options->{project} || $c->options->{proj} || $c->options->{p} || 'N/A'),
                  join   ( ' ', grep {defined} @{ $c->argv } ),
                  "\n";
   write_file( $c->stash->{log_file},
               {append => 1},
               $add,
   );
   return q{Noted};
}

#---------------------------------------------------------------------------
#  Report the log
#---------------------------------------------------------------------------
#dispatch to the diffrent report types
sub report {
   my $c = shift;
   return (! defined $c->argv->[0] )     ? report_log($c)
        : ($c->argv->[0] eq 'timecard' ) ? report_timecard($c)
        :                                  report_log($c) ;
}


sub report_log {
   my $c = shift;
   warn q{REPORT LOG};

   my @data = read_file($c->stash->{log_file});
   push @data, sprintf( q{[%s] [automated] now }, join q{ },split /\s+/, qx{date} );

   sub parse ($) { shift =~ m{\[(.*?)\] (?:\[(.*?)\]\s?)?(.*)} };

   my $report = {};

   for ( 0..scalar(@data)-2 ) { #this is look ahead, but we add a marker for now, we don't need to bother with that so we -2 to skip that
      my ($tc,$pc,$nc) = parse( $data[$_] );
      my ($tn,$pn,$nn) = parse( $data[$_+1] );
      my $spend        = (str2time($tn) - str2time($tc))/60/60;
      $report->{$pc}  += $spend;
   } 

   sub stime ($) { 
      my $in = shift || 0;
      my $h = int($in);
      my $m = int(60 * ($in-$h));
      return sprintf q{%d:%02d}, $h, $m;
   };

   my $length = max( map{length($_)} keys %$report,'TOTAL' );
   my $total  = sum( values %$report);
   my @lines = map{ sprintf qq{%*s : %s (%5.2f%%)}, -$length, $_, stime $report->{$_}, ($report->{$_}/$total)*100;
                  } reverse sort {$report->{$a} <=> $report->{$b}} keys %$report ;
   
   return join qq{\n},
          @lines,
          sprintf qq{%*s : %s\n}, $length, 'TOTAL', stime $total ;
}

#---------------------------------------------------------------------------
#  Email the log
#---------------------------------------------------------------------------
sub email {
}

#---------------------------------------------------------------------------
#  Edit files
#---------------------------------------------------------------------------
sub edit {
   my $c = shift;
   my $type = $c->argv->[0] || '';
   my $cmd = join ' ', $ENV{EDITOR} || $c->config->{editor} || 'vim' , 
                       $c->stash->{ ($type eq 'config')   ? 'config_file' 
                                   :($type eq 'timecard') ? 'timecard_file' 
                                   :                        'log_file' 
                                  };
   exec($cmd);
}


#---------------------------------------------------------------------------
#  TIMECARD PROCESSING
#---------------------------------------------------------------------------
sub fetch_timecard {}
sub parse_timecard {}
sub report_timecard { warn 'TODO: make this';}

#---------------------------------------------------------------------------
#  GO 
#---------------------------------------------------------------------------
App::Rad->run();