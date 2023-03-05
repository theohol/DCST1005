#Flytting av PCer ved hjelp av UI. Tror ikkje vi kommer til å bruke denne men kan være kjekt å ha

#$ADComps= Get-ADComputer -Filter * -SearchBase "CN=Computers,DC=core,dc=sec"| Select-Object -Property Name |sort -Property name | Out-GridView -PassThru –title “Select Computers to Move”| Select -ExpandProperty Name
#$ADOUs= Get-ADOrganizationalUnit -Filter * | Select-Object -Property DistinguishedName | Out-GridView -PassThru –title “Select Target OU”| Select-Object -ExpandProperty DistinguishedName
#Foreach($ou in $ADOUs){
#   Foreach($comp in $ADComps){
#       get-adcomputer $comp |Move-ADObject -TargetPath "$ou" -Verbose -PassThru 
#   }
#}


#Flytting av PCer ved hjelp av csv fil

$OUPCer = Import-Csv -Path '/Users/trygve/Documents/GitHub/DCST1005/test.csv' -Delimiter ";"
foreach ($OUPC in $OUPCer){
    $array = ($OUPC.PCer).Split(",")
    $OU = $OUPC.OUer

    foreach ($PC in $array){
        Get-ADComputer "$PC" | Move-ADObject -TargetPath "OU=Computer,OU=$OU,DC=core,DC=sec"
    }
}