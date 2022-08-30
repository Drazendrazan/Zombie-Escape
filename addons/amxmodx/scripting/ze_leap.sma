#include <zombie_escape>

// Global Variables.
new g_iZombieLeap
new bool:g_bLeapUsed[MAX_PLAYERS+1]
new bool:g_bLeapBlocked[MAX_PLAYERS+1]
new Float:g_flZombieForce
new Float:g_flZombieHeight
new Float:g_flZombieCooldown
new Float:g_flUserTime[MAX_PLAYERS+1]
new Float:g_flLeapForce[MAX_PLAYERS+1]
new Float:g_flLeapHeight[MAX_PLAYERS+1]
new Float:g_flLeapCooldown[MAX_PLAYERS+1]

// Forward allows registering new natives.
public plugin_natives()
{
	register_native("ze_set_user_leap", "native_set_user_leap", 1)
	register_native("ze_block_user_leap", "native_block_user_leap", 1)
	register_native("ze_unblock_user_leap", "native_unblock_user_leap", 1)
	register_native("ze_remove_user_leap", "native_remove_user_leap", 1)
}

// Forward called after server activation.
public plugin_init()
{
	// Load plugin.
	register_plugin("[ZE] Leap: Long-Jump", ZE_VERSION, AUTHORS, ZE_HOMEURL, "Long-Jump with APIs")

	// FakeMeta.
	register_forward(FM_CmdStart, "fw_CmdStart_Post", 1)

	// Create new CVars and Bind Cvars (Store the new value of CVars in Global Variables)
	bind_pcvar_num(create_cvar("ze_zombie_leap", "0"), g_iZombieLeap)
	bind_pcvar_float(create_cvar("ze_zombie_leap_force", "500"), g_flZombieForce)
	bind_pcvar_float(create_cvar("ze_zombie_leap_height", "300"), g_flZombieHeight)
	bind_pcvar_float(create_cvar("ze_zombie_leap_cooldown", "10.0"), g_flZombieCooldown)
}

// Forward called after player press any button.
public fw_CmdStart_Post(id, pUC_handle)
{
	// Player not alive?
	if (!is_user_alive(id) || g_bLeapBlocked[id])
		return
	
	// Static's
	static Float:vVelocity[3], Float:flForce, Float:flHeight, Float:flCooldown

	// Jump + Crouch?
	if (!(get_uc(pUC_handle, UC_Buttons) & (IN_JUMP|IN_DUCK) == (IN_JUMP|IN_DUCK)))
		return

	// Cooldown time isn't over yet?
	if ((g_flUserTime[id] - get_gametime()) > 0.0)
		return

	// Get velocity of player.
	get_entvar(id, var_velocity, vVelocity)

	// Player not on ground or speed not enough?
	if (!(get_entvar(id, var_flags) & FL_ONGROUND) || (vector_length(vVelocity) < 80))
		return

	if (g_bLeapUsed[id])
	{
		flForce = g_flLeapForce[id]
		flHeight = g_flLeapHeight[id]
		flCooldown = g_flLeapCooldown[id]

		// Go to bottom of function.
		goto Long_Jump
	}

	switch (g_iZombieLeap)
	{
		case 1: // All Zombies
		{
			// Player is Zombie?
			if (ze_is_user_zombie_ex(id))
			{
				flForce = g_flZombieForce
				flHeight = g_flZombieHeight
				flCooldown = g_flZombieCooldown
			
				// Go to bottom of function.
				goto Long_Jump				
			}
		}
		case 2: // First Zombie.
		{
			// Player is not first Zombie?
			if (ze_is_user_first_zombie(id))
			{
				flForce = g_flZombieForce
				flHeight = g_flZombieHeight
				flCooldown = g_flZombieCooldown

				// Go to bottom of function.
				goto Long_Jump
			}
		}
		case 3: // Last Zombie.
		{
			// Player is not last Zombie?
			if (ze_is_user_last_zombie(id))
			{
				flForce = g_flZombieForce
				flHeight = g_flZombieHeight
				flCooldown = g_flZombieCooldown
				
				// Go to bottom of function.
				goto Long_Jump
			}
		}
	}

	// Exit from function.
	goto ExitFunction

	// High Jump.
	Long_Jump:
	
	// Cooldown
	g_flUserTime[id] = get_gametime() + flCooldown

	// Get velocity by Aim.
	velocity_by_aim(id, floatround(flForce), vVelocity)

	// Add height speed.
	vVelocity[2] = flHeight

	// Set player new Velocity.
	set_entvar(id, var_velocity, vVelocity)		
	ExitFunction:
}

/**
 * Function of natives:
 */
public native_set_user_leap(id, Float:flForce, Float:flHeight, Float:flCooldown)
{
	// Player not found?
	if (!is_user_connected(id))
	{
		// Print error on server console with details.
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false
	}

	// Turn on leap for player.
	g_bLeapUsed[id] = true

	// Set leap speed.
	g_flLeapForce[id] = flForce
	g_flLeapHeight[id] = flHeight
	g_flLeapCooldown[id] = flCooldown
	return true
}

public native_block_user_leap(id)
{
	// Player not found?
	if (!is_user_connected(id))
	{
		// Print error on server console with details.
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false
	}

	g_bLeapBlocked[id] = true
	return true
}

public native_unblock_user_leap(id)
{
	// Player not found?
	if (!is_user_connected(id))
	{
		// Print error on server console with details.
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false
	}

	g_bLeapBlocked[id] = false
	return true	
}

public native_remove_user_leap(id)
{
	// Player not found?
	if (!is_user_connected(id))
	{
		// Print error on server console with details.
		log_error(AMX_ERR_NATIVE, "[ZE] Invalid Player id (%d)", id)
		return false
	}

	// Turn off leap of player.
	g_bLeapUsed[id] = false

	// Reset Var
	g_flLeapForce[id] = 0.0
	g_flLeapHeight[id] = 0.0
	g_flLeapCooldown[id] = 0.0
	return true	
}