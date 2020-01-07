// ------------------------------------------------------------
// Trilobite
// ------------------------------------------------------------
class FooFighter:HDActor{
	bool foowizard;
	bool foocleric;
	default{
		+bright +nogravity +float +noblockmap
		+seekermissile +missile
		+puffonactors +bloodlessimpact +alwayspuff +puffgetsowner +hittracer

		+rollsprite +rollcenter
		+forcexybillboard +bright
		renderstyle "add";

		height 20;radius 20;
		speed 20;
		maxstepheight 64;

		damagetype "Thermal";

		seesound "caco/ballhum";
	}
	override void beginplay(){
		super.beginplay();
		vel*=frandom(0.4,1.7);
		stamina=random(300,600);
		ChangeTid(424707);

		foowizard=randompick(0,0,0,0,1);
		foocleric=randompick(0,0,0,0,0,1);
	}
	override void postbeginplay(){
		super.postbeginplay();
		hdmobster.spawnmobster(self);
	}
	override void tick(){
		if(isfrozen()){
			clearinterpolation();
			return;
		}
		if(bnointeraction){
			roll+=10;
			scale*=1.01;
			A_SpawnItemEx("HDGunSmoke",3,0,0,2,0,1,roll,SXF_NOCHECKPOSITION);
			super.tick();
			return;
		}
		roll=frandom(0,360);
		stamina--;

		//apply movement and collision
		speed=vel.xy.length();
		int times=max(1,speed/radius);
		vector3 frac=(times==1)?vel:(vel/times);
		fcheckposition tm;
		for(int i=0;i<times;i++){
			if(stamina<1||!trymove(pos.xy+frac.xy,true,true,tm)){
				if(
					stamina>0&&random(0,blockingmobj==null?2:7)
				){
					setorigin((pos.xy+frac.xy,pos.z),true);
					continue;
				}

				//bzz
				if(blockingmobj){
					if(
						blockingmobj is "Trilobite"
						&&target
						&&target.target!=blockingmobj
					)continue;

					int pcbak=blockingmobj.painchance;
					blockingmobj.painchance=max(pcbak,240);
					blockingmobj.DamageMobj(self,target,random(1,3),"Electro");
					blockingmobj.painchance=pcbak;

					A_StartSound("caco/ballcrack",CHAN_WEAPON);
					while(random(0,2))A_SpawnParticle("white",
						SPF_RELATIVE|SPF_FULLBRIGHT,35,frandom(4,8),0,
						frandom(-4,4),frandom(-4,4),frandom(0,4),
						frandom(-1,1),frandom(-1,1),frandom(1,2),
						frandom(-0.1,0.1),frandom(-0.1,0.1),-0.05
					);
					if(random(0,3)){
						setorigin((pos.xy+frac.xy,pos.z),true);
						stamina-=1;
						vel*=0.9;
						continue;
					}
				}

				bmissile=false;
				bnointeraction=true;

				//kaBOOM
				A_HDBlast(
					blastradius:128,blastdamage:128,blastdamagetype:"Electro",
					pushradius:256,pushamount:512,pushmass:true,
					immolateradius:72,immolateamount:random(30,80),immolatechance:40,
					hurtspecies:false
				);
				distantnoise.make(self,"caco/bigexplodefar");
				A_StartSound("caco/bigexplode",CHAN_VOICE);
				A_StartSound("caco/ballecho",CHAN_BODY);
				A_StartSound("caco/bigcrack",5);

				A_SetSize(radius*2,height*1.4);
				if(
					abs(floorz-pos.z)<10
					||abs(ceilingz-(pos.z+height))<10
					||!checkmove(pos.xy,PCM_NOACTORS|PCM_DROPOFF)
				){
					A_SpawnChunks("HugeWallChunk",12,4,12);
					A_SpawnChunks("BigWallChunk",12,4,12);
					A_SpawnChunks("HDSmoke",3,0,2);
				}
				
				DistantQuaker.Quake(self,4,35,512,10);
				vel=(0,0,0.4);
				scale*=2.;
				setstatelabel("death");
				break;
			}
			addz(frac.z);
			if(pos.z<floorz){
				setz(floorz);
				vel.z=0;
			}else if(pos.z+height>ceilingz){
				setz(ceilingz-height);
				vel.z=0;
			}
		}
		vel.x*=frandom(0.9,1.05);
		vel.y*=frandom(0.9,1.05);
		vel.z*=frandom(0.9,1.05);
		if(accuracy>100&&tracer&&checksight(tracer)){
			A_Face(tracer,0,0,FAF_TOP);
			A_ChangeVelocity(cos(pitch),0,-sin(pitch),CVF_RELATIVE);
		}else if(!random(0,50))A_ChangeVelocity(5,0,0.2,CVF_RELATIVE);
		accuracy--;
		if(accuracy<0)accuracy=160;

		//nexttic
		if(CheckNoDelay()){
			if(tics>0)tics--;
			while(!tics){
				if(!SetState(CurState.NextState)){
					return;
				}
			}
		}
	}
	states{
	spawn:
		BAL2 ABABABABAB 1 light("PLAZMABX1");
		BAL2 A 0 A_Jump(24,"castspell");
		loop;
	castspell:
		BAL2 A 0{
			double achange=random(0,3)?frandom(-24,24):frandom(0,360);
			if(!random(0,3))vel.z=frandom(-vel.z*0.3,vel.z);
			vel.xy=rotatevector(vel.xy,achange);

			if(foowizard){
				int warptimes=random(3,7);
				double spdbak=speed;
				speed=100;
				for(int i=0;i<warptimes;i++){
					A_Wander();
				}
				speed=spdbak;
				setz(frandom(floorz,ceilingz-height));
			}
			if(foocleric){
				if(!tracer){
					foocleric=false;
					foowizard=true;
					return;
				}
				actor itt=null;
				actoriterator it=level.createactoriterator(424707,"FooFighter");
				while(itt=it.next()){
					if(checksight(itt))
					itt.vel+=itt.vec3to(tracer).unit()*2;
				}
			}
		}goto spawn;
	death:
		BAL2 CDE 3 light("BAKAPOST1");
		BAL2 E 3 light("PLAZMABX2") A_FadeOut(0.3);
		wait;
	}
}

class FoofPuff:Actor{
	default{
		+nointeraction +bloodlessimpact
		decal "";
	}
	states{spawn:TNT1 A 0;stop;}
}
class Foof:HDFireball{
	default{
		height 12;radius 12;
		gravity 0;
		decal "BulletScratch";
		damagefunction(random(20,40));
	}
	void ZapSomething(){
		roll=frandom(0,360);
		A_StartSound("misc/arczap",CHAN_BODY);
		blockthingsiterator it=blockthingsiterator.create(self,72);
		actor tb=target;
		actor zit=null;
		while(it.next()){
			if(
				it.thing.bshootable
			){
				zit=it.thing;
				A_Face(zit,0,0,flags:FAF_MIDDLE);
				if(
					zit.health>0
					&&checksight(it.thing)
					&&(
						!tb
						||zit==tb.target
						||!(zit is "Trilobite")
					)
				){
					zit.damagemobj(self,tb,random(0,7),"Electro");
				}
				break;
			}
		}
		if(!zit||zit==tb){pitch=frandom(-90,90);angle=frandom(0,360);}
		A_CustomRailgun(
			(0),0,"","e0 df ff",
			RGF_SILENT|RGF_NOPIERCING|RGF_FULLBRIGHT|RGF_CENTERZ|RGF_NORANDOMPUFFZ,
			0,4000,"FoofPuff",range:128,6,0.8,1.5
		);
		A_FaceTracer(4,4);
		if(pos.z-floorz<24)vel.z+=0.3;
	}
	states{
	spawn:
		BAL2 A 0 ZapSomething();
		BAL2 AB 2 light("PLAZMABX1") A_Corkscrew();
		loop;
	death:
		BAL2 C 0 A_SprayDecal("CacoScorch",radius*2);
		BAL2 C 0 A_StartSound("misc/fwoosh",5);
		BAL2 CCCDDDEEE 1 light("BAKAPOST1") ZapSomething();
	death2:
		BAL2 E 0 ZapSomething();
		BAL2 E 3 light("PLAZMABX2") A_FadeOut(0.3);
		loop;
	}
}

class Triloball:IdleDummy{
	default{
		+extremedeath
		+forcexybillboard +rollsprite +rollcenter
		renderstyle "add";
		scale 1.8; alpha 0.6;
	}
	double theight;
	override void tick(){
		if(!target){destroy();return;}
		if(isfrozen()){
			clearinterpolation();
			return;
		}
		setorigin((angletovector(target.angle,target.radius),theight)+target.pos,false);
		roll=frandom(0,360);
		alpha=random(0,1)?frandom(0.8,1.6):frandom(0,0.3);
		//nexttic
		if(CheckNoDelay()){
			if(tics>0)tics--;
			while(!tics){
				if(!SetState(CurState.NextState)){
					return;
				}
			}
		}
	}
	states{
	spawn:
		BAL2 A 40 bright light("BAKAPOST1") nodelay{
			A_StartSound("caco/charge",CHAN_AUTO,attenuation:1.);
			theight=target.height*0.6;
		}stop;
	}
}



enum CacoNums{
	CACO_MAXHEALTH=666,
}
class CacoChunk:WallChunk{
	override void postbeginplay(){
		super.postbeginplay();
		if(!target)return;
		if(random(-CACO_MAXHEALTH*2,CACO_MAXHEALTH)>target.health){
			A_SetTranslation("AllBlue");
		}else{
			scale*=frandom(0.8,2.);
			if(!random(0,3))A_SetTranslation("AllPurple");
			else A_SetTranslation("AllRed");
		}
	}
}
class CacoShellBlood:BloodSplatSilent{
	override void postbeginplay(){
		bloodsplatsilent.postbeginplay();
		A_StartSound("misc/bulletflesh",volume:0.02);
		A_SpawnChunks("CacoChunk",random(1,7),1,7);
		if(
			!target //HOW THE FUCK.
			||target.health>(CACO_MAXHEALTH*0.6)
		)destroy();
	}
}
class Trilobite:HDMobBase replaces Cacodemon{
	int charge;
	double sweepangle;
	default{
		health 400;
		radius 24;
		height 48;
		mass 400;
		+float +nogravity
		seesound "caco/sight";
		painsound "caco/pain";
		deathsound "caco/death";
		activesound "caco/active";
		hitobituary "$ob_cacohit";
		tag "$cc_caco";

		+noblooddecals
		+pushable
		pushfactor 0.05;
		bloodtype "CacoShellBlood";
		bloodcolor "10 00 90";
		painchance 90;
		deathheight 29;
		damagefactor "SmallArms0", 0.8;
		damagefactor "SmallArms1", 0.9;
		obituary "%o was inverted by a cacodemon.";
		speed 4;
		maxtargetrange 8192;
	}
	override void beginplay(){
		super.beginplay();
		hdmobai.resize(self,0.8,1.1);
		speed*=3.-2*scale.x;
		let hdmb=hdmobster(hdmobster.spawnmobster(self));
		hdmb.meleethreshold=0;
	}
	void A_CacoCorpseZap(){
		A_StartSound("misc/arczap",volume:0.3,attenuation:2.);
		A_CustomRailgun((random(1,4)),0,"","blueviolet",
			RGF_SILENT|RGF_NOPIERCING|RGF_FULLbright|RGF_CENTERZ,
			0,4000,"HDArcPuff",180,180,random(60,160),18,1.4,1.5
		);
	}
	void A_CacoMeleeZap(){
		A_FaceTarget(10,10);
		A_CustomRailgun(random(10,25),0,"","azure",
			RGF_SILENT|RGF_FULLBRIGHT,
			0,4000,"FoofPuff",4,4,200,8,1.4,1.5,"none",-12
		);
	}
	override bool CanResurrect(actor other,bool passive){
		return !passive||tics<0;
	}
	states{
	spawn:
		HEAD A 10{
			A_Look();
			if(health>(CACO_MAXHEALTH*0.5))bfloatbob=false;
			if(!bambush&&!random(0,10))hdmobai.wander(self,true);
		}wait;
	see:
		HEAD A 4{
			if(health>(CACO_MAXHEALTH*0.5))bfloatbob=false;
			hdmobai.chase(self);
		}loop;
	pain:
		HEAD E 2{
			if(health<(CACO_MAXHEALTH*0.5))bfloatbob=true;
			else if(health<(CACO_MAXHEALTH*0.6))bnoblooddecals=false;
			vel.z-=frandom(0.4,1.4);
		}
		HEAD F 6 A_Pain();
		HEAD E 3;
		---- A 0 setstatelabel("see");
	missile:
		HEAD A 0 A_JumpIfTargetInLOS("shoot",10);
		HEAD A 0 A_JumpIfTargetInLOS(2,flags:JLOSF_DEADNOJUMP);
		---- A 0 setstatelabel("see");
		HEAD A 3 A_FaceTarget(40,40,flags:FAF_TOP);
		loop;
	shoot:
		HEAD A 0{vel.z+=frandom(-1,2);}
		HEAD A 0 A_JumpIf(charge>10,"bigzap");
	foof:
		HEAD B 2{
			if(!target){
				sweepangle=0;
				return;
			}
			sweepangle=clamp((1000-distance3d(target))*0.01,10,50)*randompick(-1,1);
			angle-=sweepangle;
			charge++;
		}
		HEAD C 2;
		HEAD D 6 bright A_SpawnProjectile("Foof",flags:CMF_AIMDIRECTION,pitch);
		HEAD C 3;
		HEAD B 5{angle+=sweepangle;}
		HEAD C 2;
		HEAD D 6 bright A_SpawnProjectile("Foof",flags:CMF_AIMDIRECTION,pitch);
		HEAD C 3;
		HEAD B 5{angle+=sweepangle;}
		HEAD C 2;
		HEAD D 6 bright A_SpawnProjectile("Foof",flags:CMF_AIMDIRECTION,pitch);
		HEAD C 3;
		HEAD B 3;
		HEAD A 6{angle-=sweepangle;}
		---- A 0 setstatelabel("see");
	bigzap:
		HEAD B 2;
		HEAD C 3;
		HEAD D 36 bright{
			vel.z+=frandom(0.2,1.2);
			A_FaceTarget(30,30,flags:FAF_BOTTOM);
			bnopain=true;
			A_SpawnProjectile("Triloball",28,0,0,CMF_AIMDIRECTION,pitch);
			if(!A_JumpIfCloser(1024,"null")&&random(0,3)){
				charge=666;
				A_StartSound("caco/sight",CHAN_VOICE,volume:1.,attenuation:0.1);
				A_FaceTarget(2,8,FAF_BOTTOM);
			}else A_StartSound("caco/sight",CHAN_VOICE);
		}
		HEAD D 24{
			distantnoise.make(self,"caco/bigexplodefar2");
			A_StartSound("caco/bigshot",CHAN_WEAPON);
			A_ChangeVelocity(-cos(pitch)*3,0,sin(pitch),CVF_RELATIVE);
			if(charge==666){
				A_FaceTarget(0.5,2.,FAF_BOTTOM);
				actor bll=spawn("KekB",pos,ALLOW_REPLACE);
				bll.target=self;bll.pitch=pitch;bll.angle=angle;
				bll.vel+=vel;
			}else{
				A_CustomRailgun(random(100,200),50,"","azure",
					RGF_SILENT|RGF_NOPIERCING|RGF_FULLBRIGHT,
					0,40.0,null,0,0,2048,
					12,0.4,2.0,"",-4
				);
				actor bll=LineAttack(
					angle,2048,pitch,random(128,512),"","FooFighter"
				);
				if(bll){
					bll.stamina=0;
						for(int i=0;i<3;i++){
							bll.tracer=target;
							bll.A_SpawnItemEx("FooFighter",
								0,0,3,frandom(-1,4),0,frandom(1,5),
								angle+frandom(-50,50),
								SXF_ABSOLUTEANGLE|
								SXF_NOCHECKPOSITION|
								SXF_TRANSFERPOINTERS
							);
						}
				}
			}
			charge=0;
			bnopain=false;
		}
		HEAD C 6;
		HEAD B 3;
		HEAD A 6;
		---- A 0 setstatelabel("see");
	melee:
		HEAD BB 2 A_FaceTarget(40,40);
		HEAD C 4{
			angle+=frandom(-10,10);
			pitch+=frandom(-10,10);
			A_StartSound("caco/sight");
		}
		HEAD D 2 bright A_SpawnProjectile("Triloball",28);
		HEAD DDDDDDDDDDDD 2 bright A_CacoMeleeZap();
		HEAD C 4;
		HEAD B 2;
		HEAD A 6;
		---- A 0 setstatelabel("see");
	death.spawndead:
		HEAD G 0{
			bfloatbob=false;
			bnogravity=false;
		}goto dead;
	death:
		HEAD F 3{
			bfloatbob=false;
			bnogravity=false;
			A_StartSound(seesound,CHAN_VOICE);
		}
		HEAD GH 3;
		HEAD H 2 A_JumpIf(vel.z>=0,"deadsplatting");
		wait;
	deadsplatting:
		HEAD I 4 A_Scream();
		HEAD J 4;
		HEAD JKKKKKKK 1 light("PLAZMABX1") A_CacoCorpseZap();
		HEAD L 1 A_SetTics(random(5,25));
		HEAD LLLLL 2 light("PLAZMABX1") A_CacoCorpseZap();
	deadzapping:
		HEAD L 1 light("PLAZMABX1") A_SetTics(random(1,4));
		HEAD L 0 A_StartSound("misc/arczap",volume:0.6,attenuation:2.);
		HEAD L 1{
			A_CustomRailgun ((random(4,8)),random(-12,12),"","azure",
				RGF_SILENT|RGF_FULLBRIGHT,
				1,4000,"HDArcPuff",180,180,random(32,128),4,0.4,0.6
			);
			if(!random(0,1))A_SetTics(random(1,40));
			accuracy++;
			if(accuracy>300)setstatelabel("dead");
		}
		loop;
	dead:
		HEAD L -1;
		stop;
	raise:
		---- A 0{
			accuracy=0;
		}
		HEAD L 8 A_UnSetFloorClip;
		HEAD KJIHG 8;
		goto checkraise;
	}
}
class DeadTrilobite:Trilobite replaces DeadCacodemon{
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
	}
}




class kekb:HDBulletActor{
	default{
		+bright +nogravity +rollcenter +rollsprite
		renderstyle "add";
		speed 666;
		translation 2;
		height 4;radius 3;
		missileheight 2;
	}
	override void HitGeometry(
		line hitline,
		sector hitsector,
		int hitside,
		int hitpart,
		vector3 vu,
		double lastdist
	){
		bulletdie();
	}
	vector3 oldpos;
	override void Tick(){
		oldpos=pos;
		super.Tick();
		if(1){
			vector3 velunit=(oldpos-pos).unit()*40;
			vector3 spawnpos=velunit;
			vector3 offs=(0,0,0);
			for(int i=0;i<700;i+=20){
				A_SpawnParticle(
					"azure",SPF_FULLBRIGHT,40,frandom(3,7),0,
					spawnpos.x+offs.x,spawnpos.y+offs.y,spawnpos.z+offs.z,
					offs.x*0.1,offs.y*0.1,offs.z*0.1
				);
				offs=(
					clamp(offs.x+frandom(-3,3),-10,10),
					clamp(offs.y+frandom(-3,3),-10,10),
					clamp(offs.z+frandom(-3,3),-10,10)
				);
				spawnpos+=velunit;
			}
		}
	}
	void A_KekSplode(){
		bmissile=false;
		bnointeraction=true;
		vel=(0,0,0.2);
		roll=frandom(0,360);
		scale=(randompick(-1,1)*2.,2.);

		A_AlertMonsters();
		A_HDBlast(
			320,random(24,42)*10,128,"SmallArms0",
			pushradius:420,pushamount:420,
			immolateradius:256,immolateamount:-200,immolatechance:90
		);
		A_SprayDecal("BusterScorch",14);
		distantnoise.make(self,"world/rocketfar");
		distantnoise.make(self,"caco/bigexplodefar2",2.);
		DistantQuaker.Quake(self,
			5,50,2048,8,128,256,256
		);

		//check floor and ceiling and spawn more debris
		distantnoise.make(self,"world/rocketfar");
		for(int i=0;i<3;i++)A_SpawnItemEx("WallChunker",
			frandom(-4,4),frandom(-4,4),-4,
			flags:SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
		);

		//"open" a door
		doordestroyer.destroydoor(self,160,32);
	}
	override void postbeginplay(){
		super.postbeginplay();
		actor kb=spawn("KekBlight",pos,ALLOW_REPLACE);
		kb.target=self;
	}
	states{
	spawn:
		BAL7 AB 1;
		loop;
	death:
		TNT1 AAAA 0 Spawn("HDExplosion",pos+(frandom(-4,4),frandom(-4,4),frandom(-4,4)),ALLOW_REPLACE);
		TNT1 AAAA 0 Spawn("HDSmoke",pos+(frandom(-4,4),frandom(-4,4),frandom(-4,4)),ALLOW_REPLACE);
		TNT1 A 0 A_KekSplode();
		TNT1 AAAAAAAA 0 ArcZap(self);
		BAL2 CCCDDDEEEE 1{
			roll+=20;
			scale*=1.1;
			alpha*=0.9;
			ArcZap(self);
			ArcZap(self);
		}
		TNT1 AAAAAAAAAAAAAAAAAAAA 1 ArcZap(self);
		stop;
	}
}
class KekBlight:PointLight{
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=240;
		args[1]=196;
		args[2]=64;
		args[3]=196;
		args[4]=0;
	}
	override void tick(){
		if(isfrozen())return;
		if(bstandstill||!target){
			args[3]+=randompick(-30,15,-60);
			if(args[3]<1)destroy();
			return;
		}
		args[3]=randompick(164,296,328,436);
		if(!target.bmissile){
			args[0]=255;
			args[1]=250;
			args[2]=128;
			args[3]=300;
			args[4]=0;
			bstandstill=true;
		}
	}
}



