use strict;
use warnings;

use Data::Dumper;
use Date::Format;
use English qw{ -no_match_vars };
use File::Path;
use File::Temp qw/:mktemp/;
use JSON::PP;
use MIME::Base64;

use Test::More tests => 10;

BEGIN {
  {
    no strict 'refs';

    *{'HTTP::Request::new'}     = sub { bless {}, 'HTTP::Request'; };
    *{'HTTP::Request::request'} = sub { new HTTP::Response; };

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

sub my_encrypt {
  my ( $str, $passkey ) = @_;
  return if !$str;

  my $sum = 0;

  foreach ( split //, $passkey ) {
    $sum += ord($_);
  }

  my @encrypted_str;
  foreach ( split //, $str ) {
    push @encrypted_str, $sum + ord($_);
  }

  return \@encrypted_str;
} ## end sub my_encrypt

sub my_decrypt {
  my ( $str, $passkey ) = @_;
  return if !$str;

  my @encrypted_str = @{$str};
  my $sum           = 0;

  foreach ( split //, $passkey ) {
    $sum += ord($_);
  }

  $str = '';

  foreach my $c (@encrypted_str) {
    $c -= $sum;
    $str .= chr($c);
  }

  return $str;
} ## end sub my_decrypt

sub check_credentials {
  my ( $creds, %unencrypted_creds ) = @_;

  my $retval = 0;

  if ( $creds->get_cache ) {
    foreach my $e (qw{ access_key_id secret_access_key }) {
      my $encrypted_value   = $creds->can( 'get__' . $e )->($creds);
      my $unencrypted_value = $creds->can( 'get_aws_' . $e )->($creds);

      $retval
        += !ok( $encrypted_value && $encrypted_value ne $unencrypted_value,
        'encrypted ok' );

      $retval
        += !ok( $unencrypted_value eq $unencrypted_creds{$e},
        'decrypted ok' );

    } ## end foreach my $e (qw{ access_key_id secret_access_key })
  } ## end if ( $creds->get_cache)
  else {
    foreach my $e (qw{access_key_id secret_access_key }) {
      $retval += !ok( !defined $creds->can( 'get__' . $e )->($creds),
        'credentials not cached' );
    }
  } ## end else [ if ( $creds->get_cache)]

  return !$retval;
} ## end sub check_credentials

my $home = mkdtemp("amz-credentials-XXXXX");

my $credentials_file = eval {
  mkdir "$home/.aws";

  open( my $fh, '>', "$home/.aws/credentials" )
    or BAIL_OUT("could not create temporary credentials file");

  print $fh <<eot;
[foo]
aws_access_key_id=foo-aws-access-key-id
aws_secret_access_key=foo-aws-secret-access-key

eot
  close $fh;
  "$home/.aws/credentials";
};

$ENV{HOME}        = "$home";
$ENV{AWS_PROFILE} = undef;

my %unencrypted_creds = (
  access_key_id     => 'foo-aws-access-key-id',
  secret_access_key => 'foo-aws-secret-access-key',
);

my $creds;

subtest 'obfuscation without Crypt::CBC' => sub {
  {
    use Devel::Hide qw{ -lexically -quiet Crypt::CBC };

    $creds = Amazon::Credentials->new( profile => 'foo', encryption => 1 );

    ok( !$creds->get_encryption, 'encryption disabled (no Crypt::CBC)' );

    ok(
      decode_base64( $creds->get__access_key_id ) eq
        $unencrypted_creds{access_key_id},
      'base64 encoded obfuscation'
    );

    ok(
      decode_base64( $creds->get__secret_access_key ) eq
        $unencrypted_creds{secret_access_key},
      'base64 encoded obfuscation'
    );

    check_credentials( $creds, %unencrypted_creds )
      or diag( Dumper [$creds] );
  }
};

subtest 'decrypt' => sub {
  $creds = Amazon::Credentials->new( profile => 'foo', encryption => 1 );

  ok( defined $creds->get_passkey, 'passkey created' );
  ok( $creds->get_encryption,      'encryption enabled' );

  check_credentials( $creds, %unencrypted_creds )
    or diag( Dumper [$creds] );
};

subtest 'rotate credentials' => sub {

  $creds = Amazon::Credentials->new( profile => 'foo', encryption => 1 );

  my $passkey     = $creds->get_passkey;
  my $new_passkey = $creds->rotate_credentials;

  ok( $new_passkey ne $passkey, 'passkey changed' )
    or diag( Dumper [ $passkey, $new_passkey ] );

  check_credentials( $creds, %unencrypted_creds )
    or diag( Dumper [$creds] );
};

subtest 'custom encryption/decryption' => sub {
  $creds = Amazon::Credentials->new(
    profile => 'foo',
    encrypt => \&my_encrypt,
    decrypt => \&my_decrypt,
    passkey => sub { return 'my passkey' },
  );

  check_credentials( $creds, %unencrypted_creds )
    or diag( Dumper [$creds] );
};

subtest 'custom encryption/decryption setting' => sub {
  # set only decrypt or encrypt
  foreach my $sub (qw{ encrypt decrypt }) {
    $creds = eval {
      return Amazon::Credentials->new(
        profile => 'foo',
        $sub    => sub { },
        passkey => sub { return 'my passkey' },
      );
    };

    ok( $EVAL_ERROR && $EVAL_ERROR =~ /must be a code ref/, "set just $sub" )
      or diag($EVAL_ERROR);
  } ## end foreach my $sub (qw{ encrypt decrypt })
};

subtest 'cache credentials' => sub {
  $creds = eval { return Amazon::Credentials->new( profile => 'foo',
      cache => 1, ); };

  check_credentials( $creds, %unencrypted_creds )
    or diag( Dumper [$creds] );

  ok( defined $creds->get__secret_access_key, 'secret access key retained' );
  ok( defined $creds->get__access_key_id,     'access key id retained' );

  $creds = eval { return Amazon::Credentials->new( profile => 'foo',
      cache => 0, ); };

  check_credentials( $creds, %unencrypted_creds )
    or diag( Dumper [$creds] );

  ok( !defined $creds->get__secret_access_key, 'secret access key removed' );
  ok( !defined $creds->get__access_key_id,     'access key id removed' );

};

subtest 'get passkey from sub' => sub {

  my $passkey = Amazon::Credentials::create_passkey;

  $creds = eval {
    return Amazon::Credentials->new(
      profile    => 'foo',
      cache      => 1,
      encryption => 1,
      passkey    => sub {
        return $passkey;
      },
    );
  };

  ok( $creds->get_encryption, 'encryption enabled' );

  check_credentials( $creds, %unencrypted_creds, )
    or diag( Dumper [$creds] );

};

subtest 'rotate credentials w/new passkey' => sub {
  my $passkey = 'abra cadabra ala kazam!';

  $creds = eval {
    return Amazon::Credentials->new(
      profile    => 'foo',
      cache      => 1,
      encryption => 1,
      passkey    => $passkey,
    );
  };

  # encrypted values
  my ( $secret_access_key, $access_key_id )
    = ( $creds->get__secret_access_key, $creds->get__access_key_id );

  my $new_passkey
    = $creds->rotate_credentials(Amazon::Credentials::create_passkey);

  ok( $new_passkey ne $passkey, 'passkey rotated' )
    or diag(
    Dumper [ $new_passkey, $secret_access_key, $access_key_id, $creds ] );

  check_credentials( $creds, %unencrypted_creds )
    or diag(
    Dumper [ $new_passkey, $secret_access_key, $access_key_id, $creds ] );

  ok( $secret_access_key ne $creds->get__secret_access_key,
    'encrypted secret different' )
    or diag(
    Dumper [ $new_passkey, $secret_access_key, $access_key_id, $creds ] );

  ok(
    $access_key_id ne $creds->get__access_key_id,
    'encrypted access_key_id different'
    )
    or diag(
    Dumper [ $new_passkey, $secret_access_key, $access_key_id, $creds ] );

  $new_passkey = $creds->rotate_credentials;

  ok( $new_passkey ne $passkey, 'passkey rotated' )
    or diag(
    Dumper [ $new_passkey, $secret_access_key, $access_key_id, $creds ] );

};

subtest 'token encryption' => sub {
  my $creds = Amazon::Credentials->new(
    aws_access_key_id     => 'foo',
    aws_secret_access_key => 'bar',
    token                 => 'biz',
    encryption            => 1,
    cache                 => 1,
  );

  ok( $creds->get_encryption, 'encryption enabled' )
    or diag( Dumper [$creds] );

  ok( $creds->get__session_token ne 'biz', 'token encrypted' )
    or diag( Dumper [$creds] );

  ok( $creds->get_token eq 'biz', 'token decrypted' )
    or diag( Dumper [$creds] );

  ok( decode_base64( $creds->get__session_token ) ne 'biz',
    'encrypted, not just obfuscated' )
    or diag( Dumper [$creds] );
};

END {
  eval { rmtree($home) if $home; };
}
