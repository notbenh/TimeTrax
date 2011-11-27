#!/usr/bin/env perl 
use strict;
use warnings;
use feature qw{switch say};
require TimeTrax;

my $help = <<ENDHELP;

USEAGE: 

  timetrax.pl [ACTION] [OPTIONS]

ACTIONS:

  CONFIG:
  - config                   : list the entire state of the config file
  - config PROJECT           : list a specific project's config
  - config PROJECT KEY VALUE : set a specific key value for a project

  REPORTING:
  - (nothing)             : group all tasks       [TimeTrax::Report::All]
  - PROJECT               : project specific task [TimeTrax::Report::Project]
  - report TYPE [PROJECT] : use a specific report [TimeTrax::Report::\$TYPE]

  RECORD TASKS:
  - PROJECT TASK 

  UTIL:
  - last        : tail your log file
  - edit        : open the log file with \$ENV{EDITOR}
  - edit config : open the config file with \$ENV{EDITOR}

ENDHELP


my ($action) = shift @ARGV;

die $help if $action eq 'help';

my $tt = TimeTrax->new();
given( $action ) {
  when( 'last' ) { system q{tail}, $tt->log->file; }
  when( 'edit' ) { system $ENV{EDITOR}, @ARGV && $ARGV[0] eq 'config' 
                                      ? $tt->config->file
                                      : $tt->log->file
                                      ; 
                 }
  when('config') { scalar( @ARGV ) == 3 ? $tt->config->set(@ARGV)
                                        : $tt->config->report(@ARGV)
                 }
  when('report') { my $type  = shift @ARGV;
                   my $class = qq{TimeTrax::Report::$type};
                   eval qq{require $class};
                   say $class->new->report(@ARGV);
                 }
  default        { given( scalar(@ARGV) ) { 
                     when(0) { require TimeTrax::Report::All;
                               say TimeTrax::Report::All->new->report;
                             }
                     when(1) { require TimeTrax::Report::Project;
                               say TimeTrax::Report::Project->new->report(@ARGV);
                             }
                     when(3) { $tt->log->set(shift @ARGV, join ' ', @ARGV) }
                     default { die $help }
                   }
                 }
};


1;
