
set ::DIRS(starkit) [file normalize ~/starkits]
set ::DIRS(base)    [pwd]
set ::project       [file tail $::DIRS(base)]
set ::DIRS(test)    [file join $::DIRS(base) test]
set ::DIRS(lib)     [file join $::DIRS(base) topdir lib]

switch [lindex $argv 0] {
    starkit {
        exec tclsh [file join $::DIRS(starkit) sdx.kit] wrap [file join $::DIRS(starkit) $::project.kit] -vfs ./topdir
    }
    test {
        ::tcl::tm::path add $::DIRS(lib)
        set ::auto_path [linsert $::auto_path 0 $DIRS(lib)]
        cd $::DIRS(test)
        package require tcltest

        set outfile [file join $::DIRS(test) testreport.txt]
        set errfile [file join $::DIRS(test) testerrors.txt]
        file delete -force $outfile $errfile

        set ::argv [lassign $::argv -]
        lappend ::argv -testdir $::DIRS(test)
        lappend ::argv -outfile $outfile
        lappend ::argv -errfile $errfile
        lappend ::argv -tmpdir [file join $::DIRS(test) temp]
        lappend ::argv -load [subst -noc {
            ::tcl::tm::path add $::DIRS(lib)
            set ::auto_path [linsert \$::auto_path 0 $DIRS(lib)]
            package require $::project
            package require log
        }]

        uplevel #0 {
            ::tcltest::configure {*}$::argv
            ::tcltest::runAllTests
        }
    }
    default {
        ;
    }
}
