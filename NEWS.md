# NEWS

This is the `NEWS` file for the `perl-Amazon-Credentials`
project. This file contains information on changes since the last
release of the package, as well as a running list of changes from
previous versions.  If critical bugs are found in any of the software,
notice of such bugs and the versions in which they were fixed will be
noted here, as well.

# perl-Amazon-Credentials 1.1.0 (2022-04-06)

## Enhancements

There have been several enhanements to this module, specifically to
reduce the likelihood of exfiltration of credentials and to enhance
overall security.

* Support for IMDSv2 
* Encryption of credentials in memory
* Ability to disable credential cacheing
* DEBUG set in the environment will no longer enable DEBUG output
* new unit tests

## Fixes

* region set in config file profiles was not being used

# perl-Amazon-Credentials 1.0.6 (2018-08-03)

## Enhancements

* None

## Fixes

* AWS_PROFILE was not being handled correctly when a profile exists in
both configuration files (config, credentials)

# perl-Amazon-Credentials 1.0.5 (2018-04-24)

## Enhancements

* Added CPAN tar ball creation (see README.md)

## Fixes

* deprecated poorly named methods get_ec2_credentials() in favor of
  find_credentials()

# perl-Amazon-Credentials 1.0.4 (2018-04-22)

## Enhancements

* added example that checks for token expiration
* unit tests added
* set_credentials() method can now accept hash to set credential tuple

## Fixes

# set region from file or from instance
* refresh_token() method referenced in documentation was missing

# perl-Amazon-Credentials 1.0.3 (2018-03-21)

## Enhancements

* set region based on environment AWS_REGION as first default, then
availability zone of currently running instance
* look for credentials using the container's metadata service if the
process is running in a container

## Fixes

_None_

# perl-Amazon-Credentials 1.0.2 (2018-03-14)

## Enhancements

* `get_default_region`
   ```
   $ AWS_REGION=$(perl -MAmazon::Credentials -e 'print Amazon::Credentials::get_default_region;')
   my $creds = new Amazon::Credentials;
   print $creds->get_region, "\n";
   ```
* `$VERSION`

## Fixes

# perl-Amazon-Credentials 1.0.1 (2017-11-22)

## Enhancements

## Fixes

* `timegm`, `is_token_expired()`

# perl-Amazon-Credentials 1.0.0 (2017-11-11)

## Enhancements: first release

## Fixes
