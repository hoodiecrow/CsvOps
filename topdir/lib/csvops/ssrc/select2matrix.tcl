package require csv

if {[info commands ::csv::select2matrix] ne {}} return

if {[info commands ::colsCheck*] eq {}} {
    source [file join [file dirname [info script]] colschecker.tcl]
}

if {[info commands ::rowsCheck*] eq {}} {
    source [file join [file dirname [info script]] rowschecker.tcl]
}

# based on code from the 'csv' module
proc ::csv::select2matrix args {
    # See 'split2matrix' for the available expansion modes.

    # Argument syntax:
    #
    # select2matrix ?option...? chan m
    #
    # Options:
    #
    #                 values                                 default
    # -alternate      (flag)                                 left out
    # -rows list      one of: :M|N:M|N:; : = all             :
    # -cols list      sequence of: :N|N|N:; empty list = all (empty list)
    # -separator char character                              ;
    # -expand value   none|auto|empty                        auto

    array set options {-alternate 0 -rows : -cols {} -separator \; -expand auto}
    while {[llength $args]} {
        switch [::tcl::prefix match -error {} {-rows -cols -separator -expand -alternate --} [lindex $args 0]] {
            -rows       {set args [lassign $args - options(-rows)]}
            -cols       {set args [lassign $args - options(-cols)]}
            -separator  {set args [lassign $args - options(-separator)]}
            -expand   {
                set args [lassign $args - options(-expand)]
                switch [::tcl::prefix match -error {} {auto empty none} $options(-expand)] {
                    auto  {set options(-expand) auto}
                    empty {set options(-expand) empty}
                    none  {set options(-expand) none}
                    default {
                        return -code error "illegal expand mode $options(-expand), should be auto, empty, or none"
                    }
                }
            }
            -alternate {set options(-alternate) 1 ; set args [lrange $args 1 end]}
            --         {set args [lrange $args 1 end] ; break}
            default    {
                if {[string match -* [lindex $args 0]]} {
                    error "unknown option [lindex $args 0]"
                } else {
                    break
                }
            }
        }
    }
    lassign $args chan m

    # index expressions are "tested" by their respective compiler functions
    if {[string length $options(-separator)] != 1} {
        return -code error "illegal separator character \"$options(-separator)\""
    }
    if {[llength [file channels $chan]] == 0} {
        return -code error "not an open channel"
    }

    set rowsCheckExpr [rowsCheckMake $options(-rows)]
    set colsCheckExpr [colsCheckMake $options(-cols)]
    set data {}

    while {[chan gets $chan line] >= 0} {

        # Why skip empty lines? They may be in data. Except if the
        # buffer is empty, i.e. we are between records.
        if {$line eq {} && $data eq {}} continue

        append data $line
        if {![iscomplete $data]} {
            # Odd number of quotes - must have embedded newline
            append data \n
            continue
        }

        if {[rowsCheck $rowsCheckExpr [incr rownum]]} {
            set line [Split $options(-alternate) $data $options(-separator)]

            set csv [colsCheck $colsCheckExpr $line]
            switch -exact -- $options(-expand) {
                none {}
                empty {
                    if {[$m columns] == 0} {
                        $m add columns [llength $csv]
                    }
                }
                auto {
                    extendRow $m [llength $csv]
                }
            }
            $m add row $csv
        }
        set data {}
    }
    return
}
