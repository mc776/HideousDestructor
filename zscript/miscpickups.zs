//-------------------------------------------------
// Map replacers
//-------------------------------------------------
class HDInvRandomSpawner:RandomSpawner{
	override void beginplay(){
		if(!level.ispointinlevel(pos))return;
		let hhh=HDHandlers(eventhandler.find("HDHandlers"));
		if(hhh){
			hhh.invposx.push(pos.x);
			hhh.invposy.push(pos.y);
			hhh.invposz.push(pos.z);
		}
		super.beginplay();
	}
}
class ClipMagPickup:HDInvRandomSpawner replaces Clip{
	default{
		dropitem "HD4mMag",256,24;
		dropitem "HD9mMag15",256,4;
		dropitem "HD9mMag30",256,2;
		dropitem "ArmorBonus",256,2;
		dropitem "HD9mBoxPickup",256,1;
		dropitem "HD355BoxPickup",256,1;
	}
}
class ClipBoxPickup:HDInvRandomSpawner replaces ClipBox{
	default{
		dropitem "ClipBoxPickup1",256,14;
		dropitem "ClipBoxPickup2",256,4;
		dropitem "HDAB",256,6;
		dropitem "BossRifleSpawner",256,1;
		dropitem "HD9mBoxPickup",256,1;
		dropitem "HD7mBoxPickup",256,1;
		dropitem "HD355BoxPickup",256,1;
	}
}
class ClipBoxPickup1:IdleDummy{
	override void postbeginplay(){
		super.postbeginplay();
		A_SpawnItemEx("HD4mMag",flags:SXF_NOCHECKPOSITION);
		if(random(0,2))A_SpawnItemEx("HDFragGrenadeAmmo",-3,-3,flags:SXF_NOCHECKPOSITION);
		if(random(0,2)){
			A_SpawnItemEx("HDRocketAmmo",3,3,flags:SXF_NOCHECKPOSITION);
			A_SpawnItemEx("ZM66AssaultRifle",1,1,flags:SXF_NOCHECKPOSITION);
		}else A_SpawnItemEx("ZM66Random",1,1,flags:SXF_NOCHECKPOSITION);
		destroy();
	}
}
class ClipBoxPickup2:IdleDummy{
	override void postbeginplay(){
		super.postbeginplay();
		A_SpawnItemEx("HD9mMag30",flags:SXF_NOCHECKPOSITION);
		if(random(0,2))A_SpawnItemEx("HDFragGrenadeAmmo",-3,-3,flags:SXF_NOCHECKPOSITION);
		if(random(0,2))A_SpawnItemEx("HD9mMag30",3,3,flags:SXF_NOCHECKPOSITION);
		A_SpawnItemEx("HDSMGRandom",1,1,flags:SXF_NOCHECKPOSITION);
		destroy();
	}
}
class ShellRandom:HDInvRandomSpawner replaces Shell{
	default{
		dropitem "ShellPickup",256,8;
		dropitem "HDFumbledShell",256,4;
		dropitem "DecoPusher",200,4;
		dropitem "BFGNecroShard",200,1;
		dropitem "HDBattery",256,1;
		dropitem "HD4mMag",256,1;
		dropitem "HDAB",200,1;
		dropitem "DoorBuster",256,1;
		dropitem "YokaiSpawner",128,1;
	}
}
class ShellBoxRandom:HDInvRandomSpawner replaces ShellBox{
	default{
		dropitem "ShellBoxPickup",256,10;
		dropitem "DecoPusher",200,1;
		dropitem "HDBattery",256,2;
		dropitem "HDAB",256,1;
		dropitem "HDFragGrenadePickup",256,1;
		dropitem "HD9mBoxPickup",256,1;
		dropitem "HD7mBoxPickup",256,1;
	}
}
class RocketBoxRandom:HDInvRandomSpawner replaces RocketBox{
	default{
		dropitem "RocketBigPickup",256,14;
		dropitem "HDFragGrenadePickup",256,3;
		dropitem "PortableLadder",256,1;
		dropitem "HD9mBoxPickup",256,1;
		dropitem "HD7mBoxPickup",256,1;
	}
}
class CellRandom:HDInvRandomSpawner replaces Cell{
	default{
		dropitem "BFGNecroShard",128,1;
		dropitem "HD7mMag",256,3;
		dropitem "BrontornisRound",256,2;
		dropitem "HDBattery",256,7;
	}
}
class CellPackReplacer:HDInvRandomSpawner replaces CellPack{
	default{
		dropitem "BFGNecroShard",196,1;
		dropitem "HD7mMag",256,3;
		dropitem "BrontornisSpawner",256,1;
		dropitem "HDBattery",256,4;
		dropitem "HDAB",256,1;
		dropitem "PortableLadder",256,1;
		dropitem "YokaiSpawner",256,1;
		dropitem "HDFragGrenadePickup",256,1;
		dropitem "HD9mBoxPickup",256,1;
		dropitem "HD7mBoxPickup",256,1;
		dropitem "DoorBuster",256,1;
	}
}




//-------------------------------------------------
// The box of MYSTERY!
//-------------------------------------------------
class HDAB:RandomSpawner{
	default{
		dropitem "HDAmBox",256,1;
		dropitem "HDAmBoxUnarmed",256,5;
	}
}
class HDAmBox:HDUPK{
	default{
		//$Category "Misc/Hideous Destructor/Traps"
		//$Title "Ammo Box"
		//$Sprite "AMMOA0"

		+shootable +noblood +nopain +ghost
		+lookallaround +nofear
		scale 0.6;
		height 8; radius 12;
		health 100; mass 120;
		meleerange 42;
		radiusdamagefactor 0.5;
		hdambox.maxcapacity 200.;
		obituary "%o paid no attention to Admiral Ackbar.";
		tag "ammo box";
	}
	bool tapped;
	bool disarmed;
	int disarmsteps;
	int skullkey;
	override void postbeginplay(){
		super.postbeginplay();
		if(!random(0,7))skullkey=random(1,3);else skullkey=0;
		disarmed=false;
		disarmsteps=random(5,10);
	}
	void TryDisarm(actor user){
		if(
			bnointeraction
			||!user
			||user.countinv("IsMoving")
		)return;
		if(tapped){
			if(disarmed)setstatelabel("goodies");
			else if(
				!random(0,63)
				||skullkey==1&&user.countinv("RedSkull")
				||skullkey==2&&user.countinv("YellowSkull")
				||skullkey==3&&user.countinv("BlueSkull")
			)setstatelabel("disarm");
			else{
				target=user;
				setstatelabel("trapped");
			}
			return;
		}else if(!disarmed&&disarmsteps<1){
			setstatelabel("disarm");
			return;
		}else{
			vel.z++;
			tapped=true;
			bool tt=false;
			if(random(0,3)&&distance3d(user)<42)disarmsteps--;
			setstatelabel("tap");
			return;
		}
	}
	void A_DropStuff(
		class<actor> type,
		int amount=1
	){
		for(int i=0;i<amount;i++)A_SpawnItemEx(type,
			frandom(-4,4),frandom(-4,4),5,
			frandom(0,3),0,frandom(-4,4),
			frandom(1,360),SXF_NOCHECKPOSITION
		);
	}
	double maxcapacity;
	property maxcapacity:maxcapacity;
	virtual void SpawnContents(){
		array<string> invclasses;invclasses.clear();

		//retrieve list of HDAmmo items
		for(int i=0;i<allactorclasses.size();i++){
			let iic=(class<HDAmmo>)(allactorclasses[i]);
			if(!iic)continue;
			let iid=getdefaultbytype(iic);
			if(
				iid
				&&iid.bfitsinbackpack
				&&!iid.binvbar
				&&iid.refid!=""
				&&!FourMilAmmo(iid) //why does bare 4mm even have a refid!??!
				&&(
					(
						(class<HDMagAmmo>)(iic)
						&&
							(
								getdefaultbytype((class<HDMagAmmo>)(iic)).maxperunit
								*getdefaultbytype((class<HDMagAmmo>)(iic)).roundbulk
							)
							+getdefaultbytype((class<HDMagAmmo>)(iic)).magbulk
						<maxcapacity
					)||(
						!(class<HDMagAmmo>)(iic)
						&&iid.bulk<maxcapacity
						&&iid.bulk>0
					)
				)
			)invclasses.push(iic.getclassname());
		}

		//pick one of them at random
		let iic=(class<HDAmmo>)(invclasses[random(0,invclasses.size()-1)]);
		let iid=getdefaultbytype(iic);
		if(iid){
			double iiu=
					HDMagAmmo(iid)?(
						HDMagAmmo(iid).maxperunit
							*HDMagAmmo(iid).roundbulk
							+HDMagAmmo(iid).magbulk
					):iid.bulk;
			if(!iiu)iiu=iid.bulk;
			if(hd_debug&&!iiu)A_Log(iid.getclassname().." has an effective unit bulk of zero.");
			A_DropItem(iic,int(maxcapacity*frandom(0.1,1.)/iiu));
		}
	}
	states{
	grab:
		---- A 0 TryDisarm(picktarget);
	tap:
		---- A 10;
		---- A 0{tapped=false;}
	spawn:
		AMMO A -1;
		stop;
	death:
	trapped:
		---- A 3 A_StartSound("misc/boxtrapped",CHAN_WEAPON);
		---- A 0{
			tapped=false;
			switch(random(0,5)){
			case 1:
				A_SpawnItemEx("BFGNecroShard",
					flags:SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
				);
				break;
			case 2:
				A_SpawnItemEx("YokaiSpawner",
					flags:SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
				);
				break;
			case 3:
				A_FaceTarget(0,0);
				angle+=frandom(-20,20);
				pitch+=frandom(-20,20);
				HDBulletActor.FireBullet(self,"HDB_9",zofs:2,spread:2.,speedfactor:frandom(0.97,1.03));
				A_SpawnItemEx("HDSpent9mm", -3,1,-1,
					random(-1,-3),random(-1,1),random(-3,-4),
					0,SXF_NOCHECKPOSITION|SXF_SETTARGET
				);
				A_StartSound("weapons/pistol",CHAN_VOICE);
				break;
			case 4:
				A_SpawnItemEx("HDFragGrenade",
					0,0,10,1,0,3,
					0,SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
				);
				A_SpawnItemEx("HDFragSpoon",0,0,10,
					random(3,6),0,random(8,16),
					random(-12,12),SXF_NOCHECKPOSITION
				);
				break;
			default:
				spawn("HDExplosion",pos,ALLOW_REPLACE);
				A_Explode(64,64);
				break;
			}
		}goto brokengoodies;
	disarm:
		---- A 0{
			if(!random(0,63)){
				setstatelabel("trapped");
				return;
			}
			class<actor> deadtrap="HDFragGrenadeAmmo";
			int rnd=random(0,3);
			switch(rnd){
			case 1:
			case 2:
				deadtrap="BFGNecroShard";
				break;
			case 3:
				deadtrap="HDLoose9mm";
				break;
			default:
				break;
			}
			A_DropItem(deadtrap);
			A_SpawnItemEx("HDAmBoxDisarmed",0,0,1,flags:SXF_NOCHECKPOSITION);
		}stop;
	goodies:
		---- A 2 A_StartSound("weapons/pocket",CHAN_VOICE);
		---- A 0 A_JumpIf(Wads.CheckNumForName("id",0)!=-1,2);
		AMBX B 0 A_SpawnItemEx("HDFader",flags:SXF_TRANSFERSPRITEFRAME|SXF_TRANSFERSCALE|SXF_TRANSFERRENDERSTYLE);
		---- A 0 SpawnContents();
		stop;
	brokengoodies:
		---- A 0 A_StartSound("weapons/plasmax",CHAN_VOICE);
		---- A 0 A_DropStuff("HDSmokeChunk",random(0,6));
		---- AAA 0 A_SpawnItemEx("HDSmoke",
			frandom(-1,1),frandom(-1,1),frandom(-1,1),
			0,0,frandom(0,2),0,SXF_NOCHECKPOSITION
		);
		goto brokenmisc;
		---- A 0 A_Jump(256,
			"brokenmisc",
			"brokenzeds","brokensmgs","brokenpiss",
			"brokenlibs","brokenclip","brokenrocs",
			"brokenbron","brokencell","brokenshel"
		);
	brokenmisc:
		---- A 0{
			maxcapacity*=0.2;
			SpawnContents();
		}
		---- AAAAAAA 0 A_SpawnItemEx("HugeWallChunk",
			frandom(-3,3),frandom(-3,3),frandom(1,8),
			frandom(-10,10),frandom(-10,10),frandom(-3,8),
			0,SXF_NOCHECKPOSITION
		);
		---- AAA 0 A_SpawnItemEx("HDSmokeChunk",
			frandom(-10,10),frandom(-10,10),frandom(1,10),
			frandom(-4,4),frandom(-4,4),frandom(0,2),
			0,SXF_NOCHECKPOSITION,24
		);
		---- A 0 A_SpawnItemEx("HDExplosion",
			frandom(-1,1),frandom(-1,1),frandom(3,4),
			0,0,frandom(0,2),0,SXF_NOCHECKPOSITION,32
		);
		stop;
	brokenzeds:
		---- A 0 A_DropItem("HD4mMag");
		---- AAA 0 A_DropItem("HD4mmMagEmpty");
		---- A 0 A_SpawnItemEx("HDSmokeChunk",
			frandom(-10,10),frandom(-10,10),frandom(1,10),
			frandom(-4,4),frandom(-4,4),frandom(0,2),
			0,SXF_NOCHECKPOSITION,24
		);
		stop;
	brokensmgs:
		---- A 0 A_DropItem("HD9mMag30");
		---- AA 0 A_DropItem("HDSMGEmptyMag");
		---- A 0 A_DropStuff("HDSpent9mm",random(14,30));
		---- A 0 A_DropStuff("HDLoose9mm",random(4,12));
		stop;
	brokenpiss:
		---- A 0 A_DropItem("HD9mMag15");
		---- AAAA 0 A_DropItem("HDPistolEmptyMag");
		---- A 0 A_DropStuff("HDSpent9mm",random(12,20));
		---- A 0 A_DropStuff("HDLoose9mm",random(8,16));
		stop;
	brokenlibs:
		---- A 0 A_DropItem("HD7mMag");
		---- A 0 A_DropItem("LiberatorEmptyMag");
		---- A 0 A_DropStuff("HDSpent7mm",random(7,14));
		---- A 0 A_DropStuff("HDLoose7mm",random(6,10));
		stop;
	brokenclip:
		---- A 0 A_DropItem("HD7mClip");
		---- A 0 A_DropStuff("HDSpent7mm",random(12,20));
		---- A 0 A_DropStuff("HDLoose7mm",random(12,30));
		stop;
	brokenrocs:
		---- A 0 A_DropItem("HDRocketAmmo");
		---- AA 0 A_DropItem("DudRocket");
		stop;
	brokenbron:
		---- A 0 A_DropItem("BrontornisRound");
		---- AAA 0 A_SpawnItemEx("HDSmoke",
			frandom(-10,10),frandom(-10,10),frandom(1,10),
			0,0,frandom(0,2),0,SXF_NOCHECKPOSITION
		);
		---- AAA 0 A_SpawnItemEx("HDGunSmoke",
			frandom(-1,1),frandom(-1,1),frandom(2,10),
			0,0,frandom(0,2),0,SXF_NOCHECKPOSITION
		);
		---- A 0{
			let bbb=HDBulletActor.FireBullet(
				self,"HDB_bronto",
				zofs:1.,
				aimoffy:90
			);
		}
		---- AAAA 0 A_SpawnItemEx("HDSmokeChunk",
			frandom(-10,10),frandom(-10,10),frandom(1,10),
			frandom(-6,6),frandom(-6,6),frandom(0,4),
			0,SXF_NOCHECKPOSITION,24
		);
		stop;
	brokencell:
		---- A 0 A_DropItem("HDCellPackEmpty");
		---- A 0 A_DropItem("HDBattery");
		---- AAA 0 A_SpawnItemEx("HDSmoke",
			frandom(-1,1),frandom(-1,1),frandom(1,4),
			0,0,frandom(0,2),0,SXF_NOCHECKPOSITION
		);
		---- AAA 0 A_SpawnItemEx("HDGunSmoke",
			frandom(-1,1),frandom(-1,1),frandom(1,10),
			0,0,frandom(0,2),0,SXF_NOCHECKPOSITION
		);
		---- A 0 A_SpawnItemEx("HDExplosion",
			frandom(-1,1),frandom(-1,1),frandom(3,4),
			0,0,frandom(0,2),0,SXF_NOCHECKPOSITION
		);
		TNT1 A 0{bnointeraction=true;}
		TNT1 AAAAAA random(1,8) ArcZap(self);
		stop;
	brokenshel:
		---- A 0 A_DropItem("ShellPickup");
		---- A 0 A_DropStuff("HDFumblingShell",random(8,12));
		---- A 0 A_DropStuff("HDSpentShell",random(4,8));
		stop;
	}
}
class HDAmBoxUnarmed:HDAmBox{
		//$Category "Misc/Hideous Destructor/Traps"
		//$Title "Ammo Box(Unarmed)"
		//$Sprite "OWWVA0"

	override void postbeginplay(){
		hdactor.postbeginplay();
		disarmed=true;
	}
}
class HDAmBoxDisarmed:HDAmBoxUnarmed{
	default{
		tag "disarmed ammo box";
	}
	states{
	spawn:
		OWWV A -1 nodelay{
			tapped=true;
		}stop;
	grab:
		goto goodies;
	}
}


//-------------------------------------------------
// Health/armour bonus replacers
//-------------------------------------------------
class HDFragGrenadePickup:FragP{
	override void postbeginplay(){
		super.postbeginplay();
		A_SpawnItemEx("FragP",-4,0,flags:SXF_NOCHECKPOSITION);
		A_SpawnItemEx("FragP",-4,4,flags:SXF_NOCHECKPOSITION);
		A_SpawnItemEx("FragP",0,4,flags:SXF_NOCHECKPOSITION);
		A_SpawnItemEx("FragP",4,0,flags:SXF_NOCHECKPOSITION);
		A_SpawnItemEx("FragP",4,4,flags:SXF_NOCHECKPOSITION);
	}
}

class DecoPusher:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			int times=random(1,5);
			class<actor> thingy="HDGoreBits";
			if(!random(0,64)){
				if(!random(0,6))thingy="InnocentBarrel";
				else thingy="InnocentFireCan";
			}else if(!random(0,2)){
				times=random(2,6);
				switch(random(0,3)){
				case 0: thingy="HDSpentShell";times*=random(1,3);break;
				case 1: thingy="HDSpent9mm";times*=random(1,5);break;
				case 2: thingy="HDSpent7mm";break;
				case 3: thingy="TerrorCasing";times=random(1,3);break;
				}
			}
			flinetracedata spawnpos;
			for(int i=0;i<times;i++){
				LineTrace(
					frandom(0,360),frandom(0,96),frandom(-45,45),
					offsetz:32,
					data:spawnpos
				);
				actor aaa=spawn(thingy,spawnpos.hitlocation-spawnpos.hitdir,ALLOW_REPLACE);
				if(aaa)aaa.setz(aaa.floorz);
			}
		}stop;
	}
}
class HDCasingBits:RandomSpawner{
	default{
		dropitem "HDFumblingShell",256,1;
		dropitem "HDSpentShell",256,9;
		dropitem "HDSpent9mm",256,24;
		dropitem "HDSpent7mm",256,6;
		dropitem "TerrorCasing",256,1;
	}
}
class HDGoreBits:RandomSpawner{
	default{
		dropitem "DeadDemon",126,1;
		dropitem "DeadDoomImp",126,1;
		dropitem "DeadZombieMan",96,1;
		dropitem "DeadShotgunGuy",96,1;
		dropitem "DeadRifleman",96,1;
		dropitem "ReallyDeadRifleman",46,1;
		dropitem "ColonGibs",256,4;
		dropitem "Gibs",256,6;
		dropitem "SmallBloodPool",256,8;
		dropitem "BarrelGibs",256,8;
		dropitem "HDCasingBits",256,32;
		dropitem "HDFumbledShell",256,8;
		dropitem "HDSMGEmptyMag",256,3;
		dropitem "HDPistolEmptyMag",256,3;
		dropitem "LiberatorEmptyMag",96,1;
		dropitem "HD4mmMagEmpty",256,8;
	}
}
class HelmFrag:HDInvRandomSpawner replaces ArmorBonus{
	default{
		dropitem "DecoPusher",96,20;
		dropitem "SpiritualArmour",96,2;
		dropitem "HDFragGrenades",72,1;
		dropitem "HD7mMag",48,1;
		dropitem "HD4mMag",48,1;
		dropitem "BFGNecroShard",96,1;
		dropitem "HDBattery",48,1;
		dropitem "PortableStimpack",48,1;
		dropitem "ClipBox",48,1;
		dropitem "HDAB",48,1;
	}
}
class BlueFrag:HDInvRandomSpawner replaces HealthBonus{
	default{
		dropitem "DecoPusher",96,20;
		dropitem "BluePotion",96,2;
		dropitem "HDFragGrenades",72,1;
		dropitem "BFGNecroShard",96,1;
		dropitem "HD9mMag15",48,1;
		dropitem "HDBattery",72,1;
		dropitem "PortableMedikit",48,1;
		dropitem "PortableStimpack",48,1;
		dropitem "HDAB",48,1;
	}
}





//-------------------------------------------------
// BIG BALLS
//-------------------------------------------------
class RedSphere:HDInvRandomSpawner replaces BlurSphere{
	default{
		dropitem "SquadSummoner",256,14;
		dropitem "HDFragGrenades",256,6;
		dropitem "HDBlurSphere",256,1;
		dropitem "GarrisonArmour",256,2;
		dropitem "BluePotion",256,2;
		dropitem "HDJetpack",256,1;
	}
}
class BlueSphere:HDUPK replaces Soulsphere{
	default{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Soul Sphere"
		//$Sprite "SOULA0"

		+floatbob
		alpha 0.8;
		scale 0.8;
		stamina 777;
	}
	override void A_HDUPKGive(){
		if(!picktarget||bnointeraction)return;
		bnointeraction=true;
		PlantBit.SpawnPlants(self,70,144);
		let hdp=hdplayerpawn(picktarget);
		if(hdp)hdp.regenblues+=stamina;
		else picktarget.givebody(stamina);
		setstatelabel("fadeout");
	}
	states{
	spawn:
		SOUL ABCDCB random(2,7) bright light("SOULSPHERE");
		loop;
	fadeout:
		---- A 0{
			vel.z=0.6;
			gravity=0;
			A_StartSound("misc/p_pkup",CHAN_BODY);
		}
		---- A 1 bright{
			vel.xy*=0.6;
			A_SetScale(scale.x*1.01);
			A_FadeOut(0.06);
			A_SpawnItemEx("HDGunSmoke",
				frandom(-1,1),0,frandom(3,6),
				frandom(-1,1),0,1,frandom(0,360),
				SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM|SXF_ABSOLUTEPOSITION
			);
		}wait;
	}
}
class BrownSphere:BlueSphere replaces Megasphere{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Megasphere"
		//$Sprite "MEGAA0"

	override void A_HDUPKGive(){
		if(!picktarget||bnointeraction)return;
		picktarget.A_GiveInventory("SpiritualArmour",1);
		super.A_HDUPKGive();
	}
	states{
	spawn:
		MEGA ABCD random(2,7) bright;
		loop;
	}
}
class PlantBit:IdleDummy{
	default{
		+movewithsector
		+flatsprite
		alpha 0;
		renderstyle "translucent";
		height 3;radius 1;
	}
	vector2 tinyscale;
	override void postbeginplay(){
		super.postbeginplay();
		setz(floorz);
		scale.x=randompick(-1,1)*frandom(0.4,1.1);
		scale.y=frandom(0.4,1.1);
		frame=random(0,random(0,6));
		angle=frandom(0,360);
		pitch=frandom(-70,-90);
		roll=frandom(-0.4,0.4);
		tinyscale=scale*0.1;
		scale=tinyscale;
	}
	static void SpawnPlants(actor caller,int plants=12,double radius=33){
		double negradius=-radius*0.12;
		for(int i=0;i<plants;i++){
			caller.A_SpawnItemEx("PlantBit",frandom(negradius,radius),angle:frandom(0,360));
		}
	}
	void A_PlantGrow(){
		alpha+=0.1;
		scale+=tinyscale;
	}
	states{
	spawn:
		SPLT A 1 nodelay A_SetTics(random(30,3000));
		SPLT ### 3 A_PlantGrow();
		SPLT #### 1 A_PlantGrow();
		SPLT ### 2 A_PlantGrow();
		SPLT # 1 A_SetTics(random(3000,30000));
		SPLT AAAAAAAAAAAA 0 A_SpawnParticle("tan",0,70,frandom(1.5,2.4),zoff:frandom(0,5),
			velx:frandom(-0.1,0.1),vely:frandom(-0.1,0.1),velz:frandom(-0.2,0.4)
		);
		stop;
	}
}
class GreenSphere:BlueSphere replaces Invulnerabilitysphere{
	default{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Invulnerability Sphere"
		//$Sprite "PINVA0"

		-floatbob -nogravity
		+shootable +noblood
		renderstyle "normal";
		scale 0.6;
		health 200;
		mass 1000;
		height 12;
		radius 12;
	}
	override void A_HDUPKGive(){
		if(bnointeraction||health<1||!picktarget)return;
		bnointeraction=true;
		picktarget.A_GiveInventory("HDInvuln");
		picktarget.A_Quake(3,26,0,220,"none");
		blockthingsiterator itt=blockthingsiterator.create(picktarget,256);
		while(itt.Next()){
			A_Immolate(itt.thing,picktarget,76);
		}
		for(int i=45;i<360;i+=90){
			picktarget.A_SpawnItemEx("HDExplosion",
				4,-4,20,picktarget.vel.x,picktarget.vel.y,picktarget.vel.z+1,i,
				SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS|SXF_ABSOLUTEMOMENTUM
			);
			picktarget.A_SpawnItemEx("HDSmokeChunk",0,0,0,
				picktarget.vel.x+frandom(-12,12),
				picktarget.vel.y+random(-12,12),
				picktarget.vel.z+frandom(4,16),
				0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
			);
		}
		destroy();
	}
	states{
	spawn:
		PINV ABCD 6 bright;
		loop;
	death.telefrag:
		TNT1 A 0{
			if(target){
				picktarget=target;
				A_HDUPKGive();
			}else setstatelabel("death");
		}stop;
	death:
		TNT1 A 1{
			spawn("LightBearer",pos,ALLOW_REPLACE);
			A_CallSpecial(special,args[0],args[1],args[2],args[3],args[4]);
			for(int i=45;i<360;i+=90){
				A_SpawnItemEx("HDExplosion",
					4,-4,20,vel.x,vel.y,vel.z+1,i,
					SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS|SXF_ABSOLUTEMOMENTUM
				);
				A_SpawnItemEx("HDSmokeChunk",0,0,0,
					vel.x+frandom(-12,12),
					vel.y+random(-12,12),
					vel.z+frandom(4,16),
					0,SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
				);
			}
			A_Quake(3,26,0,220,"none");
		}
		TNT1 AAAAA 2 A_SpawnItemEx("HDSmoke",
			frandom(-4,4),frandom(-4,4),frandom(1,4),
			flags:SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
		);
		TNT1 AAAAA 4 A_SpawnItemEx("HDSmoke",
			frandom(-4,4),frandom(-4,4),frandom(1,4),
			flags:SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
		);
		stop;
	}
}
class HDInvuln:InvulnerabilitySphere{
	default{
		+inventory.persistentpower
		Powerup.Duration -90;
	}
}




//-------------------------------------------------
// Keys
//-------------------------------------------------
class MapLoadoutGiver:HDPickup{
	default{
		-hdpickup.fitsinbackpack
		hdpickup.refid HDLD_MAP;
		tag "local area map";
	}
	states{
	spawn:TNT1 A 0;stop;
	pickup:
		TNT1 A 0 A_GiveInventory("MapRevealer");
		fail;
	}
}
class KeyLoadoutGiver:HDPickup{
	default{
		-hdpickup.fitsinbackpack
		inventory.maxamount 7;
		hdpickup.refid HDLD_KEY;
		tag "keys";
	}
	states{
	spawn:TNT1 A 0;stop;
	pickup:
		TNT1 A 0{
			int whichkeys=invoker.amount;
			if(whichkeys&4)A_GiveInventory("BlueCard");
			if(whichkeys&2)A_GiveInventory("YellowCard");
			if(whichkeys&1)A_GiveInventory("RedCard");
		}fail;
	}
}
class HDUPKAlwaysGive:HDUPK{
	class<inventory> toallplayers;property toallplayers:toallplayers;
	string msgtoall;property msgtoall:msgtoall;
	default{
		hdupkalwaysgive.toallplayers "";
		hdupkalwaysgive.msgtoall "";
	}
	override void OnGrab(actor grabber){
		//this must be called again when using a grab state
		A_CallSpecial(special,args[0],args[1],args[2],args[3],args[4]);
		special=0;

		if(toallplayers!=""){
			for(int i=0;i<MAXPLAYERS;i++){
				if(playeringame[i]&&players[i].mo){
					players[i].mo.A_GiveInventory(toallplayers);
				}
			}
			if(msgtoall!="")A_Log(msgtoall);
			setstatelabel("give");
		}
	}
}
class HDKeyLight:PointLight{
	override void tick(){
		if(!target)destroy();
		else{
			args[3]=(target.frame)?0:8;
			setorigin(target.pos,true);
		}
	}
}
class HDRedKey:HDUPKAlwaysGive replaces RedCard{
	default{
		hdupkalwaysgive.toallplayers "RedCard";
		hdupkalwaysgive.msgtoall "\crRED\c- local area clearance code downloaded.";
	}
	override void PostBeginPlay(){
		super.PostBeginPlay();
		actor lite=spawn("HDKeyLight",pos,ALLOW_REPLACE);
		lite.target=self;
		if(sprite==getspriteindex("YKEYA0")){
			lite.args[0]=128;
			lite.args[1]=128;
			lite.args[2]=0;
		}else if(sprite==getspriteindex("BKEYA0")){
			lite.args[0]=64;
			lite.args[1]=64;
			lite.args[2]=128;
		}else{
			lite.args[0]=256;
			lite.args[0]=64;
			lite.args[0]=64;
		}
	}
	states{
	spawn:
		RKEY A 0;
	spawn1:
		#### ABABABAB 2;
		#### ABABABABABABABAB 3;
		#### ABABAB 6;
	spawn2:
		---- A 1 A_SetTics(random(1,1000));
	spawn3:
		#### AB 1 A_SetTics(random(1,5));
		---- A 0 A_Jump(16,"spawn2");
		loop;
	give:
	beep:
	grab:
		---- A 0{
			if(target)angle=angleto(target);
			A_StartSound("misc/i_pkup",12);
		}goto spawn1;
	}
}
class HDBlueKey:HDRedKey replaces BlueCard{
	default{
		hdupkalwaysgive.toallplayers "BlueCard";
		hdupkalwaysgive.msgtoall "\cnBLUE\c- local area clearance code downloaded.";
	}
	states{
	spawn:
		BKEY A 0;
		goto spawn1;
	}
}
class HDYellowKey:HDRedKey replaces YellowCard{
	default{
		hdupkalwaysgive.toallplayers "YellowCard";
		hdupkalwaysgive.msgtoall "\cfYELLOW\c- local area clearance code downloaded.";
	}
	states{
	spawn:
		YKEY A 0;
		goto spawn1;
	}
}
class HDRedSkull:HDUPK replaces RedSkull{
	default{
		scale 0.6;
		radius 6;
		renderstyle "translucent";
		alpha 0.75;
		missiletype "RedSkull";
		hdupk.pickupmessage "\crRED\c-, the way of the blood shed for you in vain.";
	}
	override void ongrab(actor grabber){
		target=grabber;
		grabber.A_GiveInventory(missilename);
		setstatelabel("effect");
	}
	override  void A_HDUPKGive(){}
	states{
	spawn:
		RSKU AB 1 light("REDKEY") A_SetTics(random(1,6));
		loop;
	effect:
		#### ABAB 1 bright;
		---- A 0 A_StartSound("brain/cube",666,CHANF_LOCAL);
		---- A 0 A_DamageTarget(1);
		#### ##### 1 A_SpawnItemEx("HDSmoke",0,0,0,random(4,0),random(-2,2),random(1,3),0,SXF_NOCHECKPOSITION);
		---- A 0{
			A_GiveToTarget("IsMoving",99);
			A_GiveToTarget(missilename);
			target.A_Log(pickupmessage,true);
		}
		---- A 0 A_Jump(256,"spawn");
	}
}
class HDBlueSkull:HDRedSkull replaces BlueSkull{
	default{
		missiletype "BlueSkull";
		hdupk.pickupmessage "\cnBLUE\c-, the way of the heaven forever lost to you.";
	}
	states{
	spawn:
		BSKU AB 1 light("HEALTHPOTION") A_SetTics(random(1,3));
		loop;
	}
}
class HDYellowSkull:HDRedSkull replaces YellowSkull{
	default{
		missiletype "YellowSkull";
		hdupk.pickupmessage "\cfYELLOW\c-, the way of the gold that has lured all mankind to death.";
	}
	states{
	spawn:
		YSKU AB 1 light("YELLOWKEY") A_SetTics(random(1,3));
		loop;
	}
}

class HDMap:HDUPKAlwaysGive replaces Allmap{
	default{
		scale 0.3;
		hdupkalwaysgive.toallplayers "MapRevealer";
		hdupkalwaysgive.msgtoall "\c-Local area map downloaded.";
	}
	states{
	give:
		PMAP A 0 A_StartSound("misc/i_pkup",12,CHANF_LOCAL);
	//fallthrough to spawn
	spawn:
		PMAP A 0 nodelay A_Jump(256,"a","b","c","d");
	a:
		PMAP AE 1 A_SetTics(random(1,3));
		---- A 0 A_Jump(4,"spawn");
		loop;
	b:
		PMAP BF 1 A_SetTics(random(1,3));
		---- A 0 A_Jump(4,"spawn");
		loop;
	c:
		PMAP CG 1 A_SetTics(random(1,3));
		---- A 0 A_Jump(4,"spawn");
		loop;
	d:
		PMAP DH 1 A_SetTics(random(1,3));
		---- A 0 A_Jump(4,"spawn");
		loop;
	}
}


