use strict;
use warnings;

use Test::More tests => 5;

use File::Temp qw/:mktemp/;
use File::Path;
use Data::Dumper;
use Cwd;

BEGIN {
  use_ok('Amazon::Credentials');
}

my $home = mkdtemp('amz-credentials-XXXXX');

my $config_file = eval {
  mkdir "$home/.aws";

  open( my $fh, '>', "$home/.aws/config" )
    or BAIL_OUT('could not create temporary config file');

  my $process = getcwd . '/get-creds-from-process';

  BAIL_OUT('cannot execute $process')
    if !-x $process;

  print $fh <<eot;
[profile foo]
credential_process = $process
region = us-west-2

eot
  close $fh;

  return "$home/.aws/config";
};

$ENV{HOME}        = $home;
$ENV{AWS_PROFILE} = undef;

my $creds = Amazon::Credentials->new(
  { profile => 'foo',
    order   => [qw/file/],
    debug   => $ENV{DEBUG} ? 1 : 0
  }
);

ok( ref $creds, 'find credentials' );

is( $creds->get_aws_access_key_id, 'aws-access-key-id', 'aws_access_key_id' );

is( $creds->get_aws_secret_access_key,
  'aws-secret-access-key', 'aws_secret_access_key' );

is( $creds->get_region, 'us-west-2', 'region' );

END {
  eval { rmtree($home) if $home; };
}
