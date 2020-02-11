// ------------------------------------------------------------
// Revenant
// ------------------------------------------------------------
class bonerball:slowprojectile{
	default{
		projectile;
		+rockettrail
		+shootable +thruspecies +noblood -noblockmap +thruspecies +notargetswitch
		+forcexybillboard
		+seekermissile +randomize
		+usebouncestate
		bouncetype "doom";
		health 40;mass 80;
		deathsound "skeleton/tracex";
		seesound "skeleton/attack";
		renderstyle "add";
		radius 6;
		height 6;
		scale 0.6;
		decal "revenantscorch";
		seesound "";
		speed 2;
		damagefactor(5);
		damagetype "SmallArms2";
		spriteangle 180;
	}
	override void Tick(){
		super.Tick();
		bspriteangle=(vel dot vel)<200;
	}
	vector3 oldvel;
	states{
	spawn:
		TNT1 A 0;
		TNT1 A 0 A_StartSound("skeleton/attack",CHAN_VOICE);
	spawn2:
		FATB AB 2 bright;
		TNT1 A 0{
			A_StartSound("world/rocketfar",CHAN_BODY,volume:0.4);
			oldvel=vel;
			bool targlos=A_JumpIfTargetInLOS("spawn",0,JLOSF_CHECKTRACER);
			if(targlos){
				A_ScaleVelocity(0.9);
				A_FaceTracer(45,45,0,0,FAF_TOP,-height);
				A_SetPitch(pitch+frandom(-1,1));
				A_SetAngle(angle+frandom(-1,1));
			}
			else {
				A_SetPitch(pitch+frandom(-10,10));
				A_SetAngle(angle+frandom(-20,20));
			}
			if(
				targlos
				&&(tracer&&distance3d(tracer)<96)
			)A_ChangeVelocity(Cos(Pitch)*5,0,Sin(-Pitch)*5,CVF_RELATIVE);
			else A_ChangeVelocity(Cos(Pitch)*2,0,Sin(-Pitch)*2,CVF_RELATIVE);
			if(pos.z-floorz<14)vel.z+=2;
		}
		loop;
	bounce:
		FATB A 0 A_JumpIf(
			stamina>3
			||(oldvel==(0,0,0))
			||!target
			||target.health<1
			||!target.checksight(self)
			||(
				!checkmove(pos.xy+oldvel.xy)
				&&blockingmobj
				&&blockingmobj==tracer
			)
		,"realdeath");
		FATB A 1 bright{
			vel.z+=5;
			stamina++;
			bshootable=true;
			double frangle=frandom(160,200);
			angle+=frangle;
			setorigin(pos-oldvel,true);
			A_ChangeVelocity(Cos(Pitch)*5,0,Sin(-Pitch)*5,CVF_RELATIVE);
		}
		FATB B 1 bright{bmissile=true;}
		FATB ABABABAB 1 bright{vel.z--;}
		goto spawn2;
	death:
		---- A 0 A_JumpIf(stamina<4,"bounce");
	realdeath:
		---- A 0{
			if(blockingmobj){
				A_Immolate(blockingmobj,target,random(20,40));
				blockingmobj.damagemobj(self,target,random(20,40),"SmallArms1");
			}
			oldvel*=0.1;
			A_SprayDecal("Scorch",10);
			bmissile=false;
			bnointeraction=true;
			A_Scream();
		}
		TNT1 AAAAAAAAAAA 0 A_SpawnItemEx("BigWallChunk",random(-4,4),random(-4,4),random(2,14),oldvel.x+random(-6,6),oldvel.y+random(-6,6),oldvel.z+random(-4,18),random(0,360),SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS);
		TNT1 AA 0 A_SpawnItemEx("HDSmokeChunk",random(-4,4),random(-4,4),random(2,14),oldvel.x+random(-6,6),oldvel.y+random(-6,6),oldvel.z+random(-4,18),random(0,360),SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS,160);
		TNT1 A 0 A_ChangeVelocity(0,0,2);
		FATB A 0 A_SetDamageType("SmallArms0");
		BAL1 A 4 bright light("BONEX1") A_Explode(random(10,30),random(50,70),0);
		---- A 0 A_Quake(2,48,0,24,"");
		---- AA 0 A_SpawnItemEx("HDSmoke",0,0,-2,oldvel.x,oldvel.y,oldvel.z,0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS);
		MISL CCCC 1 A_FadeOut(0.1);
		goto fade;
	fade:
		MISL D 1 A_FadeOut(0.1);
		wait;
	}
}

class Boner:HDMobBase replaces Revenant{
	default{
		radius 12;
		height 56;
		painchance 100;
		meleethreshold 196;
		+missilemore 
		+floorclip
		+hdmobbase.smallhead
		+hdmobbase.biped
		hdmobbase.downedframe 15;
		seesound "skeleton/sight";
		painsound "skeleton/pain";
		deathsound "skeleton/death";
		activesound "skeleton/active";
		meleesound "skeleton/melee";
		tag "$CC_REVEN";

		+noblooddecals
		-longmeleerange
		bloodtype "notquitebloodsplat";
		speed 14;
		mass 200;
		health 250;
		obituary "%o was bagged by a boner.";
		hitobituary "%o was slapped by a boner.";
		damagefactor "Thermal",1.1;
		damagefactor "SmallArms0",0.9;
		damagefactor "SmallArms1",0.9;
		damagefactor "SmallArms2",0.8;
		damagefactor "SmallArms3",0.7;
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(bplayingid){
			scale=(0.74,0.74);
			mass=80;
		}else{
			hdmobai.resize(self,0.8,1.1);
		}
		let hdmb=hdmobster(hdmobster.spawnmobster(self));
		hdmb.meleethreshold=200;
		balls=300;
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(mod=="Thermal"||mod=="Fire")flags|=DMG_NO_PAIN;
		return super.damagemobj(
			inflictor,source,damage,mod,flags,angle
		);
	}
	uint balls;
	states{
	spawn:
		SKEL B 10 A_Look();
		wait;
	see:
		SKEL ABCDEF 3{
			if(balls>300)hdmobai.chase(self);
			else hdmobai.chase(self,"melee",null);
			balls++;
		}loop;
	melee:
		SKEL G 4 A_FaceTarget();
		SKEL G 1 A_SkelWhoosh();
		SKEL H 2;
		SKEL I 6 A_SkelFist();
		SKEL H 4;
		---- A 0 setstatelabel("see");
	missile:
		SKEL II 4 A_FaceTarget();
		SKEL J 3 bright A_SpawnProjectile("BonerBall",42,4,-24,2,4);
		SKEL J 7 bright A_SpawnProjectile("BonerBall",42,-4,24,2,4);
		SKEL K 12{balls=0;}
		---- A 0 setstatelabel("see");
	pain:
		SKEL L 5;
		SKEL L 5 A_Pain();
		---- A 0 setstatelabel("see");
	death:
		SKEL LM 7;
		SKEL N 7 A_Scream();
		SKEL O 7 A_NoBlocking();
	dead:
		SKEL P 5 canraise A_JumpIf(floorz>pos.z-6,1);
		wait;
		SKEL Q 5 canraise A_JumpIf(floorz<=pos.z-6,"dead");
		wait;
	raise:
		SKEL Q 5;
		SKEL PONML 5;
		---- A 0 setstatelabel("see");
	falldown:
		SKEL L 5;
		SKEL M 5 A_Pain();
		SKEL NNOOP 2 A_SetSize(-1,max(deathheight,height-10));
		SKEL L 0 A_SetSize(-1,deathheight);
		SKEL Q 10 A_KnockedDown();
		wait;
	standup:
		SKEL P 6;
		SKEL O 0 A_Jump(160,2);
		SKEL O 0 A_StartSound(seesound,CHAN_VOICE);
		SKEL PO 4 A_Recoil(-0.3);
		SKEL NML 4;
		---- A 0 setstatelabel("see");
	}
}

