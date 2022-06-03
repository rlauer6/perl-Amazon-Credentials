SUBDIRS = . src cpan

ACLOCAL_AMFLAGS = -I autotools

CREDENTIALS_PM = ${srcdir}/src/main/perl/lib/Amazon/Credentials.pm

$(CREDENTIALS_PM):
	cd ${builddir}/src/main/perl/lib; \
	$(MAKE)

README.md: $(CREDENTIALS_PM)
	pod2markdown < $< >$@

dist_noinst_DATA = \
    NEWS.md \
    README.md \
    ${PACKAGE_NAME}.spec \
    ${PACKAGE_NAME}.spec.in

.PHONY: cpan

cpan:
	cd . && $(MAKE)
	cd cpan && $(MAKE) cpan

CLEANFILES = \
    README.md

DISTCHECK_CONFIGURE_FLAGS = --enable-distcheck-hack --enable-rpmbuild
