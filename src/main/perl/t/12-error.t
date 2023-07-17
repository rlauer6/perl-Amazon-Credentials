#!/usr/bin/env perl

use strict;
use warnings;

use lib qw{. lib};

use Test::More tests => 6;
use Test::Output;

use Data::Dumper;
use English qw( -no_match_vars );

use UnitTestSetup qw(:all);

BEGIN {
  use_ok('Amazon::Credentials');
}

init_test( test => '12-error.t' );

my $creds;

$creds = eval {
  Amazon::Credentials->new(
    { profile            => 'no profile',
      debug              => $ENV{DEBUG} ? 1 : 0,
      no_passkey_warning => 1,
    }
  );
};

like( $EVAL_ERROR, qr/^no\scredentials\savailable/xsm, 'raise_error => 1' )
  or BAIL_OUT($EVAL_ERROR);

stderr_like(
  sub {
    $creds = eval {
      Amazon::Credentials->new(
        { profile            => 'no profile',
          debug              => $ENV{DEBUG} ? 1 : 0,
          raise_error        => 0,
          no_passkey_warning => 1,
        }
      );
    }
  },
  qr/^no\scredentials\savailable/xsm,
  'no raise error, but print error'
);

ok( !$creds->get_aws_secret_access_key && !$EVAL_ERROR, 'raise_error => 0' )
  or BAIL_OUT( Dumper( [ $creds, $EVAL_ERROR ] ) );

stderr_is(
  sub {
    $creds = eval {
      Amazon::Credentials->new(
        { profile            => 'no profile',
          debug              => $ENV{DEBUG} ? 1 : 0,
          raise_error        => 0,
          print_error        => 0,
          no_passkey_warning => 1,
        }
      );
    }
  },
  q{},
  'no print error'
);

$creds = eval {
  return Amazon::Credentials->new(
    profile            => 'boo',
    no_passkey_warning => 1,
  );
};

like( $EVAL_ERROR, qr/could\snot\sopen/xsm, 'bad process' )
  or diag( Dumper ["$EVAL_ERROR"] );

1;
