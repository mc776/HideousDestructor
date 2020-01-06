// ------------------------------------------------------------
// Pain Lord/Pain Bringer common
// ------------------------------------------------------------
class PainMonster:HDMobBase{
	default{
		meleesound "baron/melee";
		bloodcolor "44 99 22";
		+hdmobbase.biped
		species "BaronOfHell";
	}
	override void postbeginplay(){
		super.postbeginplay();
		bsmallhead=bplayingid;
	}
	override double bulletresistance(double hitangle){
		return super.bulletresistance(hitangle);
//		return max(0,frandom(0.1,2.0)-hitangle*0.01);
	}
}

// ------------------------------------------------------------
// Pain Lord
// ------------------------------------------------------------
class PainLord:PainMonster replaces BaronofHell{
	default{
		height 64;
		radius 17;
		mass 1000;
		+bossdeath
		seesound "baron/sight";
		painsound "baron/pain";
		deathsound "baron/death";
		activesound "baron/active";
		obituary "$ob_baron";
		hitobituary "$ob_baronhit";
		tag "$CC_BARON";

		+missilemore +seeinvisible +dontharmspecies
		maxtargetrange 65536;
		damagefactor "thermal",0.8;
		damagefactor "smallarms0",0.86;
		damagefactor "smallarms1",0.95;
		damagefactor "balefire",0.3;
		meleedamage 12;
		meleerange 58;
		health BE_HPMAX;
		speed 6;
		painchance 4;
		hdmobbase.shields 2000;
	}
	void A_BaronSoul(){
			let aaa=FlyingSkull(spawn("FlyingSkull",pos,ALLOW_REPLACE));
			aaa.addz(32);
			aaa.master=self;
			aaa.target=target;
			aaa.angle=angle;
			aaa.pitch=pitch;
			aaa.spitter=self;
			aaa.vel=vel;
			aaa.A_SkullLaunch();
			shields-=66;
	}
	enum BaronStats{
		BE_HPMAX=1000,
		BE_OKAY=BE_HPMAX*7/10,
		BE_BAD=BE_HPMAX*3/10,
	}

	override double bulletshell(vector3 hitpos,double hitangle){
		return frandom(3,12);
	}
	override double bulletresistance(double hitangle){
		return max(0,frandom(0.8,1.)-hitangle*0.008);
	}
	override void postbeginplay(){
		super.postbeginplay();
		hdmobai.resize(self,0.95,1.05);
	}
	states{
	spawn:
		BOSS AA 8 A_Look();
		BOSS A 1 A_SetTics(random(1,16));
		BOSS BB 8 A_Look();
		BOSS B 1 A_SetTics(random(1,16));
		BOSS CC 8 A_Look();
		BOSS C 1 A_SetTics(random(1,16));
		BOSS DD 8 A_Look();
		BOSS D 1 A_SetTics(random(1,16));
		TNT1 A 0 A_Jump(216,"spawn");
		TNT1 A 0 A_StartSound("baron/active",CHAN_VOICE);
		loop;
	see:
		TNT1 A 0 A_AlertMonsters();
		BOSS ABCD 6{
			hdmobai.chase(self);
		}
		TNT1 A 0 A_JumpIfTargetInLOS("see");
		goto roam;
	roam:
		TNT1 A 0 A_AlertMonsters();
		TNT1 A 0 A_JumpIfTargetInLOS("missile");
		BOSS ABCD 8{
			hdmobai.wander(self,true);
		}
		loop;
	missile:
		BOSS ABCD 3{
			A_FaceTarget(30);
			if(A_JumpIfTargetInLOS("shoot",10))setstatelabel("shoot");
		}
		BOSS E 0 A_JumpIfTargetInLOS("missile");
		---- A 0 setstatelabel("see");
	shoot:
		BOSS E 0 A_AlertMonsters(0,AMF_TARGETNONPLAYER);
		BOSS E 0 A_Jump(64,2);
		BOSS E 0 A_JumpIfCloser(420,"MissileSweep");
		BOSS E 0 A_JumpIfHealthLower(BE_OKAY,1);
		goto MissileFuckYou;
		BOSS E 0 A_JumpIfHealthLower(BE_BAD,"MissileFuckYou");
		BOSS E 0 A_Jump(16,"MissileFuckYou");
		BOSS E 0 A_Jump(256,"MissileSkull","MissileMissile");
	MissileSkull:
		BOSS H 12 A_FaceTarget(0,0);
		BOSS H 12 bright{
			if(!random(0,2)){A_SpawnProjectile("BelphBall",28,0,0,2,pitch);}
			else A_BaronSoul();
		}
		BOSS H 18;
		goto MissileSweep;
	MissileMissile:
		BOSS H 16 A_FaceTarget(20,20);
		BOSS H 0 bright A_SpawnProjectile("BaleBall",38,0,2,0,0);
		BOSS H 6 bright A_SpawnProjectile("BaleBall",38,0,-2,0,0);
		BOSS H 0 bright A_SpawnProjectile("MiniBBall",46,0,9,2,0);
		BOSS H 6 bright A_SpawnProjectile("MiniBBall",46,0,-9,2,0);
		BOSS H 0 bright A_SpawnProjectile("MiniBBall",56,0,17,2,4);
		BOSS H 6 bright A_SpawnProjectile("MiniBBall",56,0,-17,2,4);
		BOSS H 0 bright A_SpawnProjectile("MiniBBall",66,0,24,2,7);
		BOSS H 6 bright A_SpawnProjectile("MiniBBall",66,0,-24,2,7);
		BOSS H 12;
		---- A 0 setstatelabel("see");
	MissileFuckYou:
		BOSS H 18 A_FaceTarget(20,20);
		BOSS H 0 bright A_SpawnProjectile("BaleBall",38,0,2,0,0);
		BOSS H 0 bright A_SpawnProjectile("BaleBall",38,0,-2,0,0);
		BOSS H 0 bright A_SpawnProjectile("MiniBBall",46,0,5,2,0);
		BOSS H 6 bright A_SpawnProjectile("MiniBBall",46,0,-5,2,0);
		BOSS H 0 bright A_SpawnProjectile("MiniBBall",56,0,7,2,4);
		BOSS H 6 bright A_SpawnProjectile("MiniBBall",56,0,-7,2,4);
		BOSS H 0 bright A_SpawnProjectile("MiniBBall",66,0,12,2,7);
		BOSS H 6 bright A_SpawnProjectile("MiniBBall",66,0,-12,2,7);
		BOSS H 12 bright{
			if(random(0,3))A_SpawnProjectile("BelphBall",28,0,0,2,pitch);
			else A_BaronSoul();
		}
		---- A 0 setstatelabel("see");
	pain:
		BOSS H 6 A_Pain();
		BOSS H 3 A_Jump(116,"see","MissileSkull");
	MissileSweep:
		BOSS F 4 A_FaceTarget(20,20);
		BOSS E 6;
		BOSS E 2 A_SpawnProjectile("MiniBBall",56,6,-6,CMF_AIMDIRECTION,pitch);
		BOSS F 2 A_SpawnProjectile("MiniBBall",46,4,-3,CMF_AIMDIRECTION,pitch);
		BOSS F 2 A_SpawnProjectile("MiniBBall",38,0,-1,CMF_AIMDIRECTION,pitch);
		BOSS G 2 A_SpawnProjectile("MiniBBall",32,0,1,CMF_AIMDIRECTION,pitch);
		BOSS G 2 A_SpawnProjectile("MiniBBall",32,0,3,CMF_AIMDIRECTION,pitch);
		BOSS G 2 A_SpawnProjectile("MiniBBall",32,0,6,CMF_AIMDIRECTION,pitch);
		BOSS G 6;
		BOSS E 2 A_Jump(194,"see");
		loop;
	melee:
		BOSS E 6 A_FaceTarget();
		BOSS F 2;
		BOSS G 6 A_CustomMeleeAttack(random(40,120),"baron/melee","","claws",true);
		BOSS F 5 A_JumpIf(target&&distance3d(target)>84,"missilesweep");
		---- A 0 setstatelabel("see");
	death.telefrag:
		TNT1 A 0 spawn("Telefog",pos,ALLOW_REPLACE);
		TNT1 A 0 A_NoBlocking();
		TNT1 AAAAA 0 A_SpawnItemEx("BFGNecroShard",
			frandom(-4,4),frandom(-4,4),frandom(6,24),
			frandom(1,6),0,frandom(1,3),
			frandom(0,360),SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS|SXF_SETMASTER
		);
		stop;
	death:
		---- A 0{bodydamage+=666*5;}
		---- A 0 A_Quake(2,64,0,600);
		BOSS I 2 A_SpawnItemEx("BFGNecroShard",0,0,20,10,0,8,45,SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS);
		BOSS I 2 A_SpawnItemEx("BFGNecroShard",0,0,35,10,0,8,135,SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS);
		BOSS I 2 A_SpawnItemEx("BFGNecroShard",0,0,50,10,0,8,225,SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS);
		BOSS I 2 A_SpawnItemEx("BFGNecroShard",0,0,65,10,0,8,315,SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS);
		BOSS J 8 A_Scream();
		BOSS K 8;
		BOSS L 8 A_NoBlocking();
		BOSS M 8;
		BOSS N 8;
		BOSS OOOOO 6;
		BOSS O -1 A_BossDeath();
		stop;
	death.maxhpdrain:
		BOSS J 5 A_StartSound("misc/gibbed",CHAN_BODY);
		BOSS K 5;
		BOSS L 5 A_NoBlocking();
		BOSS MN 5;
		BOSS O -1;
	raise:
		BOSS ONMLKJI 5;
		BOSS H 8;
		BOSS AB 6{hdmobai.wander(self,true);}
		goto checkraise;
	}
}


class BelphBall:FastProjectile{
	default{
		+forcexybillboard +seekermissile +hittracer
		damagetype "thermal";
		decal "bigscorch";
		renderstyle "soultrans";
		alpha 0.05;
		scale 0.6;
		radius 12;
		height 13;
		speed 2;
		damage 8;
		seesound "skull/melee";
		deathsound "baron/bigballx";
	}
	states{
	spawn:
		SKUL JIHGF 3 bright A_FadeIn(0.2);
		SKUL F 0 bright A_ScaleVelocity(32);
	see:
		SKUL C 2 bright;
		SKUL C 1 bright A_SpawnItemEx("ImpBallTail",-6,0,12,vel.x*0.8,vel.y*0.8,vel.z*0.8,0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		SKUL D 2 bright;
		SKUL D 1 bright A_SpawnItemEx("ImpBallTail",-6,0,12,vel.x*0.8,vel.y*0.8,vel.z*0.8,0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		loop;
	death:
		SKUL FFFFFF 0 A_SpawnItemEx("HDSmoke",0,0,random(-2,4),frandom(-2,2),frandom(-2,2),random(3,5),0,SXF_NOCHECKPOSITION);
		SKUL F 1 bright A_Quake(3,28,0,128);
		SKUL G 1 bright A_Explode(56,96,1);
		SKUL GGGGGGGGGGG 0 A_SpawnItemEx("BigWallChunk",0,0,random(-4,4),random(-10,10),random(-10,10),random(-2,10),random(0,360),SXF_NOCHECKPOSITION);
		SKUL HIJ 1 bright A_FadeOut(0.2);
		TNT1 AAAAA random(2,3) A_SpawnItemEx("HDSmoke",0,0,random(-2,4),frandom(-2,2),frandom(-2,2),random(3,5),0,SXF_NOCHECKPOSITION);
		stop;
	}
}

class MiniBBallTail:HDActor{
	default{
		+nointeraction
		+forcexybillboard
		renderstyle "add";
		alpha 0.6;
		scale 0.7;
	}
	states{
	spawn:
		BAL7 E 2 bright A_FadeOut(0.2);
		TNT1 A 0 A_StartSound("baron/ballhum",volume:0.4,attenuation:6.);
		loop;
	}
}

class MiniBBall:HDActor{
	default{
		+forcexybillboard
		projectile;
		+seekermissile
		damagetype "balefire";
		renderstyle "add";
		decal "gooscorch";
		alpha 0.8;
		scale 0.6;
		radius 4;
		height 6;
		speed 16;
		damage 6;
		seesound "baron/attack";
		deathsound "baron/shotx";
	}
	int user_counter;
	states{
	spawn:
		BAL7 EDC 1 bright;
		BAL7 ABABA 2 bright;
		BAL7 BAB 3 bright;
	spawn2:
		BAL7 A 2 bright A_SeekerMissile(5,10);
		BAL7 B 2 bright A_SpawnItemEx("MiniBBallTail",-3,0,3,3,0,random(1,2),0,161,0);
		BAL7 A 2 bright A_SeekerMissile(5,9);
		BAL7 B 2 bright A_SpawnItemEx("MiniBBallTail",-3,0,3,3,0,random(1,2),0,161,0);
		BAL7 A 2 bright A_SeekerMissile(4,8);
		BAL7 B 2 bright A_SpawnItemEx("MiniBBallTail",-3,0,3,3,0,random(1,2),0,161,0);
		BAL7 A 2 bright A_SeekerMissile(3,6);
		BAL7 B 2 bright A_SpawnItemEx("MiniBBallTail",-3,0,3,3,0,random(1,2),0,161,0);
	spawn3:
		TNT1 A 0 A_JumpIf(user_counter>4,"spawn4");
		TNT1 A 0 {user_counter++;}
		BAL7 A 3 bright A_SeekerMissile(1,1);
		BAL7 B 3 bright A_SpawnItemEx("MiniBBallTail",-3,0,3,3,0,random(1,2),0,161,0);
		loop;
	spawn4:
		BAL7 A 3 bright A_SpawnItemEx("MiniBBallTail",-3,0,3,3,0,random(1,2),0,161,0);
		TNT1 A 0 A_JumpIf(pos.z-floorz<10,2);
		BAL7 B 3 bright A_ChangeVelocity(frandom(-0.2,1),frandom(-1,1),frandom(-1,0.9),CVF_RELATIVE);
		loop;
		BAL7 B 3 bright A_ChangeVelocity(frandom(-0.2,1),frandom(-1,1),frandom(-0.6,1.9),CVF_RELATIVE);
		loop;
	death:
		BAL7 CDE 4 bright A_FadeOut(0.2);
		stop;
	}
}
