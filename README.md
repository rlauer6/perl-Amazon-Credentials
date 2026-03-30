# NAME

Amazon::Credentials - fetch Amazon credentials from file, environment or role

# SYNOPSIS

    my @order = qw( env file container role );
    my $creds = Amazon::Credentials->new( { order => \@order } );

CLI

    amazon-credentials --help

# DESCRIPTION

`Amazon::Credentials` finds AWS credentials from a chain of providers,
searching in a configurable order until credentials are found. The default
search order is:

    environment => container => role => web_identity => file

The following credential sources are supported:

- **Environment** — `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
and optionally `AWS_SESSION_TOKEN`.
- **Container** — ECS task roles via
`AWS_CONTAINER_CREDENTIALS_RELATIVE_URI` (classic ECS), or any container
runtime that provides `AWS_CONTAINER_CREDENTIALS_FULL_URI` — including
Lambda execution roles, Fargate task roles, and EKS Pod Identity.
- **Instance role** — EC2 instance profile credentials via the IMDSv2
metadata endpoint (`http://169.254.169.254`). Respects
`AWS_EC2_METADATA_DISABLED`.
- **Web Identity** — OIDC/JWT federation via STS
`AssumeRoleWithWebIdentity`. Used by EKS IRSA (IAM Roles for Service
Accounts) and GitHub Actions. Requires `AWS_WEB_IDENTITY_TOKEN_FILE`
and `AWS_ROLE_ARN`.
- **File** — `~/.aws/credentials` and `~/.aws/config` profiles,
including credential\_process and SSO configurations.

You can control which sources are tried, and in what order, via the
`order` option in the constructor. See ["new"](#new).

This class also supports SSO credentials. See ["set\_sso\_credentials"](#set_sso_credentials)
and ["get\_role\_credentials"](#get_role_credentials) for details, or use the command line tool:

    amazon-credentials.sh --role my-sso-role --account 01234567890

## AWS\_EC2\_METADATA\_DISABLED

`Amazon::Credentials` tries hard to find credentials, searching the
environment, ECS container endpoint, EC2 instance metadata, and credential
files in turn. In some situations — particularly local development or CI
environments where no metadata endpoint is reachable — this eagerness causes
an unwanted delay while the module waits for the metadata request to time out.

You have two options for dealing with this. The first is to set
`AWS_EC2_METADATA_DISABLED` to a true value, which disables the search for
role credentials via the EC2 instance metadata endpoint entirely. The second
is to reduce the timeout via the `timeout` constructor option (default is 3
seconds), which limits how long the module waits for the metadata endpoint to
respond:

    my $creds = Amazon::Credentials->new( timeout => 1 );

The preferred approach when your application is designed to run in a specific
environment is to pass an explicit `order` to the constructor, which avoids
the search entirely:

    my $creds = Amazon::Credentials->new( order => [qw(role)] );

The default credential search order is:

    environment => container => role => web_identity => file (profile)

# VERSION

This document reverse to verion 1.2.0 of
[Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials).

# METHODS AND SUBROUTINES

## new

    new( options );

    my $aws_creds = Amazon::Credential->new( { profile => 'sandbox', debug => 1 });

`options` is a hash of keys that represent various options you can
pass to the constructor to control how it will look for credentials.
Any of the options can also be retrieved using their corresponding
'get\_{option} method.

### options

- aws\_access\_key\_id

    AWS access key.

- aws\_secret\_access\_key

    AWS secret access key.

    _Note: If you pass the access keys in the constructor then the
    constructor will not look in other places for credentials._

- cache

    boolean when set to false will prevent [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) from
    cacheing credentials. **Cacheing is enabled by default.**

    _Note that the if cacheing is disabled, the module will obtain
    credentials on the first call to one of the getters
    (`get_aws_secret_access_key`, `get_aws_access_key_id` or
    `get_token`). After each method call to retrieve the credential it
    will be removed. However, for a brief period before all of them have
    been accessed by the getter credentials will be locally stored._

    If you use the `credential_keys` method for retrieving credentials,
    the entire tuple of credentials will be immediately passed to you
    without cacheing (if cacheing is disabled).

- container

    If the process is running in a container, this value will contain
    a string indicating the credential source. The class supports two
    forms of container credentials:

    **Relative URI** (classic ECS on EC2): credentials are fetched from
    the ECS container metadata endpoint using
    `AWS_CONTAINER_CREDENTIALS_RELATIVE_URI`:

        http://169.254.170.2/$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI

    **Full URI** (Lambda, Fargate, EKS Pod Identity): credentials are
    fetched from the full URL provided in
    `AWS_CONTAINER_CREDENTIALS_FULL_URI`. The URL must be `https://`,
    `http://127.x.x.x`, `http://[::1]`, or
    `http://169.254.170.23` (EKS Pod Identity agent). An optional
    authorization token may be provided via
    `AWS_CONTAINER_AUTHORIZATION_TOKEN` or
    `AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE`.

    The `container` metadata key in the returned credentials hash will
    be `'ECS'` for the relative URI form and `'full_uri'` for the full
    URI form.

- debug

    Set to true for verbose troubleshooting information. Set `logger` to
    a logger that implements a logging interface (ala
    [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl).

- decrypt

    Reference to a custom method that will decrypt credentials prior to
    returning them from the cache. The method will be passed the string to
    decrypt and a passkey.

- encrypt

    Reference to a custom method that will encrypt credentials prior to
    storing them in the cache.  The method will be passed a string to
    encrypt and the passkey.

- env - Environment

    If there exists an environment variable $AWS\_PROFILE, then an attempt
    will be made to retrieve credentials from the credentials file using
    that profile, otherwise the class will for these environment variables
    to provide credentials.

        AWS_ACCESS_KEY_ID
        AWS_SECRET_ACCESS_KEY
        AWS_SESSION_TOKEN

    _Note that when you set the environment variable AWS\_PROFILE, the
    order essentially is overridden and the class will look in your
    credential files (`~/.aws/config`, `~/.aws/credentials`) to resolve
    your credentials._

- file - Configuration Files

    - ~/.aws/config
    - ~/.aws/credentials

    The class will attempt to resolve credentials by interpretting the
    information in these two files. You can also specify a profile to use
    for looking up the credentials by passing it into the constructor or
    setting it the environment variable `AWS_PROFILE`.  If no profile is
    provided, the default credentials or the first profile found is used.

        my $aws_creds = Amazon::Credentials->new({ order => [qw/environment role file/] });

- insecure

    A debugging mode can be enabled to display information that may aid in
    troubleshooting, however output may include credentials.  This
    attribute prevents accidental exfiltration of credentials during
    troubleshooting. The default setting of `insecure` is therefore
    `false`. This will prevent debug messages that may contain credentials
    (HTTP response, configuration file contents) from exposing sensitive
    data.

    Set the value to 1 to enable all debug output **except** the content of
    credentials in HTTP responses. Set the value to 2 to enable full debug
    output.

    _Note that setting the value to 1 will enable the use of regular
    expressions to suppress credential contents. Credentials that do not
    conform to these may still be exposed. Caution is advised._

- imdsv2

    Boolean flag that causes `Amazon::Credentials` to use the IMDSv2
    protocol when retrieving instance role credentials from the EC2 metadata
    service. IMDSv2 uses a session-oriented approach requiring a token to be
    fetched before making metadata requests, providing stronger protection
    against SSRF attacks.

    Default: true

    AWS recommends IMDSv2 for all EC2 workloads. IMDSv1 can be disabled at
    the instance or account level as a security hardening measure, in which
    case this option must be enabled for instance role credential retrieval
    to succeed.

- logger

    Pass in your own logger that has a `debug()` method.  Otherwise the
    default logger will output debug messages to STDERR.

- no\_passkey\_warning

    Boolean that indicates whether warning messages about passkey usage
    should be supressed.

    If you attempt to reset the passkey or if you instantiate a second
    instance of Amazon::Credentials, the constructor will issue warnings.

    Resetting a passkey means that you previous version of
    Amazon::Credentials will no longer be able to decrypt credentials
    unless you restore the original passkey.

    If you instantiate another version of Amazon::Credentials without
    resetting the passkey, the new instance will use the old value for the
    passkey. This is by design.

    default: false

- order

    An array reference containing tokens that specifies the order in which the class will
    search for credentials.

    default:  env, role, container, file

    Example:

        my $creds = Amazon::Credentials->new( { order => [ qw/file env role/] });

- passkey

    A custom passkey for encryption. You can pass a scalar or a reference
    to a subroutine that returns the passkey. The return value of the
    subroutine should be idempotent, however you can change the subroutine
    used for encryption if you are **not** cacheing the credentials.  If
    you are cacheing credentials you should reset the credentials with the
    new passkey method.

        $credentials->set_passkey(\&new_passkey_provider);
        $credentials->reset_credentials(1);

- print\_error

    Whether to print the error if no credenials are found. `raise_error`
    implies `print_error`.

    default: true

- profile

    The profile name in the configuration file (`~/.aws/config` or
    `~/.aws/credentials`).

        my $aws_creds = Amazon::Credentials->new({ profile => 'sandbox' });

    The class will also look for the environment variable `AWS_PROFILE`,
    so you can invoke your script like this:

        $ AWS_PROFILE=sandbox my-script.pl

- raise\_error

    Whether to raise an error if credentials are not found.

    default: true

- region

    Default region. The class will attempt to find the region in either
    the configuration files or the instance unless you specify the region
    in the constructor.

- role - Instance Role

    The class will use the
    _http://169.254.169.254/latest/meta-data/iam/security-credential_ URL
    to look for an instance role and credentials.

    Credentials returned by accessing the meta-data include a token that
    should be passed to Amazon APIs along with the access key and secret.
    That token has an expiration and should be refreshed before it
    expires.

        if ( $aws_creds->is_token_expired() ) {
          $aws_creds->refresh_token()
        }

- timeout

    When looking for credentials in metadata URLs, this parameter
    specifies the timeout value in seconds for HTTP metadata sevice
    requests.

    default: 3s

- user\_agent

    Pass in your own user agent, otherwise `Amazon::Credentials::HTTP::UserAgent`
    (backed by `HTTP::Tiny`) will be used. The object must implement a `request`
    method accepting an `HTTP::Request` object and returning a response object
    with `content`, `content_type`, `is_success`, `code`, and `message` methods.
    Probably only useful to override for testing purposes.

## as\_string

    as_string()

Returns the credentials as a JSON encode string.

## credential\_keys

    my $credential_keys = $creds->credential_keys;

Return a hash reference containing the credential keys with standard
key names. Note that the session token will only be present in the
hash for temporary credentials.

- AWS\_ACCESS\_KEY\_ID
- AWS\_SECRET\_ACCESS\_KEY
- AWS\_SESSION\_TOKEN

## format\_credentials

    format_credentials(format-string)

Returns the credentials as a formatted string.  The &lt;format> argument
allows you to include a format string that will be used to output each
of the credential parts.

    format("export %s=%s\n");

The default format is a "%s %s\\n".

## find\_credentials

    find_credentials( option => value, ...);

You normally don't want to use this method. It's automatically invoked
by the constructor if you don't pass in any credentials. Accepts a
hash or hash reference consisting of keys (`order` or `profile`) in
the same manner as the constructor.

## get\_creds\_from\_\*

These methods are called internally when the `new` constructor is
invoked. You should never need to call these methods. All of these
methods will return a hash of credential information and metadata
described below.

- aws\_access\_key\_id

    The AWS access key.

- aws\_secret\_access\_key

    The AWS secret key.

- token

    Security token used with access keys.

- expiration

    Token expiration date.

- role

    IAM role if available.

- source

    The source from which the credentials were found. 

    - IAM - retrieved from container or instance role
    - container - `'ECS'` if retrieved via `AWS_CONTAINER_CREDENTIALS_RELATIVE_URI`;
    `'full_uri'` if retrieved via `AWS_CONTAINER_CREDENTIALS_FULL_URI`
    - web\_identity - retrieved via STS AssumeRoleWithWebIdentity
    - file - retrieved from file
    - process - retrieved from an external process
    - ENV - retrieved from environment

### get\_creds\_from\_container

    get_creds_from_container()

Retrieves credentials from the container credential endpoint. Supports
two mechanisms, tried in this order:

**Relative URI** — if `AWS_CONTAINER_CREDENTIALS_RELATIVE_URI` is set,
credentials are fetched from:

    http://169.254.170.2/$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI

**Full URI** — if `AWS_CONTAINER_CREDENTIALS_FULL_URI` is set, that URL
is used directly. Covers Lambda execution roles, Fargate task roles, and
EKS Pod Identity. An authorization token is added automatically if
`AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE` or
`AWS_CONTAINER_AUTHORIZATION_TOKEN` is set in the environment.

Returns an empty hash if neither environment variable is set.

### get\_creds\_from\_web\_identity

    get_creds_from_web_identity()

Retrieves temporary credentials by exchanging an OIDC/JWT web identity
token for AWS credentials via STS `AssumeRoleWithWebIdentity`. This is
the credential mechanism used by EKS IRSA (IAM Roles for Service
Accounts) and GitHub Actions OIDC federation.

Required environment variables:

- `AWS_WEB_IDENTITY_TOKEN_FILE`

    Path to a file containing the OIDC/JWT token.

- `AWS_ROLE_ARN`

    ARN of the IAM role to assume.

Optional:

- `AWS_ROLE_SESSION_NAME`

    A name for the assumed role session. Defaults to
    `amazon-credentials-session`.

The STS call is made without AWS request signing — the OIDC token
itself authenticates the request, resolving the chicken-and-egg problem
of needing credentials to obtain credentials. The regional STS endpoint
is used when `AWS_DEFAULT_REGION` or `AWS_REGION` is set; otherwise
the global `sts.amazonaws.com` endpoint is used.

Returns an empty hash if the required environment variables are not set,
if the token file cannot be read, or if the STS call fails.

### get\_creds\_from\_process

    get_creds_from_process(process)

Retrieves credentials from a helper process defined in the config
file. Returns the credentials tuple.

### get\_creds\_from\_role

    get_creds_from_role()

Returns a hash, possibly containing access keys and a token.

## get\_default\_region

Returns the region of the currently running instance or container.
The constructor will set the region to this value unless you set your
own `region` value. Use `get_region` to retrieve the value after
instantiation or you can call this method again and it will make a
second call to retrieve the instance metadata.

## get\_ec2\_credentials (deprecated)

See ["find\_credentials"](#find_credentials)

## is\_token\_expired

    is_token_expired( window-interval )

Returns true if the token is about to expire (or is
expired). `window-interval` is the time in minutes before the actual
expiration time that the method should consider the token expired.
The default is 5 minutes.  Amazon states that new credentials will be
available _at least_ 5 minutes before a token expires.

## normalize\_arn

    normalize_arn( arn )

    # as an exported function
    use Amazon::Credentials qw(normalize_arn);
    my $iam_arn = normalize_arn($sts_arn);

    # or as a method
    my $iam_arn = $creds->normalize_arn($sts_arn);

Converts an STS assumed-role ARN to its equivalent IAM role ARN.

    arn:aws:sts::123456789:assumed-role/my-role/session-name
      => arn:aws:iam::123456789:role/my-role

This is useful when an ARN obtained from `GetCallerIdentity` needs to be
passed to IAM APIs such as `SimulatePrincipalPolicy` which require an IAM
ARN and will reject STS assumed-role ARNs. Non-assumed-role ARNs (IAM users,
IAM roles) are returned unchanged.

## reset\_credentials

By default this method will remove credentials from the cache if you
pass a false or no value. Passing a true value will refresh your
credentials from the original source (equivalent to calling
`set_credentials`).

## refresh\_token (deprecated)

use `refresh_credentials()`

## refresh\_credentials()

Retrieves a fresh set of IAM credentials.

    if ( $creds->is_token_expired ) {
      $creds->refresh_token()
    }

## set\_credentials

Looks for your credentials according to the order specified by the
`order` attribute passed in the constructor and stores the
credentials in the cache.

_Note that you should never have to call
this method. If you call this method it will ignore your cache
setting!_

# SSO CREDENTIALS

You can retrieve your SSO credentials after logging in using the
`sso_set_credentials` or `get_role_credentials` methods.

After logging in using your SSO credentials...

    aws sso login

...call one of the methods below to retrieve your credentials.

## get\_role\_credentials

    get_role_credentials( options )

`options` is a hash (not reference) of options

- role\_name => role name (required)
- account\_id => AWS account id (required)
- region => AWS region where SSO has been provisioned

    default: $ENV{AWS\_REGION}, $ENV{AWS\_DEFAULT\_REGION}, us-east-1

## set\_sso\_credentials

    set_sso_options(role-name, account-id, region)

Calls `get_role_credentials` and set AWS credenital environment
variables. Region is optional, all other parameters are required.

    use Amazon::Credentials qw(set_sso_credentials)

    set_sso_credentials(@ENV{qw(AWS_ROLE_NAME AWS_ACCOUNT_ID)});

    my $credentials = Amazon::Credentials->new;

# SETTERS/GETTERS

All of the options described in the new method can be accessed by a
_getter_ or set using a _setter_ of the same name.

Example:

    $creds->set_cache(0);

# DIAGNOSTICS

Set the `debug` option when you instantiate a [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials)
object to output debug and diagnostic messages. Note that you must
also set the `insecure` option if you want to output full
diagnostics. _WARNING: Full diagnostics may include credentials. Be
careful not to expose these values in logs._

# CONFIGURATION AND ENVIRONMENT

The module will recognize several AWS specific environment variables
described throughout this documentation.

- AWS\_ACCESS\_KEY\_ID
- AWS\_SECRET\_ACCESS\_KEY
- AWS\_SESSION\_TOKEN
- AWS\_REGION
- AWS\_DEFAULT\_REGION
- AWS\_CONTAINER\_CREDENTIALS\_RELATIVE\_URI
- AWS\_CONTAINER\_CREDENTIALS\_FULL\_URI
- AWS\_CONTAINER\_AUTHORIZATION\_TOKEN
- AWS\_CONTAINER\_AUTHORIZATION\_TOKEN\_FILE
- AWS\_WEB\_IDENTITY\_TOKEN\_FILE
- AWS\_ROLE\_ARN
- AWS\_ROLE\_SESSION\_NAME

# BUGS AND LIMITATIONS

[Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) will **not** attempt to retrieve temporary
credentials for profiles that specify a role. If for example you
define a role in your credentials file thusly:

    [developer]

     role_arn = arn:aws:iam::123456789012:role/developer-access-role
     source_profile = dev

The module will not return credentials for the _developer_
profile. While it would be theoretically possible to return those
credentials, in order to assume a role, one needs credentials (chicken
and egg problem).

Note that `get_creds_from_web_identity` resolves this problem for
OIDC-federated environments (EKS IRSA, GitHub Actions) by calling STS
`AssumeRoleWithWebIdentity`, which does not require AWS signing — the
OIDC token authenticates the request directly.

# DEPENDENCIES

Lower versions of these modules may be acceptable.

    'Class::Accessor::Fast' => '0.31'
    'Config::Tiny'          => '2.28'
    'Date::Format'          => '2.24'
    'File::HomeDir'         => '1.00'
    'File::chdir'           => '0.1010'
    'HTTP::Request'         => '6.00'
    'List::Util'            => '1.5'
    'POSIX::strptime'       => '0.13'

...and possibly others

In order to enable true encryption of your credentials when cached,
[Crypt::CBC](https://metacpan.org/pod/Crypt%3A%3ACBC) is also required.

# SECURITY CONSIDERATIONS

The security concern around your credentials is not actually the fact
that the credentials can be retrieved and viewed - any process that
compromises your environment can use the same methods this class does
to resolve those credentials. Let me repeat that. If your environment
is compromised then an actor can use all of the methods employed in
this module to access your credentials.

The major issue you should be concerned about is exposing your
credentials outside of the environment running your program.  Thats
is, the exfiltration of your credentials.  Once you have resolved
these credentials you may inadvertantly reveal them in many
ways. Dumping objects to logs, saving your credentials in files or
even outputing them to your console may expose your credentials. This
module will now at the very least obfuscate them when they are stored
in memory. Accidental dumping of objects will not reveal your
credentials in plain-text.

**Always take precautions to prevent accidental exfiltration of your
credentials.**

## How [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) Helps Prevent Exfiltration

For performance and historical reasons the default is for
[Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) to cache your credentials. Starting with
version _1.1.0_, the module will attempt to encrypt the credentials
before storing them. The module uses [Crypt::CBC](https://metacpan.org/pod/Crypt%3A%3ACBC) (if available) with
the default cipher and a random (or user defined) passkey.

Even if [Crypt::CBC](https://metacpan.org/pod/Crypt%3A%3ACBC) is not available, the module will try to
obfuscate the credentials. A determined actor can still decrypt these
keys if they have access to the obfuscated values and your
passkey. You have several options to better secure your credentials
from exposure.

- Option 1 - Do not cache your credentials.

    Use the `set_cache()` method with a false value or set `cache` to
    false when you instantiate the class. **The default is to cache
    credentials.**

        my $credentials = Amazon::Credentials->new(cache => 0);

    Normally, your credentials are fetched when the [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials)
    object is instantiated. With cacheing turned off credentials will not
    be fetched until they are first requested.

    There are two ways your programs typically will fetch the keys; either
    using the getter methods on the individual credentials keys or by
    retrieving a hash containing all of the keys.

    - `credential_keys()`

        Use the method `credential_keys` to retrieve all of the keys at once
        as a hash. Using this method with cacheing turned off will prevent
        [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) from ever saving your credentials to variables
        that can be inadvertantly exposed. Each subsequent request for the
        keys will cause [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) to fetch the keys again.

    - Getter Methods

        If you use the individual getters (`get_aws_access_key_id`,
        `get_aws_secret_access_key` and `get_token`), the keys will first be
        fetched and stored. As each getter is called the key will be removed
        (burn after reading, so to speak). Therefore, for a brief period your
        credentials will be cached even if cacheing is turned off.

- Option 2 - Remove them manually after use

    Call the `reset_credentials()` with a false value after
    fetching credentials or after they are used by downstream
    processes. Call the `reset_credential()` method with a true value to
    regenerate credentials.

- Option 3 - Encrypt your credentials

    [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) will encrypt your credentials by default
    starting with version _1.1.0_. If [Crypt::CBC](https://metacpan.org/pod/Crypt%3A%3ACBC) is available, the
    class will use the default cipher and a random passkey to encrypt your
    credentials. If the encryption module is not available, the class will
    still obfuscate (not encrypt) the credentials. Encryption when the
    passkey and method used are known to a determined bad actor is
    no better than obfuscation. Accordingly, there are several ways you
    can and should encrypt credentials in a more secure way.

    - Using a Custom `passkey`

        By default the module will generate its own random passkey during
        initialization and use that to encrypt and decrypt the
        credentials. Obviously the passkey must be available for
        [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) to decrypt the keys, however it is **NOT**
        stored in the blessed hash reference that stores other data used by
        the class. Instead the passkey is a class variable and will be
        initialized once for all instances of [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) your
        script uses.

        If you plan on using multiple instances of [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) **and**
        you are passing in your own passkeys, then you'll need to reset the
        passkey for each use of the credentials. See the example below in the
        ["Using Multiple Instances of Amazon::Credentials"](#using-multiple-instances-of-amazon-credentials) section.

        To avoid having the class know about your passkey at all, pass a
        reference to a subroutine that will provide the passkey for encryption
        and decryption. You can even use the same passkey generator that is
        used by [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) (`create_passkey`).

        The point here is to avoid storing your passkey in the same object as
        the credentials to minimize the likelihood of exposing your
        credentials or your methods for encryption in logs...better but not
        perfect. It's still may be possible to expose your passkey and your
        credentials if you are not careful.

            use Amazon::Credentials qw( create_passkey );

            my $passkey = create_passkey();

            my $credentials = Amazon::Credentials->new(
                 passkey => sub { return caller(0) eq 'Amazon::Credentials' && $passkey },
             );

        A more secure approach would be for your subroutine to retrieve a
        passkey from a source other than your own program and **never** store
        the passkey inside your program.

    - Using Multiple Instances of Amazon::Credentials

        You may at times need to assume a role using initial credentials. In
        this case you can use multiple instances of
        [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials). Let's suppose that you have logged in with
        your SSO credentials but your script must assume a role in another
        account to perform some action.

            # 1. retrieve SSO credentials
            my $sso_credentials = Amazon::Credentials->new(
              sso_role_name  => 'developer',
              sso_account_id => '01234567890'
            );

            # 2. assume a role in another account
            my $role_arn = 'arn:aws:iam::09876543210:role/Route53AccountAccessRole';
            my $role_session_name = "route53-role-$PID";

            # using the SSO credentials which presumably allow you to assume the role...
            my $sts = Amazon::API::STS->new( credentials => $sso_credentials );

            my $assume_role_result = $sts->AssumeRole(
              { RoleArn         => $role_arn,
                RoleSessionName => $role_session_name,
              }
            );

            my $assume_role_credentials = $assume_role_result->{AssumeRoleResult}->{Credentials};

            # 3. create new credentials for assumed role
            my $role_credentials = Amazon::Credentials->new(
              aws_access_key_id     => $assume_role_credentials->{AccessKeyId},
              aws_secret_access_key => $assume_role_credentials->{SecretAccessKey},
              expiration            => $assume_role_credentials->{Expiration},
              token                 => $assume_role_credentials->{SessionToken},
             );

            # 4. make a call to another API
            my $rt53 = Amazon::API::Route53->new(
              credentials => $role_credentials,
             );

            my $list_tags_for_resources_response = $rt53->ListTagsForResources(
               { ResourceType => 'hostedzone',
                 ResourceIds  => \@zone_ids,
               }
             );

        As noted above, when you use multiple instances of
        [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials), the _same_ passkey is used for encrypting
        credentials. To avoid this, you can pass a custom passkey when you
        instantiate the [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) object, however, you will need
        to reset that passkey when you use that object.

            use Amazon::Credentials qw(create_passkey);

            my %passkey = (
              sso  => create_passkey,
              role => create_passkey,
            );

            my $sso_creds = sub { return $passkey{sso} };
            my $role_creds = sub { return $passkey{role} };

            my $sso_credentials = Amazon::Credentials->new(
              sso_role_name  => 'developer',
              sso_account_id => '01234567890'
              passkey        => $sso_creds,
            );

            ... 

            my $role_credentials = Amazon::Credentials->new(
              aws_access_key_id     => $assume_role_credentials->{AccessKeyId},
              aws_secret_access_key => $assume_role_credentials->{SecretAccessKey},
              token                 => $assume_role_credentials->{SessionToken},
              expiration            => $assume_role_credentials->{Expiration},
              passkey               => $role_creds,
            );

        ...then later

            $sso_credentials->set_passkey($sso_creds);

    - Using a Custom Cipher

        As noted, the default [Crypt::CBC](https://metacpan.org/pod/Crypt%3A%3ACBC) cipher is used for encrypting your
        credentials, however you can pass a custom cipher supported by
        [Crypt::CBC](https://metacpan.org/pod/Crypt%3A%3ACBC) further obfuscating the methods used to encrypt your
        credentials.

            my $credentials = Amazon::Credentials(
              passkey => \&fetch_passkey,
              cipher  => 'Blowfish'
            );

    - Rotating Passkeys and Credentials

        For those with the (justifiably) paranoid feeling that no matter what
        you do there are those determined to crack even encrypted or obfuscated
        credentials once exposed, you can periodically rotate the credentials.

        If you are not using a custom passkey...

            $credentials->rotate_credentials;

        ...or if you have a custom passkey generator your subroutine must
        continue to provide the old passkey before you can reset the passkey.

            use Amazon::Credentials qw( create_passkey );

            my $passkey = create_passkey;

            sub get_passkey {
              my ($regenerate) = shift;

              return $regenerate ? create_passkey : $passkey;
            } 

            my $credentials = Amazon::Credentials->new( passkey => \&get_passkey );

            $passkey = $credentials->rotate_credentials(get_passkey(1));

    - Using Custom Encryption Methods

        Finally, you can also provide your own `encrypt()` and `decrypt()`
        methods when you call the `new()` constructor. These methods will be
        passed the string to encrypt or decrypt and the passkey. Your methods
        should return the decrypted or encrypted strings. Your methods can
        ignore the passkey if your methods provide their own passkey or
        mechanisms for encryption.

            use Amazon::Credentials qw( create_passkey };

            my $passkey = create_passkey();

            sub my_encrypt {
              my ($self, $str) = @_;

              ...
              return $encrypted_str;
            }

            sub my_decrypt {

              ...
              return $deecrypted_str;
            }

            my $creds = Amazon::Credentials->new( encrypt => \&my_encrypt,
                                                  decrypt => \&my_decrypt,
                                                  passkey => sub { return $passkey },
                                                );

## Securing Your Logs

To troubleshoot potential bugs in this module or to understand what
[Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) is doing you can pass a debug flag that will
write potentially helpful info to STDERR.

To prevent possible exposure of credentials in debug messages, the
module will not write log messages that contain your credentials even
if your debug flag is set to a true value. In order to debug output of
all content you the `insecure` flag to any of the values shown below.

- insecure = false (0, '', undef)

    If the debug flag is true, any message that might potentially contain
    credentials is not written to STDERR. This is the default.

- insecure = 1

    Setting `insecure` to 1 will allow more debug messages, however
    credentials will be masked.

- insecure = 2 or 'insecure'

    This setting, along with setting the debug mode to a true value will
    enable full debugging.

## Use Temporary Credentials

One additional tip to help prevent the use of your credentials even if
they have been exposed in logs or files. _Use temporary credentials
with short expiration times whenever possible._ [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials)
provides methods to determine if your credentials have expired and
a method to refresh them when they have.

    if ( $credentials->is_token_expired ) {
      $credentials->refresh_token;
    }

## Use Granular Credentials

Consider the APIs that you are calling with these credentials. If all
you need to do is access a bucket or a key within a bucket, use
credentials that **ONLY** allow access to that bucket.  IAM permissions
can be quite specific regarding what and from where credentials can be
used to access resources.

## Additonal Notes on Logging

Versions _1.0.18_ and _1.0.19_ allowed you to enable debugging by
setting the environment variable DEBUG to any true value to enable
basic debug output. Version _1.0.18_ would log information to STDERR
including payloads that might contain credentials.  Version _1.0.19_
would prevent writing any payload with credentials _unless_ the debug
mode was set to 2 or 'insecure'.  Keep in mind however that you should
avoid allowing upstream programs to use environment variables to set
debugging modes that you might pass to [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials).

Starting with version _1.1.0_ the [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials) will **not**
use the environment variable DEBUG to enable debugging! You must
explicitly pass the debug flag in the constructor to enable
debugging. This was done to prevent potential upstream modules that
you might use who allow an environment variable to set debug mode to
also inadvertantly trigger debug mode for [Amazon::Credentials](https://metacpan.org/pod/Amazon%3A%3ACredentials).

# INCOMPATIBILITIES

This module has not been tested on Windows OS.

# CONTRIBUTING

You can find this project on GitHub at
[https://github.com/rlauer6/perl-Amazon-Credentials](https://github.com/rlauer6/perl-Amazon-Credentials).  PRs are always
welcomed!

# LICENSE AND COPYRIGHT

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

# AUTHOR

Rob Lauer - <rlauer6@comcast.net>
