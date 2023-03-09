#Lag egen personlig bruker på VMene (Må kjøre koden på DC1). Bare bytt ut informasjonen med din egen
$Password = Read-Host -AsSecureString
New-ADUser `
-SamAccountName "tristan.askvik" `
-UserPrincipalName "tristan.askvik@core.sec" `
-Name "Tristan" `
-GivenName "Tristan Askvik" `
-Surname "Askvik" `
-Enabled $True `
-ChangePasswordAtLogon $false `
-DisplayName "Tristan Askvik" `
-AccountPassword $Password

Add-ADPrincipalGroupMembership -Identity 'tristan.askvik' -MemberOf "Administrators"
Add-ADPrincipalGroupMembership -Identity 'tristan.askvik' -MemberOf "Domain Admins"

#Run git kommandoene etter å ha logget inn på din egen bruker

#git config --global user.name "tris0000"
#git config --global user.email "tristan.askvik@gmail.com"

#remove-adUser tristan.askvik
#get-Aduser -filter * | ft