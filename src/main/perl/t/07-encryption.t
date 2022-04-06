use strict;
use warnings;

use Test::More tests => 9;

use Data::Dumper;
use Date::Format;
use English qw{ -no_match_vars };
use MIME::Base64;

use File::Path;
use JSON::PP;

use File::Temp qw/:mktemp/;

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

  if ( $creds->get_cache ) {
    foreach my $e (qw{ access_key_id secret_access_key }) {
      my $encrypted_value   = $creds->{$e};
      my $unencrypted_value = $creds->can( 'get_aws_' . $e )->($creds);

      ok( $encrypted_value && $encrypted_value ne $unencrypted_value,
        'encrypted ok' )
        or diag( Dumper $creds);

      ok( $unencrypted_value eq $unencrypted_creds{$e}, 'decrypted ok' )
        or diag( Dumper $creds);
    } ## end foreach my $e (qw{ access_key_id secret_access_key })
  } ## end if ( $creds->get_cache)
  else {
    foreach my $e (qw{access_key_id secret_access_key }) {
      ok( !defined $creds->{$e}, 'credentials not cached' );
    }
  }
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

my $creds = Amazon::Credentials->new( profile => 'foo', encryption => 1 );

my %unencrypted_creds = (
  access_key_id     => 'foo-aws-access-key-id',
  secret_access_key => 'foo-aws-secret-access-key',
);

subtest 'decrypt' => sub {
  check_credentials( $creds, %unencrypted_creds );
};

my $passkey = $creds->get_passkey;

subtest 'rotate credentials' => sub {

  my $new_passkey = $creds->rotate_credentials;

  ok( $new_passkey ne $passkey, 'passkey changed' )
    or diag( Dumper [ $passkey, $new_passkey ] );

  check_credentials( $creds, %unencrypted_creds );
};

subtest 'custom encryption/decryption' => sub {
  $creds = Amazon::Credentials->new(
    profile => 'foo',
    encrypt => \&my_encrypt,
    decrypt => \&my_decrypt,
    passkey => sub { return 'my passkey' },
  );

  check_credentials( $creds, %unencrypted_creds );
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

  check_credentials( $creds, %unencrypted_creds );

  ok( defined $creds->get_secret_access_key, 'secret access key retained' );
  ok( defined $creds->get_access_key_id,     'access key id retained' );

  $creds = eval { return Amazon::Credentials->new( profile => 'foo',
      cache => 0, ); };

  check_credentials( $creds, %unencrypted_creds );

  ok( !defined $creds->get_secret_access_key, 'secret access key removed' );
  ok( !defined $creds->get_access_key_id,     'access key id removed' );

};

subtest 'get passkey from sub' => sub {

  $passkey = $creds->get_passkey;

  $creds->set_passkey( sub { return $passkey } );
  $creds->set_credentials;
  $creds->set_cache(1);
  check_credentials( $creds, %unencrypted_creds, );
  $creds->set_cache(0);
};

subtest 'rotate credentials w/new passkey' => sub {
  my $new_passkey = 'abra cadabra ala kazam!';

  # my sub return $passkey, so setting $passkey to new key should work
  $creds->set_cache(1);
  $passkey = $creds->rotate_credentials($new_passkey);

  check_credentials( $creds, %unencrypted_creds );
  $creds->set_cache(0);
};

subtest 'obfuscation without Crypt::CBC' => sub {
  use Devel::Hide qw{ Crypt::CBC };

  my $creds = Amazon::Credentials->new( profile => 'foo', encryption => 1 );

  ok( !$creds->get_encryption, 'no encryption available' );
  ok(
    decode_base64( $creds->get_access_key_id ) eq
      $unencrypted_creds{access_key_id},
    'base64 encoded obfuscation'
  );

  ok(
    decode_base64( $creds->get_secret_access_key ) eq
      $unencrypted_creds{secret_access_key},
    'base64 encoded obfuscation'
  );

  check_credentials( $creds, %unencrypted_creds );
};

END {
  eval { rmtree($home) if $home; };
}
