#Må være egen fil, kan ikke legges til de andre

$inactivityLimit = [DateTime]::Today.AddDays(-60)

$inactiveUsers = Get-ADDomaincontroller -Filter * | % {$DC = $_.name ; Get-ADuser `
    -Filter '(PasswordLastSet -lt $inactivityLimit) -and (LastLogon -lt $inactivityLimit)' `
    -properties * -Server $_.name | select `
        Name,`
        sAMAccountName,`
        @{n="LastLogon";e={[datetime]::FromFileTime($_.lastlogon)}},`
        PasswordLastSet,`
        DistinguishedName}

$csvfil = @(Import-Csv -path 'C:\DCST1005\CSVFiler\InactiveBrukere.csv' -Delimiter ";")

foreach ($inactiveUser in $inactiveUsers){
    if ($inactiveUser.DistinguishedName -ne "CN=$($inactiveUser.name),CN=Users,DC=core,DC=sec" -and $inactiveUser.DistinguishedName -ne "CN=$($inactiveUser.name),OU=inactive,OU=Security_Users,DC=core,DC=sec") {
        $InactivityPass1 = (33..122-as [char[]] | Where-Object {($_ -ne 59)} )
        $InactivityPassword = -join (0..14 | ForEach-Object { $InactivityPass1 | Get-Random })
        $line = New-Object -TypeName psobject
        Get-ADUser $inactiveUser.sAMAccountName | Set-ADAccountPassword -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "$InactivityPassword" -Force)
        Add-Member -InputObject $line -MemberType NoteProperty -Name Name -Value $inactiveUser.name `
            -PassThru | Add-Member -MemberType NoteProperty -Name PreviousDepartment -Value $inactiveUser.DistinguishedName `
            -PassThru | Add-Member -MemberType NoteProperty -Name Password -Value $InactivityPassword
        Get-ADUser $inactiveUser.sAMAccountName | Move-ADObject -TargetPath "OU=inactive,OU=Security_Users,DC=core,DC=sec"
        $csvfil += $line
    }
}

$ExportPathInactive = 'C:\DCST1005\CSVFiler\InactiveBrukere.csv'
$csvfil | Export-Csv -Path $ExportPathInactive -Delimiter ";" -NoTypeInformation -Encoding 'UTF8'

