
function Execute-Function-AS {param($credenciales,$comando,$funcion)
$banner = @"
  ___                 _
 | __|_ _____ __ _  _| |_ ___
 | _|\ \ / -_) _| || |  _/ -_)
 |___/_\_\___\__|\_,_|\__\___|       _   ___
 | __|  _ _ _  __| |_(_)___ _ _     /_\ / __|
 | _| || | ' \/ _|  _| / _ \ ' \   / _ \\__ \
 |_| \_,_|_||_\__|\__|_\___/_||_| /_/ \_\___/

"@
$help = @"
$banner`n`nEjemplo:`nExecute-Function-As -credenciales `$creds -comando whoami`nExecute-Function-As -credenciales `$creds -comando Invoke-funcion -function Invoke-PowerView
"@
if ($credenciales -eq $null -or $comando -eq $null) {return $help; break}

if ($funcion -eq $null) {Start-Job -ArgumentList $comando -ScriptBlock {param($comando) ; Invoke-Expression $comando} -Credential $credenciales | Wait-Job | Receive-Job}

if ($funcion -ne $null) {
$nombre_funcion = $funcion
$funcion = "`${function:REMPLAZA}" -replace "REMPLAZA",$funcion
$funcion = "function $nombre_funcion {" + ($funcion | IEX) + "}"
Start-Job -ArgumentList $comando,$funcion -ScriptBlock {param($comando,$funcion) ; IEX $funcion; $comando } -Credential $credenciales | Wait-Job | Receive-Job}

}