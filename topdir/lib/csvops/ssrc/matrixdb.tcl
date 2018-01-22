
#
# manages a matrix and provides db methods for it
#

if {[info commands ::MatrixDB] ne {}} return

if {[info commands ::csv::select2matrix] eq {}} {
    source [file join [file dirname [info script]] select2matrix.tcl]
}

oo::class create MatrixDB {
    variable m currentrow

    destructor {
        catch {$m destroy}
    }

    method CheckDB args {
        # before access, check if there is an open, non-empty database
        # Do not filter the core method implementations
        lassign [self target] def method
        if {$def ne "::oo::object" && $method ni {fill import}} {
            if {![info exists m]} {
                return -code error [mc {database not opened}]
            }
            if {[$m rows] < 1} {
                return -code error [mc {database is empty}]
            }
        }
        next {*}$args
    }
    filter CheckDB

    method fill args {
        # load a matrix database from a csv file
        catch {$m delete}
        set m [::struct::matrix]
        ::csv::select2matrix {*}$args $m
        set currentrow 0
        return
    }

    method import _m {
        # import a copy of an existing matrix database
        catch {$m delete}
        set m [::struct::matrix]
        $m = $_m
        set currentrow 0
        return
    }

    method seek row {
        if {[expr {0 < $row && $row <= [$m rows]}]} {
            incr row -1
            set currentrow $row
        } else {
            return -code error [mc {invalid row number %s} $row]
        }
    }

    method tell {} {
        expr {$currentrow + 1}
    }

    method iterate script {
        set nrows [$m rows]
        for {set currentrow 0} {$currentrow < $nrows} {incr currentrow} {
            uplevel 1 $script
        }
    }

    method get col {
        tailcall $m get cell $col $currentrow
    }

    method getColumn col {
        tailcall $m get column $col
    }

    method rows {} {
        tailcall $m rows
    }

    method columns {} {
        tailcall $m columns
    }

    method expose {} {
        tailcall $m get rect 0 0 [expr {[$m columns] - 1}] [expr {[$m rows] - 1}]
    }
}
