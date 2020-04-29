// ------------------------------------------------------------
// Respawn, including bot replacements and endgame
// ------------------------------------------------------------
extend class HDPlayerPawn{
	void ReplaceBot(){
		actor spot;int garbage;
		[garbage,spot]=A_SpawnItemEx("BotBot",flags:
			SXF_NOCHECKPOSITION|SXF_TRANSFERTRANSLATION|SXF_SETMASTER
		);
		setz(pos.z+50);
		A_Log(string.format("Bot %s replaced with rifleman.",player.getusername()));
		A_Morph("HDBotSpectator",int.MAX,MRF_FULLHEALTH,"CheckPuff","CheckPuff");
	}
}


//respawn event
extend class HDHandlers{
	vector3 corpsepos[MAXPLAYERS];
	override void PlayerRespawned(PlayerEvent e){
		let hde=HDPlayerPawn(players[e.playernumber].mo);
		if(!hde)return;

		//revived with the Power of Friendship
		if(hd_pof){
			hde.incaptimer=140;
			hde.incapacitated=20;
			hde.damagemobj(null,null,hde.health-10,"maxhpdrain",DMG_FORCED);
			hde.setorigin(corpsepos[e.playernumber],false);
			hde.angle=(corpsepos[e.playernumber].z%1.)*1000;
			return;
		}

		//replenish ammo to mitigate spawncamping
		if(!hd_dropeverythingondeath){
			for(inventory hdww=hde.inv;hdww!=null;hdww=hdww.inv){
				let hdw=hdweapon(hdww);
				if(hdw&&!hdbackpack(hdw))hdw.initializewepstats(true);
				let hdm=hdmagammo(hdww);
				if(hdm)hdm.maxcheat();
			}
		}
		if(hdlivescounter.wiped(e.playernumber)){
			hde.A_GiveInventory("SpecMorph"); //keep as an inv for ease of testing
			hde.A_GiveInventory("InvReset");
		}else{
			if(
				teamplay&&deathmatch
			){
				vector3 tmspn=teamspawns[players[e.playernumber].getteam()];
				if(tmspn!=(0,0,0)){
					hde.setorigin(tmspn,false);
					hde.angle=teamspawnangle[players[e.playernumber].getteam()];
					if(
						!hde.trymove(hde.pos.xy,true)
						&&hde.blockingmobj&&hde.blockingmobj.bshootable
					)hde.blockingmobj.damagemobj(hde,hde,hde.TELEFRAG_DAMAGE,"Balefire",DMG_FORCED);
					hde.A_Recoil(-15);
				}
			}

			hde.spawn("TeleFog",hde.pos,ALLOW_REPLACE); //HDPP only sets telefog in postbeginplay
		}
	}

	vector3 teamspawns[255]; //how do you get # of teams
	double teamspawnangle[255];
	void MoveToTeamSpawn(hdplayerpawn ppp,int team,int cmd){
		string messagesubject=string.format("\cl%s has",ppp.player.getusername());
		string message;
		if(cmd==666){
			if(ppp.player.crouchfactor<1.||!ppp.checkmove(ppp.pos.xy,PCM_NOACTORS)){
				ppp.A_Log("\crThere is not enough room to set a spawnpoint.");
				return;
			}else{
				teamspawns[team]=ppp.pos;
				teamspawnangle[team]=ppp.angle;
				message=string.format(" changed the team spawnpoint to [\cx%i\cl,\cy%i\cl,\cz%i\cl]",
					teamspawns[team].x,teamspawns[team].y,teamspawns[team].z
				);
			}
		}else if(cmd<0||cmd==999){
			teamspawns[team]=(0,0,0);
			message=(" \cyCLEARED\cl the team spawnpoint! You will respawn randomly!\n\cu(Type \crteamspawn 666\cu to set a new spawnpoint.)");
		}else{
			if(teamspawns[team]==(0,0,0))ppp.A_Log("\clNo team spawnpoint has been set. Type \crteamspawn 666\cl to set it.",true);
			else ppp.A_Log(string.format("\clThe team spawnpoint is [\cx%i\cl,\cy%i\cl,\cz%i\cl]",
				teamspawns[team].x,teamspawns[team].y,teamspawns[team].z
			),true);
			return;
		}
		for(int i=0;i<MAXPLAYERS;i++){
			if(players[i].getteam()==team&&players[i].mo)
			players[i].mo.A_Print(
				string.format("%s\cl%s",
					i==ppp.playernumber()?"\clYou have":messagesubject,
					message
				)
			);
		}
	}
}




//Spectator playerpawn
class SpecMorph:ActionItem{
	states{
	pickup:
		TNT1 A 0{
			setz(pos.z+50);
			A_Morph("HDSpectator",int.MAX,MRF_FULLHEALTH,"CheckPuff","TeleportFog");
			if(!multiplayer)return;
			if(player)A_Log(string.format("%s is now a spectator.",player.getusername()));
		}fail;
	}
}
class HDBotSpectator:HDSpectator{
	default{
		+nointeraction
	}
}
class HDSpectator:PlayerPawn{
	default{
		-solid -shootable +invisible +notarget +nogravity +noblockmap
		-telestomp +alwaystelefrag -pickup +notrigger
		telefogsourcetype "";
		telefogdesttype "";
		player.viewbob 0;
		player.soundclass "spectator";
		player.userange 0;player.jumpz 0;maxstepheight 1;
		player.morphweapon "NullWeapon";
		player.forwardmove 0.3;player.sidemove 0.3;
		player.startitem "NullWeapon";
		player.viewheight 1;player.attackzoffset 0;
		height 32;radius 16;
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		return super.damagemobj(inflictor,source,damage,mod,flags,angle);
	}
	override void postbeginplay(){
		super.postbeginplay();
		setz(min(floorz+64,ceilingz-4));
		if(!multiplayer)return;
		textalpha=0;
		titleticker=0;
	}
	override bool cancollidewith(actor other,bool passive){return false;}
	override void checkcrouch(bool totallyfrozen){}
	int destplayer;
	double textalpha;
	string spectitle;
	int titleticker;
	override void tick(){
		playerpawn.tick();
		if(!player||player.bot||player.mo!=self)return;

		int oldinput=getplayerinput(MODINPUT_OLDBUTTONS);
		vel*=0.9;
		if(player.cmd.buttons&BT_CROUCH)vel.z-=1;

		if(textalpha<0.7)textalpha+=0.02;
		if(!titleticker){
			if(hdlivescounter.owndeaths(playernumber())>fraglimit%100)spectitle="O u t   o f   l i v e s .";
			else spectitle="Now spectating.";
			titleticker=-1;
		}else if(titleticker>0)titleticker--;

		//warp to players
		int chosenplayer=-1;int choosedir;
		if(
			(player.cmd.buttons&BT_ATTACK)&&!(oldinput&BT_ATTACK)
			||(player.cmd.buttons&BT_ALTATTACK)&&!(oldinput&BT_ALTATTACK)
		){
			if(player.cmd.buttons&BT_ATTACK)choosedir=1;
			else choosedir=-1;
	
			for(int i=0;i<MAXPLAYERS&&chosenplayer<0;i++){
				destplayer+=choosedir;
				if(destplayer<0)destplayer=MAXPLAYERS-1;
				else if(destplayer==MAXPLAYERS)destplayer=0;

				if(!playeringame[destplayer])continue;

				actor pmo=players[destplayer].mo;
				if(
					pmo
					&&!(pmo is "HDSpectator")
					&&(
						!teamplay
						||bot_allowspy
						||players[destplayer].getteam()==player.getteam()
					)
				){
					titleticker=70;
					spectitle="Now viewing: \cx"..players[destplayer].getusername();
					setorigin(pmo.pos,true);
					angle=pmo.angle;pitch=10;
					A_ChangeVelocity(-6,0,12,CVF_RELATIVE|CVF_REPLACE);
					break;
				}
			}
		}
	}
	states{
	spawn:
	see:
	melee:
	missile:
	pain:
		TNT1 A -1;
	death:
	xdeath:
		TNT1 A 0 A_NoBlocking();
		TNT1 A 10 A_CheckPlayerDone();
		wait;
	}
}
