#!/usr/bin/perl

use AWS::Credentials;
use Data::Dumper;

my $creds = AWS::Credentials->new();

print Dumper [$creds];
