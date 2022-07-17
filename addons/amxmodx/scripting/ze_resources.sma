#include <zombie_escape>

// Defines
#define TASK_AMBIENCESOUND 2020
#define TASK_REAMBIENCESOUND 5050
#define ZOMBIE_CLAWS "zombie_knife"

// Default Sounds
new const szReadySound[][] = 
{
	"zombie_escape/ze_ready.mp3"
}

new const szInfectSound[][] = 
{
	"zombie_escape/zombie_infect_1.wav",
	"zombie_escape/zombie_infect_2.wav"
}

new const szComingSound[][] = 
{
	"zombie_escape/zombie_coming_1.wav",
	"zombie_escape/zombie_coming_2.wav",
	"zombie_escape/zombie_coming_3.wav"
}

new const szPreReleaseSound[][] = 
{
	"zombie_escape/ze_pre_release.wav"
}

new const szAmbianceSound[][] = 
{
	"zombie_escape/ze_ambiance1.mp3",
	"zombie_escape/ze_ambiance2.mp3",
	"zombie_escape/ze_ambiance3.mp3"
}

new const szEscapeSuccessSound[][] = 
{
	"zombie_escape/escape_success.wav"
}

new const szEscapeFailSound[][] = 
{
	"zombie_escape/escape_fail.wav"
}

// Default Sounds Duration (Hardcoded Values)
new g_iReadySoundDuration = 19
new g_iStartSoundDuration = 5
new g_iPreReleaseSoundDuration = 19
new g_iAmbianceSoundDuration = 160 //(Avarage for the 2 ambiances)

// Default Models
new const szHostZombieModel[][] =
{
	"host_zombie"
}

new const szOriginZombieModel[][] =
{
	"origin_zombie"
}

new const szHumanModels[][] =
{
	"arctic",
	"gign",
	"gsg9",
	"guerilla",
	"leet",
	"sas",
	"terror",
	"urban"
}

new const v_szZombieKnifeModel[][] =
{
	"models/zombie_escape/v_knife_zombie.mdl"
}

new const v_szHumanKnifeModel[][] = 
{
	"models/v_knife.mdl"
}

new const p_szHumanKnifeModel[][] = 
{
	"models/p_knife.mdl"
}

// Zombie claws
new const WeaponList_SpriteSpr[] = "sprites/zombie_knife.spr"
new const WeaponList_SpriteTxt[] = "sprites/zombie_knife.txt"

// Dynamic Arrays: Sounds
new Array:g_szReadySound, 
	Array:g_szInfectSound, 
	Array:g_szComingSound, 
	Array:g_szPreReleaseSound,
	Array:g_szAmbianceSound, 
	Array:g_szEscapeSuccessSound, 
	Array:g_szEscapeFailSound

// Dynamic Arrays: Models
new Array:g_szHumanModels,
	Array:g_szHostZombieModel,
	Array:g_szOriginZombieModel,
	Array:g_v_szZombieKnifeModel,
	Array:g_v_szHumanKnifeModel, 
	Array:g_p_szHumanKnifeModel

// Global Variables
new g_iReleaseTime,
	g_iMsgIndexWeaponList,
	bool:g_bAmbianceSound[33], 
	bool:g_bReadySound[33], 
	bool:g_bInReady, 
	bool:g_bInReadyOnly,
	bool:g_bReadyEnabled,
	bool:g_bReleaseEnabled,
	bool:g_bAmbianceEnabled,
	bool:g_bInfectionEnabled,
	bool:g_bComingEnabled,
	bool:g_bWinsEnabled

public plugin_natives()
{
	register_native("ze_set_starting_sounds", "native_ze_set_starting_sounds", 1)
	register_native("ze_is_starting_sounds_enabled", "native_ze_is_starting_sounds_enabled", 1)
	register_native("ze_set_ambiance_sounds", "native_ze_set_ambiance_sounds", 1)
	register_native("ze_is_ambiance_sounds_enabled", "native_ze_is_ambiance_sounds_enabled", 1)
}

public plugin_init()
{
	register_plugin("[ZE] Models & Sounds", ZE_VERSION, AUTHORS)
	
	// Hams
	RegisterHam(Ham_Item_AddToPlayer, "weapon_knife", "Fw_AddItemToPlayer_Post", 1);
		
	// CVars.
	bind_pcvar_num(create_cvar("ze_ready_sound", "1"), g_bReadyEnabled)
	bind_pcvar_num(create_cvar("ze_release_sound", "1"), g_bReleaseEnabled)
	bind_pcvar_num(create_cvar("ze_ambiance_sound", "1"), g_bAmbianceEnabled)
	bind_pcvar_num(create_cvar("ze_infection_sound", "1"), g_bInfectionEnabled)
	bind_pcvar_num(create_cvar("ze_coming_sound", "1"), g_bComingEnabled)
	bind_pcvar_num(create_cvar("ze_wins_sound", "1"), g_bWinsEnabled)
	bind_pcvar_num(get_cvar_pointer("ze_release_time"), g_iReleaseTime)

	// Hook zombie knife
	register_clcmd(ZOMBIE_CLAWS, "Hook_ZombieKnifeSelection")
	
	// Weapon list
	g_iMsgIndexWeaponList = get_user_msgid("WeaponList")
	
	// Default ambiance and ready sounds are enabled
	arrayset(g_bAmbianceSound[1], true, 32)
	arrayset(g_bReadySound[1], true, 32)
}

public plugin_precache()
{	
	// Initialize Arrays: Sounds
	g_szReadySound = ArrayCreate(MAX_SOUND_LENGTH, 1)
	g_szInfectSound = ArrayCreate(MAX_SOUND_LENGTH, 1)
	g_szComingSound = ArrayCreate(MAX_SOUND_LENGTH, 1)
	g_szPreReleaseSound = ArrayCreate(MAX_SOUND_LENGTH, 1)
	g_szAmbianceSound = ArrayCreate(MAX_SOUND_LENGTH, 1)
	g_szEscapeSuccessSound = ArrayCreate(MAX_SOUND_LENGTH, 1)
	g_szEscapeFailSound = ArrayCreate(MAX_SOUND_LENGTH, 1)
	
	// Load From External File: Sounds
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Ready Sound", g_szReadySound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Infect Sound", g_szInfectSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Coming Sound", g_szComingSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Pre-Release Sound", g_szPreReleaseSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Round Ambiance", g_szAmbianceSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Escape Success", g_szEscapeSuccessSound)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Escape Fail", g_szEscapeFailSound)
	
	// Load our Default Values: Sounds
	new iIndex
	
	if(ArraySize(g_szReadySound) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szReadySound; iIndex++)
			ArrayPushString(g_szReadySound, szReadySound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Ready Sound", g_szReadySound)
	}
	
	if(ArraySize(g_szInfectSound) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szInfectSound; iIndex++)
			ArrayPushString(g_szInfectSound, szInfectSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Infect Sound", g_szInfectSound)
	}
	
	if(ArraySize(g_szComingSound) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szComingSound; iIndex++)
			ArrayPushString(g_szComingSound, szComingSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Coming Sound", g_szComingSound)
	}
	
	if(ArraySize(g_szPreReleaseSound) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szPreReleaseSound; iIndex++)
			ArrayPushString(g_szPreReleaseSound, szPreReleaseSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Pre-Release Sound", g_szPreReleaseSound)
	}
	
	if(ArraySize(g_szAmbianceSound) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szAmbianceSound; iIndex++)
			ArrayPushString(g_szAmbianceSound, szAmbianceSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Round Ambiance", g_szAmbianceSound)
	}
	
	if(ArraySize(g_szEscapeSuccessSound) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szEscapeSuccessSound; iIndex++)
			ArrayPushString(g_szEscapeSuccessSound, szEscapeSuccessSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Escape Success", g_szEscapeSuccessSound)
	}
	
	if(ArraySize(g_szEscapeFailSound) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szEscapeFailSound; iIndex++)
			ArrayPushString(g_szEscapeFailSound, szEscapeFailSound[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "Escape Fail", g_szEscapeFailSound)
	}
	
	new szSound[MAX_SOUND_LENGTH], iArrSize
		
	// Get number of sounds in dynamic array.
	iArrSize = ArraySize(g_szInfectSound)	

	for (iIndex = 0; iIndex < iArrSize; iIndex++)
	{
		ArrayGetString(g_szInfectSound, iIndex, szSound, charsmax(szSound))
		
		if (equal(szSound[strlen(szSound)-4], ".mp3"))
		{
			format(szSound, charsmax(szSound), "sound/%s", szSound)
			precache_generic(szSound)
		}
		else
		{
			precache_sound(szSound)
		}
	}

	// Sound Durations
	if (!amx_load_setting_int(ZE_SETTING_RESOURCES, "Sound Durations", "Ready Sound", g_iReadySoundDuration))
		amx_save_setting_int(ZE_SETTING_RESOURCES, "Sound Durations", "Ready Sound", g_iReadySoundDuration)

	if (!amx_load_setting_int(ZE_SETTING_RESOURCES, "Sound Durations", "Start Sound", g_iStartSoundDuration))
		amx_save_setting_int(ZE_SETTING_RESOURCES, "Sound Durations", "Start Sound", g_iStartSoundDuration)
	
	if (!amx_load_setting_int(ZE_SETTING_RESOURCES, "Sound Durations", "Pre-Release Sound", g_iPreReleaseSoundDuration))
		amx_save_setting_int(ZE_SETTING_RESOURCES, "Sound Durations", "Pre-Release Sound", g_iPreReleaseSoundDuration)
	
	if (!amx_load_setting_int(ZE_SETTING_RESOURCES, "Sound Durations", "Round Ambiance", g_iAmbianceSoundDuration))
		amx_save_setting_int(ZE_SETTING_RESOURCES, "Sound Durations", "Round Ambiance", g_iAmbianceSoundDuration)
	
	// Initialize Arrays: Models
	g_szHumanModels = ArrayCreate(MAX_NAME_LENGTH, 1)
	g_szHostZombieModel = ArrayCreate(MAX_NAME_LENGTH, 1)
	g_szOriginZombieModel = ArrayCreate(MAX_NAME_LENGTH, 1)
	g_v_szZombieKnifeModel = ArrayCreate(MAX_MODEL_LENGTH, 1)
	g_v_szHumanKnifeModel = ArrayCreate(MAX_MODEL_LENGTH, 1)
	g_p_szHumanKnifeModel = ArrayCreate(MAX_MODEL_LENGTH, 1)
	
	// Load From External File: Models
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Player Models", "HUMANS", g_szHumanModels)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Player Models", "HOST ZOMBIE", g_szHostZombieModel)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Player Models", "ORIGIN ZOMBIE", g_szOriginZombieModel)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Weapon Models", "V_KNIFE ZOMBIE", g_v_szZombieKnifeModel)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Weapon Models", "V_KNIFE HUMAN", g_v_szHumanKnifeModel)
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Weapon Models", "P_KNIFE HUMAN", g_p_szHumanKnifeModel)
	
	// Load our Default Values: Models	
	if (ArraySize(g_szHumanModels) == 0)
	{
		for (iIndex = 0; iIndex < sizeof szHumanModels; iIndex++)
			ArrayPushString(g_szHumanModels, szHumanModels[iIndex])
		
		// Save to externel file.
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Player Models", "HUMANS", g_szHumanModels)
	}

	if(ArraySize(g_szHostZombieModel) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szHostZombieModel; iIndex++)
			ArrayPushString(g_szHostZombieModel, szHostZombieModel[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Player Models", "HOST ZOMBIE", g_szHostZombieModel)
	}
	
	if(ArraySize(g_szOriginZombieModel) == 0)
	{
		for(iIndex = 0; iIndex < sizeof szOriginZombieModel; iIndex++)
			ArrayPushString(g_szOriginZombieModel, szOriginZombieModel[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Player Models", "ORIGIN ZOMBIE", g_szOriginZombieModel)
	}
	
	if(ArraySize(g_v_szZombieKnifeModel) == 0)
	{
		for(iIndex = 0; iIndex < sizeof v_szZombieKnifeModel; iIndex++)
			ArrayPushString(g_v_szZombieKnifeModel, v_szZombieKnifeModel[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Weapon Models", "V_KNIFE ZOMBIE", g_v_szZombieKnifeModel)
	}
	
	if(ArraySize(g_v_szHumanKnifeModel) == 0)
	{
		for(iIndex = 0; iIndex < sizeof v_szHumanKnifeModel; iIndex++)
			ArrayPushString(g_v_szHumanKnifeModel, v_szHumanKnifeModel[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Weapon Models", "V_KNIFE HUMAN", g_v_szHumanKnifeModel)
	}
	
	if(ArraySize(g_p_szHumanKnifeModel) == 0)
	{
		for(iIndex = 0; iIndex < sizeof p_szHumanKnifeModel; iIndex++)
			ArrayPushString(g_p_szHumanKnifeModel, p_szHumanKnifeModel[iIndex])
		
		// Save to external file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Weapon Models", "P_KNIFE HUMAN", g_p_szHumanKnifeModel)
	}
	
	// Precache: Models
	new szPlayerModel[MAX_NAME_LENGTH], szModelPath[128]
	
	// Get number of models in dynamic array.
	iArrSize = ArraySize(g_szHostZombieModel)

	for (iIndex = 0; iIndex < iArrSize; iIndex++)
	{
		ArrayGetString(g_szHostZombieModel, iIndex, szPlayerModel, charsmax(szPlayerModel))
		formatex(szModelPath, charsmax(szModelPath), "models/player/%s/%s.mdl", szPlayerModel, szPlayerModel)
		precache_model(szModelPath)
	}

	// Get number of models in dynamic array.
	iArrSize = ArraySize(g_szOriginZombieModel)

	for (iIndex = 0; iIndex < iArrSize; iIndex++)
	{
		ArrayGetString(g_szOriginZombieModel, iIndex, szPlayerModel, charsmax(szPlayerModel))
		formatex(szModelPath, charsmax(szModelPath), "models/player/%s/%s.mdl", szPlayerModel, szPlayerModel)
		precache_model(szModelPath)
	}

	// Get number of models in dynamic array.
	iArrSize = ArraySize(g_v_szZombieKnifeModel)

	for (iIndex = 0; iIndex < iArrSize; iIndex++)
	{
		ArrayGetString(g_v_szZombieKnifeModel, iIndex, szModelPath, charsmax(szModelPath))
		precache_model(szModelPath)
	}

	// Get number of models in dynamic array.
	iArrSize = ArraySize(g_v_szHumanKnifeModel)

	for (iIndex = 0; iIndex < iArrSize; iIndex++)
	{
		ArrayGetString(g_v_szHumanKnifeModel, iIndex, szModelPath, charsmax(szModelPath))
		precache_model(szModelPath)
	}

	// Get number of models in dynamic array.
	iArrSize = ArraySize(g_p_szHumanKnifeModel)

	for (iIndex = 0; iIndex < iArrSize; iIndex++)
	{
		ArrayGetString(g_p_szHumanKnifeModel, iIndex, szModelPath, charsmax(szModelPath))
		precache_model(szModelPath)
	}
	
	// Precache zombie claws
	precache_generic(WeaponList_SpriteTxt)
	precache_generic(WeaponList_SpriteSpr)
}

// Play Ready sound only if game started
public ze_game_started()
{
	// Remove Tasks (Again as somehow may it not removed at the roundend)
	remove_task(TASK_AMBIENCESOUND)
	remove_task(TASK_REAMBIENCESOUND)
	
	// Stop All Sounds
	StopSound()
	
	// Ready sound enabled?
	if (g_bReadyEnabled)
	{
		// Play Ready Sound For All Players
		new szSound[MAX_SOUND_LENGTH]
		ArrayGetString(g_szReadySound, random_num(0, ArraySize(g_szReadySound) - 1), szSound, charsmax(szSound))
		
		for (new id = 1; id <= MaxClients; id++)
		{
			if(!is_user_connected(id) || !g_bReadySound[id])
				continue

			PlaySound(id, szSound)
		}		
	}
	
	g_bInReady = true
	g_bInReadyOnly = true
}

public ze_user_infected(iVictim, iInfector)
{	
	new szSound[MAX_SOUND_LENGTH]
	
	// Infections sound enabled?
	if (g_bInfectionEnabled)
	{
		// Emit Sound For infection (Sound Source is The zombie Body)
		ArrayGetString(g_szInfectSound, random_num(0, ArraySize(g_szInfectSound) - 1), szSound, charsmax(szSound))
		emit_sound(iVictim, CHAN_BODY, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM)		
	}
	
	// Coming sounds enabled?
	if (g_bComingEnabled)
	{
		// Play Zombie Appear Sound for all Players
		ArrayGetString(g_szComingSound, random_num(0, ArraySize(g_szComingSound) - 1), szSound, charsmax(szSound))
		PlaySound(0, szSound)		
	}
	
	// Local Variables.
	new szModel[MAX_MODEL_LENGTH]

	// Random Model Set
	switch(random_num(0, 130))
	{
		case 0..30, 71..100:
		{
			ArrayGetString(g_szHostZombieModel, random_num(0, ArraySize(g_szHostZombieModel) - 1), szModel, charsmax(szModel))
			rg_set_user_model(iVictim, szModel, true) // This native is fast than CStrike or FakeMeta module. 
		}
		case 31..70, 101..130:
		{
			ArrayGetString(g_szOriginZombieModel, random_num(0, ArraySize(g_szOriginZombieModel) - 1), szModel, charsmax(szModel))
			rg_set_user_model(iVictim, szModel, true)
		}
	}

	// Set Zombie random claw's.
	ArrayGetString(g_v_szZombieKnifeModel, random_num(0, ArraySize(g_v_szZombieKnifeModel) - 1), szModel, charsmax(szModel))
	cs_set_player_view_model(iVictim, CSW_KNIFE, szModel)
	cs_set_player_weap_model(iVictim, CSW_KNIFE, "") // Leave Blank so knife not appear with zombies
}

public ze_zombie_appear()
{
	// Pre-Release sound enabled?
	if (g_bReleaseEnabled)
		set_task(float(g_iStartSoundDuration), "ZombieAppear", _, _, _, "a", 1) // Add Delay to let Infection Sound to complete	
}

public ZombieAppear()
{
	// Now pre-release
	g_bInReadyOnly = false
	
	// Stop any other sound, so no interference occur
	StopSound()
	
	// Play Pre-Release Sound For All Players
	new szSound[MAX_SOUND_LENGTH]
	ArrayGetString(g_szPreReleaseSound, random_num(0, ArraySize(g_szPreReleaseSound) - 1), szSound, charsmax(szSound))
	
	for (new id = 1; id <= MaxClients; id++)
	{
		if(!is_user_connected(id) || !g_bReadySound[id])
			continue

		PlaySound(id, szSound)
	}
}

public ze_zombie_release()
{
	// Ambiance sound enabled?
	if (g_bAmbianceEnabled)
		set_task(float(g_iPreReleaseSoundDuration - g_iReleaseTime), "AmbianceSound", TASK_AMBIENCESOUND, _, _, "a", 1) // Add Delay to make sure Pre-Release Sound Finished
}

public AmbianceSound()
{
	// Stop All Sounds
	StopSound()
	
	g_bInReady = false
	
	// Play The Ambiance Sound For All Players
	new szSound[MAX_SOUND_LENGTH]
	ArrayGetString(g_szAmbianceSound, random_num(0, ArraySize(g_szAmbianceSound) - 1), szSound, charsmax(szSound))
	
	for(new id = 1; id <= MaxClients; id++)
	{
		if(!is_user_connected(id) || !g_bAmbianceSound[id])
			continue

		PlaySound(id, szSound)
	}

	// We should Set Task back again to replay (Repeated 5 times MAX)
	set_task(float(g_iAmbianceSoundDuration), "RePlayAmbianceSound", TASK_REAMBIENCESOUND, _, _, "a", 5)
}

public RePlayAmbianceSound()
{
	// Play The Ambiance Sound For All Players
	new szSound[MAX_SOUND_LENGTH]
	ArrayGetString(g_szAmbianceSound, random_num(0, ArraySize(g_szAmbianceSound) - 1), szSound, charsmax(szSound))
	
	for(new id = 1; id <= MaxClients; id++)
	{
		if(!is_user_connected(id) || !g_bAmbianceSound[id])
			continue

		PlaySound(id, szSound)
	}
}

// Forward called after player humanized.
public ze_user_humanized(id)
{
	// Local Variable.
	new szModel[MAX_MODEL_LENGTH]

	// Get random model from dynamic array.
	ArrayGetString(g_szHumanModels, random_num(0, ArraySize(g_szHumanModels) - 1), szModel, charsmax(szModel))

	// Set player Model.
	rg_set_user_model(id, szModel, true)
		
	// Rest Player Knife model
	ArrayGetString(g_v_szHumanKnifeModel, random_num(0, ArraySize(g_v_szHumanKnifeModel) - 1), szModel, charsmax(szModel))
	cs_set_player_view_model(id, CSW_KNIFE, szModel)
	ArrayGetString(g_p_szHumanKnifeModel, random_num(0, ArraySize(g_p_szHumanKnifeModel) - 1), szModel, charsmax(szModel))
	cs_set_player_weap_model(id, CSW_KNIFE, szModel)
	
	// Reset the claws
	WeaponList(id, 0)
}

public ze_roundend(WinTeam)
{
	remove_task(TASK_AMBIENCESOUND)
	remove_task(TASK_REAMBIENCESOUND)
	StopSound()
	
	// Wins sounds disabled?
	if (!g_bWinsEnabled)
		return

	new szSound[MAX_SOUND_LENGTH]
	
	switch (WinTeam)
	{
		case ZE_TEAM_ZOMBIE:
		{
			ArrayGetString(g_szEscapeFailSound, random_num(0, ArraySize(g_szEscapeFailSound) - 1), szSound, charsmax(szSound))
		}
		case ZE_TEAM_HUMAN:
		{
			ArrayGetString(g_szEscapeSuccessSound, random_num(0, ArraySize(g_szEscapeSuccessSound) - 1), szSound, charsmax(szSound))
		}		
	}

	// Play sound for all players.
	PlaySound(0, szSound)
}

public Fw_AddItemToPlayer_Post(iItem, id)
{
	if (is_entity(iItem) && is_user_alive(id) && ze_is_user_zombie_ex(id))
	{
		// Show zombie claws when add knife to zombies
		WeaponList(id, 1)
	}
}

public Hook_ZombieKnifeSelection(id)
{ 
	if (!is_user_alive(id) || !ze_is_user_zombie_ex(id))
		return PLUGIN_HANDLED

	engclient_cmd(id, "weapon_knife")
	
	return PLUGIN_HANDLED
}

WeaponList(id, iMode = 0)
{
	message_begin(MSG_ONE, g_iMsgIndexWeaponList, {0, 0, 0}, id)
	write_string(iMode ? ZOMBIE_CLAWS : "weapon_knife")
	write_byte(-1)
	write_byte(-1)
	write_byte(-1)
	write_byte(-1)
	write_byte(2)
	write_byte(1)
	write_byte(CSW_KNIFE)
	write_byte(0)
	message_end()
}

// Natives
public native_ze_set_starting_sounds(id, bool:bSet)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	// If true, enable starting sounds (Ready + PreRelease)
	if (bSet)
	{
		if (!g_bReadySound[id])
		{
			g_bReadySound[id] = true
			
			// This means player, still in ready so play ready sound
			if (g_bInReadyOnly == true)
			{
				new szSound[MAX_SOUND_LENGTH]
				ArrayGetString(g_szReadySound, random_num(0, ArraySize(g_szReadySound) - 1), szSound, charsmax(szSound))
				
				PlaySound(id, szSound)
			}
			
			// This will play the pre-release sound
			if (g_bInReady == true && !g_bInReadyOnly)
			{
				new szSound[MAX_SOUND_LENGTH]
				ArrayGetString(g_szPreReleaseSound, random_num(0, ArraySize(g_szPreReleaseSound) - 1), szSound, charsmax(szSound))
				
				PlaySound(id, szSound)
			}
		}
	}
	else
	{
		if (g_bReadySound[id])
		{
			g_bReadySound[id] = false
			
			client_cmd(id, "mp3 stop")
			client_cmd(id, "stopsound")
		}
	}
	
	return true;
}

public native_ze_set_ambiance_sounds(id, bool:bSet)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false;
	}
	
	// If true, enable ambiance sound
	if (bSet)
	{
		if (!g_bAmbianceSound[id])
		{
			g_bAmbianceSound[id] = true
			
			// If player not in ready, then enable sound instantly
			if (!g_bInReady)
			{
				new szSound[MAX_SOUND_LENGTH]
				ArrayGetString(g_szAmbianceSound, random_num(0, ArraySize(g_szAmbianceSound) - 1), szSound, charsmax(szSound))
				
				PlaySound(id, szSound)
				
				// We should Set Task back again to replay (Repeated 5 times MAX)
				set_task(float(g_iAmbianceSoundDuration), "RePlayAmbianceSound", TASK_REAMBIENCESOUND, _, _, "a", 5)
			}
		}
	}
	else
	{
		if (g_bAmbianceSound[id])
		{
			g_bAmbianceSound[id] = false
			
			if (!g_bInReady)
			{
				client_cmd(id, "mp3 stop")
			}
		}
	}
	
	return true;
}

public native_ze_is_starting_sounds_enabled(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return -1;
	}
	
	return g_bReadySound[id];
}

public native_ze_is_ambiance_sounds_enabled(id)
{
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return -1;
	}
	
	return g_bAmbianceSound[id];
}