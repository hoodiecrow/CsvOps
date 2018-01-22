#
# row indices: one of
#                 :M  "1 <= I <= M"
#                N:M  "N <= I <= M"
#                N:   "N <= I"
#                 :   "1 <= I"
# 
# being able to reorder rows would more or less require storing all lines in memory
#
# Used by select2matrix to determine which rows to use.

if {[info commands ::rowsCheck*] ne {}} return

proc rowsCheckMake indexExpr {
    # 'compile' an index expression to an expr expression

    # index expression = : means all rows
    if {$indexExpr eq ":"} {return {1 <= %1$d}}

    lassign [split $indexExpr :] N M

    if {$N eq {}} {
        format {1 <= %%1$d && %%1$d <= %d} $M
    } elseif {$M eq {}} {
        format {%d <= %%1$d} $N
    } else {
        format {%d <= %%1$d && %%1$d <= %d} $N $M
    }
}

proc rowsCheck {expr idx} {
    # test row index in the expr expression, returning a boolean
    # do not brace!
    expr [format $expr $idx]
}

