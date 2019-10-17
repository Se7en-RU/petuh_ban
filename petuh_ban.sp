#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <chat-processor>

#pragma newdecls required

bool PLAYER_BANNED[MAXPLAYERS+1] = {false,...};
char BanMessages[][] = {
    "Ко-ко-ко",
    "Кудах-тах-тах",
    "Кукареку",
};

public Plugin myinfo = 
{
	name = "Petuh ban",
	author = "Se7en",
	version = "0.0.1",
	url = "https://csgo.su"
};

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("Плагин предназначен только для CS:GO");
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max) 
{

    CreateNative("Petuh_Ban", Native_BanPlayer);

    RegPluginLibrary("petuh");

    return APLRes_Success; // Для продолжения загрузки плагина нужно вернуть APLRes_Success
}

public void OnClientPutInServer(int client)	
{
    SDKHook(client, SDKHook_OnTakeDamage, ClientTakeDamage);
    SDKHook(client, SDKHook_WeaponEquipPost, ClientPostWeaponEquip);

    ResetClient(client);
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
    if(IsValidClient(client, true)) {
        char sWeapon[64]; 
        GetEntPropString(weapon, Prop_Data, "m_iClassname", sWeapon, sizeof(sWeapon));

        if(StrContains(sWeapon, "weapon_knife", false) == -1 && StrContains(sWeapon, "weapon_bayonet", false) == -1) {
            if(weapon > 0 && IsValidEntity(weapon)) {
                RemovePlayerItem(client, weapon);
                AcceptEntityInput(weapon, "Kill");
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

public Action OnChatMessage(int& author, Handle recipients, char[] name, char[] message)
{
	if(IsClientBanned(author)) {
        int iMessage = GetRandomInt(0, sizeof(BanMessages)-1);
        Format(message, (MAXLENGTH_MESSAGE - strlen(name) - 5), "%s", BanMessages[iMessage]);

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
        if(i == 2) continue; // Не забираем нож
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
}

stock bool IsValidClient(int client, bool bAlive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && !IsFakeClient(client) && (!bAlive || IsPlayerAlive(client)));
}

void MakePetuh(int client)
{
    if(IsValidClient(client)) {
        PLAYER_BANNED[client] = true; // Флаг бана
        
        FakeClientCommand(client, "use weapon_knife");
        RemoveWeapons(client); // Убираем оружие
        SetClientListeningFlags(client, 1); // Мут игрока

        // TODO Звук петушка, сообщение?
        // TODO Сюда вставляем хуй
    }
}

public int Native_BanPlayer(Handle hPlugin, int iNumParams)
{
    int client = GetNativeCell(1);
    MakePetuh(client);

    return 0;
}