# NEWS

This is the `NEWS` file for the `perl-Amazon-Credentials`
project. This file contains information on changes since the last
release of the package, as well as a running list of changes from
previous versions.  If critical bugs are found in any of the software,
notice of such bugs and the versions in which they were fixed will be
noted here, as well.

# perl-Amazon-Credentials 1.1.20 (2023-07-17)

## Enhancements

* some refactoring, new unit test

## Fixes

* fixed https://rt.cpan.org/Ticket/Display.html?id=149013 - incorrect
  parsing of AWS config file

# perl-Amazon-Credentials 1.1.19 (2023-05-22)

## Enhancements

* provided hint about `no_passkey_warning` in warning message

## Fixes

* None

# perl-Amazon-Credentials 1.1.18 (2023-01-24)

## Enhancements

* removed Log::Log4perl as a requirement

## Fixes

* None

# perl-Amazon-Credentials 1.1.17 (2023-01-09)

## Enhancements

* None

## Fixes

* removed FOO.pm from distributin

# perl-Amazon-Credentials 1.1.13-16 (2023-01-08)

Versions 1.13 - 1.1.16 provide minor refactoring but no major fixes or
enhancements.

## Enhancements

- new help scripts added to distribution
  * `amazon-credentials`, `get-sso-credentials`
  
## Fixes

- avoid some uninitialized warnings
- fix missing arg in sprintf for die message

# perl-Amazon-Credentials 1.1.12 (2022-08-16)

## Enhancements

* warnings when passkey is being used from multiple instances of
  Amazon::Credentials
* 

## Fixes

* remove credentials from local environment after use
* retrieving credentials from SSO modified current working directory

# perl-Amazon-Credentials 1.1.11 (2022-08-10)

## Enhancements

* retrieve credentials from SSO by passing `sso_role_name` and `sso_account_id`

## Fixes

* None

# perl-Amazon-Credentials 1.1.10 (2022-07-15)

## Enhancements

* removal of passkey from hash to decrease risk of credential leaks
* addition of CLI access to credentials, including SSO credentials

## Fixes

* fix for exercising tests on Perls where '.' is not in path

# perl-Amazon-Credentials 1.1.6 (2022-04-24)

## Enhancements

* refactoring of unit tests

## Fixes

* unit tests on some FreeBSD systems were failing because of missing
  dependencies

# perl-Amazon-Credentials 1.1.4 (2022-04-20)

## Enhancements

* raise_error
* print_error

## Fixes

* missing unit tests in distribution

# perl-Amazon-Credentials 1.1.3 (2022-04-18)

## Enhancements


## Fixes

* unit test fixes (Module::Loaded)

# perl-Amazon-Credentials 1.1.2 (2022-04-17)

## Enhancements

* support older versions of Crypt::CBC by setting -key or -pass
* pod tweaks/corrections

## Fixes

* unit test fixes when no Crypt::CBC available
* requires List::Util 1.5

# perl-Amazon-Credentials 1.1.1 (2022-04-14)

## Enhancements

None

## Fixes

pod fixes

# perl-Amazon-Credentials 1.1.0 (2022-04-14)

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
