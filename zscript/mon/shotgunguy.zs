// ------------------------------------------------------------
// Former Human Sergeant
// ------------------------------------------------------------
class Jackboot:HideousShotgunGuy{default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Shotgun Guy (Pump)"
		//$Sprite "SPOSA1"
		accuracy 1;
}}
class JackAndJillboot:HideousShotgunGuy{default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Shotgun Guy (Side-By-Side)"
		//$Sprite "SPOSA1"
		accuracy 2;
}}
class UndeadJackbootman:HideousShotgunGuy{default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "ZM66 Burst Guy"
		//$Sprite "PLAYF1"
		accuracy 3;
}}
class HideousShotgunGuy:HDMobMan replaces ShotgunGuy{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Shotgun Guy"
		//$Sprite "SPOSA1"

		seesound "shotguy/sight";
		painsound "shotguy/pain";
		deathsound "shotguy/death";
		activesound "shotguy/active";
		tag "jackboot";

		speed 10;
		decal "BulletScratch";
		meleesound "weapons/smack";
		meleedamage 4;
		maxtargetrange 4000;
		painchance 200;
		accuracy 0;

		//placeholder
		obituary "%o was shot up by the Tyrant's jack-booted thugs.";
		hitobituary "%o was beaten up by the Tyrant's jack-booted thugs.";
	}
	bool jammed;
	bool semi;
	int gunloaded;
	int gunspent;
	int wep;
	int turnamount;
	int choke; //record here because the gun should only drop once
	double shotspread; //related to aim, NOT choke. Sorry about shitty names
	override void beginplay(){
		super.beginplay();
		bhasdropped=0;

		//-1 zm66, 0 sg, 1 ssg
		if(!accuracy) wep=random(0,1)-random(0,1);
		else if(accuracy==1)wep=0;
		else if(accuracy==2)wep=1;
		else if(accuracy==3)wep=-1;

		//if no ssg, sg
		if(Wads.CheckNumForName("SHT2B0",wads.ns_sprites,-1,false)<0&&wep==1)wep=0;
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(wep<0){
			bhashelmet=true;
			sprite=GetSpriteIndex("PLAYA1");
			A_SetTranslation("HattedJackboot");
			gunloaded=random(10,50);
			givearmour(1.,0.06,-0.4);
		}else{
			sprite=GetSpriteIndex("SPOSA1");
			A_SetTranslation("ShotgunGuy");
			gunloaded=wep?random(1,2):random(3,8);
			if(random(0,7))choke=(wep?(7+8*7):1);else{
				choke=random(0,7);
				//set second barrel
				if(wep)choke+=8*random(0,7);
			}
		}
		semi=randompick(0,0,1);
		hdmobster.spawnmobster(self);
	}
	override void deathdrop(){
		A_NoBlocking();
		if(bhasdropped){
			if(!bfriendly){
				if(wep<0)A_DropItem("HD4mMag",0,96);
				else A_DropItem("ShellPickup",0,200);
			}
		}else{
			A_DropItem("HDHandgunRandomDrop");
			bhasdropped=true;
			hdweapon wp=null;
			if(wep==-1){
				wp=hdweapon(spawn("ZM66AssaultRifle",(pos.x,pos.y,pos.z+40),ALLOW_REPLACE));
				wp.weaponstatus[0]=
					ZM66F_NOLAUNCHER|(randompick(0,1,1,1,1)*ZM66F_CHAMBER);
				wp.weaponstatus[ZM66S_MAG]=gunloaded;
				wp.weaponstatus[ZM66S_AUTO]=2;
				wp.weaponstatus[ZM66S_ZOOM]=random(16,70);
				if(jammed||!random(0,7))wp.weaponstatus[0]|=ZM66F_CHAMBERBROKEN;

				gunloaded=50;
			}
			if(wep==0){
				wp=hdweapon(spawn("Hunter",(pos.x,pos.y,pos.z+40),ALLOW_REPLACE));
				wp.weaponstatus[HUNTS_FIREMODE]=semi?1:0;
				if(gunspent)wp.weaponstatus[HUNTS_CHAMBER]=1;
				else if(gunloaded>0){
					wp.weaponstatus[HUNTS_CHAMBER]=2;
					gunloaded--;
				}
				if(gunloaded>0)wp.weaponstatus[HUNTS_TUBE]=gunloaded;
				wp.weaponstatus[SHOTS_SIDESADDLE]=random(0,12);
				wp.weaponstatus[0]&=~HUNTF_CANFULLAUTO;
				wp.weaponstatus[HUNTS_CHOKE]=choke;

				gunloaded=8;
			}
			if(wep==1){
				wp=hdweapon(spawn("Slayer",(pos.x,pos.y,pos.z+40),ALLOW_REPLACE));
				if(gunloaded==2)wp.weaponstatus[SLAYS_CHAMBER2]=2;
				else if(gunspent==2)wp.weaponstatus[SLAYS_CHAMBER2]=1;
				if(gunloaded>0)wp.weaponstatus[SLAYS_CHAMBER1]=2;
				else if(gunspent>0)wp.weaponstatus[SLAYS_CHAMBER1]=1;
				wp.weaponstatus[SHOTS_SIDESADDLE]=random(0,12);
				wp.weaponstatus[SLAYS_CHOKE1]=(choke&(1|2|4));
				wp.weaponstatus[SLAYS_CHOKE2]=(choke>>3);

				gunloaded=2;
			}
			wp.vel=vel+(frandom(-2,2),frandom(-2,2),1);
		}
		gunspent=0;
		if(wep==-1){
			gunloaded=50;
		}
		if(wep==0){
			gunloaded=8;
		}
		if(wep==1){
			gunloaded=2;
		}
	}
	states{
	spawn:
		SPOS A 0 nodelay A_JumpIf(wep>=0,"spawn2");
		PLAY A 0;
	spawn2:
		#### EEEEEE 1{
			A_Look();
			A_Recoil(frandom(-0.1,0.1));
			A_SetTics(random(1,10));
		}
		#### B 0 A_Jump(132,2,5,5,5,5);
		#### B 8{
			if(!random(0,1)){
				if(!random(0,4)){
					setstatelabel("spawnstretch");
				}else{
					if(bambush)setstatelabel("spawnstill");
					else setstatelabel("spawnwander");
				}
			}else A_Recoil(random(-1,1)*0.2);
		}loop;
	spawnstretch:
		#### G 1{
			A_Recoil(frandom(-0.4,0.4));
			A_SetTics(random(30,80));
		}
		#### A 0 A_StartSound(activesound,CHAN_VOICE);
		---- A 0 setstatelabel("spawn2");
	spawnstill:
		#### C 0{
			A_Look();
			A_Recoil(random(-1,1)*0.4);
		}
		#### CD 5{angle+=random(-4,4);}
		#### A 0{
			A_Look();
			if(!random(0,15))A_StartSound(activesound,CHAN_VOICE);
		}
		#### AB 5{angle+=random(-4,4);}
		#### B 1 A_SetTics(random(10,40));
		---- A 0 setstatelabel("spawn2");
	spawnwander:
		#### CD 5{hdmobai.wander(self,false);}
		#### A 0{if(!random(0,15))A_StartSound(activesound,CHAN_VOICE);}
		#### AB 5{hdmobai.wander(self,false);}
		#### A 0 A_Jump(64,"spawn2");
		loop;

	see:
		#### A 0{
			if(gunloaded<1)setstatelabel("reload");
			else if(!wep&&gunspent>0)setstatelabel("chambersg");
		}
		#### AABBCCDD 2{hdmobai.chase(self);}
		#### A 0 A_JumpIfTargetInLOS("see");
		#### A 0 A_Jump(16,"roam");
		loop;
	roam:
		#### A 0 A_Jump(60,"roam2");
	roam1:
		#### E 4{bmissileevenmore=true;}
		#### EEEEEEEEEEEEEEEE 1 A_Chase("melee","turnaround",CHF_DONTMOVE);
		#### A 0{bmissileevenmore=false;}
		#### A 0 A_Jump(60,"roam");
	roam2:
		#### A 0 A_Jump(8,"see");
		#### AA 3{hdmobai.chase(self);}
		#### A 0 A_Chase("melee","turnaround",CHF_DONTMOVE);
		#### BBCC 3{hdmobai.wander(self,false);}
		#### A 0 A_Chase("melee","turnaround",CHF_DONTMOVE);
		#### DD 3{hdmobai.chase(self);}
		#### A 0 A_Jump(200,"Roam");
		#### A 0{
			A_StartSound(seesound,CHAN_VOICE);
			A_AlertMonsters();
		}
		#### A 0 A_JumpIfTargetInLOS("see");
		loop;
	turnaround:
		#### A 0 A_FaceTarget(15,0);
		#### E 2 A_JumpIfTargetInLOS("missile2",40);
		#### A 0 A_FaceTarget(15,0);
		#### E 2 A_JumpIfTargetInLOS("missile2",40);
		#### AABBCCDD 2{hdmobai.chase(self);}
		---- A 0 setstatelabel("see");

	missile:
		#### A 0 A_JumpIfTargetInLOS(3,120);
		#### CD 2 A_FaceTarget(90);
		#### E 1 A_SetTics(random(4,10)); //when they just start to aim,not for followup shots!
		#### A 0 A_CheckLOF("see",
			CLOFF_JUMPNONHOSTILE|CLOFF_SKIPTARGET|
			CLOFF_JUMPOBJECT|CLOFF_MUSTBESOLID|CLOFF_SKIPENEMY,
			0,0,0,0,44,0
		);
	missile2:
		#### A 0{
			if(!target){
				setstatelabel("see");
				return;
			}
			double dist=distance3d(target);
			if(dist<300){
				turnamount=40;
			}else if(dist<800){
				turnamount=30;
			}else{
				turnamount=20;
			}
		}//fallthrough to turntoaim
	turntoaim:
		#### E 2 A_FaceTarget(turnamount,turnamount);
		#### A 0 A_JumpIfTargetInLOS(2);
		---- A 0 setstatelabel("see");
		#### A 0 A_JumpIfTargetInLOS(1,10);
		loop;
		#### A 0 A_FaceTarget(turnamount,turnamount);
		#### E 1 A_SetTics(random(1,100/clamp(1,turnamount,turnamount+1)));
		#### E 0{
			if(
				gunloaded<1
			){
				setstatelabel("ohforfuckssake");
				return;
			}
			shotspread=frandom(turnamount*0.07,turnamount*0.22);
			setstatelabel("shoot");
		}
	shoot:
		#### F 0 A_JumpIf(jammed,"jammed");
		#### A 0{
			if(gunloaded<1){
				setstatelabel("ohforfuckssake");
				return;
			}
			if(wep==1)shotspread*=0.8;
			angle+=frandom(0,shotspread)-frandom(0,shotspread);
			pitch+=frandom(0,shotspread)-frandom(0,shotspread);

			if(wep==-1)setstatelabel("shootzm66");
			else if(wep==1)setstatelabel("shootssg");
			else setstatelabel("shootsg");
		}


	shootzm66:
		#### F 0{
			gunspent=0;
		}
	shootzm662:
		#### F 1 bright light("SHOT"){
			if(!random(0,999)){
				A_StartSound("weapons/rifleclick",8);
				gunloaded=-gunloaded;
				setstatelabel("ohforfuckssake");
				return;
			}

			angle+=frandom(-0.5,0.5);
			pitch+=frandom(-0.5,0.5);

			A_StartSound("weapons/rifle",CHAN_WEAPON);

			gunspent++;
			gunloaded--;
			HDBulletActor.FireBullet(self,"HDB_426");
			if(random(0,2000)<gunspent+2){
				jammed=true;
				A_StartSound("weapons/rifleclick",8);
				setstatelabel("jammed");
			}
		}
		#### E 1{
			if(gunspent<3&&gunloaded>0)setstatelabel("shootzm662");
			else A_SetTics(random(4,12));
		}
		#### E 0 A_Jump(127,"see");
		#### E 0 A_SpidRefire();
		goto turntoaim;

	shootssg:
		#### F 1 bright light("SHOT"){
			if(vel dot vel > 900){
				setstatelabel("see");
				return;
			}

			A_StartSound("weapons/slayersingle",CHAN_WEAPON);
			if(gunloaded>1&&!random(0,5)){
				//both barrels
				A_StartSound("weapons/slayersingle",CHAN_WEAPON,CHANF_OVERLAP);
				gunspent=2;
				gunloaded=0;
				Slayer.Fire(self,0,(choke&(1|2|4)));
				Slayer.Fire(self,1,(choke>>3));
			}else{
				//single barrel
				gunspent++;
				gunloaded--;
				if(gunspent)Slayer.Fire(self,1,(choke>>3));
				else Slayer.Fire(self,0,(choke&(1|2|4)));
			}
		}
		#### E 1 A_SetTics(random(2,4));
		#### E 0 A_Jump(192,"see");
		#### E 0 A_SpidRefire();
		goto turntoaim;

	shootsg:
		#### F 1 bright light("SHOT"){
			if(gunspent>0){
				setstatelabel("chambersg");
				return;
			}else if(vel dot vel > 400){
				setstatelabel("see");
				return;
			}

			if(Hunter.Fire(self,choke)<=Hunter.HUNTER_MINSHOTPOWER)semi=false;
			gunspent=1;
		}
		#### E 3{
			if(semi){
				A_SetTics(0);
				if(gunloaded>0)gunloaded--;
				gunspent=0;
				A_SpawnItemEx("HDSpentShell",
					cos(pitch)*8,0,height-7-sin(pitch)*8,
					vel.x+cos(pitch)*cos(angle-random(86,90))*6,
					vel.y+cos(pitch)*sin(angle-random(86,90))*6,
					vel.z+sin(pitch)*random(5,7),0,
					SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
				if(!random(0,7))semi=false;
			}
		}
		#### E 1{
			if(gunspent)setstatelabel("chambersg");
			else A_SetTics(random(3,8));
		}
		#### E 0 A_Jump(127,"see");
		#### E 0 A_SpidRefire();
		goto turntoaim;
	chambersg:
		#### E 8{
			if(gunspent){
				A_SetTics(random(3,10));
				A_StartSound("weapons/huntrack",8);
				gunspent=0;
				if(gunloaded>0)gunloaded--;
				A_SpawnItemEx("HDSpentShell",
					cos(pitch)*8,0,height-7-sin(pitch)*8,
					vel.x+cos(pitch)*cos(angle-random(86,90))*6,
					vel.y+cos(pitch)*sin(angle-random(86,90))*6,
					vel.z+sin(pitch)*random(5,7),0,
					SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}
			if(!random(0,7))semi=true;
		}
		#### E 1 A_SetTics(random(3,8));
		#### E 0 A_Jump(127,"see");
		#### E 0 A_SpidRefire();
		goto turntoaim;

	jammed:
		#### E 8;
		#### E 0 A_Jump(128,"see");
		#### E 4 A_StartSound(random(0,2)?seesound:painsound,CHAN_VOICE);
		---- A 0 setstatelabel("see");

	ohforfuckssake:
		#### E 6;
	reload:
		#### A 0{
			if(wep==-1)setstatelabel("reloadzm66");
			else if(wep==1)setstatelabel("reloadssg");
			else setstatelabel("reloadsg");
		}


	reloadzm66:
		#### A 0{bfrightened=true;}
		#### AA 1{hdmobai.chase(self,"melee",null);}
		#### A 0 A_StartSound("weapons/rifleclick2",8);
		#### BCD 2{hdmobai.chase(self,"melee",null);}
		#### A 2{
			hdmobai.wander(self,true);
			if(gunspent==999)return;

			A_StartSound("weapons/rifleload",8);
			if(!gunloaded)A_SpawnProjectile("HD4mmMagEmpty",38,0,random(90,120));
			else{
				HDMagAmmo.SpawnMag(self,"HD4mMag",gunloaded);
				gunspent=999;
			}
		}
		#### BCD 2{hdmobai.chase(self,"melee",null);}
		#### A 4 A_StartSound("weapons/pocket",9);
		#### BC 4{hdmobai.wander(self,true);}
		#### E 6 A_StartSound("weapons/rifleload",8);
		#### E 2{
			A_StartSound("weapons/rifleclick2");
			gunloaded=50;
			gunspent=0;
			bfrightened=false;
			hdmobai.wander(self,true);
		}
		#### CCBB 2{hdmobai.chase(self,"melee",null);}
		goto turntoaim;

	reloadssg:
		#### E 2;
		#### E 2 A_StartSound("weapons/sshoto",8);
		#### E 0{
			while(gunspent>0){
				gunspent--;
				A_SpawnItemEx("HDSpentShell",
					cos(pitch)*5,-1,height-7-sin(pitch)*5,
					cos(pitch-45)*cos(angle)*random(1,4)+vel.x,
					cos(pitch-45)*sin(angle)*random(1,4)+vel.y,
					-sin(pitch-45)*random(1,4)+vel.z,0,
					SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}
		}

		#### EEDD 1{hdmobai.chase(self,"melee",null);}
		#### DAAB 3{hdmobai.chase(self,"melee",null);}
		#### B 1 A_StartSound("weapons/sshotl",8);
		#### CCD 4;
		#### E 6{
			A_StartSound("weapons/sshotc",8);
			gunloaded=2;
		}
		---- A 0 setstatelabel("see");

	reloadsg:
		#### A 0{bfrightened=true;}
		#### AA 1{hdmobai.chase(self,"melee",null);}
		#### A 0 A_StartSound("weapons/huntopen",8);
		#### BCDA 2{hdmobai.chase(self,"melee",null);}
	reloadsg2:
		#### BB 3{hdmobai.chase(self,null,null,flee:true);}
		#### B 0{
			gunloaded++;
			A_StartSound("weapons/huntreload",8);
			if(gunloaded>=8)setstatelabel("reloadsgend");
		}
		#### CC 3{hdmobai.chase(self,null,null,flee:true);}
		#### C 0{
			gunloaded++;
			A_StartSound("weapons/huntreload",8);
			if(gunloaded>=8)setstatelabel("reloadsgend");
		}
		#### DD 3{hdmobai.chase(self,null,null,flee:true);}
		#### D 0{
			gunloaded++;
			A_StartSound("weapons/huntreload",8);
			if(gunloaded>=8)setstatelabel("reloadsgend");
		}
		#### A 0 A_StartSound("weapons/pocket",9);
		#### AABBCCDDAA 2{hdmobai.chase(self,null,null,flee:true);}
		loop;
	reloadsgend:
		#### A 0{bfrightened=false;}
		#### BBCCDD 2{hdmobai.chase(self,null,null);}
		#### A 0 A_StartSound("weapons/huntopen",8);
		#### EEE 1 A_Chase("melee","missile",CHF_DONTMOVE);
		---- A 0 setstatelabel("see");

	melee:
		#### C 6 A_FaceTarget();
		#### D 4;
		#### E 4{
			A_CustomMeleeAttack(
				random(5,25),"weapons/smack","","none",randompick(0,0,0,1)
			);
			if(jammed&&!random(0,32)){
				if(!random(0,5))A_SpawnItemEx("HDSmokeChunk",12,0,height-12,4,frandom(-2,2),frandom(2,4));
				A_SpawnItemEx("BulletPuffBig",12,0,42,1,0,1);
				jammed=false;
				A_StartSound("weapons/rifleclick",8);
			}
		}
		#### E 3 A_JumpIfCloser(64,2);
		#### E 3 A_FaceTarget();
		goto missile;
		#### A 3;
		---- A 0 setstatelabel("see");
	pain:
		#### G 3 A_Jump(12,1);
		#### G 3{
			A_Pain();
			if(!random(0,7))A_AlertMonsters();
		}
		#### G 0{
			if(target&&distance3d(target)<100)setstatelabel("see");
			bfrightened=true;
		}
		#### ABCD 2{hdmobai.chase(self);}
		#### G 0{bfrightened=false;}
		---- A 0 setstatelabel("see");

	death:
		#### H 5;
		#### I 5 A_Scream();
		#### JK 5;
	dead:
		#### K 3 canraise{if(abs(vel.z)<2.)frame++;}
		#### L 5 canraise{if(abs(vel.z)>=2.)setstatelabel("dead");}
		wait;
	xxxdeath:
		#### M 0 A_JumpIf(wep<0,"xxxdeath2");
		#### M 5;
		#### N 5 A_XScream();
		#### OPQRST 5;
		goto xdead;
	xxxdeath2:
		#### O 5;
		#### P 5 A_XScream();
		#### QRSTUV 5;
		goto xdead2;
	xdeath:
		#### M 0 A_JumpIf(wep<0,"xdeath2");
		#### M 5;
		#### N 5{
			spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
			A_XScream();
		}
		#### OP 5 spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
		#### QRST 5;
		goto xdead;
	xdead:
		#### T 3 canraise{if(abs(vel.z)<2.)frame++;}
		#### U 5 canraise{if(abs(vel.z)>=2.)setstatelabel("xdead");}
		wait;
	xdeath2:
		#### O 5;
		#### P 5{
			spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
			A_XScream();
		}
		#### QR 5 spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
		#### STUV 5;
		goto xdead2;
	xdead2:
		#### V 3 canraise{if(abs(vel.z)<2.)frame++;}
		#### W 5 canraise{if(abs(vel.z)>=2.)setstatelabel("xdead2");}
		wait;
	raise:
		#### A 0{
			jammed=false;
		}
		#### L 4 spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
		#### LK 6;
		#### JIH 4;
		---- A 0 setstatelabel("see");
	ungib:
		#### U 12;
		#### T 8;
		#### SRQ 6;
		#### PON 4;
		goto checkraise;
	}
}

class DeadJackboot:DeadHideousShotgunGuy{default{accuracy 1;}}
class DeadJackAndJillboot:DeadHideousShotgunGuy{default{accuracy 2;}}
class DeadUndeadJackbootman:DeadHideousShotgunGuy{default{accuracy 3;}}
class DeadHideousShotgunGuy:HideousShotgunGuy replaces DeadShotgunGuy{
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
	}
	states{
	death.spawndead:
		---- A 0;
		goto dead;
	}
}

