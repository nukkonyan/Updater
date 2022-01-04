
/* Extension Helper - SteamWorks */

void Download_SteamWorks(const char[] url, const char[] dest)	{
	char sURL[MAX_URL_LENGTH];
	PrefixURL(sURL, sizeof(sURL), url);
	
	DataPack hDLPack = new DataPack();
	hDLPack.WriteString(dest);

	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, sURL);
	SteamWorks_SetHTTPRequestHeaderValue(hRequest, "Pragma", "no-cache");
	SteamWorks_SetHTTPRequestHeaderValue(hRequest, "Cache-Control", "no-cache");
	SteamWorks_SetHTTPCallbacks(hRequest, OnSteamWorksHTTPComplete);
	SteamWorks_SetHTTPRequestContextValue(hRequest, hDLPack);
	SteamWorks_SendHTTPRequest(hRequest);
}

void OnSteamWorksHTTPComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, DataPack hDLPack)	{
	char sDest[PLATFORM_MAX_PATH];
	hDLPack.Reset();
	hDLPack.ReadString(sDest, sizeof(sDest));
	delete hDLPack;
	
	switch(bRequestSuccessful && eStatusCode == k_EHTTPStatusCode200OK)	{
		case	true:	{
			SteamWorks_WriteHTTPResponseBodyToFile(hRequest, sDest);
			DownloadEnded(true);
		}
		case	false:	{
			char sError[256];
			FormatEx(sError, sizeof(sError), "SteamWorks error (status code %i). Request successful: %s", eStatusCode, bRequestSuccessful ? "True" : "False");
			DownloadEnded(false, sError);
		}
	}
	
	delete hRequest;
}
