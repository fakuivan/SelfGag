/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Admin Help Plugin
 * Displays and searches SourceMod commands and descriptions.
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <sourcemod>
#include <adminmenu>
#pragma semicolon 1

#define PLUGIN_VERSION	"0.7"

#define GET_SENDER(%1)	BfReadByte(%1)
#define GET_RECIPIENT(%1)	%1[0]

public Plugin myinfo = 
{
	name = "SelfGag",
	author = "fakuivan",
	description = "Player-to-Player Gags",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=264797"
};

public void OnPluginStart()
{
	CreateConVar("sm_selfgag_version", PLUGIN_VERSION, "Version of SelfGag", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookUserMessage(GetUserMessageId("SayText2"), Callback_OnSayText2, true);
	RegConsoleCmd("sm_sg", Callback_Gag, "Self gags a player");
	RegConsoleCmd("sm_selfgag", Callback_Gag, "Self gags a player");
	RegConsoleCmd("sm_sug", Callback_UnGag, "Self ungags a player");
	RegConsoleCmd("sm_selfungag", Callback_UnGag, "Self ungags a player");
	RegConsoleCmd("sm_cg", Callback_GetGagged, "Shows a list of self gagged players");
	RegConsoleCmd("sm_checkgagged", Callback_GetGagged, "Shows a list of self gagged players");
	LoadTranslations("common.phrases");
	LoadTranslations("sg.phrases");
}

bool gb_gagged[MAXPLAYERS][MAXPLAYERS];

public void OnClientPutInServer(int i_client)
{
	for (int i = 0; i < MaxClients; i++)
	{
		gb_gagged[i_client][i] = false;
		gb_gagged[i][i_client] = false;
	}
}

public Action Callback_GetGagged(int i_client, int i_args)
{
	ReplyToCommand(i_client, "[SM] %t:", "sg_showing_gagged");
	for (int i = 0; i < MaxClients; i++)
	{
		if (gb_gagged[i_client][i])
		{
			if (IsClientInGame(i))
			{
				ReplyToCommand(i_client, "[SM]  %N", i);
			}
		}
	}
}

public Action Callback_Gag(int i_client, int i_args)
{
	if (i_args != 1)
	{
		DisplayGagMenu(i_client);
		return Plugin_Handled;
	}
	
	char s_target[MAX_NAME_LENGTH];
	GetCmdArg(1, s_target, sizeof(s_target));
	
	char s_target_name[MAX_TARGET_LENGTH];
	int i_target_list[MAXPLAYERS], i_target_count;
	bool b_tn_is_ml;
 
	if ((i_target_count = ProcessTargetString(
			s_target,
			i_client,
			i_target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			s_target_name,
			sizeof(s_target_name),
			b_tn_is_ml)) <= 0)
	{
		ReplyToTargetError(i_client, i_target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < i_target_count; i++)
	{
		gb_gagged[i_client][i_target_list[i]] = true;
	}

	if (b_tn_is_ml)
	{
		ReplyToCommand(i_client, "[SM] %t", "sg_ml_you_gagged", s_target_name);
	}
	else
	{
		ReplyToCommand(i_client, "[SM] %t", "sg_you_gagged", s_target_name);
	}
	return Plugin_Handled;
}

public Action Callback_UnGag(int i_client, int i_args)
{
	if (i_args != 1)
	{
		DisplayUnGagMenu(i_client);
		return Plugin_Handled;
	}
	char s_target[MAX_NAME_LENGTH];
	GetCmdArg(1, s_target, sizeof(s_target));
	
	char s_target_name[MAX_TARGET_LENGTH];
	int i_target_list[MAXPLAYERS], i_target_count;
	bool b_tn_is_ml;
 
	if ((i_target_count = ProcessTargetString(
			s_target,
			i_client,
			i_target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			s_target_name,
			sizeof(s_target_name),
			b_tn_is_ml)) <= 0)
	{
		ReplyToTargetError(i_client, i_target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < i_target_count; i++)
	{
		gb_gagged[i_client][i_target_list[i]] = false;
	}

	if (b_tn_is_ml)
	{
		ReplyToCommand(i_client, "[SM] %t", "sug_ml_you_ungagged", s_target_name);
	}
	else
	{
		ReplyToCommand(i_client, "[SM] %t", "sug_you_ungagged", s_target_name);
	}
	return Plugin_Handled;
}


void DisplayGagMenu(int i_client)
{
	Handle h_menu = CreateMenu(MenuHandler_GagMenu);
	SetMenuTitle(h_menu, "%T:", "sg_menu_title", i_client);
	SetMenuExitBackButton(h_menu, true);
	
	AddTargetsToMenu2(h_menu, 0, COMMAND_FILTER_NO_BOTS);
	
	DisplayMenu(h_menu, i_client, MENU_TIME_FOREVER);
}

public MenuHandler_GagMenu(Handle h_menu, MenuAction i_action, int i_param1, int i_param2)
{
	switch (i_action)
	{
		case MenuAction_End:
		{
			CloseHandle(h_menu);
		}
		case MenuAction_Select:
		{
			char s_info[32];
			int i_target;
			
			GetMenuItem(h_menu, i_param2, s_info, sizeof(s_info));
			int i_userid = StringToInt(s_info);

			if ((i_target = GetClientOfUserId(i_userid)) == 0)
			{
				PrintToChat(i_param1, "[SM] %t", "sg_menu_cant_target");
			}
			else
			{
				PrintToChat(i_param1, "[SM] %t", "sg_menu_you_gagged", i_target);
				gb_gagged[i_param1][i_target] = true;
			}
		}
	}
}

void DisplayUnGagMenu(int i_client)
{
	Handle h_menu = CreateMenu(MenuHandler_UnGagMenu);
	SetMenuTitle(h_menu, "%T", "sug_menu_title", i_client);
	SetMenuExitBackButton(h_menu, true);
	
	AddTargetsToMenu2(h_menu, 0, COMMAND_FILTER_NO_BOTS);
	
	DisplayMenu(h_menu, i_client, MENU_TIME_FOREVER);
}

public MenuHandler_UnGagMenu(Handle h_menu, MenuAction i_action, int i_param1, int i_param2)
{
	switch (i_action)
	{
		case MenuAction_End:
		{
			CloseHandle(h_menu);
		}
		case MenuAction_Select:
		{
			char s_info[32];
			int i_target;
			
			GetMenuItem(h_menu, i_param2, s_info, sizeof(s_info));
			int i_userid = StringToInt(s_info);

			if ((i_target = GetClientOfUserId(i_userid)) == 0)
			{
				PrintToChat(i_param1, "[SM] %t", "sg_menu_cant_target");
			}
			else
			{
				PrintToChat(i_param1, "[SM] %t", "sug_menu_ungagged", i_target);
				gb_gagged[i_param1][i_target] = false;
			}
		}
	}
}


public Action Callback_OnSayText2(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	if (gb_gagged[GET_RECIPIENT(players)][GET_SENDER(msg)])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
