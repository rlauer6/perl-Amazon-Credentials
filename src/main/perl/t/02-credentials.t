use strict;
use warnings;

use Test::More tests => 6;

use Data::Dumper;
use Date::Format;
use File::Path;
use JSON::PP;

use File::Temp qw/:mktemp/;

use constant {
  ISO_8601_FORMAT => '%Y-%m-%dT%H:%M:%SZ',
  TRUE            => 1,
  FALSE           => 0,
  FIVE_MINUTES    => 5 * 60,
};

BEGIN {
  {
    no strict 'refs';

    *{'HTTP::Request::new'}     = sub { bless {}, 'HTTP::Request'; };
    *{'HTTP::Request::request'} = sub { new HTTP::Response; };

    *{'HTTP::Response::new'}        = sub { bless {}, 'HTTP::Response'; };
    *{'HTTP::Response::is_success'} = sub { TRUE; };

    *{'LWP::UserAgent::new'}     = sub { bless {}, 'LWP::UserAgent'; };
    *{'LWP::UserAgent::request'} = sub { new HTTP::Response; };
  }

  use Module::Loaded;

  mark_as_loaded(HTTP::Request);
  mark_as_loaded(HTTP::Response);
  mark_as_loaded(LWP::UserAgent);

  use_ok('Amazon::Credentials');
} ## end BEGIN

sub format_time {
  my ($time) = @_;

  return time2str( ISO_8601_FORMAT, time + $time, 'GMT' );
}

# +-------------------------+
# | MAIN SCRIPT STARTS HERE |
# +-------------------------+

my $home = mkdtemp('amz-credentials-XXXXX');

my $credentials_file = eval {
  mkdir "$home/.aws";

  open( my $fh, '>', "$home/.aws/credentials" )
    or BAIL_OUT('could not create temporary credentials file');

  print $fh <<eot;
[foo]
aws_access_key_id=foo-aws-access-key-id
aws_secret_access_key=foo-aws-secret-access-key

[bar]
aws_access_key_id=bar-aws-access-key-id
aws_secret_access_key=bar-aws-secret-access-key
eot
  close $fh;
  return "$home/.aws/credentials";
};

$ENV{HOME}        = $home;
$ENV{AWS_PROFILE} = undef;

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
  no strict 'refs';
  my $response = [ 'role', $content ];
  *{'HTTP::Response::content'} = sub { shift @{$response}; };
}

$creds->set_role('role');
$creds->refresh_token;

ok( !$creds->is_token_expired, 'refresh_token()' )
  or diag( Dumper [ $creds->get_expiration(), format_time ] );

END {
  eval { rmtree($home) if $home; };
}
