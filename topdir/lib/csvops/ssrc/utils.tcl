#
# Mostly used inside scripts.
#

package require math::fuzzy
package require struct::list

namespace export {[a-z]*}

proc CMD {} {
    lindex [info level -1] 0
}

proc anon args {
    # return a unique integer for each combination of $args
	variable anonkeyarr
	variable anonkeynum

	if {[info exists anonkeyarr($args)]} {
	    set anonkeyarr($args)
	} else {
	    set anonkeyarr($args) [incr anonkeynum]
	}
}

proc cols {fields headings} {
    # calculate a list of column indexes for a given list of field names within
    # a given list of headings
    lmap field $fields {
        set idx [lsearch -exact $headings $field]
        if {$idx < 0} {
            return -code error [mc {invalid field name %s} $field]
        }
        set idx
    }
}

proc dayDistance {date0 date1 {format %y-%m-%d}} {
    # calculate the number of dates from one date to another (later) date
    set d0 [clock format [clock scan $date0 -format $format] -format %J]
    set d1 [clock format [clock scan $date1 -format $format] -format %J]
    expr {$d1 - $d0}
}

proc getFirstLine filename {
    # read the first line of a named file
    try {
        open $filename
    } on ok chan {
        chan gets $chan
    } finally {
        catch {chan close $chan}
    }
}

proc getdiag ds {
    # recursively determine the correct diagnose code from a list of codes
    if {[llength $ds] < 1} {return saknas}

    set ds [lassign $ds first]

    switch -- $first {
        saknas {
            tailcall getdiag $ds
        }
        z {
            tailcall getdiag_z $ds
        }
        annan {
            tailcall getdiag_a $ds
        }
        default {
            return $first
        }
    }
}

proc getdiag_a ds {
    # return 'annan' unless there is an f7 code
    if {[lsearch $ds f7] >= 0} {
        return f7
    } else {
        return annan
    }
}

proc getdiag_z ds {
    # return 'z' unless there is an 'annan' or other valid code
    if {[llength $ds] < 1} {return z}

    set ds [lassign $ds first]
    switch -- $first {
        saknas -
        z {
            tailcall getdiag_z $ds
        }
        annan {
            tailcall getdiag_a $ds
        }
        default {
            return $first
        }
    }
}

proc round {val sigdig decimals {decimalChar ,}} {
    # formats a value with # of significant digits and # of decimals, also
    # changing decimal symbol
    string map [list . $decimalChar] [format %.${decimals}f [format %.${sigdig}g $val]]
}

proc serialCompareEqual {c0 c1} {
    # collects a list of booleans that describe the equality of non-decimal values in two columns
    lmap e0 $c0 e1 $c1 {
        expr {$e0 == $e1}
    }
}

proc serialCompareEqualDecimal {c0 c1} {
    # collects a list of booleans that describe decimal equality between two columns
    lmap e0 $c0 e1 $c1 {
        commaToDot e0
        commaToDot e1
        ::math::fuzzy::teq $e0 $e1
    }
}

proc serialCompareEmpty {c0 c1} {
    # collects a list of values 0-3 that compare emptiness between two columns;
    # 0 if neither cell is empty, 1 if e1 is empty, 2 if e0 is empty, 3 if both
    # are empty
    lmap e0 $c0 e1 $c1 {
        expr {(($e0 eq {}) << 1) + ($e1 eq {})}
    }
}

proc yearDistance {year0 {year1 {}}} {
    # calculates the distance between two years, with the later year by default
    # being the current
    if {$year1 eq {}} {set year1 [clock format [clock seconds] -format %Y]}
    expr {$year1 - $year0}
}

proc dbjoin args {
    if {[llength $args] == 4} {
        lassign $args mode left right writer
    } elseif {[llength $args] == 3} {
        lassign $args left right writer
        set mode inner
    } else {
        return -code error [mc {dbjoin: wrong # of arguments}]
    }

    if {$mode in {inner left right full}} {
        set writerData [::struct::list dbJoin -$mode 0 [$left expose] 0 [$right expose]]
    } else {
        return -code error [mc {dbjoin: unknown mode}]
    }

    set nrows [llength $writerData]
    if {$nrows == 0} {
        set ncols 0
    } else {
        set ncols [llength [lindex $writerData 0]]
    }

    $writer deserialize [list $nrows $ncols $writerData]
}

proc extendRow {m n} {
    # extend matrix 'm' if 'n'-current number of columns > 0
    set diff [expr {$n - [$m columns]}]
    
    if {$diff > 0} {
        $m add columns $diff
    }
}
