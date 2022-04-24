SUBDIRS = .

perlrun = @PERL@

if RPMBUILD_ENABLED
perlwc = \#
else
perlwc = @PERL@ -wc
endif

perl5libdir = @perl5libdir@
ax_perl5_extra_includes_opt = @ax_perl5_extra_includes_opt@

PERLMODULES =

AMAZON_PERLMODULES = \
    Amazon/Credentials.pm.in

GPERLMODULES = $(PERLMODULES:.pm.in=.pm)

GAMAZON_PERLMODULES = $(AMAZON_PERLMODULES:.pm.in=.pm)

amazondir = $(perl5libdir)/Amazon

amazon_DATA = $(GAMAZON_PERLMODULES:pm.in=.pm)

dist_noinst_DATA = \
    $(PERLMODULES) \
    $(AMAZON_PERLMODULES)

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

%.pm: %.pm.in
	test -d "$$(dirname "$@")" || $(INSTALL) -d "$$(dirname "$@")"
	$(do_subst) $< > $@
	$(perlwc) $(PERLINCLUDE)  $@ || { ret=$$?; rm $@ && exit $$?; }

all:

CLEANFILES = \
   $(GPERLMODULES) \
   $(GAMAZON_PERLMODULES)

