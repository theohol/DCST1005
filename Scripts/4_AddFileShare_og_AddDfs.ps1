Install-WindowsFeature -Name FS-DFS-Namespace,FS-DFS-Replication,RSAT-DFS-Mgmt-Con `
                        -ComputerName srv1 `
                        -IncludeManagementTools

Invoke-Command -ComputerName srv1 -ScriptBlock {New-Item -Path "c:\" -Name 'dfsroots' -ItemType "directory"}
Invoke-Command -ComputerName srv1 -ScriptBlock {New-Item -Path "c:\" -Name 'shares' -ItemType "directory"}

Enter-PSSession -ComputerName srv1

$folders = ('C:\dfsroots\files','C:\shares\accounting','C:\shares\hr','C:\shares\it','C:\shares\legal', 'C:\shares\inactive', 'C:\shares\management')
mkdir -Path $folders
$folders | ForEach-Object {$sharename = (Get-Item $_).name; New-SMBShare -Name $shareName -Path $_ -FullAccess Everyone}

# Kommandoen må kjøres på SRV1 med administratorbrukeren
New-DfsnRoot -TargetPath \\srv1\files -Path \\core.sec\files -Type DomainV2

# Oppretter mappene for avdelingene i \\bedriftsnavn.no\files
$folders | Where-Object {$_ -like "*shares*"} | 
            ForEach-Object {$name = (Get-Item $_).name; `
                $DfsPath = ('\\core.sec\files\' + $name); `
                $targetPath = ('\\srv1\' + $name);New-DfsnFolderTarget `
                -Path $dfsPath `
                -TargetPath $targetPath}

$departments = @('management', 'accounting', 'it', 'hr', 'legal', 'inactive')

# Legger til tilgangsgrupper for de forskjellige avdelingene

foreach ($department in $departments) {
    $path = Get-ADOrganizationalUnit -Filter * | 
            Where-Object {($_.name -eq "$department") `
            -and ($_.DistinguishedName -like "OU=$department,OU=Groups,*")}
    New-ADGroup -Name "l_fullaccess_$department-share" `
            -SamAccountName "l_fullaccess_$department-share" `
            -GroupCategory Security `
            -GroupScope Global `
            -DisplayName "l_fullaccess_$department-share" `
            -Path $path.DistinguishedName `
            -Description "$department FILE SHARE group"
}

# Gjør avdelingsgruppene medlemmer av tilgangsgruppene
foreach ($department in $departments) {
        Add-ADPrincipalGroupMembership -Identity "g_$department" -MemberOf "l_fullaccess_$department-share"
        }

# Aksesskontrol på delte mapper

# Utlister eksisterende tilgang

$folders = "\\core.sec\files\inactive"
Get-SmbShareAccess -name 'inactive'
Get-Acl -Path $folders
(Get-Acl -Path $folders).Access
(Get-Acl -Path $folders).Access | Format-Table -AutoSize
(Get-Acl -Path $folders).Access | Where-Object {$_.IsInherited -eq $true} | Format-Table -AutoSize
(Get-ACL -Path $folders).Access | Format-Table IdentityReference,FileSystemRights,AccessControlType,IsInherited,InheritanceFlags -AutoSize


$folders = ('C:\shares\inactive')

foreach ($department in $departments) {
    $acl = Get-Acl \\core\files\$department
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("l_fullaccess_$department-share","FullControl","Allow")
    $acl.SetAccessRule($AccessRule)
    $ACL | Set-Acl -Path "\\core\files\$department"
}

# Tilgangsregler vil bli arvet, men kan ikke endres eller slettes ($true, $true)

foreach ($department in $departments) {
        $ACL = Get-Acl -Path "\\core\files\$department"
        $ACL.SetAccessRuleProtection($true,$true)
        $ACL | Set-Acl -Path "\\core\files\$department"
}

# Builtin-users vil ikke ha tilgang til andre sharer enn sitt eget på filsystemnivå

foreach ($department in $departments) {
        $acl = Get-Acl "\\core\files\$department"
        $acl.Access | Where-Object {$_.IdentityReference -eq "BUILTIN\Users" } | ForEach-Object { $acl.RemoveAccessRuleSpecific($_) }
        Set-Acl "\\core\files\$department" $acl
        (Get-ACL -Path "\\core\files\$department").Access | 
                Format-Table IdentityReference,FileSystemRights,AccessControlType,IsInherited,InheritanceFlags -AutoSize
}

# Grupper (f.eks. l_remotedesktop_hr) med tilgang til RDP via GPO må være på plass for at klientene skal kunne logge seg inn må sine respektive maskiner. 
# En bruker i HR skal bare få tilgang til å logge seg inn på en maskin som ligger i HR-OU-en


# ----- DFS Replication ----- #

# Installeres på DC1
Install-WindowsFeature -name FS-DFS-Replication -IncludeManagementTools -ComputerName dc1
foreach ($department in $departments) {
    $folder = ("C:\Replica$department-SharedFolder")
    mkdir -path $folder
}


# Utføres på SRV1, ikke via Enter-PSSession
foreach ($department in $departments) {
    New-DfsReplicationGroup -GroupName "RepGrp$department-Share" 
    Add-DfsrMember -GroupName "RepGrp$department-Share" -ComputerName "srv1","dc1" 
    Add-DfsrConnection -GroupName "RepGrp$department-Share" `
                        -SourceComputerName "srv1" `
                        -DestinationComputerName "dc1" 

    New-DfsReplicatedFolder -GroupName "RepGrp$department-Share" -FolderName "Replica$department-SharedFolder" 

    Set-DfsrMembership -GroupName "RepGrp$department-Share" `
                        -FolderName "Replica$department-SharedFolder" `
                        -ContentPath "C:\shares\$department" `
                        -ComputerName "srv1" `
                        -PrimaryMember $True 

    Set-DfsrMembership -GroupName "RepGrp$department-Share" `
                        -FolderName "Replica$department-SharedFolder" `
                        -ContentPath "c:\Replica$department-SharedFolder" `
                        -ComputerName "dc1" 
}
Get-DfsrCloneState 

# gpupdate /force for å oppdatere policy-endringene