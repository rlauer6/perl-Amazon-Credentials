use strict;
use warnings;

use lib qw{ . lib};

use Test::More;

if ( !$ENV{AMAZON_CREDENTIALS_TEST_ALL} ) {
  plan skip_all => 'set AMAZON_CREDENTIALS_TEST_ALL to test in AWS';
} ## end if ( !$ENV{AMAZON_CREDENTIALS_TEST_ALL...})
else {
  plan tests => 5;
} ## end else [ if ( !$ENV{AMAZON_CREDENTIALS_TEST_ALL...})]

use Data::Dumper;

use_ok('Amazon::Credentials');

my $creds = Amazon::Credentials->new( order => 'role', imdsv2 => 1 );

ok( $creds->get_imdsv2_token, 'imdsv2 - retrieved token' )
  or diag( Dumper $creds);

ok( $creds->get_aws_access_key_id, 'imdsv2 - retrieved access key' )
  or diag( Dumper $creds);

ok( $creds->get_aws_secret_access_key,
  'imdsv2 - retrieved secret access key' )
  or diag( Dumper $creds);

my $new_creds = Amazon::Credentials->new;

ok(
  $new_creds->get_aws_access_key_id && $new_creds->get_aws_secret_access_key,
  'no imdsv2'
) or diag($new_creds);
