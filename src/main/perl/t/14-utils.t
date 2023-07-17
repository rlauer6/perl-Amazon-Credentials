use strict;
use warnings;

use Test::More;
use Data::Dumper;

use lib qw(. lib);

use_ok 'Amazon::Credentials';

use UnitTestSetup qw(TRUE FALSE);

########################################################################
subtest 'populate_creds' => sub {
########################################################################
  my $creds_source = {
    foo => 'bar',
    bar => 'foo',
    biz => 'buz',
    baz => 'biz',
  };

  my @keys = ( foo => 'foo', bar => 'bar', biz => 'biz', baz => 'baz' );

  my $creds
    = Amazon::Credentials::populate_creds( 'test', \@keys, $creds_source );

  for (qw(source foo bar biz baz)) {
    ok( exists $creds->{source}, 'exists ' . $_ );
  }

  ok( !%{$creds_source}, 'all keys deleted' );

  ok(
    join( q{}, sort keys %{$creds} ) eq
      join( q{}, sort qw(source foo bar biz baz) ),
    'keys match'
  );
};

########################################################################
subtest 'export_credentials' => sub {
########################################################################

  my @cred_keys
    = qw(AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN);

  my $credentials = {};

  @{$credentials}{@cred_keys} = qw(foo bar biz);

  my $export = Amazon::Credentials::export_credentials($credentials);

  like( $export, qr/export\sAWS_ACCESS_KEY_ID=foo$/xsm, 'access key id' )
    or diag( Dumper( [ export => $export ] ) );

  like(
    $export,
    qr/export\sAWS_SECRET_ACCESS_KEY=bar$/xsm,
    'secret access key'
  ) or diag( Dumper( [ export => $export ] ) );

  like( $export, qr/export\sAWS_SESSION_TOKEN=biz$/xsm, 'session token' )
    or diag( Dumper( [ export => $export ] ) );
};

done_testing;

1;
