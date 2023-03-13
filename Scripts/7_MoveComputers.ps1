#Flytting av PCer ved hjelp av csv fil

$OUPCer = Import-Csv -Path 'C:\DCST1005\CSVFiler\MaskinerTilOU.csv' -Delimiter ";"
foreach ($OUPC in $OUPCer){
    $array = ($OUPC.PCer).Split(",")
    $OU = $OUPC.OUer

    foreach ($PC in $array){
        Get-ADComputer "$PC" | Move-ADObject -TargetPath "OU=$OU,OU=Security_Computers,DC=secure,DC=sec"
    }
}
