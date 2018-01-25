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

    method reset {} {
        global options
        set o [OptionHandler new]
        $o option -alternate default 0 flag 1
        $o option -rows default :
        $o option -cols default {}
        $o option -separator default \;
        $o option -oseparator
        $o option -expand default auto
        $o option -fields default {}

        lassign [$o extract ::options {*}$::argv] filename
        #error [list $::argv $filename]
        set ::options(-expand) [my -expand-process $::options(-expand)]

        lappend init {package require fileutil}
        lappend init [list array set ::options [array get ::options]]

        if {[info exists starkit] && $starkit::mode eq "unwrapped"} {
            my RunDebug {*}$init {vwait forever}
        } elseif {$filename eq {}} {
            ; # just loading
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

    method RunSafe args {
        if no {
        ::csvops::log init
        }
        lappend ::auto_path .
        # TODO kludgy add: topdir/lib
        if no {
        ::tcl::tm::path add [file join [file dirname [info script]] ..]
        }

        if no {
        set int [::safe::interpCreate]
        Script_PolicyInit $int
        foreach arg [lrange $args 0 end-1] {
            $int eval $arg
        }
        $int eval [list try [lindex $args end] on error msg {error [mc {Failure %s} $msg]}]
        ::safe::interpDelete $int
        } else {
        set int {}
        Script_PolicyInit $int
        #error [interp alias $int mc]
        foreach arg [lrange $args 0 end-1] {
            interp eval $int $arg
        }
        interp eval $int [list try [lindex $args end] on error msg {error [mc {Failure %s} $msg]}]
        }

        if no {
        if {[::csvops::log done]} exit
        } else {
        exit
        }
    }

    method RunDebug args {
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

csvops reset

