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

	static bool forcepain(actor caller){
		if(
			!caller
			||caller.bnopain
			||!caller.bshootable
			||!caller.findstate("pain",true)
			||caller.instatesequence(caller.curstate,caller.resolvestate("falldown"))
			||caller.health<1
		)return false;
		caller.setstatelabel("pain");
		return true;
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
		bdontdrop=(inflictor==self&&mod!="bleedout");

		//rapid damage stacking
		if(pain>0)damage+=(pain>>2);

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
				forcepain(self);
			}
		}


		//additional knockdown stun
		if(
			//check to make sure we're not already doing it
			//if already doing so, make sure the damage never goes into painstate
			instatesequence(curstate,resolvestate("falldown"))
		){
			if(
				!bnopain
				&&!(flags&DMG_NO_PAIN)
				&&damage>painthreshold
				&&random(0,255)<painchance
			)A_Pain();
			flags|=DMG_NO_PAIN;
		}else if(
			!bnopain
			&&health>0
			&&findstate("falldown")
			&&max(stunned,damage)>random(health,(sphlth<<3))
		){
			setstatelabel("falldown");
			flags|=DMG_NO_PAIN;
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
		int sgh=sphlth+gibhealth;
		if(bodydamage<(sgh<<(HDMOB_GIBSHIFT+1)))bodydamage+=damage;

		if(hd_debug)console.printf(getclassname().." "..damage.." "..mod..", est. remain "..health-damage);


		//check for gibbing
		if(
			findstate("xdeath",true)
			&&bodydamage>(gibhealth+sphlth)
		){
			if(
				health<1
				&&bodydamage>(sgh<<HDMOB_GIBSHIFT)
			){
				bgibbed=true;
				bshootable=false;
				if(findstate("xxxdeath",true))setstatelabel("xxxdeath");
				else setstatelabel("xdeath");
				return -1;
			}else{
				return super.damagemobj(inflictor,source,health,"extreme",flags,angle);
			}
		}

		//force death even if not quite gibbing
		if(health>0&&bodydamage>sphlth){
			return super.damagemobj(inflictor,source,health,mod,flags,angle);
		}


		return super.damagemobj(inflictor,source,damage,mod,flags,angle);
	}


	enum MobDamage{
		HDMOB_GIBSHIFT=2,
	}


	//tracks what is to be done about all this damage
	int deathticks;
	void DamageTicker(){
		if(pain>0)pain>>=1;

		if(health<1){
			//fall down if dead
			if(
				!bnoshootablecorpse
				&&height>deadheight
			)A_SetSize(-1,max(deadheight-0.1,height-liveheight*0.06));

			if(deathticks<8){
				deathticks++;
				if(deathticks==8){
					A_NoBlocking();
					if(!bdontdrop){
						deathdrop();
						if(!bhasdropped)bhasdropped=true;
					}
					deathticks=9;
				}
			}
			return;
		}

		//set height according to incap
		if(instatesequence(curstate,resolvestate("falldown"))){
			if(deadheight<height)A_SetSize(-1,max(deadheight,height-10));
		}else if(liveheight!=height)A_SetSize(-1,(height+liveheight)*0.5);


		//this must be done here and not AttemptRaise because reasons
		if(bgibbed){
			bgibbed=false;
			if(findstate("ungib",true))setstatelabel("ungib");
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
		if(!(level.time&(1|2|4|8|16|32|64|128|256|512)))GiveBody(1);
	}


	virtual void deathdrop(){}
	override void die(actor source,actor inflictor,int dmgflags){
		deathticks=0;

		bool incapacitated=(
			findstate("falldown",true)
			&&frame>=11 //"M" for serpentipede, "L" for humanoids
		);


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

		//temp incap: reset +nopain, skip death sequence
		if(
			incapacitated
			&&!bgibbed
			&&findstate("dead",true)
		){
			if(!random(0,7))A_Scream();
			setstatelabel("dead");
		}

		//set corpse stuff
		bnodropoff=false;
		bnotautoaimed=true;
		balwaystelefrag=true;
		bpushable=false;
		maxstepheight=deadheight*0.1;

		if(!bgibbed)bshootable=!bnoshootablecorpse;
		else bshootable=false;

		//set height
		if(
			!incapacitated
			&&bshootable
		)A_SetSize(-1,liveheight);
	}


	//should be placed at the start of every raise state
	/*
		states: raise, ungib, xxxdeath, dead, xdead
		no special functions should be assigned to them to handle death/raise,
		absent some very special behaviour like marine zombification.
		raise and ungib should both terminate with goto checkraise.
	*/
	void AttemptRaise(){
		//reset corpse stuff
		let deff=getdefaultbytype(getclass());
		bnodropoff=deff.bnodropoff;
		bfloatbob=deff.bfloatbob;
		maxstepheight=deff.maxstepheight;
		bnotautoaimed=deff.bnotautoaimed;
		balwaystelefrag=deff.balwaystelefrag;
		bnogravity=deff.bnogravity;
		bpushable=deff.bpushable;
		gravity=deff.gravity;

		if(!bnoshootablecorpse)bshootable=true;
		deathsound=getdefaultbytype(getclass()).deathsound;

		bodydamage=clamp(bodydamage-666,0,((spawnhealth()+gibhealth)<<(HDMOB_GIBSHIFT+2)));
		if(hd_debug)console.printf(getclassname().." revived with remaining damage: "..bodydamage);

		resetdamagecounters();

		let aff=new("AngelFire");
		aff.master=self;aff.ticker=0;
	}


	//temporary stun
	void A_KnockedDown(){
		vel.xy+=(frandom(-0.1,0.1),frandom(-0.1,0.1));
		if(!random(0,3))vel.z+=frandom(0.4,1.);
		if(stunned>0||random(0,(bodydamage>>4)))return;
		//reset stuff and get up
		bnopain=getdefaultbytype(getclass()).bnopain;
		if(findstate("standup"))setstatelabel("standup");
		else if(findstate("raise"))setstatelabel("raise");
		else setstatelabel("see");
	}


	states{
	checkraise:
		---- A 0 damagemobj(self,self,1,"maxhpdrain",DMG_FORCED|DMG_NO_FACTOR);
		---- A 0 A_Jump(256,"see");
		stop;
	}

}


extend class HDHandlers{
	override void WorldThingRevived(WorldEvent e){
		let mbb=hdmobbase(e.thing);
		if(mbb)mbb.AttemptRaise();
	}
}





//a thinker that constantly bleeds
class HDBleedingWound:Thinker{
	bool hitvital;
	actor bleeder;
	int bleedrate;
	int bleedpoints;
	int ticker;
	double zed;
	enum bleednums{
		BLEED_MAXTICS=40,
	}
	override void tick(){
		if(
			!bleedpoints
			||!bleeder
			||bleeder.health<1
		){
			destroy();
			return;
		}
		if(bleeder.isfrozen())return;
		if(ticker>0){
			ticker--;
			return;
		}
		bleedpoints--;
		ticker=max(0,BLEED_MAXTICS-bleedrate);
		int bleeds=(bleedrate>>4);
		do{
			bleeds--;
			bool gbg;actor blood;
			[gbg,blood]=bleeder.A_SpawnItemEx(bleeder.bloodtype,
				frandom(-12,12),frandom(-12,12),
				flags:SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
			);
			if(blood)blood.bambush=true;
		}while(bleeds>0);
		int bled=bleeder.damagemobj(bleeder,null,bleedrate,"bleedout",DMG_NO_PAIN|DMG_THRUSTLESS);
		if(bleeder&&bleeder.health<1&&bleedrate<random(10,60))bleeder.deathsound="";
	}
	static void inflict(
		actor bleeder,
		int bleedpoints,
		int bleedrate=17,
		bool hitvital=false
	){
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

		//TODO: proper array of wounds for the player
		if(hdplayerpawn(bleeder)){
			let hpl=hdplayerpawn(bleeder);
			hpl.woundcount+=bleedpoints;
			return;
		}

		let wwnd=new("HDBleedingWound");
		wwnd.bleeder=bleeder;
		wwnd.ticker=0;
		wwnd.bleedrate=bleedrate;
		if(hitvital)wwnd.bleedpoints=-1;
		else wwnd.bleedpoints=bleedpoints;
	}
}
