use strict;
use warnings;

use lib qw{ . lib};

use Test::More tests => 5;

use UnitTestSetup qw(:all);

use Data::Dumper;
use Cwd;

BEGIN {
  use_ok('Amazon::Credentials');
}

my $process = getcwd . '/get-creds-from-process';

if ( !-x $process ) {
  BAIL_OUT("cannot execute $process");
}

init_test( test => '04-process.t', vars => { process => $process } );

my $creds = Amazon::Credentials->new(
  { profile => 'foo',
    order   => [qw/file/],
    debug   => $ENV{DEBUG} ? 1 : 0
  }
);

ok( ref $creds, 'find credentials' );

like(
  $creds->get_aws_access_key_id,
  qr/^[[:upper:][:digit:]]+$/xsm,
  'aws_access_key_id'
);

like(
  $creds->get_aws_secret_access_key,
  qr/^[[:lower:][:upper:][:digit:]+\/=]+$/xsm,
  'aws_secret_access_key'
) or diag( Dumper $creds);

like( $creds->get_token, qr/^[[:lower:][:upper:][:digit:]\/+=]+$/xsm,
  'token' )
  or diag( Dumper $creds);

1;
