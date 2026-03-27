# Amazon::Credentials 1.1.26 Release Notes

**Release Date:** 2026-03-27

## Overview

Replaces `LWP::UserAgent` with `HTTP::Tiny` via a lightweight adapter layer,
consistent with the same change made in `Amazon::API` 2.1.11. Reduces the
dependency footprint for Lambda container deployments where every megabyte
affects cold start time. Also replaces `JSON::PP` with `JSON` throughout, and
adds `release-notes.mk` and `version.mk` build infrastructure.

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

## Changes

### `Amazon::Credentials` (`Credentials.pm`)

All four HTTP call sites updated to use `Amazon::Credentials::HTTP::UserAgent`:

- `get_default_region` — static fallback `LWP::UserAgent->new` replaced
- `get_role_credentials` (IMDS/IMDSv2) — `$ua->request` call unchanged,
  UA construction replaced
- `_get_container_credentials` — UA construction replaced
- `get_role_credentials` (SSO) — refactored from `$ua->default_header` +
  `$ua->get($url)` convenience methods (LWP-specific) to explicit
  `HTTP::Request->new(GET => $url)` + `$req->header(...)` + `$ua->request($req)`

`JSON::PP` replaced with `JSON` throughout.

`LWP::UserAgent` removed from dependency list and POD.

`_set_defaults` timeout option note: `LWP::UserAgent->new(timeout => ...)`
previously honored the `timeout` accessor. `HTTP::Tiny` also supports a
`timeout` option — this has been wired through as well. The default is
correctly set to 3s.
`imdsv2` option - is now true by default. Clients may set this to
false for older EC2 instances that only support IMDSv1.

### New: `normalize_arn`

Converts an STS assumed-role ARN to its equivalent IAM role ARN,
useful when passing identity ARNs from `GetCallerIdentity` to IAM APIs
such as `SimulatePrincipalPolicy` which reject STS assumed-role
ARNs. Non-assumed-role ARNs are returned unchanged. Exported via
`@EXPORT_OK`.

### Tests (`t/02-credentials.t`, `t/03-container.t`)

Mocks updated to stub `Amazon::Credentials::HTTP::UserAgent` in place of
`LWP::UserAgent`. Additional `HTTP::Request` method stubs added (`headers`,
`content`, `method`, `uri`) and `HTTP::Headers::scan` stubbed as a no-op,
required by the new adapter's header extraction logic.

`JSON::PP` replaced with `JSON`.

### Dependencies

Added: `HTTP::Headers`, `IO::Socket::SSL`, `Net::SSLeay`, `URI`, `JSON`

Removed: `LWP::UserAgent`, `JSON::PP`

Moved to recommends: `Crypt::CBC`, `Crypt::Cipher::AES`

### Build

- `release-notes.mk` — new, provides `make release-notes` target
- `version.mk` — new, provides `make release`, `make minor`, `make major`
  version bump targets
- `cpan/recommends` — new, separates optional encryption dependencies from
  hard requirements
- `cpan/test-requires` — trimmed to actual test dependencies

---

## Known Issues

`t/10-logging.t` mocks `Amazon::Credentials::UserAgent` instead of
`Amazon::Credentials::HTTP::UserAgent` — the correct fully-qualified name.
The test passes because the logging test does not exercise the HTTP path
deeply enough to instantiate the UA. This should be corrected in 1.1.27.

---

## Upgrade Notes

`LWP::UserAgent` is no longer a dependency. SSL support now requires
`IO::Socket::SSL` and `Net::SSLeay` to be installed explicitly.

If you supply a custom user agent via the `user_agent` constructor option
it must accept a single `HTTP::Request` argument to `request` and return
an object implementing `content`, `content_type`, `is_success`, `code`,
and `message`.

The `timeout` constructor option is currently not forwarded to
`HTTP::Tiny->new`. If you rely on the timeout behavior, set a custom
user agent with the desired timeout: 
`Amazon::Credentials::HTTP::UserAgent->new(timeout => $seconds)`.
