package require tcltest

set STARKITS H:/starkits
if {![file exists $STARKITS]} {set STARKITS [file normalize [file join ~ starkits]]}
#file copy ../topdir ../csvops.vfs
exec tclsh [file join $STARKITS sdx.kit] wrap [file join $STARKITS csvops.kit] -vfs ../topdir

set testdir [file dirname [file normalize [info script]]]
set outfile [file join $testdir testreport.txt]
set errfile [file join $testdir testerrors.txt]
file delete -force $outfile $errfile

::tcltest::configure {*}$::argv

::tcltest::configure -testdir $testdir -outfile $outfile -errfile $errfile
::tcltest::configure -tmpdir [file join $testdir temp]
::tcltest::configure -loadfile [file join $testdir common.tcl]

::tcltest::runAllTests
