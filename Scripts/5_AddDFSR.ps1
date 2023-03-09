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