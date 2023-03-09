

#formatering av csv fil
$users = Import-Csv -Path 'C:\DCST1005\CSVFiler\midlertidigBrukere.csv' -Delimiter ";"


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

$exportpath = 'C:\DCST1005\CSVFiler\brukere.csv'

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
        $samcheck += $sam
        while ($sam -in $samcheck ) {
            $sam = "1" + $sam  
        } 
        $samcheck += $sam
        if ($sam.Length -gt 19) {
            $sam = $sam.Substring(0, 18) 
        }
        $samcheck += $sam
        if( $sam.Substring($sam.Length - 1) -eq "."){
            $sam = $sam.Substring(0, $sam.Length - 1)
        }
        $sam
        $samcheck += $sam
        [string] $samaccountname = $sam
        
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

$users = Import-Csv -path 'C:\DCST1005\CSVFiler\brukere.csv' -Delimiter ";"

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
$departments = @('management','accounting','it','hr','legal','inactive')
foreach ($department in $departments) {
    $ADUsers = Get-ADUser -Filter {Department -eq $department} -Properties Department

    foreach ($aduser in $ADUsers) {
        Add-ADPrincipalGroupMembership -Identity $aduser.SamAccountName -MemberOf "g_$department"
    }

}

