$users = Import-Csv -path 'C:\projects\dcst1005-demo\v23\users_final-v2.csv' -Delimiter "," #må endre til riktig path VIKTIGGGG 

foreach ($user in $users) {
    
        [string] $samaccountname = $user.Samname #må ha samme variabel som i formatert csv fil

        [string] $department = $user.Department
        [string] $searchdn = "OU=$department,OU=$security_users,*"
        
        
        if (!(Get-ADUser -Filter "sAMAccountName -eq '$($samaccountname)'")) {
            Write-Host "$samaccountname does not exist." -ForegroundColor Green
        
            Write-Host "Creating User ....%" -ForegroundColor Green
            Write-Host $user.DisplayName -ForegroundColor Green

            New-ADUser `
            -SamAccountName $samaccountname `
            -UserPrincipalName $user.UserPrincipalName `
            -Name $user.DisplayName `
            -GivenName $user.GivenName `
            -Surname $user.SurName `
            -Enabled $True `
            -ChangePasswordAtLogon $false `
            -DisplayName $user.DisplayName `
            -Department $user.Department `
            -Path $user.path ` #må være i csv fil
            -AccountPassword (convertto-securestring $user.Password -AsPlainText -Force)

        }
    }


$ADUsers = @()

foreach ($department in $departments) {
    $ADUsers = Get-ADUser -Filter {Department -eq $department} -Properties Department
    #Write-Host "$ADUsers som er funnet under $department"

    foreach ($aduser in $ADUsers) {
        Add-ADPrincipalGroupMembership -Identity $aduser.SamAccountName -MemberOf "g_$department"
    }

}
