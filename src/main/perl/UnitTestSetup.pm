use strict;
use warnings;

use parent qw{ Exporter };

use Data::Dumper;
use Date::Format;
use File::Path;
use File::Temp qw{ tempdir };
use Test::More;

our @EXPORT = qw{ init_test format_time };

use constant {
  ISO_8601_FORMAT => '%Y-%m-%dT%H:%M:%SZ',
  TRUE            => 1,
  FALSE           => 0,
  FIVE_MINUTES    => 5 * 60,
};


caller() or __PACKAGE__->main();

########################################################################
sub format_time {
########################################################################
  my ($time) = @_;

  return time2str( ISO_8601_FORMAT, time + $time, 'GMT' );
}

########################################################################
sub read_config {
########################################################################
  my ( $fh, $test ) = @_;

  $fh = $fh || *DATA;

  my %configs;

  my $config_name;

  while ( my $line = <$fh> ) {
    chomp $line;
    if ( $line =~ /^--- (.*) ---$/ ) {
      $config_name = $1;
      $configs{$1} = [];
      next;
    }

    push @{ $configs{$config_name} }, $line;
  } ## end while ( my $line = <$fh> )

  close $fh;

  return $configs{$test} ? $configs{$test} : $configs{'01-credentials.t'};
} ## end sub read_config

########################################################################
sub create_credentials_file {
########################################################################
  my ( $home, $credentials, $vars ) = @_;

  # poor mans templating...
  foreach ( @{$credentials} ) {
    next if !/(@[^@]+@)/;

    my $tmpl_var = $1;

    my $var = $tmpl_var;
    $var =~ s/@//g;

    my $val = $vars->{$var};

    s/$tmpl_var/$val/g;
  } ## end foreach ( @{$credentials} )

  mkdir "$home/.aws";

  open( my $fh, '>', "$home/.aws/credentials" )
    or BAIL_OUT('could not create temporary credentials file');

  print {$fh} join "\n", @{$credentials};

  close $fh;

  return "$home/.aws/credentials";
} ## end sub create_credentials_file

########################################################################
sub create_home_dir {
########################################################################
  my ($cleanup) = @_;

  my $home = tempdir( 'amz-credentials-XXXXX', CLEANUP => $cleanup );

  $ENV{HOME} = $home;

  return $home;
} ## end sub create_home_dir

########################################################################
sub init_test {
########################################################################
  my (%args) = @_;

  $ENV{'AWS_PROFILE'} = $args{'profile'} || 'default';

  my $credentials = read_config( *DATA, $args{'test'} // '01-credentials.t' );

  my $home = create_home_dir( $args{'cleanup'} // 1 );

  return create_credentials_file( $home, $credentials, $args{'vars'} );
} ## end sub init_test

sub main {
  print Dumper [
    init_test(
      cleanup => 0,
      test    => '01-credentials.t',
      vars    => { process => 'foo' },
    )
  ];
} ## end sub main

1;

__DATA__
--- 01-credentials.t ---
[default]
profile = bar

[foo]
aws_access_key_id=foo-aws-access-key-id
aws_secret_access_key=foo-aws-secret-access-key
region = us-east-1
  
[bar]
aws_access_key_id=bar-aws-access-key-id
aws_secret_access_key=bar-aws-secret-access-key
region = us-east-1

--- 04-process.t ---
[profile foo]
credential_process = @process@
region = us-west-2

--- 12-error.t ---
[default]
profile = foo

[foo]
aws_access_key_id=foo-aws-access-key-id
aws_secret_access_key=foo-aws-secret-access-key

[profile boo]
credential_process = some_process_that_does_not_exist
region = us-west-2


