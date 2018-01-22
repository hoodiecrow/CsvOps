
#
# implement field-based database lookup
#

if {[info commands ::FieldAccess] ne {}} return

oo::class create FieldAccess {
    variable db options colres

    method CheckFields args {
        # before any lookup, verify that 'colres' exists and that a suitable
        # number of fields are given
        # I don't need to filter lookupColumn since it's always called from a
        # filtered method
        if {[lindex [self target] 1] in {getColumn getColumnValues getFields}} {
            if {![info exists colres]} {
                if {[info exists options(-fields)]} {
                    for {set i 0} {$i < [llength $options(-fields)]} {incr i} {
                        dict set colres [lindex $options(-fields) $i] $i
                    }
                } else {
                    return -code error [mc {no fields defined}]
                }
            }
            if {[dict size $colres] > [$db columns]} {
                # can still be too many if sparse
                return -code error [mc {too many fields}]
            }
        }
        next {*}$args
    }
    filter CheckFields

    method LookupColumn col {
        try {dict get $colres $col} on error {} {
            return -code error [mc {column header missing %s} $col]
        }
    }

    method getColumn {varName field} {
        # gets a column from the database component
        upvar 1 $varName var
        set var [$db getColumn [my LookupColumn $field]]
    }

    method getColumnValues {varName field {value {}}} {
        # gets a column from the database component with all empty cells removed
        upvar 1 $varName var
        set cells [$db getColumn [my LookupColumn $field]]
        set var [lmap cell $cells {
            if {$cell ne {}} {
                set cell
            } elseif {$value ne {}} {
                set value
            } else {
                continue
            }
        }]
    }

    method getFields {{fields {}}} {
        # return a dictionary of field names and values
        if {[llength $fields] < 1} {
            set fields [dict keys $colres]
        }
        foreach field $fields {
            lappend res $field [$db get [my LookupColumn $field]]
        }
        return $res
    }

    unexport unknown destroy

}
