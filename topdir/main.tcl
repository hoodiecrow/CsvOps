package require starkit
starkit::startup

::tcl::tm::path add [file join $starkit::topdir lib]

set project csvops
package require $project
package require conf
conf msgcat
conf resource $project
if no {
    # TODO make tkcon work again
    package require tkcon
}

$project reset
$project main {*}$argv
