
interp alias {} Source {} source -encoding utf-8

oo::object create conf
oo::objdefine conf {
    method msgcat args {
        if {[catch {package present msgcat}]} {
            interp alias {} mc {} format
        } else {
            if {[llength $args] < 1} {
                set args {. ..}
            }
            namespace import ::msgcat::mc
            ::msgcat::mclocale sv
            foreach dir $args {
                ::msgcat::mcload [file join $dir msgs]
            }
        }
    }
    method resource {name args} {
        if {[llength $args] < 1} {
            set args {~ ..}
        }
        catch {Source ~/.wishrc.tcl}
        foreach dir $args {
            catch {Source [file join $dir ${name}rc.tcl]}
        }
    }
    method definition name {
        catch {Source [file join .. ${name}.def]}
    }

}
