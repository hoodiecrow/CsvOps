package require tcltest

set testdir [file dirname [file normalize [info script]]]
set outfile [file join $testdir testreport.txt]
set errfile [file join $testdir testerrors.txt]
file delete -force $outfile $errfile

::tcltest::configure {*}$::argv

::tcltest::configure -testdir $testdir -outfile $outfile -errfile $errfile
::tcltest::configure -tmpdir [file join $testdir temp]

::tcltest::runAllTests