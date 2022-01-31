SUBDIRS = lib .

check_SCRIPTS = prove.sh

TESTS = $(check_SCRIPTS)

TEST_LOG_DRIVER = env AM_TAP_AWK='$(AWK)' $(SHELL) \
              $(top_srcdir)/autotools/tap-driver.sh

UNIT_TESTS = \
    t/00-credentials.t \
    t/01-credentials.t \
    t/02-credentials.t \
    t/03-credentials.t \
    t/04-credetials.t

UNIT_TESTS_LOGS=$(UNIT_TESTS:.t=.t.log)
UNIT_TESTS_TRS=$(UNIT_TESTS:.t=.t.trs)

test:
	prove -v -r -I lib -I @perl5libdir@ t

prove.sh:
	PERL5LIBDIR="@perl5libdir@"; \
	builddir=$$(pwd); \
	echo -e "#!/usr/bin/env bash\nPERL5LIB=$$builddir/lib prove t" > prove.sh
	chmod 755 prove.sh

CLEANFILES = \
   $(check_SCRIPTS) \
   prove.sh.trs \
   prove.sh.log \
   test-suite.log \
   $(UNIT_TESTS_LOGS) \
   $(UNIT_TESTS_TRS)
