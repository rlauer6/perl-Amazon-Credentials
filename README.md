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

Use the instructions below to create a tarball of the CPAN ilk.

```
git clone https://github.com/rlauer6/perl-Amazon-Credentials.git
cd perl-Amazon-Credentials
autoreconf -i --force
./configure
make
cd src/main/perl
make cpan
```

# Author

Rob Lauer <rlauer6@comcast.net>
