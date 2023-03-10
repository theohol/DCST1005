Import-Module GroupPolicy 

## Prohibit access to Control Panel and PC settings
$gpoName = 'No Control Panel and PC settings'
New-GPO -Name $gpoName -comment 'Prohibit access to Control Panel and PC settings'

Set-GPRegistryValue -Name $gpoName -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName Nocontrolpanel -Type DWord -Value 01

$OU = 'OU=accounting', 'OU=hr', 'OU=legal', 'OU=inactive'
foreach ($group in $OU) {
    Get-GPO -Name $GPOName | New-GPLink -Target "$group,OU=Security_Users,DC=secure,DC=sec"
}

## Prevent access to the command prompt
$gpoName = 'No command prompt'
New-GPO -Name $gpoName -comment 'Prevent access to the command prompt'

Set-GPRegistryValue -Name $gpoName -Key "HKCU\Software\Policies\Microsoft\Windows\System" -ValueName DisableCMD -Type DWord -Value 01

$OU = 'OU=accounting', 'OU=hr', 'OU=legal', 'OU=inactive'
foreach ($group in $OU) {
    Get-GPO -Name $GPOName | New-GPLink -Target "$group,OU=Security_Users,DC=secure,DC=sec"
}

## Prohibit users from installing unwanted software
$gpoName = 'No installing of unwanted software'

New-GPO -Name $gpoName -comment 'Prohibit users from installing unwanted software'
Set-GPRegistryValue -Name $gpoName -Key "HKLM\Software\Policies\Microsoft\Windows\Installer" -ValueName DisableUserInstalls -Type DWord -Value 01

$OU = 'OU=accounting', 'OU=hr', 'OU=legal', 'OU=inactive'
foreach ($group in $OU) {
    Get-GPO -Name $GPOName | New-GPLink -Target "$group,OU=Security_Users,DC=secure,DC=sec"
}

## Prevent auto-restarts with logged on users during scheduled update installations
$gpoName = 'No auto-restarts'
New-GPO -Name $gpoName -comment 'Prevent auto-restarts with logged on users during scheduled update installations'

Set-GPRegistryValue -Name $gpoName -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName NoAutoRebootWithLoggedOnUsers -Type Dword -Value 01

## Remote Desktop for test
$OU = 'Security_Users'
Get-GPO -Name $GPOName | New-GPLink -Target "OU=Security_Users,DC=secure,DC=sec"

$gpoName = 'Allow Remote Desktop for Legal'
New-GPO -Name $gpoName

Get-GPO -Name $GPOName | New-GPLink -Target "OU=legal,OU=Security_Computers,DC=secure,DC=sec"
