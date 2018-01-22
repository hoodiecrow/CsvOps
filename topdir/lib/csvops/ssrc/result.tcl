package require struct::matrix
package require struct::set
package require csv

oo::class create Result {
    variable m f

    constructor args {

        set m [::struct::matrix]

        oo::objdefine [self] {
            upvar 1 m m f f
            forward addRows    $m add rows              ; lappend f addRows
            forward addColumns $m add columns           ; lappend f addColumns
            forward getRect    $m get rect              ; lappend f getRect
            forward setRect    $m set rect              ; lappend f setRect
            forward addRow     $m add row               ; lappend f addRow
            forward union      my _uniintdif union      ; lappend f union
            forward +          my _uniintdif union      ; lappend f +
            forward intersect  my _uniintdif intersect  ; lappend f intersect
            forward *          my _uniintdif intersect  ; lappend f *
            forward except     my _uniintdif difference ; lappend f except
            forward -          my _uniintdif difference ; lappend f -
            forward union-all  my _uniintdif union-all  ; lappend f union-all
            export + * -
        }

        switch [llength $args] {
            0 {}
            1 {$m = [lindex $args 0]}
            2 {my MakeResultSet {*}$args}
            default {
                return -code error "wrong # of arguments"
            }
        }
    }

    destructor {
        catch {$m destroy}
    }

    method unknown {name args} {
        try {
            $m $name {*}$args
        } on error {} {
            set forwards $f
            set methods [lsort -ascii [concat $forwards [info class methods [self class]]]]
            return -code error "unknown method \"$name\": must be [join $methods {, }], or a struct::matrix method"
        }
    }
    method MakeResultSet {fields rows} {
        my setFieldNames {*}$fields
        set len [llength $rows]
        if {$len > 0} {
            my addRows $len
            my setRect 0 1 $rows
        }
    }
    method setFieldNames args {
        set len [expr {[llength $args] - [$m columns]}]
        if {$len > 0} {
            $m add columns $len
        }
        if {[$m rows] > 0} {
            $m set row 0 $args
        } else {
            $m add row $args
        }
    }
    method getFieldNames {} {
        if {[$m rows] > 0} {
            $m get row 0
        } else {
            return {}
        }
    }
    method getData {} {
        if {[$m rows] < 2} {
            return {}
        }
        $m get rect 0 1 [expr {[$m columns] - 1}] [expr {[$m rows] - 1}]
    }
    method _uniintdif {op rr} {
        # distinct union, intersect, or difference
        # non-distinct union-all
        # TODO problem: set operations probably can't be relied on to preserve row order
        # TODO why does the test result specify reverse row order?
        set fields [my getFieldNames]
        set a [my getData]
        set b [$rr getData]
        set rows [if {$op eq "union-all"} {
            concat $a $b
        } elseif {   0   &&   $op eq "union"} {
            set union {}
            foreach row $a {
                dict set union $row 1
            }
            foreach row $b {
                dict set union $row 1
            }
            dict keys $union
        } else {
            ::struct::set $op $a $b
        }]
        if {$op eq "intersect"} {
            set rows [::struct::set union $rows {}]
        }
        return [Result new $fields $rows]
    }
    method distinct {} {
        set fields [my getFieldNames]
        set rows [::struct::set union [my getData] {}]
        return [Result new $fields $rows]
    }
    method unique args {
        set fields [my getFieldNames]
        set indexes [lmap field $args {
            if {$field ni $fields} {
                return -code error "nonexistent field $field"
            }
            lsearch $fields $field
        }]
        set rows [lmap row [my getData] {
            set idx [lmap i $indexes {
                lindex $row $i
            }]
            list $idx $row
        }]
        set rows [lmap row [lsort -unique -index 0 $rows] {
            lindex $row 1
        }]
        return [Result new $fields $rows]
    }
    method limit {limit {offset 0}} {
        set fields [my getFieldNames]
        set rows [my getData]
        if {!([string is entier -strict $offset] && $offset >= 0)} {
            return -code error "offset must be a positive integer"
        }
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
            return [Result new [my getFieldNames] {}]
        }
        incr limit -1
        if {$limit >= [llength $rows]} {
            set limit end
        }
        return [Result new $fields [lrange $rows 0 $limit]]
    }
    method order-by args {
        set fields [my getFieldNames]
        foreach sort $args {
            set sort [lassign $sort field]
            if {$field ni $fields} {
                return -code error "nonexistent field $field"
            }
            set index [lsearch $fields $field]
            my setRect 0 1 [lsort -index $index {*}$sort [my getData]]
        }
        return [self]
    }
    method PredicateEval {predicate fields values} {
        set int [interp create]
        foreach field $fields value $values {
            $int eval [list dict set __PredicateEvalDict__ $field $value]
        }
        $int eval {dict with __PredicateEvalDict__ {}}
        set res [$int eval [list expr $predicate]]
        interp delete $int
        return $res
    }
    method select args {
        if {[lindex $args 0] eq "-predicate"} {
            set args [lassign $args opt options($opt)]
        } else {
            set options(-predicate) 1
        }
        if {$options(-predicate) == 0} {return [Result new $args {}]}
        set fields [my getFieldNames]
        set indexes [lmap field $args {
            if {$field ni $fields} {
                return -code error "nonexistent field $field"
            }
            lsearch $fields $field
        }]
        set rows {}
        for {set row 1} {$row < [$m rows]} {incr row} {
            set rowdata [$m get row $row]
            if {$options(-predicate) != 1} {
                if {![my PredicateEval $options(-predicate) $fields $rowdata]} continue
            }
            lappend rows [lmap idx $indexes {lindex $rowdata $idx}]
        }
        return [Result new $args $rows]
    }
    method ReadCSV args {
        set options(-noheader) 0
        if {[lindex $args 0] eq "-noheader"} {
            set options([lindex $args 0]) 1
            set args [lrange $args 1 end]
        }
        lassign $args chan sep
        set _m [::struct::matrix]
        ::csv::read2matrix $chan $_m $sep empty
        if {$options(-noheader)} {
            $_m insert row 0 {}
        }
        set res [Result new $_m]
        $_m destroy
        return $res
    }
    method read args {
        if {[lindex $args 0] eq "-separator"} {
            set args [lassign $args opt options($opt)]
        } else {
            set options(-separator) \;
        }
        switch [llength $args] {
            1 {
                try {
                    open [lindex $args 0]
                } on ok f {
                    return [my ReadCSV $f $options(-separator)]
                } finally {
                    catch {chan close $f}
                }
            }
            2 {
                try {
                    open [lindex $args 0]
                } on ok f {
                    set r0 [my ReadCSV $f $options(-separator)]
                    try {
                        open [lindex $args 1]
                    } on ok f {
                        set r1 [my ReadCSV -noheader $f $options(-separator)]
                        set r2 [Result new [$r0 getFieldNames] [$r1 getData]]
                        $r1 destroy
                    } finally {
                        catch {chan close $f}
                    }
                    $r0 destroy
                } finally {
                    catch {chan close $f}
                }
                return $r2
            }
            default {
                return -code error "wrong # of arguments"
            }
        }
    }
}

