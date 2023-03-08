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








#formatering av csv fil
$users = Import-Csv -Path 'C:\Users\anders.fjermedal\Documents\DCST1005\midlertidigBrukere.csv' -Delimiter ";"


function New-UserInfo {
    param (
        [Parameter(Mandatory=$true)][string] $fornavn,
        [Parameter(Mandatory=$true)][string] $etternavn
    )

    if ($fornavn -match $([char]32)) {
        $oppdelt = $fornavn.Split($([char]32))
        $fornavn = $oppdelt[0]

        for ( $index = 1 ; $index -lt $oppdelt.Length ; $index ++ ) {
            $fornavn += ".$($oppdelt[$index][0])"
        }
    }

    $UserPrincipalName = $("$($fornavn).$($etternavn)").ToLower()
    $UserPrincipalName = $UserPrincipalName.Replace('æ','e').Replace('ø','o').Replace('å','a').Replace('é','e')
    
    Return $UserPrincipalName
}



$csvfile = @()

$exportpath = 'C:\Users\anders.fjermedal\Documents\DCST1005\brukere.csv'

$samcheck = @()

$123 = Get-ADUser -Filter * -Properties SamAccountName | Select-Object -ExpandProperty SamAccountName   #tatt fra chatgpt
foreach ($user in $123){
    $samcheck += $user.Trim()
}


foreach ($user in $users) {
    $pass1 = (33..122-as [char[]] | Where-Object {($_ -ne 59)} )
    $password = -join (0..14 | ForEach-Object { $pass1 | Get-Random })
    
    $line = New-Object -TypeName psobject
    
    $sam = (New-UserInfo -Fornavn $user.GivenName -Etternavn $user.SurName)
    
        if ($sam.Length -gt 19) {
            $sam = $sam.Substring(0, 18) 
        }
        while ($sam -in $samcheck ) {
            $sam = "1" + $sam  
        } 
        if ($sam.Length -gt 19) {
            $sam = $sam.Substring(0, 18) 
        }
        
        $sam
        [string] $samaccountname = $sam
        $samcheck += $sam
        [string] $department = $user.Department
        [string] $searchdn = "OU=$department,OU=$security_users,*"
        $path = Get-ADOrganizationalUnit -Filter * | Where-Object {($_.name -eq $user.Department) -and ($_.DistinguishedName -like $searchdn)}
        

        
        Add-Member -InputObject $line -MemberType NoteProperty -Name GivenName -Value $user.GivenName `
          -PassThru | Add-Member -MemberType NoteProperty -Name SurName -Value $user.SurName `
          -PassThru | Add-Member -MemberType NoteProperty -Name UserPrincipalName -Value "$sam@core.sec" `
          -PassThru | Add-Member -MemberType NoteProperty -Name DisplayName -Value "$($user.GivenName) $($user.SurName)" `
          -PassThru | Add-Member -MemberType NoteProperty -Name department -Value $user.Department `
          -PassThru | Add-Member -MemberType NoteProperty -Name Password -Value $password `
          -PassThru | Add-Member -MemberType NoteProperty -Name Path -Value $path `
          -PassThru | Add-Member -MemberType NoteProperty -Name SamAccountName -Value $samaccountname
  
  
    $csvfile += $line
}

$csvfile | Export-Csv -Path $exportpath -Delimiter ";" -Usequotes Never -NoTypeInformation -Encoding 'UTF8'

#plassere brukere i OU

$users = Import-Csv -path 'C:\Users\anders.fjermedal\Documents\DCST1005\faktiskeBrukere.csv' -Delimiter ";"

foreach ($user in $users) {

            New-ADUser `
            -SamAccountName $user.samaccountname `
            -UserPrincipalName $user.UserPrincipalName `
            -Name $user.SamAccountName `
            -GivenName $user.GivenName `
            -Surname $user.SurName `
            -Enabled $True `
            -ChangePasswordAtLogon $false `
            -DisplayName $user.DisplayName`
            -Department $user.Department `
            -Path $user.path `
            -AccountPassword (ConvertTo-SecureString $user.Password -AsPlainText -Force)

        }
    


$ADUsers = @()

foreach ($department in $departments) {
    $ADUsers = Get-ADUser -Filter {Department -eq $department} -Properties Department

    foreach ($aduser in $ADUsers) {
        Add-ADPrincipalGroupMembership -Identity $aduser.SamAccountName -MemberOf "g_$department"
    }

}



