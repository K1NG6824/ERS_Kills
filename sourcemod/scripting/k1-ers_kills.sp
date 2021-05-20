#include <cstrike>
#include <sdkhooks>
#include <clientprefs>
#include <k1_ers_core>

int g_iKills[MAXPLAYERS+1];
int g_iMaxChanse, g_iMaxWinPlayer, g_iMinClient;
ArrayList g_hArrayChanse;
char g_sLogFile[PLATFORM_MAX_PATH];
bool g_bLog;

public Plugin myinfo = 
{
    name = "[ERS] Skins for Kills",
    author = "K1NG",
    description = "http//projecttm.ru/",
    version = "1.3"
}

public void OnPluginStart()
{
    g_hArrayChanse = new ArrayList(3);
    HookEvent("cs_win_panel_match", EventCSWIN_Panel);
    HookEvent("player_death", player_death); 
    LoadConfig();
}

public player_death(Handle event, const char[] name, bool dontBroadcast) 
{ 
int iClient = GetClientOfUserId(GetEventInt(event, "attacker")); 
if(iClient > 0 && GetClientTeam(iClient) != GetClientTeam(GetClientOfUserId(GetEventInt(event, "userid")))) 
    g_iKills[iClient] += 1; 
} 


public void LoadConfig()
{
    char szBuffer[1024]; 
    BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "configs/k1-ers/modules/kills.cfg");
	
	LoadTranslations("k1-ers_kills.phrases");

    KeyValues hKeyValues = new KeyValues("K1-ERS_Kills");

    if (!hKeyValues.ImportFromFile(szBuffer))
    {
        SetFailState("Не удалось открыть файл %s", szBuffer);
        return;
    }
    
    g_iMinClient = hKeyValues.GetNum("min_client", 4);
    g_iMaxWinPlayer = hKeyValues.GetNum("winers", 1);
    g_bLog = !!hKeyValues.GetNum("log", 1);

    if (hKeyValues.JumpToKey("chanse") && hKeyValues.GotoFirstSubKey(false))
    {
        g_hArrayChanse.Clear();
        if(g_iMaxWinPlayer < 0) g_iMaxWinPlayer = 0;
        g_iMaxChanse = 0;
        char sIdSkin[10];
        char sTemp[64];
        char sInfo[2][32];
        int idx, iLen;
        do
        {
            hKeyValues.GetSectionName(sIdSkin, sizeof(sIdSkin));
            hKeyValues.GetString(NULL_STRING, sTemp, sizeof sTemp);
            iLen = ExplodeString(sTemp,"-",sInfo, sizeof(sInfo),sizeof (sInfo[]));
            for(int x = 0 ; x< iLen ;x++)
            {
                TrimString(sInfo[x]);
            }
            g_iMaxChanse += StringToInt(sInfo[0]);
            idx = g_hArrayChanse.Length;
            g_hArrayChanse.Push(StringToInt(sIdSkin));
            g_hArrayChanse.Set(idx, g_iMaxChanse, 1);
            if(iLen == 2)
                g_hArrayChanse.Set(idx, StringToInt(sInfo[1]), 2);
            else
                g_hArrayChanse.Set(idx, -1, 2);

        } while (hKeyValues.GotoNextKey(false));
    }
    delete hKeyValues;
    if(g_bLog)
        BuildPath(Path_SM, g_sLogFile, sizeof(g_sLogFile), "logs/k1-ers.log")
}


public OnClientDisconnect(iClient)
{
    g_iKills[iClient] = 0;
}

public void EventCSWIN_Panel(Event event, const char[] name, bool dontBroadcast)
{
    if(GetClientCount(true) >= g_iMinClient)
    {
        ArrayList hArrayClient = new ArrayList(2);
        int iColIter;
        for(int x = 1; x <= MaxClients; x++)
        {
            if(IsClientInGame(x) && !IsFakeClient(x)) 
            {
                hArrayClient.Set(hArrayClient.Push(g_iKills[x]), x, 1);
                iColIter++
            }
        }
        if(iColIter > 0)
        {
            hArrayClient.Sort(Sort_Descending, Sort_Integer)
            if(g_iMaxWinPlayer < iColIter) iColIter = g_iMaxWinPlayer;
            for(int x = 0; x < iColIter; x++)
            {
                GiveDrop(hArrayClient.Get(x, 1));
            }
        }
        delete hArrayClient;
    }
}

public void GiveDrop(int iClient)
{
    int iRandomInt = GetRandomInt(1, g_iMaxChanse);
    int iResult = -1;
    for(int i = 0; i < g_hArrayChanse.Length; ++i)
    {
        if(g_hArrayChanse.Get(i, 1) >= iRandomInt)
        {
            iResult = i;
            break;
        }
    }
    if(iResult != -1)
    {
        K1_ERS_GiveClientSkin(iClient, g_hArrayChanse.Get(iResult), g_hArrayChanse.Get(iResult, 2));
        if(g_bLog)
        {
            char szAuth[32];
            GetClientAuthId(iClient, AuthId_Engine, szAuth, sizeof szAuth, true);
            LogToFile(g_sLogFile, "%t", "Log_phrase", iClient, szAuth, g_hArrayChanse.Get(iResult), g_hArrayChanse.Get(iResult, 2));
        }
    }
}