use strict;
use warnings;

use Test::More tests => 5;

use Data::Dumper;
use English qw{ -no_match_vars };

use File::Temp qw/:mktemp/;
use File::Path;

BEGIN {
  use_ok('Amazon::Credentials');
}

my $home = mkdtemp('amz-credentials-XXXXX');

my $credentials_file = eval {
  mkdir "$home/.aws";

  open( my $fh, '>', "$home/.aws/credentials" )
    or BAIL_OUT('could not create temporary credentials file');

  print $fh <<eot;
[default]
profile = bar

[foo]
aws_access_key_id=foo-aws-access-key-id
aws_secret_access_key=foo-aws-secret-access-key

[bar]
aws_access_key_id=bar-aws-access-key-id
aws_secret_access_key=bar-aws-secret-access-key
region = us-east-1

eot
  close $fh;
  return "$home/.aws/credentials";
};

$ENV{HOME}        = $home;
$ENV{AWS_PROFILE} = undef;

my $creds = Amazon::Credentials->new(
  { order => [qw/file/],
    debug => $ENV{DEBUG} ? 1 : 0,
  }
);

ok( ref $creds, 'found credentials in file' );

is( $creds->get_aws_access_key_id,
  'bar-aws-access-key-id', 'default profile' );

$creds = eval {
  return Amazon::Credentials->new(order => 'blah');
};

like($EVAL_ERROR, qr/invalid/, 'only valid locations');

$creds = eval {
  return Amazon::Credentials->new(order => { this => 'blah' });
};

like($EVAL_ERROR, qr/array ref/, 'only array refs or scalars');

END {
  eval { rmtree($home) if $home; };
}
