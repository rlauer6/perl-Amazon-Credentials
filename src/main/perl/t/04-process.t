use strict;
use warnings;

use Test::More tests => 4;

use File::Temp qw/:mktemp/;
use File::Path;
use Data::Dumper;
use Cwd;

BEGIN {
  use_ok('Amazon::Credentials');
}

my $home = mkdtemp("amz-credentials-XXXXX");

my $credentials_file = eval {
  mkdir "$home/.aws";
  
  open (my $fh, ">$home/.aws/credentials") or BAIL_OUT("could not create temporary credentials file");
  my $process = getcwd . '/get-creds-from-process';
  
  print $fh <<eot;
[profile foo]
credential_process = $process
region = us-east-1

eot
  close $fh;
  "$home/.aws/credentials";
};

$ENV{HOME} = "$home";
$ENV{AWS_PROFILE} = undef;

my $creds = Amazon::Credentials->new(
  { profile => 'foo',
    order   => [qw/file/],
    debug   => $ENV{DEBUG} ? 1 : 0
  }
);

ok( ref($creds), 'find credentials' );

is($creds->get_aws_access_key_id, 'aws-access-key-id', 'get from process');
is($creds->get_region, 'us-east-1', 'region');


END {
  eval {
    rmtree($home)
      if $home;
  };
}
