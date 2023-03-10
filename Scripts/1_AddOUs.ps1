$security_users = "Security_Users"
$security_groups = "Security_Groups"
$security_computers = "Security_Computers"

$topOUs = @($security_users,$security_groups,$security_computers )
$departments = @('management','accounting','it','hr','legal','inactive')

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
