// ------------------------------------------------------------
// Fake CCMDs created through event handlers and aliases
// ------------------------------------------------------------
extend class HDHandlers{
	override void ConsoleProcess(ConsoleEvent e){
		if(
			e.name~=="ab"
		)
		eventhandler.sendnetworkevent(e.name,e.args[0],e.args[1],e.args[2]);
	}
	override void NetworkProcess(ConsoleEvent e){
		let ppp=hdplayerpawn(players[e.player].mo);
		if(!ppp)return;

		bool alive=ppp.health>0;

		if(e.name~=="ab")SetAirburst(ppp,e.args[0]);

		else if(alive&&e.name~=="hd_lean")Lean(ppp,e.args[0]);
		else if(alive&&e.name~=="hd_taunt")Taunt(ppp);
		else if(alive&&e.name~=="hd_showskins")ShowSkins(ppp);
		else if(alive&&e.name~=="hd_findrange")FindRange(ppp);
		else if(alive&&e.name~=="hd_purge")PurgeUselessAmmo(ppp);
		else if(alive&&e.name~=="hd_dropone")DropOne(ppp,ppp.player,e.args[0]);
		else if(alive&&e.name~=="checkin")HDMarine.CallCheckIn(ppp);
		else if(alive&&e.name~=="hd_playdead")PlayDead(ppp);

		else if(e.name~=="hd_strip")ChangeArmour(ppp);

		else if(alive&&e.name~=="ied")SetIED(ppp,e.args[0],e.args[1]);
		else if(e.name~=="iedtag")SetIED(ppp,-abs(e.args[0]),0);

		else if(alive&&e.name~=="herp")SetHERP(ppp,e.args[0],e.args[1],e.args[2]);
		else if(alive&&e.name~=="herpdir")SetHERP(ppp,3,e.args[1],e.args[0]);
		else if(e.name~=="herptag")SetHERP(ppp,-abs(e.args[0]),0,0);

		else if(alive&&e.name~=="derp")SetDERP(ppp,e.args[0],e.args[1],e.args[2]);
		else if(e.name~=="derptag")SetDERP(ppp,-abs(e.args[0]),0,0);

		else if(e.name~=="doorbuster")SetDB(ppp,e.args[0],e.args[1]);
		else if(e.name~=="doorbustertag")SetDB(ppp,-abs(e.args[0]));

		else if(e.name~=="clearweaponspecial")ClearWeaponSpecial(ppp);

		else if(
			e.name~=="teamspawn"
			&&teamplay&&deathmatch
			&&ppp.player.crouchfactor>0.9
		)MoveToTeamSpawn(ppp,players[e.player].getteam(),e.args[0]);
	}
}


