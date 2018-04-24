AC_INIT([perl-Amazon-Credentials], [1.0.5-0], [rlauer6@comcast.net], [perl-Amazon-Credentials])

__poor_mans_expand_file_name () {
    _tmp_name=$1
    _tmp_last="`eval echo '${'"${_tmp_name}"'}'`"
    if test -z "${_tmp_last}"; then
        printf "__poor_mans_expand_file_name() (WARNING): var \"%s\" is empty\n" \
          "${_tmp_name}" 1>&2
        return 0;  # nothing to do
    fi
    _tmp_last_expanded="`eval echo ${_tmp_last}`"
    while test "${_tmp_last_expanded}" != "${_tmp_last}"; do

        # Set 'last' hold var to most recently expanded version...
        _tmp_last="${_tmp_last_expanded}"

        # ...and try to expand further.
        _tmp_last_expanded="`eval echo ${_tmp_last_expanded}`"
    done
    printf "%s\n" "${_tmp_last_expanded}"
    unset _tmp_last_expanded
    unset _tmp_last
    unset _tmp_name
    return 0;
}


[
do_subst_command='do_subst = sed \
  -e '"'"'s,[@]PACKAGE[@],$(PACKAGE),g'"'"' \
  -e '"'"'s,[@]VERSION[@],$(VERSION),g'"'"' \
  -e '"'"'s,[@]PACKAGE_VERSION[@],$(PACKAGE_VERSION),g'"'"' \
  -e '"'"'s,[@]PATH_SEPARATOR[@],$(PATH_SEPARATOR),g'"'"' \
  -e '"'"'s~[@]configure_input[@]~Generated from $@.in; do not edit by hand.~g'"'"' \
  -e "s,[@]BUILD_DATE[@],$$(date '"'"'+%Y-%m-%d %H:%M:%S'"'"'),g" \
  \
  -e '"'"'s,[@]bindir[@],$(bindir),g'"'"' \
  -e '"'"'s,[@]datadir[@],$(datadir),g'"'"' \
  -e '"'"'s,[@]exec_prefix[@],$(exec_prefix),g'"'"' \
  -e '"'"'s,[@]includedir[@],$(includedir),g'"'"' \
  -e '"'"'s,[@]infodir[@],$(infodir),g'"'"' \
  -e '"'"'s,[@]libdir[@],$(libdir),g'"'"' \
  -e '"'"'s,[@]libexecdir[@],$(libexecdir),g'"'"' \
  -e '"'"'s,[@]localstatedir[@],$(localstatedir),g'"'"' \
  -e '"'"'s,[@]mandir[@],$(mandir),g'"'"' \
  -e '"'"'s,[@]oldincludedir[@],$(oldincludedir),g'"'"' \
  -e '"'"'s,[@]prefix[@],$(prefix),g'"'"' \
  -e '"'"'s,[@]sbindir[@],$(sbindir),g'"'"' \
  -e '"'"'s,[@]sharedstatedir[@],$(sharedstatedir),g'"'"' \
  -e '"'"'s,[@]sysconfdir[@],$(sysconfdir),g'"'"' \
  \
  -e '"'"'s,[@]abs_builddir[@],$(abs_builddir),g'"'"' \
  -e '"'"'s,[@]abs_srcdir[@],$(abs_srcdir),g'"'"' \
  -e '"'"'s,[@]abs_top_builddir[@],$(abs_top_builddir),g'"'"' \
  -e '"'"'s,[@]abs_top_srcdir[@],$(abs_top_srcdir),g'"'"' \
  -e '"'"'s,[@]srcdir[@],$(srcdir),g'"'"' \
  -e '"'"'s,[@]top_builddir[@],$(top_builddir),g'"'"' \
  -e '"'"'s,[@]top_srcdir[@],$(top_srcdir),g'"'"' \
\
  -e '"'"'s,[@]perl5libdir[@],$(perl5libdir),g'"'"' \
  -e '"'"'s,[@]perlrun[@],$(perlrun),g'"'"' \
  -e '"'"'s,[@]ksh[@],$(ksh),g'"'"' \
  -e '"'"'s,[@]bashrun[@],$(bashrun),g'"'"' \
  -e '"'"'s,[@]logdir[@],$(logdir),g'"'"' \
\
  -e '"'"'s,[@]SOME_THINGY[@],$(SOME_THINGY),g'"'"' \
'
]

AC_SUBST([do_subst_command])

AC_CONFIG_AUX_DIR([autotools])
AC_CONFIG_MACRO_DIR([autotools])

AM_INIT_AUTOMAKE([-Wall -Werror foreign tar-ustar])

AC_REQUIRE_AUX_FILE([tap-driver.sh])

AC_PROG_AWK

AC_PATH_PROG([BASHRUN],
	[bash])

if test -z "$BASHRUN" ; then 
  AC_MSG_ERROR([bash not found?])
fi

AC_PATH_PROG([POD2MAN],
	[pod2man])

if test -z "$POD2MAN" ; then 
  AC_MSG_ERROR([pod2man not found?])
fi

AC_PATH_PROG([PERL],
	[perl])

if test -z "$PERL" ; then 
  AC_MSG_ERROR([perl not found?])
fi

perl5libdir=\${datadir}/perl5
AC_ARG_WITH(
	[perl5libdir],[  --with-perl5libdir (defaults to [DATAROOTDIR]/perl5)],
	[
    if test "${withval}" = 'no'; then
        true
    elif test "$withval" = 'yes'; then
        perl5libdir=$($PERL -MConfig -wle 'print $Config{sitelib};')
    else
        perl5libdir=$withval    
    fi
        ]
)

AC_SUBST([perl5libdir])

AX_DISTCHECK_HACK
AX_DEPS_CHECK
AX_PERLDEPS_CHECK
AX_RPMBUILD_CHECK

dnl something just to make autoconf include the autotools/ads_ stuff in the distribution
ads_PERL_MODULE([Getopt::Long])

dnl example using the PERL_MODULE possibly check with a version number
ads_PERL_MODULE([POSIX::strptime])

AC_CONFIG_FILES([
    Makefile
    src/Makefile
    src/main/Makefile
    src/main/perl/Makefile
    src/main/perl/lib/Makefile
    ${PACKAGE_NAME}.spec
])

AC_OUTPUT

printf "\n"
printf "${PACKAGE} has been configured with the following options:\n"
printf "                        Prefix: %s\n" "`__poor_mans_expand_file_name prefix`"
printf "                 User binaries: %s\n" "`__poor_mans_expand_file_name bindir`"
printf "               System binaries: %s\n" "`__poor_mans_expand_file_name sbindir`"
printf "           Configuration files: %s\n" "`__poor_mans_expand_file_name sysconfdir`"
printf "                  Manual pages: %s\n" "`__poor_mans_expand_file_name mandir`"
printf "\n"
printf "                   perl5libdir: %s\n" "`__poor_mans_expand_file_name perl5libdir`"
printf "                          perl: %s\n" "`__poor_mans_expand_file_name PERL`"
printf "\n"
