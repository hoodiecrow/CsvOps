package provide csvops 1.0

package require log
interp alias {} mc {} format

package require fileutil
package require control
package require msgcat
package require options

::control::control assert enabled 1

oo::object create csvops

oo::objdefine csvops {
    variable int data

    method reset {} {
        global options
        array set options {
            -alternate 0
            -rows :
            -cols {}
            -separator \;
            -expand auto
            -fields {}
        }

        options flags -alternate
        options extra -oseparator
        lassign [options handle $::argv] filename

        lappend init {package require fileutil}
        lappend init [list array set ::options [array get ::options]]

        if {$starkit::mode eq "unwrapped"} {
            my RunDebug {*}$init {vwait forever}
        } else {
            try {
                cd [file dirname $filename]
                ::fileutil::cat $filename
            } on ok script {
                my RunSafe {*}$init $script
            } on error {msg opts} {
                dict incr opts -level 1
                return -options $opts [mc {Load %s} $msg]
            }
        }
    }

    method runSafe args {
        log init
        lappend ::auto_path .
        set int [::safe::interpCreate]
        Script_PolicyInit $int

        foreach arg [lrange $args 0 end-1] {
            $int eval $arg
        }
        $int eval [list try [lindex $args end] on error msg {error [mc {Failure %s} $msg]}]

        ::safe::interpDelete $int
        if {[log done]} exit
    }

    method runDebug args {
        set int [interp create]
        Debug_PolicyInit $int

        foreach arg $args {
            $int eval $arg
        }

        interp delete $int
    }

    method -expand-process val {
        try {
            ::tcl::prefix match {auto empty none} $val
        } on error {} {
            return -code error [mc {illegal expand mode %s} $val]
        }
    }

}
