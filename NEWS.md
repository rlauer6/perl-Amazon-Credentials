# NEWS

This is the `NEWS` file for the `perl-Amazon-Credentials` project. This file contains
information on changes since the last release of the package, as well as a
running list of changes from previous versions.  If critical bugs are found in
any of the software, notice of such bugs and the versions in which they were
fixed will be noted here, as well.


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
