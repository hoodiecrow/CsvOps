package require optionhandler

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
                set int [::safe::interpCreate]
                Script_PolicyInit $int
            } else {
                set int {}
            }
            try {
                foreach arg $preamble {
                    interp eval $int $arg
                }
                interp eval $int $script
            } on error msg {
                my Panic [mc {Failure %s} $msg]
            } finally {
                catch {::safe::interpDelete $int}
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

    method Panic msg {
        puts stderr $msg
        exit
    }

}
