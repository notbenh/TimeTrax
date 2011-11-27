#!/usr/bin/env perl 
use strict;
use warnings;

use Test::Most qw{no_plan};
require_ok q{TimeTrax::Config};
can_ok q{TimeTrax::Config}, qw{
  report
  set
};

dies_ok {TimeTrax::Config->new('no_file_here.yaml')} 
        q{dies correctly if passed a non existant file};

# TODO this should be handled cleanly?
my $test_file = './config.yaml';
unlink $test_file if -r $test_file; # seems things failed to cleanup
`touch $test_file`;

ok my $c = TimeTrax::Config->new($test_file), qw{new};
eq_or_diff $c->report, {}, q{blank config via report};

ok $c->set(test => {name => 'test', type => 'hourly'}), qw{set multi};
ok $c->set(qw[test rate 45])                          , qw{set single};

eq_or_diff $c->report(qw{test rate}), 45 , q{report syntax for report};
dies_ok {$c->report(qw{squiggle})} q{report dies when passed an unkown key};

END{
print qx{more $test_file}; # debugging
unlink $test_file;
};
