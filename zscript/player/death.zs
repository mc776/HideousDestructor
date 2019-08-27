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


		bool crouched=(!incapacitated)&&height<40;

		if(hd_disintegrator){
			A_SpawnItemEx("Telefog",0,0,0,vel.x,vel.y,vel.z,0,SXF_ABSOLUTEMOMENTUM);
		}else{
			playercorpse=spawn("HDPlayerCorpse",pos,ALLOW_REPLACE);
			playercorpse.vel=vel;playercorpse.master=self;
			if(
				crouched
			)playercorpse.sprite=GetSpriteIndex("PLYCA0");
				else playercorpse.sprite=GetSpriteIndex("PLAYA0");
			playercorpse.translation=translation;
			playercorpse.A_SetSize(12,52);

			if(
				(!inflictor||!inflictor.bnoextremedeath)
				&&(-health>gibhealth||aggravateddamage>40)
			)playercorpse.A_Die("extreme");
			else{
				playercorpse.A_Die(MeansOfDeath);
				if(!silentdeath){
					A_PlayerScream();
				}
			}
		}

		//THE BUG IS FIXED
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
				&&players[i].mo.health>0
				&&hdplayerpawn(players[i].mo)
				&&hdplayerpawn(players[i].mo).incapacitated<1
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
		bledout=0;
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
		monster; -countkill +solid +friendly
		height 52;radius 12;health 100;mass 160;
	}
	override void Tick(){
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
		super.Tick();
	}
	states{
	spawn:
		#### A -1;// nodelay A_Die();
		PLAY A 0;
	death:
		#### H 10{
			A_NoBlocking();
			bshootable=true;
			scale.x*=randompick(-1,1);
		}
		#### IJ 8;
		#### K 3 A_SetSize(12,13);
	deadfall:
		#### K 2;
		#### LM 4 A_JumpIf(abs(vel.z)>1,"deadfall");
	dead:
		#### M 1; //used for bleeding out
		#### N 2 canraise A_JumpIf(abs(vel.z)>2,"deadfall");
		wait;
	xdeath:
		#### O 5{
			A_NoBlocking();
			A_XScream();
			scale.x=1;
		}
		#### PQRSTUV 5;
		#### W -1;
	xxxdeath:
		#### O 5{
			bshootable=false;
			A_GiveInventory("IsGibbed");
			A_SpawnItemEx("MegaBloodSplatter",0,0,34,flags:SXF_NOCHECKPOSITION);
		}
		#### P 5 A_XScream();
		#### QR 5 A_SpawnItemEx("MegaBloodSplatter",0,0,34,flags:SXF_NOCHECKPOSITION);
		#### STUV 5;
		#### W -1 canraise;
		stop;
	raisegibbed:
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
		stop;
	}
}


