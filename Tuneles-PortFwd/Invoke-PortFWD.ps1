function Invoke-PortFWD {param ($LHOST,$LPORT,$RHOST,$RPORT)
$help = @"
.SYNOPSIS
    Reenvio de puertos.
    PowerShell Function: Invoke-PortFWD
    Author: Basado en https://blog.brunogarcia.com/2012/10/simple-tcp-forwarder-in-c.html
    Dependencias Requeridas: Ninguna
    Dependencias Opcionales: Ninguna
.DESCRIPTION
    Impersonaliza un usuario pasando credenciales.
.EXAMPLE
    Invoke-PortFWD -Lhost 10.10.10.10 -Lport 443 -Rhost 10.10.10.14 -Rport 8080

    Descripcion
    -----------
    Se realizara un reenvio del puerto 443 de la ip 10.10.10.10 a la ip 10.10.10.14 puerto 8080.
   
"@
if ($LHOST,$LPORT,$RHOST,$RPORT -eq $null) {return "`n$help"; break}
$mycode = @"
//based on : https://blog.brunogarcia.com/2012/10/simple-tcp-forwarder-in-c.html
using System;
using System.Net;
using System.Net.Sockets;
 

    public class TcpForwarder
    {
        private readonly Socket _mainSocket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
        private const int MAX_BYTES=8192;
       public static void StartPortFwd(string localhost, string localport, string remotehost, string remoteport)
		{
			new TcpForwarder().Start(
			     new IPEndPoint(IPAddress.Parse(localhost), int.Parse(localport)),
                 new IPEndPoint(IPAddress.Parse(remotehost), int.Parse(remoteport))
                 );
        }
        public void Start(IPEndPoint local, IPEndPoint remote)
        {
            _mainSocket.Bind(local);
            _mainSocket.Listen(10);
 
            while (true)
            {
                var source = _mainSocket.Accept();
                var destination = new TcpForwarder();
                var state = new State(source, destination._mainSocket);
                destination.Connect(remote, source);
                source.BeginReceive(state.Buffer, 0, state.Buffer.Length, 0, OnDataReceive, state);
            }
        }
 
        private void Connect(EndPoint remoteEndpoint, Socket destination)
        {
            var state = new State(_mainSocket, destination);
            _mainSocket.Connect(remoteEndpoint);
            _mainSocket.BeginReceive(state.Buffer, 0, state.Buffer.Length, SocketFlags.None, OnDataReceive, state);
        }
 
        private static void OnDataReceive(IAsyncResult result)
        {
            var state = (State)result.AsyncState;
            try
            {
                var bytesRead = state.SourceSocket.EndReceive(result);
                if (bytesRead > 0)
                {
                    state.DestinationSocket.Send(state.Buffer, bytesRead, SocketFlags.None);
                    state.SourceSocket.BeginReceive(state.Buffer, 0, state.Buffer.Length, 0, OnDataReceive, state);
                }
            }
            catch
            {
                state.DestinationSocket.Close();
                state.SourceSocket.Close();
            }
        }
 
        private class State
        {
            public Socket SourceSocket { get; private set; }
            public Socket DestinationSocket { get; private set; }
            public byte[] Buffer { get; private set; }
 
            public State(Socket source, Socket destination)
            {
                SourceSocket = source;
                DestinationSocket = destination;
                Buffer = new byte[MAX_BYTES];
            }
        }
    }

"@
Add-Type -TypeDefinition $mycode
start-job -ArgumentList $LHOST,$LPORT,$RHOST,$RPORT,$mycode -ScriptBlock {param ($LHOST,$LPORT,$RHOST,$RPORT,$mycode) Add-Type -TypeDefinition $mycode ;[TcpForwarder]::StartPortFwd("$LHOST","$LPORT","$RHOST","$RPORT")
Write-Host $LHOST,$LPORT,$RHOST,$RPORT,$mycode

}  }