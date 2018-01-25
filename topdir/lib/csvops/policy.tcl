
#
# security policy for the script slave
#

proc Script_PolicyInit slave {
    # I might want to use the standard interpreter when testing, so slave might be {}.
    if {$slave ne {}} {
        # to support a test case
        interp share {} stdout $slave
        # ::control needs this
        interp expose $slave pwd

        interp alias $slave ::open {} ::safe::AliasOpen $slave

        interp alias $slave ::mc {} ::mc

        # ::fileutil needs these, safe::loadTk needs normalize
        foreach subcommand {exists isfile writable readable size mkdir normalize} {
            interp alias $slave ::tcl::file::$subcommand {} ::safe::AliasFileSubcommand2 $slave $subcommand
        }
    }

    interp alias $slave ::log {} ::csvops::log

    if no {
    if no { # msgcat support
        setupMsgcat $slave sv msgs {.. msgs}
    } else {
        interp alias $slave mc $slave format
    }
    }

    sourceLibrary $slave ssrc
}

proc TkCon_PolicyInit slave {
    interp eval $slave [list set bin [::safe::interpAddToAccessPath $slave [file dirname [info nameofexecutable]]]]
    safe::loadTk $slave
    foreach cmd {history auto_load auto_load_index} {
        interp eval $slave [list proc ::$cmd [info args $cmd] [info body $cmd]]
    }
    foreach cmd {tk wm grab menu} {
        interp alias $slave ::$cmd {} ::$cmd
    }
    foreach var {env tcl_platform auto_index} {
        interp eval $slave [list array set ::$var [array get ::$var]]
    }
    foreach var {auto_path} {
        interp eval $slave [list set ::$var [set ::$var]]
    }
    interp eval $slave {
        #source [file join $bin tkcon.tcl]
        source tkcon.tcl
        package require tkcon
        set ::tkcon::PRIV(showOnStartup) 1
        #set ::tkcon::OPT(exec) ""
        ::tkcon::Init
    }
}

proc Debug_PolicyInit slave {
    interp eval $slave [list source [file join [file dirname [info nameofexecutable]] tkcon.tcl]]
    interp eval $slave {
        package require tkcon
        set ::tkcon::PRIV(showOnStartup) 1
        set ::tkcon::OPT(exec) ""
        ::tkcon::Init
        ::idebug on
    }

    interp alias $slave ::log {} ::csvops::log

    if no { # msgcat support
        setupMsgcat $slave sv msgs {.. msgs}
    } else {
        interp alias $slave mc $slave format
    }

    sourceLibrary $slave ssrc
}

proc sourceLibrary {slave dir} {
    if {[interp issafe $slave]} {
        interp eval $slave [list set ssrc [::safe::interpAddToAccessPath $slave [file join $::starkit::topdir lib csvops $dir]]]
    } else {
        interp eval $slave [list set ssrc [file join $::starkit::topdir lib csvops $dir]]
    }
    interp eval $slave {
        foreach file [glob -nocomplain -directory $ssrc *.tcl] {
            source $file
        }
        unset -nocomplain file ssrc
    }
}

proc setupMsgcat {slave locale args} {
    error foo
    interp eval $slave {
        package require msgcat
        namespace import ::msgcat::mc
    }
    interp eval $slave [list ::msgcat::mclocale $locale]
    foreach d $args {
        set dir [file join $::starkit::topdir {*}$d]
        if {[interp issafe $slave]} {
            interp eval $slave [list ::msgcat::mcload [::safe::interpAddToAccessPath $slave $dir]]
        } else {
            interp eval $slave [list ::msgcat::mcload $dir]
        }
    }
}

