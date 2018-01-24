package require csv

if {[info commands ::DB] ne {}} {
    return
}

if {[info commands ::Table] ne {}} {
    return
}

oo::class create DB {
    variable options

    constructor {{filename :memory:}} {
        sqlite3 [self namespace]::dbcmd $filename
        array set options {-oseparator ;}
        array set options [array get ::options]
    }

    destructor {
        [self namespace]::dbcmd close
    }

    method select {tableid args} {
        if {[llength $args] < 1} {
            set columns *
        } else {
            set columns [join $args ,]
        }
        dbcmd eval [format {SELECT %s FROM %s} $columns $tableid]
    }

    method insert {tableid args} {
        if {[llength $args] eq 1} {
            set columns {}
            set values ([join [my ImportValues [lindex $args 0]] ,])
        } elseif {[llength $args] eq 2} {
            set columns ([join [lindex $args 0] ,])
            set values ([join [my ImportValues [lindex $args 1]] ,])
        } else {
            return -code error [mc {wrong number of arguments, should be "insert tableid ?columns? values"}]
        }
        dbcmd eval [format {INSERT INTO %s %s VALUES %s} $tableid $columns $values]
    }

    method exists args {
        # TODO
    }
    
    method create {tableid args} {
        # TODO add test
        if {[llength $args] > 0} {
            set columns [join $args ,]
            dbcmd eval [format {CREATE TABLE %s (%s)} $tableid $columns]
        }
    }

    method eval2 args {
        if {[llength $args] eq 2} {
            lassign $args varName sql
            upvar 1 $varName res
        } elseif {[llength $args] eq 1} {
            lassign $args sql
        } else {
            return -code error [mc {wrong number of arguments to eval2}]
        }
        set ln 0
        set res {}
        dbcmd eval $sql ROW {
            dict set res * $ROW(*)
            foreach col $ROW(*) {
                dict lappend res $ln $ROW($col)
            }
            incr ln
        }
        return $res
    }

    method eval args {
        if yes {
        uplevel 1 [list [self namespace]::dbcmd eval {*}$args]
        } elseif no {
        tailcall [self namespace]::dbcmd eval {*}$args
        } else {
        }
    }

    method makeTable {tableid fields rows} {
        my CreateTable $tableid $fields
        foreach row $rows {
            my InsertRow $tableid [my ImportValues $row]
        }
    }

    method readTable {tableid filename} {
        try {
            open $filename
        } on ok f {
            set rows [lassign [my GetRows $f] fields]
            my makeTable $tableid $fields $rows
            return $fields
        } finally {
            catch {chan close $f}
        }
    }

    method read filename {
        try {
            open $filename
        } on ok f {
            my GetRows $f
        } finally {
            catch {chan close $f}
        }
    }

    method read1 filename {
        try {
            open $filename
        } on ok f {
            gets $f
            my GetRows $f
        } finally {
            catch {chan close $f}
        }
    }

    method write {tableid filename} {
        try {
            open $filename w
        } on ok f {
            dbcmd eval "SELECT * FROM $tableid" F {
                if {![info exists columnNames]} {
                    set columnNames $F(*)
                    puts $f [::csv::join $columnNames $options(-oseparator)]
                }
                set line {}
                foreach col $columnNames {
                    lappend line $F($col)
                }
                puts $f [::csv::join $line $options(-oseparator)]
            }
        } finally {
            catch {chan close $f}
        }
    }

    method CreateTable {tableid fields} {
        set types [lmap field $fields {
            if {[llength $field] > 1} {
                lindex $field end
            } else {
                format text
            }
        }]
        [self namespace]::dbcmd eval "CREATE TABLE $tableid ([join $fields ,])"
        return $types
    }

    method InsertRow {tableid values} {
        [self namespace]::dbcmd eval "INSERT INTO $tableid VALUES([join $values ,])"
    }

    method ImportValues values {
        lmap value $values {
            set flval [string map {, .} $value]
            if {[string is entier -strict $value]} {
                set value
            } elseif {[string is double -strict $flval]} {
                set flval
            } else {
                format '%s' [string map {' ''} $value]
            }
        }
    }

    method ExportValues values {
        lmap value $values {
            if {[string is double -strict $value} {
                string map {. ,} $value
            } else {
                set value
            }
        }
    }

    method GetRows channel {
        if no {
        # TODO kludge, this option should be set
        if {![info exists options(-separator)]} {
            set options(-separator) \;
        }
        }
        set result {}
        while {[gets $channel line] >= 0} {
            lappend result [::csv::split $line $options(-separator)]
        }
        return $result
    }

}
