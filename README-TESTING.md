# README 

This document describes the testing that can be done for the
`Amazon::Credentials` package.

# Unit Tests

There are several unit tests that can be run that exercise various
parts of the package. Most tests do not require actually
communicating with AWS or access to actual credentials.

| Test Name | Description | Requires AWS Account or Credentials |
| --------- | ----------- | -------------------- |
| 00-credentials.t | basic test of module | No
| 01-credentials.t | read credentials from profile | No
| 02-credentials.t | test token expiration and refresh | No
| 03-container.t | read credentials from container role | No
| 04-process.t | read credentials from an external process | No
| 05-format.t | format credentials as string for export  | No
| 06-security.t | tests whether credentials are exposed by debug messages | No
| 07-encryption.t | tests encryption of credentials in memory | No
| 08-imdsv2.t | tests use of new IMDSv2 token based access to metadata | Yes
| 09-live-credentials.t | test fetching live credentials | Yes |
| 10-logging.t | test the use of default and custom logger | No |
| 11-order.t | check the setting of the order attribute | No |

To enable tests that require an AWS account set the environment
variable AWS_AMAZON_CREDENTIALS_TEST_ALL to any value.

To run the tests (after you have built the package):

```
cd src/main/perl/t
prove -I lib -v t/
```

