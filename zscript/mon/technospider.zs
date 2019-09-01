// ------------------------------------------------------------
// Arachnotron
// ------------------------------------------------------------
class TechnoSpider:HDMobBase replaces Arachnotron{
	default{
		health 500;
		height 52;
		radius 32;
		mass 600;
		painchance 128;
		+floorclip
		+bossdeath
		seesound "baby/sight";
		painsound "baby/pain";
		deathsound "baby/death";
		activesound "baby/active";
		tag "$fn_arach";
		+dontharmspecies +missilemore
		obituary "%o was fried by the Wrath of Krang.";
		speed 16;
		deathheight 18;
		dropitem "Putto",8;
		+noblooddecals bloodtype "NotQuiteBloodSplat";
		damagefactor "SmallArms0",0.8;
		damagefactor "SmallArms1",0.8;
		damagefactor "SmallArms2",0.9;
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(health>0){
			if(countinv("VileCount"))return super.damagemobj(
				inflictor,source,health+1,
				"NeedMoreVile",DMG_THRUSTLESS|DMG_NO_PAIN
			);
		}
		return super.damagemobj(
			inflictor,source,damage,mod,flags,angle
		);

	}
	override void postbeginplay(){
		super.postbeginplay();
		hdmobster.spawnmobster(self);
		battery=20;
		hasdropped=false;
		alt=random(0,1);
	}
	int battery;
	bool hasdropped;
	bool alt;
	void A_ThunderZap(){
		if(battery<1){
			setstatelabel("mustreload");
			return;
		}
		thunderbuster.thunderzap(self,32,alt,battery);
		if(!random(0,(alt?5:15)))battery--;
	}
	states{
	ambushrotate:
		---- A 0 A_PlaySound("baby/walk");
		BSPI A 8 A_Look();
		BSPI B 8 A_SetAngle(angle+frandom(-12,12));
		BSPI C 8 A_Look();
		BSPI D 8 A_SetAngle(angle+frandom(-12,12));
	ambush:
		BSPI C 10 A_Look();
		---- A 0 A_Jump(28,"ambushrotate");
	spawn:
		BSPI A 0 A_JumpIf(bambush,"ambush");
		BSPI CCC 10 A_Look();
		---- A 0 A_Jump(192,"spawn","ambushrotate");
	spawnwander:
		---- A 0 A_PlaySound("baby/walk");
		BSPI ABC 8{hdmobai.wander(self);}
		---- A 0 A_SetAngle(angle+frandom(-8,8));
		---- A 0 A_PlaySound("baby/walk");
		BSPI DEF 8{hdmobai.wander(self);}
		---- A 0 A_SetAngle(angle+frandom(-8,8));
		---- A 0 A_Jump(28,"spawn");
		loop;

	see:
		---- A 0 {
			if(A_JumpIfCloser(500,"null")){
				bmissilemore=false;
				bfrightened=true;
				alt=true;
			}else{
				bmissilemore=true;
				bfrightened=false;
				alt=false;
			}
			bambush=0;
			A_PlaySound("baby/walk");
		}
		BSPI AB 5{hdmobai.chase(self);}
		---- A 0 A_PlaySound("baby/walk");
		BSPI CD 5{hdmobai.chase(self);}
		---- A 0 A_PlaySound("baby/walk");
		BSPI EF 5{hdmobai.chase(self);}
		---- A 0 A_JumpIfTargetInLOS("see");
	roam:
		---- A 0 A_PlaySound("baby/walk");
		BSPI AB 6 {hdmobai.wander(self,true);}
		---- A 0 A_PlaySound("baby/walk");
		BSPI C 6 {hdmobai.wander(self,true);}
		---- A 0 A_Jump(48,"roamc");
	roam2:
		BSPI A 6 {hdmobai.wander(self,true);}
		---- A 0 A_PlaySound("baby/walk");
		BSPI EF 6 {hdmobai.wander(self,true);}
		---- A 0 A_Jump(48,"roamf");
		---- A 0 A_JumpIfTargetInLOS("roamc");
		goto roam;
	roamc:
		BSPI CC 2 A_Chase("missile","missile",CHF_DONTMOVE);
		BSPI CCCCCC 1 A_Chase("missile","missile",CHF_DONTMOVE);
		---- A 0 A_Jump(48,1);
		loop;
		---- A 0 A_PlaySound("baby/walk");
		goto roam2;
	roamf:
		BSPI FF 2 A_Chase("missile","missile",CHF_DONTMOVE);
		BSPI FFFFFF 1 A_Chase("missile","missile",CHF_DONTMOVE);
		---- A 0 A_Jump(48,"roam");
		loop;

	missile:
		---- A 0 A_JumpIfTargetInLOS("shoot",15);
		---- A 0 A_JumpIfTargetInLOS(1);
		goto see;
		---- A 0 A_PlaySound("baby/walk");
		BSPI AA 3 A_FaceTarget(20,0);
		---- A 0 A_JumpIfTargetInLOS("shoot",15);
		---- A 0 A_JumpIfTargetInLOS(1);
		goto see;
		BSPI BB 3 A_FaceTarget(20,0);
		---- A 0 A_JumpIfTargetInLOS("shoot",15);
		---- A 0 A_JumpIfTargetInLOS(1);
		goto see;
		---- A 0 A_PlaySound("baby/walk");
		BSPI CC 3 A_FaceTarget(20,0);
		---- A 0 A_JumpIfTargetInLOS("shoot",15);
		---- A 0 A_JumpIfTargetInLOS(1);
		goto see;
		BSPI DD 3 A_FaceTarget(20,0);
		---- A 0 A_JumpIfTargetInLOS("shoot",15);
		---- A 0 A_JumpIfTargetInLOS(1);
		goto see;
		---- A 0 A_PlaySound("baby/walk");
		BSPI EE 3 A_FaceTarget(20,0);
		---- A 0 A_JumpIfTargetInLOS("shoot",15);
		---- A 0 A_JumpIfTargetInLOS(1);
		goto see;
		BSPI FF 3 A_FaceTarget(20,0);
		loop;
	shoot:
		---- A 0 A_JumpIfInventory("VileCount",1,"NotVileEnough");
		---- A 0 A_JumpIf(!hdmobai.tryshoot(self,32,256,1,1),"roam");
		BSPI A 10 A_FaceTarget(20,20,z_ofs:(alt?0:frandom(10,-60)));
	shootpb:
		BSPI A 10{alt=(target&&distance3d(target)<666);}
		BSPI GGGGG 3 bright light("PLAZMABX2")A_PlaySound("weapons/plasidle",CHAN_WEAPON);
	shootpb2:
		BSPI GGGGGGGGGGGGG 2 bright light("PLAZMABX2")A_ThunderZap();
		---- A 0 A_JumpIfTargetInLOS("shoot",3);
		goto see;
		---- A 0 A_Jump(48,"shootpb2");
		goto see;
	mustreload:
		BSPI H 10 A_Pain();
	reload:
		BSPI A 8 A_PlaySound("baby/walk",CHAN_BODY);
		BSPI A 20 A_PlaySound("baby/walk",CHAN_WEAPON);
		BSPI A 0 {battery=20;}
		goto see;
	pain:
		BSPI I 3;
		BSPI I 3 A_Pain;
		goto see;
	death:
		---- AAAAAAAA 0 A_SpawnItemEx("HugeWallChunk",frandom(-4,4),frandom(-4,4),frandom(28,34),frandom(-6,6),frandom(-6,6),frandom(-2,16),0,160,0);
		---- AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 A_SpawnItemEx("BigWallChunk",frandom(-3,3),frandom(-3,3),frandom(28,34),frandom(-2,2),frandom(-2,2),frandom(2,14),0,160,0);
		BSPI J 4 A_Scream();
		BSPI J 6 A_SpawnItemEx("MegaBloodSplatter",frandom(-10,10),frandom(-10,10),32,0,0,0,0,160,0);
		BSPI J 10 A_SpawnItemEx("MegaBloodSplatter",frandom(-4,4),frandom(-4,4),32,0,0,0,0,160,0);
		---- A 0{
			if(!hasdropped){
				hasdropped=true;
				let mmm=HDMagAmmo.SpawnMag(self,"HDBattery",battery);
				mmm.vel=vel+(frandom(-1,1),frandom(-1,1),1);
			}
		}
		BSPI KLMN 7 A_SpawnItemEx("MegaBloodSplatter",0,0,28,0,0,0,0,160,0);
		---- A 0 A_SpawnItemEx("MegaBloodSplatter",0,0,14,0,0,0,0,160,0);
		BSPI O 7;
		---- A 0 A_JumpIfInventory("VileCount",1,"NeededMoreVile");
		BSPI P -1 A_BossDeath();
	xdeath:
		stop;
	raise:
		BSPI PONMLKJ 5;
		---- A 0 A_JumpIfInventory("VileCount",3,"ReallyRaise");
		BSPI I 8;
		BSPI I 0 A_PlaySound("baby/sight");
		BSPI AAABB 3 A_Chase("NotVileEnough","NotVileEnough");
	notvileenough:
		BSPI I 0 A_Die();
	neededmorevile:
		BSPI P -1;
	reallyraise:
		BSPI I 5 A_TakeInventory("VileCount");
		BSPI I 0{
			A_PlaySound("baby/sight");
			if(!random(0,3))hasdropped=false;
		}goto see;
	}
}
