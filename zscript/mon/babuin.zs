// ------------------------------------------------------------
// "I call the big one Bitey!"
// ------------------------------------------------------------
class Babuin:HDMobBase{
	vector3 lastpos;
	vector3 latchpos;
	double targangle;
	actor latchtarget;
	double latchforce;
	override void postbeginplay(){
		super.postbeginplay();
		hdmobai.resize(self,0.9,1.1);
		let hdmb=hdmobster(hdmobster.spawnmobster(self));
		hdmb.meleethreshold=200;
		lastpointinmap=pos;
		bbiped=bplayingid;
	}
	void TryLatch(){
		if(
			health<1
			||!target
			||target==self
			||target.health<1
			||distance2d(target)-target.radius-radius>12
		){
			latchtarget=null;
			return;
		}else{
			latchtarget=target;
			latchpos.xy=
				rotatevector(pos.xy-latchtarget.pos.xy,-latchtarget.angle).unit()
				*(latchtarget.radius+radius)
			;
			latchpos.z=frandom(8,latchtarget.height-12);
			targangle=latchtarget.angle;
			latchforce=min(0.4,mass*0.02/max(1,latchtarget.mass));
			lastpos=pos;
			setstatelabel("latched");
		}
	}
	override bool cancollidewith(actor other,bool passive){
		return(
			other!=latchtarget
			||(
				!latchtarget
				&&max(
					abs(other.pos.x-pos.x),
					abs(other.pos.y-pos.y)
				)>=other.radius+radius  
			)
		);
	}
	override void Die(actor source,actor inflictor,int dmgflags){
		latchtarget=null;
		super.Die(source,inflictor,dmgflags);
	}
	vector3 lastpointinmap;
	override void Tick(){
		//brutal force
		if(
			health>0
			&&(
				!level.ispointinlevel(pos)
				||!checkmove(pos.xy,PCM_DROPOFF|PCM_NOACTORS)
			)
		){
			setorigin(lastpointinmap,true);
			setz(clamp(pos.z,floorz,ceilingz-height));
		}else lastpointinmap=pos;

		if(!latchtarget||latchtarget==self||latchtarget.health<1){
			latchtarget=null;
		}
		if(latchtarget){
			A_Face(latchtarget,0,0);
			vector3 lp=latchtarget.pos;
			targangle=(targangle+latchtarget.angle)*0.5;
			lp.xy+=rotatevector(latchpos.xy,latchtarget.angle);
			latchpos.z=clamp(latchpos.z+random(-2,2),12,max(floorz,latchtarget.height-height));
			lp.z+=latchpos.z+frandom(-0.1,0.1);

			//don't interpolate teleport
			if(
				abs(lp.x-pos.x)>100||
				abs(lp.y-pos.y)>100||
				abs(lp.z-pos.z)>100
			){
				setorigin(lp,false);
			}else setorigin((lp+pos)*0.5,true);

			bool inmap=level.ispointinlevel(pos);

			//can try to bump or shake it off
			if(
				inmap
				&&(
					absangle(latchtarget.angle,targangle)>frandom(6,180)
					||floorz>pos.z
					||ceilingz<pos.z+height
					||(
						!trymove(pos.xy,true)
						&&blockingmobj!=latchtarget
					)
				)
			){
				A_Changevelocity(-6,random(-2,2),4,CVF_RELATIVE);
				latchtarget=null;
			}else{
				//fun!
				latchtarget.A_SetAngle(frandom(
					latchtarget.angle,targangle)+random(-8,8),SPF_INTERPOLATE
				);
				latchtarget.A_SetPitch(latchtarget.pitch+random(-6,10),SPF_INTERPOLATE);
				latchtarget.vel+=(pos-lastpos)*latchforce;
				lastpos=pos;
				//lift the victim as circumstances permit
				if(
					floorz>=pos.z
					&&mass>latchtarget.mass  
				){
					latchtarget.addz(random(-1,2),true);
				}
			}
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
		else super.Tick();
	}
	void A_CheckFreedoomSprite(){
		if(bplayingid)sprite=getspriteindex("SRG2");
		else sprite=getspriteindex("SARG");
	}
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Babuin"
		//$Sprite "SRG2A1"

		monster;
		+cannotpush +pushable
		health 90;radius 12;
		height 32;deathheight 10;
		scale 0.6;
		translation "16:47=48:79";
		speed 14;
		mass 70;
		meleerange 40;
		maxtargetrange 128;
		painchance 90; pushfactor 0.2;
		maxstepheight 32;maxdropoffheight 32;
		seesound "babuin/sight";painsound "babuin/pain";
		deathsound "babuin/death";activesound "babuin/active";
		obituary "%o was mauled by a babuin.";
		damagefactor "Thermal",0.76;
		tag "babuin";
	}
	states{
	spawn:
		SARG A 0;
		SRG2 A 0 A_CheckFreedoomSprite();
		#### A 0 A_JumpIf(bambush,"spawnstill");
	spawnwander:
		#### AABBCCDD random(2,3){
			blookallaround=false;
			hdmobai.wander(self);
		}
		#### A 0{
			if(!random(0,5))setstatelabel("spawnsniff");
			else if(!random(0,9))A_StartSound(activesound,CHAN_VOICE);
		}loop;
	spawnsniff:
		#### A 0{blookallaround=true;}
		#### EEEEEEEE 2{
			angle+=frandom(-2,2);
			A_Look();
		}
		#### F 2{
			angle+=frandom(-20,20);
			if(!random(0,9))A_StartSound(activesound,CHAN_VOICE);
		}
		#### FFF 2 A_Look();
		#### A 0{
			blookallaround=false;
			if(!random(0,6))setstatelabel("spawnwander");
		}loop;
	spawnstill:
		#### AABB 4 A_Look();
		loop;
	see:
		#### A 0{
			//because babuins come into this state from all sorts of weird shit
			if(!checkmove(pos.xy,true)&&blockingmobj){
				setorigin((pos.xy+(pos.xy-blockingmobj.pos.xy),pos.z+1),true);
			}

			blookallaround=false;
			A_Chase(flags:CHF_DONTMOVE);
			if(
				(target&&checksight(target))
				||!random(0,7)
			)setstatelabel("seechase");
			else setstatelabel("roam");
		}
	seechase:
		#### AABBCCDD random(1,2){hdmobai.chase(self);}
		---- A 0 setstatelabel("seeend");
	roam:
		#### AABBCCDD random(1,3){hdmobai.wander(self,true);}
		---- A 0 setstatelabel("seeend");
	seeend:
		#### A 0{
			if(!random(0,120)){
				A_StartSound(seesound,CHAN_VOICE);
				A_AlertMonsters();
			}
			givebody(random(2,12));
			setstatelabel("see");
		}
	melee:
		#### E 7{
			A_FaceTarget(0,0);
			A_StartSound("babuin/bite",CHAN_VOICE);
			A_Changevelocity(cos(pitch)*4,0,sin(-pitch)*4,CVF_RELATIVE);
		}
		#### F 6;
		#### G 2{
			TryLatch();
			A_CustomMeleeAttack(random(5,15),"","","teeth",true);
		}
	postmelee:
		#### G 6;
		---- A 0 setstatelabel("see");

	latched:
		#### EF random(1,2){
			if(latchtarget){
				if(!random(0,30))A_Pain();
				latchtarget.damagemobj(
					self,self,random(0,2),random(0,3)?"teeth":"falling"
				);
			}else forcepain(self);
		}loop;

	missile:
		#### ABCD 2{
			A_FaceTarget(16,16);
			A_Changevelocity(1,0,0,CVF_RELATIVE);
			if(A_JumpIfTargetInLOS("null",20,0,128))setstatelabel("jump");
		}
		---- A 0 setstatelabel("see");
	jump:
		#### AE 3{
			A_FaceTarget(16,16);
			A_Changevelocity(cos(pitch)*3,0,sin(-pitch)*3,CVF_RELATIVE);
		}
		#### E 2{
			A_FaceTarget(6,6);
			A_StartSound("babuin/sight",CHAN_VOICE);
		}
		#### E 0 A_ChangeVelocity(cos(pitch)*16,0,sin(-pitch)*16+random(3,8),CVF_RELATIVE);
	fly:
		#### F 1{
			TryLatch();
			if(floorz>=pos.z)setstatelabel("land");  
		}wait;
	land:
		#### FEH 3{vel.xy*=0.8;}
		#### D 4{vel.xy=(0,0);}
		---- A 0 setstatelabel("see");
	pain:
		#### H 2 A_SetSolid();
		#### H 6 A_Pain();
		#### H 0 A_CheckFloor("missile");
		---- A 0 setstatelabel("see");
	death:
		#### I 5{
			A_CheckFreedoomSprite();
			A_Scream();
			bpushable=false;
			A_SpawnItemEx("BFGNecroShard",flags:SXF_TRANSFERPOINTERS|SXF_SETMASTER,240);
		}
	deathend:
		#### J 5 A_NoBlocking();
		#### KLM 5;
	dead:
	death.spawndead:
		#### M 3 canraise{
			if(abs(vel.z)<2)frame++;
		}loop;
	raise:
		#### NMLKJI 5;
		SRG2 A 0 A_CheckFreedoomSprite();
		goto checkraise;
	ungib:
		TROO U 6;
		TROO UT 8;
		TROO SRQ 6;
		TROO PO 4;
		SRG2 A 0 A_CheckFreedoomSprite();
		goto checkraise;
	xdeath:
		TROO O 0 A_XScream();
		TROO OPQ 4{spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);}
		TROO RST 4;
		goto xdead;
	xxxdeath:
		TROO O 4 A_XScream();
		TROO PQRST 4;
	xdead:
		TROO T 5 canraise{
			if(abs(vel.z)<2)frame++;
		}loop;
	}
}


class SpecBabuin:Babuin{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Babuin (Cloaked)"
		//$Sprite "SRG2A1"

		renderstyle "fuzzy";
		dropitem "HDBlurSphere",1;
		tag "cloaked babuin";
	}
	states{
	see:
		TNT1 A 0 A_SetTranslucent(1,2);
		TNT1 A 0 A_JumpIfCloser(128,2);
		TNT1 A 0 A_Jump(200,2);
		TNT1 A 0 A_CheckFreedoomSprite();
		goto super::see;
		TNT1 A 4 A_Chase();
		loop;
	death:
		TNT1 AAA 0 A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),random(2,14),
			vel.x,vel.y,vel.z+random(1,3),0,
			SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION
		);
		TNT1 A 0 A_CheckFreedoomSprite();
		TNT1 A 0 A_SetTranslucent(1,0);
		goto super::death;
	xdeath:
		TNT1 AAA 0 A_SpawnItemEx("HDSmoke",random(-1,1),random(-1,1),random(2,14),
			vel.x,vel.y,vel.z+random(1,3),0,
			SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION
		);
		TNT1 A 0 A_SetTranslucent(1,0);
		goto super::xdeath;
	}
}
class DeadBabuin:Babuin{
	override void postbeginplay(){
		super.postbeginplay();
		A_CheckFreedoomSprite();
		A_Die("spawndead");
	}
}
class DeadSpecBabuin:SpecBabuin{
	override void postbeginplay(){
		super.postbeginplay();
		A_CheckFreedoomSprite();
		A_NoBlocking();
		A_SetTranslucent(1,0);
		A_Die("spawndead");
	}
}


class DeadDemonSpawner:RandomSpawner replaces DeadDemon{
	default{
		+ismonster
		dropitem "DeadBabuin",256,5;
		dropitem "DeadSpecBabuin",256,2;
		dropitem "DeadSpectre",256,1;
	}
}
