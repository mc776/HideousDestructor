// ------------------------------------------------------------
// Cyberdemon
// ------------------------------------------------------------
class Roboball:SlowProjectile{
	default{
		+rockettrail
		damage 30;
		speed 72;
		radius 5;height 15;
		missileheight 4;
		gravity 0;
		decal "Scorch";
		seesound "weapons/rocklf";
		scale 0.6;
	}
	override void ExplodeSlowMissile(line blockingline,actor blockingmobj){
		//damage
		if(blockingmobj){
			int dmgg=random(70,240);
			double dangle=angle;
			A_Face(blockingmobj);
			dangle=abs(deltaangle(angle,dangle));
			if(dangle<10)dmgg+=random(2000,4000);
			else if(dangle<30)dmgg+=random(200,1200);

			blockingmobj.damagemobj(self,target,dmgg,"SmallArms3");
		}

		//explosion
		if(!inthesky){
			A_SprayDecal("Scorch",16);
			A_HDBlast(
				blastradius:512,blastdamage:random(128,256),fullblastradius:96,
				pushradius:256,pushamount:256,fullpushradius:96,
				immolateradius:128,immolateamount:random(3,60),
				immolatechance:15
			);

			//hit map geometry
			if(
				blockingline||
				floorz>=pos.z||
				ceilingz-height<=pos.z
			){
				bmissilemore=true;
				if(blockingline)doordestroyer.destroydoor(self,200,frandom(24,48),6,dedicated:true);
			}
		}else DistantNoise.Make(self,"world/rocketfar");
		A_SpawnChunks("HDB_frag",240,300,900);

		//destroy();return;
		bmissile=false;
		setstatelabel("death");
	}
	void A_SatanRoboRocketThrust(){
		if(fuel>0){
			fuel--;
			A_StartSound("weapons/rocklaunch",CHAN_AUTO,CHANF_OVERLAP,0.6);
			A_ChangeVelocity(thrust.x,0,thrust.y,CVF_RELATIVE);
		}else{
			bnogravity=false; //+nogravity is automatically set and causes all subsequent GetGravity() to return 0
			setstatelabel("spawn3");
		}
	}
	int fuel;
	vector2 thrust;
	states{
	spawn:
		TNT1 A 0 nodelay{
			A_StartSound("weapons/rocklf",CHAN_VOICE);
			fuel=100;
			thrust=(cos(pitch),-sin(pitch))*10;
		}
	spawn2:
		MISL A 2 light("ROCKET") A_SatanRoboRocketThrust();
		loop;
	spawn3:
		MISL A 1 light("ROCKET"){
			if(grav>=1.)A_SetTics(-1);
			else{
				gravity+=0.1;
				grav=getgravity();
			}
		}
		wait;
	death:
		TNT1 A 1{
			vel.xy*=0.3;
			for(int i=0;i<3;i++){
				actor xp=spawn("HDExplosion",pos+(frandom(-2,2),frandom(-2,2),frandom(-2,2)),ALLOW_REPLACE);
				xp.vel.z=frandom(1,3);
			}
			A_StartSound("world/explode");
			DistantNoise.Make(self,"world/rocketfar");
			DistantQuaker.Quake(self,4,35,512,10);
		}
		TNT1 A 0 A_SpawnChunks("HDSmokeChunk",random(3,4),2,8);
		TNT1 AAAA 0 A_SpawnItemEx("HDSmoke",
			random(-6,6),random(-6,6),random(-2,6),
			random(-1,5),0,random(0,1),
			random(-5,15)
		);
		TNT1 A 0 A_SpawnChunks("HugeWallChunk",12,4,12);
		TNT1 A 12 A_JumpIf(bmissilemore,"deathsmash");
		stop;
	deathsmash:
		TNT1 A 0 A_SpawnChunks("HugeWallChunk",16,3,8);
		TNT1 A 0 A_SpawnChunks("BigWallChunk",24,5,12);
		TNT1 A 12;
		stop;
	}
}
class Satanball:HDFireball{
	default{
		+extremedeath
		damagetype "balefire";
		activesound "cyber/ballhum";
		seesound "weapons/plasmaf";
		decal "scorch";
		gravity 0;
		height 12;radius 12;
		speed 50;
		scale 0.4;
		damagefunction(256);
	}
	actor lite;
	string pcol;
	override void postbeginplay(){
		super.postbeginplay();
		lite=spawn("SatanBallLight",pos,ALLOW_REPLACE);lite.target=self;
		if(satanrobo(target))satanrobo(target).shields-=40;
		pcol=(Wads.CheckNumForName("id",0)!=-1)?"55 ff 88":"55 88 ff";
	}
	states{
	spawn:
		BFS1 A 0{
			if(stamina>40||!target||target.health<1)return;  
			stamina++;
			actor tgt=target.target;
			if(getage()>144){
				vel+=(frandom(-1,1),frandom(-1,1),frandom(-1,1));
				return;
			}
			if(tgt&&checksight(tgt)){
				vel*=0.92;
				vel+=(tgt.pos-pos+tgt.vel*10+(0,0,tgt.height)).unit()*10;
			}
		}
		BFS1 ABAB 1 bright{
			for(int i=0;i<10;i++){
				A_SpawnParticle(pcol,SPF_RELATIVE|SPF_FULLBRIGHT,35,frandom(1,4),0,
					frandom(-8,8)-5*cos(pitch),frandom(-8,8),frandom(0,8)+sin(pitch)*5,
					frandom(-1,1),frandom(-1,1),frandom(1,2),
					-0.1,frandom(-0.1,0.1),-0.05
				);
			}
			scale=(1,1)*frandom(0.35,0.45);
		}loop;
	death:
		BFE1 A 1 bright{
			spawn("HDSmoke",pos,ALLOW_REPLACE);
			A_StartSound("weapons/bfgx",CHAN_BODY,volume:0.4);
			damagetype="thermal";
			bextremedeath=false;
			A_Explode(64,64);
			if(lite)lite.args[3]=128;
			DistantQuaker.Quake(self,2,35,512,10);

			//hit map geometry
			if(
				blockingline||
				floorz>=pos.z||  
				ceilingz-height<=pos.z
			){
				A_SpawnChunks("HDSmoke",3,2,3);
				A_SpawnChunks("HugeWallChunk",50,4,20);
			}

			//teleport victim
			if(
				blockingmobj
				&&!blockingmobj.player
				&&!blockingmobj.special
				&&(
					!blockingmobj.bismonster
					||blockingmobj.health<1
				)
				&&!random(0,3)
			){
				spawn("TeleFog",blockingmobj.pos,ALLOW_REPLACE);
				blockingmobj.setorigin(level.PickDeathmatchStart(),false);
				blockingmobj.vel=(frandom(-10,10),frandom(-10,10),frandom(10,20));
				spawn("TeleFog",blockingmobj.pos,ALLOW_REPLACE);
			}
		}
		BFE1 BBCDDEEE 2 bright A_FadeOut(0.05);
		stop;
	}
}
class SatanBallLight:PointLight{
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=52;
		bool freedoom=(Wads.CheckNumForName("FREEDOOM",0)!=-1);
		args[1]=freedoom?48:206;
		args[2]=freedoom?206:48;
		args[3]=0;
		args[4]=0;
	}
	override void tick(){
		if(!target){
			args[3]+=random(-10,1);
			if(args[3]<1)destroy();
		}else{
			if(target.bmissile)args[3]=random(32,40);
			else args[3]=random(48,64);
			setorigin(target.pos,true);
		}
	}
}

class SatanRobo:HDMobBase replaces CyberDemon{
	double launcheroffset;
	default{
		height 100;
		radius 32;
		+boss 
		+missilemore
		+floorclip
		+dontmorph
		+bossdeath
		seesound "cyber/sight";
		painsound "cyber/pain";
		deathsound "cyber/death";
		activesound "cyber/active";
		tag "$CC_CYBER";

		+avoidmelee +nofear +seeinvisible +nodropoff
		-noradiusdmg
		+noblooddecals
		+hdmobbase.smallhead
		+hdmobbase.biped
		+hdmobbase.noshootablecorpse
		damagefactor "Thermal", 0.5;
		hdmobbase.shields 8000;
		gibhealth 900;
		health 4000;
		mass 12000;
		speed 15;
		deathheight 110;
		painchance 32;
		painthreshold 200;
		maxtargetrange 0;
		radiusdamagefactor 0.6;
		obituary "%o was experimented upon by a cyberdemon.";
		minmissilechance 196;
	}
	override double bulletresistance(double hitangle){
		return max(0,frandom(0.6,4.0)-hitangle*0.01);
	}
	void A_CyberGunSmoke(){
		A_SpawnItemEx("HDSmoke",
			random(-32,32),random(-32,32),random(46,96),0,
			frandom(2,3),0,frandom(2,4),0,SXF_NOCHECKPOSITION,64
		);
	}
	void A_CyberAdjustLead(){
		oldaim=(angle,pitch);
		A_FaceTarget(12,12,0,0,FAF_MIDDLE);
		aimadjust=(deltaangle(oldaim.x,angle),deltaangle(oldaim.y,pitch));
		if(target)aimadjust*=distance3d(target)*0.0005;
	}
	void A_SatanRoboAttack(double spread=0.,double aimhorz=0.,double aimvert=0.){
		A_StartSound("weapons/bronto",CHAN_WEAPON);
		if(shottype=="Roboball")DistantNoise.Make(self,"world/shotgunfar");
		if(spread){
			aimhorz=frandom(-spread,spread);
			aimvert=frandom(-spread,spread);
		}
		bool tgt=target!=null;
		double dist=max(1,(tgt?distance3d(target):0));
		A_SpawnProjectile(shottype,42,-launcheroffset,
			aimhorz-(tgt?atan(launcheroffset/dist):0),
			CMF_AIMDIRECTION|CMF_SAVEPITCH,
			pitch+aimvert-(dist>2048?dist*0.000001:0)+(tgt?atan(10/dist):0)
		);
	}
	override void tick(){
		super.tick();
		if(
			bnofear&&
			health<1600&&
			!random(0,max(10,health))
		)A_SpawnItemEx("HDSmoke",
			random(-32,32),random(-32,32),random(46,96),
			0,0,random(2,4),0,160,64
		);
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		//cheat
		if(source==self)return 0;

		//Search me, O God, and know my heart; try me, and know my thoughts.
		if(damage==TELEFRAG_DAMAGE)
			return super.damagemobj(inflictor,source,TELEFRAG_DAMAGE,"Telefrag");

		return super.damagemobj(
			inflictor,source,damage,mod,flags,angle
		);
	}
	override void postbeginplay(){
		super.postbeginplay();
		rockets=HDCB_ROCKETMAX;
		shottype="Roboball";
		if(bplayingid)launcheroffset=24;
		hdmobster.spawnmobster(self);
	}
	vector2 oldaim;vector2 aimadjust;
	int rockets;
	class<actor>shottype;
	enum CyberStats{
		HDCB_ROCKETMAX=99,
	}
	states{
	spawn:
		CYBR EEEE 10{
			A_Look();
			angle+=frandom(-5,5);
		}
	spawn2:
		CYBR CDDAA 6{hdmobai.wander(self);}
		CYBR B 0 A_StartSound("spider/walk",15);
		CYBR BB 6{hdmobai.wander(self);}
		CYBR C 6{
			A_StartSound("cyber/hoof",15);
			hdmobai.wander(self);
		}
		CYBR C 0 A_Jump(32,"spawn");
		loop;
	see:
		CYBR E 0{
			if(health<1)setstatelabel("death");
			A_AlertMonsters(0,AMF_TARGETNONPLAYER);
			bfrightening=true;
		}
		CYBR AA 2{
			hdmobai.chase(self);
		}
		CYBR B 5{
			A_StartSound("spider/walk",15);
			hdmobai.chase(self);
		}
		CYBR C 5{
			A_StartSound("cyber/hoof",16);
			hdmobai.chase(self);
		}
		CYBR DD 2{
			hdmobai.chase(self);
		}
		CYBR E 0 A_Jump(56,"see");
		CYBR E 0 A_JumpIfTargetInLOS("missile",0);
		loop;
	pain:
		CYBR G 10{
			A_Pain();
			if(health<3500){
				if(health<3000)minmissilechance-=5;
				if(health>1000)speed++;else speed--;
				speed=clamp(speed,random(1,8),random(20,30));
			}
		}---- A 0 setstatelabel("see");
	missile:
		CYBR A 0 A_JumpIfTargetInLOS("inposition",20);
		CYBR A 4 A_FaceTarget(40,40);
		CYBR B 4{
			A_FaceTarget(40,40);
			A_StartSound("spider/walk",15);
			A_Recoil(-4);
		}
		CYBR C 0 A_JumpIfTargetInLOS("inposition",20);
		CYBR C 4{
			A_FaceTarget(40,40);
			A_StartSound("cyber/hoof",16);
			A_Recoil(-4);
		}
		CYBR D 4 A_FaceTarget(40,40);
		CYBR E random(15,25) A_Recoil(-4);
		CYBR E 0 A_JumpIfTargetInLOS("missile");
		CYBR E 0 A_Jump(128,"spray");
		---- A 0 setstatelabel("see");
	inposition:
		CYBR E 4{
			A_Recoil(1);
			bfrightening=true;
			A_FaceTarget(12,12);
		}
		CYBR E 0 A_Stop();
		CYBR E 0 A_JumpIf(health>1600,3);
		CYBR EE 2 A_CyberGunSmoke();
		CYBR E 4;
		CYBR A 0 A_AlertMonsters(0,AMF_TARGETNONPLAYER);
		CYBR E 0 A_JumpIfTargetInLOS(2,90);
		CYBR E 0 setstatelabel("missile");

		CYBR E 0 A_JumpIf(health>1600,3);
		CYBR EE 2 A_CyberGunSmoke();
		CYBR E 4 A_FaceTarget(12,12);
		CYBR E 0 A_JumpIf(health>1600,3);
		CYBR EE 2 A_CyberGunSmoke();
		CYBR E 0 A_JumpIf(!target,"fireend");
		CYBR E 4 A_SetTics(target?clamp(int(distance2d(target)*0.0003),4,random(4,24)):4);
		CYBR E 0 A_JumpIf(!target,"fireend");
		CYBR A 0{
			double dist=distance3d(target);

			if(rockets>random(0,HDCB_ROCKETMAX*12/10)){
				shottype="Roboball";
				rockets--;
			}else shottype="SatanBall";

			if(dist<1024&&!random(0,7))setstatelabel("spray");
			else if(dist<8192&&!random(0,2))setstatelabel("leadtarget");
			else setstatelabel("directshots");
		}
	leadtarget:
		CYBR F 3 bright light("ROCKET")A_SatanRoboAttack();
		CYBR E 1 A_SetTics(random(1,4));
		CYBR E 0 A_JumpIf(health>1600,3);
		CYBR EE 0 A_CyberGunSmoke();
	leadtarget2:
		CYBR E 8 A_FaceTarget(12,12,0,0,FAF_MIDDLE);
		CYBR F 3 bright light("ROCKET"){
			A_CyberAdjustLead();
			A_SatanRoboAttack(
				0.,frandom(0,2)*aimadjust.x,frandom(0,2)*aimadjust.y
			);
		}
		CYBR E 1 A_SetTics(random(1,8));
		CYBR E 0 A_JumpIf(health>1600,3);
		CYBR EE 0 A_CyberGunSmoke();
	leadtarget3:
		CYBR E 8 A_FaceTarget(12,12,0,0,FAF_MIDDLE);
		CYBR F 3 bright light("ROCKET"){
			A_CyberAdjustLead();
			A_SatanRoboAttack(
				0.,frandom(1,5)*aimadjust.x,frandom(1,5)*aimadjust.y
			);
		}
		goto fireend;

	directshots:
		CYBR F 3 bright light("ROCKET")A_SatanRoboAttack();
		CYBR E 8 A_FaceTarget(12,12,0,0,FAF_MIDDLE);
		CYBR F 3 bright light("ROCKET")A_SatanRoboAttack(0.3);
		CYBR E 8 A_FaceTarget(12,12,0,0,FAF_MIDDLE);
		CYBR F 3 bright light("ROCKET")A_SatanRoboAttack(0.7);
		goto fireend;

	spray:
		CYBR F 3 bright light("ROCKET")A_SatanRoboAttack(1.);
		CYBR E 6 A_FaceTarget(12,12,0,0,FAF_MIDDLE);
		CYBR F 3 bright light("ROCKET")A_SatanRoboAttack(2.);
		CYBR E 6 A_FaceTarget(12,12,0,0,FAF_MIDDLE);
		CYBR F 3 bright light("ROCKET")A_SatanRoboAttack(3.);
	fireend:
		CYBR E 0 A_JumpIf(health>1600,3);
		CYBR EE 2 A_CyberGunSmoke();
		CYBR E 17;
		---- A 0 setstatelabel("see");

	death:
		CYBR G 1 A_Pain();
		CYBR G 0 A_SetSolid();
		CYBR G 12 A_SetShootable();
		CYBR DD 6 A_Recoil(-2);
		CYBR A 12;
		CYBR A 0{
			A_FaceTarget(40,0);
			A_SetAngle(angle+random(-10,10));
			A_StartSound("spider/walk",15);
		}
		CYBR BB 6 A_Recoil(-2);
		CYBR C 12{
			A_FaceTarget(40,0);
			A_StartSound("cyber/hoof",16);
		}
		CYBR A 0{
			A_FaceTarget(40,0);
			angle+=random(-10,10);
		}
		CYBR DD 6 A_Recoil(-2);
		CYBR A 10{
			A_SpawnItemEx("HDExplosionBoss",
				random(-12,12),random(-12,12),random(60,64),
				random(-1,1),random(-1,1),random(1,3)
			);
			A_SpawnItemEx("HDSmokeChunk",
				random(-10,10),random(-10,10),random(38,60), 
				vel.x+random(-6,6),vel.y+random(-6,6),vel.z+random(3,12),
				0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM,144
			);
			A_StartSound("cyber/hoof",16);
		}
		CYBR D 0 A_SpawnItemEx("HDExplosionBoss",
			random(-12,12),random(-12,12),random(60,64),
			random(-1,1),random(-1,1), random(1,3)
		);
		CYBR A 5{
			A_FaceTarget(40,0);
			angle+=random(-10,10);
			A_StartSound("cyber/hoof",16);
		}
		CYBR B 6 A_StartSound("spider/walk",15);
		CYBR B 6{
			A_SpawnItemEx("HDExplosionBoss",
				random(-26,26),random(-26,26),random(60,64),
				random(-1,1),random(-1,1),random(1,3)
			);
			A_SpawnItemEx("HDSmokeChunk",
				random(-10,10),random(-10,10),random(38,60),
				vel.x+random(-6,6),vel.y+random(-6,6),vel.z+random(3,12),
				0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM,144
			);
		}
		CYBR C 16{
			A_FaceTarget(40,0);
			angle+=random(-10,10);
			A_StartSound("cyber/hoof",16);
		}
		CYBR DD 6 A_Recoil(-2);
		CYBR D 6 A_SpawnItemEx("HDExplosionBoss",
			random(-26,26),random(-26,26),random(60,64),
			random(-1,1),random(-1,1),random(1,3)
		);
		CYBR A 20 A_SpawnItemEx("HDSmokeChunk",
			random(-10,10),random(-10,10),random(38,60),
			vel.x+random(-6,6),vel.y+random(-6,6),vel.z+random(3,12),
			0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM,144
		);
		CYBR B 0{
			A_FaceTarget(40,0);
			angle+=random(-10,10);
			A_StartSound("spider/walk",15);
		}
		CYBR BB 6 A_Recoil(-1);
		CYBR C 24{
			A_SpawnItemEx("HDExplosionBoss",
				random(-26,26),random(-26,26),random(70,88),
				random(-1,1),random(-1,1),random(1,3)
			);
			A_StartSound("cyber/hoof",16);
		}
		CYBR E 14{
			A_StartSound("spider/walk",15);
		}
		CYBR EEEE 6 A_FaceTarget(10,0);
		CYBR FF 0 A_SpawnItemEx("HDSmoke",54,-24,52,
			random(-1,1),random(-1,1),random(2,4)
		);
		CYBR FFFFFF 0 A_SpawnItemEx("BigWallChunk",54,-24,52,
			random(4,14),random(-3,3),random(1,4),random(0,360)
		);
		CYBR FFFF 0 A_SpawnItemEx("HugeWallChunk",54,-24,52,
			random(4,24),random(-3,3),random(1,4),random(0,360)
		);
		CYBR F 3 bright A_SpawnItemEx("HDExplosion",54,-24,52);
		CYBR E 56;
		CYBR EEEEEE 4 A_SpawnItemEx("HDSmoke",54,-24,52,
			random(-1,1),random(-1,1),random(2,4)
		);
		CYBR EEEEEE 2 A_SpawnItemEx("HDSmoke",54,-24,52,
			random(-1,1),random(-1,1),random(3,6)
		);
	xdeath:
		CYBR E 0 A_UnSetSolid();
		CYBR E 0 A_UnSetShootable();
		CYBR EEEEEE 1 A_SpawnItemEx("HDSmoke",54,-24,52,
			random(-1,1),random(-1,1),random(4,8)
		);
		CYBR H 6 A_Scream();
		CYBR H 2 bright A_SpawnItemEx("HDExplosion",
			random(-26,26),random(-26,26),random(56,64),
			random(-1,1),random(-1,1),random(1,3)
		);
		CYBR H 3 bright A_SpawnItemEx("HDExplosionBoss",
			random(-36,36),random(-36,36),random(40,46),
			random(-1,1),random(-1,1),random(1,3)
		);
		CYBR H 1 bright A_SpawnItemEx("HDExplosion",
			random(-26,26),random(-46,46),random(30,36),
			random(-1,1),random(-1,1),random(1,3)
		);
		CYBR I 2{
			A_Explode(512,16);
			DistantQuaker.Quake(self,8,140,4096,7,400,666,256);
		}

		CYBR AAAAAAA 0 A_SpawnItemEx("HDSmokeChunk",
			random(-10,10),random(-10,10),random(38,60),
			random(-6,6),random(-6,6),random(3,12)
		);
		CYBR I 2 bright A_SpawnItemEx("HDExplosionBoss",
			random(-36,36),random(-26,26),random(60,78),
			random(-1,1),random(-1,1),random(1,3)
		);
		CYBR I 2 bright A_SpawnItemEx("HDExplosion",
			random(-36,36),random(-26,26),random(50,68),
			random(-1,1),random(-1,1),random(1,3)
		);
		CYBR I 3 bright A_SpawnItemEx("HDExplosion",
			random(-26,26),random(-26,26),random(75,82),
			random(-1,1),random(-1,1),random(1,3)
		);

		CYBR AA 0 A_SpawnItemEx("CyberGibs",
			random(-10,10),random(-10,10),random(38,60),
			random(-6,6),random(-6,6),random(3,12)
		);
		CYBR AA 0 A_SpawnItemEx("HDSmokeChunk",
			random(-10,10),random(-10,10),random(38,60),
			random(-6,6),random(-6,6),random(6,12)
		);

		CYBR J 3 bright A_SpawnItemEx("HDExplosionBoss",
			random(-26,26),random(-46,46),random(45,52),
			random(-1,1),random(-1,1),random(1,3)
		);
		CYBR AA 0 A_SpawnItemEx("CyberGibs",
			random(-10,10),random(-10,10),random(38,60),
			random(-6,6),random(-6,6),random(3,12)
		);
		CYBR J 3 bright A_SpawnItemEx("HDExplosion",
			random(-36,36),random(-26,26),random(64,82),
			random(-1,1),random(-1,1),random(1,3)
		);
		CYBR J 3 bright A_SpawnItemEx("HDExplosionBoss",
			random(-36,36),random(-26,26),random(45,82),
			random(-1,1),random(-1,1),random(1,3)
		);

		CYBR KK 0 A_SpawnItemEx("CyberGibs",
			random(-10,10),random(-10,10),random(38,60),
			random(-6,6),random(-6,6),random(3,12)
		);
		CYBR KK 0 A_SpawnItemEx("HDSmokeChunk",
			random(-10,10),random(-10,10),random(38,60),
			random(-6,6),random(-6,6),random(3,12)
		);

		CYBR K 4 bright A_SpawnItemEx("HDExplosion",
			random(-36,36),random(-46,46),random(48,62),
			random(-1,1),random(-1,1),random(1,3)
		);
		CYBR K 4 A_SpawnItemEx("HDExplosionBoss",
			random(-66,66),random(-66,66),random(15,42),
			random(-1,1),random(-1,1),random(1,3)
		);

		CYBR L 4 A_SpawnItemEx("HDExplosion",
			random(-36,36),random(-36,36),random(62,82),
			random(-1,1),random(-1,1),random(1,3)
		);
		CYBR L 1 A_SpawnItemEx("HDExplosionBoss",
			random(-16,16),random(-16,16),random(75,82),
			random(-1,1),random(-1,1),random(1,3)
		);

		CYBR LL 0 A_SpawnItemEx("HDSmokeChunk",
			random(-10,10),random(-10,10),random(38,60),
			random(-6,6),random(-6,6),random(3,12)
		);

		CYBR LLLL 3 A_SpawnItemEx("HDSmoke",
			random(-36,36),random(-36,36),random(24,80),
			random(-1,1),random(-1,1),random(3,6)
		);

		CYBR M 0 A_NoBlocking();
		CYBR MMMM 2 A_SpawnItemEx("HDSmoke",
			random(-20,20),random(-20,20),random(24,80),
			random(-1,1),random(-1,1),random(2,4)
		);
		CYBR O 0 a_spawnitemex("CyberRemains",flags:SXF_NOCHECKPOSITION|SXF_SETMASTER);

		CYBR PPPP 4 A_SpawnItemEx("HDSmoke",
			random(-26,26),random(-26,26),random(12,40),
			random(-1,1),random(-1,1),random(1,3)
		);
		CYBR PPPPPPPPPPPPPPPPP 1 A_SpawnItemEx("HDSmoke",
			random(-26,26),random(-26,26),random(32,60),
			random(-2,2),random(-2,2),random(1,6)
		);
		CYBR PPPPPPPPPPPPPPPP 5 A_SpawnItemEx("HDSmoke",
			random(-26,26),random(-26,26),random(1,14),
			random(-1,1),random(-1,1),random(2,6),random(0,255)
		);
		CYBR P 200{bnofear=false;}
		CYBR P -1 A_BossDeath();
		stop;

	//And see if there be any wicked way in me, and lead me in the way everlasting.
	death.telefrag:
		TNT1 A 100{
			bnofear=false;
			A_Pain();
			A_NoBlocking();
			A_SpawnItemEx("TeleFog",flags:SXF_NOCHECKPOSITION);
		}
		TNT1 A 200 A_Scream();
		TNT1 A 0 A_BossDeath();
		stop;
	}
}


class CyberRemains:Actor{
	default{
		renderstyle "add";
		radius 32;height 16;
		+shootable +ghost
	}
	int smokelag;
	override void postbeginplay(){
		super.postbeginplay();
		A_Die();
	}
	override void die(actor source,actor inflictor,int dmgflags){
		super.die(source,inflictor,dmgflags);
		bshootable=true;
		HDF.Give(Self,"Heat",6666);
	}
	override void tick(){
		if(master)setorigin(master.pos,true);
		super.tick();
	}
	states{
	spawn:
	death:
		CYBR NO 4;
	spawn2:
		---- AA 1 A_SpawnItemEx("HDSmoke",
			random(-30,30),random(-30,30),random(12,14),
			random(-1,1),random(-1,1),0,
			0,SXF_NOCHECKPOSITION
		);
		---- A 0 A_StartSound("misc/firecrkl",CHAN_AUTO,volume:1.0-(smokelag*0.005));
		---- AAA 0 A_SpawnItemEx("HDFlameRed",
			random(-66,66),random(-56,56),random(12,14),
			random(-1,1),random(-1,1),random(1,3),
			0,SXF_NOCHECKPOSITION
		);
		---- A 0 A_SpawnItemEx("HDSmokeChunk",
			random(-30,30),random(-30,30),random(4,12),
			random(-3,3),random(-3,3),random(2,8),
			0,SXF_NOCHECKPOSITION,160+smokelag
		);
		---- AAA 0 A_SpawnItemEx("HugeWallChunk",
			random(-30,30),random(-30,30),random(4,12),
			random(-6,6),random(-6,6),random(5,12),
			0,SXF_NOCHECKPOSITION,64+smokelag/2
		);
		---- A 0{
			A_SetTics(random(1,smokelag/7));
			smokelag++;
			if(alpha>0.2)alpha-=0.04;
			else A_FadeOut(0.001);
		}
		---- A 0 A_JumpIf(alpha<0.2,1);
		loop; //NOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
	spawn3:
		CYBR P 0;
		goto spawn2;
		CYBR E 0;
		stop;
	}
}
class CyberGibs:HDActor{
	default{
		+corpse +noblockmap
		+shootable
		radius 20;height 16;
	}
	void A_CyberGibTrail(){
		HDF.Give(Self,"Heat",666);
		for(int i=0;i<20;i++){
			A_SpawnParticle("66 00 00",
				0,random(70,100),frandom(3.,8.),0,
				frandom(-6,6),frandom(-6,6),frandom(3,6),
				frandom(-1,1),frandom(-1,1),frandom(3,6),
				-0.1,frandom(-0.1,0.1),-0.3
			);
			A_SpawnParticle("ff ed 40",
				0,random(40,70),frandom(2.,3.),0,
				frandom(-6,6),frandom(-6,6),frandom(2,4),
				frandom(-1,1),frandom(-1,1),frandom(0,4),
				-0.1,frandom(-0.1,0.1),-0.01
			);
			A_SpawnParticle("36 30 30",
				0,random(70,100),frandom(7.,10.),0,
				frandom(-12,12),frandom(-12,12),frandom(4,6),
				0,0,frandom(1.,3.),
				frandom(-0.05,0.05),frandom(-0.05,0.05),-0.005
			);
		}
	}
	void A_CyberGibSplat(){
		for(int i=0;i<20;i++){
			A_SpawnParticle("66 00 00",
				0,random(50,80),frandom(3.,8.),0,
				frandom(-6,6),frandom(-6,6),frandom(0,4),
				frandom(-3,3),frandom(-3,3),frandom(0,4),
				-0.1,frandom(-0.1,0.1),-0.3
			);
			if(!i%5)A_SpawnParticle("36 36 36",
				0,random(50,80),frandom(24.,48.),0,
				frandom(-12,12),frandom(-12,12),frandom(0,3),
				0,0,frandom(1.,3.),
				frandom(-0.05,0.05),frandom(-0.05,0.05),-0.005
			);
		}
		return;
	}
	void A_CyberGibFade(){
		for(int i=0;i<20*alpha;i++){
			A_SpawnParticle("66 00 00",
				0,50,frandom(3.,12.),0,
				frandom(-12,12),frandom(-12,12),frandom(0,8),
				frandom(-3,3),frandom(-3,3),frandom(0,4),
				-0.1,frandom(-0.1,0.1),-0.3
			);
		}
		if(heat.getamount(self)<20)A_FadeOut(0.07);
		A_SpawnItemEx("HDSmokeChunk",
			frandom(-3,3),frandom(-3,3),2,
			vel.x+frandom(-6,6),vel.y+frandom(-6,6),vel.z+frandom(5,10),
			0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
		);
	}
	states{
	spawn:
		POSS O 5 nodelay A_SetScale(randompick(-1,1),frandom(0.9,1.2));
		POSS P 2 A_CyberGibTrail();
		wait;
	crash:
		POSS QQ 1 A_SpawnItemEx("HDExplosion",
			random(-3,3),random(-3,3),2,vel.x,vel.y,vel.z+1,
			0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
		);
		POSS QRRSSTT 2 A_CyberGibSplat();
		POSS U 6 A_CyberGibFade();
		wait;
	}
}
