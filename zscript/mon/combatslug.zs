// ------------------------------------------------------------
// Mancu, mancu very much.
// ------------------------------------------------------------
class manjuicelight:PointLight{
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=164;
		args[1]=66;
		args[2]=18;
		args[3]=0;
		args[4]=0;
	}
	override void tick(){
		if(!target){
			args[3]+=random(-20,4);
			if(args[3]<1)destroy();
		}else{
			setorigin(target.pos,true);
			if(target.bmissile)args[3]=random(28,44);
			else args[3]=random(32,64);
		}
	}
}
class manjuiceburner:PersistentDamager{
	default{
		height 24;radius 48;stamina 6;
		damagetype "thermal";
	}
}
class manjuice:hdfireball{
	default{
		missiletype "HDSmoke";
		damagetype "thermal";
		activesound "misc/firecrkl";
		decal "scorch";
		gravity 0.1;
		speed 27;
		radius 7;
		height 8;
	}
	actor trailburner;
	override void ondestroy(){
		if(trailburner)trailburner.destroy();
		super.ondestroy();
	}
	states{
	spawn:
		MANF A 0 nodelay{
			actor mjl=spawn("manjuicelight",pos+(0,0,16),ALLOW_REPLACE);mjl.target=self;
			trailburner=spawn("manjuiceburner",pos,ALLOW_REPLACE);
			trailburner.target=target;trailburner.master=self;
		}
		MANF AABBAABB 1 A_FBTail();
	spawn2:
		MANF AB 2 A_FBFloat();
		loop;
	death:
		MISL B 0{
			vel.z+=1.;
			A_HDBlast(
				128,66,16,"thermal",
				immolateradius:frandom(96,196),random(20,90),42,
				false
			);
			A_SpawnChunks("HDSmokeChunk",random(2,4),6,20);
			A_StartSound("misc/fwoosh",CHAN_WEAPON);
			scale=(0.9*randompick(-1,1),0.9);
		}
		MISL BBBB 1{
			vel.z+=0.5;
			scale*=1.05;
		}
		MISL CCCDDD 1{
			alpha-=0.15;
			scale*=1.01;
		}
		TNT1 A 0 A_Immolate(null,target,80);
		TNT1 AAAAAAAAAAAAAAA 4{
			A_SpawnItemEx("HDSmoke",
				random(-2,2),random(-2,2),random(-2,2),
				frandom(2,-4),frandom(-2,2),frandom(1,4),0,SXF_NOCHECKPOSITION
			);
		}stop;
	}
}

class CombatSlug:HDMobBase replaces Fatso{
	default{
		health 600;
		mass 1000;
		speed 8;
		monster;
		+floorclip
		+bossdeath
		seesound "fatso/sight";
		painsound "fatso/pain";
		deathsound "fatso/death";
		activesound "fatso/active";
		tag "$cc_mancu";

		+dontharmspecies
		deathheight 20;
		radius 28;
		height 60;
		damagefactor "Thermal", 0.7;
		hdmobbase.shields 500;
		obituary "%o was smoked by a CombatSlug.";
		painchance 80;
	}
	override void postbeginplay(){
		super.postbeginplay();
		hdmobster.spawnmobster(self);
	}
	vector2 firsttargetaim;
	vector2 secondtargetaim;
	vector2 leadoffset;
	double targdist;
	states{
	spawn:
		FATT AB 15 A_Look;
		loop;
	see:
		FATT AABBCCDDEEFF 3 {hdmobai.chase(self);}
		loop;
	missile:
		FATT ABCD 3{
			A_FaceTarget(30);
			if(A_JumpIfTargetInLOS("null",10))setstatelabel("raiseshoot");
		}
		FATT E 0 A_JumpIfTargetInLOS("raiseshoot",30);
		FATT E 0 A_JumpIfTargetInLOS("missile");
		---- A 0 setstatelabel("see");
	raiseshoot:
		FATT G 4{
			A_StartSound("fatso/raiseguns",CHAN_VOICE);
			A_FaceTarget(40,40);
		}
		FATT G 4 A_FaceTarget(20,20);
		FATT GGGG 1 A_SpawnItemEx("HDSmoke",
			24,randompick(24,-24),18,
			random(2,4),flags:SXF_NOCHECKPOSITION
		);
	shoot:
		FATT G 2{
			A_FaceTarget(10,10);
			A_SpawnItemEx("HDSmoke",
				24,randompick(24,-24),18,
				random(2,4),flags:SXF_NOCHECKPOSITION
			);
			if(!hdmobai.TryShoot(self,24,128,48,32))setstatelabel("see");
		}
		FATT G 1{
			vector2 aimbak=(angle,pitch);
			A_FaceTarget(0,0);
			firsttargetaim=(angle,pitch);
			angle=aimbak.x;pitch=aimbak.y;
		}
		FATT G 2{
			vector2 aimbak=(angle,pitch);
			A_FaceTarget(0,0);
			secondtargetaim=(angle,pitch);
			angle=aimbak.x;pitch=aimbak.y;

			targdist=(target?max(1.,distance3d(target)):4096);

			if(targdist>2000)leadoffset=(frandom(-2.,2),frandom(-1.,1.));
			else leadoffset=(
				deltaangle(firsttargetaim.x,secondtargetaim.x),
				deltaangle(firsttargetaim.y,secondtargetaim.y)
			)*targdist*frandom(0.055,0.067);

			angle+=leadoffset.x;pitch+=leadoffset.y;
		}
		FATT H 10 bright{
			A_StartSound("weapons/bronto",CHAN_WEAPON);

			hdmobai.DropAdjust(self,"ManJuice");

			//lead target
			actor ppp;int bluh;
			[bluh,ppp]=A_SpawnItemEx(
				"manjuice",0,24,32,
				cos(pitch)*27,0,-sin(pitch)*27,
				atan(24/targdist),
				flags:SXF_NOCHECKPOSITION|SXF_SETTARGET|SXF_TRANSFERPITCH
			);

			//random
			int opt=random(0,2);
			A_FaceTarget(5,5);
			if(opt==1){
				leadoffset*=frandom(-0.6,1.);
				angle+=leadoffset.x;
				pitch+=leadoffset.y;
			}else if(opt==2){
				angle+=frandom(-10,10)/targdist;
				pitch+=frandom(-1,1);
			}
			[bluh,ppp]=A_SpawnItemEx(
				"manjuice",0,-24,32,
				cos(pitch)*27,0,-sin(pitch)*27,
				-atan(24/targdist),
				flags:SXF_NOCHECKPOSITION|SXF_SETTARGET|SXF_TRANSFERPITCH
			);
		}
		FATT G 6;
		FATT G 10{
			if(
				accuracy<2
				&&(!random(0,4)||(target&&target.health>0))
			){
				accuracy++;
				setstatelabel("shoot");
			}else accuracy=0;
		}
		---- A 0 setstatelabel("see");
	pain:
		FATT J 3;
		FATT J 3 A_Pain;
		---- A 0 setstatelabel("see");
	death:
		FATT K 6 A_SpawnItemEx("HDExplosion",0,0,36,flags:SXF_SETTARGET);
		FATT L 6 A_Scream();
		FATT MNOPQRS 6 A_SpawnItemEx("HDSmoke",
			frandom(-4,4),frandom(-4,4),frandom(26,32),
			0,0,frandom(1,4),
			0,SXF_NOCHECKPOSITION
		);
		FATT TTT 8 A_SpawnItemEx("HDSmoke",
			frandom(-4,4),frandom(-4,4),frandom(26,32),
			0,0,frandom(1,4),
			0,SXF_NOCHECKPOSITION
		);
		FATT T -1{
			A_BossDeath();
			balwaystelefrag=true; //not needed?
			bodydamage+=1200;
		}stop;
	raise:
		FATT ST 14 damagemobj(self,self,1,"maxhpdrain",DMG_NO_PAIN|DMG_FORCED|DMG_NO_FACTOR);
		FATT TSR 10;
		FATT QPONMLK 5;
		---- A 0 setstatelabel("see");
	death.maxhpdrain:
		FATT STST 14 A_SpawnItemEx("MegaBloodSplatter",
			frandom(-1,1),frandom(-1,1),frandom(10,16),
			vel.x,vel.y,vel.z,0,SXF_NOCHECKPOSITION
		);
		FATT T -1;
		stop;
	}
}

