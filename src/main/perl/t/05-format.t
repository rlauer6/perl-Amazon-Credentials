use strict;
use warnings;

use lib qw{ . lib};

use Test::More tests => 5;

use Data::Dumper;
use Date::Format;
use English qw(-no_match_vars);

use JSON::PP;
use UnitTestSetup qw(init_test format_time);

BEGIN {
  {
    no strict 'refs';  ## no critic

    *{'HTTP::Request::new'}     = sub { bless {}, 'HTTP::Request'; };
    *{'HTTP::Request::request'} = sub { HTTP::Response->new; };

    *{'HTTP::Response::new'}        = sub { bless {}, 'HTTP::Response'; };
    *{'HTTP::Response::is_success'} = sub { 1; };

    *{'LWP::UserAgent::new'}     = sub { bless {}, 'LWP::UserAgent'; };
    *{'LWP::UserAgent::request'} = sub { HTTP::Response->new; };
  }
  ## no critic

  use Module::Loaded;

  mark_as_loaded(HTTP::Request);
  mark_as_loaded(HTTP::Response);
  mark_as_loaded(LWP::UserAgent);

  use_ok('Amazon::Credentials');
}

init_test;

my $creds = Amazon::Credentials->new(
  { profile => 'foo',
    order   => [qw/file/],
    debug   => $ENV{DEBUG} ? 1 : 0
  }
);

isa_ok( $creds, 'Amazon::Credentials' ) or diag( Dumper [$creds] );

# format_credentials()
########################################################################
subtest 'format_credentials()' => sub {
########################################################################
  my $str = eval { $creds->format_credentials("export %s=%s\n"); };

  ok( $str, 'format_credentials' )
    or diag($EVAL_ERROR);

  my @lines = split /\n/xsm, $str;

  ok( @lines == 2, 'formatted 2 lines' ) or diag( Dumper [ $str, \@lines ] );

  foreach my $l (@lines) {
    ok( $l =~ /^export\s(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY)=(.*)$/xsm,
      'export %s=%s' )
      or diag($l);
  }
};

# credential_keys()
########################################################################
subtest 'credential_keys()' => sub {
########################################################################
  my $credential_keys = $creds->credential_keys;
  isa_ok( $credential_keys, 'HASH' ) or diag( Dumper [$credential_keys] );

  ok( exists $credential_keys->{AWS_ACCESS_KEY_ID},
    'hash contains AWS_ACCESS_KEY_ID' );

  ok( exists $credential_keys->{AWS_SECRET_ACCESS_KEY},
    'hash AWS_SECRET_ACCESS_KEY' );
};

# as_string()
########################################################################
subtest 'as_string' => sub {
########################################################################
  my $json = $creds->as_string();

  ok( $json && $json =~ /^[{][^}]+[}]/xsm, 'smells like a JSON string' );

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

1;
