// ------------------------------------------------------------
// Gyro-Grenades and H.E.A.T.
// ------------------------------------------------------------
extend class HDWeapon{
	int airburst;
	action void A_FireHDGL(){
		A_StartSound("weapons/grenadeshot",CHAN_WEAPON,CHANF_OVERLAP);
		let ggg=gyrogrenade(spawn("GyroGrenade",pos+(
				0,0,HDWeapon.GetShootOffset(
					self,invoker.barrellength,
					invoker.barrellength-HDCONST_SHOULDERTORADIUS
				)-2
			),
			ALLOW_REPLACE)
		);
		ggg.angle=angle;ggg.pitch=pitch-2;ggg.target=self;ggg.master=self;
		ggg.primed=false;
		if(invoker.airburst)ggg.airburst=max(10,abs(invoker.airburst))*HDCONST_ONEMETRE;
		invoker.airburst=0;
	}
	action void A_AirburstReady(){
		A_WeaponReady(WRF_NONE);
		int cab=0;
		if(justpressed(BT_ATTACK))cab=-1;
		else if(justpressed(BT_ALTATTACK))cab=1;
		else if(player.cmd.pitch){
			cab=-player.cmd.pitch;
			if(abs(cab)>(1<<9))cab>>=9;else cab=clamp(cab,-1,1);
			HijackMouse();
		}
		int abb=invoker.airburst+cab;
		if(cab<0&&abb<10)abb=0;
		else if(cab>0)abb=max(abb,10);
		invoker.airburst=abb;
	}
	states{
	abadjust:
		---- A 1 A_AirburstReady();
		---- A 0 A_JumpIf(pressingfiremode(),"abadjust");
		goto readyend;
	}
}
extend class HDHandlers{
	void SetAirburst(hdplayerpawn ppp,int abi){
		abi=max(abi>0?10:0,abi);
		let www=hdweapon(ppp.player.readyweapon);
		if(www){
			www.airburst=abi;
			ppp.A_Log(string.format("Airburst set to %i",abi),true);
		}
		return;
	}
}
class GyroGrenade:SlowProjectile{
	bool isrocket;
	default{
		-noextremedeath -noteleport +bloodlessimpact
		height 2; radius 2; scale 0.33;
		speed 110; mass 600; accuracy 0; woundhealth 0;
		obituary "%o was fragged by %k.";
		stamina 5; //used for fuel
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(isrocket)speed*=2;
		A_ChangeVelocity(speed*cos(pitch),0,speed*sin(-pitch),CVF_RELATIVE);
	}
	override void ExplodeSlowMissile(line blockingline,actor blockingobject){
		if(max(abs(skypos.x),abs(skypos.y))>=32768){destroy();return;}
		bmissile=false;

		//bounce
		if(!primed&&random(0,20)){
			if(speed>50)painsound="misc/punch";else painsound="misc/fragknock";
			actor a=spawn("IdleDummy",pos,ALLOW_REPLACE);
			a.stamina=10;a.A_StartSound(painsound,CHAN_AUTO);
			[bmissileevenmore,a]=A_SpawnItemEx("DudRocket",0,0,0,
				random(30,60),random(-10,10),random(-10,10),
				random(0,360),SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS,0
			);
			dudrocket(a).isrocket=isrocket;
			destroy();
			return;
		}

		//damage
		//NOTE: basic impact damage calculation is ALREADY in base SlowProjectile!
		if(blockingobject){
			int dmgg=random(32,128);
			if(primed&&isrocket){
				double dangle=absangle(angle,angleto(blockingobject));
				if(dangle<20){
					dmgg+=random(200,600);
					if(hd_debug)A_Log("CRIT!");
				}else if(dangle<40)dmgg+=random(100,400);
			}
			blockingobject.damagemobj(self,target,dmgg,"Piercing");
		}

		//explosion
		if(!inthesky){
			A_SprayDecal("Scorch",16);
			A_HDBlast(
				pushradius:256,pushamount:128,fullpushradius:96,
				fragradius:HDCONST_SPEEDOFSOUND-10*stamina,fragtype:"HDB_fragRL",
				immolateradius:128,immolateamount:random(3,60),
				immolatechance:isrocket?random(1,stamina):25
			);
			actor xpl=spawn("Gyrosploder",pos-(0,0,1),ALLOW_REPLACE);
			xpl.target=target;xpl.master=master;xpl.stamina=stamina;
		}else{
			distantnoise.make(self,"world/rocketfar");
		}
		A_SpawnChunks("HDB_frag",180,100,700+50*stamina);
		destroy();return;
	}
	states{
	spawn:
		ROCQ A 0;
	spawn1:
		#### B 1;
		#### A 0{
			if(isrocket)setstatelabel("spawnrocket");
			primed=true;
		}
	spawn2:
		#### AB 1;
		loop;
	spawnrocket:
		---- A 0{
			if(!inthesky){
				brockettrail=true;
				Gunsmoke();
				A_StartSound("weapons/rocklaunch",CHAN_VOICE);
			}
		}
		---- AAA 0{
			actor sss=spawn("HDGunSmoke",pos-vel*0.1+(0,0,-4),ALLOW_REPLACE);
			sss.vel=vel*-0.06+(frandom(-2,2),frandom(-2,2),frandom(-2,2));
		}
	spawnrocket2:
		#### BA 1{
			if(self is "HDHEAT")frame=0;
			if(stamina>0){  
				if(!inthesky){
					brockettrail=true;
					actor sss=spawn("HDGunsmoke",pos,ALLOW_REPLACE);
					sss.vel=vel*0.1;
				}else{
					brockettrail=false;
					bgrenadetrail=false;
				}
				A_ChangeVelocity(
					cos(pitch)*60,0,
					sin(-pitch)*60+1,CVF_RELATIVE
				);
				stamina--;
			}
		}
		---- A 0{
			if(primed){
				if(!inthesky)A_StartSound("weapons/rocklaunch",5);
			}else{
				primed=true;
				brockettrail=false;
				if(!inthesky)bgrenadetrail=true;
			}
		}loop;
	death:
		TNT1 A 1;
		stop;
	}
}
class HDHEAT:GyroGrenade{
	default{
		+forcepain
		scale 0.24; woundhealth 1800;
		decal "BrontoScorch";
	}
	override void ExplodeSlowMissile(line blockingline,actor blockingobject){
		if(max(abs(skypos.x),abs(skypos.y))>=32768){destroy();return;}
		bmissile=false;
		//bounce
		//nothing here - HEAT will always explode

		//damage
		if(blockingobject){
			int dmgg=random(70,240);
			double dangle=absangle(angle,angleto(blockingobject));
			if(dangle<20){
				dmgg+=random(2000,4000);
				if(hd_debug)A_Log("CRIT!");
			}else if(dangle<40)dmgg+=random(200,1200);
			blockingobject.damagemobj(self,target,dmgg,"Piercing");
		}else doordestroyer.destroydoor(self,dedicated:true);

		//explosion
		if(!inthesky){
			A_SprayDecal("BrontoScorch",16);
			A_HDBlast(
				pushradius:256,pushamount:128,fullpushradius:96,
				fragradius:1024,fragtype:"HDB_fragRL",
				immolateradius:128,immolateamount:random(3,60),
				immolatechance:2
			);
			actor xpl=spawn("Gyrosploder",self.pos-(0,0,1),ALLOW_REPLACE);
			xpl.target=target;xpl.master=master;xpl.stamina=stamina;
		}else distantnoise.make(self,"world/rocketfar");
		A_SpawnChunks("HDB_frag",80,100,600);

		destroy();return;
	}
	states{
	spawn:
		MISL A 0 nodelay{primed=true;}
		goto spawnrocket;
	}
}

class Gyrosploder:HDActor{
	int ud;
	default{
		+noblockmap +missile +nodamagethrust
		gravity 0;height 6;radius 6;
		damagefactor(0);
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_ChangeVelocity(1,0,0,CVF_RELATIVE);
		distantnoise.make(self,"world/rocketfar");
	}
	states{
	death:
		TNT1 A 0{
			if(ceilingz-pos.z<(pos.z-floorz)*3) ud=-5;
			else ud=5;
		}
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 A_SpawnItemEx("HugeWallChunk", -1,0,ud,
			frandom(-7,7),frandom(-7,7),ud*frandom(1,3),
			frandom(0,360),SXF_NOCHECKPOSITION
		);
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAA 0 A_SpawnItemEx("BigWallChunk", -1,0,ud,
			frandom(-1,6),frandom(-4,4),ud*frandom(1,4),
			frandom(0,360),SXF_NOCHECKPOSITION
		);
		TNT1 AA 0 A_SpawnItemEx("HDSmoke", -1,0,ud,
			frandom(-2,2),frandom(-2,2),0,
			frandom(-15,15),SXF_NOCHECKPOSITION
		);
	xdeath:
	spawn:
		TNT1 A 0 nodelay;
		TNT1 AA 0 A_SpawnItemEx("HDExplosion",
			random(-1,1),random(-1,1),2, 0,0,0,
			0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
		);
		TNT1 A 2 A_SpawnItemEx("HDExplosion",0,0,0,
			0,0,2,
			0,SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
		);
		TNT1 AAAAAAAAAAAAAAA 0 A_SpawnItemEx("BigWallChunk",0,0,1,
			random(-1,6),random(-4,4),random(4,18),
			random(-15,15),SXF_NOCHECKPOSITION
		);
	death2:
		TNT1 AA 0 A_SpawnItemEx("HDSmoke",-1,0,1,
			random(-2,3),random(-2,2),0,
			random(-15,15),SXF_NOCHECKPOSITION
		);
		TNT1 A 21{
			A_AlertMonsters();
			DistantQuaker.Quake(self,4,35,512,10);
		}stop;
	}
}





class HDRocketAmmo:HDAmmo replaces RocketAmmo{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Rocket Grenade"
		//$Sprite "ROQPA0"

		inventory.pickupmessage "Picked up a rocket grenade.";
		scale 0.33;
		tag "rocket grenade";
		hdpickup.refid HDLD_ROCKETS;
		hdpickup.bulk ENC_ROCKET;
		inventory.maxamount (60+40); //never forget
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("HDRL");
		itemsthatusethis.push("Blooper");
		itemsthatusethis.push("HDIEDKit");
	}
	override bool IsUsed(){
		if(!owner)return true;
		for(int i=0;i<itemsthatusethis.size();i++){
			if(owner.countinv(itemsthatusethis[i]))return true;
		}
		let zzz=HDWeapon(owner.findinventory("ZM66AssaultRifle"));
		if(zzz&&!(zzz.weaponstatus[0]&ZM66F_NOLAUNCHER))return true;
		let lll=HDWeapon(owner.findinventory("LiberatorRifle"));
		if(lll&&!(lll.weaponstatus[0]&LIBF_NOLAUNCHER))return true;
		return false;
	}
	states{
	spawn:
		ROQP A -1;
		stop;
	}
}
class HEATAmmo:HDAmmo{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "H.E.A.T. Rocket"
		//$Sprite "ROCKA0"

		+inventory.ignoreskill
		inventory.maxamount (60+40); //never forget
		inventory.pickupmessage "Picked up a H.E.A.T. round.";
		tag "H.E.A.T. rocket";
		hdpickup.refid HDLD_HEATRKT;
		hdpickup.bulk ENC_HEATROCKET;
		xscale 0.24;
		yscale 0.3;
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("HDRL");
	}
	states{
	spawn:
		ROCK A -1;
		stop;
	}
}
class DudRocketAmmo:HDAmmo{
	default{
		+hdpickup.cheatnogive
		inventory.pickupmessage "picked up a defused rocket grenade.";
		inventory.amount 1;
		inventory.maxamount (60+40); //never forget
		radius 2;height 2;
		scale 0.33;
		tag "dud rocket";
		hdpickup.bulk ENC_ROCKET;
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("HDIEDKit");
	}
	states{
	spawn:
		ROCQ A -1;stop;
	}
}
class DudRocket:HDUPK{
	bool isrocket;
	default{
		projectile; -nogravity -noteleport +bounceonactors
		-noblockmap -grenadetrail -floorclip +forcexybillboard
		+nodamagethrust +noblood
		bouncetype "doom"; decal "none";
		mass 30; pushfactor 3.4; bouncefactor 0.3; gravity 1;
		deathsound "misc/fragknock";
		bouncesound "misc/fragknock";
		wallbouncesound "misc/fragknock";
		obituary "%o was fragged by %k.";
		hdupk.pickupmessage "picked up (and defused) a rocket grenade.";
		damagefactor(0);
		radius 2; height 2; scale 0.33;
	}
	states{
	spawn:
		ROCQ A 0 A_Jump(256,"clean");
		ROCQ AB 2 A_SetAngle(angle+45);
		loop;
	death:
		ROCQ A 0{
			return; //why did we have these flags anyway?
			bmissile=false;
			bpushable=true;
			bshootable=true;
			bsolid=true;
		}
	dead:
		ROCQ A 0 A_Jump(64,"clean");
		ROCQ A 1 A_SetTics(random(21000,isrocket?random(21000,100000):100000));
		ROCQ A 0 A_Jump(64,"dead");
		goto explode;
	clean:
		ROCQ A -1;
		stop;
	explode:
		---- A 0{
			A_HDBlast(
				pushradius:256,pushamount:128,fullpushradius:96,
				fragradius:HDCONST_SPEEDOFSOUND-10*stamina,fragtype:"HDB_fragRL",
				immolateradius:128,immolateamount:random(3,60),
				immolatechance:25
			);
			actor xpl=spawn("Gyrosploder",self.pos-(0,0,1),ALLOW_REPLACE);
			xpl.target=target;xpl.master=master;xpl.stamina=stamina;
			A_SpawnChunks("HDB_frag",180,100,700+50*stamina);
		}stop;
	give:
		---- A 0 A_JumpIfInTargetInventory("DudRocketAmmo",0,3);
		---- A 0 A_GiveToTarget("DudRocketAmmo",1);
		---- A 0 A_StartSound("weapons/grenopen");
		stop;
		ROCQ A 0 A_Jump(1,"Explode");
		ROCQ A 0 spawn("DudRocketAmmo",pos,ALLOW_REPLACE);
		stop;
	}
}

