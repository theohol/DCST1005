#Må være egen fil, kan ikke legges til de andre

$inactivityLimit = [DateTime]::Today.AddDays(-60)

$inactiveUsers = Get-ADDomaincontroller -Filter * | ForEach-Object {Get-ADuser `
    -Filter {(PasswordLastSet -lt $inactivityLimit) -and (LastLogon -lt $inactivityLimit)} `
    -properties * -Server $_.name | Select-Object `
        Name,`
        sAMAccountName,`
        @{n="LastLogon";e={[datetime]::FromFileTime($_.lastlogon)}},`
        PasswordLastSet,`
        DistinguishedName} #Modifisert kode fra https://serverfault.com/a/1084200 for bedre lastLogin
        #Modfisert for bedre lesbarhet og effektivitet etter at video ble spilt inn. (Fjernet $DC og gjorde mer leslig)   

$csvfil = @(Import-Csv -path 'C:\DCST1005\CSVFiler\InactiveBrukere.csv' -Delimiter ";")

foreach ($inactiveUser in $inactiveUsers){
    if ($inactiveUser.DistinguishedName -ne "CN=$($inactiveUser.name),CN=Users,DC=secure,DC=sec" `
        -and $inactiveUser.DistinguishedName -ne "CN=$($inactiveUser.name),OU=inactive,OU=Security_Users,DC=secure,DC=sec") {
        
        #Genererer nytt passord til inaktive brukere    
        $InactivityPass1 = (33..122-as [char[]] | Where-Object {($_ -ne 59)} )
        $InactivityPassword = -join (0..14 | ForEach-Object { $InactivityPass1 | Get-Random })
        Get-ADUser $inactiveUser.sAMAccountName | Set-ADAccountPassword -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "$InactivityPassword" -Force)

        #Formaterer csv fil og oppdaterer csvfil arrayet
        $line = New-Object -TypeName psobject
        Add-Member -InputObject $line -MemberType NoteProperty -Name Name -Value $inactiveUser.name `
            -PassThru | Add-Member -MemberType NoteProperty -Name PreviousDepartment -Value $inactiveUser.DistinguishedName `
            -PassThru | Add-Member -MemberType NoteProperty -Name Password -Value $InactivityPassword
        $csvfil += $line 

        #Flytter inaktive brukere til OU inactive
        Get-ADUser $inactiveUser.sAMAccountName | Move-ADObject -TargetPath "OU=inactive,OU=Security_Users,DC=secure,DC=sec"
    }
}

$ExportPathInactive = 'C:\DCST1005\CSVFiler\InactiveBrukere.csv'
$csvfil | Export-Csv -Path $ExportPathInactive -Delimiter ";" -NoTypeInformation -Encoding 'UTF8'

