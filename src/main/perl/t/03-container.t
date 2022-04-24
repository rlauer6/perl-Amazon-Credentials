use strict;
use warnings;

use Test::More tests => 4;
use JSON::PP;

use Data::Dumper;
use UnitTestSetup;

BEGIN {
  {
    no strict 'refs';

    *{'HTTP::Request::new'}       = sub { bless {}, 'HTTP::Request'; };
    *{'HTTP::Request::request'}   = sub { new HTTP::Response; };
    *{'HTTP::Request::header'}    = sub { };
    *{'HTTP::Request::as_string'} = sub { };

    *{'HTTP::Response::new'}        = sub { bless {}, 'HTTP::Response'; };
    *{'HTTP::Response::is_success'} = sub { 1; };

    *{'LWP::UserAgent::new'}     = sub { bless {}, 'LWP::UserAgent'; };
    *{'LWP::UserAgent::request'} = sub { new HTTP::Response; };
  }

  use Module::Loaded;

  mark_as_loaded(HTTP::Request);
  mark_as_loaded(HTTP::Response);
  mark_as_loaded(LWP::UserAgent);

  use_ok('Amazon::Credentials');
} ## end BEGIN

# +-------------------------+
# | MAIN SCRIPT STARTS HERE |
# +-------------------------+

# could be anything...but must exist
$ENV{AWS_CONTAINER_CREDENTIALS_RELATIVE_URI} = 'blah';
$ENV{ECS_CONTAINER_METADATA_URI_V4}          = 'blah';

my %container_creds;

$container_creds{AccessKeyId}     = 'buz-aws-access-key-id';
$container_creds{SecretAccessKey} = 'buz-aws-secret-access-key';
$container_creds{Token}           = 'buz';
$container_creds{Expiration}      = format_time( 5 + FIVE_MINUTES );

my $response = JSON::PP->new->utf8->pretty->encode( \%container_creds );

my @order = ('container');

my %expected_creds;

$expected_creds{aws_access_key_id}     = 'buz-aws-access-key-id';
$expected_creds{aws_secret_access_key} = 'buz-aws-secret-access-key';
$expected_creds{token}                 = 'buz';
$expected_creds{expiration}            = format_time( 5 + FIVE_MINUTES );
$expected_creds{profile}               = undef;
$expected_creds{source}                = 'IAM';
$expected_creds{container}             = 'ECS';

{
  no strict 'refs';

  *{'HTTP::Response::content'} = sub { return $response; };
}

my $creds = Amazon::Credentials->new(
  { order => \@order,
    debug => $ENV{DEBUG} ? 1 : 0,
  }
);

isa_ok( $creds, 'Amazon::Credentials' );

ok( ref($creds), 'find credentials - container' );

my @credential_keys = qw{
  aws_access_key_id
  aws_secret_access_key
  token
  expiration
  profile
  source
  container
};

my %returned_creds;

if ( ref($creds) ) {
  foreach my $k (@credential_keys) {
    $returned_creds{$k} = $creds->can("get_$k")->($creds);
  }
}

is_deeply( \%expected_creds, \%returned_creds, 'got expected creds' );
