#include <zombie_escape>

// Fowards
enum _:TOTAL_FORWARDS
{
	FORWARD_RESULT = 0,
	FORWARD_ROUNDEND,
	FORWARD_HUMANIZED_PRE,
	FORWARD_HUMANIZED,
	FORWARD_SPAWN_POST,
	FORWARD_PRE_INFECTED,
	FORWARD_INFECTED,
	FORWARD_GAME_STARTED_PRE,
	FORWARD_GAME_STARTED,
	FORWARD_LAST_HUMAN,
	FORWARD_LAST_ZOMBIE,
	FORWARD_DISCONNECT
}

// Tasks IDs
enum
{
	TASK_SCORE_MESSAGE = 1100,
	ROUND_TIME_LEFT
}

// Colors (g_pCvarColors[] array indexes)
enum _:COLORS
{
	Red = 0,
	Green,
	Blue
}

// Variables
new g_iXVarId,
	g_iRoundTime,
	g_iHumansScore, 
	g_iZombiesScore, 
	g_iRoundNum,
	g_iLastHuman,
	g_iLastZombie,
	g_iFreezeTime,
	g_iRequiredPlayers,
	g_iScoreMessageType,
	g_iScoreMessageColors[COLORS],
	g_iWinMessageType,
	g_iHumanHealth,
	g_iHumanGravity,
	g_iZombieHealth,
	g_iZombieGravity,
	g_iRoundTimeLeft,
	g_iPainShockFree,
	g_iForwards[TOTAL_FORWARDS],
	g_iHSpeedFactor[MAX_PLAYERS+1],
	g_iZSpeedSet[MAX_PLAYERS+1],
	g_iUserGravity[MAX_PLAYERS+1],
	bool:g_bGameStarted, 
	bool:g_bSkullGreenColor,
	bool:g_bIsRoundEnding,
	bool:g_bIsZombie[MAX_PLAYERS+1],  
	bool:g_bHSpeedUsed[MAX_PLAYERS+1], 
	bool:g_bZSpeedUsed[MAX_PLAYERS+1],
	bool:g_bIsGravityUsed[MAX_PLAYERS+1],
	bool:g_bRespawnAsZombie[MAX_PLAYERS+1],
	Float:g_flReferenceTime,
	Float:g_flZombieSpeed,
	Float:g_flHumanSpeedFactor,
	Float:g_flRoundEndDelay

// Public Variable (XVar).
public xvar_GameMode

// Forward allows register new natives.
public plugin_natives()
{
	register_native("ze_is_user_zombie", "native_ze_is_user_zombie", 1)
	register_native("ze_is_user_zombie_ex", "native_ze_is_user_zombie_ex", 1)
	register_native("ze_is_game_started", "native_ze_is_game_started", 1)
	
	register_native("ze_get_round_number", "native_ze_get_round_number", 1)
	register_native("ze_get_humans_number", "native_ze_get_humans_number", 1)
	register_native("ze_get_zombies_number", "native_ze_get_zombies_number", 1)
	
	register_native("ze_set_user_zombie", "native_ze_set_user_zombie", 1)
	register_native("ze_set_user_human", "native_ze_set_user_human", 1)
	register_native("ze_set_user_zombie_ex", "native_ze_set_user_zombie_ex", 1)

	register_native("ze_set_human_speed_factor", "native_ze_set_human_speed_factor", 1)
	register_native("ze_set_zombie_speed", "native_ze_set_zombie_speed", 1)
	
	register_native("ze_reset_human_speed", "native_ze_reset_human_speed", 1)
	register_native("ze_reset_zombie_speed", "native_ze_reset_zombie_speed", 1)
	
	register_native("ze_set_user_gravity", "native_ze_set_user_gravity", 1)
	register_native("ze_reset_user_gravity", "native_ze_reset_user_gravity", 1)

	register_native("ze_allow_respawn_as_zombie", "native_ze_allow_respawn_as_zombie", 1)
	register_native("ze_disallow_respawn_as_zombie", "native_ze_disallow_respawn_as_zombie", 1)

	register_native("ze_get_last_human", "native_get_last_human", 1)
	register_native("ze_get_last_zombie", "native_get_last_zombie", 1)

	register_native("ze_is_user_last_human", "native_is_user_last_human", 1)
	register_native("ze_is_user_last_zombie", "native_is_user_last_zombie", 1)
}

// Forward called after server activation.
public plugin_init()
{
	// Load plug-in.
	register_plugin("[ZE] Core/Engine", ZE_VERSION, AUTHORS, ZE_HOMEURL, "Zombie Escape APIs")
	
	// Hook Chains.
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "Fw_TraceAttack_Pre", 0)
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "Fw_TakeDamage_Post", 1)
	RegisterHookChain(RG_CBasePlayer_Spawn, "Fw_PlayerSpawn_Post", 1)
	RegisterHookChain(RG_CSGameRules_CheckWinConditions, "Fw_CheckMapConditions_Post", 1)
	RegisterHookChain(RG_CBasePlayer_Killed, "Fw_PlayerKilled_Post", 1)
	RegisterHookChain(RG_RoundEnd, "Event_RoundEnd_Pre", 0)
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "Fw_RestMaxSpeed_Post", 1)
	RegisterHookChain(RG_HandleMenu_ChooseTeam, "Fw_HandleMenu_ChooseTeam_Post", 1)
	
	// Events.
	register_event("HLTV", "New_Round", "a", "1=0", "2=0")
	register_event("TextMsg", "Map_Restart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in", "2=#Round_Draw")
	register_logevent("Round_Start", 2, "1=Round_Start")
	register_logevent("Round_End", 2, "1=Round_End")
	
	// Create Forwards
	g_iForwards[FORWARD_ROUNDEND] = CreateMultiForward("ze_roundend", ET_IGNORE, FP_CELL)
	g_iForwards[FORWARD_HUMANIZED_PRE] = CreateMultiForward("ze_user_humanized_pre", ET_CONTINUE, FP_CELL)
	g_iForwards[FORWARD_HUMANIZED] = CreateMultiForward("ze_user_humanized", ET_IGNORE, FP_CELL)
	g_iForwards[FORWARD_PRE_INFECTED] = CreateMultiForward("ze_user_infected_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	g_iForwards[FORWARD_INFECTED] = CreateMultiForward("ze_user_infected", ET_IGNORE, FP_CELL, FP_CELL)
	g_iForwards[FORWARD_GAME_STARTED_PRE] = CreateMultiForward("ze_game_started_pre", ET_CONTINUE)
	g_iForwards[FORWARD_GAME_STARTED] = CreateMultiForward("ze_game_started", ET_IGNORE)
	g_iForwards[FORWARD_DISCONNECT] = CreateMultiForward("ze_player_disconnect", ET_CONTINUE, FP_CELL)
	g_iForwards[FORWARD_SPAWN_POST] = CreateMultiForward("ze_player_spawn_post", ET_IGNORE, FP_CELL)
	g_iForwards[FORWARD_LAST_HUMAN] = CreateMultiForward("ze_user_last_human", ET_IGNORE, FP_CELL)
	g_iForwards[FORWARD_LAST_ZOMBIE] = CreateMultiForward("ze_user_last_zombie", ET_IGNORE, FP_CELL)
	
	// Registering Messages
	register_message(get_user_msgid("TeamScore"), "Message_Teamscore")
	
	// Sequential files (.txt)
	register_dictionary("zombie_escape.txt")
	
	// Create new CVars.
	new pCvar_flZombieSpeed = create_cvar("ze_zombie_speed", "350.0")
	new pCvar_iFreezeTime = create_cvar("ze_freeze_time", "20")
	new pCvar_iRoundTime = create_cvar("ze_round_time", "9.0")
	new pCvar_iReqPlayers = create_cvar("ze_required_players", "2")

	// Create new CVars and Bind CVars (Store automatically new value in Global Variables).
	bind_pcvar_num(pCvar_iFreezeTime, g_iFreezeTime)
	bind_pcvar_num(pCvar_iRoundTime, g_iRoundTime)
	bind_pcvar_num(create_cvar("ze_human_health", "1000"), g_iHumanHealth)
	bind_pcvar_num(create_cvar("ze_human_gravity", "800"), g_iHumanGravity)
	bind_pcvar_float(create_cvar("ze_human_speed_factor", "20.0"), g_flHumanSpeedFactor)
	bind_pcvar_num(create_cvar("ze_zombie_health", "10000"), g_iZombieHealth)
	bind_pcvar_num(create_cvar("ze_zombie_gravity", "640"), g_iZombieGravity)
	bind_pcvar_float(pCvar_flZombieSpeed, g_flZombieSpeed)
	bind_pcvar_num(pCvar_iReqPlayers, g_iRequiredPlayers)
	bind_pcvar_num(create_cvar("ze_score_message_type", "1"), g_iScoreMessageType)
	bind_pcvar_num(create_cvar("ze_score_message_red", "200"), g_iScoreMessageColors[Red])
	bind_pcvar_num(create_cvar("ze_score_message_green", "100"), g_iScoreMessageColors[Green])
	bind_pcvar_num(create_cvar("ze_score_message_blue", "0"), g_iScoreMessageColors[Blue])
	bind_pcvar_float(create_cvar("ze_round_end_delay", "5.0"), g_flRoundEndDelay)
	bind_pcvar_num(create_cvar("ze_winmessage_type", "0"), g_iWinMessageType)
	bind_pcvar_num(create_cvar("ze_deathmsg_skull", "0"), g_bSkullGreenColor)
	bind_pcvar_num(create_cvar("ze_painshockfree", "1"), g_iPainShockFree)

	// Hooks CVars.
	hook_cvar_change(pCvar_iFreezeTime, "fw_CVarFreezeTime")
	hook_cvar_change(pCvar_iRoundTime, "fw_CVarRoundTime")
	hook_cvar_change(pCvar_iReqPlayers, "fw_CVarReqPlayers")

	// Check Round Time to Terminate it
	set_task(1.0, "Check_RoundTimeleft", ROUND_TIME_LEFT, _, _, "b")

	// Default Values.
	g_iXVarId = get_xvar_id("xvar_GameMode")
}

// Hook called when change the value in ze_freeze_time.
public fw_CVarFreezeTime(pCvar, const szOldVal[], const szNewVal[])
{
	// Replace value in mp_freezetime.
	set_cvar_string("mp_freezetime", szNewVal)
}

// Hook called when change the value in ze_round_time.
public fw_CVarRoundTime(pCvar, const szOldVal[], const szNewVal[])
{
	// Replace value in mp_roundtime.
	set_cvar_string("mp_roundtime", szNewVal)
}

// Hook called when change the value in ze_required_players.
public fw_CVarReqPlayers(pCvar, const szOldVal[], const szNewVal[])
{
	// Game not started yet?
	if (g_bGameStarted)
		set_task(0.1, "Check_AlivePlayers")
	else // Game already started?
		set_task(0.1, "Check_AllPlayersNumber")
}

// Forward called after init.
public plugin_cfg()
{
	// Get our configiration file and Execute it
	new szCfgDir[32]
	get_localinfo("amxx_configsdir", szCfgDir, charsmax(szCfgDir))
	server_cmd("exec %s/zombie_escape.cfg", szCfgDir)
	
	// Set Game Name
	new szGameName[MAX_NAME_LENGTH]
	formatex(szGameName, sizeof(szGameName), "Zombie Escape v%s", ZE_VERSION)
	set_member_game(m_GameDesc, szGameName)
	
	// Mod version.
	set_pcvar_string(create_cvar("ze_version", ZE_VERSION, FCVAR_SERVER|FCVAR_SPONLY), ZE_VERSION)

	// Delay before update value on game CVar's.
	set_task(1.0, "delayUpdateCVar")
}

public delayUpdateCVar() {
	// Replace CVars values.
	set_cvar_num("mp_roundtime", g_iRoundTime)
	set_cvar_num("mp_freezetime", g_iFreezeTime)
	set_cvar_float("sv_maxspeed", g_flZombieSpeed)	
}

public Fw_CheckMapConditions_Post()
{
	// Block Game Commencing
	set_member_game(m_bGameStarted, true)
	
	// Set Freeze Time
	set_member_game(m_iIntroRoundTime, g_iFreezeTime)
	
	// Set Round Time
	set_member_game(m_iRoundTime, floatround(g_iRoundTime * 60.0))
}

// Hook called after player killed.
public Fw_PlayerKilled_Post(id)
{
	// Check last Player.
	checkLastPlayer()

	// Nobody alive?
	if (!GetAlivePlayersNum(CS_TEAM_T) && !GetAlivePlayersNum(CS_TEAM_CT))
	{
		// No Winner, All Players in one team killed Or Both teams Killed
		client_print(0, print_center, "%L", LANG_PLAYER, "NO_WINNER")
	}
}

// Hook called after reset max speed of the player.
public Fw_RestMaxSpeed_Post(id)
{
	// Player is not Alive?
	if (!is_user_alive(id))
		return HC_CONTINUE // Prevent execute rest of codes.

	// Get a current maxspeed of player.
	static Float:flMaxSpeed
	get_entvar(id, var_maxspeed, flMaxSpeed)

	// Player is Alive and not Frozen?
	if (flMaxSpeed != 1.0)
	{
		// Player is Human?
		if (!g_bIsZombie[id])
		{		
			// Check Human has custom speed factor?
			if (g_bHSpeedUsed[id])
			{
				// Set New Human Speed Factor
				set_entvar(id, var_maxspeed, flMaxSpeed + float(g_iHSpeedFactor[id]))
				return HC_CONTINUE // Prevent execute rest of codes.
			}
				
			// Set Human Speed Factor, native not used
			set_entvar(id, var_maxspeed, (flMaxSpeed + g_flHumanSpeedFactor))
			return HC_CONTINUE // Prevent execute rest of codes.
		}
		else // Zombie.
		{
			// Check Zombie has custom Speed?
			if (g_bZSpeedUsed[id])
			{
				// Set Zombie speed from native.
				set_entvar(id, var_maxspeed, float(g_iZSpeedSet[id]))
				return HC_CONTINUE // Prevent execute rest of codes.
			}

			// Set Zombie maxspeed from CVar.
			set_entvar(id, var_maxspeed, g_flZombieSpeed)
			return HC_CONTINUE // Prevent execute rest of codes.
		}		
	}
	
	// Prevent resetting player maxspeed.
	return HC_SUPERCEDE
}

public Fw_PlayerSpawn_Post(id)
{	
	// Execute forward ze_player_spawn_post(id).
	ExecuteForward(g_iForwards[FORWARD_SPAWN_POST], _/* Ignore return value */, id)

	if (!g_bGameStarted)
	{
		// Force All player to be Humans if Game not started yet
		rg_set_user_team(id, TEAM_CT, MODEL_UNASSIGNED)
	}
	else
	{
		if (!g_bRespawnAsZombie[id])
		{
			// Respawn him as human.
			Set_User_Human(id)
		}
		else
		{
			// Respawn him as zombie
			Set_User_Zombie(id)
		}

		// Reset Variable.
		g_bRespawnAsZombie[id] = false
	}
}

public New_Round()
{
	// Remove All tasks in the New Round
	remove_task(TASK_SCORE_MESSAGE)
	
	if (g_bGameStarted)
	{
		g_iRoundNum++
	}
	
	// Execute forward ze_game_started_pre() and get return value.
	ExecuteForward(g_iForwards[FORWARD_GAME_STARTED_PRE], g_iForwards[FORWARD_RESULT])
	
	// Forward has return value 1 or above?
	if (g_iForwards[FORWARD_RESULT] >= ZE_STOP)
		return
	
	// New task for Score Message.
	set_task(10.0, "Score_Message", TASK_SCORE_MESSAGE, "", 0, "b")
	
	if (!g_bGameStarted)
	{
		// No Enough Players
		ze_colored_print(0, "%L", LANG_PLAYER, "NO_ENOUGH_PLAYERS", g_iRequiredPlayers)
		return // Block the execution of the blew code 
	}
	
	// Print colored message on chat for all players.
	ze_colored_print(0, "%L", LANG_PLAYER, "READY_TO_RUN")

	// Execute forward ze_game_started()
	ExecuteForward(g_iForwards[FORWARD_GAME_STARTED])
	
	// Round Starting
	g_bIsRoundEnding = false
}

// Score Message Task
public Score_Message(TaskID)
{
	// If value is 0, there is nothing to do for this case this means CVAR is disabled
	switch (g_iScoreMessageType)
	{
		case 1: // DHUD
		{
			set_dhudmessage(g_iScoreMessageColors[Red], g_iScoreMessageColors[Green], g_iScoreMessageColors[Blue], -1.0, 0.01, 0, 0.0, 9.0)
			show_dhudmessage(0, "%L", LANG_PLAYER, "SCORE_MESSAGE", g_iZombiesScore, g_iHumansScore)
		}
		case 2: // HUD
		{
			set_hudmessage(g_iScoreMessageColors[Red], g_iScoreMessageColors[Green], g_iScoreMessageColors[Blue], -1.0, 0.01, 0, 0.0, 9.0)
			show_hudmessage(0, "%L", LANG_PLAYER, "SCORE_MESSAGE", g_iZombiesScore, g_iHumansScore)
		}
	}
}

public Fw_TraceAttack_Pre(iVictim, iAttacker, Float:flDamage, Float:flDirection[3], iTracehandle, bitsDamageType)
{
	// Invalid player?
	if (iVictim == iAttacker || !is_user_connected(iVictim) || !is_user_connected(iAttacker))
		return HC_CONTINUE // Prevent execute rest of codes and continue Trace attack.
	
	// Attacker and Victim is in same teams? Skip code blew
	if (get_user_team(iAttacker) == get_user_team(iVictim))
		return HC_CONTINUE // Prevent execute rest of codes and continue Trace attack.
	
	// Round has over?
	if (g_bIsRoundEnding)
		return HC_SUPERCEDE // Prevent executre rest of codes and prevent Trace attack.

	// Check attacker is Zombie?
	if (g_bIsZombie[iAttacker])
	{		
		// If return FALSE in this function, Prevent Trace attack. 
		if (!Set_User_Zombie(iVictim, iAttacker, flDamage))
			return HC_SUPERCEDE // Prevent Trace attack.
		
		// Check if this is Last Human
		if (!GetAlivePlayersNum(CS_TEAM_CT))
		{						
			// Finish the round and make Zombies are winners and update Zombies score and show message Win.
			finish_Round(ZE_TEAM_ZOMBIE)
		}
	}

	return HC_CONTINUE // Continue Trace attack.
}

public Fw_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:flDamage, bitsDamageType)
{
	// Not Vaild Victim or Attacker so skip the event (Important to block out bounds errors)
	if (!is_user_connected(iVictim) || !is_user_connected(iAttacker))
		return
	
	switch (g_iPainShockFree)
	{
		case 1: // Zombies only?
			// Player is Zombie?
			if (g_bIsZombie[iVictim]) set_member(iVictim, m_flVelocityModifier, 1.0)
		case 2: // Humans only?
			// Player is Human?
			if (!g_bIsZombie[iVictim]) set_member(iVictim, m_flVelocityModifier, 1.0)
		case 3: // Both?
			set_member(iVictim, m_flVelocityModifier, 1.0)
	}
}

// Hook called after round over.
public Round_End()
{
	// Check round is already ended?
	if (g_bIsRoundEnding || !g_bGameStarted)
		return // Prevent execute rest of codes.

	// Get the number of alive players (Humans and Zombies)
	new iAliveZombiesNum = GetAlivePlayersNum(CS_TEAM_T)
	new iAliveHumansNum  = GetAlivePlayersNum(CS_TEAM_CT)

	// Check all Zombies are died?
	if (iAliveHumansNum && !iAliveZombiesNum)
	{
		// Finish round and make Humans are winners.
		finish_Round(ZE_TEAM_HUMAN)
	}
	else if (!iAliveHumansNum && iAliveZombiesNum)
	{
		// Finish round and make Zombies are winners.
		finish_Round(ZE_TEAM_ZOMBIE)		
	}
}

public Event_RoundEnd_Pre(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
	// The two unhandeld cases by rg_round_end() native in our Mod
	if (event == ROUND_CTS_WIN || event == ROUND_TERRORISTS_WIN)
	{
		SetHookChainArg(3, ATYPE_FLOAT, g_flRoundEndDelay)
	}
}

public Round_Start()
{
    g_flReferenceTime = get_gametime()
    g_iRoundTimeLeft = get_member_game(m_iRoundTime)
}

public Check_RoundTimeleft()
{
	// Round has over?
	if (g_bIsRoundEnding)
		return // Prevent execute rest of codes.

	// Get round time left.
	static Float:flRoundTimeLeft;flRoundTimeLeft = (g_flReferenceTime + float(g_iRoundTimeLeft)) - get_gametime()
	
	// Round has over?
	if (!floatround(flRoundTimeLeft))
	{		
		// Finish round and make Zombies are winners and update Zombies score.
		finish_Round(ZE_TEAM_ZOMBIE)
	}
}

// Forward called when player disconnected from server.
public client_disconnected(id)
{
	// Reset speed for this dropped id
	g_bIsZombie[id] = false
	g_bHSpeedUsed[id] = false
	g_bZSpeedUsed[id] = false
	g_bIsGravityUsed[id] = false
	g_iUserGravity[id] = 0

	// Last player disconnected?
	if (g_iLastHuman == id) g_iLastHuman = 0
	if (g_iLastZombie == id) g_iLastZombie = 0
	
	// Check last player.
	checkLastPlayer()

	// Execute our disconnected forward
	ExecuteForward(g_iForwards[FORWARD_DISCONNECT], g_iForwards[FORWARD_RESULT], id)
	
	if (g_iForwards[FORWARD_RESULT] >= ZE_STOP)
		return
	
	// Delay Then Check Players to Terminate The round (Delay needed)
	set_task(0.1, "Check_AlivePlayers")
}

// This check done when player disconnect
public Check_AlivePlayers()
{	
	// Game Started? (There is at least 2 players Alive?)
	if (g_bGameStarted)
	{
		// Get number of Humans and Zombies.
		new iHumansNum 	= get_member_game(m_iNumCT)
		new iZombiesNum = get_member_game(m_iNumTerrorist)

		// Required players not found?
		if ((iHumansNum + iZombiesNum) < g_iRequiredPlayers)
		{
			// Stop game.
			g_bGameStarted = false
		}
		else
		{
			// Check game mode is started or not yet?
			if (get_xvar_num(g_iXVarId))
			{
				// All Zombies disconnected from the server?
				if (iHumansNum && !iZombiesNum)
				{
					// Finish round and make Humans winners.
					finish_Round(ZE_TEAM_HUMAN)
					return // Block execute rest of codes.
				}
				else if (!iHumansNum && iZombiesNum) // All Humans disconnected from the server?
				{
					// Finish round and make Zombie winners.
					finish_Round(ZE_TEAM_ZOMBIE)	
					return // Block execute rest of codes.			
				}

				// Get number of alive Humans and Zombies.
				new iAliveZombiesNum = GetAlivePlayersNum(CS_TEAM_T)
				new iAliveHumansNum  = GetAlivePlayersNum(CS_TEAM_CT)

				// There no alive Humans?
				if (iAliveHumansNum && !iAliveZombiesNum)
				{
					// Finish round and make Humans winners.
					finish_Round(ZE_TEAM_HUMAN)			
				}
				else if (!iAliveHumansNum && iAliveZombiesNum) // There no alive Zombies?
				{
					// Finish round and make Zombie winners.
					finish_Round(ZE_TEAM_ZOMBIE)	
				}				
			}
		}
	}
}

public client_putinserver(id)
{
	// Add Delay and Check Conditions To start the Game (Delay needed)
	set_task(1.0, "Check_AllPlayersNumber")
}

// Hook called after player choose team from Teams Menu.
public Fw_HandleMenu_ChooseTeam_Post(id, MenuChooseTeam:iSlot)
{
	// Player disconnected?
	if (!is_user_connected(id))
		return // Prevent execute rest of codes.

	// Check team chosen is Terrorists team or Auto Select?
	if ((iSlot == MenuChoose_T) || (iSlot == MenuChoose_AutoSelect))
		rg_set_user_team(id, TEAM_CT) // Switch player to CTs team.
	
	// Add Delay and Check Conditions To start the Game (Delay needed)
	set_task(1.0, "Check_AllPlayersNumber")
}

public Check_AllPlayersNumber()
{
	// Game is already started?
	if (g_bGameStarted)
		return
	
	// Required players are exists?
	if (get_playersnum_ex() >= g_iRequiredPlayers)
	{
		// Start game.
		g_bGameStarted = true
		
		// Restart the game
		server_cmd("sv_restart 2")
		
		// Print Fake game Commencing Message
		client_print(0, print_center, "%L", LANG_PLAYER, "START_GAME")
	}
}

public Map_Restart()
{
	// Add Delay To help Rest Scores if player kill himself, and there no one else him so round draw (Delay needed)
	set_task(0.1, "Reset_Score_Message")

	// Execute forward ze_roundend(WinTeam).
	ExecuteForward(g_iForwards[FORWARD_ROUNDEND], _/* Ignore return value */, 0)
}

public Reset_Score_Message()
{
	g_iHumansScore = 0
	g_iZombiesScore = 0
	g_iRoundNum = 0
}

public Message_Teamscore()
{
	new szTeam[2]
	get_msg_arg_string(1, szTeam, charsmax(szTeam))
	
	switch (szTeam[0])
	{
		case 'C': set_msg_arg_int(2, ARG_BYTE, g_iHumansScore)
		case 'T': set_msg_arg_int(2, ARG_BYTE, g_iZombiesScore)
	}
}

public checkLastPlayer()
{
	new id = 0

	// Last human?
	if (GetAlivePlayersNum(CS_TEAM_CT) == 1)
	{
		for (id = 1; id <= MaxClients; id++)
		{
			// Player not found?
			if (!is_user_alive(id))
				continue

			// Player isn't Zombie?
			if (!g_bIsZombie[id])
			{
				// Store index of last Human in Global Variable.
				g_iLastHuman = id

				// Execute forward ze_user_last_human(id)
				ExecuteForward(g_iForwards[FORWARD_LAST_HUMAN], _/* Ignore return value */, id)
			}
		}
	}
	else
	{
		g_iLastHuman = 0
	}

	// Last zombie?
	if (GetAlivePlayersNum(CS_TEAM_T) == 1)
	{
		for (new id = 0; id <= MaxClients; id++)
		{
			// Player not found?
			if (!is_user_alive(id))
				continue

			// Player is Zombie?
			if (g_bIsZombie[id])
			{
				// Store index of last Zombie in Global Variable.
				g_iLastZombie = id
			
				// Execute forward ze_user_last_zombie(id)
				ExecuteForward(g_iForwards[FORWARD_LAST_ZOMBIE], _/* Ignore return value */, id)
			}
		}
	}
	else
	{
		g_iLastZombie = 0
	}
}

/**
 * Private functions:
 */
Set_User_Human(id)
{
	// Player not alive?
	if (!is_user_alive(id))
		return false
	
	// Execute forward ze_user_humanized_pre(id) and get return value.
	ExecuteForward(g_iForwards[FORWARD_HUMANIZED_PRE], g_iForwards[FORWARD_RESULT], id)

	// Forward has return value 1 or above?
	if (g_iForwards[FORWARD_RESULT] >= ZE_STOP)
		return false

	// Unset player Zombie flag.
	g_bIsZombie[id] = false

	// Set player custom health and gravity.
	set_entvar(id, var_health, float(g_iHumanHealth))
	set_entvar(id, var_gravity, float(g_bIsGravityUsed[id] ? g_iUserGravity[id]:g_iHumanGravity)/800.0)
	
	// Execute forward ze_user_humanized(id)
	ExecuteForward(g_iForwards[FORWARD_HUMANIZED], _/* Ignore return value */, id)
	
	// Player not from CTs team?
	if (TeamName:get_user_team(id) != TEAM_CT)
	{
		// Switch player to CTs team.
		rg_set_user_team(id, TEAM_CT, MODEL_UNASSIGNED)
	}

	// Check last Player.
	checkLastPlayer()
	return true
}

Set_User_Zombie(id, iAttacker = 0, Float:flDamage = 0.0)
{
	// Player not alive?
	if (!is_user_alive(id))
		return false
		
	// Execute pre-infection forward
	ExecuteForward(g_iForwards[FORWARD_PRE_INFECTED], g_iForwards[FORWARD_RESULT], id, iAttacker, floatround(flDamage))
	
	// Forward has return value 1 or above?
	if (g_iForwards[FORWARD_RESULT] >= ZE_STOP)
	{
		return false // Prevent execute rest of codes.
	}
	
	// Attacker is not server?
	if (iAttacker > 0)
	{
		// Death Message with Infection style, only if infection caused by player not server
		SendDeathMsg(iAttacker, id, g_bSkullGreenColor)

		// Fix dead attrib when send death message.
		FixDeadAttrib(id)
	}
	
	// Set player Zombie flag.
	g_bIsZombie[id] = true

	// Set player custom health and gravity
	set_entvar(id, var_health, float(g_iZombieHealth))
	set_entvar(id, var_gravity, float(g_bIsGravityUsed[id] ? g_iUserGravity[id] : (g_iZombieGravity))/800.0)

	// Remove player all weapons and items and him knife only.
	rg_remove_all_items(id)
	rg_give_item(id, "weapon_knife", GT_APPEND)

	// Execute forward ze_user_infected(iVictim, iInfector)
	ExecuteForward(g_iForwards[FORWARD_INFECTED], _/* Ignore return value */, id, iAttacker)
	
	// Player not from Terrorists team?
	if (TeamName:get_user_team(id) != TEAM_TERRORIST)
	{
		// Switch player to Terrorists team.
		rg_set_user_team(id, TEAM_TERRORIST, MODEL_UNASSIGNED)
	}
	
	// Check last Player.
	checkLastPlayer()
	return true
}

finish_Round(iTeam)
{
	// Round over.
	g_bIsRoundEnding = true

	// Choose team:
	switch (iTeam)
	{
		case ZE_TEAM_HUMAN: // Humans team.
		{
			// Execute forward ze_roundend(iWinTeam).
			ExecuteForward(g_iForwards[FORWARD_ROUNDEND], _/* No return value */, ZE_TEAM_HUMAN)

			// Finish the round, and make Humans are winners.
			rg_round_end(g_flRoundEndDelay, WINSTATUS_CTS, ROUND_CTS_WIN, "", "")

			// +1 in Humans score.
			g_iHumansScore++

			// Get HUD type of win message.
			switch (g_iWinMessageType)
			{
				case 0: // Normal Text print_center.
				{
					client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_SUCCESS")
				}
				case 1: // HUD
				{
					set_hudmessage(0, 100, 200, -1.0, 0.4, 1, g_flRoundEndDelay, g_flRoundEndDelay, 0.0, 0.0)
					show_hudmessage(0, "%L", LANG_PLAYER, "ESCAPE_SUCCESS")
				}
				case 2: // DHUD
				{
					set_dhudmessage(0, 100, 200, -1.0, 0.4, 1, g_flRoundEndDelay, g_flRoundEndDelay, 0.0, 0.0)
					show_dhudmessage(0, "%L", LANG_PLAYER, "ESCAPE_SUCCESS")				
				}
			}
		}
		case ZE_TEAM_ZOMBIE: // Zombies team.
		{
			// Execute forward ze_roundend(iWinTeam).
			ExecuteForward(g_iForwards[FORWARD_ROUNDEND], _/* No return value */, ZE_TEAM_ZOMBIE)

			// Finish the round, and make Humans are winners.
			rg_round_end(g_flRoundEndDelay, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN, "", "")

			// +1 in Humans score.
			g_iZombiesScore++

			// Get HUD type of win message.
			switch (g_iWinMessageType)
			{
				case 0: // Normal Text print_center.
				{
					client_print(0, print_center, "%L", LANG_PLAYER, "ESCAPE_FAIL")
				}
				case 1: // HUD
				{
					set_hudmessage(200, 0, 0, -1.0, 0.4, 1, g_flRoundEndDelay, g_flRoundEndDelay, 0.0, 0.0)
					show_hudmessage(0, "%L", LANG_PLAYER, "ESCAPE_FAIL")
				}
				case 2: // DHUD
				{
					set_dhudmessage(200, 0, 0, -1.0, 0.4, 1, g_flRoundEndDelay, g_flRoundEndDelay, 0.0, 0.0)
					show_dhudmessage(0, "%L", LANG_PLAYER, "ESCAPE_FAIL")				
				}
			}
		}
	}
}

/**
 * Functions of natives:
 */
public native_ze_is_user_zombie(id)
{
	if (!is_user_connected(id))
	{
		return -1;
	}
	
	return g_bIsZombie[id]
}

public native_ze_is_user_zombie_ex(id)
{
	// Player not found?
	if (!id || (id > MaxClients))
		return false

	return g_bIsZombie[id]
}

public native_ze_set_user_zombie(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	Set_User_Zombie(id)
	return true;
}

public native_ze_set_user_human(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	Set_User_Human(id)
	return true;
}

public native_ze_is_game_started()
{
	return g_bGameStarted
}

public native_ze_get_round_number()
{
	if (!g_bGameStarted)
	{
		return -1;
	}
	
	return g_iRoundNum
}

public native_ze_get_humans_number()
{
	return GetAlivePlayersNum(CsTeams:TEAM_CT)
}

public native_ze_get_zombies_number()
{
	return GetAlivePlayersNum(CsTeams:TEAM_TERRORIST)
}

public native_ze_set_human_speed_factor(id, iFactor)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	g_bHSpeedUsed[id] = true
	g_iHSpeedFactor[id] = iFactor
	rg_reset_maxspeed(id)
	return true;
}

public native_ze_reset_human_speed(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	g_bHSpeedUsed[id] = false
	rg_reset_maxspeed(id)
	return true;
}

public native_ze_set_zombie_speed(id, iSpeed)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	g_bZSpeedUsed[id] = true
	g_iZSpeedSet[id] = iSpeed
	rg_reset_maxspeed(id)
	return true;
}

public native_ze_reset_zombie_speed(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	g_bZSpeedUsed[id] = false
	rg_reset_maxspeed(id)
	return true;
}

public native_ze_set_user_gravity(id, iGravity)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false
	}
	
	g_bIsGravityUsed[id] = true
	g_iUserGravity[id] = iGravity
	set_entvar(id, var_gravity, float(iGravity) / 800.0)

	return true
}

public native_ze_reset_user_gravity(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false
	}

	g_bIsGravityUsed[id] = false
	set_entvar(id, var_gravity, float(g_bIsZombie[id] ? g_iZombieGravity : g_iHumanGravity) / 800.0)

	return true
}

public native_ze_set_user_zombie_ex(id, iInfector)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}

	// Infector not found?
	if (!iInfector || !is_user_connected(iInfector))
		return false;
	
	Set_User_Zombie(id, iInfector, 0.0)
	return true;
}

public native_ze_allow_respawn_as_zombie(id)
{
	// Player not found?
	if (!is_user_connected(id))
		return false

	g_bRespawnAsZombie[id] = true
	return true
}

public native_ze_disallow_respawn_as_zombie(id)
{
	// Player not found?
	if (!is_user_connected(id))
		return false

	g_bRespawnAsZombie[id] = false
	return true
}

public native_get_last_human()
{
	// Return true or false.
	return g_iLastHuman
}

public native_get_last_zombie()
{	
	// Return true or false.
	return g_iLastZombie
}

public bool:native_is_user_last_human(id)
{
	// Player not found or Is Zombie?
	if (!is_user_alive(id) || g_bIsZombie[id])
		return false
	
	// Return true or false.
	return (g_iLastHuman == id)
}

public bool:native_is_user_last_zombie(id)
{
	// Player not found or Is not Zombie?
	if (!is_user_alive(id) || !g_bIsZombie[id])
		return false
	
	// Return true or false.
	return (g_iLastZombie == id)	
}