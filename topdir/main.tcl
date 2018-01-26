package require starkit
starkit::startup

package require msgcat
package require sqlite3

::tcl::tm::path add [file join $starkit::topdir lib]
set auto_path [linsert $auto_path 0 [file join $starkit::topdir lib]]
package require csvops
package require conf
conf msgcat [namespace current]
conf resource csvops

csvops exec {*}$argv
