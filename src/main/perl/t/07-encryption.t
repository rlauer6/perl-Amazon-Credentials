use strict;
use warnings;

use Data::Dumper;
use Date::Format;
use English qw{ -no_match_vars };
use JSON::PP;
use MIME::Base64;
use Test::More;
use UnitTestSetup;

my $has_crypt_cbc = eval {
  require Crypt::CBC;
  require Crypt::Cipher::AES;
};

if ( !$has_crypt_cbc ) {
  plan skip_all => 'Crypt::CBC unavilable';
}
else {
  plan tests => 14;
}

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

} ## end BEGIN

########################################################################
sub my_encrypt {
########################################################################
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

########################################################################
sub my_decrypt {
########################################################################
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

########################################################################
sub check_credentials {
########################################################################
  my ( $credentials, $unencrypted_creds, $test ) = @_;

  $test = $test // q{};

  my $retval = 0;

  if ( $credentials->get_cache ) {
    foreach my $e (qw{ access_key_id secret_access_key }) {
      my $encrypted_value = $credentials->can( 'get__' . $e )->($credentials);
      my $unencrypted_value
        = $credentials->can( 'get_aws_' . $e )->($credentials);

      $retval
        += !ok( $encrypted_value && $encrypted_value ne $unencrypted_value,
        $test . ' - ' . $e . ' encrypted ok' );

      $retval += !ok(
        $unencrypted_value eq $unencrypted_creds->{$e},
        $test . ' - ' . $e . ' decrypted ok'
      );

    } ## end foreach my $e (qw{ access_key_id secret_access_key })
  } ## end if ( $credentials->get_cache)
  else {
    foreach my $e (qw{access_key_id secret_access_key }) {
      $retval
        += !ok( !defined $credentials->can( 'get__' . $e )->($credentials),
        $test . ' - ' . $e . ' not cached' );
    }
  } ## end else [ if ( $credentials->get_cache)]

  return !$retval;
} ## end sub check_credentials

########################################################################
sub check_cipher {
########################################################################
  my ( $cipher_name, $test ) = @_;

  my $credentials = Amazon::Credentials->new(
    profile => 'foo',
    cipher  => $cipher_name
  );

  ok( $credentials->get_encryption, 'encryption enabled' );

  $cipher_name = $cipher_name || $credentials->get_cipher;

  is( $credentials->get_cipher, $cipher_name, $test || $cipher_name )
    or diag( $credentials->get_cipher );

  my $passkey = $credentials->get_passkey;

  my $cipher = Crypt::CBC->new(
    '-pass'        => $passkey,
    '-key'         => $passkey,
    '-nodeprecate' => 1,
    '-cipher'      => $cipher_name,
  );

  my $access_key_id = decode_base64( $credentials->get__access_key_id );
  my $unencrypted_access_key_id = $credentials->get_aws_access_key_id;

  my $encrypted_access_key_id = $cipher->encrypt($unencrypted_access_key_id);

  isnt( $encrypted_access_key_id, $access_key_id,
    'encrypted strings different (salt)' )
    or diag( Dumper [ $passkey, $encrypted_access_key_id, $access_key_id ] );

  # decrypt your encrypted string with my cipher
  is(
    $cipher->decrypt($access_key_id),
    $credentials->get_aws_access_key_id,
    'encrypted with ' . $cipher_name
    )
    or diag( Dumper [ $passkey, $encrypted_access_key_id, $access_key_id ] );
} ## end sub check_cipher

# +------------------ +
# | TESTS START HERE |
# +------------------ +

init_test;

use_ok('Amazon::Credentials');

Amazon::Credentials->import('create_passkey');

my %unencrypted_creds = (
  access_key_id     => 'foo-aws-access-key-id',
  secret_access_key => 'foo-aws-secret-access-key',
);

# !! this test must be run first !!
########################################################################
subtest 'obfuscation without Crypt::CBC' => sub {
########################################################################

  {
    # use Devel::Hide qw{ -lexically  -quiet Crypt::CBC };
    eval "use Test::Without::Module qw{ Crypt::CBC Crypt::Cipher::AES };";

    my $credentials = Amazon::Credentials->new(
      profile    => 'foo',
      encryption => 1,
    );

    ok( !$credentials->get_encryption,
      'encryption disabled (no Crypt::CBC)' );

    ok(
      decode_base64( $credentials->get__access_key_id ) eq
        $unencrypted_creds{access_key_id},
      'base64 encoded obfuscation'
    );

    ok(
      decode_base64( $credentials->get__secret_access_key ) eq
        $unencrypted_creds{secret_access_key},
      'base64 encoded obfuscation'
    );

    check_credentials( $credentials, \%unencrypted_creds, 'obfuscation' )
      or diag( Dumper [$credentials] );
  }

  eval q{ no Test::Without::Module qw{ Crypt::CBC Crypt::Cipher::AES }; };
};

########################################################################
subtest 'decrypt' => sub {
########################################################################

  my $credentials = Amazon::Credentials->new( profile => 'foo', );

  ok( defined $credentials->get_passkey, 'passkey created' );

  ok( $credentials->get_encryption, 'default is encryption enabled' );

  check_credentials( $credentials, \%unencrypted_creds, 'decrypt' )
    or diag( Dumper [$credentials] );
};

########################################################################
subtest 'rotate credentials' => sub {
########################################################################

  my $credentials
    = Amazon::Credentials->new( profile => 'foo', encryption => 1 );

  my $passkey     = $credentials->get_passkey;
  my $new_passkey = $credentials->rotate_credentials;

  ok( $new_passkey ne $passkey, 'passkey changed' )
    or diag( Dumper [ $passkey, $new_passkey ] );

  check_credentials( $credentials, \%unencrypted_creds, 'rotate' )
    or diag( Dumper [$credentials] );
};

########################################################################
subtest 'rotate credentials with custom passkey' => sub {
########################################################################

  our $passkey = create_passkey();

  sub get_passkey {
    my ($regenerate) = @_;

    return $regenerate ? create_passkey() : $passkey;
  }

  my $credentials = Amazon::Credentials->new(
    passkey => \&get_passkey,
    profile => 'foo',
    cache   => 1,
  );

  isa_ok( $credentials, 'Amazon::Credentials' );

  my $old_passkey = $passkey;

  $passkey = $credentials->rotate_credentials( get_passkey(1) );

  ok( $old_passkey && $passkey, 'passkeys are not null' );

  ok( $old_passkey ne $passkey, 'passkey has changed' );

  check_credentials( $credentials, \%unencrypted_creds, 'rotate (cache on)' )
    or diag( Dumper [$credentials] );

  $credentials = Amazon::Credentials->new(
    cache   => 0,
    passkey => \&get_passkey,
    profile => 'foo'
  );

  $old_passkey = $passkey = get_passkey(1);

  $passkey = $credentials->rotate_credentials( get_passkey(1) );

  ok( $old_passkey && $passkey, 'passkeys are not null (cacheing off)' );

  ok( $old_passkey ne $passkey, 'passkey has changed (cacheing off' );

  check_credentials( $credentials, \%unencrypted_creds, 'rotate (cache off)' )
    or diag( Dumper [$credentials] );

  sub get_passkey_v2 {
    return 'abra cadabra ala kazam!';
  }

  $credentials->set_cache(1);
  $credentials->set_passkey( \&get_passkey_v2 );

  $credentials->reset_credentials(1);

  check_credentials( $credentials, \%unencrypted_creds, 'set new passkey' )
    or diag( Dumper [$credentials] );

  $credentials->set_insecure(1);

  $credentials->set_cache(1);

  $credentials->set_passkey( \&get_passkey );

  $credentials->reset_credentials(1);

  check_credentials( $credentials, \%unencrypted_creds,
    'set new passkey (cached)' )
    or diag( Dumper [$credentials] );
};

########################################################################
subtest 'custom encryption/decryption' => sub {
########################################################################

  my $credentials = Amazon::Credentials->new(
    profile => 'foo',
    encrypt => \&my_encrypt,
    decrypt => \&my_decrypt,
    passkey => sub { return 'my passkey' },
  );

  check_credentials( $credentials, \%unencrypted_creds, 'custom encryption' )
    or diag( Dumper [$credentials] );
};

########################################################################
subtest 'custom encryption/decryption setting' => sub {
########################################################################

  # set only decrypt or encrypt
  foreach my $sub (qw{ encrypt decrypt }) {
    my $credentials = eval {
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

########################################################################
subtest 'cache credentials' => sub {
########################################################################

  my $credentials = eval { return Amazon::Credentials->new( profile => 'foo',
      cache => 1, ); };

  check_credentials( $credentials, \%unencrypted_creds, 'cache on' )
    or diag( Dumper [$credentials] );

  ok( defined $credentials->get__secret_access_key,
    'secret access key retained' );
  ok( defined $credentials->get__access_key_id, 'access key id retained' );

};

########################################################################
subtest 'do not cache credentials' => sub {
########################################################################

  my $credentials = eval { return Amazon::Credentials->new( profile => 'foo',
      cache => 0, ); };

  check_credentials( $credentials, \%unencrypted_creds, 'cache off' )
    or diag( Dumper [$credentials] );

  ok( !defined $credentials->get__secret_access_key,
    'secret access key removed' );
  ok( !defined $credentials->get__access_key_id, 'access key id removed' );

};

########################################################################
subtest 'get passkey from sub' => sub {
########################################################################

  my $passkey = create_passkey();

  my $credentials = eval {
    return Amazon::Credentials->new(
      profile    => 'foo',
      cache      => 1,
      encryption => 1,
      passkey    => sub {
        return $passkey;
      },
    );
  };

  ok( $credentials->get_encryption, 'encryption enabled' )
    or diag( Dumper [$credentials] );

  check_credentials( $credentials, \%unencrypted_creds, )
    or diag( Dumper [$credentials] );

};

########################################################################
subtest 'rotate credentials w/new passkey' => sub {
########################################################################

  my $passkey = 'abra cadabra ala kazam!';

  my $credentials = eval {
    return Amazon::Credentials->new(
      profile    => 'foo',
      cache      => 1,
      encryption => 1,
      passkey    => $passkey,
    );
  };

  # encrypted values
  my ( $secret_access_key, $access_key_id ) = (
    $credentials->get__secret_access_key,
    $credentials->get__access_key_id
  );

  my $new_passkey = $credentials->rotate_credentials( create_passkey() );

  ok( $new_passkey ne $passkey, 'passkey rotated' )
    or diag(
    Dumper [ $new_passkey, $secret_access_key, $access_key_id, $credentials ]
    );

  check_credentials( $credentials, \%unencrypted_creds )
    or diag(
    Dumper [ $new_passkey, $secret_access_key, $access_key_id, $credentials ]
    );

  ok( $secret_access_key ne $credentials->get__secret_access_key,
    'encrypted secret different' )
    or diag(
    Dumper [ $new_passkey, $secret_access_key, $access_key_id, $credentials ]
    );

  ok( $access_key_id ne $credentials->get__access_key_id,
    'encrypted access_key_id different' )
    or diag(
    Dumper [ $new_passkey, $secret_access_key, $access_key_id, $credentials ]
    );

  $new_passkey = $credentials->rotate_credentials;

  ok( $new_passkey ne $passkey, 'passkey rotated' )
    or diag(
    Dumper [ $new_passkey, $secret_access_key, $access_key_id, $credentials ]
    );

};

########################################################################
subtest 'token encryption' => sub {
########################################################################

  my $credentials = Amazon::Credentials->new(
    aws_access_key_id     => 'foo',
    aws_secret_access_key => 'bar',
    token                 => 'biz',
    encryption            => 1,
    cache                 => 1,
  );

  ok( $credentials->get_encryption, 'encryption enabled' )
    or diag( Dumper [$credentials] );

  ok( $credentials->get__session_token ne 'biz', 'token encrypted' )
    or diag( Dumper [$credentials] );

  ok( $credentials->get_token eq 'biz', 'token decrypted' )
    or diag( Dumper [$credentials] );

  ok( decode_base64( $credentials->get__session_token ) ne 'biz',
    'encrypted, not just obfuscated' )
    or diag( Dumper [$credentials] );
};

########################################################################
subtest 'use Crypt::CBC' => sub {
########################################################################

  eval {
    require Crypt::CBC;
    require Crypt::Cipher::AES;
  };

  if ($EVAL_ERROR) {
    plan skip_all => $EVAL_ERROR;
  }

  check_cipher( '', 'default cipher' );
};

########################################################################
subtest 'use custom cipher' => sub {
########################################################################

  my $cipher_name = $ENV{AMAZON_CREDENTIAL_TEST_CIPHER} || 'Crypt::Blowfish';

  eval "require $cipher_name;";

  if ($EVAL_ERROR) {
    plan skip_all => $EVAL_ERROR;
  }

  check_cipher( $cipher_name, 'custom cipher ' . $cipher_name );
};
