#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <chat-processor>
#include <fpvm_interface>

#pragma newdecls required

#define MODEL "models/isony/Twenty_Three/knifes/is_penis_flex/is_v_penis_flex.mdl"
#define WORLD_MODEL "models/isony/Twenty_Three/knifes/is_penis_flex/is_w_penis_flex.mdl"

bool PLAYER_BANNED[MAXPLAYERS+1] = {false,...};
Handle g_hSoundTimer[MAXPLAYERS+1] = INVALID_HANDLE;
int g_Model;
int g_WorldModel;
char g_sKnifeName[MAXPLAYERS+1][64];
char BanMessages[][] = {"Ко-ко-ко", "Кудах-тах-тах", "Кукареку",};
char chickenIdleSounds[][] =  { "ambient/creatures/chicken_idle_01.wav", "ambient/creatures/chicken_idle_02.wav", "ambient/creatures/chicken_idle_03.wav" };
char chickenPanicSounds[][] =  { "ambient/creatures/chicken_panic_01.wav", "ambient/creatures/chicken_panic_02.wav", "ambient/creatures/chicken_panic_03.wav", "ambient/creatures/chicken_panic_04.wav" };

public Plugin myinfo = 
{
	name = "Petuh ban",
	author = "Se7en, iSony",
	version = "1.3",
	url = "https://csgo.su"
};

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("Плагин предназначен только для CS:GO");

	LoadTranslations("common.phrases");

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

	RegConsoleCmd("sm_admintest", Command_Admintest);
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max) 
{

    CreateNative("Petuh_Ban", Native_BanPlayer);
    CreateNative("Petuh_IsPetuh", Native_CheckPlayer);

    RegPluginLibrary("petuh_ban");

    return APLRes_Success;
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

public void OnClientPutInServer(int client)	
{
	SDKHook(client, SDKHook_OnTakeDamage, ClientTakeDamage);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	
	ResetClient(client);
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if(IsValidEntity(weapon) && IsClientBanned(client)) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action CS_OnBuyCommand(int client, const char[] sWeapon)
{
	if(IsClientBanned(client)) {
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
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
		
		if(IsPlayerAlive(author)) {
			PlaySound(author);
		}
		
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
	RemoveSoundTimer(client);
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
			PlaySound(client);
			CreateSoundTimer(client);
		}
			
		SetKnifeModel(client);
		
		SetClientListeningFlags(client, 1); // Мут игрока
		PrintToChat(client, "Вам был отключен голосовой чат!");
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

public Action Event_PlayerSpawn(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	RequestFrame(PlayerSpawned, hEvent.GetInt("userid"));
}

void PlayerSpawned(int UserID)
{
	int client = GetClientOfUserId(UserID);

	// RemoveWeapons(client);

	if(IsValidClient(client, true)) {
		int iWeapon = GetPlayerWeaponSlot(client, 2);
		GetEntityClassname(iWeapon, g_sKnifeName[client], 64);

		if(IsClientBanned(client)) {
			CreateSoundTimer(client);
			SetKnifeModel(client);
		}
	}
}

public Action Command_Admintest(int client, int args)
{
	if(IsValidClient(client, true) && !IsClientBanned(client)) {
		SetKnifeModel(client);
	}
}

public Action Timer_Sound(Handle hTimer, int UserID)
{
	int client = GetClientOfUserId(UserID);

	if(IsValidClient(client, true)) {
		PlaySoundIdle(client);
	} else {
		RemoveSoundTimer(client);
	}
}

void PlaySound(int client)
{
	int sound = GetRandomInt(0, sizeof(chickenPanicSounds) - 1);
	EmitSoundToAll(chickenPanicSounds[sound], client);
}

void PlaySoundIdle(int client)
{
	int sound = GetRandomInt(0, sizeof(chickenIdleSounds) - 1);
	EmitSoundToAll(chickenIdleSounds[sound], client);
}

void CreateSoundTimer(int client)
{
	RemoveSoundTimer(client);
	g_hSoundTimer[client] = CreateTimer(10.0, Timer_Sound, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void RemoveSoundTimer(int client)
{
	if (g_hSoundTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hSoundTimer[client]);
		g_hSoundTimer[client] = INVALID_HANDLE;
	}
}

void SetKnifeModel(int client)
{
	if(FPVMI_GetClientViewModel(client, g_sKnifeName[client]) == -1) {
		FPVMI_AddViewModelToClient(client, g_sKnifeName[client], g_Model);
		FPVMI_AddWorldModelToClient(client, g_sKnifeName[client], g_WorldModel);
	}
}