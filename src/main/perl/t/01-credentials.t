use strict;
use warnings;

use lib qw{ . lib};

use Test::More tests => 7;

use Data::Dumper;
use English qw{ -no_match_vars };

use UnitTestSetup qw(:all);

BEGIN {
  use_ok('Amazon::Credentials');
}

init_test;

print {*STDERR} Dumper [ @ARGV, $PROGRAM_NAME ];

my $creds = eval {
  Amazon::Credentials->new(
    { order => [qw/file/],
      debug => $ENV{DEBUG} ? 1 : 0,
    }
  );
};

ok( $creds && ref($creds), 'find credentials' )
  or BAIL_OUT($EVAL_ERROR);

is( $creds->get_aws_access_key_id,
  'bar-aws-access-key-id', 'default profile' );

is( $creds->get_region, 'us-east-1', 'default region' );

$creds = Amazon::Credentials->new(
  { profile            => 'bar',
    order              => [qw/file/],
    region             => 'foo',
    no_passkey_warning => 1,
  }
);

is( $creds->get_aws_access_key_id,
  'bar-aws-access-key-id', 'retrieve profile' );

is( $creds->get_region, 'us-east-1', 'region' );

is( $creds->get_source, '.aws/credentials' )
  or diag( Dumper [$creds] );

1;
