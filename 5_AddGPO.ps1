IKKE FERDIG:

##Group Policy Manager med bare PowerShell kommandoer
#region Find the registry.pol that the GPO stores registry keys in
New-GPO -Name 'Temp'
Get-GPO -Name 'Temp'

#Find the GUID
$gpoGuid = (Get-GPO -Name 'Temp').Id.ToString()

#Find the registry.pol file
Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select Name, Domain

$domainController = 'DC1'
$domainName = 'core.sec'
$registryPolPath = "\\$domainController\sysvol\$domainName\Policies\{$gpoGuid}\User"
Get-ChildItem -Path $registryPolPath

$regPolPath = Join-Path -Path $registryPolPath -ChildPath 'registry.pol'

##download and install a community module for reading the registry.pol file 
Install-Module -Name GPRegistryPolicy

Parse-PolFile -Path $regPolPath

##Capture the registry key path
$regKeyInfo = Parse-PolFile -Path $regPolPath

##Creating the GPO with the settings enabled
$gpoName = 'Hide Desktop Icons'
New-GPO -name $gpoName -Comment 'This GPO hides all desktop icons.'

$gpRegParams = @{
    Name = $gpoName
    Key = "HKCU\$($regKeyInfo.KeyName)"
    ValueName = $regKeyInfo.ValueName
    Type = $regKeyInfo.ValueType
    Value = $regKeyInfo.ValueData
}
Set-GPRegistryValue @gpRegParams

##Confirm the registry setting has been applied
Get-GPRegistryValue -Name 'Hide Desktop Icons' -Key "HKCU\$($regKeyInfo.KeyName)"

##Link the GPO to an OU

$ou = 'LearnIT_Users'
$domainDn = (Get-ADDomain).DistinguishedName

$ouDn = "OU=$ou,$domainDn"
New-GPLink -Name $gpoName -Target $ouDn -LinkEnabled 'Yes'

FORSLAG TIL GPO-er:
1. Prohibit access to the control panel
2. Prevent access to the command prompt
3. Deny all removable storage access
4. Prohibit users from installing unwanted software
5. Reinforce guest account status settings
6. Do not store LAN Manager hash values on next password changes
7. Prevent auto-restarts with logged on users during scheduled update installations
8. Monitor changes to your GPO settings
