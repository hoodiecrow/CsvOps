
# a class that can create data tables

oo::class create Presentation {
    variable label data m distribution

    constructor args {
        lassign $args label data
    }

    if no {
    method CheckLabel args {
        lassign [self target] def method
        if {$def ne "::oo::object" &&
            $method ni {addHeader getColumnKeys getRowKeys getLabel} &&
            $method in [info object methods [self] -all]
        } then {
            if {![info exists m]} {
                return -code error [mc {table doesn't exist}]
            }
        }
        next {*}$args
    }
    filter CheckLabel
    }

    if no {
    method addHeader args {
        if {[llength $args] > 1} {
            catch {$m delete}
            set m [::struct::matrix]
            $m add columns [llength $args]
            $m add row $args
            ::control::assert {[$m columns] == [llength $args]}
            ::control::assert {[$m rows] == 1}
        }
    }

    method addRow args {
        $m add row $args
    }
    }

    method getColumnKeys {} {
        dict get $data *
    }

    method getRowKeys {} {
        lrange [dict keys $data] 1 end
    }

    method getLabel {} {
        set label
    }

    method lookupColumn col {
        set idx [lsearch [my getColumnKeys] $col]
        if {$idx < 0} {
            return -code error [mc "column header %s missing" $col]
        }
        # TODO do I really need to incr and then -1?
        incr idx
    }

    method lookupRow row {
        # TODO assumes row id is in first column, may have to refine that
        set idx [lsearch -index 0 [lrange [dict values $data] 1 end] $row]
        if {$idx < 0} {
            return -code error [mc "row header %s missing" $row]
        }
        incr idx
    }

    method get {row col} {
        lindex [dict get $data [expr {[my lookupRow $row]-1}]] [my lookupColumn $col]-1
    }

    if no {
    method set {row col val} {
        $m set cell [my LookupDim column $col] [my LookupDim row $row] $val
        return $val
    }
    }

    if no {
    method incr {row col {inc 1}} {
        set c [my LookupDim column $col]
        set r [my LookupDim row $row]
        set val [$m get cell $c $r]
        if {$inc ne {}} {
            incr val $inc
            $m set cell $c $r $val
        }
        return $val
    }
    }

    method tally args {
        if {[lindex $args 0] eq {}} return
        incr distribution($args)
    }

    method getRow row {
        # TODO assumes row id is in first column, may have to refine that
        lsearch -inline -index 0 [lrange [dict values $data] 1 end] $row
    }

    method getColumn col {
        set idx [my lookupColumn $col]
        set res {}
        dict for {key row} [lrange $data 2 end] {
            lappend res [lindex $row $idx-1]
        }
        return $res
    }

    method rows {} {
        expr {[dict size $data] - 1}
    }

    method columns {} {
        llength [dict get $data *]
    }

    method makeDistribution {by maxlen args} {
        set names [array names distribution]
        set len [llength [lindex $names 0]]
        if {$len < 1} return
        if {$len == 1} {
            set args [linsert $args 0 -stride 2 -index [string equal -nocase $by value]]
            set data [lsort {*}$args [array get distribution]]
            if {$maxlen > 0} {
                incr maxlen $maxlen
                set data [lrange $data 0 $maxlen-1]
            }
            foreach {name value} $data {
                my addRow $name $value
            }
        } else {
            set rowkeys [lmap name $names {
                lrange $name 0 end-1
            }]
            set rowkeys [lsort -unique {*}$args $rowkeys]
            if {$maxlen > 0} {
                set rowkeys [lrange $rowkeys 0 $maxlen-1]
            }
            set zeroes [lrepeat [my columns] 0]
            foreach rowkey $rowkeys {
                my addRow [join $rowkey -] {*}$zeroes
                foreach colkey [my getColumnKeys] {
                    set key [list {*}$rowkey $colkey]
                    if {[info exists distribution($key)]} {
                        my set $rowkey $colkey $distribution($key)
                    }
                }
            }
        }
    }

    method toDOM doc {
        set tnode [$doc createElement table]

        dom createNodeCmd elementNode caption
        dom createNodeCmd elementNode tr
        dom createNodeCmd elementNode th
        dom createNodeCmd elementNode td
        dom createNodeCmd textNode t

        $tnode appendFromScript {caption {t [my getLabel]}}
        for {set i 0} {$i < [$m rows]} {incr i} {
            set vals [lassign [$m get row $i] rowkey]
            if {$i == 0} {
                set rowkey {}
                set nc th
            } else {
                set nc td
            }
            $tnode appendFromScript {
                tr {
                    th {t $rowkey}
                    foreach val $vals {
                        $nc {t $val}
                    }
                }
            }
        }

        return $tnode
    }

    method asLoL {} {
        # list of lists; specifically, list of rows
        for {set i 0} {$i < [$m rows]} {incr i} {
            lappend res [$m get row $i]
        }
        return $res
    }

    method toMatrix _m {
        # fill an empty matrix, created elsewhere
        $_m = $m
        return $_m
    }
}

