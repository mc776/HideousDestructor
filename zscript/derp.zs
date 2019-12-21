// ------------------------------------------------------------
// D.E.R.P. Robot
// ------------------------------------------------------------
enum DerpConst{
	DERP_TID=451816,
	DERP_MAXTICTURN=15,
	DERP_TURRET=1,
	DERP_AMBUSH=2,
	DERP_PATROL=3,
	DERP_RANGE=320,
}
class DERPBot:HDUPK{
	int cmd;
	int oldcmd;
	int ammo;
	int botid;
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "D.E.R.P. Robot"
		//$Sprite "DERPA1"

		+ismonster +noblockmonst +shootable
		+friendly +nofear +dontgib +noblood +ghost
		painchance 240;painthreshold 12;
		speed 3;
		damagefactor "Thermal",0.7;damagefactor "Normal",0.8;
		radius 4;height 8;deathheight 8;maxdropoffheight 4;maxstepheight 4;
		bloodcolor "22 22 22";scale 0.6;
		health 100;mass 20;
		maxtargetrange DERP_RANGE;
		hdupk.pickupsound "derp/crawl";
		hdupk.pickupmessage ""; //let the pickup do this
		obituary "%o went derp.";
	}
	override bool cancollidewith(actor other,bool passive){return other.bmissile||HDPickerUpper(other)||DERPBot(other);}
	bool DerpTargetCheck(bool face=false){
		if(!target)return false;
		if(
			target==master
			||(master&&target.isteammate(master))
		){
			A_ClearTarget();
			bfriendly=true;
			setstatelabel("spawn");
			return false;
		}
		if(face){
			A_PlaySound("derp/crawl");
			A_FaceTarget(2,2,FAF_TOP);
		}
		flinetracedata dlt;
		linetrace(
			angle,DERP_RANGE,pitch,
			offsetz:2,
			data:dlt
		);
		return(dlt.hitactor==target);
	}
	void DerpAlert(string msg="Derpy derp!"){
		if(master)master.A_Log(string.format("\cd[DERP]  %s",msg),true);
	}
	void DerpShot(){
		A_PlaySound("weapons/pistol",CHAN_WEAPON);
		if(!random(0,11)){
			if(bfriendly)A_AlertMonsters(0,AMF_TARGETEMITTER);
			else A_AlertMonsters();
		}
		HDBulletActor.FireBullet(self,"HDB_9",zofs:2,spread:2.,speedfactor:frandom(0.97,1.03));
		pitch+=frandom(-1.,1.);angle+=frandom(-1.,1.);
	}
	void A_DerpAttack(){
		if(DerpTargetCheck(false))DerpShot();
	}
	void A_DerpLook(int flags=0,statelabel seestate="see"){
		A_ClearTarget();
		if(cmd==DERP_AMBUSH)return;
		A_LookEx(flags,label:seestate);
		if(
			deathmatch&&bfriendly
			&&master&&master.player
		){
			for(int i=0;i<MAXPLAYERS;i++){
				if(
					playeringame[i]
					&&players[i].mo
					&&players[i].mo!=master
					&&(!teamplay||players[i].getteam()!=master.player.getteam())
					&&distance3d(players[i].mo)<DERP_RANGE
				){
					bfriendly=false;
					target=players[i].mo;
					if(!(flags&LOF_NOJUMP))setstatelabel(seestate);
					break;
				}
			}
		}
		if(flags&LOF_NOJUMP&&target&&target.health>0&&checksight(target))setstatelabel("missile");
	}

	int movestamina;
	double goalangle;
	vector2 goalpoint;
	vector2 originalgoalpoint;
	double angletogoal(){
		vector2 vecdiff=level.vec2diff(pos.xy,goalpoint);
		return atan2(vecdiff.y,vecdiff.x);
	}
	void A_DerpCrawlSound(int chance=50){
		A_PlaySound("derp/crawl",CHAN_BODY,pitch:1.3);
		if(bfriendly&&!random(0,50))A_AlertMonsters(0,AMF_TARGETEMITTER);
	}
	void A_DerpCrawl(bool attack=true){
		bool moved=true;
		//ambush(1) does nothing, not even make noise
		if(attack&&cmd!=DERP_AMBUSH){
			if(target&&target.health>0)A_Chase(
				"missile","missile",CHF_DONTMOVE|CHF_DONTTURN|CHF_NODIRECTIONTURN
			);
		}

		if(
			cmd==DERP_PATROL
			||movestamina<20
		){
			A_DerpCrawlSound();
			moved=TryMove(pos.xy+(cos(angle),sin(angle))*speed,false);
			movestamina++;
		}else if(
			cmd==DERP_TURRET
		){
			A_DerpCrawlSound();
			angle+=36;
		}

		if(!moved){
			goalangle=angle+frandom(30,120)*randompick(-1,1);
		}else if(
			movestamina>20
			&&movestamina<1000
			&&!random(0,23)
		){
			goalangle=angletogoal();
			if(cmd==DERP_PATROL){
				goalangle+=frandom(-110,110);
				movestamina=0;
			}
		}else goalangle=999;
		if(goalangle!=999)setstatelabel("Turn");
	}
	void A_DerpTurn(){
		if(goalangle==999){
			setstatelabel("see");
			return;
		}
		A_DerpCrawlSound();
		double norm=deltaangle(goalangle,angle);
		if(abs(norm)<DERP_MAXTICTURN){
			angle=goalangle;
			goalangle=999;
			return;
		}
		if(norm<0){
			angle+=DERP_MAXTICTURN;
		}else{
			angle-=DERP_MAXTICTURN;
		}
	}

	line stuckline;
	sector stuckbacksector;
	double stuckheight;
	int stucktier;
	vector2 stuckpoint;
	void A_DerpStuck(){
		setz(
			stucktier==1?stuckbacksector.ceilingplane.zatpoint(stuckpoint)+stuckheight:
			stucktier==-1?stuckbacksector.floorplane.zatpoint(stuckpoint)+stuckheight:
			stuckheight
		);
		if(
			!stuckline
			||ceilingz<pos.z
			||floorz>pos.z
		){
			stuckline=null;
			setstatelabel("unstucknow");
			return;
		}
	}

	override void postbeginplay(){
		super.postbeginplay();
		originalgoalpoint=pos.xy;
		goalpoint=originalgoalpoint;
		goalangle=999;
		ChangeTid(DERP_TID);
		if(!master||!master.player){
			ammo=15;
			cmd=random(1,3);
		}
		if(cmd==DERP_AMBUSH||cmd==DERP_TURRET)movestamina=1001;
		oldcmd=cmd;
	}
	states{
	stuck:
		DERP A 1 A_DerpStuck();
		wait;
	unstuck:
		DERP A 2 A_JumpIf(!stuckline,"unstucknow");
		DERP A 4 A_PlaySound("derp/crawl",6);
	unstucknow:
		DERP A 2 A_PlaySound("misc/fragknock",5);
		DERP A 10{
			if(stuckline){
				bool exiting=
					stuckline.special==Exit_Normal
					||stuckline.special==Exit_Secret;
				if(
					!exiting||!master||(
						checksight(master)
						&&distance3d(master)<128
					)
				){
					stuckline.activate(master,0,SPAC_Use);
					if(exiting&&master)master.A_GiveInventory("DERPUsable",1);
				}
			}
			stuckline=null;
			spawn("FragPuff",pos,ALLOW_REPLACE);
			bnogravity=false;
			A_ChangeVelocity(3,0,2,CVF_RELATIVE);
			A_PlaySound("weapons/bigcrack",4);
		}goto spawn2;
	give:
		DERP A 0{
			stuckline=null;bnogravity=false;
			if(cmd!=DERP_AMBUSH){
				A_PlaySound("weapons/rifleclick2",CHAN_AUTO);
				cmd=DERP_AMBUSH;
			}

			if(ammo>=0){
				target.A_PlaySound("weapons/rifleclick",CHAN_AUTO);
				let mmm=HDMagAmmo.SpawnMag(target,"HD9mMag15",ammo);
				if(mmm)grabthinker.grab(target,mmm);
			}
			actor ddd=spawn(health>0?"DERPUsable":"DERPDEAD",pos);
			if(ddd){
				ddd.translation=self.translation;
				grabthinker.grab(target,ddd);
			}
			destroy();
			DERPController.GiveController(target);
			return;
		}goto spawn;
	spawn:
		DERP A 0 nodelay A_JumpIf(!!stuckline,"stuck");
	spawn2:
		DERP A 0 A_ClearTarget();
		DERP A 0 A_DerpLook();
		DERP A 3 A_DerpCrawl();
		loop;
	see:
		DERP A 0 A_ClearTarget();
		DERP A 0 A_JumpIf(ammo<1&&movestamina<1&&goalangle==-999,"noammo");
	see2:
		DERP A 2 A_DerpCrawl();
		DERP A 0 A_DerpLook(LOF_NOJUMP);
		DERP A 2 A_DerpCrawl();
		DERP A 0 A_DerpLook(LOF_NOJUMP);
		DERP A 2 A_DerpCrawl();
		DERP A 0 A_DerpLook(LOF_NOJUMP);
		DERP A 2 A_DerpCrawl();
		DERP A 0 A_DerpLook(LOF_NOJUMP);
		---- A 0 setstatelabel("see");
	turn:
		DERP A 1 A_DerpTurn();
		wait;
	noshot:
		DERP AAAAAAAA 2 A_DerpCrawl();
		---- A 0 setstatelabel("see2");
	pain:
		DERP A 20{
			A_PlaySound("derp/crawl",CHAN_BODY);
			angle+=randompick(1,-1)*random(2,8)*10;
			pitch-=random(10,20);
			vel.z+=2;
		}
	missile:
	ready:
		DERP A 0 A_PlaySound("derp/crawl",CHAN_BODY,0.6);
		DERP AAA 1 A_FaceTarget(20,20,0,0,FAF_TOP,-4);
		DERP A 0 A_JumpIf(cmd==DERP_AMBUSH,"spawn");
		DERP A 0 A_JumpIfTargetInLOS(1,1);
		loop;
	aim:
		DERP A 2 A_JumpIf(!DerpTargetCheck(),"noshot");
		DERP A 0 DerpAlert("\cjEngaging hostile.");
	fire:
		DERP A 0 A_JumpIfHealthLower(1,"dead");
		DERP A 0 A_JumpIf(ammo>0,"noreallyfire");
		goto noammo;
	noreallyfire:
		DERP C 1 bright light("SHOT") DerpShot();
		DERP D 1 A_SpawnItemEx("HDSpent9mm", -3,1,-1, random(-1,-3),random(-1,1),random(-3,-4), 0,SXF_NOCHECKPOSITION|SXF_SETTARGET);
		DERP A 4{
			if(getzat(0)<pos.z) A_ChangeVelocity(cos(pitch)*-2,0,sin(pitch)*2,CVF_RELATIVE);
			else A_ChangeVelocity(cos(pitch)*-0.4,0,sin(pitch)*0.4,CVF_RELATIVE);
			ammo--;
		}
		DERP A 1{
			A_FaceTarget(10,10,0,0,FAF_TOP,-4);
			if(target&&target.health<1){  
				DerpAlert("\cf  Hostile eliminated.");
			}
		}
	yourefired:
		DERP A 0 A_JumpIfHealthLower(1,"see",AAPTR_TARGET);
		DERP A 0 A_JumpIfTargetInLOS("fire",2,JLOSF_DEADNOJUMP,DERP_RANGE,0);
		DERP A 0 A_JumpIfTargetInLOS("aim",360,JLOSF_DEADNOJUMP,DERP_RANGE,0);
		goto noshot;
		DERP A 0 A_CheckLOF("noshot",CLOFF_SKIPTARGET|CLOFF_JUMPNONHOSTILE|CLOFF_JUMPOBJECT, 0,0, 0,0, 7,0);
		goto fire;
	death:
		DERP A 0{
			DerpAlert("\cg  Operational fault.\cj Standby for repairs.");
			A_PlaySound("weapons/bigcrack",CHAN_AUTO);
			A_SpawnItemEx("HDSmoke",0,0,1, vel.x,vel.y,vel.z+1, 0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
			A_SpawnChunks("BigWallChunk",12);
		}
	dead:
		DERP A -1;
	noammo:
		DERP A 10{
			A_ClearTarget();
			DerpAlert("\cjOut of ammo. Await retrieval.");
		}goto spawn;
	}
}



//dropped corpse
class DERPDEAD:DERPUsable{
	default{
		//$Category "Items/Hideous Destructor/"
		//$Title "D.E.R.P. Robot (Broken)"
		//$Sprite "DERPA0"
		-inventory.invbar
		inventory.pickupmessage "Picked up a Defence, Engagement, Reconnaissance and Patrol robot. It is damaged.";
		hdpickup.bulk ENC_DERP;
		hdpickup.refid "";
		tag "D.E.R.P. robot (broken)";
	}
	override bool isused(){return false;}
	states{
	use:
		TNT1 A 0 A_Jump((256/77),2);
		TNT1 A 0 A_Log("\cd[DERP]\cj  ERROR",true);
		fail;
		TNT1 A 0;
		goto super::use;
	}
	override void Consolidate(){
		if(
			owner
			&&amount>randompick(0,0,0,0,0,1,1,2)
			&&!owner.A_JumpIfInventory("DERPUsable",0,"null")
		){
			HDF.Give(owner,"DERPUsable");
			int deplete=randompick(1,1,2);
			string msg="You manage to put together one (more) functioning D.E.R.P. robot";
			if(deplete>1)msg=msg.." from two broken ones.";
			else msg=msg..".";
			amount-=deplete;
			owner.A_Log(msg,true);
			if(amount<1)destroy();
		}
	}
}


//usable has separate actors to preserve my own sanity
class DERPUsable:HDPickup{
	int botid;
	default{
		//$Category "Items/Hideous Destructor"
		//$Title "D.E.R.P. Robot (Pickup)"
		//$Sprite "DERPA1"

		scale 0.6;
		inventory.icon "DERPEX";
		inventory.pickupmessage "Picked up a Defence, Engagement, Reconnaissance and Patrol robot.";
		inventory.pickupsound "derp/crawl";
		translation 0;
		hdpickup.bulk ENC_DERP;
		tag "D.E.R.P. robot";
		hdpickup.refid HDLD_DERPBOT;
	}
	override int getsbarnum(int flags){return botid;}
	override void beginplay(){
		super.beginplay();
		botid=1;
	}
	override void detachfromowner(){
		translation=owner.translation;
		super.detachfromowner();
	}
	states{
	use:
		TNT1 A 0{
			A_SetInventory("DERPDeployer",1);
			let ddp=DERPDeployer(findinventory("DERPDeployer"));
			ddp.weaponstatus[DERPS_MODESEL]=clamp(cvar.getcvar("hd_derpmode",player).getint(),1,3);
			A_SelectWeapon("DERPDeployer");
		}fail;
	spawn:
		DERP A -1;
		stop;
	}
}
class DERPDeployer:HDWeapon{
	default{
		+weapon.wimpy_weapon +weapon.no_auto_switch +weapon.cheatnotweapon
		+nointeraction
		hdweapon.barrelsize 0,0,0;
		weapon.selectionorder 1014;
	}
	override inventory createtossable(int amount){
		owner.a_dropinventory("DERPUsable",amount);
		return super.createtossable(amount);
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		int ofs=weaponstatus[DERPS_USEOFFS];
		if(ofs>90)return;
		let ddd=DERPUsable(owner.findinventory("DERPUsable"));
		if(!ddd||ddd.amount<1)return;
		let pmags=HD9mMag15(owner.findinventory("HD9mMag15"));

		vector2 bob=hpl.hudbob*0.2;
		bob.y+=ofs;
		sb.drawimage("DERPA8A2",(0,22)+bob,
			sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER|sb.DI_TRANSLATABLE,
			alpha:!!pmags?1.:0.6,scale:(2,2)
		);

		if(ofs>30)return;

		int mno=hdw.weaponstatus[DERPS_MODESEL];
		string mode;
		if(mno==DERP_TURRET)mode="\caTURRET";
		else if(mno==DERP_AMBUSH)mode="\ccAMBUSH";
		else if(mno==DERP_PATROL)mode="\cgPATROL";
		sb.drawstring(
			sb.psmallfont,mode,(0,34)+bob,
			sb.DI_TEXT_ALIGN_CENTER|sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
		);

		sb.drawstring(
			sb.psmallfont,"\cubotid \cy"..ddd.botid,(0,44)+bob,
			sb.DI_TEXT_ALIGN_CENTER|sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
		);
	}
	override string gethelptext(){
		return
		WEPHELP_FIRE.."  Deploy\n"
		..WEPHELP_UNLOAD.."  Deploy without ammo\n"
		..WEPHELP_ALTFIRE.."  Cycle modes\n"
		..WEPHELP_FIREMODE.."+"..WEPHELP_UPDOWN.."  Set BotID"
		;
	}
	action void A_AddOffset(int ofs){
		invoker.weaponstatus[DERPS_USEOFFS]+=ofs;
	}
	states{
	spawn:
		TNT1 A 0;
		stop;
	select:
		TNT1 A 0 A_AddOffset(100);
		TNT1 A 0 A_WeaponMessage("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nHold Firemode to change BotID.\nHit Altfire to toggle mode.\n\nPress Fire to deploy,\nUnload to deploy without ammo.",3500);
		goto super::select;
	ready:
		TNT1 A 1{
			if(!countinv("DERPUsable")){
				A_SelectWeapon("HDFist");
				A_WeaponReady(WRF_NOFIRE);
				return;
			}
			if(pressinguser3()){
				A_MagManager("HD9mMag15");
				return;
			}
			int iofs=invoker.weaponstatus[DERPS_USEOFFS];
			if(iofs>0)invoker.weaponstatus[DERPS_USEOFFS]=iofs*2/3;
			if(pressingfire()||pressingunload()){
				setweaponstate("deploy");
				return;
			}
			if(pressingfiremode()){
				hijackmouse();
				int ptch=player.cmd.pitch>>6;
				if(ptch){
					int newbotid=clamp(
						ptch+DERPUsable(findinventory("DERPUsable")).botid,0,63
					);
					DERPUsable(findinventory("DERPUsable")).botid=newbotid;
				}
			}
			if(justpressed(BT_ALTATTACK)){
				int mode=invoker.weaponstatus[DERPS_MODESEL];
				if(pressinguse())mode--;else mode++;
				if(mode<1)mode=3;
				else if(mode>3)mode=1;
				invoker.weaponstatus[DERPS_MODESEL]=mode;
				return;
			}
			A_WeaponReady(WRF_NOFIRE);
		}goto readyend;
	deploy:
		TNT1 AA 1 A_AddOffset(4);
		TNT1 AAAA 1 A_AddOffset(9);
		TNT1 AAAA 1 A_AddOffset(20);
		TNT1 A 0 A_JumpIf(!pressingfire()&&!pressingunload(),"ready");
		TNT1 A 4 A_PlaySound("weapons/pismagclick",CHAN_WEAPON);
		TNT1 A 2 A_PlaySound("derp/crawl",CHAN_WEAPON);
		TNT1 A 0{
			//in case someone drops all their shit mid-sequence
			if(
				!countinv("DERPUsable")
			){
				A_PlaySound("weapons/pismagclick",CHAN_WEAPON);
				A_WeaponMessage("No D.E.R.P.!",30);
				A_SelectWeapon("HDFist");
				return;
			}

			//stick it to a door
			if(pressingunload()&&pressingzoom()){
				int cid=countinv("DERPUsable");
				let hhh=hdhandlers(eventhandler.find("hdhandlers"));
				hhh.SetDERP(hdplayerpawn(self),555,DERPUsable(findinventory("DERPUsable")).botid,0);
				if(cid==countinv("DERPUsable")){
					setweaponstate("nope");
					return;
				}else{
					A_SelectWeapon("HDFist");
					return;
				}
			}

			//don't deploy unloaded unintentionally
			if(
				!pressingunload()
				&&HDMagAmmo.NothingLoaded(self,"HD9mMag15")
			){
				A_WeaponMessage("No mags!\n\n(use \cdUnload\cu to\ndeploy with no ammo.)",30);
				setweaponstate("nope");
				return;
			}

			actor a;int b;
			[b,a]=A_SpawnItemEx("DERPBot",12,0,height-12,
				cos(pitch)*6,0,-sin(pitch)*6,0,
				SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS|
				SXF_SETMASTER|SXF_TRANSFERTRANSLATION|SXF_SETTARGET
			);
			let derp=derpbot(a);
			derp.vel+=vel;
			derp.cmd=invoker.weaponstatus[DERPS_MODESEL];
			derp.botid=DERPUsable(findinventory("DERPUsable")).botid;

			let mmm=HDMagAmmo(findinventory("HD9mMag15"));
			if(mmm&&!pressingunload()){
				derp.ammo=mmm.TakeMag(true);
				A_PlaySound("weapons/pismagclick",CHAN_WEAPON);
			}else derp.ammo=-1;
			DERPController.GiveController(self);

			A_TakeInventory("DERPUsable",1);
		}
		TNT1 A 1 A_JumpIf(!pressingfire(),1);
		wait;
		TNT1 A 0 A_SelectWeapon("HDFist");
		TNT1 A 0 A_WeaponReady(WRF_NOFIRE);
		goto readyend;
	}
}
enum DERPDeployerNums{
	DERPS_MODESEL=1,
	DERPS_USEOFFS=2,
}


//evil roguebot
class EnemyDERP:DERPBot{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "D.E.R.P. Robot (Hostile)"
		//$Sprite "DERPA1"

		-friendly
		translation 1;
	}
}




extend class HDHandlers{
	void SetDERP(hdplayerpawn ppp,int cmd,int tag,int cmd2){
		if(cmd<0){
			let dpu=DERPUsable(ppp.findinventory("DERPUsable"));
			if(dpu){
				dpu.botid=-cmd;
				ppp.A_Log(string.format("\cd[DERP]  \cutag set to  \cy%i",-cmd),true);
			}
			return;
		}
		else if(cmd==1024){
			ppp.A_SetInventory("DERPController",1);
			ppp.UseInventory(ppp.findinventory("DERPController"));
			return;
		}
		else if(cmd==555){
			let dpu=DERPUsable(ppp.findinventory("DERPUsable"));
			if(!dpu)return;
			flinetracedata dlt;
			ppp.linetrace(
				ppp.angle,48,ppp.pitch,flags:TRF_THRUACTORS,
				offsetz:ppp.height-9,
				data:dlt
			);
			if(!dlt.hitline){
				ppp.A_Log(string.format("\cd[DERP]  \cuUse this command to attach the D.E.R.P. to a switch."),true);
				return;
			}
			let ddd=DERPBot(ppp.spawn("DERPBot",dlt.hitlocation-dlt.hitdir*4,ALLOW_REPLACE));
			if(!ddd){
				ppp.A_Log(string.format("\cd[DERP]  \cuCan't deploy here."),true);
				return;
			}
			if(tag)ddd.botid=abs(tag);else ddd.botid=dpu.botid;
			ppp.A_TakeInventory("DERPUsable",1);
			ddd.A_PlaySound("misc/bulletflesh",CHAN_BODY);
			ddd.stuckline=dlt.hitline;
			ddd.bnogravity=true;
			ddd.angle=ppp.angle-180;
			ddd.translation=ppp.translation;
			ddd.master=ppp;
			ddd.ammo=-1;
			if(!dlt.hitline.backsector){
				ddd.stuckheight=ddd.pos.z;
				ddd.stucktier=0;
			}else{
				sector othersector=hdmath.oppositesector(dlt.hitline,dlt.hitsector);
				ddd.stuckpoint=dlt.hitlocation.xy+dlt.hitdir.xy*4;
				double stuckceilingz=othersector.ceilingplane.zatpoint(ddd.stuckpoint);
				double stuckfloorz=othersector.floorplane.zatpoint(ddd.stuckpoint);
				ddd.stuckbacksector=othersector;
				double dpz=ddd.pos.z;
				if(dpz-ddd.height>stuckceilingz){
					ddd.stuckheight=dpz-ddd.height-stuckceilingz;
					ddd.stucktier=1;
				}else if(dpz<stuckfloorz){
					ddd.stuckheight=dpz-stuckfloorz;
					ddd.stucktier=-1;
				}else{
					ddd.stuckheight=ddd.pos.z;
					ddd.stucktier=0;
				}
			}
			DERPController.GiveController(ppp);
			return;
		}
		actoriterator it=level.createactoriterator(DERP_TID,"DERPBot");
		actor bot=null;
		int derps=0;
		bool badcommand=true;
		while(bot=it.Next()){
			let derp=DERPBot(bot);
			if(
				derp&&derp.master==ppp
				&&derp.health>0
				&&(!tag||tag==derp.botid)
			){
				bool goalset=false;
				if(cmd==6){
					badcommand=false;
					if(derp.cmd==DERP_AMBUSH)cmd=DERP_TURRET;
					else cmd=DERP_AMBUSH;
				}
				if(cmd&&cmd<4){
					badcommand=false;
					derp.cmd=cmd;
					derp.oldcmd=cmd;
					string mode;
					if(cmd==1){
						mode="aTURRET";
						derp.movestamina=1001;
					}
					else if(cmd==2){
						mode="cAMBUSH";
						derp.movestamina=1001;
					}
					else if(cmd==3){
						mode="gPATROL";
						derp.movestamina=0;
					}
					ppp.A_Log(string.format("\cd[DERP]  \c%s  \cjmode",mode),true);
				}else if(cmd==4){
					badcommand=false;
					goalset=true;
					derp.goalpoint=ppp.pos.xy;
					ppp.A_Log("\cd[DERP]  \cugoal set to  \cyYOUR POSITION",true);
				}else if(cmd==5){
					badcommand=false;
					flinetracedata derpgoal;
					ppp.linetrace(
						ppp.angle,2048,ppp.pitch,
						TRF_NOSKY,
						offsetz:ppp.height-6,
						data:derpgoal
					);
					if(derpgoal.hittype!=Trace_HitNone){
						goalset=true;
						derp.goalpoint=derpgoal.hitlocation.xy;
						ppp.A_Log(string.format("\cd[DERP]  \cugoal set to  \cx[%i,%i]",derpgoal.hitlocation.x,derpgoal.hitlocation.y),true);
					}
				}else if(cmd>800&&cmd<810){
					badcommand=false;
					vector2 which;
					switch(cmd-800){
						case 1:which=(-1,-1);break;
						case 2:which=(0,-1);break;
						case 3:which=(1,-1);break;
						case 4:which=(-1,0);break;
						case 6:which=(1,0);break;
						case 7:which=(-1,1);break;
						case 8:which=(0,1);break;
						case 9:which=(1,1);break;
						default:return;break;
					}
					if(goalset)derp.goalpoint=derp.goalpoint+which*64;
					else derp.goalpoint=derp.pos.xy+which*64;
					goalset=true;
					ppp.A_Log(string.format("\cd[DERP]  \cugoal set to  \cx[%i,%i]",derp.goalpoint.x,derp.goalpoint.y),true);
				}else if(
					cmd==556&&derp.stuckline
				){
					badcommand=false;
					derp.setstatelabel("unstuck");
				}else if(cmd==123){
					badcommand=false;
					int ammo=derp.ammo;
					ppp.A_Log(string.format("\cd[DERP] \cjtag #\cx%i \cjreporting in at [\cx%i\cj,\cx%i\cj] with %s",derp.botid,derp.pos.x,derp.pos.y,ammo>0?string.format("\cy%i\cj bullets left!",derp.ammo):"\crno ammo left!\cj Help!"),true);
				}
				if(goalset){
					derp.movestamina=20-(level.vec2diff(derp.pos.xy,derp.goalpoint)).length()/derp.speed;
					derp.goalangle=derp.angletogoal();
					derp.setstatelabel("turn");
				}
			}
		}
		if(badcommand){
			let dpu=DERPUsable(ppp.findinventory("DERPUsable"));
			ppp.A_Print(string.format("\cd[DERP]\cj List of available commands:
\n             derpt    \cjturret mode  (1)
\n             derpa    \cjambush mode  (2)
\n             derpp    \cjpatrol mode  (3)
\n             derpcome \cjcome to user (4)
\n             derpgo   \cjgo to point  (5)
\n             derpat   \cjtoggle 1/2   (6)
\n             derpmv*   \cjadvance in direction (n/s/ne/sw/etc.)  (5)
\n             derptag  \cjset tag #   (-x)
\n \cu(all of these can be shortened\n\cuwith \"d\" instead of \"derp\")
\n\n \cuType \cdderp 123\cu to poll deployed DERPs.
\n \cuCurrent tag is \cx%i.
			",dpu?dpu.botid:1),9);
		}
	}
}







class DERPController:HDWeapon{
	default{
		+inventory.invbar
		+weapon.wimpy_weapon
		+nointeraction
		+hdweapon.droptranslation
		inventory.icon "DERPA5";
		weapon.selectionorder 1012;
	}
	array<derpbot> derps;
	action derpbot A_UpdateDerps(bool resetindex=true){
		return invoker.UpdateDerps(resetindex);
	}
	derpbot UpdateDerps(bool resetindex=true){
		derps.clear();
		if(!owner)return null;
		ThinkerIterator derpfinder=thinkerIterator.Create("DERPBot");
		derpbot mo;
		while(mo=DERPBot(derpfinder.Next())){
			if(
				mo.master==owner
				&&mo.distance3d(owner)<frandom(1024,2048)
			)derps.push(mo);
		}
		if(resetindex)weaponstatus[DERPS_INDEX]=0;
		if(!derps.size())return null;
		derpbot ddd=derps[0];
		ddd.oldcmd=ddd.cmd;
		return ddd;
	}
	static void GiveController(actor caller){
		caller.A_SetInventory("DERPController",1);
		caller.findinventory("DERPController").binvbar=true;
		let ddc=DERPController(caller.findinventory("DERPController"));
		ddc.updatederps(false);
		if(!ddc.derps.size())caller.dropinventory(ddc);
	}
	int NextDerp(){
		int newindex=weaponstatus[DERPS_INDEX]+1;
		if(newindex>=derps.size())newindex=0;
		if(weaponstatus[DERPS_INDEX]!=newindex){
			owner.A_Log("Switching to next D.E.R.P. in the list.",true);
			weaponstatus[DERPS_INDEX]=newindex;
		}
		return newindex;
	}
	action void Abort(){
		A_Log("No D.E.R.P.s deployed. Abort.",true);
		A_SelectWeapon("HDFist");
		setweaponstate("nope");
		dropinventory(invoker);
	}
	override inventory CreateTossable(int amount){
		if(
			(derps.size()&&derps[NextDerp()])
			||updatederps(false)
		)return null;
		return weapon.createtossable(amount);
	}
	override string gethelptext(){
		return
		WEPHELP_FIREMODE.."  Hold to pilot\n"
		..WEPHELP_FIRESHOOT
		..WEPHELP_ALTFIRE.."  Forwards\n"
		..WEPHELP_USE.."  Backwards\n"
		..WEPHELP_RELOAD.."  Cycle through modes\n"
		..WEPHELP_UNLOAD.."  Jump to Passive mode\n"
		..WEPHELP_DROP.."  Next D.E.R.P."
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc,string whichdot
	){
		if(
			!derps.size()
			||weaponstatus[DERPS_INDEX]>=derps.size()
		)return;
		let derpcam=derps[weaponstatus[DERPS_INDEX]];
		if(!derpcam)return;

		bool dead=(derpcam.health<1);
		int scaledyoffset=66;
		texman.setcameratotexture(derpcam,"HDXHCAM1",60);
		sb.drawimage(
			"HDXHCAM1",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
			alpha:dead?frandom[derpyderp](0.6,0.9):1.,scale:(1,1)
		);
		sb.drawimage(
			"tbwindow",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
			scale:(1,1)
		);
		if(!dead)sb.drawimage(
			"redpxl",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.4,scale:(2,2)
		);
		sb.drawnum(dead?0:max(0,derpcam.ammo),
			24+bob.x,42+bob.y,sb.DI_SCREEN_CENTER,Font.CR_RED,0.4
		);
		int cmd=dead?0:derpcam.oldcmd;
		sb.drawnum(cmd,
			24+bob.x,52+bob.y,sb.DI_SCREEN_CENTER,cmd==3?Font.CR_BRICK:cmd==1?Font.CR_GOLD:Font.CR_LIGHTBLUE,0.4
		);
	}
	states{
	select:
		TNT1 A 10{
			invoker.weaponstatus[DERPS_TIMER]=3;
			if(!getcvar("hd_helptext"))return;
			A_WeaponMessage("\cf/// \cdD.E.R.P. \cf\\\\\\\c-\n\n\nDrop cycles through D.E.R.P.s, Reload modes.\n\nHold Firemode to control.\nFire shoot, Altfire forward, Use backward.\n\n\nAlt. Reload to re-ping all deployed D.E.R.P.s",175);
		}
		goto super::select;
	ready:
		TNT1 A 1{
			if(!invoker.derps.size()||invoker.weaponstatus[DERPS_INDEX]>=invoker.derps.size()
				||justpressed(BT_USER1)
			){
				a_updatederps();
				if(!invoker.derps.size()){
					Abort();
				}
				return;
			}
			A_WeaponReady(WRF_NOFIRE|WRF_ALLOWUSER3);
			derpbot ddd=invoker.derps[invoker.weaponstatus[DERPS_INDEX]];
			if(!ddd){
				if(ddd=a_updatederps())A_Log("D.E.R.P. not found. Resetting list.",true);
				else{
					Abort();
				}
				return;
			}

			int bt=player.cmd.buttons;

			if(
				ddd.health<1
				||(
					bt
					&&!invoker.weaponstatus[DERPS_TIMER]
					&&ddd.distance3d(self)>frandom(1024,2048)
				)
			){
				A_Log("CONNECTION FAILURE, REBOOT REQUIRED!: D.E.R.P. last position given at ("..int(ddd.pos.x)+random(-100,100)..","..int(ddd.pos.y)+random(-100,100)..")",true);
				ddd.cmd=ddd.oldcmd;
				invoker.derps.delete(invoker.weaponstatus[DERPS_INDEX]);
				if(!invoker.derps.size())A_SelectWeapon("HDFist");
				return;
			}

			int cmd=ddd.oldcmd;
			bool moved=false;

			if(justpressed(BT_UNLOAD)){
				cmd=2;
				A_Log("Ambush mode.",true);
			}else if(justpressed(BT_RELOAD)){
				cmd++;
				if(cmd>3)cmd=1;
				if(cmd==DERP_AMBUSH)A_Log("Ambush mode.",true);
				else if(cmd==DERP_TURRET)A_Log("Turret mode.",true);
				else if(cmd==DERP_PATROL)A_Log("Patrol mode.",true);
			}

			ddd.oldcmd=cmd;
			if(bt&BT_FIREMODE){
				ddd.cmd=DERP_AMBUSH;
				if(!invoker.weaponstatus[DERPS_TIMER]){
					if(
						justpressed(BT_ATTACK)
					){
						invoker.weaponstatus[DERPS_TIMER]+=4;
						if(ddd.ammo>0){
							ddd.setstatelabel("noreallyfire");
							ddd.tics=2; //for some reason a 1-tic firing frame won't show
						}else ddd.setstatelabel("noammo");
						return;
					}else if(
						(
							player.cmd.forwardmove
							||(bt&BT_ALTATTACK)
							||(bt&BT_USE)
						)
						&&!invoker.weaponstatus[DERPS_TIMER]
					){
						invoker.weaponstatus[DERPS_TIMER]+=2;
						ddd.A_DerpCrawlSound();
						vector2 nv2=(cos(ddd.angle),sin(ddd.angle))*ddd.speed;
						if(bt&BT_USE||player.cmd.forwardmove<0)nv2*=-1;
						if(ddd.floorz>=ddd.pos.z)ddd.TryMove(ddd.pos.xy+nv2,true);
						moved=true;
					}
				}
				int yaw=player.cmd.yaw>>6;
				int ptch=player.cmd.pitch>>6;
				if(yaw||ptch){
					ddd.A_DerpCrawlSound(150);
					ddd.pitch=clamp(ddd.pitch-clamp(ptch,-10,10),-90,60);
					ddd.angle+=clamp(yaw,-DERP_MAXTICTURN,DERP_MAXTICTURN);
					ddd.goalangle=999;
					ddd.movestamina=1001;
					if(yaw)moved=true;
				}
				if(player.cmd.sidemove){
					ddd.A_PlaySound("derp/crawl",CHAN_BODY);
					ddd.A_DerpCrawlSound(150);
					ddd.angle+=player.cmd.sidemove<0?10:-10;
					player.cmd.sidemove*=-1;
				}
				hijackmouse();
				hijackmove();
			}else{
				ddd.cmd=cmd;
				if(cmd==DERP_PATROL&&ddd.movestamina>=1000)ddd.movestamina=0;
			}

			if(moved&&!!ddd.stuckline){
				ddd.setstatelabel("unstuck");
			}

			if(!invoker.bweaponbusy&&hdplayerpawn(self))hdplayerpawn(self).nocrosshair=0;
			if(invoker.weaponstatus[DERPS_TIMER]>0)invoker.weaponstatus[DERPS_TIMER]--;
		}goto readyend;
	user3:
		---- A 0 A_MagManager("HD9mMag15");
		goto ready;
	spawn:
		TNT1 A 0;
		stop;
	}
}
enum DERPControllerNums{
	DERPS_INDEX=1,
	DERPS_AMMO=2,
	DERPS_MODE=3,
	DERPS_TIMER=4,
}



