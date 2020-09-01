// ------------------------------------------------------------
// Nice movement your objects have there.
// Shame if they got........ damaged.
// ------------------------------------------------------------
extend class HDMobBase{
	int stunned;
	int bodydamage;
	int damagerecoil;
	int bloodloss;
	int maxbloodloss;
	property maxbloodloss:maxbloodloss;
	int pain;
	int downedframe;
	property downedframe:downedframe;
	int shields;
	int maxshields;
	property shields:maxshields;
	void resetdamagecounters(){
		stunned=0;
		damagerecoil=0;
		bloodloss=0;
		pain=0;
		shields=maxshields;
	}

	static bool inpainablesequence(actor caller){
		state curstate=caller.curstate;
		return (
			!caller.instatesequence(curstate,caller.resolvestate("falldown"))
			&&!caller.instatesequence(curstate,caller.resolvestate("raise"))
			&&!caller.instatesequence(curstate,caller.resolvestate("ungib"))
			&&!caller.instatesequence(curstate,caller.resolvestate("death"))
		);
	}
	static bool forcepain(actor caller){
		if(
			!caller
			||caller.bnopain
			||!caller.bshootable
			||!caller.findstate("pain",true)
			||caller.health<1
			||!hdmobbase.inpainablesequence(caller)
			||(hdplayerpawn(caller)&&hdplayerpawn(caller).incapacitated>0)
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


	//standard doom knockback is way too much
	override void ApplyKickback(Actor inflictor, Actor source, int damage, double angle, Name mod, int flags){
		if(
			mod=="thermal"
			||mod=="burning"
			||mod=="balefire"
		)return;
		else if(mod=="piercing")damage>>=4;
		else if(
			mod=="bashing"
			||mod=="electro"
		)damage>>=1;
		else damage>>2;
		if(damage>0)super.ApplyKickback(inflictor,source,damage,angle,mod,flags);
	}


	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		//bypass mdk
		if(damage==TELEFRAG_DAMAGE)return super.damagemobj(
			inflictor,source,damage,
			"Telefrag",DMG_THRUSTLESS|DMG_NO_PAIN
		);

		int sphlth=spawnhealth();
		bdontdrop=(inflictor==self&&mod!="bleedout");

		//rapid damage stacking
		if(pain>0)damage+=(pain>>2);
		if(mod!="bleedout")pain+=max(1,(damage>>5));

		if(!inpainablesequence(self))flags|=DMG_NO_PAIN;

		//shields
		if(
			shields>0
			&&!(flags&(DMG_NO_FACTOR|DMG_FORCED))
			&&!(inflictor is "HDBulletActor")
			&&mod!="bleedout"
			&&mod!="thermal"
			&&mod!="maxhpdrain"
			&&mod!="internal"
			&&mod!="falling"
			&&mod!="holy"
			//&&mod!="jointlock" //not used... for now
		){
			int blocked=min(shields>>2,damage,512);
			damage-=blocked;
			bool supereffective=(
				mod=="BFGBallAttack"
				||mod=="electro"
				||mod=="balefire"
			);

			//deplete shields
			if(supereffective)shields-=max((blocked<<2),1);
			else shields-=max(blocked,1);

			//spawn shield debris
			if(!!inflictor&&!inflictor.bismonster&&!inflictor.player){
				int shrd=max(random(0,1),damage/50);
				for(int i=0;i<shrd;i++){
					actor aaa=inflictor.spawn("ShieldSpark",inflictor.pos,ALLOW_REPLACE);
					aaa.vel=(frandom(-3,3),frandom(-3,3),frandom(-3,3));
				}
			}

			//abort remainder of checks, chance to flinch
			if(damage<1){
				if(
					!(flags&DMG_NO_PAIN)
					&&blocked>(sphlth>>2)
					&&random(0,255)<painchance
				)forcepain(self);
				return -1;
			}
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
				if(!(flags&DMG_NO_PAIN))forcepain(self);
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
			&&!bnoincap
			&&health>0
			&&health<(spawnhealth()>>2)
			&&findstate("falldown")
			&&max(stunned,damage)>random(health,(sphlth<<4))
		){
			setstatelabel("falldown");
			flags|=DMG_NO_PAIN;
		}

		//bleeding
		if(mod=="bleedout"){
			bloodloss+=max(0,damage);
			if(!(bloodloss&(1|2|4|8))){
				bodydamage++;
			}

			//if a custom blood capacity is specified, use that instead of health
			int blhlth=maxbloodloss;
			if(blhlth<1)blhlth=sphlth;

			if(hd_debug)console.printf(getclassname().." bleed "..damage..", est. remain "..blhlth-bloodloss);
			if(bloodloss<blhlth)return 1;
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
			if(deadheight<height)A_SetSize(-1,max(deadheight,height*0.99));
		}else if(liveheight!=height)A_SetSize(-1,min(liveheight,height+liveheight*0.05));


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

		//replenish shields and handle breaking/unbreaking
		if(shields<maxshields)shields++;
		if (maxshields>0) {
			if(shields==0){
				if(hd_debug)console.printf(getclassname().." shield restored!");
				A_StartSound("misc/mobshieldf", CHAN_BODY, CHANF_OVERLAP, 0.75);
				shields=2;
				for(int i=0;i<10;i++){
					vector3 rpos=pos+(
						random(-radius,radius),
						random(-radius,radius),
						random(0,height)
					);
					actor spk=actor.spawn("ShieldSpark",rpos,ALLOW_REPLACE);
					vector3 sv = spk.Vec3To(self);
					sv.z += height/2;
					spk.vel=(sv/50);
				}
			}
			else if(shields==1){
				if(hd_debug)console.printf(getclassname().." shield broke to "..-(maxshields*0.125).."!");
				A_StartSound("misc/mobshieldx", CHAN_BODY, CHANF_OVERLAP, 0.75);
				shields=-(maxshields*0.125);
				for(int i=0;i<10;i++){
					vector3 rpos=pos+(
						random(-radius,radius),
						random(-radius,radius),
						random(0,height)
					);
					actor spk=actor.spawn("ShieldSpark",rpos,ALLOW_REPLACE);
					spk.vel=(frandom(-2,2),frandom(-2,2),frandom(-2,2))+vel;
				}
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
			&&frame>=downedframe //"M" for serpentipede, "L" for humanoids
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
		bnoblockmonst=true;
		bnotautoaimed=true;
		balwaystelefrag=true;
		bpushable=false;
		maxstepheight=deadheight*0.1;
		shields=0;

		if(!bgibbed)bshootable=!bnoshootablecorpse;
		else bshootable=false;

		//set height
		if(
			!incapacitated
			&&!bnoshootablecorpse
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
		bnoblockmonst=deff.bnoblockmonst;
		bfloatbob=deff.bfloatbob;
		maxstepheight=deff.maxstepheight;
		bnotautoaimed=deff.bnotautoaimed;
		balwaystelefrag=deff.balwaystelefrag;
		bnogravity=deff.bnogravity;
		bpushable=deff.bpushable;
		gravity=deff.gravity;

		if(!bnoshootablecorpse)bshootable=true;
		deathsound=getdefaultbytype(getclass()).deathsound;

		bodydamage=clamp(bodydamage-200,0,((spawnhealth()+gibhealth)<<(HDMOB_GIBSHIFT+2)));
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



class bbb:baronofhell{}

//a thinker that constantly bleeds
class HDBleedingWound:Thinker{
	bool hitvital;
	actor bleeder;
	actor source;
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
			||bleedrate<1
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
			if(blood){
				blood.bambush=true;
				blood.bmissilemore=true; //used to avoid converting to shield
			}
		}while(bleeds>0);

		if(!HDMobBase(bleeder))bleedrate=max(1,bleedrate>>(random(1,2)));

		int bled=bleeder.damagemobj(bleeder,source,bleedrate,"bleedout",DMG_NO_PAIN|DMG_THRUSTLESS);
		if(bleeder&&bleeder.health<1&&bleedrate<random(10,60))bleeder.deathsound="";
	}
	static bool canbleed(actor b,bool checkbandage=false){
		return(
			!hd_nobleed
			&&!!b
			&&b.bshootable
			&&!b.bnoblood
			&&!b.bnoblooddecals
			&&!b.bnodamage
			&&!b.bdormant
			&&b.health>0
			&&b.bloodtype!="ShieldNeverBlood"
			&&(
				!hdmobbase(b)
				||!hdmobbase(b).bdoesntbleed
			)
			&&(
				checkbandage
				||!b.findinventory("SpiritualArmour")
			)
		);
	}
	static void inflict(
		actor bleeder,
		int bleedpoints,
		int bleedrate=17,
		bool hitvital=false,
		actor source=null
	){
		if(!HDBleedingWound.canbleed(bleeder))return;

		//TODO: proper array of wounds for the player
		if(hdplayerpawn(bleeder)){
			let hpl=hdplayerpawn(bleeder);
			hpl.woundcount+=(bleedpoints>>1);
			hpl.lastthingthatwoundedyou=source;
			return;
		}

		let wwnd=new("HDBleedingWound");
		wwnd.bleeder=bleeder;
		wwnd.ticker=0;
		wwnd.bleedrate=bleedrate;
		wwnd.source=source;
		if(hitvital)wwnd.bleedpoints=-1;
		else wwnd.bleedpoints=bleedpoints;
	}
}

//inventory hack to allow Decorate-only mods to cause HD bleeding
//multiples of 1000 are counted as bleedrate
//e.g. 24010 = 10 bleedpoints at a rate of 24
//you can't give over 999 bleedpoints in one go
class HDWoundInventory:Inventory{
	default{inventory.maxamount int.MAX;}
	override void AttachToOwner(actor other){
		if(amount<1000)HDBleedingWound.Inflict(other,amount);
		else{
			HDBleedingWound.Inflict(other,amount%1000,amount/1000);
		}
		destroy();
	}
}



// common blood type that changes depending on shields.
// overwrite spawn state if something other than a splat is needed.
class HDMasterBlood:HDPuff{
	default{
		alpha 0.8;gravity 0.3;

		hdpuff.startvelz 1.6;
		hdpuff.fadeafter 0;
		hdpuff.decel 0.86;
		hdpuff.fade 0.88;
		hdpuff.grow 0.03;
		hdpuff.minalpha 0.03;
	}
	override void postbeginplay(){
		super.postbeginplay();
		let hdmb=hdmobbase(target);
		if(
			hdmb
			&&!bmissilemore
			&&hdmb.shields>0
		){
			A_SetTranslucent(1,1);
			grav=-0.6;
			scale*=0.4;
			setstatelabel("spawnshield");
			bnointeraction=true;
			return;
		}
		if(!bambush)A_StartSound("misc/bulletflesh",CHAN_BODY,volume:0.2);
	}
	states{
	spawn:
		BLUD ABC 4{
			if(floorz>=pos.z){
				bflatsprite=true;bmovewithsector=true;bnointeraction=true;
				setz(floorz);vel=(0,0,0);
				fade=0.97;
			}
		}wait;
	spawnshield:
		TFOG A 0 A_SetScale(frandom(0.2,0.5));
		TFOG ABCDEFGHIJ 3 bright A_FadeOut(0.05);
		stop;
	}
}
//standalone puff for hitting a shield
class ShieldSpark:IdleDummy{
	default{
		+forcexybillboard +rollsprite +rollcenter
		renderstyle "add";
	}
	override void postbeginplay(){
		super.postbeginplay();
		scale*=frandom(0.2,0.5);
		roll=frandom(0,360);
	}
	states{
	spawn:
		TFOG ABCDEFGHIJ 3 bright A_FadeOut(0.08);
		stop;
	}
}

//dummy item when you don't want anything coming out for blood or puffs
class NullPuff:Actor{
	default{+nointeraction}
	states{spawn:TNT1 A 0;stop;}
}
