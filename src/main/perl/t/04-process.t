use strict;
use warnings;

use Test::More tests => 5;

use UnitTestSetup;
use Data::Dumper;
use Cwd;

BEGIN {
  use_ok('Amazon::Credentials');
}

my $process = getcwd . '/get-creds-from-process';

BAIL_OUT('cannot execute $process')
  if !-x $process;

init_test( test => '04-process.t', vars => { process => $process } );

my $creds = Amazon::Credentials->new(
  { profile => 'foo',
    order   => [qw/file/],
    debug   => $ENV{DEBUG} ? 1 : 0
  }
);

ok( ref $creds, 'find credentials' );

like( $creds->get_aws_access_key_id, qr/^[A-Z0-9]+$/, 'aws_access_key_id' );

like( $creds->get_aws_secret_access_key,
  qr/^[a-zA-Z0-9\+\/]+$/, 'aws_secret_access_key' )
  or diag( Dumper $creds);

like( $creds->get_token, qr/^[a-zA-Z0-9\+\/=]+$/xsm, 'token' )
  or diag( Dumper $creds);
