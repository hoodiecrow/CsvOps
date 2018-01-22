set strings {
    {%s %s rows, %s bytes read}		{%s %s rader, %s bytear inlästa}
    {%s created}			{%s skapad}
    {%s destroyed}			{%s avslutad}
    {%s reading %s}			{%s läser in "%s"}
    {%s writing %s}			{%s skriver filen "%s"}
    {%s writing file %s (%s)}		{%s skriver filen "%s" med formatet %s}
    {Failure %s}    			{Bearbetningen misslyckades: %s}
    {Load %s}				{Skriptet kunde inte laddas: %s}
    {Row %s: value %s (column %s) %s%s}	{Rad %s: värde %s (fält %s) %s%s}
    {column header %s missing}		{kolumnrubrik "%s" saknas}
    {database is empty}			{databasen är tom}
    {database not opened}		{databasen är inte öppnad}
    {dbjoin: unknown mode}		{okänd metod för dbjoin}
    {dbjoin: wrong # of arguments}	{fel antal argument till dbjoin}
    {does not belong to %s}		{tillhör inte "%s"}
    {does not match %s and is not equal to ""}	{matchar inte "%s" och är inte lika med ""}
    {does not match %s}			{matchar inte "%s"}
    {finished - time elapsed: %s}	{Färdig - åtgången tid: %s}
    {illegal expand mode %s}		{ogiltig expansionstyp "%s", bör vara auto, empty eller none}
    {illegal validation operation %s}	{ogiltig valideringsoperation "%s"}
    {invalid date format -from}		{felaktigt datumformat för -from}
    {invalid field name %s}		{ogiltigt fältnamn "%s"}
    {invalid row number %s}		{ogiltigt radnummer %s}
    {is one of %s}			{är en av {%s}}
    {isn't one of %s}			{är inte en av {%s}}
    {no fields defined}			{inga fält definierade}
    {no such file or directory}         {::safe::CheckFileName: hittar inte filen eller katalogen}
    {not readable}			{::safe::CheckFileName: ej läsbar}
    {output created by csvops}		{Utmatning skapad av csvops}
    {permission denied}			{operationen tillåts inte}
    {processing line %s}		{bearbetar rad %s}
    {row header %s missing}		{radrubrik "%s" saknas}
    {starting at %s}			{Startar vid %s}
    {storing line %s}			{lagrar rad %s}
    {table doesn't exist}		{tabellen finns inte}
    {table without columns %s}		{tabellen "%s" har inga kolumner}
    {too many fields}			{för många fält}
    {unknown field name %s}		{kan inte lagra okänt fält "%s"}
    {unknown format %s}			{okänt filformat "%s"}
    {unknown option %s}			{okänt tillval "%s"}
}

msgcat::mcflmset [subst $strings]
unset strings
