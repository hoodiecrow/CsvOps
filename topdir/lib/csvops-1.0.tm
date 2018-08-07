package require msgcat
package require fileutil
package require log
package require optionhandler
package require csv
package require tdom
package require sqlite3

apply {args {
    set dir [file dirname [info script]]
    foreach arg $args {
        source -encoding utf-8 [file join $dir .. src $arg]
    }
}} csvops.tcl policy.tcl safe.tcl db.tcl
