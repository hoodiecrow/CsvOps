
#
# read a csv file and maintain an internal matrix database
#

package require optionhandler

if {[info commands ::DB] eq {}} {
    source [file join [file dirname [info script]] result.tcl]
}

if {[info commands ::Table] eq {}} {
    source [file join [file dirname [info script]] result.tcl]
}

if {[info commands ::FieldAccess] eq {}} {
    source [file join [file dirname [info script]] fieldaccess.tcl]
}

if {[info commands ::Processor] eq {}} {
    source [file join [file dirname [info script]] processor.tcl]
}

if {[info commands ::Validator] eq {}} {
    source [file join [file dirname [info script]] validator.tcl]
}

if {[info commands ::MatrixDB] eq {}} {
    source [file join [file dirname [info script]] matrixdb.tcl]
}

oo::class create Reader {
    variable db options
    mixin DB FieldAccess Processor Validator

    constructor args {
        if no {
        # local options defaults (note expand = auto)
        array set options {
            -alternate 0
            -rows :
            -cols {}
            -separator \;
            -expand auto
            -fields {}
        }
        }

        # modify by global defaults (which override)
        if {[info exists ::options]} {
            array set options [array get ::options]
        }

        set o [OptionHandler new]
        $o option -alternate default 0 flag 1
        $o option -rows default :
        $o option -cols default {}
        $o option -separator default \;
        $o option -oseparator
        $o option -expand default auto
        $o option -fields default {}
        $o extract [my varname options] {*}$args
        set options(-expand) [my -expand-process $options(-expand)]
        $o destroy

        if no {
        oo::objdefine [self] forward rows $db rows
        oo::objdefine [self] forward import $db import
        oo::objdefine [self] forward expose $db expose
        }

        log addMessage {%s created} "Reader [self]"
    }

    destructor {
        log addMessage {%s destroyed} "Reader [self]"
    }

    method separator char {
        set options(-separator) $char
    }

    method fields fields {
        set options(-fields) $fields
    }

    if no {
    method fill args {
        # load a matrix database from a csv file
        catch {$m delete}
        set m [::struct::matrix]
        ::csv::select2matrix {*}$args $m
        set currentrow 0
        return
    }

    method read filename {
        try {
            open $filename
        } on ok chan {
            log addMessage {%s reading %s} "Reader [self]" $filename
            $db fill -sep $options(-separator) \
                -rows $options(-rows) \
                -cols $options(-cols) \
                -expand $options(-expand) \
                $chan
            log addMessage {%s %s rows, %s bytes read} "Reader [self]" [my rows] [file size $filename]
        } finally {
            catch {chan close $chan}
        }
    }
    }

    method -expand-process val {
        try {
            ::tcl::prefix match {auto empty none} $val
        } on error {} {
            return -code error [mc {illegal expand mode %s} $val]
        }
    }

}
