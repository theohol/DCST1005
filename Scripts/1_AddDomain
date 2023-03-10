# Kjøres fra PowerShell på dc1
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine

# Installere choco
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco upgrade chocolatey
# Installere programvare med Choco
choco install -y powershell-core
choco install -y git.install
choco install -y vscode

# Fra Git CMD
git config --global user.name "NAVN"
git config --global user.email "EPOST@EPOST.EPOST"

# Installasjon av AD DS
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools
$Password = Read-Host -Prompt 'Enter Password' -AsSecureString
Set-LocalUser -Password $Password Administrator
$Params = @{
    DomainMode = 'WinThreshold'
    DomainName = 'secure.sec'
    DomainNetbiosName = 'secure'
    ForestMode = 'WinThreshold'
    InstallDns = $true
    NoRebootOnCompletion = $true
    SafeModeAdministratorPassword = $Password
    Force = $true
}
Install-ADDSForest @Params
Restart-Computer
# Log in as core\Administrator with password from above, test our domain
Get-ADRootDSE
<# The Get-ADRootDSE cmdlet gets the object that represents the root of the directory information tree of a directory server. This tree provides information about the configuration and capabilities of the directory server, such as the distinguished name for the configuration container, the current time on the directory server, and the functional levels of the directory server and the domain.
#>
Get-ADForest
<#
#>
Get-ADDomain
<#
#>
# Any computers joined the domain?
Get-ADComputer -Filter * | Select-Object DNSHostName
