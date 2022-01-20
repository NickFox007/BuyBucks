#include <sourcemod>
#include <cstrike>
#include <shop>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "[SHOP] Buy Bucks",
	description = "Allow players to buy game dollars in Shop",
	author = "Nick Fox",
	version = "0.1",
	url = "https://vk.com/nf_dev"
}

ItemId g_iID;

bool g_bHalfTime;

int
	g_iBucksCount,
	g_iBucksPrice,
	g_iBucksSell,	
	g_iCurRound,
	g_iMaxRounds,
	g_iRounds;

ConVar
	CVARCount,
	CVARPrice,
	CVARSell,
	CVARHalf,
	CVARRound,
	CVARMax;

public void OnPluginStart()
{
	(CVARCount = CreateConVar("sm_buybucks_count", "1000", "Количество выдаваемых денег.", _, true, 0.0)).AddChangeHook(ChangeCvar_Count);
	(CVARPrice = CreateConVar("sm_buybucks_price", "3500", "Стоимость покупки данной опции.", _, true, 0.0)).AddChangeHook(ChangeCvar_Price);
	(CVARSell = CreateConVar("sm_buybucks_sell", "0", "Стоимость при продаже.", _, true, 0.0)).AddChangeHook(ChangeCvar_Sell);
	(CVARRound = CreateConVar("sm_buybucks_rounds", "2", "Количество раундов в начале матча, в течение которых покупка запрещена.", _, true, 0.0)).AddChangeHook(ChangeCvar_Round);
	(CVARHalf = FindConVar("mp_halftime")).AddChangeHook(ChangeCvar_Half);
	(CVARMax = FindConVar("mp_maxrounds")).AddChangeHook(ChangeCvar_MaxRounds);
	
	AutoExecConfig(true, "buybucks", "shop");	
	
	Autoexec();
	
	if(Shop_IsStarted()) Shop_Started();
	
	HookEvent("round_start",OnRound,EventHookMode_Post);
	
}

public void OnMapStart()
{
	GetCurRound();
}

void GetCurRound()
{
	g_iCurRound = CS_GetTeamScore(2) + CS_GetTeamScore(3) + 1;
	if(g_bHalfTime) g_iCurRound = g_iCurRound % (g_iMaxRounds / 2);
}

public void OnPluginEnd()
{
	Shop_UnregisterMe();
}

void Autoexec()
{
	g_iBucksCount = CVARCount.IntValue;
	g_iBucksPrice = CVARPrice.IntValue;
	g_iBucksSell = CVARSell.IntValue;
	g_bHalfTime = CVARHalf.BoolValue;	
	g_iMaxRounds = CVARMax.IntValue;
	g_iRounds = CVARRound.IntValue;
}

public void Shop_Started()
{
	CategoryId category_id = Shop_RegisterCategory("stuff", "Разное", "");
	if (Shop_StartItem(category_id, "shop_buybucks"))
	{		
		Shop_SetInfo("Игровые баксы", "Покупка игровых денег для покупки оружия",0, 0, Item_Finite);
		Shop_SetCallbacks(OnItemRegistered, OnEquipItem);
		Shop_EndItem();
	}
}

public ShopAction OnEquipItem(int iClient, CategoryId category_id, const char[] sCategory, ItemId item_id, const char[] sItem, bool isOn, bool elapsed)
{
	if(GetClientTeam(iClient)<2)
	{
		PrintToChat(iClient, "Вы должны быть в одной из команд");		
	}
	else
	{
		if(g_iCurRound>g_iRounds)
		{
			int bucks = GetEntProp(iClient, Prop_Send, "m_iAccount");
			bucks += g_iBucksCount;
			SetEntProp(iClient, Prop_Send, "m_iAccount", bucks);
			PrintToChat(iClient, "Вам выдано %i$", g_iBucksCount);
			return Shop_UseOn;
		} 
		else PrintToChat(iClient, "Пока рано покупать!");
	}
	return Shop_Raw;
}

public void OnItemRegistered(CategoryId category_id, const char[] sCategory, const char[] sItem, ItemId item_id)
{
	g_iID = item_id;
	
	Shop_SetItemPrice(g_iID, g_iBucksPrice);
	Shop_SetItemSellPrice(g_iID, g_iBucksSell);	
}


public void ChangeCvar_Count(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iBucksCount = convar.IntValue;
}

public void ChangeCvar_Price(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iBucksPrice = convar.IntValue;
	Shop_SetItemPrice(g_iID, g_iBucksPrice);
}

public void ChangeCvar_Sell(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iBucksSell = convar.IntValue;
	Shop_SetItemSellPrice(g_iID, g_iBucksSell);	
}

public void ChangeCvar_Half(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bHalfTime = convar.BoolValue;
}

public void ChangeCvar_MaxRounds(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iMaxRounds = convar.IntValue;
}

public void ChangeCvar_Round(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iRounds = convar.IntValue;
}

public Action OnRound(Event hEvent,const char[] name, bool dontBroadcast)
{
	GetCurRound();
	return Plugin_Continue;
}