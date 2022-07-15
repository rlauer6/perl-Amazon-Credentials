use strict;
use warnings;

use lib qw{. lib};

use Test::More tests => 5;
use Test::Output;

use UnitTestSetup;

use Data::Dumper;
use English qw{ -no_match_vars };

BEGIN {
  use_ok('Amazon::Credentials');
} ## end BEGIN

my $creds;

init_test;

$creds = eval {
  Amazon::Credentials->new(
    { order => 'env',
      debug => $ENV{DEBUG} ? 1 : 0,
    }
  );
};

like( $EVAL_ERROR, qr/^no credentials available/, 'raise_error => 1' )
  or BAIL_OUT($EVAL_ERROR);

$ENV{AWS_ACCESS_KEY_ID}     = 'AKIexample';
$ENV{AWS_SECRET_ACCESS_KEY} = '599797945475eefadfd';

$creds = eval {
  Amazon::Credentials->new(
    { order => 'env',
      debug => $ENV{DEBUG} ? 1 : 0,
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
