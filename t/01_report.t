#!/usr/bin/env perl 
use strict;
use warnings;

use Test::Most qw{no_plan};
require_ok q{TimeTrax::Report};
can_ok q{TimeTrax::Report}, qw{
  parse_seconds
  sec2hm
  sec2hms
};

eq_or_diff TimeTrax::Report::parse_seconds(3661)
         , { hours => 1
           , minutes => 1
           , seconds => 1
           }
         , q{parse_seconds};

is TimeTrax::Report::sec2hm (3661), '1:01'   , 'sec2hm';
is TimeTrax::Report::sec2hms(3661), '1:01:01', 'sec2hms';
