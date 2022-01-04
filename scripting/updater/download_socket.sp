
/* Extension Helper - Socket */

#define MAX_REDIRECTS 5

static DataPackPos DLPack_Header;
static DataPackPos DLPack_Redirects;
static DataPackPos DLPack_File;
static DataPackPos DLPack_Request;

void Download_Socket(const char[] url, const char[] dest)	{
	char sURL[MAX_URL_LENGTH];
	PrefixURL(sURL, sizeof(sURL), url);
	
	if(strncmp(sURL, "https://", 8) == 0)	{
		char sError[256];
		FormatEx(sError, sizeof(sError), "Socket does not support HTTPs (URL: %s).", sURL);
		DownloadEnded(false, sError);
		return;
	}
	
	File hFile = OpenFile(dest, "wb");
	
	if(hFile == null)	{
		char sError[256];
		FormatEx(sError, sizeof(sError), "Error writing to file: %s", dest);
		DownloadEnded(false, sError);
		return;
	}
	
	// Format HTTP GET method.
	char hostname[64], location[128], filename[64], sRequest[MAX_URL_LENGTH+128];
	ParseURL(sURL, hostname, sizeof(hostname), location, sizeof(location), filename, sizeof(filename));
	FormatEx(sRequest, sizeof(sRequest), "GET %s/%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\nPragma: no-cache\r\nCache-Control: no-cache\r\n\r\n", location, filename, hostname);
	
	DataPack hDLPack = new DataPack();
	
	hDLPack.Position = DLPack_Header;
	hDLPack.WriteCell(0);
	
	DLPack_Redirects = hDLPack.Position;
	hDLPack.WriteCell(0);
	
	DLPack_File = hDLPack.Position;
	hDLPack.WriteCell(hFile);
	
	DLPack_Request = hDLPack.Position;
	hDLPack.WriteString(sRequest);
	
	Socket socket = new Socket(SOCKET_TCP, OnSocketError);
	socket.SetArg(hDLPack);
	socket.SetOption(ConcatenateCallbacks, 4096);
	socket.Connect(OnSocketConnected, OnSocketReceive, OnSocketDisconnected, hostname, 80);
}

void OnSocketConnected(Socket socket, DataPack hDLPack)	{
	char sRequest[MAX_URL_LENGTH+128];
	hDLPack.Position = DLPack_Request;
	hDLPack.ReadString(sRequest, sizeof(sRequest));
	socket.Send(sRequest);
}

void OnSocketReceive(Socket socket, char[] data, const int size, DataPack hDLPack)	{
	int idx = 0;
	
	// Check if the HTTP header has already been parsed.
	hDLPack.Position = DLPack_Header;
	bool bParsedHeader = hDLPack.ReadCell();
	int iRedirects = hDLPack.ReadCell();
	
	if(!bParsedHeader)	{
		// Parse header data.
		switch((idx = StrContains(data, "\r\n\r\n")) == -1)	{
			case true:	idx = 0;
			case false:	idx += 4;
		}
	
		if(strncmp(data, "HTTP/", 5) == 0)	{
			// Check for location header.
			int idx2 = StrContains(data, "\nLocation: ", false);
			
			if(idx2 > -1 && (idx2 < idx || !idx))	{
				switch(++iRedirects > MAX_REDIRECTS)	{
					case	true:	{
						CloseSocketHandles(socket, hDLPack);
						DownloadEnded(false, "Socket error: too many redirects.");
						return;
					}
					case	false:	{
						hDLPack.Position = DLPack_Redirects;
						hDLPack.WriteCell(iRedirects);
					}
				}
			
				// skip to url
				idx2 += 11;
				
				char sURL[MAX_URL_LENGTH];
				strcopy(sURL, (FindCharInString(data[idx2], '\r') + 1), data[idx2]);
				
				PrefixURL(sURL, sizeof(sURL), sURL);
				
#if defined DEBUG
				Updater_DebugLog("  [ ]  Redirected: %s", sURL);
#endif
				
				if(strncmp(sURL, "https://", 8) == 0)	{
					CloseSocketHandles(socket, hDLPack);
					
					char sError[256];
					FormatEx(sError, sizeof(sError), "Socket does not support HTTPs (URL: %s).", sURL);
					DownloadEnded(false, sError);
					return;
				}
				
				char hostname[64], location[128], filename[64], sRequest[MAX_URL_LENGTH+128];
				ParseURL(sURL, hostname, sizeof(hostname), location, sizeof(location), filename, sizeof(filename));
				FormatEx(sRequest, sizeof(sRequest), "GET %s/%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\nPragma: no-cache\r\nCache-Control: no-cache\r\n\r\n", location, filename, hostname);
				
				hDLPack.Position = DLPack_Request; // sRequest
				hDLPack.WriteString(sRequest);
				
				Socket newSocket = new Socket(SOCKET_TCP, OnSocketError);
				newSocket.SetArg(hDLPack);
				newSocket.SetOption(ConcatenateCallbacks, 4096);
				newSocket.Connect(OnSocketConnected, OnSocketReceive, OnSocketDisconnected, hostname, 80);
				
				delete socket;
				return;
			}
			
			// Check HTTP status code
			char sStatusCode[64];
			strcopy(sStatusCode, (FindCharInString(data, '\r') - 8), data[9]);
			
			if(strncmp(sStatusCode, "200", 3) != 0)	{
				CloseSocketHandles(socket, hDLPack);
			
				char sError[256];
				FormatEx(sError, sizeof(sError), "Socket error: %s", sStatusCode);
				DownloadEnded(false, sError);
				return;
			}
		}
		
		hDLPack.Position = DLPack_Header;
		hDLPack.WriteCell(1);	// bParsedHeader
	}
	
	// Write data to file.
	hDLPack.Position = DLPack_File;
	File hFile = view_as<File>(hDLPack.ReadCell());
	
	while(idx < size)
		WriteFileCell(hFile, data[idx++], 1);
}

void OnSocketDisconnected(Socket socket, DataPack hDLPack)	{
	CloseSocketHandles(socket, hDLPack);
	DownloadEnded(true);
}

void OnSocketError(Socket socket, const int errorType, const int errorNum, DataPack hDLPack)	{
	CloseSocketHandles(socket, hDLPack);

	char sError[256];
	FormatEx(sError, sizeof(sError), "Socket error: %d (Error code %d)", errorType, errorNum);
	DownloadEnded(false, sError);
}

void CloseSocketHandles(Socket socket, DataPack hDLPack)	{
	hDLPack.Position = DLPack_File;
	delete view_as<ArrayList>(hDLPack.ReadCell());	// hFile
	delete hDLPack;
	delete socket;
}
