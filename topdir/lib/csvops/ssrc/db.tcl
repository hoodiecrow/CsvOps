
if {[llength [info commands ::DB]] > 0} return

package require csv
package require tdom

oo::class create DB {
    variable tally

    constructor {{filename :memory:}} {
        sqlite3 [self namespace]::dbcmd $filename
    }

    destructor {
        [self namespace]::dbcmd close
    }

    forward eval dbcmd eval
    forward function dbcmd function

    # SQL shortcuts: create, select, insert. 

    method create {tableid args} {
        # Create a table given a table name and a sequence of column
        # specifications. Does nothing if no column specifications are given.
        if {[llength $args] > 0} {
            set columns [join $args ,]
            dbcmd eval [format {CREATE TABLE %s (%s)} $tableid $columns]
        }
    }

    method select args {
        # Select columns from a table given a table name and a sequence of
        # column names. * is used if no column names are given. The -dict
        # option sets the return value to be a result dict, otherwise the
        # return value will be a result set.
        if {[lindex $args 0] eq "-dict"} {
            set columns [join [lassign $args - tableid] ,]
            set fn {my dict}
        } else {
            set columns [join [lassign $args tableid] ,]
            set fn {dbcmd eval}
        }
        if {$columns eq {}} {
            set columns *
        }
        {*}$fn [format {SELECT %s FROM %s} $columns $tableid]
    }

    method insert {tableid args} {
        log::logMsg [info level 0]
        #error [info level 0]
        # Insert a row into a table given table name, optionally a list of
        # column names, and a list of values.
        set argc [llength $args]
        lassign [lmap arg [lreverse $args] {join $arg ,}] values columns
        switch $argc {
            1 {
                log::logMsg [list dbcmd eval [format {INSERT INTO %s VALUES (%s)} $tableid $values]]
                dbcmd eval [format {INSERT INTO %s VALUES (%s)} $tableid $values]
            }
            2 {dbcmd eval [format {INSERT INTO %s (%s) VALUES (%s)} $tableid $columns $values]}
            default {
                return -code error [mc {wrong number of arguments, should be "insert tableid ?columns? values"}]
            }
        }
    }

    method dict args {
        set o [OptionHandler new]
        $o option -all
        $o option -values flag 1
        variable dictOpts
        lassign [$o extract [self namespace]::dictOpts {*}$args] sql
        if {[info exists dictOpts(-all)]} {
            set sql [format {SELECT * FROM %s} $dictOpts(-all)]
        }
        set ln 1
        set res {}
        dbcmd eval $sql ROW {
            dict set res * $ROW(*)
            foreach col $ROW(*) {
                dict lappend res $ln $ROW($col)
            }
            incr ln
        }
        if {$dictOpts(-values)} {
            return [dict values $res]
        } else {
            return $res
        }
    }

    method readTable {tableid filename} {
        # Create and populate a table from a file.
        try {
            open $filename
        } on ok f {
            set rows [lassign [my GetRows $f] fields]
            my create $tableid {*}$fields
            my fillTable $tableid {*}$rows
            return $fields
        } finally {
            catch {chan close $f}
        }
    }

    method loadTable {tableid filename} {
        # Populate an existing table from a file.
        try {
            open $filename
        } on ok f {
            my fillTable $tableid {*}[my GetRows $f]
        } finally {
            catch {chan close $f}
        }
    }

    method fillTable {tableid args} {
        # Populate an existing table from a sequence of tuples.
        foreach row $args {
            my insert $tableid $row
        }
    }

    method dumpTable args {
        set o [OptionHandler new]
        $o option -values flag 1
        variable dumpTableOpts
        lassign [$o extract [self namespace]::dumpTableOpts {*}$args] tableid filename 
        try {
            open $filename w
        } on ok f {
            set t [my dict -values -all $tableid]
            set rows [lassign $t fields]
            if {!$dumpTableOpts(-values)} {
                puts $f [::csv::join $fields $::options(-oseparator)]
            }
            puts -nonewline $f [::csv::joinlist [my OutputFilterList $rows] $::options(-oseparator)]
        } finally {
            catch {chan close $f}
            $o destroy
        }
    }

    method OutputFilterList {rows args} {
        set opts {decimal ,}
        set opts [dict merge $opts $args]
        lmap row $rows {
            my OutputFilterRow $row {*}$opts
        }
    }

    method OutputFilterRow {row args} {
        set opts {decimal ,}
        set opts [dict merge $opts $args]
        lmap val $row {
            if {[string is double -strict $val] && "write" in $::options(-convert-decimal)} {
                string map {. ,} $val
            } else {
                string map {'' '} $val
            }
        }
    }

    method InputFilterRow row {
        lmap val $row {
            if {"read" in $::options(-convert-decimal)} {
                set flval [string map {, .} $val]
            } else {
                set flval $val
            }
            if {[regexp {^0\d+$} $val]} {
                # kludge for numeric constants beginning with 0
                format '%s' $val
            } elseif {[string is entier -strict $val]} {
                set val
            } elseif {[string is double -strict $flval]} {
                set flval
            } else {
                format '%s' [string map {' ''} $val]
            }
        }
    }

    method GetRows channel {
        set result {}
        while {[gets $channel line] >= 0} {
            lappend result [my InputFilterRow [::csv::split $line $::options(-separator)]]
        }
        return $result
    }

    method tally {{key {}}} {
        if {$key ne {}} {
            dict incr tally $key
        }
        dict values $tally
    }

    method html {tableid caption} {
        set doc [dom createDocument table]
        set root [$doc documentElement]
        set dict [my dict [format {SELECT * FROM %s} $tableid]]

        dom createNodeCmd elementNode caption
        dom createNodeCmd elementNode tr
        dom createNodeCmd elementNode th
        dom createNodeCmd elementNode td
        dom createNodeCmd textNode t

        $root appendFromScript {caption {t $caption}}
        dict for {key val} $dict {
            $root appendFromScript {
                tr {
                    if {$key eq "*"} {
                        th {t {}}
                        foreach v $val {
                            th {t $v}
                        }
                    } else {
                        th {t $key}
                        foreach v $val {
                            td {t $v}
                        }
                    }
                }
            }
        }
        set res [$doc asHTML]
        $doc delete
        return $res
    }

}
