# README

This is the README file for the `perl-Amazon-Credentials` project.

# DESCRIPTION

Perl module to find AWS credentials either in your environment, from
your credentials files or your EC2 meta data.  See:

```
perldoc Amazon::Credentials
```

# Building an rpm

Assuming you have an `rpmbuild` environment setup for yourself:

```
git clone https://github.com/rlauer6/perl-Amazon-Credentials.git
cd perl-Amazon-Credentials
autoreconf -i --force
./configure --enable-rpmbuild
make dist
rpmbuild -tb perl-Amazon-Credentials-1.0.0.tar.gz
```

# Building CPAN tarball

See https://github.com/rlauer6/make-cpan-dist for more information
about creating CPAN distributions from these RPM based projects

This project contains a `makefile` that will help you create the CPAN
tarball. Try this recipe:

```
git clone https://github.com/rlauer6/perl-Amazon-Credentials.git
cd perl-Amazon-Credentials
autoreconf -i --force
./configure
make
cd cpan
make cpan
```

# Author

Rob Lauer <rlauer6@comcast.net>
