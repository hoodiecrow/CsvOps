
if {[info commands ::Validator] ne {}} return

oo::class create Validator {
    variable db

    method validate {clauses output} {
        # validates cell values by one of the validator subcommands
        ::fileutil::writeFile $output {}
        my get {
            foreach {var subcmd validation} $clauses {
                set val [set $var]
                set fail [validator $subcmd $val $validation]
                if {$fail ne {}} {
                    ::fileutil::appendToFile $output [mc {Row %s: value %s (column %s) %s%s} [$db tell] $val $var $fail \n]
                }
            }
        }
    }

    unexport unknown destroy
}

namespace eval ::validator {
    namespace export {[a-z]*}
    namespace ensemble create -unknown [namespace current]::Unknown

    proc one-of {val validation} {
        if {$val ni $validation} {
            return [mc {isn't one of %s} $validation]
        }
    }
    proc not-one-of {val validation} {
        if {$val in $validation} {
            return [mc {is one of %s} $validation]
        }
    }
    proc matches {val validation} {
        if {![regexp -- $validation $val]} {
            return [mc {does not match %s} $validation]
        }
    }
    proc matches-or-is-empty {val validation} {
        if {!([regexp -- $validation $val] || $val eq {})} {
            return [mc {does not match %s and is not equal to ""} $validation]
        }
    }
    proc belongs-to {val validation} {
        if {[::csvops::convert-$validation $val] eq {}} {
            return [mc {does not belong to %s} $validation]
        }
    }

    proc Unknown {cmd op args} {
        return -code error [mc {illegal validation operation %s} $op]
    }
}
