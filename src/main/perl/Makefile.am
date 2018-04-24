SUBDIRS = . lib

check_SCRIPTS = prove.sh

TESTS = $(check_SCRIPTS)

TEST_LOG_DRIVER = env AM_TAP_AWK='$(AWK)' $(SHELL) \
              $(top_srcdir)/autotools/tap-driver.sh

UNIT_TESTS = \
    t/00-credentials.t \
    t/01-credentials.t \
    t/02-credentials.t

UNIT_TESTS_LOGS=$(UNIT_TESTS:.t=.t.log)
UNIT_TESTS_TRS=$(UNIT_TESTS:.t=.t.trs)

test:
	prove -v -r -I lib -I @perl5libdir@ t

prove.sh:
	echo 'prove -r -I lib -I @perl5libdir@ t' > prove.sh
	chmod 755 prove.sh

CLEANFILES = \
   $(check_SCRIPTS) \
   prove.sh.trs \
   prove.sh.log \
   test-suite.log \
   $(UNIT_TESTS_LOGS) \
   $(UNIT_TESTS_TRS)

.PHONY: cpan

cpan:
	set -x; tmpdir=$$(mktemp -d); \
	destdir=$$(pwd); \
	ln -s $$(pwd)/t $$tmpdir/t; \
	ln -s $$(pwd)/lib $$tmpdir/lib; \
	for a in Makefile.PL MANIFEST; do \
	  ln -s $$(pwd)/$$a $$tmpdir/$$a; \
	done; \
	cd $$tmpdir; \
	pwd; \
	perl Makefile.PL; \
	make dist; \
	cp *.tar.gz $$destdir; \
	rm -rf $$tmpdir
