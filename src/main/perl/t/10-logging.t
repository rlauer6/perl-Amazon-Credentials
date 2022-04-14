use strict;
use warnings;

use Test::More;
use Test::Output;

use Data::Dumper;
use Date::Format;
use File::Path;
use JSON::PP;

use File::Temp qw/:mktemp/;

BEGIN {
  use English qw{ -no_match_vars };

  eval <<'END_OF_TEXT';
use Log::Log4perl;
use Log::Log4perl::Level;
Log::Log4perl->easy_init($DEBUG);
END_OF_TEXT

  if ($EVAL_ERROR) {
    plan skip_all => 'no Log::Log4perl available';
  }
  else {
    plan tests => 2;
  }

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

my $stderr_from;

subtest 'logging' => sub {

  $stderr_from = stderr_from(
    sub {
      Amazon::Credentials->new(
        profile => 'foo',
        debug   => 1,
        logger  => undef,
      );
    }
  );

  ok( $stderr_from =~ /Amazon::Credentials::Logger/, 'use default logger' )
    or diag($stderr_from);

  $stderr_from = stderr_from(
    sub {
      Amazon::Credentials->new(
        profile => 'foo',
        debug   => 1,
        logger  => Log::Log4perl->get_logger,

      );
    }
  );

  ok( $stderr_from =~ /using Log::Log4perl::Logger/, 'use Log::Log4perl' )
    or diag($stderr_from);
};

END {
  eval { rmtree($home) if $home; };
}
