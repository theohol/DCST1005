$departments = @('management','accounting','it','hr','legal','inactive')
$security_groups = "Security_Groups"

foreach ($department in $departments) {
    $path = Get-ADOrganizationalUnit -Filter * | 
            Where-Object {($_.name -eq "$department") `
            -and ($_.DistinguishedName -like "OU=$department,OU=$security_groups,*")}
    New-ADGroup -Name "g_$department" `
            -SamAccountName "g_$department" `
            -GroupCategory Security `
            -GroupScope Global `
            -DisplayName "g_$department" `
            -Path $path.DistinguishedName `
            -Description "$department group"
}

#Lager en global gruppe
New-ADGroup -name "g_all_employee" `
            -SamAccountName "g_all_employee" `
            -GroupCategory Security `
            -GroupScope Global `
            -DisplayName "g_all_employee" `
            -path "OU=Security_Groups,DC=secure,DC=sec" `
            -Description "all employee"
            
            
            
#Starter en schedule task som sjekker om brukere har vært inactive (kjører hver dag kl 04:00)

$ScheduleTime = New-ScheduledTaskTrigger -Daily -At 04:00
$ScheduleUser = "secure\Administrator"
$SchedulePasswordUser = "DCST1005GruppeOppgave!" #Ikke ideelt å ha passord i klartekst men for å gjøre det lettere i fremvisningen
#så skriver vi bare passordet direkte inn. Best ville vært å bare skreve passordet inn når programmet kjører.
$SchedulePS = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "C:\DCST1005\Scripts\8_MoveInactiveUsers.ps1"
Register-ScheduledTask -TaskName "RemoveInactiveUsers" -Trigger $ScheduleTime -User $ScheduleUser -Action $SchedulePS -Password $SchedulePasswordUser            
