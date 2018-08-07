oo::object create csvops

oo::objdefine csvops {
    method reset {} {}

    method main args {
        set o [OptionHandler new]
        $o option -alternate default 0 flag 1
        $o option -separator default \;
        $o option -delimiter default \"
        $o option -oseparator
        $o option -safe flag 1 default 1
        $o option -convert-decimal default {read write}

        lassign [$o extract ::options {*}$args] filename
        $o defaultTo -oseparator -separator

        if {[info exists starkit::mode] && $starkit::mode eq "unwrapped"} {
            error deprecated
        } else {
            set int [my GetInterp $::options(-safe)]
            set preamble {
                {package require fileutil}
                {package require log}
            }
            set script [my GetScript $filename]
            my Run $int $preamble $script
        }
    }

    method Run {int preamble script} {
        try {
            foreach arg $preamble {
                interp eval $int $arg
            }
            interp eval $int $script
        } on error msg {
            my Panic [mc {Failure %s} $msg]
        } finally {
            if {$int ne {}} {
                ::safe::interpDelete $int
            }
        }
    }

    method GetInterp safe {
        if {$safe} {
            return [Script_PolicyInit [::safe::interpCreate]]
        } else {
            return {}
        }
    }

    method GetScript {filename {default {package require tkcon;tkcon show}}} {
        if {$filename eq {}} {
            return $default
        } else {
            return [my LoadScript $filename]
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
