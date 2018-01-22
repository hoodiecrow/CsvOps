package require csv
package require struct::matrix
package require math::statistics
package require fileutil

oo::class create View {
    variable options m RowID
    constructor args {
        set args [my ParseOptions $args]
        set m [::struct::matrix]
        if {[llength $args] > 0} {
            my ReadData {*}$args
        }
        set RowID 0
    }

    destructor {
        $m destroy
    }

    method ParseOptions arglist {
        array set options {-separator \; -noheader 0}
        while {[llength $arglist]} {
            switch [::tcl::prefix match -error {} {-rowid -header -separator --} [lindex $arglist 0]] {
                -separator {set arglist [lassign $arglist - options(-separator)]}
                -noheader  {set arglist [lrange $arglist 1 end] ; set options(-noheader) 1}
                --         {set arglist [lrange $arglist 1 end] ; break}
                default {
                    if {[string match -* [lindex $arglist 0]]} {
                        error [mc {unknown option %s} [lindex $arglist 0]]
                    } else {
                        break
                    }
                }
            }
        }
        return $arglist
    }

    method ReadData {fn1 {fn2 {}}} {
        try {open $fn1} on ok f {
            my ReadCSV $f
            if {$fn2 ne {}} {
                set header [$m get row 0]
                try {open $fn2} on ok f {
                    my ReadCSV $f
                    $m insert row 0 $header
                } finally {
                    catch {chan close $f}
                }
            }
        } finally {
            catch {chan close $f}
        }
    }

    method ReadCSV chan {
        set _m [::struct::matrix]
        ::csv::read2matrix $chan $_m $options(-separator) empty
        if {$options(-noheader)} {
            set header {}
            for {set i 0} {$i < [$_m columns]} {incr i} {
                lappend header field$i
            }
            $_m insert row 0 $header
        }
        $m = $_m
        $_m destroy
    }

    method NextRowID {} {
        incr RowID
    }

    method FieldExists field {
        expr {[lsearch -exact [$m get row 0] $field] >= 0}
    }

    method GetColumn field {
        set i [lsearch -exact [$m get row 0] $field]
        if {$i < 0} {
            return -code error "unknown field \"$field\""
        }
        return $i
    }

    method NewFromRows rows {
        set header [$m get row 0]
        set _ [::struct::matrix]
        $_ add columns [llength $header]
        $_ add row $header
        foreach row $rows {
            $_ add row $row
        }
        $m = $_
        $_ destroy
    }

    method = v {
        $m deserialize [$v serialize]
        self
    }
    export =

    method --> v {
        $v deserialize [$m serialize]
        self
    }
    export -->

    method M args {
        $m {*}$args
        self
    }
    
    method add {what args} {
        switch $what {
            field {
                set args [lassign $args field]
                if {[my FieldExists $field]} {
                    return -code error "field \"$field\" already exists"
                } else {
                    $m add column [concat $args]
                }
            }
            row {
                if {[llength $args] == 2} {
                    foreach col [lindex $args 0] val [lindex $args 1] {
                        dict set colval $col $val
                    }
                    foreach col [$m get row 0] {
                        if {[dict exists $colval $col]} {
                            lappend values [dict get $colval $col]
                        } else {
                            lappend values {}
                        }
                    }
                } else {
                    set values [lindex $args 0]
                }
                if {[$m get cell 0 0] eq "@"} {
                    set values [linsert $values 0 [my NextRowID]]
                }
                $m add row $values
            }
            default {
                # column columns rows
                $m add $what {*}$args
            }
        }
        self
    }

    method GetCalcData field {
        lmap v [lrange [$m get column [my GetColumn $field]] 1 end] {
            if {[string is double -strict $v] || [string is entier -strict $v]} {
                set v
            } else {
                continue
            }
        }
    }

    method calc {fun args} {
        # does NOT return [self]
        lassign [lreverse $args] field distinct
        switch $fun {
            avg - min - max - sum {
                set data [my GetCalcData $field]
                switch $fun {
                    avg {::math::statistics::mean $data}
                    min {::math::statistics::min $data}
                    max {::math::statistics::max $data}
                    sum {::tcl::mathop::+ {*}$data}
                }
            }
            count {
                if {$field eq "*"} {
                    expr {[$m rows] - 1}
                } else {
                    set data [my GetCalcData $field]
                    if {$distinct eq "-distinct"} {
                        set data [lsort -unique $data]
                    }
                    llength $data
                }
            }
            first {
                lindex $data 0
            }
            last {
                lindex $data end
            }
        }
    }

    forward cells my M cells 
    forward cellsize my M cellsize 
    forward columns my M columns 

    method delete {what args} {
        switch $what {
            field {
                set args [lassign $args field]
                set col [my GetColumn $field]
                if {$col < 0} {
                    return -code error "no such field \"$field\""
                } else {
                    $m delete column $col
                }
            }
            rows {
                if {[llength $args] == 0} {
                    # delete all tuples
                    if {[$m rows] > 1} {$m delete rows [expr {[$m rows] - 1}]}
                } elseif {[lindex $args 0] eq "-filter"} {
                    set predicate [lindex $args 1]
                    switch $predicate {
                        0 {return [self]}
                        1 {$m delete rows [expr {[$m rows] - 1}]}
                        default {
                            set fields [$m get row 0]
                            set int [interp create]
                            # going backward, delete all rows that match
                            for {set row [expr {[$m rows] - 1}]} {$row > 0} {incr row -1} {
                                set data [$m get row $row]
                                $int eval [list lassign $data {*}$fields]
                                if {[$int eval [list expr $predicate]]} {
                                    $m delete row $row
                                }
                            }
                            interp delete $int
                        }
                    }
                } else {
                    $m delete rows [lindex $args 0]
                }
            }
            default {
                # column columns row
                $m delete $what {*}$args
            }
        }
        self
    }

    forward deserialize my M deserialize 

    method distinct {} {
        my NewFromRows [lsort -unique [my get rows]]
        self
    }

    method except view {
        set a [my get rows]
        set b [$view get rows]
        my NewFromRows [::struct::set difference $a $b]
        self
    }

    method expr {expr field} {
        # TODO evaluate expression for each row and store in field
        set field [my GetColumn $field]
        set fields [$m get row 0]
        set int [interp create]
        set nrows [$m rows]
        set cmd [list expr $expr]
        for {set row 1} {$row < $nrows} {incr row} {
            set data [$m get row $row]
            $int eval [list lassign $data {*}$fields]
            $m set cell $col $row [$int eval $cmd]
        }
        interp delete $int
        self
    }

    method filter predicate {
        set fields [$m get row 0]
        set int [interp create]
        # going backward, delete all rows that don't match
        for {set row [expr {[$m rows] - 1}]} {$row > 0} {incr row -1} {
            set data [$m get row $row]
            $int eval [list lassign $data {*}$fields]
            if {![$int eval [list expr $predicate]]} {
                $m delete row $row
            }
        }
        interp delete $int
        self
    }

    forward format my M format

    method get {what args} {
        # do not return [self]
        switch $what {
            header {
                $m get row 0
            }
            index {
                $m get cell 0 0
            }
            rows {
                lrange [lindex [$m serialize] 2] 1 end
            }
            default {
                # cell column rect row
                $m get $what {*}$args
            }
        }
    }

    method index {} {
        set indexes [$m get column 0]
        # going backwards, remove rows that are duplicates in column 0
        for {set row [expr {[$m rows] - 1}]} {$row > 0} {incr row -1} {
            if {[lsearch $indexes [lindex [$m get row $row] 0]] < $row} {
                $m delete row $row
            }
        }
        self
    }

    method insert {what args} {
        switch $what {
            field {
                set args [lassign $args field]
                set col [my GetColumn $field]
                if {$col < 0} {
                    return -code error "no such field \"$field\""
                } elseif {$col == 0} {
                    return -code error "can't insert before index"
                } else {
                    lassign $args values
                    $m insert column $col $values
                }
            }
            row {
                if {[lindex $args 0] == 0} {
                    return -code error "can't insert before header"
                }
                if {[$m get cell 0 0] eq "@"} {
                    lassign $args row values
                    $m insert row $row [linsert $values 0 [my NextRowID]]
                }
            }
            column {
                if {[lindex $args 0] == 0} {
                    return -code error "can't insert before index"
                }
                $m insert column {*}$args
            }
        }
        self
    }

    method intersect view {
        set a [my get rows]
        set b [$view get rows]
        my NewFromRows [::struct::set intersect $a $b]
        my distinct
        self
    }

    method join args {
        if {[lindex $args 0] in {-inner -left -right -full}} {
            set args [lassign $args type]
        } else {
            set type -inner
        }
        set view [lindex $args 0]
        # TODO
        self
    }

    forward link my M link
    forward links my M links

    method merge view {
        # TODO
        # foreach row in view
        # if view.index exists in m
        # update m
        # else
        # insert in m
        self
    }

    method order-by args {
        set fields [my get header]
        foreach sort $args {
            set sort [lassign $sort field]
            if {$field ni $fields} {
                return -code error "nonexistent field $field"
            }
            set index [lsearch $fields $field]
            my set rows [lsort -index $index {*}$sort [my get rows]]
        }
        self
    }

    method range {a b} {
        lassign [my serialize] r c data
        set data [lrange $data $a $b]
        list [llength $data] $c $data
    }

    method read args {
        array set saveOptions [array get options]
        set args [my ParseOptions $args]
        my ReadData {*}$args
        set RowID 0
        array set options [array get saveOptions]
        self
    }

    method rename dict {
        $m set row 0 [lmap h [$m get row 0] {
            if {[dict exists $dict $h]} {
                dict get $dict $h
            } else {
                set h
            }
        }]
        self
    }

    method renumber {} {
        if {[$m get cell 0 0] eq "@"} {
            # TODO
            # sort by column 0
            # renumber from 1
        }
        self
    }

    forward rowheight my M rowheight
    forward rows my M rows 
    forward search my M search 

    method select args {
        # TODO going from right to left, remove columns that aren't in $args
        set fields [lindex $args 0]
        for {set col [expr {[$m columns] - 1}]} {$col >= 0} {incr col -1} {
            if {[$m get cell $col 0] ni $fields} {
                $m delete column $col
            }
        }
        self
    }

    method serialize {} {
        # can't be run through M and must not return [self]
        $m serialize
    }

    method set {what args} {
        switch $what {
            header {
                set header [lindex $args 0]
                set diff [expr {[llength $header] - [$m columns]}]
                if {$diff > 0} {
                    $m add columns $diff
                } elseif {$diff < 0} {
                    for {set col 0} {$col < [$m columns]} {incr col} {
                        if {[lindex $header $col] eq {}} {
                            set h #$col
                            while {$h in $header} {
                                set h $h'
                            }
                            lset header $col $h
                        }
                    }
                }
                if {[$m rows] < 1} {
                    $m add row $header
                } else {
                    $m set row 0 $header
                }
            }
            cell {
                lassign $args column row value
                if {$column == 0} {
                    set cindex [$m get cell 0 $row]
                    if {$row > 0 && $value != $cindex} {
                        set indexes [lrange [$m get column 0] 1 end]
                        if {[$m get cell 0 0] eq "@" || $values in $indexes} {
                            return -code error "indexing error writing data cell"
                        }
                    }
                }
                $m set cell $column $row $value
            }
            row {
                lassign $args row values
                set dindex [lindex $values 0]
                set cindex [$m get cell 0 $row]
                if {$row > 0 && $dindex != $cindex} {
                    set indexes [lrange [$m get column 0] 1 end]
                    if {[$m get cell 0 0] eq "@" || $dindex in $indexes} {
                        return -code error "indexing error writing data row"
                    }
                }
                $m set row $row $values
            }
            rows {
                set header [my get header]
                lassign [my serialize] r c
                lassign $args data
                set data [linsert $data 0 $header]
                $m deserialize [list [llength $data] $c $data]
            }
            default {
                # column rect
                $m set $what {*}$args
            }
        }
        self
    }

    method sort {what args} {
        # TODO protect header and index column
    }

    method swap {what a b} {
        # TODO protect header and index column
    }

    method transpose {} {return -code error "transpose operation not available"}

    method union view {
        set a [my get rows]
        set b [$view get rows]
        my NewFromRows [::struct::set union $a $b]
        self
    }

    method union-all view {
        set a [my get rows]
        set b [$view get rows]
        my NewFromRows [concat $a $b]
        self
    }

    forward unlink my M unlink

    method write filename {
        ::fileutil::writeFile $filename [::csv::joinmatrix $m $options(-separator)]
    }


    ### =========================================================================================

    method getRows {} {
        if {[$m rows] <= 1} {
            return {}
        } else {
            $m get rect 0 1 [expr {[$m columns] - 1}] [expr {[$m rows] - 1}]
        }
    }
    method getData {} {
        if {[$m rows] <= 1} {
            return {}
        } elseif {$options(-rowid)} {
            $m get rect 1 1 [expr {[$m columns] - 1}] [expr {[$m rows] - 1}]
        } else {
            tailcall my getRows
        }
    }

    method _uniintdif {op rr} {
        # distinct union, intersect, or difference
        # non-distinct union-all
        # distinct
        set a [my getData]
        if {$op eq "distinct"} {
            set rows $a
        } else {
            set b [$rr getData]
            set rows [if {$op eq "union-all"} {
                concat $a $b
            } else {
                ::struct::set $op $a $b
            }]
        }
        if {$op in {intersect distinct}} {
            set rows [::struct::set union $rows {}]
        }
        if {[$m rows] > 1} {$m delete rows [expr {[$m rows] - 1}]}
        foreach row $rows {$m add row $row}
    }
    #forward union my _uniintdif union
    #forward intersect my _uniintdif intersect
    #forward except my _uniintdif difference
    #forward union-all my _uniintdif union-all
    #forward distinct my _uniintdif distinct {}

    method unique args {
        set fields [my get header]
        set indexes [lmap field $args {
            if {$field ni $fields} {
                return -code error "nonexistent field $field"
            }
            lsearch $fields $field
        }]
        set rows [lmap row [my get rows] {
            set idx [lmap i $indexes {
                lindex $row $i
            }]
            list $idx $row
        }]
        set rows [lmap row [lsort -unique -index 0 $rows] {
            lindex $row 1
        }]
        if {[$m rows] > 1} {$m delete rows [expr {[$m rows] - 1}]}
        foreach row $rows {$m add row $row}
    }

    method _deprecated_limit {limit {offset 0}} {
        if {!([string is entier -strict $offset] && $offset >= 0)} {
            return -code error "offset must be a positive integer"
        }
        set rows [my getData]
        if {[regexp {all(?:(-\d+))?$} $limit -> n]} {
            set offset 0
            set limit [llength $rows]
            if {$n ne {}} {
                incr limit $n
            }
        }
        if {![string is entier -strict $limit]} {
            return -code error "limit must be integral, \"all\", or \"all-n\""
        }
        incr limit $offset
        if {$limit == 0} {
            $m delete rows [expr {[$m rows] - 1}]
        } else {
            incr limit -1
            if {$limit >= [llength $rows]} {
                set limit end
            }
            set rows [my getData]
            $m delete rows [expr {[$m rows] - 1}]
            foreach row [lrange $rows 0 $limit] {$m add row $row}
        }
    }

    method PredicateEval {predicate fields values} {
        set int [interp create]
        foreach field $fields value $values {
            $int eval [list set $field $value]
        }
        set res [$int eval [list expr $predicate]]
        interp delete $int
        return $res
    }

    method copy _m {
        $m = $_m
    }

}

