package require starkit
starkit::startup

package require msgcat
package require fileutil

::tcl::tm::path add [file join $starkit::topdir lib]
set auto_path [linsert $auto_path 0 [file join $starkit::topdir lib]]
package require csvops
package require conf
conf msgcat
conf resource csvops
if no {
    # TODO make tkcon work again
    package require tkcon
}

csvops exec {*}$argv
