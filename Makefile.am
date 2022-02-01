SUBDIRS = . src cpan

ACLOCAL_AMFLAGS = -I autotools

dist_noinst_DATA = \
    NEWS.md \
    README.md \
    ${PACKAGE_NAME}.spec \
    ${PACKAGE_NAME}.spec.in

.PHONY: cpan

cpan:
	cd . && $(MAKE)
	cd cpan && $(MAKE) cpan

DISTCHECK_CONFIGURE_FLAGS = --enable-distcheck-hack --enable-rpmbuild
