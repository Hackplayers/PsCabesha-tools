function Install-OpenSSH {param($zipfile,[switch]$nocolor)
$ErrorActionPreference = "SilentlyContinue"
$banner = @"
  _____           _        _ _                
 |_   _|         | |      | | |               
   | |  _ __  ___| |_ __ _| | |               
   | | | '_ \/ __| __/ _` | | |               
  _| |_| | | \__ \ || (_| | | |               
 |_____|_| |_|___/\__\__,_|_|_|_ _____ _    _ 
  / __ \                  / ____/ ____| |  | |
 | |  | |_ __   ___ _ __ | (___| (___ | |__| |
 | |  | | '_ \ / _ \ '_ \ \___ \\___ \|  __  |
 | |__| | |_) |  __/ | | |____) |___) | |  | |
  \____/| .__/ \___|_| |_|_____/_____/|_|  |_|
        | |                                   
        |_|                                   
                                                                                                                                                     
                            CyberVaca@Hackplayers
"@

$help = @"
.SYNOPSIS
    Install-OpenSSH
    PowerShell Function: Install-OpenSSH
    Author: Luis Vacas (CyberVaca)
    Required dependencies: None
    Optional dependencies: None
.DESCRIPTION
.EXAMPLE
    Install-OpenSSH -zipfile c:\programdata\OpenSSH-Win64.zip
    Description
    -----------
    Install OpenSSH
    https://github.com/PowerShell/Win32-OpenSSH/releases
"@

if ($zipfile -eq $null -or $zipfile -eq "") {$help} else {

function print-banner {param($banner)$Color = [char]27;$RED = "[31m";$GREEN = "92m";$END = "[0m";"$Color$RED" + $banner + "$Color$end"}
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {"You must have elevated privileges to use this module."} else {
if ($menu -ne $null -or $nocolor -eq $false ) {function informa {param ($msg) ;$Color = [char]27 ; $RED = "[31m" ;$GREEN = "[92m" ; $END = "[0m"; "$Color$GREEN[$color$RED+$Color$GREEN] " + $msg + "$color$END"} } else {function informa {param($msg) "[+] $msg"}}

print-banner $banner
$openSSHPath = "C:\Program Files\OpenSSH-Win64"
informa "Modifying environment variable path"
$addpath = (Get-ItemProperty "registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\").path + $openSSHPath
Set-ItemProperty "registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\" -Name Path -Value $addpath

informa "Decompressing OpenSSH"
Expand-Archive -LiteralPath $zipfile -DestinationPath "C:\Program files"
cd $openSSHPath
informa "Installing OpenSSH"
.\install-sshd.ps1
informa "Generating keys"
.\ssh-keygen.exe 
informa "Starting up services"
get-service ssh* | start-service  
informa "Creating rule for the firewall."
netsh.exe advfirewall firewall add rule name="SSH" dir=in action=allow protocol=TCP localport=22
informa "Installation has been completed successfully."

}}}
