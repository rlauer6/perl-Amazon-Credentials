#!/usr/bin/env perl

# Example of how to check for an expired token

use strict;
use warnings;

use Data::Dumper;
use Date::Format;

use Amazon::Credentials;

my $creds = Amazon::Credentials->new({ order => [ 'role'  ], debug => 1});

while (1) {
  my @tm = localtime(time);
  print STDERR sprintf("expiry time: %s now: %s\n", $creds->get_expiration, strftime("%Y-%m-%dT%H:%M:%S%Z", @tm, "Z"));
  
  if ( $creds->is_token_expired ) {
    $creds->set_aws_access_key_id(undef);
    $creds->set_aws_secret_access_key(undef);
    $creds->set_token(undef);
    
    $creds->refresh_token();
    print STDERR Dumper $creds;
  }

  sleep(60);
}
