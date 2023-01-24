SUBDIRS = .

CPAN_DIST_MAKER=/usr/local/bin/make-cpan-dist.pl
package_version=@PACKAGE_VERSION@
package=@PACKAGE@

# builds the distribution tarball and renames based on package version
cpan: buildspec.yml
	PROJECT_ROOT="--project-root $$(readlink -f ..)"; \
	$(CPAN_DIST_MAKER) $$PROJECT_ROOT -b $<

	if test -n "$$(echo $(package_version) | grep '\-')"; then \
	  echo $$package_version; \
	  package_version=$(package_version); package=$(package); \
	  tarball=$${package##perl-}-$${package_version%%-*}.tar.gz; \
	  test -e "$$tarball" && mv $$tarball $${package##perl-}-$$package_version.tar.gz; \
	fi

.PHONY: cpan

dist_noinst_DATA = buildspec.yml

clean-local:
	rm -f *.tar.gz
	rm -f provides
