
static bool lateLoad;
static bool shavitLoaded;
static EngineVersion engineVersion;
static char jumpstatsVersion[32];
static int tickrate;
chatstrings_t g_csChatStrings;
bool g_bEditing[MAXPLAYERS + 1]; //Setting to true enables "edit mode", menu.sp. defined in here to prevent scoping errors

void Init_Utils(bool late, bool shavit, EngineVersion engine, char[] version)
{
	lateLoad = late;
	shavitLoaded = shavit;
	engineVersion = engine;
	tickrate = RoundToFloor(1 / GetTickInterval());


	Format(jumpstatsVersion, sizeof(jumpstatsVersion), "%s", version);
	if(shavitLoaded)
	{
		Shavit_OnChatConfigLoaded();
	}
}


stock bool BgsLateLoaded()
{
	return lateLoad;
}

stock void BgsVersion(char[] buffer, int len)
{
	Format(buffer, len, "%s", jumpstatsVersion);
}


stock bool BgsShavitLoaded()
{
	return shavitLoaded;
}


stock int BgsTickRate()
{
	return tickrate;
}

stock EngineVersion BgsGetEngineVersion()
{
	return engineVersion;
}

public void Shavit_OnChatConfigLoaded()
{
	Shavit_GetChatStrings(sMessagePrefix, g_csChatStrings.sPrefix, sizeof(chatstrings_t::sPrefix));
	Shavit_GetChatStrings(sMessageText, g_csChatStrings.sText, sizeof(chatstrings_t::sText));
	Shavit_GetChatStrings(sMessageWarning, g_csChatStrings.sWarning, sizeof(chatstrings_t::sWarning));
	Shavit_GetChatStrings(sMessageVariable, g_csChatStrings.sVariable, sizeof(chatstrings_t::sVariable));
	Shavit_GetChatStrings(sMessageVariable2, g_csChatStrings.sVariable2, sizeof(chatstrings_t::sVariable2));
	Shavit_GetChatStrings(sMessageStyle, g_csChatStrings.sStyle, sizeof(chatstrings_t::sStyle));
}

stock int BgsGetHUDTarget(int client, int fallback = 0)
{
	int target = fallback;
	if(!IsClientObserver(client))
	{
		return target;
	}
	int iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
	if (iObserverMode >= 3 && iObserverMode <= 7)
	{
		int iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		if (BgsIsValidClient(iTarget)) {
			target = iTarget;
		}
	}
	return target;
}

stock bool BgsIsValidClient(int client, bool bAlive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && (!bAlive || IsPlayerAlive(client)));
}

stock void BgsPrintToChat(int client, const char[] format, any...)
{
	char buffer[300];
	VFormat(buffer, sizeof(buffer), format, 3);

	if(BgsShavitLoaded())
	{
		Shavit_PrintToChat(client, "%s[JumpStats]: %s%s", g_csChatStrings.sVariable, g_csChatStrings.sText, buffer)
	}
	else
	{
		PrintToChat(client, "%s%s[JumpStats]: %s%s", (BgsGetEngineVersion() == Engine_CSGO) ? " ":"", g_sBstatColorsHex[Cyan], g_sBstatColorsHex[White], buffer);
	}
}

stock void BgsSetCookie(int client, Cookie hCookie, int n)
{
	char strCookie[64];
	IntToString(n, strCookie, sizeof(strCookie));
	SetClientCookie(client, hCookie, strCookie);
}

stock int GetIntSubValue(int num, int position, int binaryShift, int binaryMask)
{
	if(num < 0)
	{
		num = ~num;
		num = num >> (position * binaryShift);
		num = ~num & binaryMask;
	}
	else
	{
	  	num = (num >> (position * binaryShift)) & binaryMask;
	}

	return num;
}

stock void SetIntSubValue(int &editNum, int insertVal, int position, int binaryShift, int binaryMask)
{
	editNum = (editNum & ~(binaryMask << (position * binaryShift))) | ((insertVal & binaryMask) << (position * binaryShift));
}

stock float GetAdjustedHudCoordinate(int value, float scaler)
{
	float rVal = -1.0;
	if(value <= 0 || value > RoundToFloor(scaler))
	{
		return rVal;
	}

	rVal = value / scaler;
	if(rVal <= 0.0 || rVal > 1.0)
	{
		return -1.0;
	}
	return rVal;
}

stock int GetHudCoordinateToInt(float value, int scaler, int min, int max)
{
	if(value < 0 || value > 1.0)
	{
		return 0;
	}

	int adjVal = RoundToFloor(value * scaler);
	if(adjVal > max)
	{
		adjVal = max;
	}
	if(adjVal < min)
	{
		adjVal = min;
	}
	return adjVal;
}

stock void BgsDisplayHud(int client, float pos[2], int rgb[3], float holdTime, int channel, bool force, const char[] message, any...)
{
	if(g_bEditing[client] && !force)
	{
		return;
	}

	char buffer[512];
	VFormat(buffer, sizeof(buffer), message, 8);
	SetHudTextParams(pos[0], pos[1], holdTime, rgb[0], rgb[1], rgb[2], 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, channel, message);
}

stock float FloatMod(float num, float denom)
{
	return num - denom * RoundToFloor(num / denom);
}

stock float operator%(float oper1, float oper2)
{
	return FloatMod(oper1, oper2);
}
