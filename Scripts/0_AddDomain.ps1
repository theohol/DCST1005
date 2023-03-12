# Kjøres fra PowerShell på dc1
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine

# Installere choco
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco upgrade chocolatey
# Installere programvare med Choco
choco install -y powershell-core
choco install -y git.install
choco install -y vscode

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

# Kjøres på hver maskin som skal legges i domenet
# IP-adressen tilhører dc1-maskinen
ipconfig
Get-NetAdapter | Set-DnsClientServerAddress -ServerAddresses 192.168.111.194

$cred = Get-Credential -UserName 'secure\Administrator' -Message 'Cred'
Add-Computer -Credential $cred -DomainName secure.sec -PassThru -Verbose
Restart-Computer

# Koble seg til andre maskiner over PowerShell
# Hvis maskinen ikke tillater autentisering for oppkoblingen, kjør følgende i powershell:
# winrm set winrm/config/service/auth '@{Kerberos="true"}' 
# for å liste ut: winrm get winrm/config/service/auth
# Hvis maskina ikke har aktivert PSRemote:
# Enable-PSRemoting -Force

Get-ADComputer -Filter * | Select-Object DNSHostName
