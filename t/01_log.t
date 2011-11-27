#!/usr/bin/env perl 
use strict;
use warnings;

use Test::Most qw{no_plan};
require_ok q{TimeTrax::Log};
can_ok q{TimeTrax::Log}, qw{
  parse
  set
};

dies_ok {TimeTrax::Log->new('no_file_here.log')} 
        q{dies correctly if passed a non existant file};

# TODO this should be handled cleanly?
my $test_file = './config.log';
unlink $test_file if -r $test_file; # seems things failed to cleanup
`touch $test_file`;

ok my $c = TimeTrax::Log->new($test_file), qw{new};
eq_or_diff [$c->parse], [], q{blank parse via parse};

use File::Slurp;
append_file($c->{file}, qq{$_\n}) for q{[Fri Aug 12 11:12:07 PDT 2011] [-] zzz}
                                , q{[Sat Aug 13 23:41:44 PDT 2011] [ode] CSS mockup}
                                , q{[Sun Aug 14 00:58:05 PDT 2011] [-] bed}
                                , q{[Sun Aug 14 09:05:57 PDT 2011] [OST] grading}
                                , q{[Sun Aug 14 10:46:25 PDT 2011] [-] internet}
                                , q{[Sun Aug 14 15:26:27 PDT 2011] [ode] CSS builder}
                                , q{[Sun Aug 14 17:35:23 PDT 2011] [-] stuff}
                                ;

ok $c->set(test => q{something goes here}), qw{set};

eq_or_diff scalar( $c->parse )         , 8, q{there are 8 tasks};
eq_or_diff scalar( $c->parse(q{test}) ), 1, q{there is only be one test task};

END{
print qx{more $test_file}; # debugging
unlink $test_file;
};
