# Amazon::Credentials 1.2.0 Release Notes

**Release Date:** 2026-03-28

## Overview

A significant modernization release. Replaces `LWP::UserAgent` with
`HTTP::Tiny` throughout via a new lightweight adapter layer, bringing
`Amazon::Credentials` in line with the same change made in `Amazon::API`
2.1.11. Adds two new credential providers — full URI container credentials
(covering Lambda, Fargate, and EKS Pod Identity) and web identity token
federation (covering EKS IRSA and GitHub Actions OIDC) — bringing the
credential chain to parity with the AWS SDK's default provider chain.
Also replaces `JSON::PP` with `JSON`, makes IMDSv2 the default, and adds
`release-notes.mk` and `version.mk` build infrastructure.

---

## New Modules

### `Amazon::Credentials::HTTP::UserAgent`

Thin adapter wrapping `HTTP::Tiny`. Accepts an `HTTP::Request` object,
extracts method, URI, headers, and content, and delegates to
`HTTP::Tiny->request`. The `Host` header is filtered before passing to
HTTP::Tiny, which manages that header itself and rejects it if supplied.
Returns an `Amazon::Credentials::HTTP::Response` object.

### `Amazon::Credentials::HTTP::Response`

Adapter wrapping HTTP::Tiny's response hashref in an object presenting the
`LWP::HTTP::Response` interface. Implements `content`, `content_type`,
`is_success`, `code`, and `message` so all existing response-handling code
in `Credentials.pm` is unchanged.

---

## New Credential Providers

### Full URI Container Credentials (`FULL_URI`)

`get_creds_from_container` now supports `AWS_CONTAINER_CREDENTIALS_FULL_URI`
in addition to the existing `AWS_CONTAINER_CREDENTIALS_RELATIVE_URI`. The
full URI form is the credential mechanism used by:

- **Lambda** execution roles (the runtime sets `FULL_URI` and
  `AWS_CONTAINER_AUTHORIZATION_TOKEN`)
- **Fargate** task roles
- **EKS Pod Identity** (agent at `http://169.254.170.23`)

The implementation enforces the same URL security constraint as the AWS SDK:
only `https://`, `http://127.x.x.x`, `http://[::1]`, and
`http://169.254.170.23` are permitted, preventing SSRF attacks via a
malicious `FULL_URI` value.

Authorization tokens are read automatically from
`AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE` (preferred) or
`AWS_CONTAINER_AUTHORIZATION_TOKEN`.

The `container` key in the returned credentials hash is `'ECS'` for the
relative URI form and `'full_uri'` for the full URI form.

### Web Identity / OIDC Federation

New method `get_creds_from_web_identity` exchanges an OIDC/JWT token for
temporary AWS credentials via STS `AssumeRoleWithWebIdentity`. This covers:

- **EKS IRSA** (IAM Roles for Service Accounts)
- **GitHub Actions** OIDC federation
- Any OIDC-compatible identity provider

Required environment variables: `AWS_WEB_IDENTITY_TOKEN_FILE` and
`AWS_ROLE_ARN`. Optional: `AWS_ROLE_SESSION_NAME` (defaults to
`amazon-credentials-session`).

The STS call is made **without AWS request signing** — the OIDC token itself
authenticates the request. This resolves the chicken-and-egg problem of
needing credentials to obtain credentials. No new dependencies are added:
the STS XML response is parsed with targeted regex, and URI encoding is
handled inline.

`web_identity` is now part of the default search order:

```
environment => container => role => web_identity => file
```

---

## Changes

### `Amazon::Credentials` (`Credentials.pm`)

**HTTP::Tiny replaces LWP::UserAgent** at all four call sites:

- `get_default_region` — static fallback `LWP::UserAgent->new` replaced
- `get_creds_from_role` (IMDS/IMDSv2) — UA construction replaced
- `get_creds_from_container` — UA construction replaced; method refactored
  into `_get_creds_from_relative_uri` and `_get_creds_from_full_uri`
- `get_role_credentials` (SSO) — refactored from LWP-specific
  `$ua->default_header` + `$ua->get($url)` to explicit
  `HTTP::Request->new(GET => $url)` + `$req->header(...)` + `$ua->request($req)`

**IMDSv2 is now enabled by default.** The `imdsv2` constructor option
defaults to `true`. Set `imdsv2 => 0` for older EC2 instances that only
support IMDSv1. AWS recommends IMDSv2 for all EC2 workloads.

**`DEFAULT_TIMEOUT` corrected** from 2s to 3s (was incorrectly set in a
prior release).

**`JSON::PP` replaced with `JSON`** throughout.

**New exported function: `normalize_arn`** — converts an STS assumed-role
ARN to its equivalent IAM role ARN. Useful when an ARN from
`GetCallerIdentity` needs to be passed to IAM APIs such as
`SimulatePrincipalPolicy` that reject STS assumed-role ARNs.

**New private helpers:** `_get_creds_from_relative_uri`,
`_get_creds_from_full_uri`, `_read_container_auth_token`,
`get_creds_from_web_identity`, `_xml_element`, `_extract_sts_error`,
`_uri_escape`.

### Tests

- `t/02-credentials.t` — mocks updated to stub
  `Amazon::Credentials::HTTP::UserAgent` in place of `LWP::UserAgent`;
  additional `HTTP::Request` method stubs added (`headers`, `content`,
  `method`, `uri`); `HTTP::Headers::scan` stubbed as a no-op; `JSON::PP`
  replaced with `JSON`; `imdsv2 => 0` added to avoid IMDSv2 token fetch
  in unit test context
- `t/03-container.t` — same UA mock updates; `JSON::PP` replaced with `JSON`
- `t/05-format.t` — `JSON::PP` replaced with `JSON`
- `t/06-security.t` — `JSON::PP` removed (unused)
- `t/07-encryption.t` — `JSON::PP` removed; Blowfish skip condition
  improved to check for actual module absence rather than any eval error
- `t/08-imdsv2.t` — `no_passkey_warning => 1` added to suppress spurious
  warning in test output
- `t/09-live-credentials.t` — `JSON::PP` removed; `no_passkey_warning => 1`
  added; `AWS_PROFILE` note added to README-TESTING.md
- `t/10-logging.t` — `LWP::UserAgent` mock corrected to
  `Amazon::Credentials::HTTP::UserAgent` (fixes the known issue documented
  in the draft 1.1.26 notes)
- `t/02-web-identity.t` — **new**; covers `_xml_element`, `_extract_sts_error`,
  `_uri_escape`, query string construction, and integration tests for all
  `get_creds_from_web_identity` paths via mocked UA

### Dependencies

Added: `HTTP::Headers`, `IO::Socket::SSL`, `Net::SSLeay`, `JSON`

Removed: `LWP::UserAgent`, `JSON::PP`

Moved to recommends: `Crypt::CBC`, `Crypt::Cipher::AES`

### Build

- `release-notes.mk` — new; provides `make release-notes` target that
  generates diff, file list, and tarball against the previous tagged version
- `version.mk` — new; provides `make release`, `make minor`, `make major`
  version bump targets
- `cpan/recommends` — new; separates optional encryption dependencies from
  hard requirements
- `cpan/test-requires` — trimmed to actual test dependencies
- `cpan/requires` — `LWP::UserAgent`, `JSON::PP` removed; `HTTP::Headers`,
  `IO::Socket::SSL`, `Net::SSLeay`, `JSON` added

---

## Upgrade Notes

**`LWP::UserAgent` is no longer a dependency.** SSL support now requires
`IO::Socket::SSL` and `Net::SSLeay` to be installed explicitly if not
already present.

**IMDSv2 is now the default.** If you are running on older EC2 instances
that only support IMDSv1, pass `imdsv2 => 0` to the constructor.

**Custom user agents** supplied via the `user_agent` constructor option must
accept a single `HTTP::Request` argument to `request` and return an object
implementing `content`, `content_type`, `is_success`, `code`, and `message`.
The `timeout` option is forwarded to `HTTP::Tiny->new` and defaults to 3s.

**Lambda users** no longer need to set `order => [qw(container)]` explicitly.
With `FULL_URI` support now in the `container` provider, the default search
order resolves Lambda execution role credentials automatically.

**EKS IRSA users** benefit from the new `web_identity` provider, which fires
automatically when `AWS_WEB_IDENTITY_TOKEN_FILE` and `AWS_ROLE_ARN` are set
in the environment, as they are by default on EKS with IRSA configured.
