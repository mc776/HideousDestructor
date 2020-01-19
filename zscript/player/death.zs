// ------------------------------------------------------------
// Death and corpses
// ------------------------------------------------------------
extend class HDPlayerPawn{
	bool silentdeath;
	states{
	death.bleedout:
	death.invisiblebleedout:
	death.internal:
		---- A 0{
			if(playercorpse)playercorpse.A_StopSound(CHAN_VOICE);
			A_StopSound(CHAN_VOICE);
		}
	death:
	xdeath:
		---- A 50{
			binvisible=true;
			A_NoBlocking();
		}
		---- A 20 A_CheckPlayerDone();
		wait;
	}
	int deathcounter;
	override void DeathThink(){
		if(player&&!player.bot){
			if(hd_yolo&&!alldown())player.cmd.buttons&=~BT_USE;
			if(deathcounter==144&&!(player.cmd.buttons&BT_USE)){
				showgametip();
				specialtip=specialtip.."\n\n\clPress \cdUse\cl to continue.";
				deathcounter=145;
			}else if(
				deathcounter<144
				&&player
			){
				player.cmd.buttons&=~BT_USE;
				if(!(player.cheats & CF_PREDICTING))deathcounter++;
			}
			if(playercorpse){
				playercorpse.setorigin((pos.xy-playercorpse.angletovector(angle),pos.z),true);
			}
		}
		if(hd_disintegrator)A_SetBlend("00 00 00",1.,10);
		super.DeathThink();
	}
	override void Die(actor source,actor inflictor,int dmgflags,name MeansOfDeath){

		//forced delay for respawn to clear all persistent damagers
		//exemption made for suicide
		if(
			(source==self&&health<-50000)
			||(
				!multiplayer&&!level.allowrespawn
			)
		)deathcounter=145;
		else deathcounter=1;

		if(hd_dropeverythingondeath){
			array<inventory> keys;
			for(inventory item=inv;item!=null;item=item.inv){
				if(item is "Key"){
					keys.push(item);
					item.detachfromowner();
				}else if(item is "HDPickup"||item is "HDWeapon"){
					DropInventory(item);
				}
				if(!item||item.owner!=self)item=inv;
			}
			for(int i=0;i<keys.size();i++){
				keys[i].attachtoowner(self);
			}
		}


		if(player){
			let www=hdweapon(player.readyweapon);
			if(www)www.OnPlayerDrop();
		}
		if(player.attacker is "HDFire")player.attacker=player.attacker.master;


		bool crouched=player&&player.crouchfactor<0.7;//(!incapacitated)&&height<40;

		if(hd_disintegrator){
			A_SpawnItemEx("Telefog",0,0,0,vel.x,vel.y,vel.z,0,SXF_ABSOLUTEMOMENTUM);
		}else{
			playercorpse=spawn("HDPlayerCorpse",pos,ALLOW_REPLACE);
			playercorpse.vel=vel;playercorpse.master=self;
			if(player)playercorpse.settag(player.getusername());

			playercorpse.translation=translation;
			ApplyUserSkin(true);
			playercorpse.sprite=sprite;

			if(
				(!inflictor||!inflictor.bnoextremedeath)
				&&(-health>gibhealth||aggravateddamage>40)
			)playercorpse.A_Die("extreme");
			else if(!silentdeath)A_StartSound(deathsound,CHAN_VOICE);
		}

		super.die(source,inflictor,dmgflags,MeansOfDeath);
	}
	bool alldown(){
		if(!player)return false;
		if(
			!teamplay
			&&deathmatch
		){
			cvar.findcvar("hd_yolo").setbool(false);
			return false;
		}
		bool ad=true;
		for(int i=0;i<MAXPLAYERS;i++){
			if(
				playeringame[i]
				&&players[i].mo
				&&players[i].mo.health>HDCONST_MINSTANDHEALTH
				&&hdplayerpawn(players[i].mo)
				&&hdplayerpawn(players[i].mo).incapacitated<1
				&&hdplayerpawn(players[i].mo).incaptimer>10
				&&(
					!teamplay
					||players[i].getteam()==player.getteam()
				)
			){
				ad=false;
				break;
			}
		}
		return ad;
	}
	void healthreset(){
		regenblues=0;
		woundcount=0;
		oldwoundcount=0;
		unstablewoundcount=0;
		burncount=0;
		aggravateddamage=0;
		stunned=0;
		bloodloss=0;
		secondflesh=0;
	}
}


//call the lives counter thinker when someone dies
extend class HDHandlers{
	override void PlayerDied(PlayerEvent e){
		hdlivescounter.playerdied(e.playernumber);
	}
}


//corpse substituter
class HDPlayerCorpse:HDMobMan{
	default{
		monster; -countkill +friendly +nopain
		health 100;mass 160;
		tag "$CC_MARINE";
	}
	override void Tick(){
		super.Tick();
		let ppp=hdplayerpawn(master);
		if(
			ppp
			&&ppp.health>0
		){
			ppp.playercorpse=null;
			ppp.healthreset();
			ppp.levelreset();
			master=null;
		}
		if(
			health>0
			&&!instatesequence(curstate,resolvestate("raise"))
			&&!instatesequence(curstate,resolvestate("ungib"))
		)A_Die();
	}
	states{
	spawn:
		#### AA -1;
		PLAY A 0;
	forcexdeath:
		#### A -1;
	death:
		#### H 10{
			let ppp=hdplayerpawn(master);
			if(
				ppp
				&&ppp.incapacitated>(4<<2)
			)setstatelabel("dead");
			else scale.x*=randompick(-1,1);
		}
		#### IJ 8;
		#### K 3;
	deadfall:
		#### K 2;
		#### LM 4 A_JumpIf(abs(vel.z)>1,"deadfall");
	dead:
		#### M 1; //used for bleeding out
		#### N 2 canraise A_JumpIf(abs(vel.z)>2,"deadfall");
		wait;
	xdeath:
		#### O 5{
			A_XScream();
			scale.x=1;
		}
		#### PQRSTUV 5;
		#### W -1;
	xxxdeath:
		#### O 5;
		#### P 5 A_XScream();
		#### QRSTUV 5;
		#### W -1 canraise;
		stop;
	ungib:
		---- A 0{
			bnotargetswitch=false;
			actor masbak=master;
			A_SpawnItemEx("ReallyDeadRifleman",flags:
				SXF_NOCHECKPOSITION|
				SXF_TRANSFERPOINTERS|
				SXF_TRANSFERTRANSLATION|
				SXF_ISMASTER
			);
			A_RaiseMaster(RF_NOCHECKPOSITION|RF_TRANSFERFRIENDLINESS);
			master.master=masbak;
		}
		stop;
	raise:
		#### MLKJIH 5;
		---- A 0{
			A_SpawnItemEx("UndeadRifleman",flags:
				SXF_NOCHECKPOSITION|
				SXF_TRANSFERPOINTERS|
				SXF_TRANSFERTRANSLATION
			);
		}
	falldown:
		stop;
	}
}

