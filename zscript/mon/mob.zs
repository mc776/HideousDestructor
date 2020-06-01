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
	flagdef noincap:hdmobflags,11;

	default{
		monster;
		radius 12;
		gibhealth 100;
		+dontgib
		-noblockmonst  //set true in HDActor, set false again in some monsters explicitly
		height 52;
		deathheight 24;
		burnheight 24;
		bloodtype "HDMasterBlood";
		hdmobbase.shields 0;
		hdmobbase.downedframe 11; //"K"
	}

	double liveheight;
	double deadheight;
	override void postbeginplay(){
		liveheight=getdefaultbytype(getclass()).height;
		deadheight=getdefaultbytype(getclass()).deathheight;
		hitboxscale=1.;
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
		double drad=radius;
		double dheight=height;
		double minchkscl=max(1.,minscl+0.1);
		double scl;
		do{
			scl=frandom(minscl,maxscl);
			A_SetSize(drad*scl,dheight*scl);
			maxscl=scl; //if this has to check again, don't go so high next time
		}while(
			//keep it smaller than the geometry
			scl>minchkscl
			&&!checkmove(pos.xy,PCM_NOACTORS)
		);
		A_SetHealth(int(health*max(scl,1)));
		scale*=scl;
		mass=int(scl*mass);
		speed*=scl;
		meleerange*=scl;

		//save a few things for future reference
		hitboxscale=scl;
		liveheight=height;
		deadheight=deathheight*scl;
	}
	override double getdeathheight(){
		return super.getdeathheight()*hitboxscale;
	}
}



//someday I will have the time, motivation and organization to update this

#include "zscript/mon/mobai_old.zs"

