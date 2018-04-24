SUBDIRS = .

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

perlrun = @PERL@

if RPMBUILD_ENABLED
perlwc = \#
else
perlwc = @PERL@ -wc
endif

perl5libdir = @perl5libdir@
ax_perl5_extra_includes_opt = @ax_perl5_extra_includes_opt@

amazondir = $(perl5libdir)/Amazon

PERLMODULES = \
    Amazon/Credentials.pm.in

GPERLMODULES = $(PERLMODULES:.pm.in=.pm)

amazon_DATA = $(GPERLMODULES)

dist_noinst_DATA = $(PERLMODULES)

@do_subst_command@

if USING_PERL5_EXTRA_INCLUDES
PERL5_EXTRA_INCLUDES = $(ax_perl5_extra_includes_opt)
else
endif

# Please see the notes concerning PERLINCLUDE in the ../bin/Makefile.am file
PERLINCLUDE = \
   -I $(builddir) \
   $(PERL5_EXTRA_INCLUDES) \
   -I $(perl5libdir) 

$(GPERLMODULES): % : %.in 
	test -d "$$(dirname "$@")" || $(INSTALL) -d "$$(dirname "$@")"
	$(do_subst) $< > $@
	$(perlwc) $(PERLINCLUDE)  $@ || { ret=$?; rm $@ && exit $ret; }

all:

test:
	prove -v -r -I . t

prove.sh:
	echo 'prove -v -r -I . t' > prove.sh
	chmod 755 prove.sh

.PHONY: cpan

CLEANFILES = \
   $(GPERLMODULES) \
   $(check_SCRIPTS) \
   prove.sh.trs \
   prove.sh.log \
   test-suite.log \
   $(UNIT_TESTS_LOGS) \
   $(UNIT_TESTS_TRS)

