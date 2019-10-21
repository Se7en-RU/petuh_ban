#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <chat-processor>
#include <fpvm_interface>

#pragma newdecls required

#define MODEL "models/isony/Twenty_Three/knifes/is_penis_flex/is_v_penis_flex.mdl"
#define WORLD_MODEL "models/isony/Twenty_Three/knifes/is_penis_flex/is_w_penis_flex.mdl"

bool PLAYER_BANNED[MAXPLAYERS+1] = {false,...};
char BanMessages[][] = {
    "Ко-ко-ко",
    "Кудах-тах-тах",
    "Кукареку",
};
int g_Model;
int g_WorldModel;
char g_sKnifeName[MAXPLAYERS+1][64];

public Plugin myinfo = 
{
	name = "Petuh ban",
	author = "Se7en, iSony",
	version = "1.0",
	url = "https://csgo.su"
};

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("Плагин предназначен только для CS:GO");

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);

	RegAdminCmd("sm_petuh", AdminCommand_Petuh, ADMFLAG_ROOT);
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max) 
{

    CreateNative("Petuh_Ban", Native_BanPlayer);
    CreateNative("Petuh_IsPetuh", Native_CheckPlayer);

    RegPluginLibrary("petuh_ban");

    return APLRes_Success;
}

public void OnClientPutInServer(int client)	
{
    SDKHook(client, SDKHook_OnTakeDamage, ClientTakeDamage);
    SDKHook(client, SDKHook_WeaponEquipPost, ClientPostWeaponEquip);

    ResetClient(client);
}

public void OnMapStart()
{ 
	g_Model = PrecacheModel(MODEL);
	g_WorldModel = PrecacheModel(WORLD_MODEL);
	
	// model downloads
	AddFileToDownloadsTable("materials/models/isony/Twenty_Three/knifes/is_penis_flex/is_penis.vmt");
	AddFileToDownloadsTable("materials/models/isony/Twenty_Three/knifes/is_penis_flex/is_penis.vtf");
	AddFileToDownloadsTable("materials/models/isony/Twenty_Three/knifes/is_penis_flex/is_penis_normal.vtf");
	AddFileToDownloadsTable("models/isony/Twenty_Three/knifes/is_penis_flex/is_v_penis_flex.dx90.vtx");
	AddFileToDownloadsTable("models/isony/Twenty_Three/knifes/is_penis_flex/is_v_penis_flex.mdl");
	AddFileToDownloadsTable("models/isony/Twenty_Three/knifes/is_penis_flex/is_v_penis_flex.vvd");
	AddFileToDownloadsTable("models/isony/Twenty_Three/knifes/is_penis_flex/is_w_penis_flex.dx90.vtx");
	AddFileToDownloadsTable("models/isony/Twenty_Three/knifes/is_penis_flex/is_w_penis_flex.mdl");
	AddFileToDownloadsTable("models/isony/Twenty_Three/knifes/is_penis_flex/is_w_penis_flex.phy");
	AddFileToDownloadsTable("models/isony/Twenty_Three/knifes/is_penis_flex/is_w_penis_flex.vvd");
	AddFileToDownloadsTable("models/isony/Twenty_Three/knifes/is_penis_flex/is_w_penis_flex_dropped.dx90.vtx");
	AddFileToDownloadsTable("models/isony/Twenty_Three/knifes/is_penis_flex/is_w_penis_flex_dropped.mdl");
	AddFileToDownloadsTable("models/isony/Twenty_Three/knifes/is_penis_flex/is_w_penis_flex_dropped.phy");
	AddFileToDownloadsTable("models/isony/Twenty_Three/knifes/is_penis_flex/is_w_penis_flex_dropped.vvd");
} 

// Кикаем петушков в конце игры
public void OnMapEnd()
{
    for(int i = 1; i <= MaxClients; i++) 
	{
        if(!IsValidClient(i) || !IsClientBanned(i)) continue;

        KickClient(i, "Твоё время вышло, петушок!");
	}
}

public Action ClientPostWeaponEquip(int client, int weapon)
{
    if(IsValidClient(client, true) && IsClientBanned(client)) {
        char sWeapon[64]; 
        GetEntPropString(weapon, Prop_Data, "m_iClassname", sWeapon, sizeof(sWeapon));

        if(StrContains(sWeapon, "weapon_knife", false) == -1 && StrContains(sWeapon, "weapon_bayonet", false) == -1)
		{
            if(weapon > 0 && IsValidEntity(weapon))
			{
                RemovePlayerItem(client, weapon);
                AcceptEntityInput(weapon, "Kill");
                FakeClientCommand(client, "use weapon_knife");
			}
        }
    }
}

public Action ClientTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype) 
{
	if(IsValidClient(attacker) && IsClientBanned(attacker)) {
        damage = 0.0;
        return Plugin_Changed;
    }
    
	return Plugin_Continue;
}

public Action CP_OnChatMessage(int& author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors)
{
	if(IsClientBanned(author)) {
        int iMessage = GetRandomInt(0, sizeof(BanMessages)-1);
        Format(message, (MAXLENGTH_MESSAGE - strlen(name) - 5), "\x01%s", BanMessages[iMessage]);

        return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{	
	ResetClient(client);
}

stock void RemoveWeapons(int client)
{
	int iWeapon;
	for(int i = 0; i <= 5; i++)
	{
		if(i == 2) continue;
		while((iWeapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, iWeapon);
			AcceptEntityInput(iWeapon, "kill");
		}
	}
}

bool IsClientBanned(int client)
{
    return (PLAYER_BANNED[client]);
}

void ResetClient(int client)
{
	PLAYER_BANNED[client] = false;
	g_sKnifeName[client] = "";
}

stock bool IsValidClient(int client, bool bAlive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && !IsFakeClient(client) && (!bAlive || IsPlayerAlive(client)));
}

void MakePetuh(int client)
{
	if(IsValidClient(client)) {
		PLAYER_BANNED[client] = true; // Флаг бана
		
		if(IsPlayerAlive(client)) {
			FakeClientCommand(client, "use weapon_knife");
			RemoveWeapons(client); // Убираем оружие
		}
			
		FPVMI_AddViewModelToClient(client, g_sKnifeName[client], g_Model);
		FPVMI_AddWorldModelToClient(client, g_sKnifeName[client], g_WorldModel);
		
		SetClientListeningFlags(client, 1); // Мут игрока
		// TODO Звук петушка, сообщение?
        // TODO Сюда вставляем хуй
    }
}

void DelPetuh(int client)
{
	if(IsValidClient(client)) {
		PLAYER_BANNED[client] = false; // Флаг бана
		
		SetClientListeningFlags(client, 0); // Анмут игрока

		int iWeapon;
		iWeapon = GetPlayerWeaponSlot(client, 2);
		GetEntityClassname(iWeapon, g_sKnifeName[client], 64);
		
		FPVMI_RemoveViewModelToClient(client, g_sKnifeName[client]);
		FPVMI_RemoveWorldModelToClient(client, g_sKnifeName[client]);
    }
}

public int Native_BanPlayer(Handle hPlugin, int iNumParams)
{
    int client = GetNativeCell(1);
    MakePetuh(client);

    return 0;
}

public int Native_CheckPlayer(Handle hPlugin, int iNumParams)
{
    int client = GetNativeCell(1);
    return IsClientBanned(client);
}

public Action AdminCommand_Petuh(int client, any args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_petuh <#userid|name>");
		
		return Plugin_Handled;
	}

	char Arguments[256];
	GetCmdArgString(Arguments, sizeof(Arguments));

	char arg[65];
	BreakString(Arguments, arg, sizeof(arg));

	int target = FindTarget(client, arg, true);
	if (target == -1) {
		return Plugin_Handled;
	}


	if(!IsClientBanned(client)) {
		MakePetuh(client);
	} else {
		DelPetuh(client);
	}

	return Plugin_Handled;
}

public Action Event_PlayerSpawn(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	RequestFrame(PlayerSpawned, hEvent.GetInt("userid"));
}

void PlayerSpawned(int UserID)
{
	int client = GetClientOfUserId(UserID);

	if(IsValidClient(client)) {
		int iWeapon = GetPlayerWeaponSlot(client, 2);
		GetEntityClassname(iWeapon, g_sKnifeName[client], 64);

		if(IsClientBanned(client) && FPVMI_GetClientViewModel(client, g_sKnifeName[client]) == -1) {
			FPVMI_AddViewModelToClient(client, g_sKnifeName[client], g_Model);
			FPVMI_AddWorldModelToClient(client, g_sKnifeName[client], g_WorldModel);
		}
	}
}