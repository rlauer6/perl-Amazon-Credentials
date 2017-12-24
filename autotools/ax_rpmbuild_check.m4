AC_DEFUN([AX_RPMBUILD_CHECK],[
    AC_MSG_CHECKING([[whether to enable an RPM build environment]])

    AC_ARG_ENABLE([rpmbuild],
        [[  --enable-rpmbuild configure for an RPM build ]],

        dnl AC_ARG_ENABLE: option if given
        [
            case "${enableval}" in
                yes)  ax_rpmbuild_enabled=true  ;;
                no)   ax_rpmbuild_enabled=false ;;
                *)
                    AC_MSG_ERROR([bad value ("$enableval") for '--enable-rpmbuild' option])
                    ;;
            esac
        ],

        dnl AC_ARG_ENABLE: option if not given
        [
            ax_rpmbuild_enabled=false
        ]
    )

    if ${ax_rpmbuild_enabled}; then
        AC_MSG_RESULT([yes])
    else
        AC_MSG_RESULT([no])
    fi

    dnl register a conditional for use in Makefile.am files
    AM_CONDITIONAL([RPMBUILD_ENABLED], [test "${ax_rpmbuild_enabled}" = "true"])
])
