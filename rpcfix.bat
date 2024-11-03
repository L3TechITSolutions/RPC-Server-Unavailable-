@echo off
echo Starting RPC issue resolution...

REM Step 1: Configure Network Discovery and File & Printer Sharing
echo Configuring network discovery and file & printer sharing...

REM Private network: Network discovery ON, File & printer sharing ON
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes

REM Domain network: Network discovery OFF, File & printer sharing ON
netsh advfirewall firewall set rule group="Network Discovery" new enable=No profile=domain
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes profile=domain

echo Step 1 complete: Network settings configured.

REM Step 2: Configure Local Group Policy for Remote Administration Exception
echo Configuring local group policy for allowing inbound remote administration exception...

REM Add the registry key to enable the inbound remote administration exception in Windows Firewall
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile" /v AllowRemoteAdmin /t REG_DWORD /d 1 /f

echo Step 2 complete: Local group policy for remote administration exception enabled.

REM Step 3: Configure Firewall Rules
echo Configuring firewall rules...

REM Firewall rule for SMB (139/TCP)
netsh advfirewall firewall add rule name="Remote Shadowing - SMB (139/TCP)" dir=in action=allow protocol=TCP localport=139

REM Firewall rule for SMB (445/TCP)
netsh advfirewall firewall add rule name="Remote Shadowing - SMB (445/TCP)" dir=in action=allow protocol=TCP localport=445

REM Firewall rule for RPC Dynamic Ports (49152-65535/TCP)
netsh advfirewall firewall add rule name="Remote Shadowing - RPC Dynamic Ports (49152-65535/TCP)" dir=in action=allow protocol=TCP localport=49152-65535

echo Step 3 complete: Firewall rules configured.

REM Step 4: Start and set services to automatic
echo Starting services and setting to automatic...

sc config RasMan start= auto
net start RasMan

sc config SessionEnv start= auto
net start SessionEnv

sc config TermService start= auto
net start TermService

sc config UmRdpService start= auto
net start UmRdpService

sc config RpcSs start= auto
net start RpcSs

sc config RpcLocator start= auto
net start RpcLocator

sc config RpcEptMapper start= auto
net start RpcEptMapper

echo Step 4 complete: Services started and set to automatic.

REM Step 5: Enable File and Printer Sharing for Microsoft Networks using PowerShell
echo Enabling File and Printer Sharing for Microsoft Networks...

REM Check if "File and Printer Sharing for Microsoft Networks" is installed and enabled
powershell -Command "Get-NetAdapterBinding -ComponentID ms_server | ForEach-Object { if (-not $_.Enabled) { Enable-NetAdapterBinding -Name $_.Name -ComponentID ms_server } }"

REM Install "File and Printer Sharing for Microsoft Networks" if not found
powershell -Command "
$adapter = Get-NetAdapter | Where-Object { -not (Get-NetAdapterBinding -Name $_.Name -ComponentID ms_server).Enabled }
if ($adapter) {
    $adapter | ForEach-Object { Install-WindowsFeature -Name FS-SMB1 -IncludeManagementTools }
    $adapter | ForEach-Object { Enable-NetAdapterBinding -Name $_.Name -ComponentID ms_server }
}
"

echo Step 5 complete: File and Printer Sharing for Microsoft Networks enabled.

REM Step 6: Output final message
echo RPC issue has been resolved, credit goes to SK.
pause
