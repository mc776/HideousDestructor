// ------------------------------------------------------------
// Nice movement your objects have there.
// Shame if something happened to them.
// ------------------------------------------------------------

//All monsters should inherit from this.
class HDMobBase : HDActor{
	int hdmobflags;
	flagdef doesntbleed:hdmobflags,0;
	flagdef hasdroppedgun:hdmobflags,1;
	flagdef hasnodistincthead:hdmobflags,2;
	flagdef gibbed:hdmobflags,3;

	default{
		monster;
		radius 12;
	}

	override void Tick(){
		super.tick();
		if(isfrozen())return;

		//do these only while the monster is still alive
		if(health>0){

			//regeneration
			//recover from bashing damage
			if(bashed>0){
				bashed--;
				if(!bashed){
					speed=getdefaultbytype(getclass()).speed;
				}else{
					if(!(bashed&(1|2)))givebody(1);
					speed=frandom(0,getdefaultbytype(getclass()).speed);
				}
			}
			if(!(level.time&(1|2|4|8|16)))GiveBody(1);
		}
	}
}



//general corpse-gibbing
class SawGib:InventoryFlag{
	default{
		inventory.maxamount int.MAX;
	}
	override void attachtoowner(actor user){
		super.attachtoowner(user);
		actor o=owner;
		if(owner){
			stamina=max(o.gibhealth,o.spawnhealth());
		}else destroy();
	}
	override void doeffect(){
		if(amount>stamina){
			actor o=owner;
			if(o)o.bdontgib=false;
			if(bmissileevenmore)return;
			bmissileevenmore=true;
			if(
				!o.bcorpse
				||!o.bshootable
				||o.health>0
			)destroy();
			else{
				o.bshootable=false;
				//use the old death state first
				if(o.findstate("XDeathBrewtleLulz"))o.setstatelabel("XDeathBrewtleLulz");
				else if(o.findstate("XXDeath"))o.setstatelabel("XXDeath");
				else o.bshootable=true;
				if(!o.bshootable)amount=0;
			}
		}
	}
}


class TauntHandler:EventHandler{
	override void NetworkProcess(ConsoleEvent e){

		//check to ensure the acting player can taunt
		let ppp = playerpawn(players[e.player].mo);
		if(!ppp) return;

		if(
			e.name~=="taunt"
			&&ppp.health>0 //delete if you want corpses taunting the enemy
		){
			ppp.A_PlaySound("*taunt",CHAN_VOICE);
			ppp.A_TakeInventory("powerfrightener");
			ppp.A_AlertMonsters();
		}
	}
}

//generic bleeding
//maybe use this for players too in the future???
class HDWound:Thinker{
	static void Inflict(actor bleeder,int amount){
		if(
			!skill||hd_nobleed
			||!bleeder.bshootable
			||bleeder.bnoblood
			||bleeder.bnoblooddecals
			||bleeder.bnodamage
			||bleeder.bdormant
			||bleeder.health<1
			||bleeder.bloodtype=="ShieldNeverBlood"
			||(
				hdmobbase(bleeder)
				&&hdmobbase(bleeder).bdoesntbleed
			)
		)return;

		let wwnd=new("HDWound");
		wwnd.owner=bleeder;
		wwnd.ticker=0;

		int modamt=getdefaultbytype(bleeder.getclass()).health;
		if(modamt>100)wwnd.amount=amount*100/modamt;
		else wwnd.amount=amount;
	}
	int ticker;
	int amount;
	actor owner;
	override void tick(){
		if(!owner||owner.health<1){destroy();return;}
		if(owner.isfrozen())return;
		ticker++;
		if(ticker>3){
//owner.A_LogInt(amount);
			ticker=0;
			if(amount>random(0,100)){
				owner.damagemobj(owner,null,max(1,(amount>>3)),"bleedout",DMG_NO_PAIN);
				if(owner.health<1&&amount<random(10,60))owner.deathsound="";
				owner.A_SpawnItemEx(owner.bloodtype,
					frandom(-12,12),frandom(-12,12),
					flags:SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
				);
			}else if(amount<random(-100,67))amount--;
			if(amount<1||owner.health<1)destroy();
		}
	}
}


#include "zscript/mon/mobai_old.zs"
