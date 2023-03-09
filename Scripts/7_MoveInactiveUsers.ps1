#Må være egen fil, kan ikke legges til de andre

$inactivityLimit = [DateTime]::Today.AddDays(-60)

$inactiveUsers = Get-ADDomaincontroller -Filter * | % {$DC = $_.name ; Get-ADuser `
    -Filter '(PasswordLastSet -lt $inactivityLimit) -and (LastLogon -lt $inactivityLimit)' `
    -properties * -Server $_.name | select `
        Name,`
        sAMAccountName,`
        @{n="LastLogon";e={[datetime]::FromFileTime($_.lastlogon)}},`
        PasswordLastSet}

foreach ($inactiveUser in $inactiveUsers){
    Get-ADUser $inactiveUser.sAMAccountName | Move-ADObject -TargetPath "OU=inactive,OU=Security_Groups,DC=core,DC=sec"
}
