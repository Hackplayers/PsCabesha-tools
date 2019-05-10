function Execute-Remoting {param ($credenciales,$Funcion,$Comando,$computername)
$banner = @"
  ___                 _           ___               _   _
 | __|_ _____ __ _  _| |_ ___ ___| _ \___ _ __  ___| |_(_)_ _  __ _
 | _|\ \ / -_) _| || |  _/ -_)___|   / -_) '  \/ _ \  _| | ' \/ _`` |
 |___/_\_\___\__|\_,_|\__\___|   |_|_\___|_|_|_\___/\__|_|_||_\__, |
                                                              |___/
"@
$help = @"
$banner `n`nEjemplo:`nExecute-Function-As -credenciales `$creds -comando whoami`nExecute-Function-As -credenciales `$creds -comando Invoke-Function -function Invoke-Function
"@
if ($credenciales -eq $null -or $Comando -eq $null -or $Comando -eq $null) {return $help; break}

if ($Funcion -ne $null){
$nombre_funcion = $funcion
$funcion = "`${function:REMPLAZA}" -replace "REMPLAZA",$funcion
$funcion = "function $nombre_funcion {" + ($funcion | IEX) + "}"
$sesion = New-PSSession -ComputerName $computername -Credential $credenciales  -EnableNetworkAccess
Invoke-Command -Session $sesion  -ArgumentList $Funcion,$Comando -ScriptBlock {param ($Funcion,$Comando) IEX $Funcion}
Invoke-Command -Session $sesion  -ArgumentList $Comando -ScriptBlock { param ($comando) IEX "$comando"}
}
else {
$sesion = New-PSSession -ComputerName $computername -Credential $credenciales  -EnableNetworkAccess
Invoke-Command -Session $sesion  -ArgumentList $Comando -ScriptBlock { param ($comando) IEX "$comando"}
}
}