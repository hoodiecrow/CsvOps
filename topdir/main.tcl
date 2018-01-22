package require starkit
starkit::startup

::tcl::tm::path add [file join $starkit::topdir lib]
package require csvops
package require conf

conf msgcat
conf resource csvops

csvops reset

package require tkcon

tkcon show
