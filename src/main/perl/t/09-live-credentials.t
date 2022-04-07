use strict;
use warnings;

use Test::More;

if ( !$ENV{AMAZON_CREDENTIALS_TEST_ALL} ) {
  plan skip_all => 'set AMAZON_CREDENTIALS_TEST_ALL to test in AWS';
}
else {
  plan tests => 2;
}

use Data::Dumper;
use Date::Format;
use English qw{ -no_match_vars };

use File::Path;
use JSON::PP;

use File::Temp qw/:mktemp/;

use_ok('Amazon::Credentials');

subtest 'get real credentials' => sub {
  my $creds = Amazon::Credentials->new;
  
  ok(defined $creds->get_aws_secret_access_key, 'got secret access key');
  ok(defined $creds->get_aws_access_key_id, 'got access key id');
}
  



