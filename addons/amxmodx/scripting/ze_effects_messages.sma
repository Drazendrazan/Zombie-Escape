#include <zombie_escape>

// Task ID.
#define TASK_MESSAGE 2030

// Enums (Ranks)
enum _:RANKS
{
	RANK_NONE = 0,
	RANK_FIRST,
	RANK_SECOND,
	RANK_THIRD
}

// Colors
enum _:COLORS
{
	Red = 0,
	Green,
	Blue
}

// Global Variables.
new g_iSpeedRank,
	g_iInfectionMsg,
	g_iRankMode,
	g_iInfectColors[COLORS],
	g_iRankColors[COLORS],
	g_iLeaderGlowColors[COLORS],
	g_iEscapeRank[RANKS],
	bool:g_bInfectNotice,
	bool:g_bLeaderGlow,
	bool:g_bLeaderGlowRandom,
	bool:g_bHideRankHud[MAX_PLAYERS+1],
	bool:g_bGlowRendering[MAX_PLAYERS+1],
	bool:g_bStopRendering[MAX_PLAYERS+1],
	Float:g_flMaxVelocity,
	Float:g_flEscapePoints[MAX_PLAYERS+1]

// Forward allows registering natives.
public plugin_natives()
{
	register_native("ze_get_escape_leader_id", "native_ze_get_escape_leader_id", 1)
	register_native("ze_stop_mod_rendering", "native_ze_stop_mod_rendering", 1)
	register_native("ze_show_user_rankhud", "native_show_user_rankhud", 1)
	register_native("ze_hide_user_rankhud", "native_hide_user_rankhud", 1)
}

// Forward called after server activation.
public plugin_init()
{
	// Load plugin.
	register_plugin("[ZE] Messages", ZE_VERSION, AUTHORS, ZE_HOMEURL, "Infection notice and Leader/Rank/Damage mode")
	
	// Create new CVars and Store automatically new value in CVars when changed.
	bind_pcvar_num(create_cvar("ze_enable_infect_notice", "1"), g_bInfectNotice)
	bind_pcvar_num(create_cvar("ze_infect_notice_red", "255"), g_iInfectColors[Red])
	bind_pcvar_num(create_cvar("ze_infect_notice_green", "0"), g_iInfectColors[Green])
	bind_pcvar_num(create_cvar("ze_infect_notice_blue", "0"), g_iInfectColors[Blue])
	bind_pcvar_num(create_cvar("ze_speed_rank_mode", "1"), g_iRankMode)
	bind_pcvar_num(create_cvar("ze_speed_rank_red", "0"), g_iRankColors[Red])
	bind_pcvar_num(create_cvar("ze_speed_rank_green", "255"), g_iRankColors[Green])
	bind_pcvar_num(create_cvar("ze_speed_rank_blue", "0"), g_iRankColors[Blue])
	bind_pcvar_num(create_cvar("ze_leader_glow", "1"), g_bLeaderGlow)
	bind_pcvar_num(create_cvar("ze_leader_random_color", "1"), g_bLeaderGlowRandom)
	bind_pcvar_num(create_cvar("ze_leader_glow_red", "255"), g_iLeaderGlowColors[Red])
	bind_pcvar_num(create_cvar("ze_leader_glow_green", "0"), g_iLeaderGlowColors[Green])
	bind_pcvar_num(create_cvar("ze_leader_glow_blue", "0"), g_iLeaderGlowColors[Blue])
	bind_pcvar_num(get_cvar_pointer("sv_maxvelocity"), g_flMaxVelocity)
	
	// Messages
	g_iSpeedRank = CreateHudSyncObj()
	g_iInfectionMsg = CreateHudSyncObj()
}

// Forward called before game started.
public ze_game_started_pre()
{
	// We're used this in ze_game_started_pre(), Because if we put it in ze_gamestarted()
	// When prevent the ze_game_started() forward from ze_game_started_pre(), The task is never removed.	
	remove_task(TASK_MESSAGE)

	// Reset Array's.
	arrayset(g_iEscapeRank, 0, sizeof(g_iEscapeRank))
	arrayset(g_flEscapePoints, 0.0, sizeof(g_flEscapePoints))
}

// Forward called after player humanized.
public ze_user_humanized(id)
{
	// Reset player Escape Points.
	g_flEscapePoints[id] = 0.0
	
	// Remove human Leader Glow when humanized.
	if (g_bLeaderGlow && (g_iEscapeRank[RANK_FIRST] == id) && g_bGlowRendering[id])
	{
		// Unset player glow rendering.
		Set_Rendering(id)
	}
}

// Forward called after player infected.
public ze_user_infected(iVictim, iInfector)
{		
	// Infection notice enabled?
	if (g_bInfectNotice && (iInfector != 0))
	{
		// Local Variables.
		new szVictimName[MAX_NAME_LENGTH], szAttackerName[MAX_NAME_LENGTH]

		// Get name of Victim and Infector.
		get_user_name(iVictim, szVictimName, charsmax(szVictimName))
		get_user_name(iInfector, szAttackerName, charsmax(szAttackerName))

		// Show colored HUD for all players.
		set_hudmessage(g_iInfectColors[Red], g_iInfectColors[Green], g_iInfectColors[Blue], 0.05, 0.45, 1, 0.0, 6.0, 0.0, 0.0)
		ShowSyncHudMsg(0, g_iInfectionMsg, "%L", LANG_PLAYER, "INFECTION_NOTICE", szAttackerName, szVictimName)
	}

	// Remove human Leader Glow when infected.
	if (g_bLeaderGlow && (g_iEscapeRank[RANK_FIRST] == iVictim) && g_bGlowRendering[iVictim])
	{
		// Unset player glow rendering.
		Set_Rendering(iVictim)
		g_bGlowRendering[iVictim] = false
	}

	// Adding Infection icon on Victim Screen
	InfectionIcon(iVictim)
}

// Forward called when zombies appear.
public ze_zombie_appear()
{
	// New task for Show message for player (0.5s for reduce CPU usage).
	set_task(0.5, "Show_Message", TASK_MESSAGE, "", 0, "b")
}

public Show_Message(iTask)
{
	// Static's
	static Float:vVelocity[3], iPlayers[MAX_PLAYERS], iAliveCount, iNum, id

	// Get index of all alive players.
	get_players(iPlayers, iAliveCount, "a")

	for (iNum = 0; iNum < iAliveCount; iNum++)
	{
		// Get player id.
		id = iPlayers[iNum]

		// Get velocity of player.
		get_entvar(id, var_velocity, vVelocity)
			
		/* Convert Velocity to Points (Reduce use high value in Variable, Because Variable has limits).
		And I see this best way to get points from Velocity of player */
		g_flEscapePoints[id] += vector_length(vVelocity) / g_flMaxVelocity
			
		// Show HUDs for player.
		if (!g_bHideRankHud[id])
		{
			Show_Speed_Message(id)
		}
	}

	// Leader glow enabled?
	if (g_bLeaderGlow)
	{
		// Set glow for Leader.
		for (iNum = 0; iNum < iAliveCount; iNum++)
		{
			// Get player id.
			id = iPlayers[iNum]

			// Glow rendering disabled?
			if (g_bStopRendering[id])
				continue

			// Player ins't Human or Rendering stopped?
			if (ze_is_user_zombie_ex(id))
				continue

			// Player in Rank First?
			if (g_iEscapeRank[RANK_FIRST] == id) // The Leader id
			{
				// Random glow colors disabled?
				if (!g_bLeaderGlowRandom)
				{
					// Player has glow rendering?
					if (!g_bGlowRendering[id])
					{
						// Set player glow rendering
						g_bGlowRendering[id] = true
						Set_Rendering(id, kRenderFxGlowShell, g_iRankColors[Red], g_iRankColors[Green], g_iRankColors[Blue], kRenderNormal, 20)						
					}
				}
				else // Random glow enabled.
				{
					// Player has glow rendering?
					if (!g_bGlowRendering[id])
					{
						// Set player glow rendering
						g_bGlowRendering[id] = true
						Set_Rendering(id, kRenderFxGlowShell, random(256), random(256), random(256), kRenderNormal, 20)						
					}
				}		
			}
			else
			{
				// Player has glow rendering?
				if (g_bGlowRendering[id])
				{
					// Remove player colored glow.
					Set_Rendering(id)
					g_bGlowRendering[id] = false
				}			
			}
		}
	}
}

public Show_Speed_Message(id)
{
	// Rank mode.
	switch (g_iRankMode)
	{
		case 1: // Leader Mode
		{
			// Static's
			static szLeader[MAX_NAME_LENGTH], iLeaderID

			// Find highest points.
			Speed_Stats()

			// Get player id in Rank First.
			iLeaderID = g_iEscapeRank[RANK_FIRST]
			
			if (is_user_alive(iLeaderID) && !ze_is_user_zombie_ex(iLeaderID) && g_flEscapePoints[iLeaderID] != 0.0)
			{
				// Get name of player.
				get_user_name(iLeaderID, szLeader, charsmax(szLeader))
				
				// Show HUD for all players.
				set_hudmessage(g_iLeaderGlowColors[Red], g_iLeaderGlowColors[Green], g_iLeaderGlowColors[Blue], 0.015,  0.18, 0, 0.2, 0.4, 0.09, 0.09)
				ShowSyncHudMsg(id, g_iSpeedRank, "%L", LANG_PLAYER, "RANK_INFO_LEADER", szLeader)
			}
			else
			{
				// Show HUD for all players.
				formatex(szLeader, charsmax(szLeader), "%L", LANG_PLAYER, "RANK_INFO_NONE")
				set_hudmessage(g_iLeaderGlowColors[Red], g_iLeaderGlowColors[Green], g_iLeaderGlowColors[Blue], 0.015,  0.18, 0, 0.2, 0.4, 0.09, 0.09)
				ShowSyncHudMsg(id, g_iSpeedRank, "%L", LANG_PLAYER, "RANK_INFO_LEADER", szLeader)
			}
		}
		case 2: // Rank Mode
		{
			// Static's
			static szFirst[MAX_NAME_LENGTH], szSecond[MAX_NAME_LENGTH], szThird[MAX_NAME_LENGTH], iFirstID, iSecondID, iThirdID
			
			// Find highest points.
			Speed_Stats()
			 
			// Players index.
			iFirstID 	= g_iEscapeRank[RANK_FIRST]
			iSecondID	= g_iEscapeRank[RANK_SECOND]
			iThirdID 	= g_iEscapeRank[RANK_THIRD]
			
			// Player is alive and is Human?
			if (is_user_alive(iFirstID) && !ze_is_user_zombie_ex(iFirstID) && g_flEscapePoints[iFirstID] != 0.0)
				get_user_name(iFirstID, szFirst, charsmax(szFirst)) // Get name of first player.
			else
				formatex(szFirst, charsmax(szFirst), "%L", LANG_PLAYER, "RANK_INFO_NONE")
			
			// Player is alive and is Human?
			if (is_user_alive(iSecondID) && !ze_is_user_zombie_ex(iSecondID) && g_flEscapePoints[iSecondID] != 0.0)				
				get_user_name(iSecondID, szSecond, charsmax(szSecond)) // Get name of second player.
			else
				formatex(szSecond, charsmax(szSecond), "%L", LANG_PLAYER, "RANK_INFO_NONE")
			
			// Player is alive and is Human?
			if (is_user_alive(iThirdID) && !ze_is_user_zombie_ex(iThirdID) && g_flEscapePoints[iThirdID] != 0.0)		
				get_user_name(iThirdID, szThird, charsmax(szThird)) // Get name of third player.
			else
				formatex(szThird, charsmax(szThird), "%L", LANG_PLAYER, "RANK_INFO_NONE")
			
			// Show HUD for player.
			set_hudmessage(g_iRankColors[Red], g_iRankColors[Green], g_iRankColors[Blue], 0.015,  0.18, 0, 0.2, 0.4, 0.09, 0.09)
			ShowSyncHudMsg(id, g_iSpeedRank, "%L", LANG_PLAYER, "RANK_INFO", szFirst, szSecond, szThird)
		}
	}
}

/**
 * Private Function:
 */
Speed_Stats()
{
	// Static's
	static iPlayers[MAX_PLAYERS], iAliveCount, Float:flHighest, iCurID, id

	// Get index of alive players.
	get_players(iPlayers, iAliveCount, "a")

	// Reset static.
	iCurID = 0
	flHighest = 0.0
	
	// First Rank.
	for (id = 0; id < iAliveCount; id++)
	{
		// Player ins't Human?
		if(ze_is_user_zombie_ex(id))
			continue
			
		// Find player has highest point?
		if(g_flEscapePoints[id] > flHighest)
		{
			// Store the player id in Buffer.
			iCurID = id

			// Store the player escapes point in Buffer
			flHighest = g_flEscapePoints[id]
		}
	}
	
	// Store the player index in Rank First.
	g_iEscapeRank[RANK_FIRST] = iCurID
	
	if (g_iRankMode == 2)
	{
		// Reset static.
		iCurID = 0
		flHighest = 0.0
		
		// Second Rank.
		for (id = 0; id < iAliveCount; id++)
		{
			// Player ins't Human?
			if(ze_is_user_zombie_ex(id))
				continue
			
			// Ignore player in Rank First!
			if (g_iEscapeRank[RANK_FIRST] == id)
				continue
				
			// Find second player has highest point?
			if(g_flEscapePoints[id] > flHighest)
			{
				// Store the player id in Buffer.
				iCurID = id

				// Store the player escapes point in Buffer
				flHighest = g_flEscapePoints[id]
			}
		}
		
		// Store the player index in Second Rank.
		g_iEscapeRank[RANK_SECOND] = iCurID		
		
		// Reset static.
		iCurID = 0
		flHighest = 0.0
		
		// Third Rank.
		for (id = 0; id < iAliveCount; id++)
		{
			// Player ins't Human?
			if(ze_is_user_zombie_ex(id))
				continue
			
			// Ignore player in Rank First or Rank Second?
			if(g_iEscapeRank[RANK_FIRST] == id || g_iEscapeRank[RANK_SECOND] == id)
				continue
				
			// Find third player has highest point? 
			if(g_flEscapePoints[id] > flHighest)
			{
				// Store the player id in Buffer.
				iCurID = id

				// Store the player escapes point in Buffer.
				flHighest = g_flEscapePoints[id]
			}
		}
		
		// Store the player index in Third Rank.
		g_iEscapeRank[RANK_THIRD] = iCurID		
	}	
}

/**
 * Functions of natives:
 */
public native_ze_get_escape_leader_id()
{
	return g_iEscapeRank[RANK_FIRST]
}

public native_ze_stop_mod_rendering(id, bool:bSet)
{
	// Player not found?
	if (is_user_connected(id))
	{
		g_bStopRendering[id] = bSet
		return true
    }
	
	return false
}

public native_show_user_rankhud(id)
{
	// Player not found?
	if (!is_user_connected(id))
		return false

	// HUD is already appear?
	if (!g_bHideRankHud[id])
		return true
	
	// Show player HUD.
	g_bHideRankHud[id] = false
	return true
}

public native_hide_user_rankhud(id)
{
	// Player not found?
	if (!is_user_connected(id))
		return false
	
	// HUD is already hidden?
	if (g_bHideRankHud[id])
		return true

	// Hide player HUD.
	g_bHideRankHud[id] = true
	return true
}