SUBDIRS = .

CPAN_DIST_MAKER=/usr/local/libexec/make-cpan-dist.pl
package_version=@PACKAGE_VERSION@
package=@PACKAGE@

# builds the distribution tarball and renames based on package version
cpan: buildspec.yml
	$(CPAN_DIST_MAKER) -b $<

	if test -n "$$(echo $(package_version) | grep '\-')"; then \
		echo $$package_version; \
		package_version=$(package_version); package=$(package); \
		tarball=$${package##perl-}-$${package_version%%-*}.tar.gz; \
		test -e "$$tarball" && mv $$tarball $${package##perl-}-$$package_version.tar.gz; \
	fi

.PHONEY: cpan

clean-local:
	rm -f *.tar.gz
