SUBDIRS = lib .

if DISTCHECK_HACK_ENABLED
else
check_SCRIPTS = prove.sh

TESTS = $(check_SCRIPTS)

TEST_LOG_DRIVER = env AM_TAP_AWK='$(AWK)' $(SHELL) \
              $(top_srcdir)/autotools/tap-driver.sh

UNIT_TESTS = \
    t/00-credentials.t \
    t/01-credentials.t \
    t/02-credentials.t \
    t/03-container.t \
    t/04-process.t

UNIT_TESTS_LOGS=$(UNIT_TESTS:.t=.t.log)
UNIT_TESTS_TRS=$(UNIT_TESTS:.t=.t.trs)

test:
	prove -v -r -I lib -I @perl5libdir@ t

prove.sh:
	set -x; \
	PERL5LIBDIR="@perl5libdir@"; \
	builddir=$(builddir); \
	echo $$builddir; \
	echo -e "#!/usr/bin/env bash\nset -x\nPERL5LIB=$(builddir)/lib prove -r t" > $(builddir)/prove.sh
	chmod 755 $(builddir)/prove.sh
endif

dist_noinst_DATA = \
    $(UNIT_TESTS) \
    get-creds-from-process

CLEANFILES = \
   prove.sh \
   prove.sh.trs \
   prove.sh.log \
   test-suite.log \
   $(UNIT_TESTS_LOGS) \
   $(UNIT_TESTS_TRS)
