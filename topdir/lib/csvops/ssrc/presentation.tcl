
# a class that can create data tables

oo::class create Presentation {
    variable m distribution

    constructor args {
        my addHeader {*}$args
        log addMessage {%s created} "Presentation [self]"
    }

    destructor {
        catch {$m delete}
        log addMessage {%s destroyed} "Presentation [self]"
    }

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

    method getColumnKeys {} {
        lrange [$m get row 0] 1 end
    }

    method getRowKeys {} {
        lrange [$m get column 0] 1 end
    }

    method getLabel {} {
        $m get cell 0 0
    }

    method LookupDim {dim x} {
        switch $dim {
            row {set range [$m get column 0]}
            column {set range [$m get row 0]}
            default {
                return -code error [mc {bad dimension %s} $dim]
            }
        }
        set idx [lsearch [lrange $range 1 end] $x]
        if {$idx < 0} {
            return -code error [mc "$dim header %s missing" $x]
        }
        incr idx
    }

    forward lookupColumn my LookupDim column
    forward lookupRow my LookupDim row

    method get {row col} {
        $m get cell [my LookupDim column $col] [my LookupDim row $row]
    }

    method set {row col val} {
        $m set cell [my LookupDim column $col] [my LookupDim row $row] $val
        return $val
    }

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

    method tally args {
        if {[lindex $args 0] eq {}} return
        incr distribution($args)
    }

    method getRow row {
        $m get row [my LookupDim row $row]
    }

    method getColumn col {
        $m get column [my LookupDim column $col]
    }

    method rows {} {
        $m rows
    }

    method columns {} {
        $m columns
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

