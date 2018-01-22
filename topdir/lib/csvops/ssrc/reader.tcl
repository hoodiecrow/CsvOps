
#
# read a csv file and maintain an internal matrix database
#

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
    mixin FieldAccess Processor Validator

    constructor args {
        # local options defaults (note expand = auto)
        array set options {
            -alternate 0
            -rows :
            -cols {}
            -separator \;
            -expand auto
            -fields {}
        }

        # modify by global defaults (which override)
        if {[info exists ::options]} {
            array set options [array get ::options]
        }

        while {[llength $args]} {
            switch [::tcl::prefix match -error {} {-rows -cols -separator -expand -fields -alternate --} [lindex $args 0]] {
                -rows       {set args [lassign $args - options(-rows)]}
                -cols       {set args [lassign $args - options(-cols)]}
                -separator  {set args [lassign $args - options(-separator)]}
                -expand     {
                    set args [lassign $args - options(-expand)]
                    switch [::tcl::prefix match -error {} {auto empty none} $options(-expand)] {
                        auto  {set options(-expand) auto}
                        empty {set options(-expand) empty}
                        none  {set options(-expand) none}
                        default {
                            return -code error [mc {illegal expand mode %s} $options(-expand)]
                        }
                    }
                }
                -fields     {set args [lassign $args - options(-fields)]}
                -alternate  {set options(-alternate) 1 ; set args [lrange $args 1 end]}
                --          {set args [lrange $args 1 end] ; break}
                default     {
                    if {[string match -* [lindex $args 0]]} {
                        error [mc {unknown option %s} [lindex $args 0]]
                    } else {
                        break
                    }
                }
            }
        }

        set db [MatrixDB new]

        oo::objdefine [self] forward rows $db rows
        oo::objdefine [self] forward import $db import
        oo::objdefine [self] forward expose $db expose

        log addMessage {%s created} "Reader [self]"
    }

    destructor {
        $db destroy

        log addMessage {%s destroyed} "Reader [self]"
    }

    method separator char {
        set options(-separator) $char
    }

    method fields fields {
        set options(-fields) $fields
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
