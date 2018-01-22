package require tdom

oo::class create PresentationWriter {
    variable options

    constructor args {
        # local options defaults
        array set options {
            -separator \;
        }

        # modify by global defaults (which override)
        if {[info exists ::options]} {
            array set options [array get ::options]
        }

        while {[llength $args]} {
            switch [::tcl::prefix match -error {} -oseparator [lindex $args 0]] {
                -oseparator {set args [lassign $args - options(-oseparator)]}
                default break
            }
        }
        log addMessage {%s created} "PresentationWriter [self]"
    }

    destructor {
        log addMessage {%s destroyed} "PresentationWriter [self]"
    }

    method oseparator char {
        set options(-oseparator) $char
    }

    method write args {
        set args [lassign $args filename]
        set format [string map {. {}} [file extension $filename]]
        log addMessage {%s writing file %s (%s)} "PresentationWriter [self]" $filename [string toupper $format]
        switch -nocase $format {
            csv {my WriteCSV $filename {*}$args}
            html {my WriteHTML $filename {*}$args}
            default {
                return -code error [mc {unknown format %s} $format]
            }
        }
    }

    method WriteCSV {filename args} {
        if {[info exists options(-oseparator)]} {
            set oseparator $options(-oseparator)
        } else {
            set oseparator $options(-separator)
        }
        ::fileutil::writeFile $filename {}
        foreach tbl $args {
            set csv [::csv::joinlist [$tbl asLoL] $oseparator]
            ::fileutil::appendToFile $filename $csv
        }
    }

    method WriteHTML {filename args} {
        set doc [dom createDocument html]
        set root [$doc documentElement]
        $root appendFromList [format {
            head {} {
                {link {rel stylesheet type text/css href csvops.css} {}}
                {title {} {{#text {%s}}}}
            }
        } [mc {output created by csvops}]]
        $root appendFromList {body {} {}}
        set body [$root lastChild]
        foreach tbl $args {
            $body appendChild [$tbl toDOM $doc]
        }
        ::fileutil::writeFile $filename [$doc asHTML]
        $doc delete
    }
}
