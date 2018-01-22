package require csv

if {[info commands ::DB] ne {}} {
    return
}

if {[info commands ::Table] ne {}} {
    return
}

oo::class create DB {

    constructor args {
        sqlite3 dbcmd :memory:
        switch [llength $args] {
            0 {
                ;
            }
            3 {
                my makeTable {*}$args
            }
            default {
                return -code error [mc {wrong # of arguments (%d), should be (none) or tableid fields rows} [llength $args]]
            }
        }
    }

    destructor {
        dbcmd close
    }

    method eval args {
        uplevel 1 [namespace code [list dbcmd eval {*}$args]]
    }

    method makeTable {tableid fields rows} {
        set types [my CreateTable $tableid $fields]
        foreach row $rows {
            my InsertRow $tableid [my TypeDecorate $types $row]
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

    method CreateTable {tableid fields} {
        set types [lmap field $fields {
            if {[llength $field] > 1} {
                lindex $field end
            } else {
                format text
            }
        }]
        dbcmd eval "CREATE TABLE $tableid ([join $fields ,])"
        return $types
    }

    method InsertRow {tableid values} {
        dbcmd eval "INSERT INTO $tableid VALUES([join $values ,])"
    }

    method TypeDecorate {types values} {
        lmap type $types value $values {
            switch -glob $type {
                text - char - char(*) - varchar - varchar(*) {format '%s' $value}
                int - float(*) - double(*)  {set value}
                default {
                    return -code error [mc {unsupported sql type "%s"} $type]
                }
            }
        }
    }

    method GetRows channel {
        # TODO kludge, this option should be set
        if {![info exists options(-separator)]} {
            set options(-separator) \;
        }
        set result {}
        while {[gets $channel line] >= 0} {
            lappend result [::csv::split $line $options(-separator)]
        }
        return $result
    }

}

oo::class create Table {
    # original intention was to model a result set
    variable dbcmd

    constructor {_dbcmd args} {
        set dbcmd $_dbcmd
        switch [llength $args] {
            0 {
                ;
            }
            3 {
                my makeTable {*}$args
            }
            default {
                return -code error [mc {wrong # of arguments (%d), should be dbcmd or dbcmd tableid fields rows} [llength $args]]
            }
        }
    }

    method makeTable {tableid fields rows} {
        set types [my CreateTable $tableid $fields]
        foreach row $rows {
            my InsertRow $tableid [my TypeDecorate $types $row]
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

    method CreateTable {tableid fields} {
        set types [lmap field $fields {
            if {[llength $field] > 1} {
                lindex $field end
            } else {
                format text
            }
        }]
        $dbcmd eval "CREATE TABLE $tableid ([join $fields ,])"
        return $types
    }

    method InsertRow {tableid values} {
        $dbcmd eval "INSERT INTO $tableid VALUES([join $values ,])"
    }

    method TypeDecorate {types values} {
        lmap type $types value $values {
            switch -glob $type {
                text - char - char(*) - varchar - varchar(*) {format '%s' $value}
                int - float(*) - double(*)  {set value}
                default {
                    return -code error [mc {unsupported sql type "%s"} $type]
                }
            }
        }
    }

    method GetRows channel {
        # TODO kludge, this option should be set
        if {![info exists options(-separator)]} {
            set options(-separator) \;
        }
        set result {}
        while {[gets $channel line] >= 0} {
            lappend result [::csv::split $line $options(-separator)]
        }
        return $result
    }

}

oo::class create Result {
    mixin Table
}
