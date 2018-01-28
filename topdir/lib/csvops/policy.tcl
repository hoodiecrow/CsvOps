
#
# security policy for the script slave
#

# TODO refactor this please
source [file join $starkit::topdir lib csvops ssrc db.tcl]
proc _DB {slave args} {
    set db [DB {*}$args]
    interp alias $slave $db {} $db
}

proc Script_PolicyInit slave {
    # to support a test case
    interp share {} stdout $slave
    # ::control needs this
    interp expose $slave pwd

    interp alias $slave ::open {} ::safe::AliasOpen $slave

    interp eval $slave [list array set ::options [array get ::options]]

    interp alias $slave ::mc {} ::mc
    interp alias $slave ::OptionHandler {} ::OptionHandler
    interp alias $slave ::DB {} ::_DB $slave

    # ::fileutil needs these, safe::loadTk needs normalize
    foreach subcommand {exists isfile writable readable size mkdir normalize} {
        interp alias $slave ::tcl::file::$subcommand {} ::safe::AliasFileSubcommand2 $slave $subcommand
    }

    if {[interp issafe $slave]} {
        interp eval $slave [list set ssrc [::safe::interpAddToAccessPath $slave [file join $::starkit::topdir lib csvops ssrc]]]
    } else {
        interp eval $slave [list set ssrc [file join $::starkit::topdir lib csvops ssrc]]
    }

    interp eval $slave {
        set files [glob -nocomplain -directory $ssrc *.tcl]
        foreach file $files {
            source $file
        }
        unset -nocomplain file ssrc
    }
}
