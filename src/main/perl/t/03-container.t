use strict;
use warnings;

use Test::More tests => 4;
use JSON::PP;

use Data::Dumper;
use Date::Format;

BEGIN {
  {
    no strict 'refs';
    
    *{'HTTP::Request::new'} = sub { bless {}, 'HTTP::Request'; };
    *{'HTTP::Request::request'} = sub { new HTTP::Response; };
    *{'HTTP::Request::header'} = sub {  };
    *{'HTTP::Request::as_string'} = sub {  };

    *{'HTTP::Response::new'} = sub { bless {}, 'HTTP::Response'; };
    *{'HTTP::Response::is_success'} = sub { 1; };

    *{'LWP::UserAgent::new'} = sub { bless {}, 'LWP::UserAgent'; };
    *{'LWP::UserAgent::request'} = sub { new HTTP::Response; };
  }

  use Module::Loaded;

  mark_as_loaded(HTTP::Request);
  mark_as_loaded(HTTP::Response);
  mark_as_loaded(LWP::UserAgent);

  use_ok('Amazon::Credentials');
}

# could be anything...but must exist
$ENV{AWS_CONTAINER_CREDENTIALS_RELATIVE_URI} = 'http://169.254.170.2';

my %container_creds;

$container_creds{AccessKeyId}     = 'buz-aws-access-key-id';
$container_creds{SecretAccessKey} = 'buz-aws-secret-access-key';
$container_creds{Token}           = 'buz';
$container_creds{Expiration}
  = time2str( "%Y-%m-%dT%H:%M:%SZ", time + 5 + ( 5 * 60 ), "GMT" );

my $response = JSON::PP->new->utf8->pretty->encode(\%container_creds);

my @order = ('container');

my %expected_creds;

$expected_creds{aws_access_key_id}     = 'buz-aws-access-key-id';
$expected_creds{aws_secret_access_key} = 'buz-aws-secret-access-key';
$expected_creds{token}                 = 'buz';
$expected_creds{expiration} 
  = time2str( "%Y-%m-%dT%H:%M:%SZ", time + 5 + ( 5 * 60 ), "GMT" );
$expected_creds{profile} = undef;
$expected_creds{source} = 'IAM';
$expected_creds{container} = 'ECS';

{
  no strict 'refs';
  
  *{'HTTP::Response::content'} = sub { return $response; };
}

my $creds = Amazon::Credentials->new({ order => \@order,  debug => $ENV{DEBUG} ? 1 : 0 });
isa_ok($creds, 'Amazon::Credentials');

ok(ref($creds), 'find credentials - container');

my %returned_creds;

if ( ref($creds) ) {
  foreach my $k (qw/aws_access_key_id aws_secret_access_key token expiration profile source container/) {
    $returned_creds{$k} = $creds->{$k};
  }
}

is_deeply(\%expected_creds, \%returned_creds, 'got expected creds');
