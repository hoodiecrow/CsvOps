package require struct::matrix
package require struct::set



return




oo::class create Table {
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
        $m add row $args
    }
    method getFieldNames {} {
        $m get row 0
    }
    method getData {} {
        if {[$m rows] < 2} {
            return {}
        }
        $m get rect 0 1 [expr {[$m columns] - 1}] [expr {[$m rows] - 1}]
    }
}
