// ------------------------------------------------------------
// Helpful? tips???
// ------------------------------------------------------------
extend class hdplayerpawn{
	double specialtipalpha;
	string specialtip;
	void showgametip(){
		if(
			!player
			||!hd_helptext
			||!hd_helptext.getbool()
		)return;
		static const string specialtips[]={
			"Read the manual!\n(open the pk7 with 7Zip and look for \cdhd_manual.md\cu)",
			"Hold \cdUse\cu to check what options are available for a given weapon.",
			"Make sure you bind keys for \cdall weapon \"User\" buttons\cu\n\cdDrop Weapon\cu, \cdZoom\cu and \cdReload\cu!",
			"Check the menu for additional keybinds unique to HD!",
			"To stop bleeding, hit \cd9\cu or use the \cdmedikit\cu.\nThen, if needed, take off your armour\nby hitting \cdReload\cu.",
			"Hold \cdJump\cu and move forwards into a ledge to try to clamber over it.",
			"Hit \cdUser3\cu to access the magazine manager on most weapons.",
			"Hit \cdUser4\cu to unload most weapons.",
			"If you are carrying too much useless ammo,\nhit the \cdPurge Useless Ammo\cu key\nor use the \cdhd_purge\cu command.",
			"Hit \cdUse\cu on a ladder to start climbing, and again or \cdJump\cu to dismount.\nHit \cdJump\cu while \cdcrouching\cu to take down the ladder.",

			"Your movement and turning affect your punches and grenades.\nGo to the range and practice!",
			"Use stimpacks to slow down bleeding.",

			"If the sight picture is getting in your way when you're on the move,\ntry changing the \cdhd_noscope\cu and \cdhd_sightbob\cu settings to taste.",
			"Holding \cdZoom\cu will greatly stabilize your aim,\nand implicitly brace your weapon\nagainst nearby map geometry.",
			"Hit the \cdDrop One\cu key or use the \cdhd_dropone\cu command\nto drop a single unit of each ammo type used by your current weapon.",
			"If you don't want the diving action when you hit \cdCrouch\cd while running,\nset \cdhd_noslide\cu to true.",
			"If you don't want \cdZoom\cu to make you lean,\nset \cdhd_nozoomlean\cu to true.",

			"Set \cdfraglimit\cu to 100+ to enable HD's elimination mode.\nIn co-op, a positive fraglimit under 100\nalso serves as a lives limit.",
			"Turn on \cdhd_pof\cu in co-op or teamplay for a one-life mode where\nyou can only be raised in the presence of all living teammates.",
			"Turn on \cdhd_flagpole\cu in multiplayer to create an objective!\n(Move AWAY from the flagpole to program the flag.)",
			"Turn on \cdhd_nobots\cu to cause the bots to be replaced by HD marines.",

			"To remote activate a switch or door,\ntype \cdderp 555\cu to stick a D.E.R.P. on to it,\nthen \cdderp 556\cu to make it flick the switch.",
			"Hold \cdZoom\cu and/or \cdUse\cu when you use the goggles to set the amplitude.\nBoth together decrements; \cdUse\cu alone increments.\n\cdZoom\cu alone toggles red/green mode.",

			"Zombies never surrender!\nCheck downed monsters to see\nif they're still twitching.",

			"If a map contains a mandatory drop that is harmless\nin vanilla but absolutely cannot be survived in HD,\nit is socially acceptable to cheat past it with \cdiddqd\cu or \cdfly\cu."
		};
		int newtip;
		int lasttip=cvar.getcvar("hd_lasttip",player).getint();
		do{newtip=random(0,specialtips.size()-1);}while(newtip==lasttip);

//		newtip=specialtips.size()-1;

		hd_lasttip.setint(newtip);
		specialtip="\crTIP: \cu"..specialtips[newtip];
		specialtipalpha=1001.;
		A_Log(specialtip,true);
	}
}
