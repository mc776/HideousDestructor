// ------------------------------------------------------------
// Nice movement your objects have there.
// Shame if they got........ damaged.
// ------------------------------------------------------------

extend class HDMobBase{
	int stunned;
	int bodydamage;
	int damagerecoil;
	int bloodloss;
	int pain;
	void resetdamagecounters(){
		stunned=0;
		damagerecoil=0;
		bloodloss=0;
		pain=0;
	}

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
		int sphlth=spawnhealth();

		//check for gibbing
		if(
			findstate("xdeath",true)
			&&bodydamage>gibhealth+sphlth
		){
			if(health<1){
				if(findstate("xxxdeath",true))setstatelabel("xxxdeath");
				else setstatelabel("xdeath");
				bgibbed=true;
				A_GiveInventory("IsGibbed"); //deprecated, needs to be replaced for all monsters
				return -1;
			}else{
				return super.damagemobj(inflictor,source,health,"extreme",flags,angle);
			}
		}

		//force death if body appears to be totally shredded
		if(health>0&&bodydamage>1.){
			int ret=super.damagemobj(inflictor,source,damage,mod,flags,angle);
			if(self)super.damagemobj(inflictor,source,health,mod,DMG_THRUSTLESS|DMG_NO_FACTOR,angle);
			return ret;
		}

		//bashing
		if(mod=="bashing"){
			stunned+=(damage<<2);
			damage>>=2;
			int bashthreshold=health-(sphlth>>3);
			if(
				damage>=bashthreshold
				&&damage<sphlth
				&&random(0,7)
			){
				damage=max(1,bashthreshold);
				forcepain();
			}
		}

		//bleeding
		else if(mod=="bleedout"){
			bloodloss+=damage;
			if(!(bloodloss&(1|2|4|8))){
				bodydamage++;
			}
			if(bloodloss<(sphlth<<2))return -1;
			flags|=DMG_NO_PAIN|DMG_THRUSTLESS;
		}

		//make sure bodily integrity tracker is affected
		bodydamage+=damage;

		return super.damagemobj(
			inflictor,source,damage,mod,flags,angle
		);
	}



	//tracks what is to be done about all this damage
	void DamageTicker(){
		if(health<1)return;

		if(stunned>0){
			stunned-=max(1,(spawnhealth()>>7));
			if(stunned<1){
				speed=getdefaultbytype(getclass()).speed;
				bjustattacked=false;
				stunned=0;
			}else{
				if(
					stunned>50
					&&(
						!target
						||distance2d(target)>meleerange+target.radius*HDCONST_SQRTTWO
					)
				)bjustattacked=random(0,stunned>>3);
				speed=frandom(0,getdefaultbytype(getclass()).speed);
			}
		}

		if(pain>0)pain--;

		//regeneration
		if(!(level.time&(1|2|4|8|16|32|64|128|256|512|1024)))GiveBody(1);
	}



	override void die(actor source,actor inflictor,int dmgflags){
		super.Die(source,inflictor,dmgflags);
		if(!self)return;

		//check gibbing
		bgibbed=(
			(
				!inflictor
				||!inflictor.bnoextremedeath
			)&&(
				health < getgibhealth()
				||(inflictor&&inflictor.bextremedeath)
			)
		);

		//set corpse stuff
		bnodropoff=false;
		maxstepheight=deathheight*0.1;
		bnotautoaimed=true;
		balwaystelefrag=true;

		if(!bgibbed)bshootable=true;
		else A_GiveInventory("IsGibbed"); //delete this line later
	}


	//should be placed at the start of every raise state
	void AttemptRaise(){
		if(!findstate("raise"))return;
		if(bgibbed){
			bgibbed=false;
			A_Die("ungib");
		}
		bodydamage-=100/mass;
		if(bodydamage>0.4){
			A_Die("needmore");
			return;
		}

		//handle deprecated flag
		A_TakeInventory("SawGib");

		//reset corpse stuff
		if(!bfloat)bnodropoff=true;
		maxstepheight=getdefaultbytype(getclass()).maxstepheight;
		bnotautoaimed=false;
		balwaystelefrag=false;

		bshootable=true;
		let aff=new("AngelFire");
		aff.master=self;aff.ticker=0;

		resetdamagecounters();
	}

}
