package require starkit
starkit::startup

::tcl::tm::path add [file join $starkit::topdir lib]
set auto_path [linsert $auto_path 0 [file join $starkit::topdir lib]]
package require csvops

if no {
package require conf
conf msgcat [namespace current]
conf resource csvops
}

package require tkcon

tkcon show
