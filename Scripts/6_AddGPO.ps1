Import-Module GroupPolicy 

# Må bli enige om hvilke departments som skal ha hvilke policies.

## Eksempel domene
$ou = 'LearnIT_Users'
$domainDn = (Get-ADDomain).DistinguishedName
$ouDn = "OU=$ou,$domainDn"

## KAN VÆRE 'Set-GPregistryValue'-DELEN MÅ FJERNES ##

## Prohibit access to Control Panel and PC settings
$gpoName = 'No Control Panel and PC settings'
New-GPO -Name $gpoName -comment 'Prohibit access to Control Panel and PC settings'

Set-GPRegistryValue -Name $gpoName -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName Nocontrolpanel -Type DWord -Value 01

New-GPLink -Name $gpoName -Target $ouDn -LinkEnabled 'Yes'

## Prevent access to the command prompt
$gpoName = 'No command prompt'
New-GPO -Name $gpoName -comment 'Prevent access to the command prompt'

Set-GPRegistryValue -Name $gpoName -Key "HKCU\Software\Policies\Microsoft\Windows\System" -ValueName DisableCMD -Type DWord -Value 01

New-GPLink -Name $gpoName -Target $ouDn -LinkEnabled 'Yes'

## Deny all removable storage access
$gpoName = 'Deny all removable storage access'
New-GPO -Name $gpoName -comment 'Deny all removable storage access'

Set-GPRegistryValue -Name $gpoName -Key "HKCU\Software\Policies\Microsoft\Windows\RemovableStorageDevices" -ValueName Deny_All -Type DWord -Value 01

New-GPLink -Name $gpoName -Target $ouDn -LinkEnabled 'Yes'

## Prohibit users from installing unwanted software
$gpoName = 'No installing of unwanted software'

New-GPO -Name $gpoName -comment 'Prohibit users from installing unwanted software'
Set-GPRegistryValue -Name $gpoName -Key "HKLM\Software\Policies\Microsoft\Windows\Installer" -ValueName DisableUserInstalls -Type DWord -Value 01

New-GPLink -Name $gpoName -Target $ouDn -LinkEnabled 'Yes'

## Prevent auto-restarts with logged on users during scheduled update installations
$gpoName = 'No auto-restarts'
New-GPO -Name $gpoName -comment 'Prevent auto-restarts with logged on users during scheduled update installations'

Set-GPRegistryValue -Name $gpoName -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName NoAutoRebootWithLoggedOnUsers -Type Dword -Value 01

New-GPLink -Name $gpoName -Target $ouDn -LinkEnabled 'Yes'




