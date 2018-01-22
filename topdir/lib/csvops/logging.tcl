
namespace eval ::csvops::log {
    namespace export {[a-z]*}
    namespace ensemble create

    variable objects {}
    variable lastmsg {}
    variable running 0

    proc reset {} {
        variable t0 0
        variable labels [dict create]
        variable loglblc 0
        variable objects [dict create]
        variable messages {}
        variable lastmsg {}
    }

    proc setLabel {key args} {
        variable objects
        variable labels
        variable loglblc
        variable running

        if {!$running} return

        if {![dict exists $labels $key]} {
            set new 1
            set tag loglbl[incr loglblc]
            dict set labels $key $tag
        } else {
            set new 0
            set tag [dict get $labels $key]
        }
        set str [namespace eval [namespace parent] [list mc {*}$args]]
        dict set objects $key $str
        #after 0 [list after idle [list ::csvops::log::updateLabel $new $tag $key $str]]
    }

    proc addMessage args {
        variable lastmsg
        variable messages
        variable running

        if {!$running} return

        set lastmsg [namespace eval [namespace parent] [list mc {*}$args]]\n
        append messages $lastmsg
    }

    proc init {} {
        variable t0
        variable running

        try {
            toplevel .log
            grid [ttk::frame .log.obj] [text .log.msg] -sticky news
        } on error {} {
            return
        }

        set running 1
        set t0 [clock seconds]
        addMessage {starting at %s} [clock format $t0 -format %H:%M:%S]
    }

    proc done {} {
        variable running

        if {!$running} {return 1}

        addMessage {finished - time elapsed: %s} [timeElapsed]

        return 0
    }

    proc timeElapsed {} {
        variable t0
        variable running

        if {!$running} return

        set s [expr {[clock seconds] - $t0}]
        set m [expr {$s / 60}]
        set s [expr {$s % 60}]
        set h [expr {$m / 60}]
        set m [expr {$m % 60}]
        format %02d:%02d:%02d $h $m $s
    }

    proc isRunning {} {
        variable running

        return $running
    }

    proc U args {
        variable objects
        variable labels
        variable running

        if {!$running || ![winfo exists .log]} return

        dict for {key msg} $objects {
            set tag [dict get $labels $key]
            if {![winfo exists .log.obj.$tag]} {
                grid [ttk::label .log.obj.$tag -text "$key: $msg" -anchor w] -sticky w
            } else {
                .log.obj.$tag configure -text "$key: $msg"
            }
        }
        update
    }
    trace add variable objects write U

    proc updateLabel {new tag key str} {
        variable running

        if {!$running || ![winfo exists .log]} return

        if {$new} {
            grid [ttk::label .log.obj.$tag -text "$key: $str" -anchor w] -sticky w
        } else {
            .log.obj.$tag configure -text "$key: $str"
        }
    }

    proc V args {
        variable lastmsg
        variable running

        if {!$running || ![winfo exists .log]} return

        .log.msg insert end $lastmsg
        .log.msg see end-2c
        update
    }
    trace add variable lastmsg write V

    reset
}
