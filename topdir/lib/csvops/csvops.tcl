package provide csvops 1.0

package require log

# TODO move to main.tcl
package require conf
conf msgcat [namespace current]
conf resource csvops

apply {args {
    set dir [file dirname [info script]]
    foreach arg $args {
        source -encoding utf-8 [file join $dir $arg]
    }
}} policy.tcl safe.tcl

#interp alias {} mc {} format

package require fileutil
package require control
package require msgcat
package require optionhandler

::control::control assert enabled 1

oo::object create csvops

oo::objdefine csvops {
    variable int data

    method exec args {
        set o [OptionHandler new]
        $o option -alternate default 0 flag 1
        $o option -rows default :
        $o option -cols default {}
        $o option -separator default \;
        $o option -oseparator
        $o option -expand default auto
        $o option -fields default {}
        $o option -safe flag 1
        $o option -convert-decimal default {read write}

        lassign [$o extract ::options {*}$args] filename
        my option-expand ::options -expand auto empty none
        my option-fallback ::options -oseparator -separator

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

    method option-expand {varName opt args} {
        upvar 0 $varName var
        if no {
        set var($opt) [try {
            ::tcl::prefix match -message value $args $var($opt)
        } on error {} {
            return -code error [mc {illegal expand mode %s} $var($opt)]
        }]
        } else {
        set var($opt) [::tcl::prefix match -message value $args $var($opt)]
        }
    }

    method option-fallback {varName opt1 opt2} {
        upvar 0 $varName var
        if {![info exists var($opt1)]} {
            set var($opt1) $var($opt2)
        }
    }

}
