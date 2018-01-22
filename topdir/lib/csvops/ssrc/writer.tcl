package require struct::matrix

oo::class create Writer {
    variable m options

    constructor args {
        # get options defaults (note expand = auto)
        array set options {
            -fields {}
        }

        # modify by global defaults (which override)
        if {[info exists ::options]} {
            array set options [array get ::options]
        }

        while {[llength $args]} {
            switch [::tcl::prefix match -error {} {-oseparator -fields} [lindex $args 0]] {
                -oseparator {set args [lassign $args - options(-oseparator)]}
                -fields    {set args [lassign $args - options(-fields)]}
                default break
            }
        }

        set m [::struct::matrix]
        log addMessage {%s created} "Writer [self]"
    }

    destructor {
        $m destroy
        log addMessage {%s destroyed} "Writer [self]"
    }

    method oseparator char {
        set options(-oseparator) $char
    }

    method fields fields {
        set options(-fields) $fields
    }

    method import _m {
        # import a copy of an existing matrix database
        $m = $_m
    }

    method deserialize ser {
        tailcall $m deserialize $ser
    }

    method put args {
        # adds a new row to the matrix, extends row if necessary
        if {[llength $args] > 0} {
            lassign $args key values
            set data [list $key {*}[dict values $values]]
        } else {
            upvar 1 F F
            set data [lmap field $options(-fields) {
                try {
                    set F($field)
                } on error {} {
                    return -code error [mc {unknown field name %s} $field]
                }
            }]
        }
        extendRow $m [llength $data]
        $m add row $data
        log setLabel "Writer [self]" {storing line %s} [$m rows]
    }

    method write filename {
        # write the matrix to the channel
        if {[info exists options(-oseparator)]} {
            set oseparator $options(-oseparator)
        } else {
            set oseparator $options(-separator)
        }
        log addMessage {%s writing %s} "Writer [self]" $filename

        try {
            open $filename w
        } on ok chan {
            ::csv::writematrix $m $chan $oseparator
        } finally {
            catch {chan close $chan}
        }
    }

    method clear {} {
        $m = [::struct::matrix]
    }

}
