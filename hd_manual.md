*(no line breaks? get a real text editor like notepad++.)*

# HIDEOUS DESTRUCTOR
### A WEAPONS AND MONSTERS MOD FOR GZDOOM

## QUICKSTART

* Look down or select bandages (first weapon on slot 9) to see if you're bleeding.
* Use medikits (in inventory or second weapon on slot 9) or bandages to stop bleeding.
* Hit the unload key (user4) to take ammo out of a weapon.
* Use items to pick them up, and enemies to melee them.
* Hold the jump key in front of a low ledge to climb over it.
* Hold the run/walk key to sprint. Use run/walk toggle to switch from walk and run.
* Hold the use/open door key to view all inventory and available weapon functions.


***

**CONTENTS**

* [I. INTRODUCTION](#I-INTRODUCTION)
* [II. GETTING STARTED](#II-GETTING-STARTED)
* [III. CONTROLS](#III-CONTROLS)
* [IV. COMMANDS AND CVARS](#IV-COMMANDS-AND-CVARS)
* [V. ITEMS](#V-ITEMS)
* [VI. LIVES](#VI-LIVES)
* [VII. WEAPONS](#VII-WEAPONS)
* [VIII. MONSTERS](#VIII-MONSTERS)

***

## I. INTRODUCTION

The Hideous Destructor weapons and monsters mod is a speculative re-imagining of Freedoom's gameplay: what if this game, with its gun-toting zombie mooks and 90s-soft-sci-fi and ridiculous firepower, didn't hold things back for the benefit of the player? What if a lone robo-zombie coming at you with an assault rifle became a cause of concern *now*, rather than ten minutes later when your health suddenly dips to single digits because your teammate ran in front of your rocket? What if your guns actually had some serious range and stopping power - as did the enemy's, creating opportunities and risks that would have been much harder to model before? What if you actually had to act like 100 humanoid aggressors were coming at you with guns?

To accomplish this design objective, HD makes four main changes:

* Slowing the player to relatively plausible human speeds subject to fatigue and (some) injury, while providing more options to go faster or slower with appropriate tradeoffs.
* Exaggerating both the strengths and (relative) weaknesses of all weapons and monsters, turning into key gameplay elements implications hinted at by lore and artwork that are glossed over in canon.
* Creating more incentives for the player not to get hit, while making it harder to avoid damage without some coherent attack plan and proper use of cover.
* Adding an inventory system to give the player more control over what they collect and use and when.

The result is a more intense, frustrating and brutal experience where everyone is fighting at a much more equal level than before and nothing can be taken for granted. Have fun.

The setting fluff is primarily written to fit events express and implied in Freedoom. Please read `hd_lore_id.txt` for the lore that was originally written for the id Software games Doom and Doom II: Hell on Earth. There is no continuity whatsoever with the Doom novels or Doom 3.

To the extent logically possible, whether written for Doom or Freedoom or otherwise, Hideous Destructor has absolutely nothing whatsoever to do with anything in the Bethesda games, or with any Middle-Earth material not personally written by John Ronald Reuel Tokien or Christopher Tolkien.

## II. GETTING STARTED

To play Hideous Destructor, save the GitHub download into a folder and load that folder as you would any normal GZDoom mod file.

If using a release, the .pk7 file is just a renamed .7z file. Treat it as a .pk3 to be loaded into GZDoom.

Hideous Destructor is designed to be run on any map that does not define its own weapons and monsters.

HD makes use of all canonical Doom keys plus all built-in GZDoom weapon keys. Make sure your run/walk key is set to something you can hold down comfortably while moving, and Reload, Zoom, Drop Weapon and the additional buttons Alternate Reload, Fire Mode and Unload (user buttons 1, 2 and 4 respectively), somewhere easily accessible without being too easy to hit by accident. More about these controls can be found in Part III of this text.

With that done, you're ready to begin.

### Compatibility notes

Hideous Destructor uses many advanced GZDoom features. If GZDoom has fixed some unusual vanilla behaviour, HD will typically rely on that fix, and if GZDoom has not, HD will often supply its own fix. Please turn off all vanilla compatibility flags to be sure.

In particular, "Use Doom code for hitscan attacks" will cause all headshots to miss.

### The bleeding system

When you get hit in HD, the injury is recorded in addition to your hitpoint loss.

Look down every so often to see if you are leaving a blood trail, or check what message comes up when you use weapon slot 9. Bleeding means you are losing health and will eventually die if it is not stopped.

Armour absorbs some damage and reduces the bleeding rate of any injury it blocks. If it prevents a bullet from penetrating that bullet will only mildly impact you.

Of the mundane tech items, only medikits can help stop bleeding permanently, though stimpacks and berserk packs might buy you some time.

Absent a proper medikit, you can try to bandage yourself using improvised objects. This is abstracted into weapon #9: just stand still and hold the fire button until the help text tells you you're done. No attempt is guaranteed to work. Your armour is designed to apply pressure and aid you in this so do NOT take it off the way you must to prepare for a medikit.

Side note about being on fire: As you cannot truly "stop, drop and roll" in the Doom engine, there is an option of spinning around or turning left and right very quickly to try to put out a fire earlier. Doing so\* in liquids\*\*, sand or gooey snake floors while crouched greatly increase your chances of putting out the flames in time.

\* *or any rapid movement*
\*\* *other than nukage or lava*

### The damage system

Hideous Destructor tracks burn damage and "aggravated" damage, as well as non-bleeding but still existent wounds. All accumulate to the detriment of your maximum HP.

You slowly heal from everything except aggravated damage over time.

Aggravated damage represents long-term damage that cannot be readily healed due to fundamental interference with your body's metaphysical pattern. It can only be healed by supernatural means, but may be inflicted by both supernatural and technological means (most notably balefire and the berserk pack's aftereffects).

Soul sphere and blue potion magic will remove lethal and aggravated damage.

### The aiming system

For the most part Hideous Destructor functions like Doom: point the middle of your screen at the monster, hit the fire button, and insha Allah the monster will fall down and stop hurting you.

There is no auto-aim anywhere in HD. In fact, if you move or turn too quickly it can throw off your aim a bit.

Hold Use or Zoom to lower your mouse sensitivity, subject to the hd_aim/bracesensitivity setting. Setting hd_usefocus to false will restrict this behaviour to Zoom. Zoom will also bring up your scope view if your weapon has one and it is not up already, and change your strafe keys to lean keys unless hd_nozoomlean is set to true.

### Customizing your loadout

HD lets you set custom loadouts through the cvars hd_loadout1 through 20.

Each of these is a string that you can configure to add your loadout. What is available for backpacks is a subset of what is available generally (e.g., no BFG).

The syntax is as follows:

    <pic>#<name>: xxx yy, zzz aa, bbb cc /<description>

where xxx and zzz are 3-character codes referring to an item.

For non-weapons, yy, aa, etc. are the quantity of the item. For weapons, the number may be followed by a longer string that defines specific configurations for the given weapon (more on this below).

<pic> is the lump name for the graphic ("PISTA0", etc.) and must be followed by #, while <name> is the display name for the loadout selection menu and must be followed by a colon; these are optional (and you may specify either without the other, or specify the name before the pic as long as both precede the loadout data) and will default, respectively, to the icon/sprite of the first item indicated and "Loadout <number>".

<description> is completely optional and must be placed at the very end.

Items are separated by commas, spaces optional. If you only want one of a given item, you may also omit the number (e.g. "bos,710,7mm20" for a Boss, a single 10-round 7.76mm clip and 20 loose 7.76mm rounds).

NOTE: Due to technical reasons spaces *must* be omitted from loadout strings if they're being set via the "+set" method at the command line.

The first item is the weapon you pull out at start. If the first item is not a weapon, you start with your hands free. If you want to start with a weapon and nothing else, but do not want it drawn at start, use the code for fists ("fis") at the start of your loadout.

Sometimes you'll find a "-" in a loadout. This is an older way of setting backpack contents: it implicitly gives you a backpack, then all items listed after it are stored in that backpack.

The loadout system will detect items from mods for HD like Ugly as Sin. (modding note: it must inherit from "HDPickup" or "HDWeapon" and have a unique "refid" defined and "fitsinbackpack" set to true if it is to be placed in a backpack.) To see a list of all items in the currently loaded session, type "give loadoutitemlist" in the console.

The amount for "key" is treated as a bitmask: 1 red, 2 yellow, 4 blue, 7 all.

The standard soldier kit "sol" provides garrison armour, a pistol, 3 frags, a DERP and one ladder.

Some shortcuts:
* "doomguy": Fully tac-loaded pistol with 2 extra mags and 4 loose rounds (total 50 shots)
* "insurgent": Weighted randomization.
* "hd_loadout*": Only relevant for hd_forceloadout, this forces everyone to use whatever they've set for the loadout number placed where the star is.

### Customizing your weapons

The syntax is as follows:

    ... xxx yyyy zz aaaa bb ...

where xxx is the item code, yyyy/aaaa are the variable names and zz/bb are the values assigned to them.

Spaces are optional/prohibited as with the rest of the loadout but the variable name must be written in full. If you do not assign a value it will default to 1 (i.e., true for a boolean value). A value less than zero means to use the default.

You can have multiple weapons of the same type configured in the same way or in different ways, e.g., "z66, z66 3 nogl semi" will give you a main and 3 emergency backup plinkers for your mouse problem.

Please see the individual weapon entries in this manual for the variables available for each.

## III. CONTROLS

### General

Hideous Destructor uses all eight of GZDoom's canonical weapon buttons. The four generic "User" buttons have special names, being respectively: Alternate Reload, Fire Mode, Mag Manager and Unload.

Press and hold Use to bring up a list of available functions for your selected weapon.

Some weapon functions may require you to hold down one button (or two) while hitting another.


### Dropping items

You will be moving things in and out of your inventory frequently. It is recommended that you bind the following, in descending order of importance:

1. Dropping your weapon, in the usual manner (to forcibly throw your weapon, hold zoom while hitting the drop weapon key)
2. hd_dropone
3. hd_purge

See "Commands and CVars" below for details.

### Managing ammo

Console command: +user3 or `use MagManager`

Default key: none

For weapons that are loaded with magazines or other containers from which you can freely move individual rounds, you can open the magazine manager to fill up some mags/clips for future use - or cannibalize some from one type of mag/clip for the other.

To access the mag manager, type "use MagManager" in the console, or similarly use the specific GZDoom actor name for that mag type, or hit the User3 key for a weapon that uses that ammo type.

As with the backpack, holding Zoom will let you scroll through the items, reload puts things into the container and unload takes them out.

Tap fire/altfire to switch between mags one at a time; if you do this while Zoom is held down, you will switch between mag types instead.

Reload/Unload while holding Fire Mode will take mags in and out of your backpack if you have one.

### Aiming and turning

If you are standing still, press and hold Use or Zoom to reduce your mouse sensitivity (and enable the scope if hd_noscope is set to true).

If you have some map geometry right underneath where your weapon is pointing (including the floor when you are crouching), or your barrel is touching a vertical wall, this will also brace your gun against it for additional support and precision.

If you must make a very wide turn, you will automatically step to the side as you adjust your body. Turning while already moving ignores this function.

Your turn may be stopped by the muzzle of your weapon colliding with a wall; hold the sprint key or switch to fist or a shorter weapon to avoid this.

### Sprinting

Console command: +speed

Default key: Whatever you have set it to

Your unburdened, ininjured movement speed, with "always run" off, is a walk of about 5 km/h. To make a quick dash at full speed (comparable to Usain Bolt), hold on to the +speed key while moving. You will generally put away your weapon as you sprint.

If you have "always run" on, your normal speed increases to about 18 km/h, but you cannot recover from fatigue while moving at that speed.

Holding sprint and crouch at the same time has you scrambling along the ground, unable to shoot but achieving something close to your normal, unencumbered moving speed.

You can sprint forward continuously for about 100m before tiring out. If at any time you stop sprinting, you must substantially recover from your fatigue before you can start again.

Lunge/Slide: If you are standing while moving forward or sideways, hit the Crouch button to drop and lunge in the direction you are moving. Your turning will also be affected when you do this. Set hd_noslide to true to limit this behaviour to while sprinting.

### Jumping

Console command: `+jump`

Default key: Whatever you have set it to

If you walk right up to a ledge between waist and shoulder height, you can press and hold the jump key for about half a second to hoist yourself onto that ledge. You will briefly be unable to fire while doing this. This action cannot be done while crouching.

Switch to fist to empty your hands for a better climbing experience.

If you jump while moving forward and the way ahead of you is clear, you will leap forward. Good for crossing gaps and closing in for a beatdown.

If you hit the jump key in any other situation, you will make a normal vertical leap.

### Using

Console command: `+use`

Default key: Whatever you have set it to

You can open doors with it, as usual. But you also get two other functions:

Pickups: For most things, you must "use" an item to pick it up. If you cannot carry the item, you will put it back on the floor in front of you. For smaller items like loose rounds, you may hold the use key to continuously pick up many of them.

Kicking: pressing use in front of an enemy lets you kick them. (There is no animation for this; this mod is called hideous for a reason.) You can also kick away corpses and hand grenades if they're in the way.

Hold both Zoom and Speed while hitting Use on a thin door to try to kick it down. It might hurt a bit.

HUD: HD typically hides your complete inventory display. Pressing and holding use brings this up. It will also show how many arbitrary "blocks'" worth of equipment you are carrying.

### Leaning

Console commands: `+hd_leanleft`, `+hd_leanright`, `+hd_lean`

These are, respectively, commands that can be bound to buttons for leaning left, leaning right, and holding to lean in the direction of your sidemove input. The latter is also done through the Zoom key.

### Taunting

Console command: `hd_taunt`

Default key: b

Yells at the monsters, waking them and causing them to attack you.

### Playing Dead

Console command: `hd_playdead`

Default key: none

Puts yourself in incapacitated mode without actually getting hurt. Press Jump or attempt to sprint forward to get back up. While in this state (whether faking it or not), your only possible actions are to strip armour, press Fire to attempt to bandage wounds, or press Altfire to fumble for a stimpack - or a round, olive green parting gift for those nearby.

### Rangefinder

Console command: hd_findrange

Default key: none

Logs the distance of the object or map geometry you're pointing at.

## IV. COMMANDS AND CVARS

### Commands

* `hd_strip`: Takes off your armour. If you are not wearing any armour, this command will put on any spare armour you happen to be carrying.

  Hitting Reload while you have a medikit or bandages in hand, or double-tapping the use item key with another armour selected, will also strip your armour.

  You may need to strip off your backpack and/or environment suit first.

* `hd_dropone`: This will drop one unit of each type of ammo that applies to your current weapon. If you have both full mags and loose ammo, you drop all your loose ammo first; otherwise, if you specify a number after this command, you will drop that number instead. (For shotgun shells 4 shells equals one default unit, but if you specify a number you will drop exactly that many shells if you have enough.)

* `hd_purge`: This will drop all ammunition for which you do not have an appropriate weapon, along with empty cells (in the absence of a BFG) and broken robots. If you are holding Zoom while you execute this command, it will also drop any additional weapons you have more than one of the same type.

* `hd_slideon`, `hd_slideoff`: Like `hd_zoomon` and `hd_zoomoff` but for the hd_noslide cvar.

* `hd_clearcvs`: Resets all archived CVars (other than loadout cvars) to their defaults.

* `clearweaponspecial`: Sets the special of your currently held weapon to 0. The purpose is for some maps where a special cutscene or event is played when you pick up a certain weapon, but the mapper never considered that the player might be repeatedly dropping and picking back up the weapon so what should have been a one-time thing ends up playing every time you do a bit of complicated inventory management.


* `teamspawn`: In team deathmatch, any member of a team can type `teamspawn 666` in the console to set their own current position as the team spawnpoint. Similarly, any member of a team can type `teamspawn -1` or `teamspawn 999` to clear the team spawnpoint and resume respawning in random places. This is intended to allow your team to establish a well-fortified camping ground to cause as much grief to the opposing team as possible.

* `hd_doomguy` (cheat): This command, available anytime and not considered a cheat, will set you back to the good old naked marine with a pistol and 50 bullets.

### Commands (equipment-specific)

* `ab`: Type `ab <number>` in the console to set the airburst counter whenever you have an automatic rifle, blooper or rocket launcher out and ready to fire a grenade.

* `ied`: Type `ied <mode> <tag>` in the console to command your deployed IEDs. Mode 2 sets them to passive; 1 sets them to active; 999 detonates all of them at once.

  `detonate`, `iedpassive`, `iedactive`: shortcuts for `ied 999`, `ied 2` and `ied 1` respectively. Can also take tags.

* `iedtag`: If you feel weird about negative numbers, use this command to set your IED tag instead.

* `herp`: Type `herp <mode> <tag> <direction>` in the console to command your deployed HERPs, in a similar fashion to IEDs. Modes 1-2 are active and inactive respectively; mode 3 lets you change their base angle using the direction parameter (in degrees going counterclockwise).

* `herptag`: as `iedtag`.

* `herpdir`: Type `herpdir <direction> <tag>` as a shortcut alternative to `herp 3 <tag> <direction>`. Useful if you only have one HERP and don't want to bother typing that extra zero.

### CVars (host only) - gameplay meta

* `hd_debug` (0): Turns on some debug logging messages and displays, such as damage reports and (at level 2) bullet trails.

* `hd_nobots` (false): This causes bots to be replaced with riflemen. Can be used for coop and deathmatch. Generally far more competent, but cannot use customized loadouts and can sometimes appear in odd places.

* `hd_nodoorbuster` (false): Some weapons such as the H.E.A.T. rocket and the Brontornis can destroy small pieces of map geometry, letting you bypass tedious or impossible-to-reach areas. This can result in unpredictable or unwanted behaviour, so enabling this option will prevent such weapons from being able to affect map geometry this way. Enabling this midgame will not reverse any damage already done.

* `hd_safelifts` (true): With HD's reduced player speed and falling damage, some classic Doom lifts end up creating scenarios that resemble a superimposition of a Simone Giertz comedy routine and the deposition materials from a factory class action suit. HD automatically scales all these lifts at level start to more reasonable speeds. This may break some levels, so this option is provided. Note that the level must be restarted for the changes to take effect.

* `hd_dirtywindows` (true): Before limit-removing sourceports the only windows in Doom were wholly see-through, even if they were supposed to block absolutely everything. This can be a bit frustrating when you have no idea what your shots can or cannot go through unimpeded. This setting will overlay all of these blocking surfaces with a translucent dirt texture to make them look like a poorly cleaned window.

* `hd_3speed` (false): The frequently varying player speeds in HD do not play well with the movement prediction in network play. If you are experiencing an unusual amount of "rubber banding" while playing online, you can enable this option so that you are restricted to one of only 3 possible pre-set speeds at any time in multiplayer.

### CVars (host only) - gameplay modes

* `hd_forceloadout` (""): If this has been set, set this to "", "false", "0" or "none" to let everyone choose their own loadout. Set this to anything else and it becomes everyone's loadout. Takes effect on player spawn.

  Default is blank. This cvar is not saved between sessions.

* `hd_blacklist` (""): Add some item codes to this, separated by commas. Counts will be ignored.

  You can also use the blacklist to change one type of item to another by using the right angle bracket, e.g., "bfg=thu" to replace starting BFGs with Thunder Busters or "zrk=stm" to replace berserk packs with stimpacks. Unfortunately the system is not very smart so certain shortcuts will not be affected (e.g. blacklist "z66=lib" will replace "z66 nogl" with "lib nogl", but someone with "z6a" will spawn without a rifle at all).

  Default is blank. This cvar is not saved between sessions.

  If you add the keyword "all" to your blacklist, e.g. "all,bfg" or "all,bfg=thu", all items blacklisted will have their pickups deleted from the map the moment they appear.

* `hd_dropeverythingondeath` (false): HD mostly goes with regular (GZ)Doom inventory behaviour when dying and respawning: you keep your stuff in co-op, reset your stuff in deathmatch, maybe drop an extra copy of your weapon. Enabling this cvar will cause you to drop *all* your inventory except keys, leaving a stash of loot for your opponents (or buddies) in deathmatch or, in co-op, forcing you to do a naked walk of shame back to where you'd died.

* `hd_disintegrator` (false): With this on, once you hit zero hitpoints you immediately disappear. Mostly for deathmatch. Overrides YOLO mode below.

* `hd_yolo` (false): With this on, you will trigger the wipeout counter the first time you die, but you can't die until everyone (or, in teamplay, everyone on your team) is dead or incapacitated. Not recommended for free-for-all deathmatch.

* `hd_flagpole` (false): See the "Flagpole" section for details.


### CVars (host only) - difficulty modifiers

* `hd_encumbrance` (0.25): This is a multiplier for how much encumbrance affects you. 0.25 is a reasonable approximation of how much you "should" be able to carry to approximate a fully equipped doomguy. This is the only difficulty modifier setting that is archived between sessions.

* `hd_damagefactor` (1.0): Multiply any raw damage inflicted on the player by this amount, before any other calculations (besides checking for telefrag/suicide, forced damage and god mode) are applied.

* `hd_shardrate` (0): number of ticks per shard spawning.

* `hd_nobleed` (false): Eliminates all bleeding.

* `hd_killerbarrels` (5): The percentage chance that any barrel (nukage or flaming) will be a killer barrel.

* `hd_novilespam` (true): At map start, if this is true and multiple archviles are stacked too close together, some of them will be replaced with other monsters. Default true.

* `hd_lowspeed` (true): constrain maximum sprint speed to "realistic" values and don't worry about breaking many vanilla jumping puzzles.

* `hdskill_hardcore`, `hdskill_casual`, `hdskill_normal`: Presets for the above.

* `hd_clearscv`: Resets all archived host options to their defaults.

### CVars (user-based)

* `hd_helptext` (true): Some events generate text messages on your screen that remind you of certain non-obvious events. By setting this cvar to zero, you turn those reminders off. At your own risk.

* `hd_hudsprite` (false): Displays your current weapon as a pickup sprite graphic inside your HUD, Ghost Recon-style. Always on when `r_drawplayersprites` is off.

* `hd_hudstyle` (0): Normally the "fullscreen" hud gives you the mugshot while the "status bar" hud one screenblock below gives you no mugshot. Set this to 1 or 2 to force it to always or never use the mugshot respectively.

* `hd_noscope` (0): Many weapons have an optic sight that is represented as a sight picture just below HD's regular sight picture crosshair. By default, this always appears when the main sight picture is visible. Set to 1 to show only while the full HUD is visible or Zoom is pressed. Set to 2 to show only while Zoom is pressed.

* `hd_sightbob` (true): HD's sight crosshairs by default will bob as the player moves. This can sometimes be useful for making trick shots, but for many it is more distracting than anything else. Turn this off to hide the entire thing when you're moving above a certain threshold. Note that your scope angle will still follow the bob which is still used to calculate the trajectory of your shot.

* `hd_xhairscale` (1): HD's sight crosshairs can scale unpredictably at different resolutions. Other people just don't like the size. Use this setting to make adjustments. Values are between 0.1 and 3.0 inclusive and default is 1.

* `hd_crosshair` (0): This affects which image is displayed on the ZM66, Vulcanette and Liberator reflex sights. This is applied on a per-user basis and you will not need to set this every time you pick up a new gun. If you want to modify these, the lumps to replace are "riflsit1" through "riflsit5".

* `hd_mugshot` (-1): This sets the status bar mugshot and nothing else. -1 means use the one intended for your "gender" cvar setting. 0 and 1 are respectively masculine and feminine, while 3 is the robot.

* `hd_voicepitch` (1.0): This lets you change the speed of the samples that play for your character's voice, allowing distinct audio cues for each person in multiplayer. Clamped between 0.7 and 1.3.

* `hd_nv` (7): This sets the starting amplitude of your light amplification visor, between 0 and 100. Negative values mean the display is red rather than green. Brighter displays drain more battery.

  You can also set it to 999 to get the vanilla Doom behaviour where the renderer just omits lighting reduction. This is considered a cheat in multiplayer.

* `hd_hudusedelay` (12): This is how many tics (1/35 of a second) you must hold Use before the full HUD shows up with all the ammo counts and compass (and scope view if hd_noscope is set to 1). Minimum delay is 12. If you set the value over 100, the digits preceding the tens place will be parsed as the delay before even the partial HUD appears, e.g., a value of 1212 means an all-or-nothing with no partial HUD while 120 means you can quickly hit Use to check your vitals and hold much longer to get everything.

* `hd_autostrip` (false): If enabled, you automatically take off your armour just by holding Fire while using the medikit, as opposed to getting a message telling you to hit Reload instead.

* `hd_aimsensitivity` (0.1): Sets the amount to which your mouse sensitivity is reduced while aiming with the Zoom or Use key.

* `hd_bracesensitivity` (1.0): Sets the amount to which your mouse sensitivity is reduced while aiming with the Zoom or Use key while your weapon is braced. The final sensitivity is the minimum of this value and your `hd_aimsensitivity` setting.

* `hd_usefocus` (true): Holding the Zoom key will normally reduce your aim sensitivity, subject to the `hd_aimsensitivity` setting. Normally the Use key will also cause this to happen, for the benefit of those who may be running low on room on their keyboards; if this is not a concern for you, or you find that the numerous functions of the Use key are clashing against each other, set this to false so that only the Zoom key will affect your aim.

* `hd_nozoomlean` (false): When you're holding Zoom, the sidestep keys turn into lean keys. Enabling this cvar disables this behaviour, limiting leaning to the dedicated controls only.

* `hd_noslide` (false): Normally if you hit Crouch while moving, you will dive/slide/lunge in that direction. This can be pretty useful to defend against certain attacks (or to inflict certain attacks) but it is bad for fine control and cover manipulation. Set this to true to just simply crouch for this input if you are not sprinting.

* `hd_swapbarrels` (false): By default, HD's double-barreled shotgun has regular fire shoot the left barrel and alternate fire shoot the right barrel. This assumes the player has fire on their left mouse button and altfire on their right. Enabling this option switches this around (and nothing else, unless you make a submod featuring a weapon that also relies on this cvar) to correspond to setups that do not fit this assumption.

* `hd_maglimit` (0): This limits the number of mags you can pick up before you reach your actual encumbrance limit. You can set this temporarily to rapidly pick up/swap out a pile of mags until you have the fullest ones. 0 means no limit. Alternatively, you can hold Firemode while attempting to pick up a mag to force swapping mode.

* `hd_consolidate` (true): By default, when you change maps you are assume to do some inventory management including consolidating all your mags to concentrate everything in as few mags as possible, and attempting to repair robots (and cannibalizing some broken ones in the process). Disable this option if you prefer to manage all this yourself.

* `hd_clearucv`: Resets all archived user options to their defaults.

### CVars (user-based): weapon default options

The following cvars affect how some of your weapons are set up when you first spawn with them in your loadout. Default setting in parentheses.

* `hd_derpmode` (0): Sets the starting mode for the DERP. 1=turret; 2=ambush; 3=patrol.

* `hd_autoactivateied` (true): If false, you have to manually activate your IEDs using the `ied 1 [tag]` command. If true, they activate after a 2-second warning period without any further input.

* `hd_weapondefaults`: See ["Customizing your weapons"](#customizing-your-weapons) above for details. Similar format to loadouts, except for weapons only. This lets you set some defaults overriding HD's own so you don't need to specify each time. For instance, if you know you will always prefer reliability over damage per shot, you can add `bos customchamber` to this string and any Boss-bearing loadout where you don't specify the variable will include the custom chamber. This has no effect for weapons that take quantities instead of variables.

  Note: if you're putting spaces into your input, you will need to put your entire setting string in quotes, e.g.: `hd_weapondefaults "bro zoom, bos bulletdrop 0`

* `hd_setweapondefault`: Enter a loadout customization string for a single weapon, e.g. `lib nobp nogl zoom1`, and `hd_weapondefaults` will be updated accordingly for that weapon alone without interfering with the others. Note that this requires all items to be separated by commas.

  To delete an entry, type `hd_setweapondefault xxx` where xxx is the weapon's loadout code.

* `hd_clearwepcv`: Resets all archived weapon options to their defaults.

As editing these can get a bit involved, you might want to use your preferred text editor rather than the console. Please read https://zdoom.org/wiki/Configuration_file if you need help finding your gzdoom.ini file.


## V. ITEMS

To pick up an item, use it as you would use a door or switch, or hold Use and look towards it. Even if you do not pick it up, you will bring it towards yourself, so this can also be done to quickly get an unwanted item out of the way of another (or an actual door or switch) that you do want.

Armour comes in two levels: "Garrison" as standard military use, and "Battle" for your more refined, higher-budget militarized-police/unaccountable non-state-actor corporate "civilian" work. Battle armour mitigates the most damage, while garrison armour lasts longer generally and restricts less movement.

Supernatural health bonuses (potions, soul spheres, megaspheres) are stored and gradually "leak" into your system whenever you are injured, allowing recovery from nearly anything that does not immediately kill you.

Some items can be picked up and saved for later, as described below.

* **Stimpack**

  GZDoom actor name: `PortableStimpack`
  Loadout code: `stm`

  Use one of these to kickstart your system, decreasing your recovery time while slowing down your bleeding.

  DANGER: DO NOT OVERDOSE.

* **Medikit**

  GZDoom actor name: `PortableMedikit`
  Loadout code: `med`

  Weapon slot: 9

  The staple (no pun intended) bit of safety equipment once prevention has failed. You will find in each sealed package:

  1. One (1) Second Flesh(tm) Human Biotic Rapid Growth Medium Auto-Suture Syringe; and
  1. One (1) Second Blood(tm) Wearable Mobile IV Feed. (Ingredient list can be compiled for personal research use only under various open licences and non-expiring government patents.)
  1. One (1) stimpack;

  To use item 1, inject the device into the wound and hold down the trigger. The pressurized syringe will extend to the end of the wound (or the exit as appropriate) and startsshooting out strands of Second Flesh(tm) that pull together the flesh and then fuse with it rapidly, and continue to apply and seal while retracting back to the application point. The fusing will continue to take effect over time and may result in some discomfort.

  Controls:

  Remove armour and unseal one package.

  Once the applicator is in hand, look down at yourself and press and hold the fire button to begin applying item 1 to stop virtually any bleeding.

  To deal with wide-area burns that cannot be reached by the syringe, do the same thing while holding zoom.

  Press and hold fire while holding firemode only to use the medikit's auto-diagnostic function. Try not to move while it is scanning. The scan *can* be done while wearing armour but accuracy suffers as a result.

  To apply the medikit to someone else, use altfire instead of fire.

  WARNING: DO NOT USE THE SAME APPLICATOR ON MULTIPLE PATIENTS. (Seriously, if half of what your buddies say about their R&R exploits were true...)

* **Synthetic Blood**

  GZDoom actor name: `SecondBlood`
  Loadout code: `bld`

  Weapon slot: n/a

  A shelf-stable mix of self-regulating nanobots and chemical binding agents, fed through a compact, ergonomically fitted intravenous feed that a busy operator will not even notice in combat.

  Some tiredness may sink in as certain chemicals need to be processed by the body upon injection.

  Standard rules of fire-self, altfire-other application apply.

  This may get knocked off under some extreme circumstances. If this happens, do NOT attempt to re-attach the device, and use the other items in your medikit to seal up the wound immediately.

* **Berserk Pack**

  GZDoom actor name: `PortableBerserkPack`
  Loadout code: `zrk`

  Its original "on-label" use was to save someone going into shock or cardiac arrest, though it was found that sometimes it made things worse after it wore off.

  When you've got more monsters than time to reload, this thing is a godsend. The burst of strength also lets you carry heavy weapons more efficiently. The effect only lasts a short while, so use it while you've got it!

* **Light Amplification Visor**

  GZDoom actor name: `PortableLiteAmp`
  Loadout code: `lit`

  Use to turn on and off. Requires at least one operational battery in your inventory to charge.

  Use the goggles while holding:

  - Use to increase amplitude.
  - Zoom to toggle green and red.
  - Use and Zoom to decrease amplitude.
  - Mag Manager to cycle through which set of goggles you are using.

  To set your starting nightvision mode, use the `hd_nv` cvar to set a value between -40 and 40. Negative values are red and positive values are green.

* **Ladder**

  GZdoom actor name: `PortableLadder`
  Loadout code: `lad`

  Use while on a ledge (above or below) to deploy.

  From below, stand as close to the ledge as possible and look right into the wall.

  From above, look at the ledge you want to hang the ladder from.

  Press use to engage the ladder. To disengage, do any of the following:

  - press jump at any time (which will also give you a horizontal boost away from the ladder).
  - press use again while turned away from it, or while directly facing it.
  - press speed while standing about on the top ledge from which you have hung the ladder.

  To remove the ladder, get onto the ladder and attempt to jump while crouching.

* **Radiation Shielding Suit**

  GZDoom actor name: `PortableRadSuit`
  Loadout code: `rad`

  Doubles as a fire retardant suit. Lasts until damaged.

  Protip: The suit heats up pretty fast. Keep moving to keep it from stewing in its own gases and igniting.

* **Backpack*

  GZDoom actor name: `HDBackpack`
  Loadout code: `bak`

  Use from inventory to bring it up. Fire and altfire select your item; hold fire mode to momentarily use your pitch input instead. Reload places one unit of the selected item type into it, unload takes it out. Mash the Zoom key to dump out all the contents of the backpack. The drop-one key works to remove ammo from your own inventory in case you want to make a little more space.

  To load items into a backpack, after the "bak" code type in your items as you normally would, but separate them with "." instead of ",". Use "," as usual to mark the end of your backpack contents definition.

  "z66, bak z66 nogl. z66 nogl semi, stm", for instance, will give you a ZM66 in hand, two more in your backpack, and a stimpack in your pocket.

* **Defence, Engagement, Reconnaissance and Patrol Robot**

  GZDoom actor name: `DERPBot`
  Loadout code: `drp`

  The gun that runs around killing people by itself! Basically a pistol wired to a webcam and treads, made of bullets, aggression and shitty programmer art. They can't climb and run out of ammo quickly, but you can pick them back up anytime as you would an ordinary item for later redeployment. Takes one pistol mag to deploy, and any unused ammo is recovered on pickup.

  If it breaks, unload the mag, then hold fire and tap reload to try to repair it.

  The DERP can be programmed to one of several behaviours. Type the following into the console, or `derp <number shown>`, to set what mode it will engage in at any time.

  - 1 = `derpt` = TURRET: Stand ground and engage targets from wherever it is.
  - 2 = `derpa` = AMBUSH: As turret, but will not shoot.
  - 3 = `derpp` = PATROL: Wander around the vicinity of its goal, pursue and engage targets as acquired.
  - 4 = `derpcome`: make a beeline towards the user.
  - 5 = `derpgo`: make a beeline towards the general direction you are pointing in.
  - 6 = `derpat`: toggle between turret and ambush mode.
  - 80* = `derpmv*`: make a beeline towards a spot several feet ahead in a cardinal direction. For the `derpmv` command, this means n/s/e/w/ne/sw/se/sw; for the number, look at your numpad.

  `derp` in the above can be shortened to `d`, e.g. `dtz` for ambush mode, but not if you use the numbers. Typing `derp` only, or entering an unused number, will show these commands.

  Type `derp 123` to show coordinates and ammo.

  An additional, somewhat off-label use is to stick the treads onto the moving parts of a switch and use the DERP to operate it while the user is out of reach. Type `derp 555 <tag>` in the console to place it and `derp 556 <tag>` to set it off.

  In addition to all the above, the DERP can be controlled via a direct-control interface that also communicates with its internal camera. It will appear in your inventory after you deploy a DERP: use it to bring it up, and:

  - Hit Reload to cycle through turret, ambush/passive and patrol modes.
  - Hit Unload to go immediately to ambush/passive, for ease of direct control.
  - Hit Throw Weapon to cycle to the next DERP, if you have multiple robots deployed.
  - Hit Alt. Reload to attempt to re-establish connections with DERPs that had gone out of range.
  - Hold Firemode to directly steer the DERP.
    - Fire shoots the gun.
    - Altfire moves forwards.
    - Use moves backwards.

* **Heavy Engagement Rotary Platform Robot**

  GZDoom actor name: `HERPBot`
  Loadout code: `hrp`

  In the wake of the stunning success of the D.E.R.P. project, the Brojira Robotics and Human Development Foundation soon secured a second grant from the Israeli military to build a scaled-up version for high-accuracy automated targeting in heavy urban engagements. This was met with some setbacks early on in the project when it was discovered that Brojira's CEO at the time, Dr. Branson Icke, had supported a local mayoral candidate in his hometown eight years before whose platform included "ending the politically correct war on Christmas by passing a bylaw that every mall Santa shall be a real Santa with HIS beard and HIS wife Mrs. Claus who is a woman". A great and terrible media cycle ensued and Dr. Icke, one of the chief coders and designers behind the original D.E.R.P. project, was forced to resign from all further positions with Brojira, and the H.E.R.P. project was substantially completed without his guidance and programming virtuosity. The resulting product remains functional, if a bit bloated, slow and unwieldy.

  Once deployed, the HERP will begin doing sweeps of the 90-degree view in front of its starting position. The new IFF detection system\* means it can only focus on a narrow band in front of it, meaning that it will only target enemies that cross the sensor line.

  \* *(which contains a few additional safeguards after numerous class action lawsuits resulting from fatalities when local American police forces were found to be deploying units in inner-city schools)*

  The HERP takes up to 3 mags and 1 cell to deploy.

  The HERP is bulky enough to count as its own weapon when encumbrance limits are enabled.

  You can manipulate your HERPs from the console.

  Command format: `herp <mode> <tag> <direction>`

  Possible modes are:

  * 1 = On: scan for enemies and shoot on sight
  * 2 = Off: stand by and do nothing
  * 3 = Redirect: change base angle by the amount given in the direction parameter, going counterclockwise in degrees.
  * 123 = Query: show coordinates, orientation and status
  * -x = Set tag: where x is any whole number

  For more information on tags, please see the IED Kit description.

  In addition to all the above, the HERP can be controlled via a direct-control interface. Bring it up the same way as the DERP, and:

  * Hit Reload to establish the remote connection. Note that the connection cannot be maintained while the HERP is in autonomous mode. (The advantage is that range limit has significantly improved since the DERP and you do not need to worry about it.)
  * Hit Throw Weapon to cycle to the next HERP, if you have multiple robots deployed.
  * Hit Alt. Reload to set the HERP's home angle to the current angle.
  * Hold Firemode to directly control the HERP. Fire shoots the gun.

  If it breaks, unload the battery, then hold fire and tap reload to try to repair it.

  In a pinch, the H.E.R.P. can be fired as a crude personal defence automated weapon.

* **Door Buster**

  GZDoom actor name: `DoorBuster`
  Loadout code: `dbs`

  Some military-grade demolition charges, because doors are a social construct.

  Please do not stand directly in front of the blast shell when it detonates.

  Command format: `db <option> <tag>`

  Possible options:

  * 999 = Detonate
  * 123 = Query
  * -x = Set tag ("dbtag <tag>" also works)

* **IED Kit*

  GZDoom actor name: `HDIEDKit`
  Loadout code: `ied`

  The OpenTerror Working Group's brief lifespan included what turned out to be an ingenious adaptation of the Heckler & Mok Short-Range Reduced-Arc Hybrid Rocket Grenade for securing a building against certain passing threats. The open-source schematics have allowed numerous aftermarket companies to develop the Simple Idiotproof Improvised Explosive Device Kit for various military, police and private security contracts long after the original inventors were captured, tortured and their remains presumably disposed of in an undisclosed location by various government and other\* agencies.

  \* *A lawsuit against Heckler & Mok by the families was dismissed with costs after an eighteen-day motion was heard. The families settled for an undisclosed amount and were never heard from again.*

  To activate the IED, make sure you have at least one IED kit and one live or dud rocket. (You can pick duds up from any botched grenade launch assuming they don't spontaneously detonate on you first.) The IED takes 5 seconds to come online, during which you may decide to flee. They will generally not target friendlies. An IED may be picked up and its components reused; the disarming process, however, ruins the rocket grenade such that it can no longer be launched and is only good for planting another IED.

  You can manipulate your IEDs from the console.

  Command format: `ied <mode> <tag>`

  Possible modes are:

  * 1 = Active: detonate once an enemy is in range
  * 2 = Passive: detonate only when commanded
  * 999 = Detonate: detonate immediately
  * 123 = Query: show coordinates and status
  * -x = Set tag

  `iedactive`, `iedpassive` and `detonate` can be used in place of `ied 1`, `ied 2` and `ied 999` and can all take tags.

  Tags help you sort IEDs into groups. The tag number appears in cyan in your inventory selection: that is the tag of any IED you deploy next. If you set Active, Passive, Detonate or Query and specify a tag, only those deployed IEDs of yours that have that specific tag will be affected.

  Example: I type `ied -2` and plant an IED by the door, then type `ied -3` and plant another IED down the hall, then run for cover and type `ied 2` to set all the IEDs to passive. The door opens and some monsters come through the door, and as they pass the door IED I type `ied 999 2`. The door IED blasts a bunch of them, and the survivors continue down the hall. They reach the second IED, I type `ied 999 3` (or `ied 999` since I don't have anything else deployed anyway) and that IED blows up those survivors.

* **7.76mm Reloading Device**

  GZDoom actor name: `AutoReloader`
  Loadout code: `rld`

  Your ZM66 tactical reloads will leave you with a lot of unreliable caseless powder and lead and primers. Firing the Liberator leaves a lot of cases without powder or lead. The reuse of a partial 4.26mm UAC Standard mag is illegal, but really, the worst Volt UAC's impious counsel can do is drag you in front of The Honourable Mr. Justice Rotting-Head-On-A-Stick and his clerk Mrs. Caco, and as a natural person you don't recognize their jurisdiction. If you have this device, you will be assumed to figure out what to do in the downtime between levels.

  During a level, however: ensure you have at least 4 loose 4.26mm rounds (for the primers and powder), brass, and bullets on your person (not backpack), then hold Use and hit Unload. Stand back at least 4 feet as the method is not perfect. Grabbing the device back will stop the process. You can make up to seven at a time.

* **Ion-Jet Light Infantry Atmospheric Landing Craft**

  GZDoom actor name: `HDJetpack`
  Loadout code: `jet`

  Many missions require a drop into hostile territory that a larger craft may not be able to reach and a parachute may be impractical. For some of these stealth may be optional, or at least deferred.

  Press Fire to thrust upwards, Altfire to thrust upwards and slightly forwards. Firemode turns off and on to save battery or warm up for a quick deployment.

* **Relic of the Ancients**

  GZDoom actor name: `SquadSummoner`

  Not all the magics that escaped through the gates are evil, or at least not all of them are specifically out to get you. Every so often you may run into an ancient piece of arms and armour that serves as a talisman to bring back the spirits of long-departed warriors to aid your quest - if only for a little while. Their damage is almost entirely illusory, but they can be very useful for routing and isolating an otherwise overwhelming force.

* **Four-Dimensional Ring of Shadows**

  GZdoom actor name: `HDBlurSphere`

  This one is not out to get you. It cannot be; it is precious. Use it early and often to get out of bad things and stop bad people from looking at you and hurting you. You will only ever need one. It is precious.

* **Potion of Goodness**

  GZDoom actor name: `BluePotion`

  Another supernatural artifact of questionably non-Hellish origin. Heals you over time. In fact, it can "over-heal" you so that if you're hurt later, you can recover faster because of your prior drinking! (Please do not apply this logic to other bottled materials that some people use in lieu of actual spiritual healing.)

* **Spiritual Armour**

  GZDoom actor name: `SpiritualArmour`

  Another supernatural artifact of even more questionably non-Hellish origin. Stops any and all bleeding on the spot and grants you additional protection from damage.

* **Suspiciously Generic Ammo Box**

  GZDoom actor name: `HDAmBox`, `HDAmBoxUnarmed`, `HDAmBoxDisarmed`, `HDAB`

  These ammo boxes are actually full of ammo, though they may also contain other lovely surprises. To disarm the trap, tap use once to attempt to disarm. You will automatically flip disarmed boxes over to mark them as checked. Rapidly double-tap use on the box to open it immediately without completing the trap check. Not all boxes are trapped in such a way as to allow disarm, and you may want to shoot them open from a safe distance instead.

## VI. ALTERNATE GAME MODES

### Lives

If you set the fraglimit to certain values in a multiplayer game, you can play a last-man- or last-team-standing deathmatch game, or play co-op without the temptation to send wave after wave of yourself into the enemy until they eventually thin out.

Only the host needs to set the fraglimit. You must allow exits for the level end to work.

Generally: FL less than 100 = points; FL 100 or over = elimination.

Deathmatch FL <100: Same as usual.

FFA Deathmatch FL >=100:

- Each player has a number of lives equal to fraglimit less 100.
- If you run out of lives, next time you die you are out and respawn frozen and unable to interact.
- Last person still alive is deemed to win the match.

Team Deathmatch FL >=100:

- Each team has a pool of lives equal to fraglimit less 100.
- If your team runs out of lives, next time you die you are out and respawn frozen and unable to interact.
- Last team with at least one surviving member is deemed to win the match.

Co-op FL <=0:

- There is no lives pool, and you respawn infinitely subject to your usual dmflags.

Co-op FL >=100:

- All players share a single lives pool, equal to fraglimit less 100.
- If you run out of lives, next time you die you are out and respawn as a spectator.
- If everyone is out, the game over message appears and the map restarts after a few seconds.
- "Outed" players' loadouts are reset.

Co-op FL <100:

- All players share a single lives pool, equal to fraglimit.
- If you run out of lives, the game over message appears and the map restarts after a few seconds.
- If you manage to die during these few seconds, you are out as in FL <100.
- "Outed" players' loadouts are reset.

### Flagpole

Set the cvar `hd_flagpole` to true. The next map you load, two objects will spawn at random places: a "flag" and a "flagpole".

Pick up the flag. It is usable like a HERP. It must be "programmed" to indicate you or your team before it can be planted: to do this, get out of range of the flagpole and move around.

To plant the flag, go back to the flagpole, use the flag, and hold Fire without leaving range or LOS. The exact effect of planting a flag varies depending on game mode, but it is always significantly beneficial.

## VII. WEAPONS

### Unarmed
GZDoom actor name: `HDFist`

Default weapon slot: 1

Loadout code: `fis`

Punching people and things.

Instructions: Fire button is a straight-up punch. Reload performs a finger-jab-hook combo. Hold the Use key to start kicking someone in front of you. You are assumed to be trying to cause maximum damage with every attack and it will only take a few hits to take down weaker enemies.

Note that the use key kick is available with any weapon.

The unload button lets you flick a small piece of debris in the direction you are looking. This can be useful for causing a distraction or hitting a shootable switch. You can collect debris by punching walls; if you don't have debris, you'll generate your own.

Hold Firemode to grab something and possibly drag it along. It has some limited use in combat, and is mostly for dragging bodies and objects to more convenient places.

Hold Zoom and try to drop your fist "weapon" as a shortcut for dropping all your miscellaneous usable items (D.E.R.P., radsuit, etc.). If you do not have any of those, you will drop your meds instead.

The fist can also be invoked to perform the Rite of the Once-Mortal, a magic spell that only takes effect while hd_yolo is on. To perform:

 * Find a player whose max health has gone down below 50.
 * Move away anything that might pose a hazard for anyone who cannot defend themselves for the next 3-5 minutes.
 * Get all non-incapacitated players in a group together right next to you.
 * While holding Use and Zoom, punch the target player.
 * Take some time to recover.

Protip: Punching damage responds to the way you are turning at the time your fist connects. A good left hook or uppercut to the head can knock out a zombie in one punch. In any event, headshots are generally good for knocking someone about to keep them from hitting back. (Their not hitting back is not guaranteed.)

### Chainsaw
GZDoom actor name: `Lumberjack`

Default weapon slot: 1

Loadout code: `saw`

A small, rugged, not terribly precise-cutting chainsaw, good for destroying things that would otherwise get in your way.

Instructions: Press fire to cut things. Eats cell power like popcorn; reload as any other weapon. Check your angle and distance as you cut as the blade will slip out of position from time to time. Do not let the blade catch hard surfaces while cutting up a dead body.

Protip: Some of the above mentioned hard surfaces are themselves destructible.

### Pistol
GZDoom actor name: `HDPistol`

GZDoom ammo actor names: `HD9mMag15`, `HDPistolAmmo`

Default weapon slot: 2

Loadout codes: `pis`
* selectfire - 0/1, whether it has a fire selector enabled
* firemode - 0/1, semi/auto, subject to the above

With its compact high-capacity design and extremely powerful 9x22mm Parumpudicum round, the Mouletta 99FX has followed and surpassed the tradition of its forebears as the standard complement to any arsenal. There was also a limited production of a full-auto variant that may occasionally be found as a PDW.

Instructions: Press the fire button to further your effort to bust as many caps in your target's body part of choice as possible. Fire mode works if you have the lucky pistol that allows it.

While both the pistol and the SMG use the same rounds, the magazines are not cross-compatible. Hit the user3 button to load and unload mags.

Alternate reload lets you swap to the other pistol in your other hand, if you have one. If you don't, it's in your other hand now.

### Revolver
GZDoom actor name: `HDRevolver`

Loadout code: `rev`

Compact and ergonomic, the Buger Blue Deinonychus makes for an excellent and stylish everyday civilian carry. The Deinonychus can take 9mm Parumpudicum in a pinch but is chambered for the more powerful .355 Masterball.

Hit Fire to rotate the cylinder and pull the hammer. Note that if you do not depress the trigger all the way the weapon may cycle without discharging.

Hit Altfire to pull back the hammer and cycle the cylinder in preparation for a single action shot.

Hit Reload or Unload to open up the cylinder. Once it is opened, hit Reload to load a round into the selected chamber, Altfire to turn the cylinder (or Zoom+Altfire to turn it the other way), Unload again to eject all spent cartridges, or double-tap Unload to empty the entire cylinder. Once finished, hit Reload or Fire to close the cylinder.

Hand switching works similarly to the automatic but you can also use fire mode.

### SMG
GZDoom actor name: `HDSMG`

GZDoom ammo actor names: `HD9mMag30`, `HDPistolAmmo`

Default weapon slot: 2

Loadout codes: `smg`
* firemode - 0-2, semi/burst/auto
* fireswitch - 0-3, default/semi only/semi-burst/semi-full
* reflexsight - 0-1, no/yes

The Heckler and Mok MP-46 heavy automatic pistol - nicknamed the "Sexy Manly Guy" in reference to a rather untimely scandal involving one of the company's directors (then a senator) who was supervising the development, an 18-year-old male intern, allegations of insider trading, an unidentified leather object found with some early prototype drawings and some saucy emails revealed during a deposition - fills that niche where a rifle is too noisy and unwieldy, a shotgun is too bulky and lethal, and a pistol just can't hit fast or far enough. Mostly bought by collectors and casing-loving hipsters, as well as law enforcement looking for a weapon with less kick and noise than the ZM66 but better suppressive capability (both tactical and PR-strategic) for use while keeping us all safe from alleged drug dealers and their alleged drug money.

Instructions: Press and hold the fire button to further your effort to bust as many caps in your target's body part of choice as possible. Use the fire mode key to switch between semi, burst and full-auto. Note that the order is different between the MP-46 and the ZM66 due to conflicting manufacturing standards.

As with the pistol, hit the user3 button to load and unload mags.

Protip: The SMG is both harder hitting and quieter than the pistol.

### Shotgun
GZDoom actor name: `Hunter`

GZDoom ammo actor names: `HDShellAmmo`

Default weapon slot: 3

Loadout codes: `hun`
* type - 0-2, export/regular/hacked
* firemode - 0-2, pump/semi/auto, subject to the above
* choke - 0-7, 0 skeet, 7 full

The DiFranco SPOS-E28 scattergun is easily the most widespread firearm in known space. Formerly marketed as the "Man-Hunter" before the liberals got the name banned in eleven states after a spate of shooting sprees, the Hunter's reliability, (relative) safety while firing in pressurized quarters, and ability to take just about any ammo given to it are unsurpassed by any current weapon. Also good for home defence and hunting big game - up close.

A made-for-export "Sportsman" edition exists with a slimmer mag profile and action dedicated entirely to manual chambering.

The Tyrant has been strangely fond of this weapon and has armed most of his zombies with it; while officially Metallian Holdings Ltd. (DiFranco's parent company) denies any dealings with the Tyrant or any of his known dealers, or in the alternative at least having ever profited from such transactions, or in the further alternative having ever received any such funds from DiFranco, unofficially we all know there's no such thing as bad publicity.

It is extremely illegal in most states, and under the rules set by the Tyrant, to modify the SPOS-E28 to remove the safety features in its trigger mechanism as to allow continuous fire with fully automatic cycling.

Instructions: Altfire cycles the next round; make sure you press hard and long enough that the round actually cycles. Primary fire is what you do to something until it dies.

Holding down the trigger while you chamber a new round lets you slam-fire the shotgun, firing the round immediately when it is ready to fire. Semiauto disables this.

Hold Reload and Unload to continually reload and unload the tube.

To reload quickly from the shotgun's side saddles, press the reload key. To slowly fish a shell or two from somewhere in your pockets to load those, press the secondary reload key. To reload the side saddles, hold the reload key while the Hunter itself is full, or while holding the fire mode key.

If you hit reload and unload while the pump is pulled back, you will reload and unload the chamber.

To change fire mode, hit the fire mode key. There is no guarantee as to the quality of the ammo you find and not every round may be strong enough to cycle properly, so altfire is still available to force cycle a round if necessary.

If you have the Slayer, pressing Unload while holding Use or Zoom will remove up to 4 shells at a time from its side saddles and place them in your general inventory.

### Super Shotgun
GZDoom actor name: `Slayer`

GZDoom ammo actor names: `HDShellAmmo`

Default weapon slot: 3

Loadout code: `sla`
* lchoke, rchoke - 0-7, 0 skeet, 7 full

Accurate, ergonomic and compact, deceptively primitive yet rugged enough to withstand anything the bad guys might ever think to throw at you, the ambidextrously designed Calvary Arms SL41 "Slayer" side-by-side is an instant classic among big game hunters throughout the solar system. Big, bipedal game.

Instructions: Each of fire and altfire represents the trigger for one barrel. You can fire them in as rapid a succession as you want, even simultaneously.

If you want to ensure a double every time, hold fire mode and tap either fire button.

When you reload, both shells eject at once, even if only one shell has been fired. Provided you are in good health, have space in your inventory, and (if you are distracted by anything less than near-perfect health) aren't moving about at the same time, you should be able to catch the unspent shell; otherwise, you must find out where it's dropped.

Secondary reload works in a similar manner to the Hunter. Side saddles work identically.

If you have the Hunter, pressing Unload while holding Use or Zoom will remove up to 4 shells at a time from its side saddles and place them in your general inventory.

### Assault Rifle
GZDoom actor names: `ZM66AssaultRifle`

GZDoom ammo actor names: `HD4mMag`, `HDRocketAmmo`

Default weapon slot: 4

Loadout codes: `z66`
* nogl - 0/1, whether it has a launcher
* semi - 0/1, whether it has a fire selector enabled
* firemode - 0-2, semi/auto/burst
* zoom - 16-70, 10x the resulting FOV in degrees

The basic infantryman's weapon of the 32nd century. A very lightweight select-fire weapon that fires up to 2100 rounds per minute, the Volt ZM66 represents the highest evolution of its state-of-the-art ammunition. As a refinement of the principles behind the old 5.56 NATO, the 4.26mm UAC Standard round packs an incredible amount of punch for its size. The 4.26mm UAC Standard round is protected by a special non-terminating legislative patent and a 99-year automatically renewed confidential exclusive contract with the militaries of all developed Western nations listed in the federal Officially Freedom-Loving Foreign Countries Trade Partnership Protocols, guaranteeing a safe and reliable supply.

To get around prior overheating issues with the caseless 4.26mm round, the ZM66 chamber and barrel are lined with a patented heat-sink polymer that contracts when placed under extreme stress and heat, returning to its original form after having a chance to cool down. This reduces friction with subsequent bullets and allows for vastly increased tolerance thresholds that let the ZM66 continue firing where most rifles will have broken down. This temporary warping sacrifices some accuracy and power under sustained fire, but if you're in that spray-and-pray situation to begin with, chances are you won't even notice it. [a handwritten note reads: or the ensuing cookoff.]

You may occasionally find some old variants of the ZM66 that were made for the civilian market shortly before private consumer assault weapon bans were prohibited by treaty in all APEC nations thanks to the efforts of many freedom-loving lobbyists back home, sponsored by the Volt Strategic Systems Group (and the 2/3 of Congress that have sat in their and the Universal Anthroposoterium Cybernetics Group's various boards of directors). Some people actually prefer the semi variant for its reportedly greater reliability, though numerous UAC-sponsored independent reviews have found no evidence for such a claim.

The ZM66 has a telescopic sight with a backup dot on top.

The ZM66 may be fitted with an underslung grenade launcher capable of taking the Heckler & Mok Short-Range Reduced-Arc Hybrid Rocket Grenade; however, for safety reasons the launcher is designed only to fire in grenade mode.

Instructions: Press the fire button to shoot, altfire to switch to and from the grenade launcher.

The scope can be adjusted by holding Zoom and Firemode, and using either aim up/down or the fire and altfire buttons.

The grenade does not arm for the first 15 feet or so. While usually firing at close range would leave you with a dud grenade, there is no guarantee the projectile will not arm and detonate at some later point if left unattended!

Reload key reloads the rifle. Alternate reload reloads the grenade launcher. If you are using the rifle and it is jammed, press reload to try to clear the jam.

Tap fire mode when using the rifle to cycle through semi, fullauto and 3-round burst. When using the grenade launcher, hold fire mode and press fire and altfire to program airburst as with the dedicated grenade/rocket launchers.

When you switch to the rifle from any other weapon, you're set to shoot the rifle not the grenade launcher. This is NOT the case with the rocket launcher which remembers your setting.

Protip: Do not hit Reload at just the right time as the message comes up. Doing so is illegal.

### Rotary Support Weapon
GZDoom actor name: `Vulcanette`

GZDoom ammo actor names: `HD4mMag`

Default weapon slot: 4

Loadout codes: `vul`
* fast - 0/1, whether to start in "fuller auto" mode
* zoom - 16-70, 10x the resulting FOV in degrees

At the same time as the ZM66's development, the UAC was experimenting with its own designs for a 4.26 Standard support weapon. One method of overcoming the heat issue was to cycle multiple barrels at slightly looser tolerances, which led to the UAC Standard Mk. III "Vulcanette".

Thus far no stable single-barrel 4.26 SAW design capable of sustained full-auto fire has been found, and the Vulcanette model remains in production today throughout the solar system. Despite its bulk, it provides an advanced but rugged and durable support weapon heavy enough to manage its own recoil with enough heat radiating from its greater surface area to allow limited support fire in space. And it's pretty intimidating-looking, to boot.

Certain engineering limitations (in particular the "always eject" system of cycling rounds) prevented full implementation of the UAC Volt Standard Distribution Licensing Protection Protocol. A lawsuit was promptly settled after the ensuing cross-division drama caused stocks to plummet by an unprecedented 9.9 points in a single day. The reader is nonetheless hereby (without limitation) placed on notice that it is still illegal to reuse 4.26 UAC Standard magazines for any weapon.

Instructions: Use the fire mode key to switch between 700 RPM and 2100 RPM. The higher firing rate is unavailable when your battery power is low (around the last notch of the indicator).

When the active mag has run out, the Vulcanette will automatically cycle the next mag. When unloading the weapon, you will unload, in descending order of priority: the second mag in the queue (and bringing up the remaining mags to replace it); the active mag; the cell.

Use the alternate reload key to load a cell. One cell will provide for about 2000 rounds' worth of shots.

Protip: The Vulcanette is by far the most mechanically complicated weapon in the game. Overheating parts under undue stress and dirt may result in damage that cannot be field repaired even between maps.

### Rocket Launcher
GZDoom actor name: `HDRL`

GZDoom ammo actor names: `HDRocketAmmo`, `HEATAmmo`

Default weapon slot: 5

Loadout codes: `lau`
* zoom - 0/1, which sight comes up first
* heat - 0/1, whether you start with a H.E.A.T. loaded
* grenade - 0/1, whether you start in grenade mode

The Heckler and Mok Urban Artillery series was developed as a response to a growing need for more powerful but more containable infantry firepower for fighting in built-up areas. While the grenade launcher still prevails in ease of use and responsiveness, sometimes one simply hasn't the luxury of arcing a grenade under the low ceilings of a rebel base. The patented Short-Range Reduced-Arc Hybrid Rocket Grenade combines the functions of both RPG and fragmentation grenade in a single neat, deadly, digital precise package.

(There was some brief scandal in the People's Republic of China when illegal foreign-funded underground media sources reported extensive use of this technology in a brutal suppression of a student protest in a gathering place now known as Anquanmen (安圈門, Peaceful Circle Gate) which also allegedly involved numerous people being scalded to death with some unremembered weapon. Official sources say that the current Chairman, the Head that controls the Socialist People's Institute of Co-ordinated Experiments, has scientifically established that only the criminals of the worst sort were neutralized there in an emergency and no students were harmed. However, astute readers would also note that certain unrelated rumours about a "successor head" crisis in the S.P.I.C.E. (colloquially referred to as 替光頭gate) in the preceding months were also very quickly silenced following the incident.)

Instructions: Press fire to launch a rocket. The rocket will arm and accelerate about 14 metres away, and drop as it travels.

Altfire switches to and from grenade mode, as with the rifle's underslung grenade launcher.

The zoom function is limited to rocket mode only and cannot be adjusted. Hold Zoom and tap Firemode to switch between the magnified and the regular sights.

Reloading the launcher works the same way as reloading the Hunter, except the launcher can only hold five rockets plus the chamber.

To set the airburst distance, hold down the fire mode key and use fire and altfire to increase and decrease time accordingly (zero being no airburst). This setting is reset every time you shoot, switch between grenade and rocket mode, or load/unload a HEAT round. The number is in metres of total distance travelled by the rocket grenade (NOT horizontal distance from your target).

You may occasionally run into high-explosive anti-tank (HEAT) rockets that can be loaded into the launcher. These are oversize and once loaded you cannot cycle through the magazine, so it must be used or unloaded before you may use normal rockets again. To load one, hit the alternate reload key; to unload it, hit that key again or the reload key. Any already chambered rocket will be unloaded and pocketed or dropped depending on space in your inventory.

Protip: When the rocket is fired as a grenade, it contains some unused propellant which can cause serious burns in addition to the blast damage. However, the grenade also lacks the direct impact damage that a rocket can do at greater distances, damaging some targets that can otherwise shrug off an explosion. The bigger the target and the longer the range, the more likely a rocket would be preferable to a grenade.

### Grenade Launcher
GZDoom actor name: `Blooper`

GZDoom ammo actor names: `HDRocketAmmo`

Default weapon slot: 5

Loadout code: `blo`

Eventually demand for a simpler, more portable weapon compatible with the new standard Short-Range Reduced-Arc Hybrid Rocket Grenade resulted in the production of a much simpler weapon from previous centuries. Name and all, it seems.

Instructions: Press fire to launch a grenade. As with the rocket launcher, the fire mode key let you program airburst. There is no rocket mode, but altfire can still be used to quickly reset the airburst.

Protip: The blooper takes slightly longer to load than it takes to load a single rocket into the rocket launcher.

### Pulsed Particle Beam Projector
GZDoom actor name: `ThunderBuster`

GZDoom ammo actor names: `HDBattery`

Default weapon slot: 6

Loadout codes: `thu`
* alt - 0/1, whether to start in spray fire mode

In recent years Heckler & Mok were going through their typical occasional experimental infantry energy weapons research kick. Their latest casualty of common sense is the Atmospheric Mk.XI "Thunder Buster", an adaptation of the big phased particle beam cannons found in large Bishop-class high-orbital patrollers. It is indeed a fine and powerful weapon, but nonetheless based on something shooting through space at massive inanimate objects with highly predictable trajectories. For want of any commercial application they sold the specs to the UAC, at an exorbitantly inflated price if one were to include a portion that was ostensibly part of a settlement amid accusations of corporate espionage and stealing of trade secrets in UAC's old, officially scrapped Martian weapons project.

Instructions: Press and hold fire to shoot the beam. The beam must be focussed on a single spot until you see the plasma ball. Keep holding the beam there - you'll know when something has happened. Warning: For best results, only engage targets more than 20 metres and less than 200 metres away.

Press fire mode or altfire to activate the "hacked" version of the Thunder Buster which breaks the beam into a scattered, chaotic mess that does not (usually) trigger the critical explosion but causes much more damage to everything overall. This is extremely energy inefficient, but oddly cathartic.

Hit alternate reload to quickly use the range finder.

Protip: The Thunder Buster's beam destabilizes shields.

### Battle Rifle
GZDoom actor names: `LiberatorRifle`

GZDoom ammo actor names: `HD7mMag`, `SevenMilAmmo`

Default weapon slot: 6

Loadout codes: `lib`
* nogl - 0/1, whether it has a launcher
* nobp - 0/1, whether it is bullpup
* semi - 0/1, whether it is semi-auto only or has a fire selector
* altreticle - 0/1, whether to use the glowing crosshair
* frontreticle - 0/1, whether to scale the crosshair with zoom
* firemode - 0/1, whether you start in full auto
* bulletdrop - 0-600, amount of compensation for bullet drop
* zoom - ??-70, 10x the resulting FOV in degrees

Back before the days of the ZM66, the Volt-Shepard Arms Group (at the time independent of the Universal Anthroposoterium Cybernetics Group) had in limited production an extremely durable, almost jam-free long-range automatic rifle chambered for its 7.76mm full-power cased round that could be produced by virtually anyone. A few government contracts, failed bids and five US Supreme Court appeals resolved against Volt-Shepard later (all 5/4 splits along Democrat/Republican lines and despite extensive advocacy by several military intervenors) the UAC Standard was fully recognized and the Volt-Shepard companies were subject to an immediate hostile takeover by UAC. During the chaos Heckler & Mok bought the rights to the patent, rebranded it as the "ZM7 Liberator", and made a killing selling it at a huge markup to people who resented the state-sponsored UAC/Volt near-monopoly over their right to bear arms. A vague rumour on the Internet that the government was going to ban future production to regulate the copper supply and/or prevent future spree killings (a murderer would not be stopped by a jam or overheat!) also helped sales.

Today a few are still made for the civilian market and can be found among special forces personnel from Canada and several African states. Its biggest drawback, besides market share, is cost: the rate of barrel foulings, breakages and jams more than septuagintuples if the casings are not made from real brass rather than ordinary plastic or steel.

Instructions: As with the ZM66 unless noted otherwise. There is no 3-round burst.

Hit the user3 button to load and unload mags.

The scope can be adjusted by holding Zoom and Firemode, and using either aim up/down or the fire and altfire buttons. You can similarly adjust bullet drop compensation by holding Zoom and Use; the default is roughly the entire length of HD's firing range.

Protip: Every Liberator has a portable reloading bot built into its stock. Hold Use and hit Unload to activate it when you have enough powder and brass.

### Saskatchewan Silver Rift Energy Nano-Extractor, Model 1337
GZDoom actor name: `BFG9K`

GZDoom ammo actor names: `HDBattery`

Default weapon slot: 7

Loadout code: `bfg`

Tapping into the eldritch power of the Ancients using adaptive-AI computer-assisted spacetime magick, AGM was in competition with multiple factions in race to perfect the Botis field glyph, a device that could have made them the single biggest player in the energy market for centuries.

Unluckily for all involved, the proposed energy source caused the rout of civilization and the massacre of mankind - with the resulting lawsuits likely to result in a slightly smaller profit than imagined. Luckily for you, one of these attempts, the Model Thirteen Thirty-Seven is just small enough for one spaceman on the run to carry. Choose life. Choose a fucking big gun.

Background: The Botis fields were first discovered by Dr. Graf Botis in a freak particle beam weapons testing accident during a routine military exercise in Pluto-Charon orbital space. The field appeared to generate some kind of plasma-like or energy-like substance that seemed to behave alternately like a gas and a subatomic particle. Unable to properly characterize it, it was mentioned in Dr. Botis' notes\* as "Gretchenfrage" as a placeholder pending further study. (This was shortened in later notes to "Frage" and eventually "Frag" in common anglophone parlance; in practice most groups used some kind of codeword for it, often a precious metal like gold or silver.)

Under certain conditions (Dr. Botis found the shape and alignment of the lab to be a major factor) it was discovered that Botis fields could be used to recharge power cells almost indefinitely, as though time itself were being reversed. Quadrillions of dollars were diverted to energy research and an entire infrastructure was built across numerous systems - and subsequent discovery of the Ancients' large-scale teleportation, on top of the clean, renewable energy source, surpassed the wildest dreams of researchers and executives alike.

\* *Leaked by a rogue articled student during discovery in one of many class action suits against the Saskatchewan Silver Mining Company (SKAG) and others following the invasion (with the result that residents of the Third Holy Russian Empire, Neo-Moose Jaw, Proxima Centauri II BFG-Babuin Station XVI, all SKAG and AGM stations orbiting Proxima Centauri, Betelgeuse Stations I through III and the City of Edmonton, as well as Her Majesty Victoria III of England, Wales and the Near Side of the Moon in her personal capacity, were unable to recover against Saskatchewan Silver, AGM or any of its subsidiaries or affiliates under any proceedings respecting these invasions). Nothing is known about where this student went afterwards.*

Instructions: The BFG needs the equivalent of 40 cell power units (i.e., 2 cell packs) to fire. The BFG has a built-in cell that cannot be removed, plus space for one removable one; either of these must have at least 35% power to start the charge sequence. To charge it up, simply press fire and remain in an area where there is an influx of Frag. (After the invasion, that means just about anywhere.) You can stop the charging process at its earlier stages by hitting the reload button, and you get to keep what charge you've already accrued. Note that as a side effect of its Hellish nature, the BFG may drain your life energies while you're already under stress (i.e., to exacerbate already low health). This may be an asset (faster charge) or a liability (higher risk).

Once you've got your charge built up, hold the fire key for a second or so to fire. The fire sequence requires a final few moments of charging, after which the Frag will attain critical mass and the firing process will become irreversible. After about a second you will see a large globule of green goo emanating from the BFG, which will then spontaneously send out tendrils to attack hostiles as it travels along its serpentine path.

Reloading the BFG works the same way as for the particle beam gun. You are assumed to load and charge the BFG to full capacity in the downtime between maps.

Use alternate reload to load a completely depleted cell into the BFG. If the BFG's internal cell is charged, it can be used to charge the depleted cell.

There is a slight momentary green glow as a charged cell is removed; leaked UAC studies confirm this is not a sign of radioactivity and exposure to this light will not hurt you. By repeatedly charging and unloading, you can soon replenish all your cell ammunition.

To improve accuracy, it is recommended that one deploy the recoil suppression harness on the BFG's stock. Press altfire to put it on and take it off.

Protip: Long shots beat point blank, as the ball gets more time to launch secondary attacks at hostiles before exploding.

### Cannon
GZDoom actor name: `Brontornis`

GZDoom ammo actor names: `BrontornisRound`

Default weapon slot: 7

Loadout codes: `bro`
* zoom - 0/1, which sight comes up first

The Freeley "Brontornis" series Mk.VII Ultralight Cannon was one of the candidates for the military's Urban Artillery project, ultimately losing out to Heckler & Mok's bid for its versatility and wide-area firepower. It fires a heavy, non-self-propelled 35mm hi-ex anti-materiel/incendiary round (colloquially known as a "bolt") that can punch through most hard targets while remaining highly effective at decisively neutralizing soft targets (colloquially known as "gibbing people").

In the post-invasion paradigm, where surprise teleportations of heavily armoured infantry units into sensitive populated areas is a routine enemy tactic and there is a renewed interest in concentrated, maneuverable firepower in urban combat regularly blurring the line between anti-personnel and anti-materiel, the Freeley Intellectual Properties Group have announced plans on bringing the Brontornis back into full production but thus far supply has not met demand.
Instructions: Point, shoot, kill. Adjust for range in the rare event it is necessary as there is still an arc. Hit firemode or altfire to switch between the dot sight and the magnified stadia.

To ensure operator safety and comfort, the Brontornis cannon should only be fired from a secure position.

Protip: While it is too wide to penetrate walls effectively without detonating, the Brontornis shell is hard enough to overpenetrate softer targets. Line them up.

### Bolt-Action Rifle
GZDoom actor names: `BossRifle`

GZDoom ammo actor names: `HD7mClip`, `SevenMilAmmo`

Default weapon slot: 8

Loadout codes: `bos`
* customchamber - 0/1, whether to use the reduced-jam customization
* frontreticle - 0/1, whether to scale the crosshair with zoom
* bulletdrop - 0-600, amount of compensation for bullet drop
* zoom - 5-60, 10x the resulting FOV in degrees

The Mk. IV Boss rifle is a deadly accurate weapon. Its long barrel, tighter reinforced chamber and manual action allow much greater muzzle velocity than an identical load in the Liberator. Its traditional action and extremely tight trigger allow pinpoint accuracy. The Boss rifle requires clean ammunition to prevent jamming. Good luck!

Instructions: Point, shoot, hope it dies. Altfire works the bolt, similar to the Hunter's pump. DO NOT SHORT STROKE.

Clip reload is only available to fill the entire mag, for reasons.

Hit the user3 button to load and unload clips.

When it jams, hold altfire to keep trying to unjam it. It's a little less finicky than the ZM66 that way.

If it's jamming more than it was before, you may need to clean some gunk out of the action. With the gun completely unloaded, hold altfire to pull the bolt back and hit unload while pulled.

To load a single round directly into the chamber, hold altfire to pull the bolt back and hit reload while pulled.

As with the other rifles, hold zoom and firemode or use to adjust scope zoom.

You can also adjust the bullet drop compensation, with fire mode instead of zoom. Zero means no adjustment and your shot will start parallel with your view. The default is roughly the length of HD's firing range.

Protip: It is nothing short of murder to send out men against the enemy with such a weapon. Find a Liberator.

### Hand Grenade
GZDoom actor name: `HDFragGrenades`

GZDoom ammo actor names: `HDFragGrenadeAmmo`

Default weapon slot: 0

Loadout code: `frg` (ammo only)

The M67.1A fragmentation grenade hasn't changed much from its predecessors over the years. Pull the pin, drop the spoon, chuck it in a window, roll it along the floor, it blows up, everyone left standing is happy.

Instructions: Press and hold fire to set the force of the throw. A quick tap drops the grenade in front of your feet; a long hold risks bouncing the grenade off a wall back towards you (and possibly rolling well past you into safety, but don't assume that). If you've gone over the desired force, hit reload to put the pin back in and let go of the fire button once you hear the click to restart.

Hold altfire for just under a second to pull the pin. Once the pin has been pulled, you can throw it normally or press altfire again to release the spoon and begin the timer.

Grenades on the ground can be kicked out of the way by pressing use. This may save your life one day - or end it, timing being the secret to this as with any other comedy.

Grenade fuze delay is four seconds.

IED: Suppose you had some string and gum in your pocket. And a hand grenade. To use, hit Zoom while your frag grenades are out, and click on a wall to plant the gummed end of the string. Click again to plant the other end with the grenade. Congratulations on your new, probably treaty-contravening tripwire trap! To undo a tripwire trap, simply pick up the grenade as you normally would. If you walk slowly and carefully you *may* be able to safely step over some lower tripwires.

Protip: You can "fling" a hand grenade by turning as you let go, giving it the momentum of your turning movement - just like throwing a Pokéball (albeit without the curveballs). It is strongly recommended that you practice this on the range before attempting it in combat.

## VIII. MONSTERS

*[NOTE TO MAPPERS: Please see check the individual ZScript files for customizing individually placed enemies.]*

### Undead Homeboy
GZDoom actor name: `UndeadHomeboy`

> *"The cyborg is a creature in a post-gender world; it has no truck with bisexuality, pre-oedipal symbiosis, unalienated labour, or other seductions to organic wholeness through a final appropriation of all the powers of the parts into a higher unity. In a sense, the cyborg has no origin story in the Western sense - a 'final' irony since the cyborg is also the awful apocalyptic telos of the 'West's' escalating dominations of abstract individuation, an ultimate self untied at last from all dependency, a man in space."*

The slums of the understations are not a happy place. Angry young men and women fused with blood-red nanobot tattoos, permanently grafted vacuum-resistant oxygenizer masks and more than their years' worth of violence and disillusionment have long prowled the margins of respectable society. When given a chance to break into the traditional territory of that respectable society, their undead remains, still scarred in both brain and body, adapted and weaponized that disillusionment well. They still don't have money for long guns or armour, though.

### Stormtrooper
GZDoom actor name: `ZombieStormtrooper`

> *"The green flash in the sky. His demons were here all along - in our hearts and souls - just waiting for a sign from him. And now they're destroying our world."*

Twisted and corrupted by the daemoniac energies now uncontrollably pouring into this world, these shambling husks wander out to the front, hoping to infiltrate enemy lines and tenderize hostile forces a bit before the Tyrant's real army steamrolls its way in.

Protip: They dish out a lot more than they can take, so the one that kills you is rarely the one you see. Check all exits early and often and don't be shy about deploying your DERP bot.

### Jack-Booted Thug
GZDoom actor name: `Jackboot`, `UndeadJackbootman`

> *"They carry their full context with them, self-contained, like a badge of honor, and represent the most uncomplicated relationship between Occupier and Occupied: unabashed traitor, become converted to the cause. And thus they also become evidence put forward by the Occupier that their will is supported within the city, for the Partial wants only to be Whole: to be the Occupier."*

Mobs of the Tyrant's black-clad, jack-booted undead thugs now wander the countryside, burning and killing and bludgeoning without care or reason except to terrorize what's left of humanity into submission.

Protip: If caught standing in the open, you can sometimes time your duck perfectly to avoid a shot.

### Machine Gunner
GZDoom actor name: VulcanetteGuy

*"He's like a bear. He's like a big shaved bear that hates people."* Hyped up on ultra-violent theology and a permanent slow-drip zerk implant, the Tyrant's crimson-clad vampiric elite infantry are strong enough to wield a Vulcanette one-handed.

Protip: When you run for cover, the machine gunner's typical first reaction is to wait where he's shooting until you come back out, but he doesn't have much patience or empathy. See if you can find a way behind him.

### Marines
GZDoom actor names: `HDMarine`, `Rifleman`, `Enforcer`, `Infiltrator`, `Rocketeer`, `Tango`, `ShotTango`, `SMGTango`, `RocketTango`, `GhostRifleman`, `UndeadRifleman`

Some people you meet are folks just like yourself in the scattered resistance against the Tyrant. Others are less lucky, and appear as reanimated possessed remains of the fallen. Yet others still turn against humanity of their own free will, selling their souls to the Tyrant for a small piece of his hellish dominion that they can call their own. In game terms, the last three in the list are identical to the first three, except without the +friendly flag.

Protip: You'll normally only see these guys if they've been raised by necromantic magic. They are far deadlier than any of the zombies, so try not to let the enemy create too many of them. If you end up with one anyway, a double-tap from the Slayer should do the trick, though explosives are generally safer.

The good news is that normal human bodies cannot be raised without some degeneration. After a few cycles undead marines become indistinguishable from ordinary zombies.

Protip: if in doubt, type `checkin` in the console and you and all allied marines will report their positions.

NOTE TO MAPPERS: Please see `marine.txt` in the ZScript folder for customizing individually placed marines.

### Serpentipedes
GZDoom actor names: `Serpentipede`, `Ardentipede`, `Regentipede`

These gibbering carcinoids were the dominant species from one of the Tyrant's first conquered worlds, the remnant of ancient masters of arcane energy corrupted and diminished by their cruelty and hatred. They are now often seen bustling about in disorganized bands, unthinkingly eating anything edible-looking they find and burning the rest.

Serpentipedes come in three distinct types: the fighter, the mage, and the healer. Fighters are the most common and weakest but also the most vicious. Mages are the rarest, but both their sharper talons and superior fireball-casting more than make up for such shortcomings. But worst of all are the healers: have enough of these in a group coming your way with a few fighters to soak up the shots, and you can watch your easy fight turn into a gruelling, siege-like ordeal.

Though their tentacles can't quite hold and point a gun properly, some serpentipedes keep pistols taken off their victims as war trophies - a fact to keep in mind when ammo is scarce and enemies must be prioritized.

Protip: The serpentipede's fireball is a quantity of Frag-infused teleported hot gas held in place by a magical plasma membrane. When it comes into contact with something, the membrane ruptures at that point, sending out a jet stream of plasma into the target while binding itself magnetically to the target to maximize damage. This binding does NOT constantly track changes in the target's orientation, which means that if you can rapidly turn around and distribute the stream, you may be able to prevent it from penetrating and causing severe organ failure. It will still hurt like a motherfucker though.

This protip does not apply to the secondary function of the membrane found in some balls, which simply smear the burning gas onto you.

### Babuin
GZDoom actor name: `Babuin`, `SpecBabuin`

Of course these evil godless Communists don't have dogs. Instead, they have these little devils who would like nothing more than to chew your gonads off and vomit them into your eyes (because they don't have any).

Protip: Crouching to shoot reduces your room for error significantly. When grappling with one, try to bump it into the map geometry. Remember your sidearms. Non-sapient robots are too stupid to be tricked by cloaking magic.

### Ninja Pirate
GZDoom actor name: `NinjaPirate`

As the serpentipedes were his enforcers, the great spectral worms served as the Tyrant's storm troops before contact with humanity. They strike only from close range, their saw-toothed penta-jaws a septic mess of pain and death.

Protip: The only time a ninja pirate moves faster than your sprint (at least at full health) is while cloaked and fleeing you. Conversely, it gets a bit lazy with its cloak when it is outside of crucial killing range. Oftentimes the best strategy is a retreat, however undignified.

### Frag Containment Storage Cell
GZDoom actor name: `HDBarrel`

Throughout its jursdiction AGM had stored hundreds of barrels of a special compound designed to hold Frag in a concentrated and transportable form. The Tyrant's minions took a liking to this practice, forced the recipe out of the technicians they captured, and starting putting it everywhere to help them establish a foothold in the Terran worlds. Now there are millions and millions of barrels of this volatile substance (nicknamed "nukage") stashed across humanity's various planetary and orbital territories. It may be centuries before anyone can even begin to fathom the ecological damage. And now it seems that the magickal properties of Frag can take possession of the barrels themselves. Which means that among all these polluting barrels of crap, we've also got thousands of shuffling metal monstrosities with balefire attacks and an agenda to kill all humans...

Protip: Killer barrels generally lose their "life"-"giving" potential through animating their container, so they are generally safe to destroy.

### Frag Containment Oxidation Processor
GZDoom actor name: `HDFireCan`

Nukage sometimes needs to be "aired out" to increase its energy density at the cost of some of the power being released into the air. Sometimes these oxidation units are left unattended. Sometimes the resulting mix of symlinked mana, semifluid polymer alloy and decaying ceramic melds into a freakish fire-belching abomination against all that is good and true. Fortunately, it is quite destructible.

Protip: They explode a lot sooner than a nukage barrel and can set one off nearby, so if you see them together shoot the burning barrel first.

### Putto
GZDoom actor name: `Putto`

These ghoulish little four-faced metal terrors drift through the polluted air, flinging toxic balls of balefire at you. Where these flames come from no one knows, since the source is instantly destroyed in a searing fireball once the thing has been damaged beyond its ability to function in combat.

Protip: Getting caught by the blast of a bursting fireball may prevent you from returning fire long enough for the putto to hit you again. The best strategy is to remain on the move until you can land a good, clean hit with a rifle or shotgun.

### Yokai
GZDoom actor name: `Yokai`

These floating evil eyes latch onto you with their gaze and lock you into their twisted, numbing reality, slowly doing damage and wearing you out. They seem to have an affinity for energy weapons and often appear where such might be found.

Protip: The yokai has no physical weapon that it can stab you in the back with. There is no need to look at it until the last split second.

### The Begotten
GZDoom actor names: `FlyingSkull`

> *"How* can *you go on talking all that rot? Your wonderful Lion didn't come and help you, did he? Thought not. And now—even now—when you've been beaten and shoved into this black hole, just the same as the rest of us, you're still at your old game. Starting a new lie! Trying to make us believe we're none of us shut up, and it ain't dark, and heaven knows what."*

They can't stop burning and don't want you to stop burning either! Billions of souls of sapient beings across the universe have been drawn into fuelling the Tyrant's unnatural flame, to eventually be consumed utterly into the seed for a new world tilled, harvested, fertilized with blood and Frag and ready for planting. It is not know how many of them are typically spawned before a new Tyrant bears fruit: some battlefield counts and geological samples taken from the Tyrant's cave suggest an extrapolation anywhere between 1 and 5 trillion."

Protip: Treat the Begotten as a weaker babuin that just happens to be capable of flight. And capable of burning you to a crisp if you leave it on for too long.

### Hive Pit
GZDoom actor name: `SkullSpitter`

There are more Begotten than one might think. They hide in the dark unseen places of space, where the space-time folds into crevices and crannies unfathomed by man. They can drag these holes around by means unknown to us, gathering together into spheres of ossified fire, occasionally releasing one of its own in collective defence - or to find prey.

Protip: Engaging up close isn't as good a tactic as before. Not only does it have a melee attack, any Begotten that it does spit explode if they die after spawning in a bad place. Needless to say, the pit itself also explodes.

### Trilobite
ZDoom actor name: `Trilobite`

One thing is for sure: the Tyrant did not attack us to steal our plasma rifle technology. These monsters send swathes of vaporizingly hot charged material that gently drift towards the target, scorching anything in its path. To make things worse, sometimes it follows this up with a savage power attack that can send you flying one piece at a time.

Once you see the flash, you have two options: duck and cover, or shoot it until it dies.

Protip: The trilobite's ball lightning travels so slowly that at closer engagements you're actually better off circlestrafing it with a pistol.

### Technospider
GZDoom actor name: `TechnoSpider`

These brain repletes are armed with particle beam guns. When you hear its signature screech, take all steps necessary to neutralize the threat immediately.

Protip: To spend time aiming at the technospider is to tempt fate. The surest way to kill one is to lure it into your grenade. They are vulnerable up close as long as you do not approach them head-on.

### Dark Soldier
GZDoom actor name: `Boner`

Reviled throughout the galaxy, nicknamed "the devil's [risible mistake]." The former dominant species of another of the Tyrant's conquered worlds capable of fire magick. These heavyset goblinoids can fling them with much greater force than the serpentipedes, and focus them into much greater mass, suggesting they have experienced a shorter time of degradation since their reality had been assimilated.

Protip: Their missiles can be shot down and are particularly weak against explosives - including each other.

### Combat Slug
GZDoom actor name: `CombatSlug`

Armed with a pair of grossly inefficient gasoline-fueled plasma launchers, these formless cyborgs can tear through armies with the right guidance.

Protip: The combat slug's slow, heavy projectiles mean it must make significant adjustments for distance and movement. The trick is not only to get it to miss, but miss far enough that none of the burning ichor splashes on you and you don't end up running into the affected area immediately after.

### Pain Bringer
GZDoom actor name: `PainBringer`

These petty officers of the Tyrant's legions saturate their immediate vicinity with balefire to make sure that whatever they hate is going to be dead. They can summon putti to their aid if necessary.

Protip: Unlike its bigger cousin the hell knave is not resistant to explosives. A grenade around the corner can take one out, or at least soften it up enough for you to pop in and finish it off with a double-barreled hit of the Slayer. If that is not enough, retreat immediately.

### Pain Lord
GZDoom actor name: `PainLord`

The Tyrant's trusted lieutenants in the first invasions. Able to withstand ludicrous amounts of damage without slowing down, it supplements its balefire attack by summoning a secondary projectile that resembles (and sometimes is) a charging, unstable Begotten.

Protip: The hell prince's skull shot looks scary, but it's mostly a distraction from the fan of seeking missiles around it. It is the only boss monster that can regenerate so don't take your time.

### Necromancer
GZDoom actor name: `Necromancer`

> *"Yet this is held true by the wise of Eressëa, that all those of the Quendi who came into the hands of Melkor, ere Utumno was broken, were put there in prison, and by slow arts of cruelty were corrupted and enslaved; and thus did Melkor breed the hideous race of the Orcs in envy and mockery of the Elves, of whom they were afterwards the bitterest foes."*

A miserable shadow of their once glorious past, these spectral projections of the High Ancients have been warped and deteriorated across the span of incomprehensible eons. They detest the Tyrant they serve, forever bound by a blood oath made when our Moon was still molten hot in the sky. The projected memory of masters of life and sub-creation, their only remaining creative power is to restore life and limb to the fallen, for the sole purpose of continuing their own dark master's battle.

Protip: Unlike all other monsters, who are taken down after suffering a certain amount of gross damage, the monster must feel pain a certain number of times to be destroyed. When the necromancer finally does die do try to stay away from the corpses of larger, non-ammo-supplying baddies for a while until you can escape the map...

### Light Bearer
GZDoom actor name: `LightBearer`

There are rumours about that some of the High Ancients' projections retaining some memory of their sapience, wishing to work with the newer and the dying worlds even after eons of dark damnation. Others say that these are no longer Ancient simulacra at all, but angels sent to mankind's aid. Perhaps none of the proposed answers is true; perhaps they are all true, or there are as many answers as there are these friendly projections. They're not saying anything, though.

Protip: Get out of the way and let them do their work. They are somewhat more maneuverable than their unrepentant brethren, so should you happen across one you shouldn't find it too difficult to make sure it's still by your side.

### Assault Tripod
GZDoom actor name: `SatanRobo`

> *"Dear Santa: I want a giant fucking robot for Christmas. To get rid of all these other horrible problems I have to deal with. Like other giant fucking robots. Especially the ones that like nothing more than to send a barrage of rockets at the slightest suggestion of line of sight with me, each the size of a grown man's torso. I would say I've been a really good boy this year just by putting up with this shit. Yours truly,"*

Protip: The assault tripod is the most heavily shielded boss that is not covered in map geometry. Sustained fire and follow-up attacks are critical. Try setting up traps, get as many things wearing down that shield at once as you can. Give the BFG ball enough time to shoot it until it dies.

### Large Technospider
GZDoom actor name: `Technorantula`

Galloping trigger-happy freak with a full-length-round version of the Vulcanette.

Protip: The Technorantula's shields regenerate more slowly than the Assault Tripod's, but you will have fewer chances to land a shot before getting winged by its shots.

### The Tyrant
GZDoom actor name: `TheTyrant`, `HDBBE`

This eldritch fossilized horror is the mortal avatar of the Tyrant, a vast cosmic mind that births its nightmare armies from its invincible stone skull like a billion crawling, tentacled Pallas Athenae.

Protip: Don't bother with that stupid platform, just aim and shoot and hope and be ready to shoot again if your first shot was blocked by a cube. The Thunder Buster is a powerful asset if you can keep the defenders from throwing off your aim. As with the necromancers, the Tyrant must feel pain a certain number of times before its avatar will depart this world (or whichever one its form happens to be inhabiting).

https://github.com/MatthewTheGlutton/HideousDestructor/
