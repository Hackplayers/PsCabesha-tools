function Crea-Credenciales {param ($user,$password)
$banner = @"
   ___
  / __|_ _ ___ __ _
 | (__| '_/ -_) _`` |
  \___|_| \___\__,_|            _      _
  / __|_ _ ___ __| |___ _ _  __(_)__ _| |___ ___
 | (__| '_/ -_) _`` / -_) ' \/ _| / _`` | / -_|_-<
  \___|_| \___\__,_\___|_||_\__|_\__,_|_\___/__/

"@
if ($user -eq $null -or $password -eq $null) {return "$banner`n`nEjemplo:`n`$credenciales = Crea-Credenciales -user cabesha -password de_nabo" ; break}
$securestring = ConvertTo-SecureString -String $password –asplaintext –force
$credenciales = New-Object System.Management.Automation.PSCredential $user,$securestring
return $credenciales

}