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

# Oppretter mappene i \\core\files
$folders | Where-Object {$_ -like "*shares*"} | 
            ForEach-Object {$name = (Get-Item $_).name; `
                $DfsPath = ('\\core.sec\files\' + $name); `
                $targetPath = ('\\srv1\' + $name);New-DfsnFolderTarget `
                -Path $dfsPath `
                -TargetPath $targetPath}


$security_users = "Security_Users"
$security_groups = "Security_Groups"
$security_computers = "Security_Computers"

$topOUs = @($security_users,$security_groups,$security_computers )
$departments = @('it','hr','legal', 'management')

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



