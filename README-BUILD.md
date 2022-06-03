# README

This is the README file for the `perl-Amazon-Credentials` project.

![badge](https://codebuild.us-east-1.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoia3BvcFcwdlRBS0Q4eXRCempKZCtUNTBraGZOdVg1ajJ4dTVQbUZDRzdDWlJYNEJpd0FpMnk4UHZWWUpwRnM5Qk5rUmRNeXFReE9uZWp6M2VpeVIxUWVvPSIsIml2UGFyYW1ldGVyU3BlYyI6Img1bWNSVGIvZjBQTzlHazEiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master)

---

# DESCRIPTION

Perl module to find AWS credentials either in your environment, from
your credentials files, your EC2 or container's metadata .  See:

```
perldoc Amazon::Credentials
```

# Building an rpm

Assuming you have an `rpmbuild` environment setup for yourself:

```
git clone https://github.com/rlauer6/perl-Amazon-Credentials.git
cd perl-Amazon-Credentials
./bootstrap
./configure --enable-rpmbuild
make dist
rpmbuild -tb perl-Amazon-Credentials-1.0.17.tar.gz
```

# Building CPAN tarball

See https://github.com/rlauer6/make-cpan-dist for more information
about creating CPAN distributions from these RPM based projects

This project contains a `makefile` that will help you create the CPAN
tarball. Try this recipe:

```
git clone https://github.com/rlauer6/perl-Amazon-Credentials.git
cd perl-Amazon-Credentials
./bootstrap
./configure
make cpan
```

# Author

Rob Lauer <rclauer@gmail.com>
