# 
# edit this file in csvops.vfs only
#
# Used by select2matrix to determine which columns to use.

if {[info commands ::colsCheck*] ne {}} return

proc colsCheckMake indexExpr {
    # 'compile' an index expression to a list of index pairs

    # index expression = empty list means all columns in order
    if {$indexExpr eq {}} {return {{0 end}}}

    lmap item $indexExpr {
        if {[regexp -- {^:(\d+)$} $item -> n]} {
            # index expression item = :N -> index pair (0, N)
            list 0 $n
        } elseif {[regexp -- {^(\d+):$} $item -> n]} {
            # index expression item = N: -> index pair (N, end)
            list $n end
        } elseif {[regexp -- {^\d+$} $item]} {
            # index expression item = N -> index pair (N, N)
            list $item $item
        }
    }
}

proc colsCheck {pairs data} {
    # produce a flat list of field values according to the given list of index pairs
    set res [list]
    foreach pair $pairs {
        lappend res {*}[lrange $data {*}$pair]
    }
    set res
}


