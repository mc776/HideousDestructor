// ------------------------------------------------------------
// Lost Soul
// ------------------------------------------------------------
class FlyingSkull:HDMobBase replaces LostSoul{
	default{
		mass 50;
		painchance 256;
		monster;
		+float +nogravity +missilemore +dontfall +noicedeath
		attacksound "skull/melee";
		painsound "skull/pain";
		deathsound "skull/death";
		tag "$cc_lost";

		+noblood +pushable -floorclip +avoidmelee
		+noforwardfall
		+bright
		+hdmobbase.noshootablecorpse
		obituary "%o found a skull.";
		activesound "";
		scale 0.6;
		radius 12;
		height 26;
		speed 4;
		damage 3;
		health 70;
		alpha 1.0;
		renderstyle "normal";
		maxtargetrange 245;
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_GiveInventory("ImmunityToFire");
		hdmobai.resize(self,0.8,1.3);
		latched=null;
		lastpointinmap=pos;
	}
	override void tick(){
		if(
			!level.ispointinlevel(pos)
			||!checkmove(pos.xy,PCM_DROPOFF|PCM_NOACTORS)
		){
			setorigin(lastpointinmap,true);
			setz(clamp(pos.z,floorz,ceilingz-height));
		}else lastpointinmap=pos;
		super.tick();
		A_TakeInventory("Heat");
		if(!bcorpse&&!(level.time%8)){
			spawn("HDFlameRed",pos+(frandom(-4,4),frandom(-4,4),frandom(2,8)),ALLOW_REPLACE);
		}
	}
	void A_SkullChase(){
		hdmobai.chase(self);
		vel.z+=frandom(-0.3,0.3);
		if(!random(0,64)&&!A_JumpIfTargetInLOS("null")){
			A_StartSound("skull/activescream",CHAN_VOICE);
		}
	}
	void A_SkullStrafe(){
		A_FaceTarget(16,16);
		spawn("HDSmoke",pos,ALLOW_REPLACE);
		A_ChangeVelocity(cos(pitch),randompick(-1,1)*frandom(3,6),0,CVF_RELATIVE);
	}
	void A_SkullLaunch(){
		latched=null;
		A_StartSound("skull/melee",CHAN_VOICE);
		spawn("HDSmoke",pos,ALLOW_REPLACE);
		A_FaceTarget(16,16);
		A_ChangeVelocity(cos(pitch)*20,0,-sin(pitch)*20,CVF_RELATIVE);
		flycheck=vel.xy*3;
		setstatelabel("fly");
	}
	vector2 flycheck;
	void A_SkullFlying(){
		vel*=0.95;
		if(vel dot vel<(10*10)){
			setstatelabel("see");
			return;
		}
		if(!CheckMove(pos.xy+flycheck,1)){
			bool bounce=false;
			if(blockingline){
				bounce=true;
			}else if(blockingmobj){
				actor bmj=blockingmobj;
				if(
					!target
					||bmj!=target
					||absangle(angleto(target),angle)>30
					||(
						!CheckMove(pos.xy+vel.xy,1) //too far away
						&&blockingmobj!=bmj //another intervening blocker
					)
				){
					bounce=true;
					hdf.give(bmj,"heat",5);
					bmj.vel+=vel*min(mass/max(1,bmj.mass),0.9);
				}else if(!CheckMove(pos.xy+vel.xy,1)){
					A_FaceTarget();
					latched=bmj;
					latchangle=deltaangle(bmj.angle,bmj.angleto(self));
					latchdist=frandom(0.95,1.)*(latched.radius+radius);
					latchz=pos.z-latched.height-latched.pos.z;
					latchedlastangle=latched.angle;
					hdf.give(bmj,"heat",12);
					latched.damagemobj(self,self,random(2,7),"Teeth");
					setstatelabel("latched");
				}
			}

			if(bounce){
				vel.xy=rotatevector(vel.xy,frandom(120,240));
				vel.z*=frandom(0.4,0.9)*randompick(-1,1);
				A_StartSound("weapons/fragknock",CHAN_BODY);
				forcepain(self);
			}
		}
	}
	void A_SkullLatched(){
		if(!latched||latched.health<1){
			latched=null;
			setstatelabel("see");
			return;
		}
		setz(latched.height+latched.pos.z+latchz);
		if(
			absangle(latched.angle,latchedlastangle)>30
			||!trymove(latched.pos.xy+angletovector(latched.angle+latchangle,latchdist),true)
		){
			target=latched; //just in case it was forgotten somehow
			latched=null;
			vel.xy=rotatevector(vel.xy,frandom(120,240));
			vel.z*=frandom(0.4,0.9)*randompick(-1,1);
			A_StartSound("weapons/fragknock",CHAN_BODY);
			forcepain(self);
			return;
		}
		//omnomnom
		A_FaceTarget();
		latchedlastangle=latched.angle;
		setorigin(pos+(frandom(-1,1),frandom(-1,1),frandom(-1,1)),true);
		hdf.give(latched,"heat",random(6,12));
		latched.angle+=frandom(-2,2);
		latched.pitch+=frandom(-2,2);
		if(!random(0,6))latched.damagemobj(self,self,random(0,2),"Teeth");
	}
	override bool cancollidewith(actor other,bool passive){
		return !latched&&(!spitter||other!=spitter);
	}
	actor spitter;
	actor latched;
	double latchdist;
	double latchz;
	double latchangle;
	double latchedlastangle;
	vector3 lastpointinmap;
	states{
	spawn:
		SKUL AB 6{hdmobai.wander(self);}
		SKUL A 0 A_Jump(12,1);
		loop;
		SKUL A 0 A_StartSound("skull/idlescream",CHAN_VOICE);
		loop;
	see:
		SKUL AB 3 A_SkullChase();
		loop;
	strafe:
		SKUL A 0 A_SkullStrafe();
		SKUL ABAB 2 bright;
		---- A 0 setstatelabel("see");
	missile:
		SKUL A 0 A_Jump(64,"strafe");
		SKUL A 0 A_Jump(200,2);
		SKUL A 0 A_SkullStrafe();
		SKUL ABABAB 2;
		SKUL B 2 A_FaceTarget(0,0);
		SKUL C 2 A_SkullLaunch();
	fly:
		SKUL CD 2 A_SkullFlying();
		loop;
	latched:
		SKUL CD 1 A_SkullLatched();
		loop;
	pain:
		SKUL E 3 bright{
			spitter=null;
		}
		SKUL E 3 A_Pain();
		---- A 0 setstatelabel("see");
	death:
		SKUL E 2 bright{
			A_SetTranslucent(1,1);
			vel.z++;
		}
		TNT1 AAA 0 A_SpawnItemEx("HDSmokeChunk",0,0,3,
			vel.x+frandom(-4,4),vel.y+frandom(-4,4),vel.z+frandom(1,6),
			0,SXF_ABSOLUTE|SXF_ABSOLUTEMOMENTUM
		);
		SKUL G 2 A_NoBlocking();
		SKUL H 2 A_Scream();
		SKUL HHH 0 A_SpawnItemEx("HDSmoke",
			frandom(-2,2),frandom(-2,2),frandom(4,8),
			vel.x,vel.y,vel.z+random(1,2),
			0,SXF_ABSOLUTE|SXF_ABSOLUTEMOMENTUM
		);
		SKUL HHHHHHHHH 0 A_SpawnItemEx("BigWallChunk",
			frandom(-4,4),frandom(-4,4),frandom(2,14), 
			vel.x+frandom(-4,4),vel.y+frandom(-4,4),vel.z+frandom(-4,10),
			random(0,360),SXF_ABSOLUTEMOMENTUM|SXF_ABSOLUTE|SXF_SETTARGET
		);
		SKUL I 1{
			HDActor.HDBlast(self,
				blastradius:96,blastdamage:random(1,12),blastdamagetype:"Thermal",
				immolateradius:96,immolateamount:random(4,20),immolatechance:32
			);
		}
		SKUL JJJJ 1 A_FadeOut(0.2);
		stop;
	}
}


// ------------------------------------------------------------
// Pain Elemental
// ------------------------------------------------------------
class ShieldSkullBall:ShieldImpBall{
	default{speed 26;}
}
class SkullSpitter:HDMobBase replaces PainElemental{
	default{
		radius 24;
		height 56;
		health 400;
		mass 400;
		painchance 128;
		+float 
		+nogravity
		seesound "pain/sight";
		painsound "pain/pain";
		deathsound "pain/death";
		activesound "pain/active";
		tag "$cc_pain";

		+pushable
		pushfactor 0.3;
		obituary "%o braved the elements.";
		hitobituary "%o thought it was elementary that certain monsters had no melee attack.";
		hdmobbase.shields 1000;
		speed 3;
	}
	override void postbeginplay(){
		super.postbeginplay();
		hdmobster.spawnmobster(self);
		hdmobai.resize(self,0.9,1.1);
	}
	int brewing;
	states{
	spawn:
		PAIN A 10 A_Look;
		loop;
	see:
		PAIN AAABBBCCC 5{
			hdmobai.chase(self);
		}loop;
	missile:
		TNT1 A 0 A_JumpIfTargetInLOS("missile2",20);
		PAIN ABCB 3 A_FaceTarget(10,10);
		TNT1 A 0 A_ChangeVelocity(0.8,0,frandom(-0.4,0.4),CVF_RELATIVE);
		TNT1 A 0 A_JumpIfTargetInLOS("missile");
		TNT1 A 0 A_Jump(40,"missile2");
		---- A 0 setstatelabel("see");
	missile2:
		PAIN DDE 2 A_FaceTarget(5,5);
		PAIN F 3 A_FaceTarget(5,5);
		PAIN F 0 A_JumpIf(brewing>0,"missile2a");
		PAIN F 6{
			let aaa=FlyingSkull(spawn("FlyingSkull",pos,ALLOW_REPLACE));
			aaa.addz(32);
			aaa.master=self;
			aaa.target=target;
			aaa.angle=angle;
			aaa.pitch=pitch;
			aaa.spitter=self;
			aaa.vel=vel;
			aaa.A_SkullLaunch();
			brewing=4;
			shields-=66;
		}
		goto missileend;
	missile2a:
		PAIN F 6{
			brewing--;
			A_SpawnProjectile("ShieldSkullBall",flags:CMF_AIMDIRECTION,pitch:pitch);
			shields=max(shields,shields+24);
			vel.z+=frandom(0.2,2.);
		}
		PAIN F 4 A_SpawnProjectile("ShieldSkullBall",flags:CMF_AIMDIRECTION,pitch:pitch);
		PAIN F 3 A_SpawnProjectile("ShieldImpBall",flags:CMF_AIMDIRECTION,pitch:pitch);
	missileend:
		PAIN ED 3;
		---- A 0 setstatelabel("see");
	melee:
		PAIN DE 4 A_FaceTarget(10,10);
		PAIN F 6 A_FaceTarget(10,10);
		PAIN C 12 A_CustomMeleeAttack(random(20,40));
		---- A 0 setstatelabel("see");
	pain:
		PAIN G 6{
			A_ScaleVelocity(0.6);
			brewing--;
		}
		PAIN G 6 A_Pain();
		---- A 0 setstatelabel("missile2");
	death.telefrag:
		TNT1 A 0 spawn("Telefog",pos,ALLOW_REPLACE);
		TNT1 A 0 A_NoBlocking();
		TNT1 AAAAAAAAAAAAA 0 A_SpawnItemEx("BFGNecroShard",
			frandom(-4,4),frandom(-4,4),frandom(6,24),
			frandom(1,6),0,frandom(1,3),
			frandom(0,360),SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS|SXF_SETMASTER
		);
		stop;
	death:
		PAIN H 2;
		PAIN I 3 A_Scream();
		TNT1 A 0 A_NoBlocking();
		TNT1 AAAA 0 A_SpawnItemEx("HDSmokeChunk", random(-7,7),random(-7,7),random(2,6), vel.x+random(-7,7),vel.y+random(-7,7),vel.z+random(4,8),0, SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		PAIN J 1 bright;
		TNT1 A 0 A_Explode(60,200);
		TNT1 A 0 A_RadiusGive("HDFireStarter", 56, RGF_PLAYERS|RGF_MONSTERS|RGF_OBJECTS|RGF_CORPSES,random(1,4));
		TNT1 AAAAA 0 A_SpawnItemEx("HDSmokeChunk", random(-7,7),random(-7,7),random(2,6), vel.x+random(-7,7),vel.y+random(-7,7),vel.z+random(4,8),0, SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM);
		PAIN JJJKKK 1 A_SpawnItemEx("HDSmoke", random(-4,4), random(-4,4), random(-2,4), vel.x,vel.y,vel.z+random(1,4), random(0,360), 168, 16);
		PAIN LLL 0{
			actor aaa;
			[bseesdaggers,aaa]=A_SpawnItemEx("FlyingSkull",
				randompick(-20,0,20),randompick(-20,0,20),frandom(1,12),
				frandom(2,7),frandom(-4,4),frandom(1,3),
				frandom(-45,45),
				flags:SXF_NOCHECKPOSITION|SXF_SETMASTER
			);
			let ccc=FlyingSkull(aaa);if(ccc)ccc.A_SkullLaunch();
		}
		PAIN LL 1 A_SpawnItemEx("HDSmoke", random(-4,4), random(-4,4), random(-2,4), vel.x,vel.y,vel.z+random(1,4), random(0,360), 168, 16);
		PAIN LLLMMMM 1 A_SpawnItemEx("HDSmoke", random(-4,4), random(-4,4), random(-2,4), vel.x,vel.y,vel.z+random(1,4), random(0,360), 168, 72);
		TNT1 AAAAAAA 3 A_SpawnItemEx("HDSmoke", random(-4,4), random(-4,4), random(-2,4), 0, 0, 0, random(0,360), 160, 92);
		stop;
	raise:
		PAIN MLKJIH 8;
		---- A 0 setstatelabel("checkraise");
	}
}

//old pre-ZScript fire thingy, now only used by PE because I don't care.
class HDFireStarter:ActionItem{
	states{
	pickup:
		TNT1 A 0{
			if(!self) return;
			if(hd_debug)a_log("deprecated fire. please use A_Immolate() directly.");
			actor f=spawn("HDFire",pos,ALLOW_REPLACE);
			f.target=self;f.master=self.target;
			f.stamina=random(40,80);
			return;
		}fail;
	}
}
