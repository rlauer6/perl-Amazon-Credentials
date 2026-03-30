#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempfile tempdir);
use English qw(-no_match_vars);

########################################################################
# Since Amazon::Credentials has heavy deps we may not have in test
# environments, we test the web identity logic in two ways:
#
#   1. Pure unit tests of the helper functions (_xml_element,
#      _extract_sts_error, _uri_escape) extracted into this file
#
#   2. Integration tests of get_creds_from_web_identity via
#      a mocked UA, skipped if Amazon::Credentials is not loadable
########################################################################

########################################################################
# Helper function implementations (mirrors Credentials.pm)
# Tested here in isolation — no Amazon::Credentials dep required
########################################################################

sub _xml_element {
  my ( $xml, $tag ) = @_;
  return $1 if $xml =~ m{<$tag>([^<]+)</$tag>}xsm;
  return undef; ## no critic
}

sub _extract_sts_error {
  my ($xml) = @_;
  return q{} if !defined $xml || !length $xml;
  my $code    = _xml_element( $xml, 'Code' )    // q{};
  my $message = _xml_element( $xml, 'Message' ) // q{};
  return q{} if !$code && !$message;
  return " - $code: $message";
}

sub _uri_escape {
  my ($str) = @_;
  $str =~ s/([^A-Za-z0-9\-_.~])/sprintf '%%%02X', ord($1)/xsmeg;
  return $str;
}

########################################################################
# STS XML fixtures
########################################################################

my $SUCCESS_XML = <<'XML';
<AssumeRoleWithWebIdentityResponse>
  <AssumeRoleWithWebIdentityResult>
    <Credentials>
      <AccessKeyId>ASIAIOSFODNN7EXAMPLE</AccessKeyId>
      <SecretAccessKey>wJalrXUtnFEMI/K7MDENG+bPxRfiCY</SecretAccessKey>
      <SessionToken>AQoXnyc4lcK4//SESSION/TOKEN==</SessionToken>
      <Expiration>2025-01-01T12:00:00Z</Expiration>
    </Credentials>
    <AssumedRoleUser>
<Arn>arn:aws:sts::123456789:assumed-role/my-role/session</Arn>
    </AssumedRoleUser>
  </AssumeRoleWithWebIdentityResult>
</AssumeRoleWithWebIdentityResponse>
XML

my $ERROR_XML = <<'XML';
<ErrorResponse>
  <e>
    <Code>InvalidIdentityToken</Code>
    <Message>Provided token is expired.</Message>
  </e>
</ErrorResponse>
XML

my $EXPIRED_XML = <<'XML';
<ErrorResponse>
  <e>
    <Code>ExpiredTokenException</Code>
    <Message>Token has expired.</Message>
  </e>
</ErrorResponse>
XML

########################################################################
# Unit tests — no Amazon::Credentials required
########################################################################

subtest '_xml_element' => sub {
  is _xml_element( $SUCCESS_XML, 'AccessKeyId' ), 'ASIAIOSFODNN7EXAMPLE', 'extracts AccessKeyId';

  is _xml_element( $SUCCESS_XML, 'SecretAccessKey' ),
    'wJalrXUtnFEMI/K7MDENG+bPxRfiCY', 'extracts SecretAccessKey with special chars';

  is _xml_element( $SUCCESS_XML, 'SessionToken' ), 'AQoXnyc4lcK4//SESSION/TOKEN==', 'extracts SessionToken with / and =';

  is _xml_element( $SUCCESS_XML, 'Expiration' ), '2025-01-01T12:00:00Z', 'extracts Expiration';

  ok !defined _xml_element( $SUCCESS_XML, 'NoSuchTag' ), 'returns undef for missing tag';

  is _xml_element( $ERROR_XML, 'Code' ), 'InvalidIdentityToken', 'extracts error Code';

  is _xml_element( $ERROR_XML, 'Message' ), 'Provided token is expired.', 'extracts error Message';
};

subtest '_extract_sts_error' => sub {
  is _extract_sts_error($ERROR_XML),
    ' - InvalidIdentityToken: Provided token is expired.',
    'formats error with code and message';

  is _extract_sts_error($EXPIRED_XML), ' - ExpiredTokenException: Token has expired.', 'formats expired token error';

  is _extract_sts_error($SUCCESS_XML), q{}, 'returns empty string for success response (no Code/Message)';

  is _extract_sts_error(undef),                      q{}, 'handles undef gracefully';
  is _extract_sts_error(q{}),                        q{}, 'handles empty string gracefully';
  is _extract_sts_error('<foo>no error tags</foo>'), q{}, 'returns empty when no error elements';
};

subtest '_uri_escape' => sub {
  # ARN characters: colons and slashes must be encoded
  my $arn         = 'arn:aws:iam::123456789:role/my-role';
  my $encoded_arn = _uri_escape($arn);
  ok $encoded_arn !~ /[:]/,  'colons encoded in ARN';
  ok $encoded_arn !~ /[\/]/, 'slashes encoded in ARN';
  is $encoded_arn, 'arn%3Aaws%3Aiam%3A%3A123456789%3Arole%2Fmy-role', 'ARN encoded correctly';

  # JWT special chars: +, /, = must all be encoded
  my $jwt         = 'eyJhbGciOiJSUzI1NiJ9.payload+data/extra==';
  my $encoded_jwt = _uri_escape($jwt);
  ok $encoded_jwt !~ /[+\/=]/, 'JWT special chars encoded';
  like $encoded_jwt, qr/%2B/, '+ encoded as %2B';
  like $encoded_jwt, qr/%2F/, '/ encoded as %2F';
  like $encoded_jwt, qr/%3D/, '= encoded as %3D';

  # Safe chars must NOT be encoded
  my $safe = 'hello-world_test.name~value';
  is _uri_escape($safe), $safe, 'safe chars (- _ . ~) not encoded';

  # Alphanumerics not encoded
  is _uri_escape('abc123ABC'), 'abc123ABC', 'alphanumerics not encoded';

  # Space encoded as %20 not +
  like _uri_escape('hello world'), qr/hello%20world/, 'space encoded as %20';
};

subtest 'query string construction' => sub {
  # Verify the query string built for STS would be correct
  my %params = (
    Action           => 'AssumeRoleWithWebIdentity',
    Version          => '2011-06-15',
    RoleArn          => 'arn:aws:iam::123456789:role/my-role',
    RoleSessionName  => 'my-session',
    WebIdentityToken => 'tok+en/val==',
  );

  my $query = join q{&}, map { _uri_escape($_) . q{=} . _uri_escape( $params{$_} ) }
    sort keys %params;

  like $query, qr/Action=AssumeRoleWithWebIdentity/, 'Action in query';
  like $query, qr/Version=2011-06-15/,               'Version in query';
  like $query, qr/RoleArn=arn%3Aaws/,                'RoleArn encoded';
  like $query, qr/WebIdentityToken=tok%2Ben/,        'token + encoded';
  like $query, qr/WebIdentityToken=.*%2F/,           'token / encoded';
  like $query, qr/WebIdentityToken=.*%3D%3D/,        'token = encoded';

  # Parameters must be sorted (required by some STS implementations)
  my @keys   = map { ( split /=/, $_, 2 )[0] } split /&/, $query;
  my @sorted = sort @keys;
  is_deeply \@keys, \@sorted, 'query parameters are sorted';
};

########################################################################
# Integration tests — require Amazon::Credentials to load
########################################################################

my $can_load_creds = eval { require Amazon::Credentials; 1 };

SKIP: {
  skip 'Amazon::Credentials not loadable', 1 if !$can_load_creds;

  # Mock response object — matches Amazon::Credentials::HTTP::Response interface
  sub make_mock_response {
    my (%args)  = @_;
    my $success = $args{success} // 1;
    my $content = $args{content} // q{};
    my $status  = $args{status}  // ( $success ? '200 OK' : '400 Bad Request' );

    return bless {
      _success     => $success,
      _content     => $content,
      _status_line => $status,
      },
      'MockResponse';
  }

  {

    package MockResponse;
    sub is_success  { return $_[0]->{_success} }
    sub content     { return $_[0]->{_content} }
    sub status_line { return $_[0]->{_status_line} }
  }

  # Mock UA — captures the request and returns a canned response
  sub make_mock_ua {
    my ($response) = @_;
    return bless { _response => $response, _last_request => undef }, 'MockUA';
  }

  {

    package MockUA;

    sub request {
      my ( $self, $req ) = @_;
      $self->{_last_request} = $req;
      return $self->{_response};
    }
    sub last_request { return $_[0]->{_last_request} }
  }

  subtest 'get_creds_from_web_identity - missing env vars' => sub {
    local $ENV{AWS_WEB_IDENTITY_TOKEN_FILE} = undef;
    local $ENV{AWS_ROLE_ARN}                = undef;

    my $creds = Amazon::Credentials->new(
      { order                 => [qw(web_identity)],
        aws_access_key_id     => 'dummy',
        aws_secret_access_key => 'dummy',
      }
    );

    my $result = $creds->get_creds_from_web_identity;
    is_deeply $result, {}, 'returns empty hash when env vars not set';
  };

  subtest 'get_creds_from_web_identity - missing token file' => sub {
    local $ENV{AWS_WEB_IDENTITY_TOKEN_FILE} = '/nonexistent/token/file';
    local $ENV{AWS_ROLE_ARN}                = 'arn:aws:iam::123456789:role/my-role';

    my $creds = Amazon::Credentials->new(
      { aws_access_key_id     => 'dummy',
        aws_secret_access_key => 'dummy',
      }
    );

    my $result = $creds->get_creds_from_web_identity;
    is_deeply $result, {}, 'returns empty hash when token file missing';
  };

  subtest 'get_creds_from_web_identity - empty token file' => sub {
    my ( $fh, $fname ) = tempfile( UNLINK => 1 );
    close $fh;  # leave empty

    local $ENV{AWS_WEB_IDENTITY_TOKEN_FILE} = $fname;
    local $ENV{AWS_ROLE_ARN}                = 'arn:aws:iam::123456789:role/my-role';

    my $creds = Amazon::Credentials->new(
      { aws_access_key_id     => 'dummy',
        aws_secret_access_key => 'dummy',
      }
    );

    my $result = $creds->get_creds_from_web_identity;
    is_deeply $result, {}, 'returns empty hash for empty token file';
  };

  subtest 'get_creds_from_web_identity - successful STS call' => sub {
    my ( $fh, $fname ) = tempfile( UNLINK => 1 );
    print $fh 'eyJhbGciOiJSUzI1NiJ9.pay+load/data==end';
    close $fh;

    local $ENV{AWS_WEB_IDENTITY_TOKEN_FILE} = $fname;
    local $ENV{AWS_ROLE_ARN}                = 'arn:aws:iam::123456789:role/my-role';
    local $ENV{AWS_ROLE_SESSION_NAME}       = 'test-session';

    my $mock_ua = make_mock_ua( make_mock_response( success => 1, content => $SUCCESS_XML ) );

    my $creds_obj = Amazon::Credentials->new(
      { aws_access_key_id     => 'dummy',
        aws_secret_access_key => 'dummy',
        user_agent            => $mock_ua,
      }
    );

    my $result = $creds_obj->get_creds_from_web_identity;

    is $result->{aws_access_key_id},     'ASIAIOSFODNN7EXAMPLE',           'aws_access_key_id set';
    is $result->{aws_secret_access_key}, 'wJalrXUtnFEMI/K7MDENG+bPxRfiCY', 'aws_secret_access_key set';
    is $result->{aws_session_token},     'AQoXnyc4lcK4//SESSION/TOKEN==',  'aws_session_token set';
    is $result->{token},                 'AQoXnyc4lcK4//SESSION/TOKEN==',  'token alias set';
    is $result->{expiration},            '2025-01-01T12:00:00Z',           'expiration set';
    is $result->{source},                'web_identity',                   'source is web_identity';

    # Verify the request was made without signing
    my $req = $mock_ua->last_request;
    ok !$req->header('Authorization'), 'no Authorization header — request is unsigned';

    # Verify query string contents
    my $url = $req->uri->as_string;
    like $url, qr/Action=AssumeRoleWithWebIdentity/, 'Action in URL';
    like $url, qr/Version=2011-06-15/,               'Version in URL';
    like $url, qr/RoleArn=arn%3Aaws/,                'RoleArn encoded in URL';
    like $url, qr/RoleSessionName=test-session/,     'RoleSessionName in URL';
    like $url, qr/WebIdentityToken=/,                'WebIdentityToken in URL';
    # Extract just the token value and verify special chars are percent-encoded
    my ($token_val) = $url =~ /WebIdentityToken=([^&]*)/;
    ok defined $token_val, 'WebIdentityToken present in URL';
    ok $token_val =~ /%2B/,    '+ encoded as %2B in token';
    ok $token_val =~ /%2F/,    '/ encoded as %2F in token';
    ok $token_val =~ /%3D/,    '= encoded as %3D in token';
    ok $token_val !~ /[+\/=]/, 'no raw special chars in token value';
  };

  subtest 'get_creds_from_web_identity - default session name' => sub {
    my ( $fh, $fname ) = tempfile( UNLINK => 1 );
    print $fh 'fake-jwt-token';
    close $fh;

    local $ENV{AWS_WEB_IDENTITY_TOKEN_FILE} = $fname;
    local $ENV{AWS_ROLE_ARN}                = 'arn:aws:iam::123:role/r';
    local $ENV{AWS_ROLE_SESSION_NAME}       = undef;

    my $mock_ua = make_mock_ua( make_mock_response( success => 1, content => $SUCCESS_XML ) );

    my $creds_obj = Amazon::Credentials->new(
      { aws_access_key_id     => 'dummy',
        aws_secret_access_key => 'dummy',
        user_agent            => $mock_ua,
      }
    );

    $creds_obj->get_creds_from_web_identity;

    my $url = $mock_ua->last_request->uri->as_string;
    like $url, qr/RoleSessionName=amazon-credentials-session/, 'default session name used when AWS_ROLE_SESSION_NAME not set';
  };

  subtest 'get_creds_from_web_identity - STS error response' => sub {
    my ( $fh, $fname ) = tempfile( UNLINK => 1 );
    print $fh 'expired-jwt-token';
    close $fh;

    local $ENV{AWS_WEB_IDENTITY_TOKEN_FILE} = $fname;
    local $ENV{AWS_ROLE_ARN}                = 'arn:aws:iam::123:role/r';

    my $mock_ua = make_mock_ua(
      make_mock_response(
        success => 0,
        content => $ERROR_XML,
        status  => '400 Bad Request',
      )
    );

    my $creds_obj = Amazon::Credentials->new(
      { aws_access_key_id     => 'dummy',
        aws_secret_access_key => 'dummy',
        user_agent            => $mock_ua,
      }
    );

    my $result = $creds_obj->get_creds_from_web_identity;
    is_deeply $result, {}, 'returns empty hash on STS error';
  };

  subtest 'get_creds_from_web_identity - regional STS endpoint' => sub {
    my ( $fh, $fname ) = tempfile( UNLINK => 1 );
    print $fh 'fake-jwt';
    close $fh;

    local $ENV{AWS_WEB_IDENTITY_TOKEN_FILE} = $fname;
    local $ENV{AWS_ROLE_ARN}                = 'arn:aws:iam::123:role/r';
    local $ENV{AWS_DEFAULT_REGION}          = 'eu-west-1';

    my $mock_ua = make_mock_ua( make_mock_response( success => 1, content => $SUCCESS_XML ) );

    my $creds_obj = Amazon::Credentials->new(
      { aws_access_key_id     => 'dummy',
        aws_secret_access_key => 'dummy',
        user_agent            => $mock_ua,
      }
    );

    $creds_obj->get_creds_from_web_identity;

    my $url = $mock_ua->last_request->uri->as_string;
    like $url, qr{sts\.eu-west-1\.amazonaws\.com}, 'uses regional STS endpoint when AWS_DEFAULT_REGION is set';
  };

  subtest 'get_creds_from_web_identity - global STS endpoint for us-east-1' => sub {
    my ( $fh, $fname ) = tempfile( UNLINK => 1 );
    print $fh 'fake-jwt';
    close $fh;

    local $ENV{AWS_WEB_IDENTITY_TOKEN_FILE} = $fname;
    local $ENV{AWS_ROLE_ARN}                = 'arn:aws:iam::123:role/r';
    local $ENV{AWS_DEFAULT_REGION}          = 'us-east-1';

    my $mock_ua = make_mock_ua( make_mock_response( success => 1, content => $SUCCESS_XML ) );

    my $creds_obj = Amazon::Credentials->new(
      { aws_access_key_id     => 'dummy',
        aws_secret_access_key => 'dummy',
        user_agent            => $mock_ua,
      }
    );

    $creds_obj->get_creds_from_web_identity;

    my $url = $mock_ua->last_request->uri->as_string;
    like $url, qr{sts\.amazonaws\.com(?!/eu|/ap|/us-west)}, 'uses global STS endpoint for us-east-1';
  };

  subtest 'web_identity in default search order' => sub {
    # Verify web_identity slot exists in the dispatch table
    # by confirming the constant includes it
    my $order = Amazon::Credentials::DEFAULT_SEARCH_ORDER();
    like $order, qr/web_identity/, 'DEFAULT_SEARCH_ORDER includes web_identity';

    # And it comes after container/role but before file
    my @parts = split /,/, $order;
    my %pos;
    @pos{@parts} = ( 0 .. $#parts );

    ok exists $pos{web_identity}, 'web_identity in search order';

    SKIP: {
      skip 'container or file not in order', 2
        unless exists $pos{container} && exists $pos{file};
      ok $pos{web_identity} > $pos{container}, 'web_identity comes after container';
      ok $pos{web_identity} < $pos{file},      'web_identity comes before file';
    }
  };
}

done_testing;
