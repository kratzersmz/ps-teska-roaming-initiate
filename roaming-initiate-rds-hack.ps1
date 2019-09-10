# very, very ... ugly hack for generating automatically roaming profiles for a bunch of users
# csv style: pw,username 
# destinationclient has to be productive OS, schueler-users + lehrer-users have to be in remotedesktop group on $destinationclient (could be scripted also
# mostly copied and pasted from sources on the internet

$destinationclient = "terra360-01"
$csvfile = "C:\Users\Administrator.PAEDML-LINUX\Desktop\BenutzerImport-4-9-19\alle.csv"


$usergroups = "schueler-schule","lehrer-schule"
$GroupName = "Remotedesktopbenutzer"
$DomainName = $env:USERDOMAIN
$ErrorActionPreference = "Stop"

 
Write-Host "Adding Users to Remotedesktopusers on $destinationclient" -ForegroundColor Green
Foreach($usergroup in $usergroups){
  Try{
   
   $Remotegroup = [ADSI]"WinNT://$destinationclient/$GroupName"
   Start-Sleep -Seconds 1
   $newgroup = [ADSI]"WinNT://$DomainName/$usergroup"
   Start-Sleep -seconds 1
   $Remotegroup.Add($newgroup.path)
  }
  Catch{
    $_.Exception.innerexception
    Continue
  }
}


Write-host "Importing $csvfile"
$passusers = Import-Csv -Path $csvfile

write-host "Logoff all users on $destinationclient . Lasts 40 secs"
try {
   query user /server:$destinationclient 2>&1 | select -skip 1 | foreach {
     logoff ($_ -split "\s+")[-6] /server:$destinationclient
   }
}
catch {}
start-sleep -seconds 10


ForEach ($passuser in $passusers) {
  $username = $($passuser.username)
  $pass = $($passuser.pw)
  write-host "Working on : $username"
  write-host "Hashing key/pw"
  cmdkey /generic:TERMSRV/$destinationclient /user:$username /pass:$pass
  write-host "Initiate Session to $destinationclient with user $username"
  write-host "Lasts about 5 mins.......please wait"
  mstsc /v:$destinationclient /h:800 /w:600
  Start-sleep -Seconds 300
  write-host "Now Logoff $username at $destinationclient"
  try {
    query user /server:$destinationclient 2>&1 | select -skip 1 | foreach {
     logoff ($_ -split "\s+")[-6] /server:$destinationclient
    }
  }
  catch {}
  start-sleep -Seconds 30
}

Write-Host "Removing Users to Remotedesktopusers on $destinationclient" -ForegroundColor Green
Foreach($usergroup in $usergroups){
  Try{
   
   $Remotegroup = [ADSI]"WinNT://$destinationclient/$GroupName"
   Start-Sleep -Seconds 1
   $newgroup = [ADSI]"WinNT://$DomainName/$usergroup"
   Start-Sleep -seconds 1
   $Remotegroup.remove($newgroup.path)
  }
  Catch{
    $_.Exception.innerexception
    Continue
  }
}
