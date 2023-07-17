use strict;
use warnings;

use lib qw{. lib};

use Test::More tests => 5;
use Test::Output;

use UnitTestSetup qw(init_test);

use Data::Dumper;
use English qw{ -no_match_vars };

BEGIN {
  use_ok('Amazon::Credentials');
}

my $creds;

init_test;

$creds = eval {
  Amazon::Credentials->new(
    { order => 'env',
      debug => $ENV{DEBUG} ? 1 : 0,
    }
  );
};

like( $EVAL_ERROR, qr/^no\scredentials\savailable/xsm, 'raise_error => 1' )
  or BAIL_OUT($EVAL_ERROR);

local $ENV{AWS_ACCESS_KEY_ID}     = 'AKIexample';
local $ENV{AWS_SECRET_ACCESS_KEY} = '599797945475eefadfd';

delete $ENV{AWS_REGION};
delete $ENV{AWS_DEFAULT_REGION};

$creds = eval {
  Amazon::Credentials->new(
    { order              => 'env',
      debug              => $ENV{DEBUG} ? 1 : 0,
      no_passkey_warning => 1,
    }
  );
};

is( $creds->get_aws_access_key_id,
  $ENV{AWS_ACCESS_KEY_ID}, 'get creds from env' );

is(
  $creds->get_aws_secret_access_key,
  $ENV{AWS_SECRET_ACCESS_KEY},
  'get creds from env'
);

is( $creds->get_region, 'us-east-2', 'default region from .aws/config' );

1;
