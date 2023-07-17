use strict;
use warnings;

use lib qw{ . lib};

use Test::More tests => 6;

use Data::Dumper;
use Date::Format;
use JSON::PP;

use UnitTestSetup qw(:all);

BEGIN {
  {
    no strict 'refs';  ## no critic

    *{'HTTP::Request::new'}     = sub { bless {}, 'HTTP::Request'; };
    *{'HTTP::Request::request'} = sub { HTTP::Response->new; };

    *{'HTTP::Response::new'}        = sub { bless {}, 'HTTP::Response'; };
    *{'HTTP::Response::is_success'} = sub { TRUE; };

    *{'LWP::UserAgent::new'}     = sub { bless {}, 'LWP::UserAgent'; };
    *{'LWP::UserAgent::request'} = sub { HTTP::Response->new; };

    ## use critic
  }

  use Module::Loaded;

  mark_as_loaded(HTTP::Request);
  mark_as_loaded(HTTP::Response);
  mark_as_loaded(LWP::UserAgent);

  use_ok('Amazon::Credentials');
}

# +-------------------------+
# | MAIN SCRIPT STARTS HERE |
# +-------------------------+

init_test;

my $creds = Amazon::Credentials->new(
  { profile => 'bar',
    order   => [qw/file/],
    debug   => $ENV{DEBUG} ? 1 : 0,
  }
);

ok( ref($creds), 'find credentials - file' );

my %new_creds = (
  aws_access_key_id     => 'biz-aws-access-key-id',
  aws_secret_access_key => 'biz-aws-secret-access-key',
  token                 => 'biz',
  expiration            => format_time( -5 + FIVE_MINUTES ),

);

$creds->set_credentials( \%new_creds );

ok( $creds->is_token_expired, 'is_token_expired() - yes?' )
  or diag( Dumper [ $creds->get_expiration(), format_time() ] );

# is_expired() should be true 5 or less minutes before expiration time
$creds->set_expiration( format_time( 5 + FIVE_MINUTES ) );

ok( !$creds->is_token_expired, 'is_token_expired() - no?' )
  or diag( Dumper [ $creds->get_expiration(), format_time ] );

# expire token
$creds->set_expiration( format_time( -5 + FIVE_MINUTES ) );

ok( $creds->is_token_expired, 'is_token_expired() - reset as expired' )
  or diag( Dumper [ $creds->get_expiration(), format_time ] );

$new_creds{AccessKeyId}     = 'buz-aws-access-key-id';
$new_creds{Expiration}      = format_time( 5 + FIVE_MINUTES );
$new_creds{SecretAccessKey} = 'buz-aws-secret-access-key';
$new_creds{Token}           = 'buz';

my $content = encode_json( \%new_creds );

{
  no strict 'refs';  ## no critic

  my $response = [ 'role', $content ];
  *{'HTTP::Response::content'} = sub { shift @{$response}; };
}

$creds->set_role('role');

local $ENV{AWS_EC2_METADATA_DISABLED} = 'false';

$creds->refresh_token;

ok( !$creds->is_token_expired, 'refresh_token()' )
  or diag( Dumper [ $creds->get_expiration(), format_time ] );

1;
