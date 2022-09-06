#include <zombie_escape>

// Defines
#define SOUND_MAX_LENGTH 64
#define TASK_COUNTDOWN 2010

// Default Countdown Sounds
new const szCountDownSound[][] =
{
	"zombie_escape/1.wav",
	"zombie_escape/2.wav",
	"zombie_escape/3.wav",
	"zombie_escape/4.wav",
	"zombie_escape/5.wav",
	"zombie_escape/6.wav",
	"zombie_escape/7.wav",
	"zombie_escape/8.wav",
	"zombie_escape/9.wav",
	"zombie_escape/10.wav"
}

// Dynamic Arrays
new Array:g_szCountDownSound

// Variables
new g_iCountDown

// Forward allows precache game files.
public plugin_precache()
{
	// Initialize arrays
	g_szCountDownSound = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "COUNT DOWN", g_szCountDownSound)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new iIndex
	
	if (ArraySize(g_szCountDownSound) == 0)
	{
		for (iIndex = 0; iIndex < sizeof szCountDownSound; iIndex++)
		{
			// Get Defaults Sounds and Store them in the Array
			ArrayPushString(g_szCountDownSound, szCountDownSound[iIndex])
		}
		
		// Save values stored in Array to External file
		amx_save_setting_string_arr(ZE_SETTING_RESOURCES, "Sounds", "COUNT DOWN", g_szCountDownSound)
	}

	new szSound[MAX_SOUND_LENGTH], iArrSize

	// Get number of sounds in dynamic array.
	iArrSize = ArraySize(g_szCountDownSound)

	for (iIndex = 0; iIndex < iArrSize; iIndex++)
	{
		ArrayGetString(g_szCountDownSound, iIndex, szSound, charsmax(szSound))
		
		format(szSound, charsmax(szSound), "sound/%s", szSound)
		precache_generic(szSound)
	}
}

// Forward called after server activation.
public plugin_init()
{
	register_plugin("[ZE] Sound Countdown", ZE_VERSION, AUTHORS)
}

// Forward called every new round, After game started.
public ze_game_started()
{
	// Get gamemode delay
	g_iCountDown = get_cvar_num("ze_gamemodes_delay") 
	
	// New task for countdown.
	set_task(1.0, "Countdown_Start", TASK_COUNTDOWN, _, _, "b")
}

public Countdown_Start()
{
	// Check game mode has started or not yet?
	if ((g_iCountDown - 1 < 0) || !ze_is_game_started())
	{
		remove_task(TASK_COUNTDOWN) // Remove the task
		return // Block the execution of the blew code
	}
	
	// Start the count down when remains 10 seconds
	if (g_iCountDown <= 10)
	{
		static szSound[SOUND_MAX_LENGTH]
		ArrayGetString(g_szCountDownSound, g_iCountDown - 1, szSound, charsmax(szSound))
		PlaySound(0, szSound)
	}
	
	g_iCountDown--
}

// Forward called when gamemode chosen.
public ze_gamemode_chosen(game_id)
{
	// At gamemode chosen, remove countdown task to block interference next round.
	remove_task(TASK_COUNTDOWN)
}

public ze_roundend(WinTeam)
{
	// At round end, remove countdown task to block interference next round.
	remove_task(TASK_COUNTDOWN)
}