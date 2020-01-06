// ------------------------------------------------------------
// Pistol guy
// ------------------------------------------------------------
class UndeadHomeboy:HDMobMan{
	//remembering goals and targets
	vector3 targetlastpos;
	vector3 goalpos;
	vector3 threatpos;
	double walkangle;

	//tracking ammo
	int chamber;
	int thismag;
	int firemode; //based on the old pistol method: -1=semi only, 0=semi selected, 1=full auto

	//aiming and leading targets
	vector2 aimpoint1;
	vector2 aimpoint2;
	int aimpointtics;
	double spread;

	//specific to undead homeboy
	bool user_weapon; //0 random, 1 semi, 2 auto

	override void postbeginplay(){
		super.postbeginplay();
		hdmobster.spawnmobster(self);
		walkangle=angle;
		bhasdropped=false;
		if(goal)goalpos=goal.pos;else goalpos=(0,0,0);
		aimpoint1=(-1,-1);
		aimpoint2=(-1,-1);

		//specific to undead homeboy
		thismag=random(1,15);
		chamber=2;
		if(
			user_weapon==2
			||(
				user_weapon!=1
				&&!random(0,15)
			)
		)firemode=randompick(0,0,0,1);
		else firemode=-1;
	}
	virtual bool noammo(){
		return chamber<1&&thismag<1;
	}
	void A_TurnTowardsTarget(
		statelabel shootstate="shoot",
		double maxturn=20,
		double maxvariance=20
	){
		A_FaceTarget(maxturn,maxturn);
		if(
			!target
			||maxvariance>absangle(angle,angleto(target))
			||!checksight(target)
		)setstatelabel(shootstate);
		if(bfloat||floorz>=pos.z)A_ChangeVelocity(0,frandom(-0.1,0.1)*speed,0,CVF_RELATIVE);
	}

	//leading the target
	void A_LeadTarget(int phase){
		vector2 ap;
		if(target){
			double dist=distance2d(target);
			ap=(
				angleto(target),
				atan2(
					pos.z-target.pos.z,
					distance2d(target)
				)
			);
		}else ap=(angle,pitch);
		if(phase==2)aimpoint2=ap;
		else aimpoint1=ap;
	}
	void A_LeadAim(double missilespeed,int inleadtics=1,vector3 destpos=(-32000,0,0)){
		double dist;
		if(destpos==(-32000,0,0)){
			if(!target)return;
			destpos=target.pos;
		}
		vector2 apadj=(aimpoint2-aimpoint1)/inleadtics;

		dist=(level.vec3offset(pos,destpos)).length(); //placeholder, look up the proper code
		double ticstolead=dist/missilespeed;

		//then adjust for time to reach original spot???

		//put it all together
		pitch+=apadj.y*ticstolead;
		angle+=apadj.x*ticstolead;
	}


	//post-shot checks
	void A_HDMonsterRefire(statelabel jumpto,int chancetocontinue=0){
		if(
			random(1,100)>chancetocontinue
			&&(
				!target
				||!checksight(target)
				||target.health<1
				||absangle(angle,angleto(target))>3
			)
		)setstatelabel(jumpto);
	}


	//the movement stuff
	virtual void A_HDWander(bool dontlook=false){
		hdmobai.wander(self,dontlook);
	}
	virtual void A_HDChase(statelabel mlstate="melee",statelabel msstate="missile",int flags=0){
		if(!target||checksight(target))hdmobai.chase(self,mlstate,msstate,flags);
		else hdmobai.wander(self,true);
	}

	//will routinely be overridden
	virtual void A_HDMissileAttack(){
		if(chamber<2){
			if(thismag>0){
				if(chamber>0)A_EjectCasing();
				chamber=2;
				thismag--;
			}
			setstatelabel("postshot");
			return;
		}

		pitch+=frandom(0,spread)-frandom(0,spread);
		angle+=frandom(0,spread)-frandom(0,spread);
		HDBulletActor.FireBullet(self,"HDB_9",spread:2.,speedfactor:frandom(0.97,1.03));

		A_StartSound("weapons/pistol",CHAN_WEAPON);
		pitch+=frandom(-0.4,0.3);
		angle+=frandom(-0.4,0.4);

		A_EjectCasing();
		if(thismag>0)thismag--;
		else chamber=0;
	}
	override void deathdrop(){
		if(bhasdropped){
			A_DropItem("HD9mMag15");
		}else{
			bhasdropped=true;
			let ppp=HDPistol(spawn("HDPistol",(pos.xy,pos.z+40)));
			ppp.weaponstatus[PISS_MAG]=thismag;
			ppp.weaponstatus[PISS_CHAMBER]=chamber;
			if(firemode>=0){
				ppp.weaponstatus[0]|=PISF_SELECTFIRE;
				if(firemode>0)ppp.weaponstatus[0]|=PISF_FIREMODE;
			}
		}
	}
	virtual void A_HDUnload(int which=0){
		if(thismag>=0){
			actor aaa;int bbb;
			[bbb,aaa]=A_SpawnItemEx("HD9mMag15",
				cos(pitch)*10,0,height-8-sin(pitch)*10,
				vel.x,vel.y,vel.z,
				0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
			);
			hdmagammo(aaa).mags.clear();
			hdmagammo(aaa).mags.push(thismag);
			A_StartSound("weapons/pismagclick",8);
		}
		thismag=-1;
	}
	virtual bool A_HDReload(int which=0){
		if(thismag>=0)return false;
		thismag=15;
		if(chamber<2){
			if(chamber==1)A_EjectCasing();
			chamber=2;
			thismag--;
		}
		A_StartSound("weapons/pismagclick",8);
		return true;
	}

	//specific to undead homeboy, no virtual
	void A_EjectCasing(){
		A_SpawnItemEx("HDSpent9mm",
			cos(pitch)*10,0,height-8-sin(pitch)*10,
			vel.x,vel.y,vel.z,
			0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
	}

	//defaults and states
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Pistol Zombie"
		//$Sprite "POSSA1"

		seesound "grunt/sight";
		painsound "grunt/pain";
		deathsound "grunt/death";
		activesound "grunt/active";
		tag "$cc_zombie";

		radius 10;
		speed 12;
		mass 100;
		painchance 200;
		obituary "%o had a cap busted in %p ass by a zombieman.";
		hitobituary "%o was beaten up by a zombieman.";
	}
	states{
	spawn:
		POSS A 0{
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
		#### B 0 A_JumpIf(noammo(),"reload");
		#### B 0 A_Jump(28,"spawngrunt");
		#### B 0 A_Jump(132,"spawnswitch");
		#### B 8 A_Recoil(frandom(-0.2,0.2));
		loop;
	spawngrunt:
		#### G 1{
			A_Recoil(frandom(-0.4,0.4));
			A_SetTics(random(30,80));
			if(!random(0,7))A_StartSound("grunt/active",CHAN_VOICE);
		}
		#### A 0 A_Jump(256,"spawn");
	spawnswitch:
		#### A 0 A_JumpIf(bambush,"spawnstill");
		goto spawnwander;
	spawnstill:
		#### A 0 A_Look();
		#### A 0 A_Recoil(random(-1,1)*0.4);
		#### CD 5 A_SetAngle(angle+random(-4,4));
		#### A 0{
			A_Look();
			if(!random(0,127))A_StartSound("grunt/active",CHAN_VOICE);
		}
		#### AB 5 A_SetAngle(angle+random(-4,4));
		#### B 1 A_SetTics(random(10,40));
		#### A 0 A_Jump(256,"spawn");
	spawnwander:
		#### CDAB 5 A_HDWander();
		#### A 0{
			if(!random(0,127))A_StartSound("grunt/active",CHAN_VOICE);
		}
		#### A 0 A_Jump(64,"spawn");
		loop;

	see:
		#### ABCD 5 A_HDChase();
		#### A 0 A_JumpIf(noammo(),"reload");
		loop;
	missile:
		#### A 0 {bfrightened=false;}
		#### ABCD 4 A_TurnTowardsTarget();
		loop;
	shoot:
		#### E 3 A_LeadTarget(1);
		#### E 1 A_LeadTarget(2);
		#### E 2 A_LeadAim(500,3);
		#### E 0 {if(firemode>=0)firemode=randompick(0,0,0,1);}
	fire:
		#### F 1 bright light("SHOT") A_HDMissileAttack();
	postshot:
		#### E 1;
		#### E 0 A_JumpIf(chamber!=2||!target,"nope");
		#### E 0{
			if(
				firemode>0
			){
				pitch+=frandom(-2.4,2);
				angle+=frandom(-2,2);
				setstatelabel("fire");
			}else A_SetTics(random(3,10));
		}
		#### E 0 A_HDMonsterRefire("see",25);
		goto fire;
	nope:
		#### E 10;
	reload:
		#### A 0{bfrightened=true;}
		#### ABCD 6 A_HDChase();
		#### A 7 A_HDUnload();
		#### BC 7 A_HDChase();
		#### D 8 A_HDReload();
		---- A 0 setstatelabel("see");

	melee:
		#### C 8 A_FaceTarget();
		#### D 4;
		#### E 4 A_CustomMeleeAttack(
			random(3,12),"weapons/smack","","none",randompick(0,0,0,1)
		);
		#### E 3 A_JumpIfCloser(64,2);
		#### E 4 A_FaceTarget(10,10);
		goto shoot;
		#### A 4;
		---- A 0 setstatelabel("see");
	pain:
		#### G 2;
		#### G 3{
			A_Pain();
			if(!random(0,10))A_AlertMonsters();
		}
		#### G 0{
			if(
				floorz==pos.z
				&&target
				&&(
					!random(0,4)
					||distance3d(target)<128
				)
			){
				double ato=angleto(target)+randompick(-90,90);
				vel+=((cos(ato),sin(ato))*speed,1.);
				setstatelabel("missile");
			}else bfrightened=true;
		}
		#### ABCD 2 A_HDChase();
		#### G 0{bfrightened=false;}
		---- A 0 setstatelabel("see");
	death:
		#### H 5;
		#### I 5 A_Scream();
		#### J 5 A_NoBlocking();
		#### K 5;
	dead:
		#### K 3 canraise{if(abs(vel.z)<2.)frame++;}
		#### L 5 canraise{if(abs(vel.z)>=2.)setstatelabel("dead");}
		wait;
	xxxdeath:
		#### M 5;
		#### N 5{
			spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
			A_XScream();
		}
		#### OPQRST 5;
		goto xdead;
	xdeath:
		#### M 5;
		#### N 5{
			spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
			A_XScream();
		}
		#### O 0 A_NoBlocking();
		#### OP 5 spawn("MegaBloodSplatter",pos+(0,0,34),ALLOW_REPLACE);
		#### QRST 5;
		goto xdead;
	xdead:
		#### T 3 canraise{if(abs(vel.z)<2.)frame++;}
		#### U 5 canraise A_JumpIf(abs(vel.z)>=2.,"xdead");
		wait;
	raise:
		#### L 4;
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




