// ------------------------------------------------------------
// All damage that affects the player goes here.
// ------------------------------------------------------------
extend class HDPlayerPawn{
	int inpain;
	override int DamageMobj(
		actor inflictor,
		actor source,
		int damage,
		name mod,
		int flags,
		double angle
	){
		//"You have to be aware of recursively called code pointers in death states.
		//It can easily happen that Actor A dies, calling function B in its death state,
		//which in turn nukes the data which is being checked in DamageMobj."
		if(!self || health<1 || damage<1)return damage;

		int originaldamage=damage;

		silentdeath=false;

		//replace all armour with custom HD stuff
		if(countinv("BasicArmor")&&!countinv("HDArmourWorn")){
			A_GiveInventory("HDArmourWorn");
			A_TakeInventory("BasicArmor");
		}

		if(
			damage==TELEFRAG_DAMAGE
			&&source
		){
			if(source==self){
				flags|=DMG_FORCED;
				A_TakeInventory("SpiritualArmour");
			}

			//because spawn telefrags are bullshit
			else if(
				(source.player&&source.player.mo==source)
				&&(self.player&&self.player.mo==self)
				&&(
					!deathmatch
					||level.time<35
					||source.getage()<10
				)
			){
				return -1;
			}
		}

		if(inflictor&&inflictor.bpiercearmor)flags|=DMG_NO_ARMOR;
		let armr=HDArmourWorn(findinventory("HDArmourWorn"));
		//it just goes through one of the gaping holes in your armour
		if(
			armr
			&&armr.durability<random(2,8)
		){
			armr=null;
		}

		//factor in cheats and skills
		if(
			!(flags&DMG_FORCED)
			&&damage!=TELEFRAG_DAMAGE
		){
			if(
				binvulnerable||!bshootable
				||(player&&(
					player.cheats&CF_GODMODE2 || player.cheats&CF_GODMODE
				))
			){
				A_TakeInventory("Heat");
				woundcount=0;
				oldwoundcount=0;
				unstablewoundcount=0;
				burncount=0;
				aggravateddamage=0;
				return 0;
			}
			damage=int(damage*hd_damagefactor);
		}

		//credit and blame where it's due
		if(source is "BotBot")source=source.master;

		//abort if zero team damage, otherwise save factor for wounds and burns
		double tmd=1.;
		if(
			source is "PlayerPawn"
			&&source!=self
			&&isteammate(source)
			&&player!=source.player
		){
			if(!teamdamage) return 0;
			else tmd=teamdamage;
		}

		if(source&&source.player)flags|=DMG_PLAYERATTACK;

		int towound=0;
		int toburn=0;
		int tostun=0;
		int tobreak=0;

		//blursphere
		let blrs=HDBlurSphere(findinventory("HDBlursphere"));
		if(blrs&&blrs.worn){
			if(mod=="balefire")damage=max(1,damage-blrs.level*2);
			else if(mod=="thermal")blrs.intensity-=100;
		}

		//too many old maps that predate the availability of lava "fire" damage
		//better just treat them all the same
		if(mod=="fire"&&!inflictor)mod="slime";

		//radsuit
		if(mod=="slime")A_GiveInventory("Heat",int(damage*frandom(2.3,2.7)));
		if(countinv("PowerIronFeet"))A_GiveInventory("WornRadsuit");
		let radsuit=wornradsuit(findinventory("WornRadsuit"));
		if(
			radsuit
			&&!(flags&DMG_NO_ARMOR)
		){
			radsuit.stamina+=random(1,damage);
			if(mod=="slime"){
				if(
					damage>10
					&&radsuit.stamina>2100
				){
					destroyradsuit();
				}else if(damage>random(10,50)){
					damage=1;
				}else return 0;
			}
		}

		//regular armour...
		int alv=(flags&DMG_NO_ARMOR||flags&DMG_FORCED)?0:self.armourlevel;

		//which is just a vest not a bubble...
		if(
			alv
			&&inflictor
			&&getdefaultbytype(inflictor.getclass()).bmissile
		){
			double impactheight=inflictor.pos.z+inflictor.height*0.5;
			double shoulderheight=pos.z+height-16;
			double waistheight=pos.z+height*0.4;
			double impactangle=absangle(angle,angleto(inflictor));
			if(impactangle>90)impactangle=180-impactangle;
			bool shouldhitflesh=(
				impactheight>shoulderheight
				||impactheight<waistheight
				||impactangle>80
			)?!random(0,5):!random(0,31);
			if(shouldhitflesh)alv=0;
			else if(impactangle>80)alv=random(1,alv);
		}

		//excess hp
		if(mod=="maxhpdrain"){
			damage=min(health-1,damage);
			flags|=DMG_NO_PAIN|DMG_THRUSTLESS;
		}
		//bleeding
		else if(
			mod=="bleedout"||
			mod=="internal"||
			mod=="invisiblebleedout"
		){
			flags|=(DMG_NO_ARMOR|DMG_NO_PAIN|DMG_THRUSTLESS);
			silentdeath=true;

			if(regenblues>0&&health<=damage){
				regenblues--;
				damage=health-random(1,3);
			}else{
				damage=min(health,damage);
				if(!random(0,127))oldwoundcount++;
			}

			bool actuallybleeding=(mod!="internal");
			if(actuallybleeding){
				if(hd_nobleed){
					woundcount=0;
					return 0;
				}

				bloodloss+=(damage<<2);

				if(
					!waterlevel
					&&!checkliquidtexture()
					&&bloodloss<HDCONST_MAXBLOODLOSS*1.4
				){
					for(int i=0;i<damage;i+=2){
						a_spawnitemex("HDBloodTrailFloor",
							random(-12,12),random(-12,12),0,
							0,0,0,
							0,SXF_NOCHECKPOSITION|SXF_USEBLOODCOLOR
							|SXF_SETMASTER
						);
					}
				}

				if(level.time&(1|2))return -1;
				if(bloodloss<HDCONST_MAXBLOODLOSS){
					if(!(flags&DMG_FORCED))damage=clamp(damage>>2,1,health-1);
					if(!random(0,health)){
						beatcap--;
						if(!(level.time%4))bloodpressure--;
					}
				}
				if(damage<health)source=null;
			}
		}else if(
			mod=="thermal"||
			mod=="fire"||
			mod=="ice"||
			mod=="heat"||
			mod=="cold"||
			mod=="plasma"||
			mod=="burning"
		){
			//burned
			//the heat still has to hit the armour
			if(radsuit){
				radsuit.stamina+=random(1,damage);
				if(damage<random(0,6))return 0;else{
					damage=int(damage*0.4);
					if(radsuit.stamina>2100){
						destroyradsuit();
					}else if(damage<4)mod="slime";
				}
			}
			if(armr&&random(0,5)){
				if(alv==3){
					damage-=30;
					if(!random(0,200-damage))armr.durability-=max(0,damage/5);
				}
				else if(alv==1){
					damage-=30;
					if(!random(0,220-damage))armr.durability-=max(0,damage/10);
				}
			}
			if(damage<=1){
				damage=1;
				if(!random(0,27))toburn++;
			}else toburn+=int(max(damage*frandom(0.1,0.6),random(0,1)));
			if(!random(0,30+alv*3))towound+=max(1,damage*3/100);
		}else if(
			mod=="electro"||
			mod=="electrical"||
			mod=="lightning"||
			mod=="bolt"
		){
			//electrocuted
			if(radsuit){
				if(damage<100)return 0;
				destroyradsuit();
				damage=int(damage*0.8);
			}
			toburn+=int(max(damage*frandom(0.2,0.5),random(0,1)));
			if(!random(0,35))towound+=max(1,damage/20);
			if(!random(0,1))tostun+=damage;
		}else if(
			mod=="balefire"||
			mod=="hellfire"||
			mod=="unholy"
		){
			//balefired
			toburn+=int(damage*frandom(0.6,1.1));
			if(!random(0,1+alv))towound+=max(1,damage*6/100);
			if(random(1,50)<damage*tmd)aggravateddamage++;
			A_AlertMonsters();
		}else if(
			mod=="teeth"||
			mod=="claws"||
			mod=="bite"||
			mod=="scratch"||
			mod=="nails"||
			mod=="natural"
		){

			//radsuit
			if(random(1,damage)>10){
				destroyradsuit();
				damage-=5;
				if(damage<1)return 0;
			}
			//armour
			if(random(0,3)){
				if(alv==3)damage/=10;
				else if(alv)damage/=3;
				if(damage<1)return 0;
			}else{
				if(!random(0,mod=="teeth"?12:36))aggravateddamage++;
				if(random(1,15)<damage)towound++;
			}
			tostun+=int(damage*frandom(0,0.6));
		}else if(
			mod=="GhostSquadAttack"
		){
			//do nothing here, rely on GhostMarine.A_GhostShot
		}else if(
			mod=="staples"
			||mod=="falling"
			||mod=="drowning"
			||mod=="slime"
		){
			//noarmour
			flags|=DMG_NO_ARMOR;

			if(mod=="falling"){
				if(!source)return -1; //ignore regular fall damage
				tostun+=damage*random(20,30);
				damage>>=1;
			}
			else if(mod=="slime"&&!random(0,99))aggravateddamage++;
		}else if(mod=="bashing"){
			tostun+=damage;
			damage>>=2;
		}else if(
			mod=="cutting"
			||mod=="slashing"
		){
			//swords, chainsaw, etc.
			damage=int(damage*(1.-(alv*0.3)));
			if(!random(0,10+alv*2))towound+=max(1,damage*4/100);
			if(armr)armr.durability-=max(0,damage>>(1+alv));
			if(damage>random(5,30))destroyradsuit();
		}else{
			//anything else
			damage=int(damage*(1.-(alv*0.2)));
			if(!random(0,10+alv*2))towound+=max(1,damage*3/100);
			if(towound>random(4,20))destroyradsuit();
			if(
				armr
				&&mod!="piercing" //bullets do their own thing
			)armr.durability-=max(0,damage>>random(1,5));
		}


		//spiritual armour
		if(!(flags&DMG_FORCED)&&countinv("SpiritualArmour")){
			towound=0;
			toburn=0;
			if(inpain>0)inpain=max(inpain,3);
			else if(
				mod!="bleedout"
				&&mod!="internal"
				&&damage>random(7,144)
			){
				A_TakeInventory("SpiritualArmour",1);
			}
			damage=clamp(damage,0,health-7);
			if(mod!="internal")mod="falling";
		}


		//check for destruction after armour depleted, not before
		if(armr&&armr.durability<1){
			armr.durability=0;
			armr.destroy();
		}

		//abort if damage is less than zero
		if(damage<0)return 0;


		//HDBulletActor has its separate wound handling
		if(inflictor is "HDBulletActor")towound=0;


		//add to wounds and burns after team damage multiplier
		//(super.damagemobj() takes care of the actual damage amount)
		towound=int(towound*tmd);
		toburn=int(toburn*tmd);
		if(towound){
			lastthingthatwoundedyou=source;
			woundcount+=towound;
		}
		burncount+=toburn;
		stunned+=tostun;
		oldwoundcount+=tobreak;

		//stun the player randomly
		if(damage>60 || (!random(0,5) && damage>20)){
			tostun+=damage;
		}

		if(hd_debug&&player){
			string st="the world";
			if(inflictor)st=inflictor.getclassname();
			A_Log(string.format("%s took %d %s damage from %s",
				player.getusername(),
				damage,
				mod,
				st
			));
		}


		//disintegrator mode keeps things simple
		//also do this while zerk sometimes, to reflect loss of self-preservation reflexes
		if(
			hd_disintegrator
			||(zerk&&abs(zerk)>400)
		)return super.DamageMobj(
			inflictor,
			source,
			damage,
			mod,
			flags|DMG_NO_ARMOR,
			angle
		);


		//player survives at cost
		if(
			damage>=health
		){
			if(
				mod!="internal"
				&&mod!="bleedout"
				&&mod!="invisiblebleedout"
				&&damage<random(12,70)
				&&random(0,3)
			){
				int wnddmg=random(0,max(0,damage>>2));
				if(mod=="bashing")wnddmg>>=1;
				damage=health-random(1,3);
				if(
					mod=="fire"
					||mod=="ice"
					||mod=="heat"
					||mod=="cold"
					||mod=="plasma"
					||mod=="burning"
					||mod=="thermal"
				){
					burncount+=wnddmg;
				}else if(
					mod=="slime"
					||mod=="balefire"
				){
					aggravateddamage+=wnddmg;
				}else{
					unstablewoundcount+=wnddmg;
				}
			}
		}


		//finally call the real one but ignore all armour
		int finaldmg=super.DamageMobj(
			inflictor,
			source,
			damage,
			mod,
			flags|DMG_NO_ARMOR,
			angle
		);

		//transfer pointers to corpse
		if(deathcounter&&inflictor&&!inflictor.bismonster&&playercorpse){
			if(inflictor.tracer==self)inflictor.tracer=playercorpse;
			if(inflictor.target==self)inflictor.target=playercorpse;
			if(inflictor.master==self)inflictor.master=playercorpse;
		}

		//go into dying/collapsed mode
		if(
			health>0
			&&player
			&&incapacitated<1
			&&(
				health<random(-1,max((originaldamage>>3),3))
				||tostun>(health<<2)
			)&&(
				mod!="bleedout"
				||bloodloss>random(2048,3072)
			)
		)A_Incapacitated((originaldamage>10)?HDINCAP_SCREAM:0,originaldamage<<3);

		return finaldmg;
	}
	void DestroyRadsuit(){
		if(!!findinventory("WornRadsuit")){
			A_TakeInventory("WornRadsuit");
			A_TakeInventory("PowerIronFeet");
			A_StartSound("radsuit/burst",CHAN_AUTO);
		}
	}
	//disarm
	static void Disarm(actor victim){
		if(!victim.player)return;
		let pwep=hdweapon(victim.player.readyweapon);
		if(!pwep)return;
		pwep.OnPlayerDrop();
		if(
			pwep
			&&pwep.owner==victim //onplayerdrop might change this
			&&!pwep.bdontdisarm
		){
			victim.DropInventory(pwep);
		}
	}
	states{
	pain:
	pain.drowning:
	pain.falling:
	pain.staples:
		---- A 0{
			if(!random(0,128))oldwoundcount++;
		}
	painend:
		#### G 3{
			if(!inpain){
				inpain=3;
				if(bloodpressure<100)bloodpressure+=20;
				if(beatmax>12)beatmax=max(beatmax-randompick(10,20),8);
				A_SetBlend("00 00 00",0.8,40,"00 00 00");
				double jerkamt=(stimcount>8)?2.:4.;
				A_MuzzleClimb(
					(frandom(-jerkamt,jerkamt),frandom(-jerkamt,jerkamt)),
					(0,0),(0,0),(0,0)
				);
				A_TakeInventory("PowerFrightener");
			}
			if(incapacitated)frame=clamp(6+abs(incapacitated>>2),6,11);
		}
		---- A 3 A_StartSound(painsound,CHAN_VOICE);
		---- A 0 setstatelabel("spawn");
	pain.slime:
		#### G 3{
			if(bloodpressure<40)bloodpressure+=2;
			if(beatmax>20)beatmax=max(beatmax-2,18);
			A_SetBlend("00 00 00",0.8,40,"00 00 00");
		}
		#### G 3 A_StartSound(painsound,CHAN_VOICE);
		---- A 0 setstatelabel("spawn");
	}
}


//for future reference
class DamageFloorChecker:Actor{
	override void postbeginplay(){
		super.postbeginplay();
		sector sss=floorsector;
		A_Log(string.format(
			"%i %s damage every %i tics with %i leak chance.",
			sss.damageamount,
			sss.damagetype,
			sss.damageinterval,
			sss.leakydamage
		));
		destroy();
	}
}
