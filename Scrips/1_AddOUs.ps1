$security_users = "Security_Users"
$security_groups = "Security_Groups"
$security_computers = "Security_Computers"

$topOUs = @($security_users,$security_groups,$security_computers )
$departments = @('accounting','it','hr','legal','inactive')

#Lager OU-ene for hver avdeling i bedrifften vår
foreach ($ou in $topOUs) {
    New-ADOrganizationalUnit $ou -Description "Top OU for Secure Security" -ProtectedFromAccidentalDeletion:$false #Sett true før livemiljø
    $topOU = Get-ADOrganizationalUnit -Filter * | Where-Object {$_.name -eq "$ou"}
        foreach ($department in $departments) {
            New-ADOrganizationalUnit $department `
                        -Path $topOU.DistinguishedName `
                        -Description "Deparment OU for $department in topOU $topOU" `
                        -ProtectedFromAccidentalDeletion:$false #True før livemiljø
        }
}

# ----- Gruppe Struktur ----- #

foreach ($department in $departments) {
    $path = Get-ADOrganizationalUnit -Filter * | 
            Where-Object {($_.name -eq "$department") `
            -and ($_.DistinguishedName -like "OU=$department,OU=$security_groups,*")}
    New-ADGroup -Name "g_$department" `
            -SamAccountName "g_$department" `
            -GroupCategory Security `
            -GroupScope Global `
            -DisplayName "g_$department" `
            -Path $path.DistinguishedName `
            -Description "$department group"
}

#Lager en global gruppe
New-ADGroup -name "g_all_employee" `
            -SamAccountName "g_all_employee" `
            -GroupCategory Security `
            -GroupScope Global `
            -DisplayName "g_all_employee" `
            -path "OU=Security_Groups,DC=core,DC=sec" `
            -Description "all employee"
