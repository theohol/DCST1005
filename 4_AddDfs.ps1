Install-WindowsFeature -Name FS-DFS-Namespace,FS-DFS-Replication,RSAT-DFS-Mgmt-Con `
                        -ComputerName srv1 `
                        -IncludeManagementTools

Invoke-Command -ComputerName srv1 -ScriptBlock {New-Item -Path "c:\" -Name 'dfsroots' -ItemType "directory"}
Invoke-Command -ComputerName srv1 -ScriptBlock {New-Item -Path "c:\" -Name 'shares' -ItemType "directory"}

Enter-PSSession -ComputerName srv1

$folders = ('C:\dfsroots\files','C:\shares\accounting','C:\shares\hr','C:\shares\it','C:\shares\legal', 'C:\shares\inactive')

$folders | ForEach-Object {$sharename = (Get-Item $_).name; New-SMBShare -Name $shareName -Path $_ -FullAccess Everyone}


