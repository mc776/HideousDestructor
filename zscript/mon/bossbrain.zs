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
		if(!bshootable)return -1;
		if(
			bfriendly
			||damage==TELEFRAG_DAMAGE
		){
			bshootable=false;
			setstatelabel("deathfade");
			return -1;
		}
		forcepain(self);
		bshootable=false;
		while(accuracy<stamina)A_SpawnWaveSpot();
		stamina++;
		accuracy=0;

		for(int i=0;i<MAXPLAYERS;i++){
			if(
				playeringame[i]
				&&players[i].mo
				&&players[i].mo.health>0
			){
				let pmo=players[i].mo;
				pmo.vel+=(pmo.pos-pos).unit()*7;
			}
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
		if(bfriendly||accuracy>stamina)return;
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
