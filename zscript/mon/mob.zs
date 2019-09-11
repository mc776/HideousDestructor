// ------------------------------------------------------------
// Nice movement your objects have there.
// Shame if something happened to them.
// ------------------------------------------------------------

//All monsters should inherit from this.
class HDMobBase : HDActor{
	int hdmobflags;
	flagdef doesntbleed:hdmobflags,0;
	flagdef hasdropped:hdmobflags,1;
	flagdef gibbed:hdmobflags,2;
	flagdef novitalshots:hdmobflags,3;
	flagdef hashelmet:hdmobflags,4;
	flagdef smallhead:hdmobflags,5;
	flagdef biped:hdmobflags,6;
	flagdef noshootablecorpse:hdmobflags,7;
	flagdef playingid:hdmobflags,8;
	flagdef dontdrop:hdmobflags,9;
	flagdef norandomweakspots:hdmobflags,10;

	default{
		monster;
		radius 12;
		gibhealth 100;
		+dontgib
		height 52;
		deathheight 24;
		burnheight 24;
	}

	override void postbeginplay(){
		liveheight=getdefaultbytype(getclass()).height;
		super.postbeginplay();
		resetdamagecounters();bloodloss=0;
		bplayingid=(Wads.CheckNumForName("id",0)!=-1);
	}

	override void Tick(){
		super.tick();
		if(!self||isfrozen())return;
		DamageTicker();
	}

	//randomize size
	double hitboxscale;
	void resize(double minscl=0.9,double maxscl=1.,int minhealth=0){
		double scl=frandom(minscl,maxscl);
		double drad=radius;double dheight=height;
		double minchkscl=max(1.,minscl+0.1);
		while(
			//keep it smaller than the geometry
			scl>minchkscl&&  
			!checkmove(pos.xy,PCM_NOACTORS)
		){
			scl=frandom(minscl,maxscl);
			A_SetSize(drad*scl,dheight*scl);
			maxscl=scl; //if this has to check again, don't go so high next time
		}
		health*=max(scl,1);
		scale*=scl;
		mass*=scl;
		speed*=scl;
		meleerange*=scl;

		//save a few things for future reference
		hitboxscale=scl;
		liveheight=height;
	}
}


//TODO: move to playerextras not mob
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




//below this, only deprecated code



//generic bleeding
class HDWound:Thinker{
	static void Inflict(actor bleeder,int amount){
		if(
			hd_nobleed
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
