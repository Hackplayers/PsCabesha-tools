function Impersonaliza-User {param ($usuario,$password,$dominio)
$help = @"
.SYNOPSIS
    Impersonaliza un ususario pasando las credenciales
    PowerShell Function: Impersonaliza-User
    Author: N/A
    Dependencias Requeridas: Ninguna
    Dependencias Opcionales: Ninguna
.DESCRIPTION
    Impersonaliza un usuario pasando credenciales.
.EXAMPLE
    Impersonaliza-User -usuario pepe -password secretisima -dominio dominio.es

    Descripcion
    -----------
    Esto nos cambiara de Token en la misma sesion en la que estes.
    Tu puedes comprobar esto ejecutando la variable de entorno [Environment]::username
   
"@
if ($usuario,$password,$dominio,$comando -eq $null)  {return "`n $help";break}

$code = @"
using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;
using Microsoft.Win32;
using System.IO;
using System.Security.Principal;
using System.Security.Permissions;
using Microsoft.Win32.SafeHandles;
using System.Runtime.ConstrainedExecution;
using System.Security;

namespace Impersonalizador

{

    public static class Funciones

    {

        const UInt32 INFINITE = 0xFFFFFFFF;
        const UInt32 WAIT_FAILED = 0xFFFFFFFF;
        [Flags]
        public enum LogonType

        {

            LOGON32_LOGON_INTERACTIVE = 2,
            LOGON32_LOGON_NETWORK = 3,
            LOGON32_LOGON_BATCH = 4,
            LOGON32_LOGON_SERVICE = 5,
            LOGON32_LOGON_UNLOCK = 7,
            LOGON32_LOGON_NETWORK_CLEARTEXT = 8,
            LOGON32_LOGON_NEW_CREDENTIALS = 9

        }

        [Flags]

        public enum LogonProvider
        {

            LOGON32_PROVIDER_DEFAULT = 0,
            LOGON32_PROVIDER_WINNT35,
            LOGON32_PROVIDER_WINNT40,
            LOGON32_PROVIDER_WINNT50
        }

	public enum TOKEN_TYPE
        {
            TokenPrimary = 1,
            TokenImpersonation = 2
        }

	public enum SECURITY_IMPERSONATION_LEVEL
        {
            SecurityAnonymous = 0,
            SecurityIdentification = 1,
            SecurityImpersonation = 2,
            SecurityDelegation = 3,
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct STARTUPINFO

        {

            public Int32 cb;
            public String lpReserved;
            public String lpDesktop;
            public String lpTitle;
            public Int32 dwX;
            public Int32 dwY;
            public Int32 dwXSize;
            public Int32 dwYSize;
            public Int32 dwXCountChars;
            public Int32 dwYCountChars;
            public Int32 dwFillAttribute;
            public Int32 dwFlags;
            public Int16 wShowWindow;
            public Int16 cbReserved2;
            public IntPtr lpReserved2;
            public IntPtr hStdInput;
            public IntPtr hStdOutput;
            public IntPtr hStdError;

        }

	[StructLayout(LayoutKind.Sequential)]
	public struct SECURITY_ATTRIBUTES
	{
    	    public int nLength;
    	    public IntPtr lpSecurityDescriptor;
            public int bInheritHandle;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct PROCESS_INFORMATION
        {

            public IntPtr hProcess;
            public IntPtr hThread;
            public Int32 dwProcessId;
            public Int32 dwThreadId;

        }

        [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern Boolean LogonUser
        (

            String lpszUserName,
            String lpszDomain,
            String lpszPassword,
            LogonType dwLogonType,
            LogonProvider dwLogonProvider,
            out IntPtr phToken

        );
		
        [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern Boolean CreateProcessWithLogonW
        (
            String lpszUsername,
            String lpszDomain,
            String lpszPassword,
            Int32 dwLogonFlags,
            String applicationName,
            String commandLine,
            Int32 creationFlags,
            IntPtr environment,
            String currentDirectory,
            ref STARTUPINFO sui,
            out PROCESS_INFORMATION processInfo
        );

	[DllImport("advapi32.dll", CharSet=CharSet.Auto, SetLastError=true)]
	public static extern Boolean DuplicateTokenEx
	(
            IntPtr hExistingToken,
            uint dwDesiredAccess,
            ref SECURITY_ATTRIBUTES lpTokenAttributes,
            SECURITY_IMPERSONATION_LEVEL ImpersonationLevel,
            TOKEN_TYPE TokenType,
            out IntPtr phNewToken 
        );

				
	[DllImport("advapi32.dll", SetLastError=true)]
	public extern static Boolean DuplicateToken
	(
		IntPtr ExistingTokenHandle,
		int SECURITY_IMPERSONATION_LEVEL,
		ref IntPtr DuplicateTokenHandle
	);

	[DllImport("advapi32.dll", SetLastError=true)]
	public extern static Boolean OpenProcessToken(IntPtr ProcessHandle, UInt32 DesiredAccess, out IntPtr TokenHandle);

	[DllImport("advapi32.dll", SetLastError=true)]
	public static extern bool SetThreadToken(IntPtr Thread, IntPtr Token);


        [DllImport("kernel32", SetLastError=true)]
        public static extern Boolean CloseHandle (IntPtr handle);

	[DllImport("advapi32.dll", SetLastError = true)]
        public static extern Boolean RevertToSelf();

        public static IntPtr ImpersonateUser(string strCommand, string strDomain, string strName, string strPassword)

        {

            PROCESS_INFORMATION processInfo = new PROCESS_INFORMATION();
            STARTUPINFO startInfo = new STARTUPINFO();

            bool bResult = false;

            try

            {

                startInfo.cb = Marshal.SizeOf(startInfo);

                bResult = CreateProcessWithLogonW(

                    strName,
                    strDomain,
                    strPassword,
                    0,
                    null,
                    strCommand,
                    0,
                    IntPtr.Zero,
                    null,
                    ref startInfo,
                    out processInfo

                );

                if (!bResult) { throw new Exception("CreateProcessWithLogonW error #" + Marshal.GetLastWin32Error().ToString());}


		IntPtr newToken = IntPtr.Zero;

		bResult = OpenProcessToken(processInfo.hProcess, 0x6, out newToken);
		if (!bResult) {
			throw new Exception("Failed to grab token!");
		}


		IntPtr dup = IntPtr.Zero;
		bResult = DuplicateToken(newToken, 2, ref dup); 

		if (!bResult)
		{
			throw new Exception("DuplicateToken error #" + Marshal.GetLastWin32Error().ToString());
		}
		
		return dup;
            }

            finally

            {

                // Close all handles

                CloseHandle(processInfo.hProcess);

                CloseHandle(processInfo.hThread);

            }

        }

    }

}
"@

Add-Type -TypeDefinition $code -Language CSHARP
########################## Llamada a la funcion ##############################
[IntPtr]::Zero
$proceso_a_impersonalizar = [Impersonalizador.Funciones]::ImpersonateUser("lsass.exe", $dominio, $usuario, $password) 
[Impersonalizador.Funciones]::SetThreadToken([IntPtr]::Zero, $proceso_a_impersonalizar);

}