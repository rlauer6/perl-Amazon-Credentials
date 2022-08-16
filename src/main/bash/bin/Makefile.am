SUBDIRS = . 

perlrun = @PERL@
bashrun = @BASHRUN@

BASHSCRIPTS = \
    get-sso-credentials.sh.in \
    amazon-credentials.sh.in

GBASHSCRIPTS = $(BASHSCRIPTS:.sh.in=.sh)

libexec_SCRIPTS = $(GBASHSCRIPTS)

dist_noinst_DATA = $(BASHSCRIPTS)

bin_SCRIPTS = $(GBASHSCRIPTS:.sh=)

@do_subst_command@

$(GBASHSCRIPTS): % : %.in
	$(do_subst) $< > $@
	chmod +x $@

$(bin_SCRIPTS): % : %.sh $(GBASHSCRIPTS)
	cp $< $@
	chmod +x $@

CLEANFILES = $(GBASHSCRIPTS) $(bin_SCRIPTS)
