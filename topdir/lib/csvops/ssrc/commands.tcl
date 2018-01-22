#
# Mostly used inside scripts.
#

package require control

::control::control assert enabled 1

proc constrain {varName mode args} {
    # normalizes a cell value within a minimum and optional maximum value
    upvar 1 $varName var
    if {[lindex $args 0] eq "between"} {set args [lreplace $args 0 0]}
    if {[lindex $args 1] eq "and"} {set args [lreplace $args 1 1]}

    set var [lindex [lsort $mode [linsert $args 0 $var]] 1]
}

proc convDateFmt {varName args} {
    # converts a date cell value from one value to another, or sets it to a default date
    upvar 1 $varName var
    set options {-to %y-%m-%d -from %Y-%m-%d -default {}}
    set options [dict merge $options $args]

    if {$var eq {}} {
        set var [dict get $options -default]
    } else {
        try {
            clock scan $var -format [dict get $options -from]
        } on ok d {
            # clock format doesn't fail but might return garbage
            set var [clock format $d -format [dict get $options -to]]
        } on error {} {
            error [mc {invalid date format -from}]
        }
    }
}

proc segment {varName args} {
    # matches a cell value against a sequence of non-negative integral values, and returns which interval it belongs to
    upvar 1 $varName var
    set as [list 0 {*}[lmap a $args {expr {$a + 1}}]]
    foreach a $as b $args {
        if {$b eq {} || $var <= $b} {
            return [set var ${a}_$b]
            # could be written:
            #tailcall set $varName ${a}_$b
        }
    }
}

proc stringNormalize {varName {ops trim}} {
    # normalizes a cell value by iterative application of string modifications (default trim)
    upvar 1 $varName var
    foreach op $ops {
        set var [string $op $var]
    }
}

proc commaToDot varName {
    # change all commas in a cell value to dots
    upvar 1 $varName var
    set var [string map {, .} $var]
}

proc dotToComma varName {
    # change all dots in a cell value to commas
    upvar 1 $varName var
    set var [string map {. ,} $var]
}

