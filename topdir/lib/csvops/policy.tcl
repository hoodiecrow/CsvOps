
#
# security policy for the script slave
#

proc Script_PolicyInit slave {
    # to support a test case
    interp share {} stdout $slave
    # ::control needs this
    interp expose $slave pwd

    interp alias $slave ::open {} ::safe::AliasOpen $slave

    interp eval $slave [list array set ::options [array get ::options]]

    interp alias $slave ::mc {} ::mc
    interp alias $slave ::sqlite3 {} ::sqlite3

    # ::fileutil needs these, safe::loadTk needs normalize
    foreach subcommand {exists isfile writable readable size mkdir normalize} {
        interp alias $slave ::tcl::file::$subcommand {} ::safe::AliasFileSubcommand2 $slave $subcommand
    }

    #interp alias $slave ::log {} ::csvops::log

    if no {
    sourceLibrary $slave ssrc
    } else {
    if {[interp issafe $slave]} {
        interp eval $slave [list set ssrc [::safe::interpAddToAccessPath $slave [file join $::starkit::topdir lib csvops ssrc]]]
    } else {
        interp eval $slave [list set ssrc [file join $::starkit::topdir lib csvops ssrc]]
    }
    interp eval $slave {
        foreach file [glob -nocomplain -directory $ssrc *.tcl] {
            source $file
        }
        unset -nocomplain file ssrc
    }
    }
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
