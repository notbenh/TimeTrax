#!/usr/bin/env perl 
use strict;
use warnings;


use Test::Most qw{no_plan};

#-------------------------------------------------------------------------------
#  BUILD TEST FILE
#-------------------------------------------------------------------------------
require_ok q{TimeTrax::Log}; 

# TODO this should be handled cleanly?
our $test_file = './config.log';
unlink $test_file if -r $test_file; # seems things failed to cleanup
`touch $test_file`;

my $l = TimeTrax::Log->new($test_file), qw{new};
use File::Slurp;
append_file($l->{file}, qq{$_\n}) for q{[Fri Aug 12 11:12:07 PDT 2011] [project] task1}
                                    , q{[Sat Aug 13 23:41:44 PDT 2011] [project] task2}
                                    , q{[Sun Aug 14 00:58:05 PDT 2011] [-] bed}
                                    , q{[Sun Aug 14 09:05:57 PDT 2011] [project] task3}
                                    , q{[Sun Aug 14 10:46:25 PDT 2011] [-] break}
                                    , q{[Sun Aug 14 15:26:27 PDT 2011] [project] task4}
                                    , q{[Sun Aug 14 17:35:23 PDT 2011] [-] dinner}
                                    ;

$l->set(test => q{something goes here}), qw{set};

#-------------------------------------------------------------------------------
#  REPORT TESTS
#-------------------------------------------------------------------------------
$ENV{TIMETRAX_FILE} = $test_file;
require_ok q{TimeTrax::Report::All};
can_ok q{TimeTrax::Report::All}, qw{
  report
};

ok my $r = TimeTrax::Report::All->new;

use v5.10;
say $r->report;







#-------------------------------------------------------------------------------
#  CLEAN UP TEST FILE
#-------------------------------------------------------------------------------
END{
print qx{more $test_file}; # debugging
unlink $test_file;
};
