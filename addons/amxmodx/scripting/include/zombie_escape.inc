#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <nvault>
#include <sqlx>
#include <amx_settings_api>
#include <cs_weap_models_api>
#include <zombie_escape_stocks>

// Mod Information's.
#define ZE_VERSION "1.7.1"
#define AUTHORS "ZE Dev Team"
#define ZE_HOMEURL "https://github.com/raheem-cs/Zombie-Escape"

/*
*	For more information about these natives and forwards, just vist our forum:
*						Escapers-Zone.net
*/

// Settings file.
#define ZE_SETTING_RESOURCES "zombie_escape.ini"

// Max Extra-Items
#define MAX_EXTRA_ITEMS 60

// Team constants, use them in ze_roundend() forward 
enum (+=1)
{
	ZE_TEAM_ZOMBIE = 1,
	ZE_TEAM_HUMAN
}

// Items returns used in ze_select_item_pre()
enum (+=1)
{
	ZE_WRONG_ITEM = -1,
	ZE_ITEM_AVAILABLE,
	ZE_ITEM_UNAVAILABLE,
	ZE_ITEM_DONT_SHOW
}

// General forwards return values
enum (+=1)
{
	ZE_CONTINUE = 0,
	ZE_STOP
}

// Game mode return value.
enum (+=1)
{
	ZE_WRONG_GAME = -1
}

// Used in ze_resource.sma
const MAX_MODEL_LENGTH = 64
const MAX_SOUND_LENGTH = 64

// Forwards

/**
 * Description:		Called on round end event.
 *
 * @param WinTeam	The win team ZE_TEAM_ZOMBIE or ZE_TEAM_HUMAN.
 *
 * @noreturn
 *
 */
forward ze_roundend(WinTeam);

/**
 * Description:	Called when user humanized, it called whenever 
 *				ze_set_user_human(id) native used.
 *				It's called also at every new round when all players humanized.
 *
 * @param id	Client index.
 *
 * @return		ZE_STOP 	| Prevent humanization event.
 *				ZE_CONTINUE	| Continue humanization event.
 *
 * @note 		ze_user_humanized never called,
 *				When this forward return value 1 or above.
 *
 */
forward ze_user_humanized_pre(id);

/**
 * Description:	Called after user humanized, it called whenever 
 *				ze_set_user_human(id) native used.
 *				It's called also at every new round when all players humanized.
 *
 * @param id	Client index.
 *
 * @return		Returns here useless.
 *
 */
forward ze_user_humanized(id);

/**
 * Description:		Called before user get infected by player.
 *
 * @param iVictim	Victim index, human who will catch the infection.
 * @param iInfector	Infector index, zombie who will cause the infection.
 * @param iDamage	The blocked damage value.
 *
 * @return			To stop the infection event use:   return ZE_STOP
 *					To let the infection continue use: return ZE_CONTINUE
 *
 * @note			This forward will not called on the zombie choose by the server,
 *					only called if player try to infect player.
 *					You can use pre to block the infection or to let it in specific conditions.
 *					Basically return > ZE_CONTINUE  will stop the infection.
 *			
 */
forward ze_user_infected_pre(iVictim, iInfector, iDamage);

/**
 * Description:		Called when user infected by player or by the server.
 *					Called also at the first choose of zombies (in this case server is the infector).
 *
 * @param iVictim	Victim index, human who catch the infection.
 * @param iInfector	Infector index, zombie or server who caused the infection.
 *
 * @noreturn
 *
 * @note			If the infector is the server, The iInfector will be 0
 *					else the iInfector will be the zombie id.		
 *
 */
forward ze_user_infected(iVictim, iInfector);

/**
 * Description:	Called when zombies chosen.
 *
 * @noreturn
 *
 * @note 		This forward never called, If no chosen Zombies.
 *				Try use ze_zombie_appear_ex(const iFirstZombies[], iZombieNum)
 *				This forward is called in Escape Mode.
 *
 */
forward ze_zombie_appear();

/**
 * Description:	Called when zombies chosen.
 *
 * @param iFirstZombies[] 	Array contains an index of the first Zombies.
 * @param iZombieNum 		Number of the first Zombies.
 *
 * @noreturn
 *
 * @note 					This forward called in Escape Mode.
 *
 */
forward ze_zombie_appear_ex(const iFirstZombies[], iZombieNum);

/**
 * Description:	Called when the chosen zombies released.
 *
 * @noreturn
 *
 * @note 		This forward called in Escape Mode.
 *
 */
forward ze_zombie_release();

/**
 * Description:	Called every new round if game started.
 *
 * @return		ZE_STOP 	| Block zombie escape mod.
 *				ZE_CONTINUE | Continue zombie escape mod.
 *
 * @note		This called every new round only if the game started
 *				which mean players is higher than required player so game already started.
 *				this native somehow similar to new round event but only called when game started.
 *				You can use it to block zombie escape mod round, and use your own round like Nemesis round
 *				make sure to use this after first round, never return ZE_STOP in first round.
 *
 */
forward ze_game_started_pre();

/**
 * Description:	Called every new round if game started.
 *
 * @noreturn
 *
 * @note		This called every new round only if the game started
 *				which mean players is higher than required player so game already started.
 *				this native somehow similar to new round event but only called when game started.
 *
 */
forward ze_game_started();

/*
* Description:	Called before zombie (or human) get fired by fire nade.
*
* @return		ZE_STOP 		| Block the fire action, zombie will not get fired.
*				ZE_CONTINUE 	| Continue the fire, zombie will be fired.
*
* @note			You can use this to stop the fire action at specific conditions.
*
*/
forward ze_fire_pre(id);

/**
 * Description:	Called before zombie (or human) get frozen by frost nade.
 *
 * @return		ZE_STOP 	| Block the freeze action, zombie will not get frozen.
 *				ZE_CONTINUE | Continue the freeze, zombie will be frozen.
 *
 * @note		You can use this to stop the freeze action at specific conditions.
 *
 */
forward ze_frost_pre(id);

/**
 * Description:	Called when zombie get unfrozen.
 *
 * @noreturn
 *
 */
forward ze_frost_unfreeze(id);

/**
 * Description:			Called when player opens the extra-items menu.
 *						Or when he choose the item but before he get it.
 *
 * @param id			Client index.
 * @param iItemid		Index of item he try to buy.
 * @param bIgnoreCost	True has ignore the cost, False will not ignore cost.
 *
 * @return				ZE_ITEM_AVAILABLE	| Shows item in the menu, player can also buy it.
 *						ZE_ITEM_UNAVAILABLE | Show to player but he can't but it.
 *						ZE_ITEM_DONT_SHOW 	| Item not appear to that player.
 *
 */
forward ze_select_item_pre(id, iItemid, bIgnoreCost);

/**
 * Description:			Called after player choose the item,
 *						called only if ze_select_item_pre() returned ZE_ITEM_AVAILABLE.
 *
 * @param id			Client index.
 * @param iItemid		Index of item he try to buy.
 * @param bIgnoreCost	true will ignore the cost, false will not ignore cost.
 *
 * @noreturn
 *
 */
forward ze_select_item_post(id, iItemid, bIgnoreCost);

/*
* Description:			Called when player disconnect.
*
* @param id				Client index.
*
* @return				ZE_CONTINUE | Continue Mod game rules.
*						ZE_STOP 	| Block Mod game rules, you can use yours.
*
* @note					Useful in plugins like, replacing disconnected zombie/human if he was last zombie/human.
*
*/
forward ze_player_disconnect(id);

/**
 * Description:		Called when player spawn.
 *
 * @param id 		Client index.
 *
 * @noreturn
 */
forward ze_player_spawn_post(id);

/**
 * Description:			Called before game mode chosen.
 *
 * @param game_id 		game mode id.
 * @param bSkipCheck 	True when game mode is started by a native.
 *
 * @return 				ZE_STOP 	| Prevent choosing a game mode.
 *						ZE_CONTINUE | Continue choosing a game mode.
 *
 * @note 				If a game mode is not chosen, 
 *						the default game mode will be chosen.
 *
 */
forward ze_gamemode_chosen_pre(game_id, bSkipCheck);

/**
 * Description:		Called when game mode chosen.
 *
 * @param game_id 	game mode id.
 *
 * @return 			Returns here useless.
 *
 */
forward ze_gamemode_chosen(game_id);

/**
 * Description: Called when player become last Human.
 *
 * @param id 	Client index.
 * 
 * @noreturn
 *
 */
forward ze_user_last_human(id);

/**
 * Description: Called when player become last Zombie.
 *
 * @param id 	Client index.
 * 
 * @noreturn
 *
 */
forward ze_user_last_zombie(id);

// Natives

/**
 * Description:	Check if user zombie or not.
 *
 * @param id		Client index.
 *
 * @return		true	| If user Zombie.
 *				false	| If user Human.
 *				NULLENT | If player not connected.
 *
 */
native ze_is_user_zombie(id);

/**
 * Description: Check if user zombie or not
 *				If player not found is will return false not NULLENT.
 *
 * @param id 	Client index.
 *
 * @return		true  | If user Zombie.
 *				false | If user Human.
 *
 */
native bool:ze_is_user_zombie_ex(id);

/**
 * Description:	Check if game started (Zombie Escape Mod) or not.
 *				Game start when minimun required players connected.
 *
 * @return		true 	| If game started.
 *				false 	| If game not started yet.
 *
 */
native ze_is_game_started();

/**
 * Description:	Check if this zombie in pre-release time or not.
 *				Pre-Release time is said to be freeze time for zombies.
 *
 * @param id	Client index.
 *
 * @return		true  | If this zombie in freeze time.
 *				false | If this zombie not in freeze time.
 *				-1    | If player not connected or this player is Human.
 *
 * @note 		This native is working in Escape Mode.
 *
 */
native ze_is_zombie_frozen(id);

/**
 * Description:	Return current round number (Integer).
 *				First round is round 1, second is 2 ... etc.
 *
 * @return		Round number 	| If game started
 *				-1				| If game not started yet
 *
 */
native ze_get_round_number();

/**
 * Description:	Return alive humans number (Integer).
 *
 * @return		Alive humans number.
 *
 */
native ze_get_humans_number();

/**
 * Description:	Return alive zombies number (Integer).
 *
 * @return		Alive zombies number.
 *
 */
native ze_get_zombies_number();

/**
 * Description:	Set user to zombie team.
 *
 * @param id	Client index.
 *
 * @return		true 	| If set successfully
 *				false 	| If this player not connected
 *
 * @error 		If player not connected.
 *
 */
native ze_set_user_zombie(id);

/**
 * Description:	Set user to zombie team.
 *
 * @param id			Client index.
 * @param iInfector		Infector index.
 *
 * @return				true 	| If set successfully
 *						false 	| If this player not connected
 *
 * @error 				If player not connected.
 *
 */
native ze_set_user_zombie_ex(id, iInfector);

/**
 * Description:	Set user to human team.
 *
 * @param id		Client index.
 *
 * @return			true  | If set successfully
 *					false | If this player not connected
 *
 * @error 			If player not connected.
 *
 */
native ze_set_user_human(id);

/**
 * Description:		Increase human speed with this factor.
 *					This factor added to his current speed depend on which weapon he carries.
 *
 * @param id		Client index.
 * @param iFactor	The factor to be added to current speed.
 *
 * @return			true  | If set successfully
 *					false | If this player not connected
 *
 * @error 			If player not connected.
 *
 * @note			This native will add speed to current speed.
 *					For example, ze_set_human_speed_factor(id, 0) will not set player speed to zero
 *					it won't increase his speed so he will have normal weapon speed.
 *					Example, if player carry knife and ze_set_human_speed_factor(id, 20) his speed will be 
 *					increased by 20 so his total speed will be 270 (default knife speed: 250)
 *					You may use negative factors to decrease this speed.
 *					Using this native will set the players speed for the whole map.
 *					Speeds reset if this player disconnect, or reset using reset native.
 *					This is limited by sv_maxspeed cvar.
 *					This will throw error in case of invalid player.
 *
 */
native ze_set_human_speed_factor(id, iFactor);

/**
 * Description:	Reset human speed to default value used in ze_human_speed_factor cvar.
 *
 * @param id	Client index.
 *
 * @return		true  | If reset successfully
 *				false | If this player not connected
 *
 * @error 		If player not connected.
 *
 * @note		This will remove the custom speed factor set by
 *				ze_set_human_speed_factor(id, iFactor) native.
 *				And will use the default factor in ze_human_speed_factor cvar.
 *				This will throw error in case of invalid player.
 *
 */
native ze_reset_human_speed(id);

/**
 * Description:		Set this zombie speed to custom value.
 *
 * @param id		Client index.
 * @param iSpeed	Speed to set this zombie to.
 *
 * @return			true  | If set successfully
 *					false | If this player not connected
 *
 * @error 			If player not connected.
 *
 * @note			This native will set custom speed for this zombie
 *					and will not use value defined in ze_zombie_speed cvar
 *					This is limited by sv_maxspeed cvar.
 *					This will throw error in case of invalid player.
 *
 */
native ze_set_zombie_speed(id, iSpeed);

/**
 * Description:	Reset zombie speed to default value used in ze_zombie_speed cvar.
 *
 * @param id	Client index.
 *
 * @return		true  | If reset successfully
 *				false | If this player not connected
 *
 * @error 		If player not connected.
 *
 */
native ze_reset_zombie_speed(id);

/**
 * Description:	Get user knockback.
 *
 * @param id		Client index.
 *
 * @return			Knockback value | if client valid
 *					NULLENT			| If player not connected or ins't Zombie
 *
 * @error 			If player not connected.
 *
 */
native ze_get_user_knockback(id);

/**
 * Description:	Get user knockback (Float value).
 *
 * @param id		Client index.
 *
 * @return			Knockback value | if client valid
 *					NULLENT			| If player not connected or ins't Zombie
 *
 * @error 			If player not connected.
 *
 */
native Float:ze_get_user_knockback_f(id);

/**
 * Description:	Set user knockback.
 *
 * @param id			Client index.
 * @param flKnockback	Knockback value as float.	
 *
 * @return				true  | If set successfully
 *						false | If this player not connected
 *
 * @error 				If player not connected.
 *
 */
native ze_set_user_knockback(id, Float:flKnockback);

/**
 * Description:	Reset user knockback to use value from CVAR.
 *
 * @param id	Client index.
 *
 * @return		true	| If reset successfully
 *				false	| If this player not connected
 *
 * @error 		If player not connected.
 *
 */
native ze_reset_user_knockback(id);

/**
 * Description:			Set user gravity.
 *
 * @param id			Client index.
 * @param iGravity		Gravity value.	
 *
 * @return				true	| If set successfully
 *						false	| If this player not connected
 *
 * @error 				If player not connected.
 *
 */
native ze_set_user_gravity(id, iGravity);

/**
 * Description:	Reset user gravity to use value from CVAR.
 *
 * @param id	Client index.
 *
 * @return		true	| If reset successfully
 *				false	| If this player not connected
 *
 * @error 		If player not connected.
 *
 */
native ze_reset_user_gravity(id);

/**
 * Description:	Remove zombie freeze time message.
 *
 * @return		true  | If removed successfully
 *				false | If message still not appeared (message not there)
 *
 *
 */
native ze_remove_zombie_freeze_msg();

/**
 * Description:	Get player escape coins.
 *
 * @param id	Client index.
 *
 * @return		Player coins | If this player in server
 *				false		 | If this player not connected
 *
 * @error 		If player not connected.
 *
 */
native ze_get_escape_coins(id);

/**
 * Description:		Set player escape coins.
 *
 * @param id		Client index.
 * @param iAmount	Amount of escape coins to set.
 *
 * @return			true  | If set successfully
 *					false | If this player not connected
 *
 * @error 			If player not connected.
 *
 */
native ze_set_escape_coins(id, iAmount);

/**
 * Description: 	Give player escape coins.
 *
 * @param id 		Client index.
 * @param iFactor 	Amount of escape coins to give.
 *
 * @return 			True 	| If successfully.
 *					False 	| If this player not connected.
 *
 * @error 			If client not connected.
 *
 */
native ze_give_escape_coins(id, iFactor);

/**
 * Description:		Get escape leader index.
 *
 * @return			Escape leader id
 *
 * @note			Make sure to use it when game already started.
 *					If rank mode which is used the native will return rank 1 player.
 *
 */
native ze_get_escape_leader_id();

/**
 * Description:		Stop/Resume setting rendering from ze_effects_messages.sma plugin.
 *
 * @param id		Client index.
 * @param bSet		True or false, True will stop the rendering that comes from ze_effects_messages.sma
 *					false will continue setting rendering from ze_effects_messages.sma
 *
 * @return			true  | If set successfully
 *					false | If this player not connected
 *	
 * @erorr 			If player not connected.
 *	
 * @note			This native will not throw error if player not connected. It will just return false.
 *					You before you set rendering for any player in any plugin you should first make: ze_stop_mod_rendering(id, true)
 *					This will ensure that no rendering is setting from ze_effects_messages.sma plugin.
 *					When you remove rendering, you should use: ze_stop_mod_rendering(id, false)
 *
 */
native ze_stop_mod_rendering(id, bool:bSet);

/**
 * Description:	Used to set/stop fire on zombie.
 *
 * @param id	Client index.
 * @param bSet	Boolean value, true will set fire on zombie.
 *				false will stop fire on zombie.
 *
 * @return		true  	| If successfully set/stop fire on zombie.
 *				false 	| If returned 1 in ze_fire_pre() forward.
 *						Mean if fire action stopped by the pre forward.
 *				NULLENT	| If this zombie not alive.
 *
 * @note		If zombie fired right now, you can use this to stop the fire
 *				imediatly by using: ze_set_fire_grenade(id, false)
 *				Same you can fire him at anytime.
 *				Always check if user alive or not when using this native.
 *				This will throw error in case of invalid player.
 *				You can also set fire on alive humans.
 *
 */
native ze_set_fire_grenade(id, bSet);

/**
 * Description:	Used to set fire on zombie with duration.
 *
 * @param id	Client index.
 * @param delay Fire duration, -1 = CVar duration.
 *
 * @return		true  		| If successfully set/stop fire on zombie.
 *				false 		| If returned 1 in ze_fire_pre() forward.
 *							Mean if fire action stopped by the pre forward.
 *				NULLENT 	| If this zombie not alive.
 *
 * @note		If zombie fired right now, you can use this to stop the fire
 *				imediatly by using: ze_set_fire_grenade(id, false)
 *				Same you can fire him at anytime.
 *				Always check if user alive or not when using this native.
 *				This will throw error in case of invalid player.
 *				You can also set fire on alive humans.
 *
 */
native ze_set_fire_grenade_ex(id, delay);

/**
 * Description:	Tells you if this zombie burning now or not.
 *
 * @param id	Client index.
 *
 * @error 		If player not connected.
 *
 * @return		true  	| If this zombie burning now.
 *				false 	| If this zombie not burning.
 *				NULLENT | If this zombie not alive.
 *
 */
native ze_zombie_in_fire(id);

/**
 * Description:	Used to set/stop freeze on zombie.
 *
 * @param id	Client index.
 * @param bSet	Boolean value, true will freeze zombie. false will unfreeze zombie.
 *
 * @return		true  	| If successfully freeze/unfreeze zombie.
 *				false 	| If returned 1 in ze_frost_pre() forward.
 *						Mean if freeze action stopped by the pre forward.
 *						Or if player already frozen
 *				NULLENT | If this zombie not alive.
 *
 * @note		If zombie frozen right now, you can use this to unfreeze him
 *				imediatly by using: ze_set_frost_grenade(id, false)
 *				Same you can freeze him at anytime.
 *				Always check if user alive or not when using this native.
 *				This will throw error in case of invalid player.
 *				You can also freeze alive humans.
 *
 */
native ze_set_frost_grenade(id, bSet);

/**
 * Description:	Used to set/stop freeze on zombie with specific duration.
 *
 * @param id		Client index.
 * @param bSet		Boolean value, true will freeze zombie. false will unfreeze zombie.
 * @param flDelay	Frost Nade Freeze Duaration, -1 = duration time exists in ze_frost_duration.
 *
 * @return		true  	| If successfully freeze/unfreeze zombie.
 *				false 	| If returned 1 in ze_frost_pre() forward.
 *						Mean if freeze action stopped by the pre forward.
 *						Or if player already frozen
 *				NULLENT | If this zombie not alive.
 *
 * @note		If zombie frozen right now, you can use this to unfreeze him
 *				imediatly by using: ze_set_frost_grenade(id, false)
 *				Same you can freeze him at anytime.
 *				Always check if user alive or not when using this native.
 *				This will throw error in case of invalid player.
 *				You can also freeze alive humans.
 *
 */
native ze_set_frost_grenade_ex(id, bSet, Float:flDelay = -1.0);

/**
 * Description:	Tells you if this zombie frozen now or not.
 *
 * @param id	Client index.
 *
 * @error 		If player not connected.
 *
 * @return		true  	| If this zombie frozen now.
 *				false 	| If this zombie unfrozen.
 *				NULLENT | If this zombie not alive.
 *
 */
native ze_zombie_in_forst(id);

/**
 * Description:			Register extra-item in the items-menu.
 *
 * @param szItemName[]	Item name.
 * @param iCost			Item cost.
 * @param iLimit		Item limit.
 *
 * @return				Item id in the menu, if successfully registered.
 *						ZE_WRONG_ITEM | If item name was empty or item already registered.
 *
 * @error 				If player not connected.
 *
 * @note				ZE_WRONG_ITEM is defined as -1
 *						Limit must be >= 0, 0 means unlimited.
 *						Use this native in plugin_init() forward.
 *
 */
native ze_register_item(const szItemName[], iCost, iLimit);

/**
 * Description:	Open items menu for specific player.
 *
 * @param id	Client index.
 *
 * @return		true  | If successfully opened to the player.
 *				false | If this player not connected.
 *
 * @error 		If player not connected.
 *
 */
native ze_show_items_menu(id);

/**
 * Description:			Force player to buy specific extra-item.
 *
 * @param id			Client index.
 * @param iItemid		Item id, returned by ze_register_item() or ze_get_item_id().
 * @param bIgnoreCost	true will ignore the cost, false will not ignore cost.
 *
 * @return				true  | If successfully bought item.
 *						false | If this player not connected or itemid is invalid.
 *
 * @error 				If player not connected.
 *
 */
native ze_force_buy_item(id, iItemid, bIgnoreCost);

/**
 * Description:			Get item id by it's name.
 *
 * @param szItemName[]	Item name that used in ze_register_item().
 *
 * @return				Item index    | If item name is valid.
 *						ZE_WRONG_ITEM | If this item name invalid.
 *
 * @note				ZE_WRONG_ITEM is defined as -1
 *						Item name used in ze_register_item() native,
 *						is called the real item name. 
 *						this native deal with real name not name in ze_extraitems.ini
 *
 */
native ze_get_item_id(const szItemName[]);

/**
 * Description:			Get item cost (Integer) by it's id.
 *
 * @param iItemid		The item id from ze_register_item() or ze_get_item_id().
 *
 * @return				Item cost     | If item id is valid.
 *						ZE_WRONG_ITEM | If item id is invalid.
 *
 * @note				ZE_WRONG_ITEM is defined as -1
 *
 */
native ze_get_item_cost(iItemid);

/**
 * Description:		Add extra-text to the item name.
 *
 * @param szText[]	Text to be added.
 *
 * @noreturn
 *
 * @note			This native is used in ze_select_item_pre() forward.
 *					Maximum length of the text is 32
 *
 */
native ze_add_text_to_item(const szText[]);

/**
 * Description:		Return item limit.
 *
 * @param iItemid	Item id.
 *
 * @return			Limit 		  | If this itemid is valid.
 *					ZE_WRONG_ITEM | If this itemid is invalid.
 *
 * @note			ZE_WRONG_ITEM is defined as -1
 *
 */
native ze_get_item_limit(iItemid);

/**
 * Description:		Return item global limit.
 *
 * @param iItemid	Item id.
 *
 * @return			Global Limit  | If this itemid is valid.
 *					ZE_WRONG_ITEM | If this itemid is invalid.
 *
 * @note			ZE_WRONG_ITEM is defined as -1
 *
 */
native ze_get_item_global_limit(iItemid);

/**
 * Description:		Check if this item id is valid or not.
 *
 * @param iItemid	Item id to check.
 *
 * @return			true  | If this itemid is valid.
 *					false | If this itemid is invalid.
 *
 */
native ze_is_valid_itemid(iItemid);

/**
 * Description:		Return the item name by it's id.
 *
 * @param iItemid	Item id to check.
 * @param szName[]	String to copy the string name to.
 * @param iLen		The string szName[] max length.
 *
 * @return			true 		  | If item name copied successfully to szName[] string.
 *					ZE_WRONG_ITEM | If this itemid is invalid.
 *
 */
native ze_get_item_name(iItemid, const szName[], iLen);

/*
* Description:		Set this item for specific level.
*
* @param iItemid	Item id.
* @param iLevel		Level must player have to buy this item.
*
* @return			true 		  | If level set successfully.
*					false 		  | If level < 0 (Failed).
*					ZE_WRONG_ITEM | If this itemid is invalid.
*
* @note				Use this under ze_register_item() native in plugin_init() forward.
*					To use this native level plugin must be installed.
*
*/
native ze_set_item_level(iItemid, iLevel);

/**
 * Description:		Get item level.
 *
 * @param iItemid	Item id.
 *
 * @return			Item level 	  | If this itemid is valid.
 *					ZE_WRONG_ITEM | If this itemid is invalid.
 *					
 * @note			To use this native level plugin must be installed.
 *
 */
native ze_get_item_level(iItemid);

/*
* Description:		Set this item for VIPs on specific flag.
*
* @param iItemid	Item id.
* @param szFlag		Flag to set item to: a, b, c ... etc.
*
* @return			true 		  | If set successfully for VIPs.
*					ZE_WRONG_ITEM | If this itemid is invalid.
*
* @note				Use this under ze_register_item() native in plugin_init() forward.
*					To use this native VIP plugin must be installed.
*					Make sure to use only one flag.
*
*/
native ze_set_item_vip(iItemid, szFlag[]);

/**
 * Description:		See if this item for VIP or not, and on which flag.
 *
 * @param iItemid	Item id.
 *
 * @return			Flag this item set to (return integer).
 *					ZE_WRONG_ITEM | If this itemid is invalid.
 *					
 * @note			To use this native VIP plugin must be installed.
 *					This native works like ze_get_vip_flags() native.
 *
 */
native ze_get_item_vip(iItemid);

/**
 * Description:	Check if this zombie in madness or not.
 *
 * @param id	Client index.
 *
 * @return		true	| This zombie in madness.
 *				false	| If this zombie not in madness.
 *				NULLENT | If this player not connected or he is human.
 *
 */
native ze_zombie_in_madness(id);

/**
 * Description:	Show weapon menu for player.
 *
 * @param id	Client index.
 *
 * @return		true  | If menu opened successfully.
 *				false | If this player not connected.
 *
 * @error 		If player not connected.
 *
 */
native ze_show_weapon_menu(id);

/**
 * Description:	Check if auto buy enabled or not.
 *
 * @param id	Client index.
 *
 * @return		true  | If auto buy enabled.
 *				false | If auto buy disabled.
 *				-1 	  | If this player not connected.
 *
 * @error 		If player not connected.
 *
 */
native ze_is_auto_buy_enabled(id);

/**
 * Description:	This will disable auto buy for player.
 *
 * @param id	Client index.
 *
 * @return		true  | If disabled successfully.
 *				false | If this player not connected.
 *
 * @error 		If player not connected.
 *
 */
native ze_disable_auto_buy(id);

/**
 * Description:	Enable and disable Ready&PreRelease sounds for any player.
 *
 * @param id	Client index.
 * @param bSet	true will enable sounds, false will disable sounds.
 *
 * @return		true  | If successfully disabled/enabled.
 *				false | If this player not connected.
 *
 * @error 		If player not connected.
 *
 */
native ze_set_starting_sounds(id, bool:bSet);

/**
 * Description:	Enable and disable ambiance sound for any player.
 *
 * @param id	Client index.
 * @param bSet	true will enable sound, false will disable sound.
 *
 * @return		true  | If successfully disabled/enabled.
 *				false | If this player not connected.
 *
 * @error 		If player not connected.
 *
 */
native ze_set_ambiance_sounds(id, bool:bSet);

/**
 * Description:	Check for any player if Ready&PreRelease sounds enabled or disabled.
 *
 * @param id		Client index.
 *
 * @return		true	| If sounds enabled.
 *				false	| If sounds disabled.
 *				NULLENT | If this player not connected.
 *
 * @error 		If player not connected.
 *
 */
native ze_is_starting_sounds_enabled(id);

/**
 * Description:	Check for any player if ambiance sounds enabled or disabled.
 *
 * @param id	Client index.
 *
 * @return		true	| If sounds enabled.
 *				false	| If sounds disabled.
 *				NULENT	| If this player not connected.
 *
 * @error 		If player not connected.
 *
 */
native ze_is_ambiance_sounds_enabled(id);

/**
 * Description:		Show HUDs info for player.
 *
 * @param 			Client index
 *
 * @return 			true  | If HUDs is shown successfully.
 *					false | If this player not connected.
 *
 * @error 			If player not connected.
 *
 */
native ze_show_user_hud_info(id);

/**
 * Description:		Hide HUDs info for player.
 *
 * @param 			Client index
 *
 * @return 			true  | If HUDs is hidden successfully.
 *					false | If this player not connected.
 *
 * @error 			If player not connected.
 *
 */
native ze_hide_user_hud_info(id);

/**
 * Description: 	Allow spawning player Zombie.
 *
 * @param id 		Client index.
 *
 * @return 			true  | If allowed successfully.
 *					false | If player not connected.
 *
 * @error 			If player not connected.
 *
 */
native ze_allow_respawn_as_zombie(id);

/**
 * Description: 	Disallow spawning player Zombie.
 *
 * @param id 		Client index. 
 *
 * @return 			true  | If disallowed successfully.
 *					false | If player not connected.		
 *
 * @error 			If player not connected.
 *
 */
native ze_disallow_respawn_as_zombie(id);

/**
 * Description:		Registers a new game mode.
 *
 * @param szName[]	Game mode name.
 * 
 * @return 			A game mode ID, or ZE_WRONG_GAME on failure.
 *
 * @note 			Max length of game mode name is 32 characters.
 *
 * @error 			If game mode name is already exists, or game mode without name.
 *
 */
native ze_gamemode_register(const szName[]);

/**
 * Description:		Sets a default game mode.
 *
 * @param game_id 	A valid game mode ID.
 *
 * @return 			true  | If set successfully.
 *					false | Otherwise.
 *
 * @error 			If game mode ID is not a valid.
 *
 */
native ze_gamemode_set_default(const game_id);

/**
 * Description: 	Gets a current game mode.
 *
 * @noparam
 *
 * @return 			A game mode ID, or ZE_WRONG_GAME if game mode not chosen yet.
 *
 * @note 			ZE_WRONG_GAME is -1.
 */
native ze_gamemode_get_current();

/**
 * Description:		Gets a game mode's name.
 *
 * @param szName[] 	The buffer to store string in.
 * @param iLen 		Character size of the output buffer.
 *
 * @return 			true  | If successfully.
 *					false | Otherwise.
 *
 * @error 			If a game mode ID is invalid.
 *
 */
native ze_gamemode_get_name(const game_id, szName[], iLen);

/**
 * Description: 	Gets a game mode's ID.
 *
 * @param szName[] 	Game mode name to look for.
 *
 * @return 			A game mode ID, ZE_WRONG_GAME if not found.
 *
 */
native ze_gamemode_get_id(const szName[]);

/**
 * Description: 	Get number of registered game modes.
 *
 * @noparam
 *
 * @return 			Number of registered game modes.
 *
 */
native ze_gamemode_get_count();

/**
 * Description: 	Forces a game mode to start and stop countdown.
 *
 * @param game_id 	A valid game mode ID.
 *
 * @return 			ture  | If started successfully.
 *					false | If game mode can't start.
 *
 * @error 			If a game mode ID is invalid.
 *
 */
native ze_gamemode_start(const game_id);

/**
 * Description: Hide rank HUD for specific player.
 *
 * @param id 	Client index.
 *
 * @return 		ture  | If hidden successfully.
 *				false | If player not connected.
 *
 * @error 		If player not connected.
 *
 */
native ze_hide_user_rankhud(const id);

/**
 * Description: Show rank HUD for specific player.
 *
 * @param id 	Client index.
 *
 * @return 		true  | If displays successfully.
 *				false | If player not connected.
 *
 * @error 		If player not connected.
 *
 */
native ze_show_user_rankhud(const id);

/**
 * Description: Check player is first Zombie or not.
 *
 * @param id 	Client index.
 *
 * @return 		true 	| If player is first Zombie.
 *				false 	| If player in not first Zombie.
 *
 * @note 		Native will return false, If player not connected or not zombie.
 *				This native is working in Escape Mode.
 *
 */
native bool:ze_is_user_first_zombie(const id);

/**
 * Description: Check player is last Zombie.
 *
 * @param id 	Client index.
 *
 * @return 		true 	| If player is last Zombie
 *				false 	| If player not alive or connected or Is not Zombie or Is not last Zombie 
 *
 */
native bool:ze_is_user_last_zombie(const id);

/**
 * Description: Check player is last Human.
 *
 * @param id 	Client index.
 *
 * @return 		true 	| If player is last Human
 *				false 	| If player not connected or Is not Zombie or Is not last Human 
 * 
 */
native bool:ze_is_user_last_human(const id);

/**
 * Description: Get client index of last Human.
 *
 * @noparam 
 *
 * @return 		Client index of last Human.
 *
 */
native ze_get_last_human();

/**
 * Description: Get client index of last Zombie.
 *
 * @noparam
 *
 * @return 		Client index of last Zombie.
 *
 */
native ze_get_last_zombie();

/**
 * Description: Set player custom Night Vision with colors.
 *
 * @param id 		Client index.
 * @param iRed 		Red color.
 * @param iGreen 	Green color.
 * @param iBlue 	Blue color.
 * @param iDensity 	Nightvision density.
 * @param bAuto 	true = Enable night vision automatic | false = Otherwise.
 * 
 * @return 			true 	| If set successfully. 
 * 					false 	| If player not connected.
 *
 * @error 			If player not connected.
 *
 */
native ze_set_user_nvg(id, iRed, iGreen, iBlue, iDensity, bool:bAuto = true);

/**
 * Description: Remove player custom Night Vision.
 *
 * @param id 	Client index.
 *
 * @return 		true 	| If reset successfully.
 *				false 	| If player not connected.
 *
 * @error 		If player not connected.
 *
 */
native ze_reset_user_nvg(id);

/**
 * Description: Check Night Vision is ON or OFF.
 *
 * @param id 	Client index.
 *
 * @return 		true 	| If nightvision on.
 *				false 	| If nightvision off or player not connected.
 *
 */
native bool:ze_is_nvg_on(id);

/**
 * Description: Check player is Nemesis.
 *
 * @param id 	Client index.
 *
 * @return  	true 	| If player is Nemesis.
 *				false 	| If player is not Nemesis or Is not connected or Is not Zombie.
 *
 *
 */
native bool:ze_is_user_nemesis(id);

/**
 * Description: Set player Nemesis.
 *
 * @param id 	Client index.
 *
 * @return 		true 	| If set successfully.
 * 				false 	| If player not connected.
 *
 * @error 		If player not connected.
 *
 */
native ze_set_user_nemesis(id);

/**
 * Description: Remove player Nemesis attributes
 *
 * @param id 		Client index.
 * @param bZombie	Set player Zombie attributes after remove.
 *
 * @return 			true 	| If remove successfully.
 * 					false 	| If player not connected.
 *
 * @note 			Nemesis health never reset, When remove Nemesis attributes.
 *
 * @error 			If player not connected.
 *
 */
native ze_remove_user_nemesis(id, bool:bZombie = true);

/**
 * Description: Check round is Escape mode.
 *
 * @noparam
 *
 * @return 		true 	| If round is Escape Mode.
 *				false 	| Otherwise.
 *
 */
native bool:ze_is_round_escape();

/**
 * Description: Check round is Nemesis mode.
 *
 * @noparam
 *
 * @return 		true 	| If round is Nemesis Mode.
 *				false 	| Otherwose.
 *
 */
native bool:ze_is_round_nemesis();

/**
 * Description: Set player Leap (Long-Jump).
 *
 * @param id 			Client index.
 * @param flForce 		Leap force.
 * @param flHeight 		Leap height.
 * @param flCooldown 	Leap cooldown.
 *
 * @return 				true 	| If set successfully.
 *						false 	| If player not connected.
 *		
 * @error 				If player not connected.	
 *		
 */
native ze_set_user_leap(id, Float:flForce, Float:flHeight, Float:flCooldown);

/**
 * Description: Remove player Leap (Long-Jump).
 *
 * @param id 	Client index.
 *
 * @return 		true 	| If removed successfully.
 *				false 	| If player not connected.
 *
 * @error 		If player not connected.
 *
 */
native ze_remove_user_leap(id);

/**
 * Description: Block the player use Leap in every team.
 *
 * @param id 	Client index.
 *
 * @return 		true 	| If blocked successfully.
 *				false 	| If player not connected.
 *				
 * @error 		If player not connected.			
 *				
 */
native ze_block_user_leap(id);

/**
 * Description: Unblock the player to use Leap for All teams.
 *
 * @param id 	Client index.
 *
 * @return 		true 	| If successfully.
 *				false 	| If player not connected.
 *				
 * @error 		If player not connected.			
 *				
 */
native ze_unblock_user_leap(id);