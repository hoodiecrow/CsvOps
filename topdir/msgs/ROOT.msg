set strings {
    {msgload %s %s} {%s message file(s) loaded. Message locale: %s.}
    {Failure %s}    {Execution failed: %s}
    {illegal expand mode %s}		{illegal expand mode %s, should be auto, empty, or none}
}

msgcat::mcflmset [subst $strings]
unset strings
