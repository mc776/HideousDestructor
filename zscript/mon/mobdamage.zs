// ------------------------------------------------------------
// Nice movement your objects have there.
// Shame if something happened to them.
// ------------------------------------------------------------

extend class HDMobBase{
	int bashed;
	int corpsedamage;
	void forcepain(){
		if(
			!bnopain
			&&health>0
			&&findstate("pain")
		)setstatelabel("pain");
	}

	//determine threshold and overall resistance to gunshots
	virtual double bulletshell(
		vector3 hitpos,
		double hitangle
	){
		return 0;
	}
	virtual double bulletresistance(
		double hitangle //abs(bullet.angleto(hitactor),bullet.angle)
	){
		return max(0,frandom(0.8,1.0)-hitangle*0.01);
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		//if dead, convert to bodily degeneration
		if(health<1){
			//TODO: add momentum effects even if not going to be gibbed

			if(!findstate("xdeath",true))return -1;
			if(mod=="bashing")damage=(damage>>2);
			if((corpsedamage>>3)>gibhealth){
//TODO: mass string search for the old "XDeathBrewtleLulz"
				if(findstate("xxxdeath",true))setstatelabel("xxxdeath");
				else setstatelabel("xdeath");
				bgibbed=true;
			}
			return -1;
		}

		//bashing
		if(mod=="bashing"){
			bashed+=(damage<<2);
			int bashthreshold=health-(spawnhealth()>>3);
			if(
				damage>=bashthreshold
				&&damage<spawnhealth()
				&&random(0,7)
			){
				damage=max(1,bashthreshold);
				forcepain();
			}
		}

		return super.damagemobj(
			inflictor,source,damage,mod,flags,angle
		);
	}
}
