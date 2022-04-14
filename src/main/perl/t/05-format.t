use strict;
use warnings;

use Test::More tests => 5;

use Data::Dumper;
use Date::Format;
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

my $home = mkdtemp('amz-credentials-XXXXX');

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

$ENV{HOME}        = $home;
$ENV{AWS_PROFILE} = undef;

my $creds = Amazon::Credentials->new(
  { profile => 'foo',
    order   => [qw/file/],
    debug   => $ENV{DEBUG} ? 1 : 0
  }
);

isa_ok( $creds, 'Amazon::Credentials' ) or diag( Dumper [$creds] );

# format_credentials()
subtest 'format_credentials()' => sub {
  my $str = eval { $creds->format_credentials("export %s=%s\n"); };

  ok( $str, 'format_credentials' )
    or diag($@);

  my @lines = split /\n/, $str;

  ok( @lines == 2, "formatted 2 lines" ) or diag( Dumper [ $str, \@lines ] );

  foreach my $l (@lines) {
    ok( $l =~ /^export (AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY)=(.*)$/,
      'export %s=%s' )
      or diag($l);
  }
};

# credential_keys()
subtest 'credential_keys()' => sub {
  my $credential_keys = $creds->credential_keys;
  isa_ok( $credential_keys, 'HASH' ) or diag( Dumper [$credential_keys] );

  ok( exists $credential_keys->{AWS_ACCESS_KEY_ID},
    'hash contains AWS_ACCESS_KEY_ID' );

  ok( exists $credential_keys->{AWS_SECRET_ACCESS_KEY},
    'hash AWS_SECRET_ACCESS_KEY' );
};

# as_string()
subtest 'as_string' => sub {
  my $json = $creds->as_string();

  ok( $json && $json =~ /^\{[^\}]+\}/, 'smells like a JSON string' );

  my $obj = eval { return JSON::PP->new->decode($json); };

  isa_ok( $obj, 'HASH', 'is a JSON string' ) or diag( Dumper [$obj] );

  ok(
    exists $obj->{AWS_ACCESS_KEY_ID},
    'JSON string contains AWS_ACCESS_KEY_ID'
  );

  ok(
    exists $obj->{AWS_SECRET_ACCESS_KEY},
    'JSON string AWS_SECRET_ACCESS_KEY'
  );
};

END {
  eval { rmtree($home) if $home; };
}
