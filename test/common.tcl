set dir [file join [file dirname [info script]] .. topdir lib]
::tcl::tm::path add $dir
set auto_path [linsert $auto_path 0 $dir]

package require log
package require control
package require optionhandler
