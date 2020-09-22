// ------------------------------------------------------------
// Humanoid template
// ------------------------------------------------------------
class HDMobMan:HDMobBase{
	default{
		gibhealth 140;
		health 100;
		height 54;
		radius 12;
		deathheight 12;
		mass 120;
		speed 10;
		+hdmobbase.smallhead
		+hdmobbase.biped
		hdmobbase.downedframe 11;
		tag "zombie";
	}
	//give armour
	hdarmourworn givearmour(double chance=1.,double megachance=0.,double minimum=0.){
		a_takeinventory("hdarmourworn");
		if(frandom(0.,1.)>chance)return null;
		let arw=hdarmourworn(giveinventorytype("hdarmourworn"));
		int maxdurability;
			if(frandom(0.,1.)<megachance){
			arw.mega=true;
			maxdurability=HDCONST_BATTLEARMOUR;
		}else maxdurability=HDCONST_GARRISONARMOUR;
		arw.durability=int(max(1,frandom(min(1.,minimum),1.)*maxdurability));
		return arw;
	}
	states{
	falldown:
		#### H 5;
		#### I 5 A_Scream();
		#### JJKKK 2 A_SetSize(-1,max(deathheight,height-10));
		#### L 0 A_SetSize(-1,deathheight);
		#### L 10 A_KnockedDown();
		wait;
	standup:
		#### K 6;
		#### J 0 A_Jump(160,2);
		#### J 0 A_StartSound(seesound,CHAN_VOICE);
		#### JI 4 A_Recoil(-0.3);
		#### HE 6;
		#### A 0 A_Jump(256,"see");
	}
}
class shootest:HDMobMan{
	default{+nodamage +nopain health int.MAX;}
	states{
	spawn:
		POSS A -1;
	}
}
class shoothicc:shootest{
	default{radius 48;}
}


// ------------------------------------------------------------
// Former Human
// ------------------------------------------------------------

/*
	SPECIAL NOTE FOR MAPPERS
	You can customize individual zombies using user_weapon.
	1=ZM66 regular; 2=ZM66 marksman; 3=SMG
*/

class ZombieStormtrooper:HDMobMan{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Zombieman"
		//$Sprite "POSSA1"

		+floorclip
		seesound "grunt/sight";
		painsound "grunt/pain";
		deathsound "grunt/death";
		activesound "grunt/active";
		tag "$cc_zombie";

		translation "58:66=128:136","214:223=141:148","176:191=24:47","16:34=68:79";
		speed 8;
		dropitem "";attacksound "";decal "BulletScratch";
		painchance 250;
		obituary "%o was gunned down by a zombieman.";
		hitobituary "%o was beaten up by a zombieman.";
		accuracy 0;
	}
	double spread;
	double turnamount;
	int user_weapon;
	int mag;
	int firemode; //-2 SMG; -1 semi only; 0 semi; 1 auto; 2+ burst
	bool jammed;
	override void postbeginplay(){
		super.postbeginplay();
		if(user_weapon)accuracy=user_weapon;
		if(accuracy==1)firemode=random(0,5);
		else if(accuracy==2)firemode=-1;
		else if(accuracy==3)firemode=-2;
		else firemode=random(-2,4);
		if(firemode==-2){
			mag=random(1,30);
			A_SetTranslation("ZombieSMG");
		}else{
			mag=random(1,50);
			if(firemode>2)firemode=1;
			maxtargetrange=6000;
		}
		hdmobster.spawnmobster(self);
	}
	void A_ZomFrag(){
		bool garbage;actor gg;
		double cpp=cos(pitch);double spp=sin(pitch);
		[garbage,gg]=A_SpawnItemEx("HDFragSpoon",
			cpp*-4,-3,height-6-spp*-4,
			cpp*3,0,-spp*3,
			frandom(30,45),SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
		gg.vel+=self.vel;
		double gforce=frandom(10,30);
		[garbage,gg]=A_SpawnItemEx("HDFragGrenade",
			0,0,height-6,
			cpp*gforce,0,-spp*gforce,
			0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
		gg.vel+=self.vel;
	}
	override void deathdrop(){
		if(bhasdropped&&bfriendly)return;
		hdweapon wp=null;
		if(firemode==-2){
			if(!bhasdropped){
				if(wp=hdweapon(spawn("HDSMG",pos,ALLOW_REPLACE))){
					wp.weaponstatus[SMGS_AUTO]=random(0,2);
					wp.weaponstatus[SMGS_MAG]=mag;
					wp.weaponstatus[SMGS_CHAMBER]=2;
				}
				A_DropItem("HDFragGrenadeAmmo",0,8);
				A_DropItem("HDFragGrenadeAmmo",0,4);
				A_DropItem("HD9mMag30");
			}else{
				A_DropItem("HD9mMag30",0,240);
				A_DropItem("HD9mMag30",0,128);
				A_DropItem("HDFragGrenadeAmmo",0,4);
				A_DropItem("HDFragGrenadeAmmo",0,4);
			}
		}else{
			if(!bhasdropped){
				if(wp=hdweapon(spawn("ZM66AssaultRifle",pos,ALLOW_REPLACE))){
					wp.weaponstatus[0]=ZM66F_NOLAUNCHER|(random(0,1)*ZM66F_CHAMBER);
					if(firemode==-1)wp.weaponstatus[0]|=ZM66F_NOFIRESELECT;

					if(mag>=50)wp.weaponstatus[ZM66S_MAG]=51;
					else wp.weaponstatus[ZM66S_MAG]=mag;

					wp.weaponstatus[ZM66S_ZOOM]=random(16,70);

					if(jammed||!random(0,15))wp.weaponstatus[0]|=ZM66F_CHAMBERBROKEN;
					else wp.weaponstatus[ZM66S_AUTO]=clamp(firemode,0,2);
				}
			}else{
				A_DropItem("HD4mMag",0,96);
			}
		}
		if(wp){
			wp.bdropped=true;
			wp.addz(40);
			wp.vel=vel+(frandom(-2,2),frandom(-2,2),1);
		}
		if(!bhasdropped){
			A_DropItem("HDHandgunRandomDrop");
			bhasdropped=true;
		}
	}
	void A_CheckFreedoomSprite(){
		if(bplayingid)sprite=getspriteindex("POSS");
		else{
			sprite=getspriteindex("SPOS");
			A_SetTranslation("FreedoomGreycoat");
		}
	}
	states{
	spawn:
		POSS A 0 nodelay A_CheckFreedoomSprite();
	spawn2:
		#### A 0{
			A_Look();
			A_Recoil(frandom(-0.1,0.1));
		}
		#### EEE 1{
			A_SetTics(random(5,17));
			A_Look();
		}
		#### E 1{
			A_Recoil(frandom(-0.1,0.1));
			A_SetTics(random(10,40));
		}
		#### B 0 A_Jump(28,"spawngrunt");
		#### B 0 A_Jump(132,"spawnswitch");
		#### B 8 A_Recoil(frandom(-0.2,0.2));
		loop;
	spawngrunt:
		#### G 1{
			A_Recoil(frandom(-0.4,0.4));
			A_SetTics(random(30,80));
			if(!random(0,7))A_StartSound(activesound,CHAN_VOICE);
		}
		#### A 0 A_Jump(256,"spawn2");
	spawnswitch:
		#### A 0 A_JumpIf(bambush,"spawnstill");
		goto spawnwander;
	spawnstill:
		#### A 0 A_Look();
		#### A 0 A_Recoil(random(-1,1)*0.4);
		#### CD 5 A_SetAngle(angle+random(-4,4));
		#### A 0{
			A_Look();
			if(!random(0,127))A_StartSound(activesound,CHAN_VOICE);
		}
		#### AB 5 A_SetAngle(angle+random(-4,4));
		#### B 1 A_SetTics(random(10,40));
		#### A 0 A_Jump(256,"spawn2");
	spawnwander:
		#### CDAB 5{hdmobai.wander(self,false);}
		#### A 0{
			if(!random(0,127))A_StartSound(activesound,CHAN_VOICE);
		}
		#### A 0 A_Jump(64,"spawn2");
		loop;
	missile:
		#### A 0{
			if(!target){
				setstatelabel("spawn2");
				return;
			}
			double dt=distance3d(target);
			if(
				firemode==-2
				&&target
				&&!random(0,39)
				&&dt>200
				&&dt<1000
			)setstatelabel("frag");
		}
		#### A 0 A_JumpIf(mag<1,"reload");
		#### A 0 A_JumpIfTargetInLOS(3,120);
		#### CD 2 A_FaceTarget(90);
		#### E 1 A_SetTics(random(4,10)); //when they just start to aim,not for followup shots!
		#### A 0 A_JumpIfTargetInLOS("missile2");
		#### A 0 A_CheckLOF("see",
			CLOFF_JUMPNONHOSTILE|CLOFF_SKIPTARGET|
			CLOFF_JUMPOBJECT|CLOFF_MUSTBESOLID|
			CLOFF_SKIPENEMY,
			0,0,0,0,44,0
		);
	missile2:
		#### A 0{
			if(!target){
				setstatelabel("spawn2");
				return;
			}
			double enemydist=distance3d(target);
			if(enemydist<200)turnamount=50;
			else if(enemydist<600)turnamount=30;
			else turnamount=10;
		}goto turntoaim;
	turntoaim:
		#### E 2 A_FaceTarget(turnamount,turnamount);
		#### A 0 A_JumpIfTargetInLOS(2);
		---- A 0 setstatelabel("see");
		#### A 0 A_JumpIfTargetInLOS(1,10);
		loop;
		#### E 1{
			A_FaceTarget(turnamount,turnamount);
			A_SetTics(random(1,int(120/clamp(turnamount,1,turnamount+1)+4)));
			spread=frandom(0.12,0.27)*turnamount;
		}
		#### A 0 A_Jump(256,"shoot");
	shoot:
		#### F 0 A_JumpIf(jammed,"jammed");
		#### F 1 bright light("SHOT"){
			if(mag<1){
				setstatelabel("ohforfuckssake");
				return;
			}
			if(firemode==-2){
				pitch+=frandom(0,spread)-frandom(0,spread);
				angle+=frandom(0,spread)-frandom(0,spread);
				A_StartSound("weapons/smg",CHAN_WEAPON);
				HDBulletActor.FireBullet(self,"HDB_9",speedfactor:1.1);
				A_SpawnItemEx("HDSpent9mm",
					cos(pitch)*10,0,height-8-sin(pitch)*10,
					vel.x,vel.y,vel.z,
					0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}else{
				pitch+=frandom(-spread,spread);
				angle+=frandom(-spread,spread);
				A_StartSound("weapons/rifle",CHAN_WEAPON);
				HDBulletActor.FireBullet(self,"HDB_426");
				if(random(0,2000)<firemode){
					jammed=true;
					A_StartSound("weapons/rifleclick",5);
					setstatelabel("jammed");
				}
			}

			mag--;
		}
		#### E 2{
			if(
				//conditions under which no autofire can happen
				!firemode
				||firemode==-1
				||firemode>3
				||mag<1
			){
				if(firemode>2)firemode=2;
				setstatelabel("postshot");
			}else if(
				//if burst, do not wait the tics of this frame
				firemode>=2
			){
				firemode++;
				setstatelabel("shoot");
			}
			else spread++;
		}
		#### A 0 A_Jump(120,"shoot");
		//fallthrough to postshot
	postshot:
		#### E 5{
			if(!random(0,127))A_StartSound(activesound,CHAN_VOICE);
			if(mag<1){
				setstatelabel("reload");
				return;
			}
			spread=max(0,spread-1);
			A_SetTics(random(2,6));
		}
		#### E 3;
		#### E 0 A_JumpIfTargetInLOS(1);
		goto coverfire;//even if not in los,occasionally keep shooting anyway
		#### E 3 A_FaceTarget(10,10);
		#### E 0 A_Jump(30,"see");//even if in los,occasionally stop shooting anyway
		goto coverfire;

	coverfire:
		#### E 1 A_SetTics(random(2,12));
		#### E 0{
			spread=2;
		}
		#### E 0 A_Jump(90,"roam");
		#### E 0 A_JumpIfTargetInLOS("missile2");
		#### E 0 A_Jump(216,"shoot");
		loop;

	frag:
		---- A 10 A_StartSound(seesound,CHAN_VOICE);
		---- A 20{
			A_StartSound("weapons/pocket",CHAN_WEAPON);
			A_FaceTarget(0,0);
			pitch-=random(10,50);
		}
		---- A 10{
			A_SpawnItemEx("HDFragSpoon",cos(pitch)*4,-1,height-6-sin(pitch)*4,cos(pitch)*cos(angle)*4+vel.x,cos(pitch)*sin(angle)*4+vel.y,sin(-pitch)*4+vel.z,0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH);
			A_ZomFrag();
		}
		---- A 0 A_JumpIf(mag<1,"reload");
		---- A 0 setstatelabel("see");

	jammed:
		#### E 8;
		#### E 0 A_Jump(128,"see");
		#### E 4 A_StartSound(random(0,2)?seesound:painsound,CHAN_VOICE);
		---- A 0 setstatelabel("see");

	ohforfuckssake:
		#### E 8;
	reload:
		---- A 4{
			A_StartSound("weapons/rifleclick2");
			bfrightened=true;
		}
		#### AA 1{hdmobai.chase(self,"melee",null);}
		#### A 0{
			A_StartSound("weapons/rifleload");
			name emptymag="HD4mMag";
			if(firemode==-2)emptymag="HD9mMag30";
			HDMagAmmo.SpawnMag(self,emptymag,0);
		}
		#### BCD 2 {hdmobai.chase(self,"melee",null);}
		#### E 12 A_StartSound("weapons/pocket",8);
		#### E 8 A_StartSound("weapons/rifleload",9);
		#### E 2{
			A_StartSound("weapons/rifleclick2",8);
			if(firemode==-2)mag=30;else mag=50;
			bfrightened=false;
		}
		#### CCBB 2{hdmobai.wander(self,true);}

	see:
		#### A 0{if(firemode>=0)firemode=random(0,2);}
	see2:
		#### A 0{
			if(mag<1)setstatelabel("reload");
		}
		#### AABBCCDD 2 {hdmobai.chase(self);}
		#### A 0{
			spread=2;
		}
		#### A 0 A_JumpIfTargetInLOS("see");
		#### A 0 A_Jump(24,"roam");
		loop;
	roam:
		#### E 3 A_Jump(60,"roam2");
		#### E 0{spread=1;}
		#### EEEE 1 A_Chase("melee","turnaround",CHF_DONTMOVE);
		#### E 0{spread=0;}
		#### EEEEEEEEEEEEE 1 A_Chase("melee","turnaround",CHF_DONTMOVE);
		#### A 0 A_Jump(60,"roam");
	roam2:
		#### A 0 A_Jump(8,"see");
		#### A 5{hdmobai.chase(self);}
		#### BC 5{hdmobai.wander(self,true);}
		#### D 5{hdmobai.chase(self);}
		#### A 0 A_Jump(140,"Roam");
		#### A 0 A_AlertMonsters();
		#### A 0 A_JumpIfTargetInLOS("see");
		loop;
	turnaround:
		#### A 0 A_FaceTarget(15,0);
		#### E 2 A_JumpIfTargetInLOS("missile2",40);
		#### E 0{spread=3;}
		#### A 0 A_FaceTarget(15,0);
		#### E 0{spread=6;}
		#### E 2 A_JumpIfTargetInLOS("missile2",40);
		#### E 0{spread=4;}
		#### ABCD 3{hdmobai.chase(self);}
		---- A 0 setstatelabel("see");
	melee:
		#### C 8 A_FaceTarget();
		#### D 4;
		#### E 4{
			A_CustomMeleeAttack(
				random(3,20),"weapons/smack","","none",randompick(0,0,0,1)
			);
			if(jammed&&!random(0,32)){
				if(!random(0,5))A_SpawnItemEx("HDSmokeChunk",12,0,height-12,4,frandom(-2,2),frandom(2,4));
				for(int i=0;i<5;i++)A_SpawnItemEx("FourMilChunk",0,0,20,
					random(4,7),random(-2,2),random(-2,1),0,SXF_NOCHECKPOSITION
				);
				jammed=false;
				A_StartSound("weapons/rifleclick",8);
			}
		}
		#### E 3 A_JumpIfCloser(64,2);
		#### E 4 A_FaceTarget(10,10);
		goto missile2;
		#### A 4;
		---- A 0 setstatelabel("see");
	pain:
		#### G 2;
		#### G 3{
			A_Pain();
			if(!random(0,10))A_AlertMonsters();
		}
		#### G 0{
			if(target&&distance3d(target)<100)setstatelabel("see");
			else bfrightened=true;
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
		#### M 5;
		#### N 5 A_XScream();
		#### OPQRST 5;
		goto xdead;
	xdeath:
		#### M 5;
		#### N 5{
			spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
			A_XScream();
		}
		#### OP 5 spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
		#### QRST 5;
		goto xdead;
	xdead:
		#### T 3 canraise A_JumpIf(abs(vel.z)<2.,1);
		#### U 5 canraise A_JumpIf(abs(vel.z)>=2.,"xdead");
		wait;
	raise:
		#### L 4{
			jammed=false;
		}
		#### LK 6;
		#### JIH 4;
		goto checkraise;
	ungib:
		#### U 12;
		#### T 8;
		#### SRQ 6;
		#### PONM 4;
		goto checkraise;
	}
}


class ZombieAutoStormtrooper:ZombieStormTrooper{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Zombieman (ZM66)"
		//$Sprite "POSSA1"
		accuracy 1;
}}
class ZombieSemiStormtrooper:ZombieStormTrooper{default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Zombieman (ZM66 Semi)"
		//$Sprite "POSSA1"
		accuracy 2;
}}
class ZombieSMGStormtrooper:ZombieStormTrooper{default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Zombieman (SMG)"
		//$Sprite "POSSA1"
		accuracy 3;
}}

class ZombieHideousTrooper:RandomSpawner replaces ZombieMan{
	default{
		dropitem "ZombieStormtrooper",256,100;
		dropitem "EnemyHERP",256,1;
	}
}
class DeadZombieStormtrooper:ZombieStormtrooper replaces DeadZombieMan{
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
	}
	states{
	death.spawndead:
		SPOS A 0;
		POSS A 0 A_CheckFreedoomSprite();
		goto dead;
	}
}
class DeadZombieAutoStormtrooper:DeadZombieStormtrooper{default{accuracy 1;}}
class DeadZombieSemiStormtrooper:DeadZombieStormtrooper{default{accuracy 2;}}
class DeadZombieSMGStormtrooper:DeadZombieStormtrooper{default{accuracy 3;}}



