// ------------------------------------------------------------
// The Tyrant
// ------------------------------------------------------------
class bossbrainspawnsource:hdactor{
	static void SpawnCluster(actor caller,vector3 pos){
		let bbs=bossbrainspawnsource(spawn("bossbrainspawnsource",pos));
		bbs.master=caller;
		bbs.target=caller.target;
		bbs.stamina=caller.health<<2;
		switch(random(0,11)){
		case 0:
			bbs.accuracy=200;
			bbs.spawntype="Necromancer";
			break;
		case 1:
			bbs.accuracy=50;
			bbs.spawntype="PainLinger";
			break;
		case 2:
			bbs.accuracy=30;
			bbs.spawntype="Trilobite";
			break;
		case 3:
			bbs.accuracy=70;
			bbs.spawntype="SkullSpitted";
			break;
		case 4:
			bbs.accuracy=8;
			bbs.spawntype="Babstre";
			break;
		case 5:
			bbs.accuracy=6;
			bbs.spawntype="Putto";
			break;
		case 6:
			bbs.accuracy=6;
			bbs.spawntype="Yokai";
			break;
		case 7:
			bbs.accuracy=50;
			bbs.spawntype="CombatSlug";
			break;
		case 8:
			bbs.accuracy=50;
			bbs.spawntype="Technospider";
			break;
		case 9:
			bbs.accuracy=40;
			bbs.spawntype="Boner";
			break;
		default:
			bbs.accuracy=10;
			bbs.spawntype="ImpSpawner";
			break;
		}
	}
	void A_SpawnMonsterType(){
		setz(floorz);
		spawn("TeleFog",pos,ALLOW_REPLACE);
		let bbs=spawn(spawntype,pos,ALLOW_REPLACE);
		bbs.master=master;bbs.target=target;
		stamina-=accuracy;
		if(stamina<1)destroy();
	}
	class<actor> spawntype;
	property spawntype:spawntype;
	default{
		+ismonster
		-shootable
		-solid
		+noblockmap
		bossbrainspawnsource.spawntype "ImpSpawner";
		accuracy 10;
		speed 16;
		maxstepheight 128;
		maxdropoffheight 128;
		renderstyle "add";
	}
	states{
	spawn:
		TNT1 A 0 nodelay setz(floorz);
		TNT1 AAAA 0 A_Wander();
		TNT1 A -1;
		stop;
	awaken:
		FIRE ABCDCDCDBCDEDCDEDCBCDEDCBCD 1 bright;
		FIRE EFGH 2 bright A_FadeOut(0.2);
	place:
		TNT1 AAAA 0 A_Wander();
		TNT1 A 1 A_SpawnMonsterType();
		loop;
	}
}
class HDBossBrain:HDMobBase{
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(
			!bshootable
			||!source
			||source.master==self
		)return -1;
		if(
			!bincombat
			||damage==TELEFRAG_DAMAGE
		){
			bshootable=false;
			setstatelabel("deathfade");
			return -1;
		}

		bshootable=false;
		stamina++;
		accuracy=0;

		int maxhp=skill+2;

		for(int i=0;i<MAXPLAYERS;i++){
			if(!playeringame[i])continue;
			maxhp++;
			if(
				players[i].mo
				&&players[i].mo.health>0
			){
				let pmo=players[i].mo;
				pmo.vel+=(pmo.pos-pos).unit()*7;
				pmo.vel.z+=3;
			}
		}

		if(stamina>maxhp){
			setstatelabel("death");
			hdbosseye bbe;
			thinkeriterator bbem=ThinkerIterator.create("hdbosseye");
			while(bbe=hdbosseye(bbem.next(true))){
				bbe.remainingmessage="";
			}
		}else{
			setstatelabel("pain");
			while(accuracy<stamina)A_SpawnWaveSpot();
		}

		DistantQuaker.Quake(
			self,4,120,8192,10,
			HDCONST_SPEEDOFSOUND,
			HDCONST_MINDISTANTSOUND*2,
			HDCONST_MINDISTANTSOUND*4
		);

		return -1;
	}
	void A_SpawnWaveSpot(){
		if(!bincombat||accuracy>stamina)return;
		accuracy++;
		int bbstamina=0;
		if(!target){
			for(int i=0;i<MAXPLAYERS;i++){
				if(playeringame[i]){
					target=players[i].mo;
					bbstamina+=50;
				}
			}
		}
		if(target){
			let bbs=spawn("bossbrainspawnsource",target.pos);
			bbs.target=target;bbs.master=self;
			bbs.stamina=bbstamina;
		}
	}
	void A_SpawnWave(){
		bossbrainspawnsource bpm;
		thinkeriterator bexpm=ThinkerIterator.create("bossbrainspawnsource");
		while(bpm=bossbrainspawnsource(bexpm.next(true))){
			bpm.setstatelabel("awaken");
		}
		hdbosseye bbe;
		thinkeriterator bbem=ThinkerIterator.create("hdbosseye");
		while(bbe=hdbosseye(bbem.next(true))){
			bbe.setmessage();
			break;
		}
	}
	default{
		+noblood
	}
	states{
	spawn:
		BBRN A 140 A_SpawnWaveSpot();
		wait;
	pain:
		MISL B 10;
		BBRN B 70 A_Pain();
		---- A 70 A_SpawnWave();
		---- A 0 A_SetShootable();
		goto spawn;
	death:
		BBRN B 100;
		BBRN A 100{
			hdbosseye bbe;
			thinkeriterator bbem=ThinkerIterator.create("hdbosseye");
			while(bbe=hdbosseye(bbem.next(true))){
				bbe.playintro();
				break;
			}
		}
	deathfade:
		BBRN B 7;
		BBRN B 20 A_Scream();
		BBRN BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB 1{binvisible=!binvisible;}
		TNT1 A 0 A_BrainDie();
		TNT1 A 10;
		TNT1 A 0 A_SetShootable();
		TNT1 A 0 SetStateLabel("spawn");
		stop;
	}
}




//randomspawners for the tyrant waves

class Babstre:RandomSpawner{
	default{
		+ismonster
		dropitem "Babuin",256,12;
		dropitem "SpecBabuin",256,3;
		dropitem "NinjaPirate",256,1;
	}
}
class PainLinger:RandomSpawner{
	default{
		+ismonster
		dropitem "PainLord",256,1;
		dropitem "PainBringer",256,4;
	}
}
class SkullSpitted:SkullSpitter{
	override void postbeginplay(){
		super.postbeginplay();
		for(int i=0;i<5;i++){
			A_SpawnItemEx(
				"FlyingSkull",
				50,0,frandom(0,10),
				0,0,0,
				frandom(0,360),
				SXF_TRANSFERPOINTERS|SXF_SETMASTER,
				32
			);
		}
	}
}



class HDBossEye:HDMobBase{
	array<string> messages;
	array<string> intromessages;
	string remainingmessage;
	int messageticker;
	override void postbeginplay(){
		super.postbeginplay();
		remainingmessage="";
		messageticker=-1;

		//set brain to know this is a real boss and not just a pistol start hack
		bool foundbrain=false;
		hdbossbrain bpm;
		thinkeriterator bexpm=ThinkerIterator.create("hdbossbrain");
		while(bpm=hdbossbrain(bexpm.next(true))){
			bpm.bincombat=true;
			foundbrain=true;
		}
		if(!foundbrain){
			let bpm=spawn("hdbossbrain",pos);
			bpm.bincombat=true;
		}

		string allmessages=Wads.ReadLump(Wads.FindLump("bbtalk"));

		//set up array of intros
		int dashpos=allmessages.indexof("---");
		if(dashpos<0){
			intromessages.clear();
		}else{
			string intros=allmessages.left(dashpos);
			intros.split(intromessages,"\n");
			for(int i=0;i<intromessages.size();i++){
				if(
					intromessages[i]==""
					||intromessages[i].left(2)=="//"
				){
					intromessages.delete(i);
					i--;
				}
			}
			allmessages=allmessages.mid(dashpos+3);
		}

		//set up array of messages
		allmessages.split(messages,"\n");
		if(messages[0]=="---")messages.delete(0);
		for(int i=0;i<messages.size();i++){
			if(
				messages[i]==""
				||messages[i].left(2)=="//"
			){
				messages.delete(i);
				i--;
			}
		}
	}
	//set the next message to play
	//the bossbrain should be finding the bosseye and calling this from its damagemobj
	void setmessage(){
		int msgsize=messages.size();
		if(!msgsize)return;
		msgsize=random(0,msgsize-1);
		if(remainingmessage=="")remainingmessage=messages[msgsize];
		else remainingmessage=remainingmessage.."__"..messages[msgsize];
		messages.delete(msgsize);
		messageticker=1;
	}
	void playintro(){
		int msgsize=intromessages.size();
		if(!msgsize)return;
		msgsize=random(0,msgsize-1);
		string thismessage=intromessages[msgsize];
		thismessage.replace("/","\n\n\cj");
		double messecs=max(2.,thismessage.length()*0.08);
		A_PrintBold("\cj"..thismessage,messecs,"BIGFONT");
		intromessages.delete(msgsize);
	}
	override void tick(){
		super.tick();

		//see if there's a message to be played
		//countdown to next part of message
		if(
			!messageticker
			&&remainingmessage!=""
		){
			int nextpause=remainingmessage.indexof("_");
			string thismessage;
			if(nextpause<0){
				thismessage=remainingmessage;
				remainingmessage="";
			}else{
				thismessage=remainingmessage.left(nextpause);
				remainingmessage=remainingmessage.mid(nextpause+1);
			}
			thismessage.replace("/","\n\n\cj");
			double messecs=max(2.,thismessage.length()*0.08);
			A_PrintBold("\cj"..thismessage,messecs,"BIGFONT");
			messageticker+=messecs*35;
		}else if(messageticker>0)messageticker--;
	}
	default{
		-solid -shootable +noblockmap +lookallaround
	}
	states{
	spawn:
		TNT1 A 10 A_Look();
		wait;
	see:
		TNT1 A -1 playintro();
		stop;
	}
}










//yet another attempt
//this is good though
class ZomZom:ZombieMan{
	void A_TurnToFace(double threshold=30){
		if(
			!target
			||!checksight(target)
		){
			setstatelabel("see");
			return;
		}
		double totarg=angleto(target);
		double diff=deltaangle(angle,totarg);
		if(abs(diff)<max(0.1,threshold)){
			decidetoaim();
			setstatelabel("aim");
		}else angle+=threshold*frandom(0.6,1.6);
	}
	virtual void decidetoaim(){
		bhittarget=!random(0,5);
	}
	virtual void A_AimAtTarget(
		double threshold=1.,
		double projectilespeed=0,
		double projectilegravity=0,
		double shotheight=999
	){
		if(
			!target
			||!checksight(target)
		){
			setstatelabel("noshot");
			return;
		}
		if(threshold<=0)threshold=0.001;
		double totarg=angleto(target);
		double dist=distance3d(target);
		double dist2=distance2d(target);
		threshold*=1000./dist;

		double diff=deltaangle(angle,totarg);
		if(abs(diff)>max(threshold,30)){
			setstatelabel("turntoshoot");
			return;
		}else if(abs(diff)>frandom(0.001,threshold)){
			angle+=clamp(diff,-threshold,threshold)*frandom(0.6,1.6);
			return;
		}

		setstatelabel("shoot");

		//randomize pitch based on angle aim
		pitch=hdmath.pitchto(pos,target.pos);
		double finaldiff=absangle(angle,totarg);
		pitch+=frandom(-finaldiff,finaldiff);

		//lead the target
		if(
			projectilespeed>0
			&&target.vel!=(0,0,0)
		){
			vector3 leadpos=target.pos+target.vel;
			let ownpos=pos;
			double leadx1=hdmath.angleto(ownpos.xy,target.pos.xy);
			double leady1=hdmath.pitchto(ownpos,target.pos);
			double leadx2=hdmath.angleto(ownpos.xy,leadpos.xy);
			double leady2=hdmath.pitchto(ownpos,leadpos);
			double leadmult=frandom(0.1,1.3)*dist/projectilespeed;
			angle+=leadmult*deltaangle(leadx1,leadx2);
			pitch+=leadmult*deltaangle(leady1,leady2);
		}

		//compensate for drop
		if(
			projectilespeed>0
			&&projectilegravity>0
		){
			double gravtics=dist2/projectilespeed;
			double gravadjust=0;
			if(gravtics>1){
				for(int i=0;i<gravtics;i++){
					gravadjust-=i*projectilegravity;
				}
			}
			pitch+=atan2(gravadjust,dist2);
		}

		//readjust pitch for height of shot and centre of target
		double targheight=target.height*0.6;
		if(shotheight==999)shotheight=HDWeapon.GetShootOffset(self);
		pitch-=atan2(targheight-shotheight,dist2);
	}
	default{
		maxtargetrange 32000;
		+missilemore +missileevenmore
	}
	states{
	missile:
	turntoshoot:
		#### ABCD 4 A_TurnToFace();
		loop;
	aim:
		#### E 3 A_AimAtTarget(
			threshold:(bhittarget?1.:10.),
			projectilespeed:getdefaultbytype("HDB_9").speed,
			projectilegravity:getgravity()
		);
		loop;
	noshot:
		#### E 10;
		#### A 0 SetStateLabel("see");
	shoot:
		#### F 20 bright{HDBulletActor.FireBullet(self,"HDB_9");}
		#### A 0 SetStateLabel("see");
	}
}
