package provide csvops 1.0

package require log

apply {args {
    set dir [file dirname [info script]]
    foreach arg $args {
        source -encoding utf-8 [file join $dir $arg]
    }
}} csvops.tcl policy.tcl safe.tcl db.tcl
