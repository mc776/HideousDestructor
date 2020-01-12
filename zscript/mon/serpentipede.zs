// ------------------------------------------------------------
// Imp
// ------------------------------------------------------------

//old non-recycling version still used for some other actors
class ImpBallTail:BlackParticleFountain{
	default{
		+nointeraction +forcexybillboard -invisible
		renderstyle "add";
		alpha 0.5;scale 0.6;
	}
	states{
	spawn:
		BAL1 BC 2 bright A_StartSound("misc/firecrkl",volume:0.2,attenuation:4.);
	death:
		BAL1 DDEE 2 bright A_FadeOut(0.2);
		stop;
	}
}
class ReverseImpBallTail:RedParticleFountain{
	default{
		+nointeraction +forcexybillboard -invisible
		renderstyle "add";
		scale 0.6;alpha 0;
	}
	states{
		spawn:
			BAL1 EEDC 2 bright A_FadeIn(0.2);
		death:
			BAL1 BAB 2 bright A_FadeIn(0.2);
			stop;
	}
}
class HDImpBallTail:HDFireballTail{
	default{
		translation "ice";
		renderstyle "subtract";
		deathheight 0.9;
		gravity 0;
	}
	states{
	spawn:
		BAL1 CDE 5{
			roll+=10;
			scale.x*=randompick(-1,1);
		}loop;
	}
}
class HDImpBall:HDFireball{
	default{
		+seekermissile
		missiletype "HDImpBallTail";
		decal "BrontoScorch";
		speed 12;
		damagetype "electro";
		gravity 0;
	}
	double initangleto;
	double inittangle;
	double inittz;
	vector3 initpos;
	virtual void A_HDIBFly(){
		roll+=10;
		if(!A_FBSeek()){
			vel*=0.99;
			A_FBFloat();
			A_Corkscrew(stamina*frandom(0,0.4));if(stamina<5)stamina++;
		}
	}
	void A_ImpSquirt(){
		roll=frandom(0,360);alpha*=0.96;scale*=frandom(1.,0.96);
		if(!tracer)return;
		double diff=max(
			absangle(initangleto,angleto(tracer)),
			absangle(inittangle,tracer.angle),
			abs(inittz-tracer.pos.z)*0.05
		);
		int dmg=int(max(0,10-diff*0.1));
		if(!tracer.player)tracer.angle+=randompick(-10,10);

		//do it again
		initangleto=angleto(tracer);
		inittangle=tracer.angle;
		inittz=tracer.pos.z;

		setorigin((pos+(tracer.pos-initpos))*0.5,true);
		if(dmg){
			tracer.A_GiveInventory("Heat",dmg);
			tracer.damagemobj(self,target,dmg/10,"Thermal");
		}
	}
	states{
	spawn:
		BAL1 ABAB 3 A_FBTail();
	spawn2:
		BAL1 AB 3 A_HDIBFly();
		loop;
	death:
		TNT1 AAA 0 A_SpawnItemEx("HDSmoke",flags:SXF_NOCHECKPOSITION);
		TNT1 A 0{
			A_Scream();
			tracer=null;
			if(blockingmobj){
				if(
					blockingmobj is "Serpentipede"
					&&(!target||blockingmobj!=target.target)
				)blockingmobj.givebody(random(1,10));
				else{
					tracer=blockingmobj;
					blockingmobj.damagemobj(self,target,random(6,18),"Electro");
				}
			}
			if(tracer){
				initangleto=angleto(tracer);
				inittangle=tracer.angle;
				inittz=tracer.pos.z;
				initpos=tracer.pos-pos;

				//HEAD SHOT
				if(
					pos.z-tracer.pos.z>tracer.height*0.8
					&&!(tracer is "Trilobite")
					&&!(tracer is "Technorantula")
					&&!(tracer is "TechnoSpider")
					&&!(tracer is "SkullSpitter")
					&&!(tracer is "FlyingSkull")
					&&!(tracer is "Putto")
					&&!(tracer is "Yokai")
				){
					if(hd_debug)A_Log("HEAD SHOT");
					bpiercearmor=true;
				}
			}
			A_SprayDecal("BrontoScorch",radius*2);
		}
		BAL1 ABCCDDEEEEEEE 3 A_ImpSquirt();
		stop;
	}
}


class Serpentipede:HDMobBase{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Imp Fighter"
		//$Sprite "TROOA1"

		mass 100;
		+floorclip
		seesound "imp/sight";
		painsound "imp/pain";
		deathsound "imp/death";
		activesound "imp/active";
		meleesound "imp/melee";
		hdmobbase.downedframe 12;
		tag "$CC_IMP";

		damagefactor "Thermal",0.66;
		Health 100;
		gibhealth 100;
		Radius 14;
		Height 56;
		Speed 12;
		Damage 4;
		MeleeDamage 4;
		PainChance 80;
		translation "MediumImp";
		obituary "%o was marinated by the serpentipedes.";
		hitobituary "%o was tenderized by the serpentipedes.";
	}
	override void postbeginplay(){
		super.postbeginplay();
		hdmobster.spawnmobster(self);
		if(bplayingid){
			bsmallhead=true;
			bbiped=true;
			A_SetSize(13,54);
		}
		resize(0.8,1.1);
	}
	override string GetObituary(actor victim,actor inflictor,name mod,bool playerattack){
		string ob;
		if(mod=="claws")ob=hitobituary;
		else ob=obituary;
		if(bplayingid)ob.replace("serpentipede","imp");
		return ob;
	}
	virtual void A_ImpChase(){
		hdmobai.chase(self);
	}
	override void deathdrop(){
		if(!bfriendly)A_DropItem("HDHandgunRandomDrop");
	}
	vector2 leadaim1;
	vector2 leadaim2;
	states{
	spawn2:
		#### ABCD 4{
			A_Wander();
			A_Look();
		}
		#### A 0 A_Jump(198,"spawn2");
		#### A 0 A_Recoil(-0.4);
		#### A 0 A_Jump(64,"spawn0");
		loop;
	spawn:
		TROO A 0;
	spawn0:
		#### AAABBCCCDD 8 A_Look();
		#### A 0 A_SetAngle(angle+random(-4,4));
		#### A 1 A_SetTics(random(1,3));
		---- A 0 A_Jump(216,2);
		---- A 0 A_StartSound(activesound,CHAN_VOICE);
		#### A 0 A_JumpIf(bambush,"spawn0");
		#### A 0 A_Jump(32,"spawn2");
		loop;
	see:
		#### ABCD 4 A_ImpChase();
		---- A 0 A_Jump(180,"see");
		---- A 0 A_AlertMonsters();
		loop;
	missile:
		#### ABCD 4{
			A_FaceTarget(40,40);
			if(A_JumpIfTargetInLOS("null",40))setstatelabel("missile0");
			else if(!A_JumpIfTargetInLOS("null"))setstatelabel("see");
		}loop;
	missile0:
		---- A 0 A_JumpIfTargetInLOS(2);
		---- A 0 A_Jump(256,"spam");
		#### E 0{
			bNODROPOFF=true;
			A_ChangeVelocity(1,random(-1,1)*random(0,3),0,CVF_RELATIVE);
		}
		#### E 0 A_Jump(16,"hork");
		goto lead;
		#### E 0 A_JumpIfCloser(512,"lead");
		goto hork;

	lead:
		#### E 6 A_FaceTarget(40,40);
		#### E 1{
			A_FaceTarget(20,40);
			leadaim1=(angle,pitch);
		}
		#### E 0{
			if(!target)return;
			A_FaceTarget(20,40);
			leadaim2=(angle,pitch);
			leadaim1=(deltaangle(leadaim1.x,leadaim2.x),deltaangle(leadaim2.y,leadaim1.y));

			double dist=min(distance3d(target),512);
			leadaim1*=frandom(0,dist/7); //less than average speed of ball
			leadaim1.x=clamp(leadaim1.x,-30,30);
			leadaim1.y=clamp(leadaim1.y,-12,10);

			angle+=leadaim1.x;
			pitch+=leadaim1.y;
		}
		#### F 4;
		#### G 8 A_SpawnProjectile("HDImpBall",34,0,0,CMF_AIMDIRECTION,pitch);
		#### F 0 A_ChangeVelocity(frandom(-1,1),frandom(-3,3),0,CVF_RELATIVE);
		#### F 6;
		---- A 0 A_JumpIfTargetInsideMeleeRange("melee");
		#### E 0 A_JumpIf(!hdmobai.TryShoot(self,32,256,10,10),"see");
		#### E 0 A_Jump(16,"see");
		#### E 0 A_Jump(40,"spam","hork");
		goto missile;

	spam:
		---- A 0 A_JumpIfTargetInLOS(2);
		---- A 0 A_Jump(256,3);
		#### DD 2 A_FaceTarget(12,24);
		#### E 5 A_SetTics(random(4,6));
		#### E 0 A_JumpIfTargetInLOS(1);
		goto spam2;
		#### E 2 A_FaceTarget(12,24);
	spam2:
		#### F 2;
		#### G 6 A_SpawnProjectile("HDImpBall",35,0,frandom(-5,7),CMF_AIMDIRECTION,pitch+random(-4,4));
		#### F 4;
		#### F 0 A_JumpIfTargetInLOS("spam3");
		#### F 0 A_Jump(256,"coverfire");
	spam3:
		---- A 0 A_Jump(120,"missile");
		---- A 0 A_Jump(256,"see");
	coverfire:
		---- A 0 A_JumpIfTargetInsideMeleeRange("melee");
		#### E random(2,7)A_JumpIfTargetInLOS("Missile");
		---- A 0 A_Jump(180,"missile1a");
		---- A 0 A_Jump(40,"hork");
		---- A 0 A_Jump(40,"see");
		---- A 0 A_Jump(80,1);
		loop;
		#### AABBCCDD 2 A_ImpChase();
		---- A 0 A_Jump(256,"missile");
	hork:
		#### E 0 A_Jump(156,"spam");
		---- A 0 A_JumpIfTargetInLOS(2);
		---- A 0 A_Jump(256,2);
		---- A 0 A_FaceTarget(40,80);
		#### E 2;
		#### E 0 A_StartSound(seesound,CHAN_VOICE);
		#### EEEEE 2 A_SpawnItemEx("ReverseImpBallTail",4,24,random(31,33),1,0,0,0,160);
		#### E 2;
		#### F 2;
		#### G 0 A_SpawnProjectile("HDImpBall",36,0,(frandom(-2,10)),CMF_AIMDIRECTION,pitch+frandom(-4,4));
		#### G 0 A_SpawnProjectile("HDImpBall",36,0,(frandom(-4,4)),CMF_AIMDIRECTION,pitch+frandom(-4,4));
		#### G 0 A_SpawnProjectile("HDImpBall",36,0,(frandom(-2,-10)),CMF_AIMDIRECTION,pitch+frandom(-4,4));
		#### GGFE 5 A_SetTics(random(4,6));
		#### E 0 A_JumpIf(!hdmobai.TryShoot(self,32,256,10,10),"see");
		---- A 0 A_Jump(256,"spam");
	melee:
		#### EE 4 A_FaceTarget();
		#### F 2;
		#### G 8 A_CustomMeleeAttack(random(10,30),meleesound,"","claws",true);
		#### F 4;
		---- A 0 setstatelabel("see");
	pain:
		---- A 0 A_GiveInventory("HDFireEnder",3);
		#### H 3 {bNODROPOFF=true;}
		#### H 3 A_Pain();
		---- A 0 A_Jump(180,2);
		---- A 0 A_AlertMonsters();
		#### A 2 A_FaceTarget();
		#### BCD 2 A_FastChase();
		goto missile;
	death:
		#### I 6 A_Gravity();
		#### J 6 A_Scream();
		#### KL 5;
	dead:
	death.spawndead:
		#### L 3 canraise A_JumpIf(abs(vel.z)<2,1);
		loop;
		#### M 5 canraise A_JumpIf(abs(vel.z)>=2,"Dead");
		loop;
	xxxdeath:
		#### N 0 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		#### O 5 A_XScream();
		#### PQRS 5;
		#### T 5;
		goto xdead;
	xdeath:
		---- A 0 A_Gravity();
		#### N 0 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		#### O 5 A_XScream();
		#### O 0 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		#### P 5 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		#### QRS 5;
		#### T 5;
	xdead:
		#### T 5 canraise A_JumpIf(abs(vel.z)<2,1);
		wait;
		#### U 5 canraise A_JumpIf(abs(vel.z)>=2,"XDead");
		wait;
	raise:
		#### M 4;
		#### ML 6;
		#### KJI 4;
		goto checkraise;
	ungib:
		#### U 6;
		#### UT 8;
		#### SRQ 6;
		#### PONH 4;
		goto checkraise;
	falldown:
		#### H 5;
		#### I 5 A_Scream();
		#### JJKKL 2 A_SetSize(-1,max(deathheight,height-10));
		#### L 2 A_SetSize(-1,deathheight);
		#### M 10 A_KnockedDown();
		wait;
	standup:
		#### LK 5;
		#### J 0 A_Jump(64,2);
		#### J 0 A_StartSound(seesound,CHAN_VOICE);
		#### JI 4 A_Recoil(-0.3);
		#### HE 5;
		#### A 0 A_Jump(256,"see");
	}
}


// ------------------------------------------------------------
// Healer Imp
// ------------------------------------------------------------
class tempshieldimp:tempshield{
	default{
		+noblooddecals
		bloodtype "ShieldNeverBlood";
		radius 18;height 26;
		stamina 10;
	}
}
class ShieldImpBall:DoomImpBall{
	default{
		+seekermissile +forcexybillboard
		decal "DoomImpScorch";
		-noblockmap
		+shootable +mthruspecies +noblooddecals
		scale 1.2;
		height 20;
		radius 20;
		speed 8;
		damagetype "Electro";
		damage 5;
		bloodtype "ShieldNeverBlood";
		health 1;
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(!bmissile)return 0;
		ExplodeMissile();
		tempshield.spawnshield(self,"tempshieldimp",false,8);
		A_Scream();
		bmissile=false;
		setstatelabel("death");
		return 0;
	}
	vector2 savedvel;
	states{
	spawn:
		BAL1 A 0 nodelay{
			A_StartSound("imp/attack",CHAN_VOICE);
			savedvel=vel.xy;
		}
		BAL1 ABABAB 2 bright;
		BAL1 B 2 A_JumpIfTargetInLOS("see");
		BAL1 ABABAB 2 bright A_SeekerMissile(6,9);
	see:
		BAL1 AB 2 bright A_SpawnItemEx("ImpBallTail",-2,0,0,vel.x*0.6,vel.y*0.6,vel.z*0.6+random(0,1),0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION);
		BAL1 AB 1 bright;
		BAL1 A 2 bright A_SpawnItemEx("ImpBallTail",-2,0,0,vel.x*0.6,vel.y*0.6,vel.z*0.6+random(0,1),0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION);
		BAL1 BA 1 bright;
		BAL1 B 2 bright A_SpawnItemEx("ImpBallTail",-2,0,0,vel.x*0.7,vel.y*0.7,vel.z*0.7+random(0,1),0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION);
		BAL1 AB 1 bright A_BishopMissileWeave();
		TNT1 A 0 {savedvel=vel.xy;}
		BAL1 A 2 bright A_SpawnItemEx("ImpBallTail",-2,0,0,vel.x*0.8,vel.y*0.8,vel.z*0.8+random(0,1),0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION);
		BAL1 B 2 A_JumpIfTargetInLOS(2,360);
		BAL1 B 0 A_Jump(256,2);
		BAL1 B 0 A_SeekerMissile(6,9);
		BAL1 B 0{
			savedvel=vel.xy;
			vel.z+=frandom(-3,4);
		}loop;
	death:
		TNT1 AAA 0 A_SpawnItemEx("HDSmoke",frandom(-1,1),frandom(-1,1),0,savedvel.x*0.2+frandom(-3,3),savedvel.y*0.2+frandom(-3,3),frandom(1,3),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		BAL1 A 2{
			vel.xy=savedvel*0.1;vel.z=1;
			A_NoBlocking();
		}
		BAL1 A 0{bshootable=false;}
		BAL1 BBCC 1 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,savedvel.x*0.2+frandom(-3,3),savedvel.y*0.2+frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		TNT1 A 0 A_FadeOut(0.2);
		BAL1 CCCC 1 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,frandom(-3,3),frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION);
		TNT1 A 0 A_FadeOut(0.2);
		BAL1 DDDD 1 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,frandom(-3,3),frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION);
		BAL1 E 0 bright A_FadeOut(0.2);
		TNT1 A 0 A_Gravity();
		TNT1 A 0 A_GiveInventory("Heat",300);
		BAL1 E 2 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,frandom(-3,3),frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION);
		BAL1 E 2 bright A_FadeOut(0.2);
		BAL1 E 2 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,frandom(-3,3),frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION);
		BAL1 E 2 bright A_FadeOut(0.2);
		TNT1 AAAAAAA 4 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,frandom(-3,3),frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION);
		TNT1 AAAAAAA 6 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,frandom(-3,3),frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION);
		TNT1 AAAAAAA 14 bright A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),0,frandom(-3,3),frandom(-3,3),random(1,2),0,SXF_NOCHECKPOSITION);
		stop;
	}
}
class Regentipede:Serpentipede{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Imp Healer"
		//$Sprite "TROOA1"

		-missilemore
		speed 6;
		health 120;
		gibhealth 140;
		translation "LightImp";
		seesound "";
		activesound "";
		meleedamage 3;
		obituary "%o could feel the schadenfreude.";
		hitobituary "%o said I want a second opinion, so the imps said okay you're ugly too.";
		tag "$CC_IMPH";
	}
	override void postbeginplay(){
		super.postbeginplay();
		resize(0.6,0.85);
	}
	override void A_ImpChase(){
		hdmobai.chase(self,flags:CHF_RESURRECT);
	}
	states{
	see:
		#### AABBCCDD 2 A_ImpChase();
		loop;
	missile:
		#### E 0 A_Jump(128,"Missile2");
		#### E 4 A_FaceTarget(0,0);
		---- A 0 A_JumpIfTargetInLOS(2);
		---- A 0 A_Jump(256,2);
		---- A 0 A_FaceTarget(0,0);
		#### F 4;
		#### G 8 A_SpawnProjectile("HDImpBall",(random(24,30)),0,(random(-6,6)),CMF_AIMDIRECTION,pitch);
		#### F 5;
		---- A 0 setstatelabel("see");
	missile2:
		#### E 2 A_FaceTarget(0,0);
		#### E 0 A_StartSound(seesound,CHAN_VOICE);
		#### EEEEE 2 A_SpawnItemEx("ReverseImpBallTail",3,19,random(24,30),1,0,0,0,160);
		---- A 0 A_JumpIfTargetInLOS(2);
		---- A 0 A_Jump(256,2);
		---- A 0 A_FaceTarget(0,0);
		#### F 4;
		---- A 0 A_JumpIfTargetInLOS(2);
		---- A 0 A_Jump(256,2);
		---- A 0 A_FaceTarget(0,0);
		#### F 4;
		#### G 0 A_FaceTarget();
		#### G 0 A_SpawnProjectile("ShieldImpBall",32,8,0,CMF_AIMDIRECTION,pitch);
		#### GGFE 5;
		---- A 0 setstatelabel("see");
	pain:
		---- A 0 A_GiveInventory("HDFireEnder",5);
		#### H 3;
		#### H 3 A_Pain();
		---- A 0 setstatelabel("see");
	heal:
		#### AHAHAHAHAHA 4 light("HEAL");
		---- A 0 setstatelabel("see");
	death:
		---- A 0 A_SpawnItemEx("BFGNecroShard",0,0,24,0,0,8,0,SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS,164);
		goto super::death;
	xdeath:
		---- A 0 A_SpawnItemEx("BFGNecroShard",0,0,24,0,0,8,0,SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS,188);
		goto super::xdeath;
	raise:
		#### M 4 A_SpawnItemEx("MegaBloodSplatter",0,0,4,vel.x,vel.y,vel.z+3,0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		#### ML 6;
		#### KJI 4;
		goto pain;
	}
}


// ------------------------------------------------------------
// Mage Imp
// ------------------------------------------------------------
class Ardentipede:Serpentipede{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Imp Caster"
		//$Sprite "TROOA1"

		-missilemore
		translation "MageImp";
		speed 8;
		health 110;
		obituary "%o experienced the magic.";
		hitobituary "%o experienced ALL the magic.";
		tag "$CC_IMPM";
	}
	override void postbeginplay(){
		super.postbeginplay();
		resize(0.9,1.2);
	}
	override void tick(){
		super.tick();
		if(instatesequence(curstate,findstate("missile3a")))gravity=0;
		else gravity=1;
	}
	states{
	recharge:
		---- A 6;
		#### ABCD 4 {
			hdmobai.wander(self,true);
			if(stamina>0)stamina--;
		}---- A 0 setstatelabel("see");
	missile:
		---- A 0 A_JumpIf(stamina>random(5,10),"recharge");
		---- A 0 A_JumpIf(health<random(0,200),1);
		goto super::missile;
		---- A 0{stamina+=3;}
		---- A 0 A_JumpIfTargetInLOS(2);
		---- A 0 A_Jump(256,"missile1");
		#### E 0 A_Jump(16,"missile1");
		#### E 0 A_JumpIfCloser(640,1);
		goto Missile3;
		#### E 0 A_JumpIfCloser(256,1);
		goto Missile2;
	missile1:
		#### E 0 A_Jump(32,"missile2");
		---- A 0 A_JumpIfTargetInLOS(2);
		---- A 0 A_Jump(256,2);
		---- A 0 A_FaceTarget(0,0);
		#### E 6;
		---- A 0 A_JumpIfTargetInLOS(2);
		---- A 0 A_Jump(256,2);
		---- A 0 A_FaceTarget(0,0);
		#### F 6;
		#### G 8 A_SpawnProjectile("ArdentipedeBall",(random(30,34)),0,(random(-6,6)),CMF_AIMDIRECTION,pitch);
		---- A 0 setstatelabel("see");
	missile2:
		#### E 0 A_Jump(96,"Missile1");
		#### E 0 A_Jump(16,"Missile3");
		#### E 2 A_FaceTarget(0,0);
		#### E 2 A_StartSound(seesound,CHAN_VOICE);
		#### EEEEEEE 2 A_SpawnItemEx("ReverseImpBallTail",random(3,5),random(23,25),random(31,33),1,0,0,0,160);
		---- A 0 A_JumpIfTargetInLOS(2);
		---- A 0 A_Jump(256,2);
		---- A 0 A_FaceTarget(0,0);
		#### F 6;

		#### GGGGGGGG 0 A_SpawnProjectile("ArdentipedeBall2",random(29,34),6,(random(-18,18)),CMF_AIMDIRECTION,pitch+frandom(-2,4));
		---- A 0{stamina+=5;}
		#### GGFE 5;
		---- A 0 setstatelabel("see");
	missile3:
		#### E 0 A_Jump(16,"missile1");
		#### E 0 A_Jump(32,"missile2");
		#### EEH 3 A_FaceTarget(0,0);
	missile3a:
		#### H 2;
		#### H 16 bright{
			vel.z+=2;
			stamina+=8;
		}
		#### HHHH 2 bright{vel.z*=0.6;}
		#### H 0 A_SpawnProjectile("ArdentipedeBall2",32,0,162,2,60);
		#### H 2 bright A_SpawnProjectile("ArdentipedeBall2",32,0,-162,2,60);
		#### H 0 A_SpawnProjectile("ArdentipedeBall2",32,0,156,2,40);
		#### H 2 bright A_SpawnProjectile("ArdentipedeBall2",32,0,-156,2,40);
		#### H 0 A_SpawnProjectile("ArdentipedeBall2",32,0,150,2,20);
		#### H 2 bright A_SpawnProjectile("ArdentipedeBall2",32,0,-150,2,20);
		#### H 0 A_SpawnProjectile("ArdentipedeBall2",32,0,144,2,0);
		#### H 2 bright A_SpawnProjectile("ArdentipedeBall2",32,0,-144,2,0);
		#### H 0 A_SpawnProjectile("ArdentipedeBall2",32,0,138,2,-10);
		#### H 2 bright A_SpawnProjectile("ArdentipedeBall2",32,0,-138,2,-10);
		#### H 0 A_SpawnProjectile("ArdentipedeBall2",32,0,132,2,-14);
		#### H 8 bright A_SpawnProjectile("ArdentipedeBall2",32,0,-132,2,-14);
	missile3b:
		#### H 8;
		goto missile1;
	pain:
		---- A 0 A_GiveInventory("HDFireEnder",3);
		#### H 0 A_Gravity();
		#### H 3 {bNODROPOFF=true;}
		#### H 3 A_Pain();
		#### A 2 A_FaceTarget();
		#### BCD 2 A_FastChase();
		Goto Missile;
	}
}

class ArdentipedeBall:HDImpBall{
	default{
		missiletype "ArdentipedeBallTail";
		speed 10;
		scale 1.2;
	}
	override void A_HDIBFly(){
		roll=frandom(0,360);
		if(tracer){
			vel*=0.86;
			if(!A_FBSeek(512))vel+=(frandom(-1,1),frandom(-1,1),frandom(-1,1));
		}
	}
	states{
	spawn:
		BAL1 ABABABAB 2 A_FBTail();
		goto spawn2;
	death:
		TNT1 AAA 0 A_SpawnItemEx("HDSmoke",flags:SXF_NOCHECKPOSITION);
		TNT1 A 0 {if(blockingmobj)A_Immolate(blockingmobj,target,40);}
		goto super::death;
	}
}
class ArdentipedeBall2:HDImpBall{
	default{
		missiletype "ArdentipedeBallTail2";
		damage 2;
		speed 7;
		height 4;radius 4;
		scale 0.6;
		decal "Scorch";
	}
	override void A_HDIBFly(){
		roll=frandom(0,360);
		A_FBSeek(256);
	}
	states{
	spawn:
		BAL1 A 2 bright{
			A_SeekerMissile(40,40);
			A_FaceTracer(2,2);
			stamina++;
			if(stamina>10){
				pitch+=frandom(-1,1);
				angle+=frandom(-1,1);
				setstatelabel("spawn2");
			}else if(stamina<5)A_FBTail();
		}
		loop;
	spawn2:
		BAL1 ABAB 1 bright fast A_ChangeVelocity(cos(pitch)*4,0,-sin(pitch)*4,CVF_RELATIVE);
	spawn3:
		BAL1 AB 3 bright fast A_HDIBFly();
		loop;
	death:
		TNT1 A 0{
			spawn("HDSmoke",pos,ALLOW_REPLACE);
			if(blockingmobj)A_Immolate(blockingmobj,target,random(10,32));
		}
		BAL1 CDE 4 bright A_FadeOut(0.2);
		stop;
	}
}
class ArdentipedeBallTail:HDFireballTail{
	default{
		deathheight 0.9;
		gravity 0;
		friction 0.92;
		radius 1.6;
	}
	states{
	spawn:
		BAL1 AB 2{
			roll=frandom(0,360);
			scale.x*=randompick(-1,1);
		}loop;
	}
}
class ArdentipedeBallTail2:ArdentipedeBallTail{
	default{
		deathheight 0.86;
		radius 0.7;
	}
}


// ------------------------------------------------------------
// Imp Spawner
// ------------------------------------------------------------
class ImpSpawner:RandomSpawner replaces DoomImp{
	default{
		+ismonster
		dropitem "Serpentipede",256,5;
		dropitem "Regentipede",256,2;
		dropitem "Ardentipede",256,3;
	}
}
class DeadImpSpawner:RandomSpawner replaces DeadDoomImp{
	default{
		+ismonster
		dropitem "DeadSerpentipede",256,5;
		dropitem "DeadRegentipede",256,2;
		dropitem "DeadArdentipede",256,3;
	}
}
class DeadSerpentipede:Serpentipede{
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
	}
}
class DeadRegentipede:Regentipede{
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
	}
}
class DeadArdentipede:Ardentipede{
	override void postbeginplay(){
		super.postbeginplay();
		A_Die("spawndead");
	}
}
