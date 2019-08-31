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
			&&findstate("pain",true)
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

		//force death if body appears to be totally shredded
		if(health>0&&bodydamage>sphlth){
			int ret=super.damagemobj(inflictor,source,damage,mod,flags,angle);
			if(self)super.damagemobj(inflictor,source,health,mod,DMG_THRUSTLESS|DMG_NO_FACTOR,angle);
			return ret;
		}


		//rapid damage stacking
		if(pain>0)damage+=pain;

		if(mod!="bleedout")pain+=max(1,(damage>>5));


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
		if(mod=="bleedout"){
			bloodloss+=damage;
			if(!(bloodloss&(1|2|4|8))){
				bodydamage++;
			}
			if(hd_debug)console.printf(getclassname().." bleed "..damage..", est. remain "..sphlth-bloodloss);
			if(bloodloss<sphlth)return 1;
			return super.damagemobj(
				inflictor,source,random(damage,health),mod,DMG_NO_PAIN|DMG_THRUSTLESS,angle
			);
		}


		//make sure bodily integrity tracker is affected
		if(bodydamage<(sphlth<<(HDMOB_GIBSHIFT+1)))bodydamage+=damage;


		if(hd_debug)console.printf(getclassname().." "..damage.." "..mod..", est. remain "..health-damage);


		//check for gibbing
		if(
			findstate("xdeath",true)
			&&bodydamage>(gibhealth+sphlth)
		){
			if(
				health<1
				&&bodydamage>(sphlth<<HDMOB_GIBSHIFT)
			){
				A_GiveInventory("IsGibbed"); //deprecated, needs to be replaced for all monsters
				bgibbed=true;
				bshootable=false;
				if(findstate("xxxdeath",true))setstatelabel("xxxdeath");
				else setstatelabel("xdeath");
				return -1;
			}else{
				return super.damagemobj(inflictor,source,health,"extreme",flags,angle);
			}
		}

		return super.damagemobj(inflictor,source,damage,mod,flags,angle);
	}


	enum MobDamage{
		HDMOB_GIBSHIFT=7,
	}


	//tracks what is to be done about all this damage
	void DamageTicker(){
		if(pain>0)pain>>=1;

		if(health<1){
			//fall down if dead
			if(
				!bnoshootablecorpse
				&&height>deathheight
			)A_SetSize(-1,max(deathheight-0.1,height-liveheight*0.06));
			return;
		}

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

		//regeneration
		if(!(level.time&(1|2|4|8|16|32|64|128|256|512|1024)))GiveBody(1);
	}


	double liveheight;
	override void die(actor source,actor inflictor,int dmgflags){
		//retrieve actor's current height
		liveheight=height;

		super.Die(source,inflictor,dmgflags);
		if(!self)return;

		//check gibbing
		bgibbed=(
			findstate("xdeath",true)
			&&(
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

		if(!bgibbed)bshootable=!bnoshootablecorpse;
		else A_GiveInventory("IsGibbed"); //delete this line later

		//set height
		//TODO: replace all tempshields
		//TODO: test this to ensure it does, in fact, block shots
		if(bshootable)A_SetSize(-1,liveheight);
	}


	//should be placed at the start of every raise state
	void AttemptRaise(){
		if(!findstate("raise"))return;
		if(bgibbed){
			bgibbed=false;
			A_Die("ungib");
		}
		bodydamage=max(0,bodydamage-100);
		if(bodydamage>(health<<2)/10){
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

		if(!bnoshootablecorpse)bshootable=true;
		deathsound=getdefaultbytype(getclass()).deathsound;
		let aff=new("AngelFire");
		aff.master=self;aff.ticker=0;

		resetdamagecounters();
	}

}


extend class HDHandlers{
	override void WorldThingRevived(WorldEvent e){
		console.printf(e.thing.height.." height, health "..e.thing.health);
		let mbb=hdmobbase(e.thing);
		if(mbb)mbb.AttemptRaise();
	}
}


