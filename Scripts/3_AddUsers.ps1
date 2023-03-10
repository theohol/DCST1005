
#formatering av csv fil
$users = Import-Csv -Path 'C:\DCST1005\CSVFiler\midlertidigBrukere.csv' -Delimiter ";"


function New-UserInfo {
    param (
        [Parameter(Mandatory=$true)][string] $fornavn,
        [Parameter(Mandatory=$true)][string] $etternavn
    )
    #sjekker for mellomnavn
    if ($fornavn -match $([char]32)) {
        $oppdelt = $fornavn.Split($([char]32))
        $fornavn = $oppdelt[0]

        for ( $index = 1 ; $index -lt $oppdelt.Length ; $index ++ ) {
            $fornavn += ".$($oppdelt[$index][0])"
        }
    }
    #fjerner store boksatver særnorske tegn
    $UserPrincipalName = $("$($fornavn).$($etternavn)").ToLower()
    $UserPrincipalName = $UserPrincipalName.Replace('æ','e').Replace('ø','o').Replace('å','a').Replace('é','e')
    
    Return $UserPrincipalName
}



$csvfile = @()

$exportpath = 'C:\DCST1005\CSVFiler\brukere.csv'

#lager en tom liste som brukes til å sjekke om samaccauntname finnes fra før 
$samcheck = @()

#henter alle eksisterende samaccountname og legger de til i listen
$hentSAMname = Get-ADUser -Filter * -Properties SamAccountName | Select-Object -ExpandProperty SamAccountName   #tatt fra chatgpt
foreach ($user in $hentSAMname){
    $samcheck += $user.Trim()
}


foreach ($user in $users) {
    #tom liste som brukes til å telle hvor mange ganger en whileløkke kjører
    $whileteller= @()

    #lager passord uten semikolon 
    $pass1 = (33..122-as [char[]] | Where-Object {($_ -ne 59)} ) 
    $password = -join (0..14 | ForEach-Object { $pass1 | Get-Random })
    
    $path = Get-ADOrganizationalUnit -Filter * | Where-Object {($_.name -eq $user.Department) -and ($_.DistinguishedName -like $searchdn)}
    $line = New-Object -TypeName psobject
    $sam = (New-UserInfo -Fornavn $user.GivenName -Etternavn $user.SurName)
    
    
   
        #sjekker om samaccountname er for langt
        if ($sam.Length -gt 19) {
            $sam = $sam.Substring(0, 18) 
            $samcheck += $sam
        }
        #lager et midlertidig samaccountname som blir sjekket opp mot eksisterende samaccountname og legger til et tall helt til det ikke matcher et eksisterende navn
        $whileSAM = $sam
            while ($whileSAM -in $samcheck ) {
            
            $whileteller += 1 
            $whileSam2 = ($whileteller.Count | Out-String)
            $whileSAM2 = $whileSAM2.Trim()
            $whileSAM = $whileSAM2 + $sam
        }  
        $sam = $whileSAM
       
        #ny sjekk i tilfelle om tallet gjorde navnet for langt
        $samcheck += $sam
        if ($sam.Length -gt 19) {
            $sam = $sam.Substring(0, 18) 
        }
        #sjekker om siste character er et punktum og fjerner det, for et gyldig samaccountname kan ikke slutte på et punktum 
        $samcheck += $sam
        if( $sam.Substring($sam.Length - 1) -eq "."){
            $sam = $sam.Substring(0, $sam.Length - 1)
        }
        $sam
        $samcheck += $sam
       
       
        [string] $samaccountname = $sam        
        [string] $department = $user.Department
        [string] $searchdn = "OU=$department,OU=$security_users,*"
       
        
        Add-Member -InputObject $line -MemberType NoteProperty -Name GivenName -Value $user.GivenName `         #-PassThru er tatt fra chatgpt
          -PassThru | Add-Member -MemberType NoteProperty -Name SurName -Value $user.SurName `
          -PassThru | Add-Member -MemberType NoteProperty -Name UserPrincipalName -Value "$sam@secure.sec" `
          -PassThru | Add-Member -MemberType NoteProperty -Name DisplayName -Value "$($user.GivenName) $($user.SurName)" `
          -PassThru | Add-Member -MemberType NoteProperty -Name department -Value $user.Department `
          -PassThru | Add-Member -MemberType NoteProperty -Name Password -Value $password `
          -PassThru | Add-Member -MemberType NoteProperty -Name Path -Value $path `
          -PassThru | Add-Member -MemberType NoteProperty -Name SamAccountName -Value $samaccountname
  
  
    $csvfile += $line
}

$csvfile | Export-Csv -Path $exportpath -Delimiter ";" -Usequotes Never -NoTypeInformation -Encoding 'UTF8'

#lage brukere

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
    

#legger brukerene inn i gruppene de tilhører 
$ADUsers = @()
$departments = @('management','accounting','it','hr','legal','inactive')
foreach ($department in $departments) {
    $ADUsers = Get-ADUser -Filter {Department -eq $department} -Properties Department

    foreach ($aduser in $ADUsers) {
        Add-ADPrincipalGroupMembership -Identity $aduser.SamAccountName -MemberOf "g_$department"
    }

}
