
#
# extensions for safe
#

namespace eval ::safe {

    # code scavenged from the 'safe' package; I've left logging in

    proc AliasOpen {slave filename {access r}} {
        # safe open. access is limited to [rw][+b]

        # get the real path from the virtual one.
        set realfile [try {
            TranslatePath $slave $filename
        } on error msg {
            Log $slave $msg
            return -code error [mc {permission denied}]
        }]
        
        if {[string match r* $access]} {
            # don't open for reading unless name passes this test
            try {
                CheckFileName $slave $realfile
            } on error msg {
                Log $slave "$realfile: $msg"
                return -code error [mc $msg]
            }
        } else {
            # don't open for writing unless in current directory
            set path [file normalize [file dirname $realfile]]
            set curr [file normalize .]
            if {$path ne $curr} {
                Log $slave "\"$filename\": not in current directory"
                return -code error [mc {permission denied}]
            }
        }

        try {
            open $realfile $access
        } on ok chan {
            interp transfer {} $chan $slave
            set chan
        } on error {} {
            Log $slave "\"$filename\": can't open"
            return -code error [mc {permission denied}]
        }
    }

    proc AliasFileSubcommand2 {slave subcmd path} {
        # for subcommands that need a real path
        set realpath [try  {
            TranslatePath $slave $path
        } on error msg {
             Log $slave $msg
            return -code error [mc {permission denied}]
        }]
        interp invokehidden $slave tcl:file:$subcmd $realpath
    }
}
