use strict;
use warnings;

use Test::More tests => 6;
use Test::Output;

use Data::Dumper;
use English qw{ -no_match_vars };

use File::Temp qw/:mktemp/;
use File::Path;

BEGIN {
  use_ok('Amazon::Credentials');
}

my $home = mkdtemp('amz-credentials-XXXXX');

my $credentials_file = eval {
  mkdir "$home/.aws";

  open( my $fh, '>', "$home/.aws/credentials" )
    or BAIL_OUT('could not create temporary credentials file');

  print $fh <<eot;
[default]
profile = foo

[foo]
aws_access_key_id=foo-aws-access-key-id
aws_secret_access_key=foo-aws-secret-access-key

[profile boo]
credential_process = some_process_that_does_not_exist
region = us-west-2

eot
  close $fh;
  return "$home/.aws/credentials";
};

$ENV{HOME}        = $home;
$ENV{AWS_PROFILE} = undef;

my $creds;

$creds = eval {
  Amazon::Credentials->new(
    { profile => 'no profile',
      debug => $ENV{DEBUG} ? 1 : 0,
    }
  );
};

like($EVAL_ERROR, qr/^no credentials available/, 'raise_error => 1')
  or BAIL_OUT($EVAL_ERROR);

stderr_like(sub {
            $creds = eval {
              Amazon::Credentials->new(
                                       { profile => 'no profile',
                                         debug => $ENV{DEBUG} ? 1 : 0,
                                         raise_error => 0,
                                       }
                                      );
            }
          }, qr/^no credentials available/, 'no raise error, but print error');

ok(!$creds->get_aws_secret_access_key && !$EVAL_ERROR, 'raise_error => 0')
  or BAIL_OUT(Dumper([$creds, $EVAL_ERROR]));

stderr_is(sub {
            $creds = eval {
              Amazon::Credentials->new(
                                       { profile => 'no profile',
                                         debug => $ENV{DEBUG} ? 1 : 0,
                                         raise_error => 0,
                                         print_error => 0,
                                       }
                                      );
            }
          }, '', 'no print error');

$creds = eval {
  return Amazon::Credentials->new(profile => 'boo');
};

like($EVAL_ERROR, qr/could not open/, 'bad process')
  or diag(Dumper ["$EVAL_ERROR"]);

END {
  eval { rmtree($home) if $home; };
}
