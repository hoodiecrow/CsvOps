package provide csvops 1.0

package require log

apply {args {
    set dir [file dirname [info script]]
    foreach arg $args {
        source -encoding utf-8 [file join $dir $arg]
    }
}} policy.tcl safe.tcl

::control::control assert enabled 1

oo::object create csvops

oo::objdefine csvops {
    variable int data

    method exec args {
        set o [OptionHandler new]
        $o option -alternate default 0 flag 1
        $o option -separator default \;
        $o option -delimiter default \"
        $o option -rows default :
        $o option -cols default {}
        $o option -oseparator
        $o option -expand default auto
        $o option -fields default {}
        $o option -safe flag 1 default 1
        $o option -convert-decimal default {read write}

        lassign [$o extract ::options {*}$args] filename
        $o expand -expand {auto empty none}
        $o defaultTo -oseparator -separator

        set preamble {}

        if {[info exists starkit::mode] && $starkit::mode eq "unwrapped"} {
            error deprecated
            my RunDebug {*}$preamble {vwait forever}
        } else {
            try { 
                if {$filename eq {}} {
                    format {package require tkcon ; tkcon show}
                } else {
                    # TODO see if exit can be dispensed with
                    cd [file dirname $filename]
                    format "%s;exit" [::fileutil::cat $filename]
                }
            } on ok script { 
                if {$::options(-safe)} {
                    lappend preamble {package require fileutil}
                    lappend preamble {package require log}
                    # Note: seems impossible to load modules through the tm
                    # mechanism in a safe base interpreter.
                    my RunSafe {*}$preamble $script
                } else {
                    my RunOpen {*}$preamble $script
                }
            } on error {msg opts} { 
                dict incr opts -level 1
                # TODO the error message does not change when recasting
                return -options $opts [mc {Load %s} $msg] 
            } 
        }
    }

    method RunOpen args {
        set dir [file join $::starkit::topdir lib csvops ssrc]
        foreach file [glob -nocomplain -directory $dir *.tcl] {
            uplevel #0 [list source -encoding utf-8 $file]
        }
        foreach arg [lrange $args 0 end-1] {
            uplevel #0 $arg
        }
        uplevel #0 [list try [lindex $args end] on error msg {error [mc {Failure %s} $msg]}]
    }

    method RunSafe args {
        set int [::safe::interpCreate]
        Script_PolicyInit $int
        foreach arg [lrange $args 0 end-1] {
            $int eval $arg
        }
        $int eval [list try [lindex $args end] on error msg {error [mc {Failure %s} $msg]}]
        ::safe::interpDelete $int
    }

}
