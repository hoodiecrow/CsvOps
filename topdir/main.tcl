package require starkit
starkit::startup

package require msgcat
package require sqlite3
package require fileutil
package require control

::tcl::tm::path add [file join $starkit::topdir lib]
set auto_path [linsert $auto_path 0 [file join $starkit::topdir lib]]
package require optionhandler
package require csvops
package require conf
conf msgcat
conf resource csvops

csvops exec {*}$argv
