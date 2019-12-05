// ------------------------------------------------------------
// H.E.R.P. Robot
// ------------------------------------------------------------
enum HERPConst{
	HERP_TID=851816,
}
class HERPLeg:Actor{
	default{
		+flatsprite +nointeraction +noblockmap
	}
	vector3 relpos;
	double oldfloorz;
	override void Tick(){
		if(!master){destroy();return;}
		binvisible=oldfloorz!=floorz;
		setorigin(master.pos+relpos,true);
		oldfloorz=floorz;
	}
	states{
	spawn:
		HLEG A -1;
		stop;
	}
}
class HERPBot:HDUPK{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "H.E.R.P. Robot"
		//$Sprite "HERPA1"

		+ismonster +noblockmonst +friendly +standstill +nofear
		+shootable +ghost +noblood +dontgib
		+missilemore //on/off
		height 9;radius 7;mass 400;health 200;
		damagefactor "Thermal",0.7;damagefactor "SmallArms3",0.8;
		obituary "%o went HERP.";
		hdupk.pickupmessage ""; //just use the spawned one
		hdupk.pickupsound "";
		scale 0.8;
	}

	//it is now canon: the mag and seal checkers are built inextricably into the AI.
	//if you tried to use a jailbroken mag, the whole robot just segfaults.
	int ammo[3]; //the mag being used: -1-51, -1 no mag, 0 empty, 51 sealed, >100  dirty
	int battery; //the battery, -1-20
	double startangle;
	bool scanright;
	int botid;

	override bool cancollidewith(actor other,bool passive){return other.bmissile||HDPickerUpper(other);}
	override void ongrab(actor other){
		if(ishostile(other)){
			bmissilemore=false;
			setstatelabel("off");
		}
	}
	override void Die(actor source,actor inflictor,int dmgflags){
		super.Die(source,inflictor,dmgflags);
		if(self)bsolid=true;
	}
	override void Tick(){
		if(
			pos.z+vel.z<floorz+12
		){
			vel.z=0;
			setz(floorz+12);
			bnogravity=true;
		}else bnogravity=pos.z-floorz<=12;
		if(bnogravity)vel.xy*=getfriction();
		super.tick();
	}
	override void postbeginplay(){
		super.postbeginplay();
		startangle=angle;
		scanright=false;
		if(!master){
			ammo[0]=51;
			ammo[1]=51;
			ammo[2]=51;
			battery=20;
		}
		bool gbg;actor lll;
		[gbg,lll]=A_SpawnItemEx(
			"HERPLeg",xofs:-7,zofs:-12,
			angle:0,
			flags:SXF_NOCHECKPOSITION|SXF_SETMASTER
		);
		HERPLeg(lll).relpos=lll.pos-pos;
		lll.pitch=-60;
		[gbg,lll]=A_SpawnItemEx(
			"HERPLeg",xofs:-7,zofs:-12,
			angle:-120,
			flags:SXF_NOCHECKPOSITION|SXF_SETMASTER
		);
		HERPLeg(lll).relpos=lll.pos-pos;
		lll.pitch=-60;
		[gbg,lll]=A_SpawnItemEx(
			"HERPLeg",xofs:-7,zofs:-12,
			angle:120,
			flags:SXF_NOCHECKPOSITION|SXF_SETMASTER
		);
		HERPLeg(lll).relpos=lll.pos-pos;
		lll.pitch=-60;
	}
	void herpbeep(string snd="herp/beep",double vol=1.){
		A_PlaySound(snd,CHAN_VOICE);
		if(
			master
			&&master.player
			&&master.player.readyweapon is "HERPController"
		)master.A_PlaySound(snd,CHAN_WEAPON,0.4);
	}
	void message(string msg){
		if(!master)return;
		master.A_Log(string.format("\cd[HERP]\cj  %s",msg),true);
	}
	void scanturn(){
		if(battery<1){
			message("Operational fault. Please check your manual for proper maintenance. (ERR-4fd92-00B) Power low.");
			setstatelabel("nopower");
			return;
		}
		if(health<1){
			A_Die();
			setstatelabel("death");
			return;
		}
		if(!bmissilemore){
			setstatelabel("off");
			return;
		}
		if(bmissileevenmore){
			setstatelabel("inputready");
			return;
		}
		if(!random(0,8192))battery--;
		A_ClearTarget();

		//shoot 5 lines for at least some z-axis awareness
		actor a;int b;int c=-2;
		while(
			c<=1
		){
			c++;
			//shoot a line out
			flinetracedata hlt;
			linetrace(
				angle,4096,c,
				flags:TRF_NOSKY,
				offsetz:9.5,
				data:hlt
			);

			if(!c&&hlt.hittype!=Trace_HitNone)a_spawnparticle(
				"red",SPF_FULLBRIGHT,lifetime:2,size:2,0,
				hlt.hitlocation.x-pos.x,
				hlt.hitlocation.y-pos.y,
				hlt.hitlocation.z-pos.z
			);

			//if the line hits a valid target, go into shooting state
			actor hitactor=hlt.hitactor;
			if(
				hitactor
				&&isHostile(hitactor)
				&&hitactor.bshootable
				&&!hitactor.bnotarget
				&&!hitactor.bnevertarget
				&&(hitactor.bismonster||hitactor.player)
				&&(!hitactor.player||!(hitactor.player.cheats&CF_NOTARGET))
				&&hitactor.health>random(random(0,99)?0:-2,20)
			){
				target=hitactor;
				setstatelabel("ready");
				message("IFF system alert: enemy pattern recognized.");
				if(hd_debug)A_Log(string.format("HERP targeted %s",hitactor.getclassname()));
				return;
			}
		}

		//if nothing, keep moving (add angle depending on scanright)
		angle+=scanright?-3:3;

		//if anglechange is too far, start moving the other way
		double chg=deltaangle(angle,startangle);
		if(abs(chg)>35){
			if(chg<0)scanright=true;
			else scanright=false;
			setstatelabel("postbeep");
		}
	}
	actor A_SpawnPickup(){
		let hu=HERPUsable(spawn("HERPUsable",pos,ALLOW_REPLACE));
		if(hu){
			hu.translation=translation;
			if(health<1)hu.weaponstatus[0]|=HERPF_BROKEN;
			hu.weaponstatus[1]=ammo[0];
			hu.weaponstatus[2]=ammo[1];
			hu.weaponstatus[3]=ammo[2];
			hu.weaponstatus[4]=battery;
		}
		destroy();
		return hu;
	}

	states{
	spawn:
		HERP A 0;
	spawn2:
		HERP A 0 A_JumpIfHealthLower(1,"dead");
		HERP A 10 A_ClearTarget();
	idle:
		HERP A 2 scanturn();
		wait;
	postbeep:
		HERP A 6 herpbeep("herp/beep");
		goto idle;


	inputwaiting:
		HERP A 4;
		HERP A 0{
			if(!master){
				setstatelabel("spawn");
				return;
			}
			herpbeep("herp/beep");
			message("Establishing connection...");
			A_SetTics(random(10,min(350,0.3*distance3d(master))));
		}
		HERP A 20{
			if(master){
				bmissileevenmore=true;
				herpbeep("herp/beepready");
				message("Connected!");
			}else{
				setstatelabel("inputabort");
				return;
			}
		}
	inputready:
		HERP A 1 A_JumpIf(
			!master
			||!master.player
			||!(master.player.readyweapon is "HERPController")
		,"inputabort");
		wait;
	inputabort:
		HERP A 4{bmissileevenmore=false;}
		HERP A 2 herpbeep("herp/beepready");
		HERP A 20 message("Disconnected.");
		goto spawn;


	ready:
		HERP A 7 A_PlaySound("weapons/vulcanup",CHAN_BODY);
		HERP AAA 1 herpbeep("herp/beepready");
	aim:
		HERP A 2 A_FaceTarget(2.,2.,0,0,FAF_TOP,-4);
	shoot:
		HERP B 2 bright light("SHOT"){
			int currammo=ammo[0];
			if(
				(
					currammo<1
					&&ammo[1]<1
					&&ammo[2]<1
				)||(currammo>100&&!random(0,7))
			){
				message("Operational fault. Please check your manual for proper maintenance. (ERR-42392-41A) Cartridge empty. Shutting down...");
				if(currammo>100&&!random(0,3))ammo[0]--;
				setstatelabel("off");
				return;
			}
			if(currammo<1&&ammo[1]>0){
				setstatelabel("swapmag");
				return;
			}

			//deplete 1 round
			if(currammo>100){
				//"100" is an empty mag so set it to empty
				if(currammo==101)ammo[0]=0;
				else ammo[0]--;
			}else if(currammo>50){
				//51-99 = sealed mag, break seal and deplete one = 49
				ammo[0]=49;
			}else ammo[0]--;

			A_PlaySound("weapons/rifle",CHAN_WEAPON);
			HDBulletActor.FireBullet(self,"HDB_426",zofs:6,spread:1);
		}
		HERP C 2{
			angle-=frandom(0.4,1.);
			pitch-=frandom(0.8,1.3);
			if(bfriendly)A_AlertMonsters(0,AMF_TARGETEMITTER);
			else A_AlertMonsters();
		}
		HERP A 0{
			if(ammo[0]<1){
				setstatelabel("swapmag");
			}else if(target && target.health>random(-30,30)){
				flinetracedata herpline;
				linetrace(
					angle,4096,pitch,
					offsetz:12,
					data:herpline
				);
				if(herpline.hitactor!=target){
					if(checksight(target))setstatelabel("aim");
					else target=null;
				}else setstatelabel("shoot");
			}
		}goto idle;
	swapmag:
		HERP A 3{
			int nextmag=ammo[1];
			if(
				nextmag<1
				||nextmag==100
				||(nextmag>100&&!random(0,3))
			){
				message("Operational fault. Please check your manual for proper maintenance. (ERR-42392-41A) Cartridge empty. Shutting down...");
				A_PlaySound("weapons/vulcandown");
				setstatelabel("off");
			}else{
				int currammo=ammo[0];
				if(currammo>=0){
					let mmm=hd4mmag(spawn("hd4mmag",(pos.xy,pos.z-6)));
					mmm.mags.clear();mmm.mags.push(max(0,currammo));
					double angloff=angle+100;
					mmm.vel=(cos(angloff),sin(angloff),1)*frandom(0.7,1.3)+vel;
				}
				ammo[0]=ammo[1];
				ammo[1]=ammo[2];
				ammo[2]=-1;
			}
		}goto idle;
	nopower:
		HERP A -1;
	off:
		HERP A 10{
			if(health>0){
				double turn=clamp(deltaangle(angle,startangle),-24,24);
				if(turn){
					A_PlaySound("herp/crawl",CHAN_BODY,0.6);
					angle+=turn;
					A_SetTics(5);
				}
			}
		}
		HERP A 0{
			if(
				!bmissilemore
				||absangle(angle,startangle)>12
				||(
					ammo[0]%100<1
					&&ammo[1]%100<1
					&&ammo[2]%100<1
				)
			)setstatelabel("off");
		}goto idle;
	give:
		---- A 0{
			let hu=A_SpawnPickup();
			if(hu){
				hu.translation=self.translation;
				grabthinker.grab(target,hu);
			}
			let ctr=HERPController(target.findinventory("HERPController"));
			if(ctr)ctr.UpdateHerps(false);
		}stop;
	death:
		HERP A 0{
			if(ammo[0]>=0)ammo[0]=random(0,ammo[0]+randompick(0,0,0,100));
			if(ammo[1]>=0)ammo[1]=random(0,ammo[1]+randompick(0,0,0,100));
			if(ammo[2]>=0)ammo[2]=random(0,ammo[2]+randompick(0,0,0,100));
			battery=min(battery,random(-1,20));
			if(battery<0){
				A_GiveInventory("Heat",1000);
				ammo[0]=min(ammo[0],0);
				ammo[1]=min(ammo[1],0);
				ammo[2]=min(ammo[2],0);
			}
			A_NoBlocking();
			A_PlaySound("world/shotgunfar",CHAN_BODY,0.4);
		}
		HERP A 1 A_PlaySound("weapons/bigcrack",5);
		HERP A 1 A_PlaySound("weapons/bigcrack",6);
		HERP A 1 A_PlaySound("weapons/bigcrack",7);
		HERP AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 A_SpawnItemEx("HugeWallChunk",random(-6,6),random(-6,6),random(0,6), vel.x+random(-6,6),vel.y+random(-6,6),vel.z+random(1,8),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		HERP A 0{
			A_PlaySound("weapons/vulcandown",CHAN_WEAPON);
			string yay="";
			switch(random(0,8)){
			case 0:
				yay="Operational fault. Please check your manual for proper maintenance. (ERR-4fd92-00B) Power low.";break;
			case 1:
				yay="Operational fault. Please check your manual for proper maintenance. (ERR-74x29-58A) Unsupported ammunition type.\n\n\cjPlease note: Reloading a 4.26 UAC Standard magazine or its components without the supervision of a Volt UAC Standard Certified Cartridge Professional(tm) is a breach of the Volt End User License Agreement.";break;
			case 2:
				yay="Operational fault. Please check your manual for proper maintenance. (ERR-8w8i7-8VX) No interface detected.";break;
			case 3:
				yay="Illegal operation. Please check your manual for proper maintenance. (ERR-u0H85-6NN) System will restart.";break;
			case 4:
				yay="Illegal operation. Identify Friend/Foe system has been tampered with. Please contact your commanding officer immediately. (ERR-0023j-000) System will halt.";break;
			case 5:
				yay="Formatting C:\\ (DBG-444j2-0A0)";break;
			case 6:
				yay="Testing mode initialized.  (DBG-86nm8-BN5) Cache cleared.";break;
			case 7:
				yay="*** Fatal Error *** Address not mapped to object (signal 11) Address: 0x8";break;
			case 8:
				yay="*** Fatal Error *** Segmentation fault (signal 11) Address: (nil)";break;
			}
			if(!random(0,3))yay="\cg"..yay;
			message(yay);
		}
		HERP AAA 1 A_SpawnItemEx("HDSmoke",random(-2,2),random(-2,2),random(-2,2), vel.x+random(-2,2),vel.y+random(-2,2),vel.z+random(1,4),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		HERP AAA 3 A_SpawnItemEx("HDSmoke",random(-2,2),random(-2,2),random(-2,2), vel.x+random(-2,2),vel.y+random(-2,2),vel.z+random(1,4),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		HERP AAA 9 A_SpawnItemEx("HDSmoke",random(-2,2),random(-2,2),random(-2,2), vel.x+random(-2,2),vel.y+random(-2,2),vel.z+random(1,4),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
	dead:
		HERP A -1 A_SpawnPickup();
		stop;
	}
}
class EnemyHERP:HERPBot{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "H.E.R.P. Robot (Hostile)"
		//$Sprite "HERPA1"

		-friendly
		translation "112:120=152:159","121:127=9:12";
	}
}
class BrokenHERP:HERPBot{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "H.E.R.P. Robot (Broken)"
		//$Sprite "HERPA1"
		translation "112:120=152:159","121:127=9:12";
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
	}
	states{
	spawn:
		HERP A -1;
		stop;
	death.spawndead:
		HERP A -1{
			ammo[0]=random(0,ammo[0]+randompick(0,0,0,100));
			ammo[1]=random(0,ammo[1]+randompick(0,0,0,100));
			ammo[2]=random(0,ammo[2]+randompick(0,0,0,100));
			battery=min(battery,random(-1,20));
			if(battery<0){
				ammo[0]=0;ammo[1]=0;ammo[2]=0;
			}
			A_NoBlocking();
			A_SpawnPickup();
		}stop;
	}
}
class HERPUsable:HDWeapon{
	default{
		//$Category "Items/Hideous Destructor"
		//$Title "H.E.R.P. Robot (Pickup)"
		//$Sprite "HERPA1"

		+weapon.wimpy_weapon
		+inventory.invbar
		+hdweapon.droptranslation
		+hdweapon.fitsinbackpack
		inventory.amount 1;
		inventory.maxamount 1;
		inventory.icon "HERPEX";
		inventory.pickupsound "misc/w_pkup";
		inventory.pickupmessage "Picked up a Heavy Engagement Rotary Platform robot.";
		tag "H.E.R.P. robot";
		hdweapon.refid HDLD_HERPBOT;
		weapon.selectionorder 1015;
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override double gunmass(){
		double amt=9+weaponstatus[HERP_BATTERY]<0?0:1;
		if(weaponstatus[1]>=0)amt+=3.6;
		if(weaponstatus[2]>=0)amt+=3.6;
		if(weaponstatus[3]>=0)amt+=3.6;
		if(owner&&owner.player.cmd.buttons&BT_ZOOM)amt*=frandom(3,4);
		return amt;
	}
	override double weaponbulk(){
		double enc=ENC_HERP;
		for(int i=1;i<4;i++){
			if(weaponstatus[i]>=0)enc+=max(ENC_426MAG*0.2,weaponstatus[i]*ENC_426*0.8);
		}
		if(owner&&owner.player.cmd.buttons&BT_ZOOM)enc*=2;
		return enc;
	}
	override int getsbarnum(int flags){return weaponstatus[HERP_BOTID];}
	override void InitializeWepStats(bool idfa){
		weaponstatus[HERP_BATTERY]=20;
		weaponstatus[1]=51;
		weaponstatus[2]=51;
		weaponstatus[3]=51;
	}
	action void A_ResetBarrelSize(){
		invoker.weaponstatus[HERP_YOFS]=100;
		invoker.barrellength=0;
		invoker.barrelwidth=0;
		invoker.barreldepth=0;
		invoker.bobspeed=2.4;
		invoker.bobrangex=0.2;
		invoker.bobrangey=0.8;
	}
	action void A_RaiseBarrelSize(){
		invoker.barrellength=25;
		invoker.barrelwidth=3;
		invoker.barreldepth=3;
		invoker.bobrangex=8.2;
		invoker.bobrangey=4.6;
		invoker.bobspeed=2.8;
	}
	states{
	select:
		TNT1 A 0 A_ResetBarrelSize();
		TNT1 A 0 A_WeaponMessage("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nHold \cdUse\cu while hitting \cdAlt. Reload\nto unload battery.\n\nHold \cdUse\cu while hitting \cdUnload\nto remove partially-spent mags.\n\nHold \cdFiremode\cu to change BotID, \cdAltfire\cu to toggle on/off.\n\nPress \cdFire\cu to deploy.",3500);
		goto super::select;
	ready:
		TNT1 A 0 A_JumpIf(pressingzoom(),"raisetofire");
		TNT1 A 1 A_HERPWeaponReady();
		goto readyend;
	user3:
		TNT1 A 0 A_MagManager("HD4mMag");
		TNT1 A 1 A_WeaponReady(WRF_NOFIRE);
		goto nope;

	unload:
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[1]<0
			&&invoker.weaponstatus[2]<0
			&&invoker.weaponstatus[3]<0,"altunload");
		TNT1 A 0{invoker.weaponstatus[0]|=HERPF_UNLOADONLY;}
		//fallthrough to unloadmag
	unloadmag:
		TNT1 A 14;
		TNT1 A 5 A_UnloadMag();
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&HERPF_UNLOADONLY,"reloadend");
		goto reloadend;
	reload:
		TNT1 A 0 A_JumpIf(HD4mMag.NothingLoaded(self,"HD4mMag"),"nope");
		TNT1 A 14 A_PlaySound("weapons/pocket",CHAN_WEAPON);
		TNT1 A 5 A_LoadMag();
		goto reloadend;

	altreload:
		TNT1 A 0 A_JumpIf(pressinguse()||pressingzoom(),"altunload");
		TNT1 A 0{
			if(HDBattery.NothingLoaded(self,"HDBattery"))setweaponstate("nope");
			else invoker.weaponstatus[0]&=~HERPF_UNLOADONLY;
		}goto unloadbattery;
	altunload:
		TNT1 A 0{invoker.weaponstatus[0]|=HERPF_UNLOADONLY;}
		//fallthrough to unloadbattery
	unloadbattery:
		TNT1 A 20;
		TNT1 A 5 A_UnloadBattery();
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&HERPF_UNLOADONLY,"reloadend");
	reloadbattery:
		TNT1 A 14 A_PlaySound("weapons/pocket",CHAN_WEAPON);
		TNT1 A 5 A_LoadBattery();
	reloadend:
		TNT1 A 6;
		goto ready;
	spawn:
		HERP A -1;
		stop;

	//for manual carry-firing
	raisetofire:
		TNT1 A 8 A_PlaySound("herp/crawl",CHAN_WEAPON,1.);
		HERG A 1 offset(0,80) A_PlaySound("herp/beepready",CHAN_WEAPON);
		HERG A 1 offset(0,60) A_WeaponMessage("");
		HERG A 1 offset(0,50) A_RaiseBarrelSize();
		HERG A 1 offset(0,40);
		HERG A 1 offset(0,34);
	readytofire:
		HERG A 1{
			if(pressingzoom()){
				if(pressingfire())setweaponstate("directfire");
				if(pitch<10&&!gunbraced())A_MuzzleClimb(frandom(-0.1,0.1),frandom(0.,0.1));
			}else{
				setweaponstate("lowerfromfire");
			}
		}
		HERG A 0 A_ReadyEnd();
		loop;
	directfire:
		HERG A 2{
			if(invoker.weaponstatus[HERP_BATTERY]<1){
				setweaponstate("directfail");
				return;
			}
			int currammo=invoker.weaponstatus[1];

			//check ammo and cycle mag if necessary
			if(
				!currammo
				||currammo>100
			){
				let mmm=hd4mmag(spawn("hd4mmag",(pos.xy,pos.z+height-20)));
				mmm.mags.clear();mmm.mags.push(max(0,currammo));
				double angloff=angle+100;
				mmm.vel=(cos(angloff),sin(angloff),1)*frandom(0.7,1.3)+vel;
				invoker.weaponstatus[1]=-1;
			}
			if(
				invoker.weaponstatus[1]<0
			){
				invoker.weaponstatus[1]=invoker.weaponstatus[2];
				invoker.weaponstatus[2]=invoker.weaponstatus[3];
				invoker.weaponstatus[3]=-1;

				int curmag=invoker.weaponstatus[1];
				if(
					curmag>0
					&&curmag<51
					&&!random(0,15)
				)invoker.weaponstatus[1]+=100;

				return;
			}

			//deplete ammo and fire
			if(invoker.weaponstatus[1]==51)invoker.weaponstatus[1]=49;
			else invoker.weaponstatus[1]--;				
			A_Overlay(PSP_FLASH,"directflash");
		}
		HERG B 2;
		HERG A 0 A_JumpIf(!pressingzoom(),"lowerfromfire");
		HERG A 0 A_Refire("directfire");
		goto readytofire;
	directflash:
		HERF A 1 bright{
			HDFlashAlpha(-16);
			HDBulletActor.FireBullet(
				self,"HDB_426",zofs:height-12,
				spread:1
			);
			A_PlaySound("weapons/rifle",CHAN_WEAPON);
			A_ZoomRecoil(max(0.95,1.-0.05*min(invoker.weaponstatus[ZM66S_AUTO],3)));
			A_MuzzleClimb(
				frandom(-0.2,0.2),frandom(-0.4,0.2),
				frandom(-0.4,0.4),frandom(-0.6,0.4),
				frandom(-0.4,0.4),frandom(-1.,0.6),
				frandom(-0.8,0.8),frandom(-1.6,0.8)
			);
		}stop;
	directfail:
		HERG # 1 A_WeaponReady(WRF_NONE);
		HERG # 0 A_JumpIf(pressingfire(),"directfail");
		goto readytofire;
	lowerfromfire:
		HERG A 1 offset(0,34) A_ClearRefire();
		HERG A 1 offset(0,40) A_PlaySound("herp/beepready",CHAN_WEAPON);
		HERG A 1 offset(0,50);
		HERG A 1 offset(0,60);
		HERG A 1 offset(0,80)A_ResetBarrelSize();
		TNT1 A 1 A_PlaySound("herp/crawl",CHAN_WEAPON,1.);
		TNT1 A 1 A_JumpIf(pressingfire()||pressingaltfire(),"nope");
		goto select;
	}
	action void Message(string msg){
		A_Log("\cd[HERP]\cj  "..msg,true);
	}
	action void A_LoadMag(){
		let magg=HD4mMag(findinventory("HD4mMag"));
		if(!magg)return;
		for(int i=1;i<4;i++){
			if(invoker.weaponstatus[i]<0){
				int toload=magg.takemag(true);
				invoker.weaponstatus[i]=toload;
				break;
			}
		}
	}
	action void A_UnloadMag(){
		bool unsafe=(player.cmd.buttons&BT_USE)||(player.cmd.buttons&BT_ZOOM);
		for(int i=3;i>0;i--){
			int thismag=invoker.weaponstatus[i];
			if(thismag<0)continue;
			if(unsafe||!thismag||thismag>50){
				invoker.weaponstatus[i]=-1;
				if(pressingunload()||pressingreload()){
					HD4mMag.GiveMag(self,"HD4mMag",thismag);
					A_PlaySound("weapons/pocket",CHAN_WEAPON);
					A_SetTics(20);
				}else HD4mMag.SpawnMag(self,"HD4mMag",thismag);
				break;
			}
		}
	}
	action void A_LoadBattery(){
		if(invoker.weaponstatus[4]>=0)return;
		let batt=HDBattery(findinventory("HDBattery"));
		if(!batt)return;
		int toload=batt.takemag(true);
		invoker.weaponstatus[4]=toload;
		A_PlaySound("weapons/vulcopen1",CHAN_WEAPON);
	}
	action void A_UnloadBattery(){
		int batt=invoker.weaponstatus[4];
		if(batt<0)return;
		if(pressingunload()||pressingreload()){
			HDBattery.GiveMag(self,"HDBattery",batt);
			A_PlaySound("weapons/pocket",CHAN_WEAPON);
			A_SetTics(20);
		}else HDBattery.SpawnMag(self,"HDBattery",batt);
		invoker.weaponstatus[4]=-1;
	}
	action void A_HERPWeaponReady(){
		if(invoker.amount<1){
			invoker.goawayanddie();
			return;
		}
		if(pressingfire()){
			int yofs=invoker.weaponstatus[HERP_YOFS];
			yofs=max(yofs+12,yofs*3/2);
			if(yofs>100)A_DeployHERP();
			invoker.weaponstatus[HERP_YOFS]=yofs;
		}else invoker.weaponstatus[HERP_YOFS]=invoker.weaponstatus[HERP_YOFS]*2/3;
		if(pressingfiremode()){
			int inputamt=clamp((player.cmd.pitch>>8),-4,4);
			inputamt+=(justpressed(BT_ATTACK)?1:justpressed(BT_ALTATTACK)?-1:0);
			hijackmouse();
			invoker.weaponstatus[HERP_BOTID]=clamp(
				invoker.weaponstatus[HERP_BOTID]-inputamt,0,63
			);
		}else if(justpressed(BT_ALTATTACK)){
			invoker.weaponstatus[0]^=HERPF_STARTOFF;
			A_PlaySound("weapons/fmswitch",CHAN_WEAPON);
		}else A_WeaponReady(WRF_NOFIRE|WRF_ALLOWRELOAD|WRF_ALLOWUSER1|WRF_ALLOWUSER3|WRF_ALLOWUSER4);
	}
	action bool A_CheckFail(){
		if(invoker.weaponstatus[0]&HERPF_BROKEN){
			message(":(");
			return true;
		}
		if(invoker.weaponstatus[4]<1){
			message("No power. Please load 1 cell pack before deploying.");
			return true;
		}
		return false;
	}
	action void A_DeployHERP(){
		if(A_CheckFail()){
			setweaponstate("nope");
			return;
		}

		actor hhh;int iii;
		[iii,hhh]=A_SpawnItemEx("HERPBot",5,0,height-16,
			2.5*cos(pitch),0,-2.5*sin(pitch),
			0,SXF_NOCHECKPOSITION|SXF_TRANSFERTRANSLATION
			|SXF_TRANSFERPOINTERS|SXF_SETMASTER
		);
		hhh.A_PlaySound("misc/w_pkup",5);
		hhh.changetid(HERP_TID);
		hhh.vel+=vel;hhh.angle=angle;
		let hhhh=HERPBot(hhh);
		hhhh.startangle=angle;
		hhhh.ammo[0]=invoker.weaponstatus[1];
		hhhh.ammo[1]=invoker.weaponstatus[2];
		hhhh.ammo[2]=invoker.weaponstatus[3];
		hhhh.battery=invoker.weaponstatus[4];
		hhhh.botid=invoker.weaponstatus[HERP_BOTID];
		hhhh.bmissilemore=invoker.weaponstatus[0]&HERPF_STARTOFF?false:true;
		A_Log(string.format("\cd[HERP] \cjDeployed with tag ID \cy%i",invoker.weaponstatus[HERP_BOTID]),true);
		A_GiveInventory("HERPController");
		HERPController(findinventory("HERPController")).UpdateHerps(false);
		dropinventory(invoker);
		invoker.goawayanddie();
		return;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		int batt=hdw.weaponstatus[4];

		//bottom status bar
		for(int i=2;i<4;i++){
			if(hdw.weaponstatus[i]>=0)sb.drawwepdot(-8-i*4,-13,(3,2));
		}
		sb.drawwepnum(hdw.weaponstatus[1]%100,50,posy:-10);
		sb.drawwepcounter(hdw.weaponstatus[0]&HERPF_STARTOFF,
			-28,-16,"STBURAUT","blank"
		);

		if(!batt)sb.drawstring(
			sb.mamountfont,"00000",(-16,-8),
			sb.DI_TEXT_ALIGN_RIGHT|sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
			Font.CR_DARKGRAY
		);else if(batt>0)sb.drawwepnum(batt,20);

		if(barrellength>0)return;

		int yofs=weaponstatus[HERP_YOFS];
		if(yofs<70){
			vector2 bob=hpl.hudbob*0.2;
			bob.y+=yofs;
			sb.drawimage("HERPA7A3",(10,14)+bob,
				sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER|sb.DI_TRANSLATABLE,
				scale:(2,2)
			);
			for(int i=1;i<4;i++){
				int bbb=hdw.weaponstatus[i];
				if(bbb>=51)sb.drawimage("ZMAGA0",(-20,i*10)+bob,
					sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					scale:(2,2)
				);else if(bbb>=0)sb.drawbar(
					"ZMAGNORM","ZMAGGREY",
					bbb,50,
					(-20,i*10)+bob,-1,
					sb.SHADER_VERT,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
				);
			}
			if(batt>=0){
				string batsprite;
				if(batt>13)batsprite="CELLA0";
				else if(batt>6)batsprite="CELLB0";
				else batsprite="CELLC0";
				sb.drawimage(batsprite,(0,30)+bob,
					sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
				);
			}
		}
	}
	override string gethelptext(){
		return
		WEPHELP_FIRE.."  Deploy\n"
		..WEPHELP_ALTFIRE.."  Cycle modes\n"
		..WEPHELP_FIREMODE.."+"..WEPHELP_UPDOWN.."  Set BotID\n"
		..WEPHELP_RELOAD.."  Reload mag\n"
		..WEPHELP_ALTRELOAD.."  Reload battery\n"
		..WEPHELP_UNLOAD.."  Unload mag\n"
		..WEPHELP_USE.."+"..WEPHELP_ALTRELOAD.."  Unload battery\n"
		..WEPHELP_USE.."+"..WEPHELP_UNLOAD.."  Unload partial mag\n"
		..WEPHELP_ZOOM.."  Manual firing"
		;
	}
	override void consolidate(){
		if(
			!(weaponstatus[0]&HERPF_BROKEN)
			||!owner
		)return;
		let bp=hdbackpack(owner.findinventory("HDBackpack"));
		if(bp){
			int herpindex=bp.invclasses.find(getclassname());
			if(herpindex<bp.invclasses.size()){
				array<string> inbp;
				bp.amounts[herpindex].split(inbp," ");
				for(int i=0;i<inbp.size();i+=9){
					if(
						inbp[i].toint()&HERPF_BROKEN
						&&!random(0,4)
					){
						//delete those entries
						for(int j=0;j<9;j++){
							inbp.delete(i);
						}
						string inbps="";
						while(inbp.size()){
							inbps=inbps..inbp[0];
							inbp.delete(0);
							if(inbp.size())inbps=inbps.." ";
						}
						bp.amounts[herpindex]=inbps;
						bp.updatemessage(bp.index);
						weaponstatus[0]&=~HERPF_BROKEN;
						owner.A_Log("You cannibalize some parts from the H.E.R.P.s your backpack to fix the one you were using.",true);
						return;
					}
				}
			}
		}
		if(!random(0,7)){
			weaponstatus[0]&=~HERPF_BROKEN;
			owner.A_Log("You manage some improvised field repairs to your H.E.R.P. robot.",true);
		}
	}
}
enum HERPNum{
	HERP_MAG1=1,
	HERP_MAG2=2,
	HERP_MAG3=3,
	HERP_BATTERY=4,
	HERP_BOTID=5,
	HERP_YOFS=6,

	HERPF_STARTOFF=1,
	HERPF_UNLOADONLY=2,
	HERPF_BROKEN=4,
}


extend class HDHandlers{
	void SetHERP(hdplayerpawn ppp,int botcmd,int botcmdid,int achange){
		let herpinv=HERPUsable(ppp.findinventory("HERPUsable"));
		int botid=herpinv?herpinv.weaponstatus[HERP_BOTID]:1;

		//set HERP tag number with -#
		if(botcmd<0){
			if(!herpinv)return;
			herpinv.weaponstatus[HERP_BOTID]=-botcmd;
			ppp.A_Log(string.format("\cd[HERP] \cjNext HERP tag set to \cy%i",-botcmd),true);
			return;
		}

		//give actual commands
		bool anybots=false;
		int affected=0;
		bool badcommand=true;
		actoriterator it=level.createactoriterator(HERP_TID,"HERPBot");
		actor bot=null;
		while(bot=it.Next()){
			anybots=true;
			let herp=HERPBot(bot);
			if(
				herp
				&&herp.master==ppp
				&&herp.health>0
				&&(
					!botcmdid||
					botcmdid==herp.botid
				)
			){
				if(botcmd==1){
					badcommand=false;
					if(
						herp.battery<1
						||(
							herp.ammo[0]<1
							&&herp.ammo[1]<1
							&&herp.ammo[2]<1
						)
					){
						ppp.A_Log(string.format("\cd[HERP] \crERROR:\cj HERP at [\cj%i\cu,\cj%i\cu] out of ammo or cells, \cxNOT\cj activated.",herp.pos.x,herp.pos.y),true);
					}else{
						affected++;
						herp.bmissilemore=true;
					}
				}
				else if(botcmd==2){
					affected++;
					badcommand=false;
					herp.bmissilemore=false;
				}
				else if(botcmd==3){
					if(!achange){
						ppp.A_Log(string.format("\cd[HERP] \crERROR:\cj No angle change indicated."),true);
					}else{
						badcommand=false;
						affected++;
						int anet=(herp.startangle+achange)%360;
						if(anet<0)anet+=360;
						herp.startangle=anet;
						herp.setstatelabel("off");

						ppp.A_Log(string.format("\cd[HERP] \cj HERP at [\cj%i\cu,\cj%i\cu]\cj base angle now facing %s",herp.pos.x,herp.pos.y,hdmath.cardinaldirection(anet)),true);
					}
				}
				else if(botcmd==123){
					badcommand=false;
					ppp.A_Log(string.format("\cd[HERP] \cu [\cj%i\cu,\cj%i\cu]\cj facing %s \cy%i\cj %s",
						herp.pos.x,herp.pos.y,
						hdmath.cardinaldirection(herp.startangle),
						herp.botid,
						herp.bmissilemore?"\cxACTIVE":"\cyinactive"
					),true);
				}
				else{
					badcommand=true;
					break;
				}
			}
		}
		if(
			!badcommand
			&&botcmd!=123
		){
			string verb="hacked";
			if(botcmd==1)verb="\cxactivated";
			else if(botcmd==2)verb="\cydeactivated";
			else if(botcmd==3)verb="\curedirected";
			ppp.A_Log(string.format(
				"\cd[HERP] \cj%i HERP%s %s%s\cj.",affected,affected==1?"":"s",
				botcmdid?string.format("with tag \ca%i\cj ",botcmdid):"",
				verb
			),true);
		}else if(badcommand)ppp.A_Log(string.format("\cd[HERP] \cj%sCommand format:\cu herp <option> <tag number> <direction>\n\cjOptions\n 1 = ON\n 2 = OFF\n 3 = DIRECTION (counterclockwise in degrees)\n 123 = QUERY\n -n = set tag number\n\cj  tag number on next deployment: \cy%i",anybots?"":"No HERPs currently deployed.\n",botid),true);
	}
}








class HERPController:HDWeapon{
	default{
		+inventory.invbar
		+weapon.wimpy_weapon
		+nointeraction
		inventory.icon "HERPA5";
		weapon.selectionorder 1013;
		tag "H.E.R.P. interface";
	}
	array<herpbot> herps;
	herpbot UpdateHerps(bool resetindex=true){
		herps.clear();
		if(!owner)return null;
		ThinkerIterator herpfinder=thinkerIterator.Create("HERPBot");
		herpbot mo;
		while(mo=HERPBot(herpfinder.Next())){
			if(
				mo.master==owner
				&&mo.battery>0
			)herps.push(mo);
		}
		if(resetindex)weaponstatus[HERPS_INDEX]=0;
		if(!herps.size()){
			if(
				owner
				&&owner.player
				&&owner.player.readyweapon==self
			){
				owner.A_Log("No H.E.R.P.s deployed. Abort.",true);
				owner.A_SelectWeapon("HDFist");
			}
			destroy();
			return null;
		}
		herpbot ddd=herps[0];
		return ddd;
	}
	static void GiveController(actor caller){
		caller.A_SetInventory("HERPController",1);
		caller.findinventory("HERPController").binvbar=true;
		let ddc=HERPController(caller.findinventory("HERPController"));
		ddc.updateherps(false);
		if(ddc&&!ddc.herps.size())caller.dropinventory(ddc);
	}
	int NextHerp(){
		int newindex=weaponstatus[HERPS_INDEX]+1;
		if(newindex>=herps.size())newindex=0;
		if(weaponstatus[HERPS_INDEX]!=newindex){
			owner.A_Log("Switching to next H.E.R.P. in the list.",true);
			weaponstatus[HERPS_INDEX]=newindex;
		}
		return newindex;
	}
	override inventory CreateTossable(int amount){
		if(
			(herps.size()&&herps[NextHerp()])
			||updateherps(false)
		)return null;
		if(self)return weapon.createtossable(amount);
		return null;
	}
	override string gethelptext(){
		if(!herps.size())return "ERROR";
		weaponstatus[HERPS_INDEX]=clamp(weaponstatus[HERPS_INDEX],0,herps.size()-1);
		let herpcam=herps[weaponstatus[HERPS_INDEX]];
		if(!herpcam)return "ERROR";
		if(
			herpcam.health<1
			||herpcam.battery<1
		)return WEPHELP_DROP.."  Next H.E.R.P.";
		bool connected=(herpcam.bmissileevenmore);
		bool turnedon=(herpcam.bmissilemore);
		if(connected)return
		WEPHELP_FIREMODE.."  Hold to pilot and:\n"
		.."  "..WEPHELP_FIRESHOOT
		..WEPHELP_ALTRELOAD.."  Set home angle\n"
		..WEPHELP_ALTFIRE.."  Turn "..(turnedon?"Off":"On").."\n"
		..WEPHELP_RELOAD.."  Disconnect manual mode\n"
		..WEPHELP_DROP.."  Next H.E.R.P."
		;
		return
		WEPHELP_RELOAD.."  Connect manual mode\n"
		..WEPHELP_DROP.."  Next H.E.R.P."
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc,string whichdot
	){
		if(
			!herps.size()
			||weaponstatus[HERPS_INDEX]>=herps.size()
		)return;
		let herpcam=herps[weaponstatus[HERPS_INDEX]];
		if(!herpcam)return;

		bool dead=herpcam.health<1;
		bool nobat=dead||!herpcam.bmissilemore||herpcam.battery<1;
		int scaledyoffset=66;
		if(!nobat)texman.setcameratotexture(herpcam,"HDXHCAM7",60);
		sb.drawimage(
			nobat?"HDXHCAM1BLANK":"HDXHCAM7",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
			scale:nobat?(1,1):(0.5,0.5)
		);
		sb.drawimage(
			"tbwindow",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
		);
		if(!dead)sb.drawimage(
			"redpxl",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.4,scale:(2,2)
		);
		sb.drawnum(dead?0:max(0,herpcam.ammo[0]),
			24+bob.x,42+bob.y,sb.DI_SCREEN_CENTER,Font.CR_RED,0.4
		);
		int cmd=dead?0:herpcam.battery;
		sb.drawnum(cmd,
			24+bob.x,52+bob.y,sb.DI_SCREEN_CENTER,cmd>10?Font.CR_OLIVE:Font.CR_BROWN,0.4
		);

		string hpst1="\cxAUTO",hpst2="press \cdreload\cu for manual";
		if(nobat){
			hpst1="\cuOFF";
			hpst2="press \cdaltfire\cu to turn on";
		}else if(herpcam.bmissileevenmore){
			hpst1="\cyMANUAL";
			hpst2=(owner.player.cmd.buttons&BT_FIREMODE)?"":"hold \cdfiremode\cu to steer";
		}
		sb.drawstring(
			sb.psmallfont,hpst1,
			(bob.x,10+bob.y),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_CENTER,alpha:0.7
		);
		if(cvar.getcvar("hd_helptext",owner.player).getbool()){
			sb.drawstring(
				sb.psmallfont,hpst2,
				(bob.x,18+bob.y),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_CENTER,Font.CR_DARKGRAY,alpha:0.6
			);
		}
	}
	states{
	select:
		TNT1 A 10{
			invoker.weaponstatus[HERPS_TIMER]=3;
			if(getcvar("hd_helptext"))A_WeaponMessage("\cd/// \ccH.E.R.P. \cd\\\\\\\c-\n\n\n\cdDrop\cu cycles through H.E.R.P.s. \cdReload\cu toggles input mode.\n\n\cdAlt. Reload\cu sets home angle.\n\nHold \cdFiremode\cu to control.\n\cdFire\cu to shoot.",215);
		}
		goto super::select;
	ready:
		TNT1 A 1{
			A_SetHelpText();
			if(
				!invoker.herps.size()
				||invoker.weaponstatus[HERPS_INDEX]>=invoker.herps.size()
			){
				invoker.updateherps();
				return;
			}
			A_WeaponReady(WRF_NOFIRE|WRF_ALLOWUSER3);
			herpbot ddd=invoker.herps[invoker.weaponstatus[HERPS_INDEX]];
			if(!ddd){
				if(ddd=invoker.updateherps())A_Log("H.E.R.P. not found. Resetting list.",true);
				return;
			}
			int bt=player.cmd.buttons;

			if(ddd.health<1)return;

			if(justpressed(BT_ALTATTACK)){
				ddd.bmissilemore=ddd.bmissilemore?false:true;
				ddd.herpbeep();
			}

			if(
				ddd.bmissileevenmore
				&&ddd.bmissilemore
			){
				if(justpressed(BT_RELOAD)){
					ddd.setstatelabel("inputabort");
				}else if(bt&BT_FIREMODE){
					if(
						bt&BT_ATTACK
						&&!invoker.weaponstatus[HERPS_TIMER]
						&&ddd.ammo[0]>0
					){
						invoker.weaponstatus[HERPS_TIMER]+=4;
						ddd.setstatelabel("shoot");
					}
					int yaw=player.cmd.yaw>>6;
					int ptch=player.cmd.pitch>>6;
					if(yaw||ptch){
						ddd.A_PlaySound("derp/crawl",CHAN_BODY);
						ddd.pitch=clamp(ddd.pitch-clamp(ptch,-10,10),-60,60);
						ddd.angle+=clamp(yaw,-DERP_MAXTICTURN,DERP_MAXTICTURN);
					}
					if(player.cmd.sidemove){
						ddd.A_PlaySound("derp/crawl",CHAN_BODY);
						ddd.angle+=player.cmd.sidemove<0?10:-10;
						player.cmd.sidemove*=-1;
					}
					hijackmouse();
				}
				if(justpressed(BT_USER1)){
					ddd.startangle=ddd.angle;
					ddd.herpbeep();
					A_Log("Home angle set.",true);
				}
			}else if(justpressed(BT_RELOAD)){
				ddd.setstatelabel("inputwaiting");
			}

			if(!invoker.bweaponbusy&&hdplayerpawn(self))hdplayerpawn(self).nocrosshair=0;
			if(invoker.weaponstatus[HERPS_TIMER]>0)invoker.weaponstatus[HERPS_TIMER]--;
		}goto readyend;
	user3:
		---- A 0 A_MagManager("HD9mMag15");
		goto ready;
	spawn:
		TNT1 A 0;
		stop;
	}
}
enum HERPControllerNums{
	HERPS_INDEX=1,
	HERPS_AMMO=2,
	HERPS_MODE=3,
	HERPS_TIMER=4,
}

