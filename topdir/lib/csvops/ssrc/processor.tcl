
#
# implement some high-level methods to be added to a Reader
#

if {[info commands ::Processor] ne {}} return

oo::class create Processor {
    variable db uniq

    method getRow {varName row} {
        # seek a db row and get fields
        $db seek $row

        upvar 1 $varName F
        array set F [my getFields]
    }

    method get script {
        # iterating over db rows, get fields and run script
        # script should not change number of rows
        # method claims the variable F in the enclosing scope
        upvar 1 F F
        $db iterate {
            log setLabel "Reader [self]" {processing line %s} [$db tell]
            array set F [my getFields]
            uplevel 1 $script
        }
    }

    method unique args {
        # determine if a set of args is unique
        set key [my getFields $args]
        if {![info exists uniq($key)]} {
            set uniq($key) 1
            return true
        } else {
            return false
        }
    }

    unexport unknown destroy

}
