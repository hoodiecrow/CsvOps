package provide csvops 1.0

package require log

apply {args {
    set dir [file dirname [info script]]
    foreach arg $args {
        source -encoding utf-8 [file join $dir $arg]
    }
}} policy.tcl safe.tcl db.tcl

oo::object create csvops

oo::objdefine csvops {
    method exec args {
        set o [OptionHandler new]
        $o option -alternate default 0 flag 1
        $o option -separator default \;
        $o option -delimiter default \"
        $o option -oseparator
        $o option -safe flag 1 default 1
        $o option -convert-decimal default {read write}

        lassign [$o extract ::options {*}$args] filename
        $o defaultTo -oseparator -separator

        log::logMsg [array get ::options]
        set preamble {}

        if {[info exists starkit::mode] && $starkit::mode eq "unwrapped"} {
            error deprecated
        } else {
            if {$filename eq {}} {
                set script {package require tkcon ; tkcon show}
            } else {
                set script [my LoadScript $filename]
            }
            if {$::options(-safe)} {
                lappend preamble {package require fileutil}
                lappend preamble {package require log}
                # Note: seems impossible to load modules through the tm
                # mechanism in a safe base interpreter.
                my RunSafe {*}$preamble $script
            } else {
                my RunOpen {*}$preamble $script
            }
        }
    }

    method LoadScript filename {
        # TODO see if exit can be dispensed with
        try {
            cd [file dirname $filename]
            format "%s;exit" [::fileutil::cat $filename]
        } on error msg {
            my Panic [mc {Load %s} $msg]
        }
    }

    method RunOpen args {
        foreach arg $args {
            uplevel #0 $arg
        }
    }

    method RunSafe args {
        set int [::safe::interpCreate]
        Script_PolicyInit $int
        foreach arg [lrange $args 0 end-1] {
            $int eval $arg
        }
        try {
            $int eval [lindex $args end] 
        } on error msg {
            my Panic [mc {Failure %s} $msg]
        } finally {
            ::safe::interpDelete $int
        }
    }

    method Panic msg {
        puts stderr $msg
        exit
    }

}
