set strings {
    {Failure %s}                {Bearbetningen misslyckades: %s}
    {Load %s}                   {Skriptet kunde inte laddas: %s}
    {no such file or directory} {::safe::CheckFileName: hittar inte filen eller katalogen}
    {not readable}              {::safe::CheckFileName: ej läsbar}
    {permission denied}         {operationen tillåts inte}
    {wrong#number "%s"}         {fel antal kommandoradsparametrar, ska vara: %s}
}

msgcat::mcflmset [subst $strings]
unset strings
