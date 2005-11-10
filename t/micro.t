#!perl

use strict;
use warnings;

use Test::More 'no_plan';
use Params::Validate::Micro qw(:all);
use Params::Validate qw(:types);

sub micro_is {
  is_deeply(
    { micro_translate(shift) },
    shift,
    shift,
  );
}

eval {
  micro_translate("")
};
like($@, qr/does not appear to be a micro-spec/,
     "empty param string");

micro_is(
  q{$text},
  { text => { type => SCALAR } },
  'single scalar',
);

micro_is(
  q{@arr; %hash},
  {
    arr => { type => ARRAYREF },
    hash => { type => HASHREF, optional => 1 },
  },
  'array and optional hash',
);

eval {
  micro_translate(q{$foo; $bar; $baz});
};
like($@, qr/multiple semicolons/,
     "multiple semicolons");

eval {
  micro_validate(
    [ foo => 1 ],
    '$foo; $bar',
  );
};
is($@, "", "validate with optional");

eval {
  micro_validate(
    [ foo => 1 ],
    '$foo',
    {
      foo => {
        callbacks => {
          'more than 1' => sub {
            shift > 1
          },
        },
      },
    },
  );
};
like($@, qr/did not pass.+more than 1/,
     "validate with extra");
