use strict;
use warnings;

use lib qw{ . lib};

use Test::More;

if ( !$ENV{AMAZON_CREDENTIALS_TEST_ALL} ) {
  plan skip_all => 'set AMAZON_CREDENTIALS_TEST_ALL to test in AWS';
}
else {
  plan tests => 3;
}

use Data::Dumper;
use English qw{ -no_match_vars };

use JSON::PP;

use File::Temp qw/:mktemp/;

use_ok('Amazon::Credentials');

########################################################################
subtest 'get real credentials from role' => sub {
########################################################################
  if ( !$ENV{AWS_ROLE_NAME} ) {
    plan skip_all => 'no AWS_ROLE_NAME defined';
  }

  my $creds = Amazon::Credentials->new( order => ['role'] );

  ok( defined $creds->get_aws_secret_access_key, 'got secret access key' )
    or diag( Dumper $creds);

  ok( defined $creds->get_aws_access_key_id, 'got access key id' )
    or diag( Dumper $creds);

  ok( defined $creds->get_role, 'got role' )
    or diag( Dumper $creds);
};

########################################################################
subtest 'get real credentials from profile' => sub {
########################################################################
  if ( !$ENV{AWS_PROFILE} ) {
    plan skip_all => 'no PROFILE defined';
  }

  my $creds = eval {
    Amazon::Credentials->new(
      order => ['file'],
      debug => $ENV{DEBUG}
    );
  };

  ok( $creds, 'got credentials from file' )
    or BAIL_OUT($EVAL_ERROR);

  ok( defined $creds->get_aws_secret_access_key, 'got secret access key' )
    or diag( Dumper $creds);

  ok( defined $creds->get_aws_access_key_id, 'got access key id' )
    or diag( Dumper $creds);
};

1;
