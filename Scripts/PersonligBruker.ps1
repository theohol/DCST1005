#Lag egen personlig bruker på VMene (Må kjøre koden på DC1). Bare bytt ut informasjonen med din egen
$Password = Read-Host -AsSecureString
New-ADUser `
-SamAccountName "navn.etternavn" `
-UserPrincipalName "navn.etternavn@secure.sec" `
-Name "navn etternavn" `
-GivenName "navn" `
-Surname "etternavn" `
-Enabled $True `
-ChangePasswordAtLogon $false `
-DisplayName "navn etternavn" `
-AccountPassword $Password

Add-ADPrincipalGroupMembership -Identity 'tristan.askvik' -MemberOf "Administrators"
Add-ADPrincipalGroupMembership -Identity 'tristan.askvik' -MemberOf "Domain Admins"

#Run git kommandoene etter å ha logget inn på din egen bruker

#git config --global user.name "NAVN"
#git config --global user.email "EPOST@EPOST.EPOST"

#remove-adUser navn.etternavn
#get-Aduser -filter * | ft
