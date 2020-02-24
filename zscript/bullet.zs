// ------------------------------------------------------------
// The Bullet!
// ------------------------------------------------------------
class bltest:HDCheatWep{
	default{
		weapon.slotnumber 1;
		hdweapon.refid "blt";
		tag "bullet sampler (cheat!)";
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc,string whichdot
	){
		double dotoff=max(abs(bob.x),abs(bob.y));
		if(dotoff<10){
			sb.drawimage(
				"riflsit3",(0,0)+bob*1.6,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				alpha:0.8-dotoff*0.04,scale:(0.8,0.8)
			);
		}
		sb.drawimage(
			"xh25",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
			scale:(1.6,1.6)
		);
		int airburst=hdw.airburst;
		if(airburst)sb.drawnum(airburst,
			10+bob.x,9+bob.y,sb.DI_SCREEN_CENTER,Font.CR_BLACK
		);
	}
	states{
	fire:
/*
	hold:
		TNT1 A 4 A_FireHDGL();
		TNT1 A 0 A_Refire();
		goto ready;
*/
		TNT1 A 0{
			if(player.cmd.buttons&BT_USE)HDBulletActor.FireBullet(self,"HDB_bronto");
			else HDBulletActor.FireBullet(self,"HDB_9");
		}goto nope;
	altfire:
		TNT1 A 0{
			HDBulletActor.FireBullet(self,"HDB_776");
		}goto nope;
	reload:
		TNT1 A 0{
			HDBulletActor.FireBullet(self,"HDB_426");
		}goto nope;
	user2:
		TNT1 A 0{
			HDBulletActor.FireBullet(self,"HDB_50");
//			HDBulletActor.FireBullet(self,"HDB_00",spread:6,amount:7);
		}goto nope;
	}
}
class HDB_50:HDBulletActor{
	default{
		pushfactor 0.4;
		mass 420;
		speed 1100;
		accuracy 666;
		stamina 1270;
		woundhealth 10;
		hdbulletactor.hardness 3;
		hdbulletactor.distantsound "world/riflefar";
		hdbulletactor.distantsoundvol 3.;
	}
}
class HDB_426:HDBulletActor{
	default{
		pushfactor 0.4;
		mass 32;
		speed 1200;
		accuracy 666;
		stamina 426;
		woundhealth 40;
		hdbulletactor.hardness 2;
		hdbulletactor.distantsound "world/riflefar";
	}
}
class HDB_776:HDBulletActor{
	default{
		pushfactor 0.05;
		mass 120;
		speed 1100;
		accuracy 600;
		stamina 776;
		woundhealth 5;
		hdbulletactor.hardness 4;
		hdbulletactor.distantsound "world/riflefar";
		hdbulletactor.distantsoundvol 2.;
	}
}
class HDB_9:HDBulletActor{
	default{
		pushfactor 0.4;
		mass 86;
		speed 550;
		accuracy 300;
		stamina 900;
		woundhealth 10;
		hdbulletactor.hardness 3;
	}
}
class HDB_355:HDBulletActor{
	default{
		pushfactor 0.3;
		mass 99;
		speed 600;
		accuracy 240;
		stamina 890;
		woundhealth 15;
		hdbulletactor.hardness 3;
	}
}
class HDB_00:HDBulletActor{
	default{
		pushfactor 0.5;
		mass 25;
		speed 720;
		accuracy 200;
		stamina 838;
		woundhealth 3;
		hdbulletactor.hardness 5;
	}
}
class HDB_wad:HDBulletActor{
	default{
		pushfactor 10.;
		mass 12;
		speed 700; //presumably most energy is transferred to the shot
		accuracy 0;
		stamina 1860;
		woundhealth 5;
		hdbulletactor.hardness 0; //should we change this to a double...
	}
	override void gunsmoke(){}
}
class HDB_frag:HDBulletActor{
	default{
		pushfactor 1.;
		mass 20;
		speed 600;
		accuracy 400;
		stamina 300;
		woundhealth 5;
		deathheight 0.2;	//minimum speed factor
		burnheight 0.5;	//minimum scale factor
		projectilepassheight 3.;	//maximum scale factor
	}
	override void gunsmoke(){}
	override void resetrandoms(){
		double scalefactor=frandom(burnheight,projectilepassheight);
		pushfactor=1./scalefactor;
		let gdbt=getdefaultbytype(getclass());
		mass=max(1,int(gdbt.mass*pushfactor));
		speed=max(1,gdbt.speed*frandom(deathheight,1.));
		accuracy=max(1,int(gdbt.accuracy*frandom(0.3,1.7)));
		stamina=max(1,int(gdbt.stamina*pushfactor));
	}
}
class HDB_scrap:HDB_frag{
	default{
		pushfactor 1.;
		mass 30;
		speed 200;
		accuracy 100;
		stamina 800;
		woundhealth 20;
		deathheight 0.05;
		burnheight 0.1;
		projectilepassheight 10;
	}
}
class HDB_scrapDB:HDB_frag{default{burnheight 0.1; projectilepassheight 8.;}}
class HDB_fragRL:HDB_frag{default{burnheight 0.6; projectilepassheight 5.;}}
class HDB_fragBronto:HDB_scrap{default{speed 300; burnheight 0.8; projectilepassheight 4.;}}
class HDB_bronto:HDBulletActor{
	default{
		pushfactor 0.05;
		mass 5000;
		speed 500;
		accuracy 600;
		stamina 3700;

		hdbulletactor.distantsound "world/shotgunfar";
		hdbulletactor.distantsoundvol 2.;
		missiletype "HDGunsmoke";
		scale 0.08;translation "128:151=%[1,1,1]:[0.2,0.2,0.2]";
		seesound "weapons/riflecrack";
		obituary "%o played %k's cannon.";
	}
	override actor Puff(){
		if(max(abs(pos.x),abs(pos.y))>=32768)return null;
		setorigin(pos-(2*(cos(angle),sin(angle)),0),false);

		A_SprayDecal("BrontoScorch",16);
		if(vel==(0,0,0))A_ChangeVelocity(cos(pitch),0,-sin(pitch),CVF_RELATIVE|CVF_REPLACE);
		else vel*=0.01;
		if(tracer){ //warhead damage
			int dmg=random(1000,1200);
			vector3 hitpoint=vel.unit()*tracer.radius;
			vector3 tracmid=(tracer.pos.xy,tracer.pos.z+tracer.height*0.618);
			dmg=int(1.-((hitpoint-tracmid).length()/tracer.radius)*dmg);
			tracer.damagemobj(
				self,target,
				dmg,
				"Piercing",DMG_THRUSTLESS
			);
		}
		doordestroyer.destroydoor(self,128,frandom(24,36),6,dedicated:true);
		A_HDBlast(
			fragradius:256,fragtype:"HDB_fragBronto",
			immolateradius:64,immolateamount:random(4,20),immolatechance:32,
			source:target
		);
		DistantQuaker.Quake(self,3,35,256,12);
		actor aaa=Spawn("WallChunker",pos,ALLOW_REPLACE);
		A_SpawnChunks("BigWallChunk",20,4,20);
		A_SpawnChunks("HDSmoke",4,1,7);
		aaa=spawn("HDExplosion",pos,ALLOW_REPLACE);aaa.vel.z=2;
		distantnoise.make(aaa,"world/rocketfar");
		A_SpawnChunks("HDSmokeChunk",random(3,4),6,12);

		bmissile=false;
		bnointeraction=true;
		vel=(0,0,0);
		if(!instatesequence(curstate,findstate("death")))setstatelabel("death");
		return null;
	}
	override void onhitactor(actor hitactor,vector3 hitpos,vector3 vu,int flags){
		double spbak=speed;
		super.onhitactor(hitactor,hitpos,vu,flags);
		if(spbak-speed>10)puff();
	}
	override void postbeginplay(){
		super.postbeginplay();
		for(int i=2;i;i--){
			A_SpawnItemEx("TerrorSabotPiece",0,0,0,
				speed*cos(pitch)*0.01,(i==2?3:-3),speed*sin(pitch)*0.01,0,
				SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
			);
		}
	}
	states{
	death:
		TNT1 A 0{if(tracer)puff();}
		goto super::death;
	}
}



class HDBulletTracer:LineTracer{
	hdbulletactor bullet;
	actor shooter;
	override etracestatus tracecallback(){
		if(
			results.hittype==TRACE_HitFloor
			||results.hittype==TRACE_HitCeiling
		){
			int skipsize=bullet.tracesectors.size();
			for(int i=0;i<skipsize;i++){
				if(bullet.tracesectors[i]==results.hitsector)return TRACE_Skip;
			}
		}else if(results.hittype==TRACE_HitActor){
			if(
				results.hitactor==bullet
				||(results.hitactor==shooter&&!bullet.bincombat)
			)return TRACE_Skip;
			int skipsize=bullet.traceactors.size();
			for(int i=0;i<skipsize;i++){
				if(
					bullet.traceactors[i]==results.hitactor
					||(
						results.hitactor is "TempShield"
						&&bullet.traceactors[i]==results.hitactor.master
					)
				)return TRACE_Skip;
			}
		}else if(results.hittype==TRACE_HitWall){
			int skipsize=bullet.tracelines.size();
			for(int i=0;i<skipsize;i++){
				if(bullet.tracelines[i]==results.hitline)return TRACE_Skip;
			}
		}
		return TRACE_Stop;
	}
}
class HDBulletActor:HDActor{
	array<line> tracelines;
	array<actor> traceactors;
	array<sector> tracesectors;

	vector3 realpos;

	int hdbulletflags;
	flagdef neverricochet:hdbulletflags,0;

	int hardness;
	property hardness:hardness;

	sound distantsound;
	property distantsound:distantsound;
	double distantsoundvol;
	property distantsoundvol:distantsoundvol;
	double distantsoundpitch;
	property distantsoundpitch:distantsoundpitch;

	enum BulletConsts{
		BULLET_CRACKINTERVAL=64,

		BLT_HITTOP=1,
		BLT_HITBOTTOM=2,
		BLT_HITMIDDLE=3,
		BLT_HITONESIDED=4,
	}
	const BULLET_TERMINALVELOCITY=-277.;


	default{
		+noblockmap
		+missile
		+noextremedeath
		+cannotpush
		height 0.1;radius 0.1;
		/*
			speed: 200-1000
			mass: in tenths of a gram
			pushfactor: 0.05-5.0 - imagine it being horizontal speed blowing in the wind
			accuracy: 0,200,200-700 - angle of outline from perpendicular, round deemed to be 200
			stamina: 900, 776, 426, you get the idea
			hardness: 1-5 - 1=pure lead, 5=steel (NOTE: this setting's bullets are (Teflon-coated) steel by default; will implement lead casts "later")
		*/
		hdbulletactor.distantsound "";
		hdbulletactor.distantsoundvol 1.;
		hdbulletactor.distantsoundpitch 1.;
		hdbulletactor.hardness 5;
		pushfactor 0.05;
		mass 160;
		speed 1100;
		accuracy 600;
		stamina 776;
	}
	virtual void resetrandoms(){}
	virtual void gunsmoke(){
		actor gs;
		double j=cos(pitch);
		vector3 vk=(j*cos(angle),j*sin(angle),-sin(pitch));
		j=clamp(speed*max(mass,1)*0.00002,0,5);
		if(frandom(0,1)>j)return;
		for(int i=0;i<j;i++){
			gs=spawn("HDGunSmoke",pos+i*vk,ALLOW_REPLACE);
			gs.pitch=pitch;gs.angle=angle;gs.vel=vk*j;
		}
	}
	override void postbeginplay(){
		resetrandoms();
		super.postbeginplay();
		realpos=pos;
		gunsmoke();
		if(distantsound!="")distantnoise.make(self,distantsound,distantsoundvol,distantsoundpitch);
		if(hd_debug){
			scale=(1.,1.);
			sprite=getspriteindex("BAL1A0");
		}else{
			scale=(0.001,0.001)*stamina;
		}
	}
	double penetration(){ //still juvenile giggling
		double pen=
			(25+hardness)*(8000+accuracy)*(30+mass)*(4000+speed)/max(1,200+stamina)*0.00000021
		;
		if(pushfactor>0)pen/=(1.+pushfactor*2.);


		if(hd_debug>1)console.printf(getclassname().." penetration:  "..pen.."   "..realpos.x..","..realpos.y);
		return pen;
	}
	void ApplyDeceleration(){
		vel*=min(1.,1.-pushfactor*0.001);
	}
	void ApplyGravity(){
		if(vel.z>BULLET_TERMINALVELOCITY)vel.z-=max(0.001,getgravity());
	}
	override bool cancollidewith(actor other,bool passive){
		return !passive;
	}
	static HDBulletActor FireBullet(
		actor caller,
		class<HDBulletActor> type="HDBulletActor",
		double zofs=999, //999=use default
		double xyofs=0,
		double spread=0, //range of random velocity added
		double aimoffx=0,
		double aimoffy=0,
		double speedfactor=0,
		int amount=1,
		sound distantsound="",
		double distantsoundvol=1.,
		double distantsoundpitch=1.
	){
		if(zofs==999)zofs=HDWeapon.GetShootOffset(
			caller,caller.player
			&&!!hdweapon(caller.player.readyweapon)
			?hdweapon(caller.player.readyweapon).barrellength:36
		);
		HDBulletActor bbb=null;
		do{
			amount--;
			bbb=HDBulletActor(spawn(type,(caller.pos.x,caller.pos.y,caller.pos.z+zofs)));
			if(bbb.distantsound==""){
				bbb.distantsound=distantsound;
				bbb.distantsoundvol=distantsoundvol;
				bbb.distantsoundpitch=distantsoundpitch;
			}
			if(distantsound!="")distantnoise.make(caller,distantsound,distantsoundvol);
			if(xyofs)bbb.setorigin(bbb.pos+(sin(caller.angle)*xyofs,cos(caller.angle)*xyofs,0),false);

			if(speedfactor>0)bbb.speed*=speedfactor;
			else if(speedfactor<0)bbb.speed=-speedfactor;

			bbb.target=caller;

			if(hdplayerpawn(caller)){
				let hdpc=hdplayerpawn(caller).scopecamera;
				if(hdpc){
					bbb.angle+=hdpc.angle;
					bbb.pitch+=hdpc.pitch;
				}else{
					let hdp=hdplayerpawn(caller);
					bbb.angle+=hdp.angle;
					bbb.pitch+=hdp.pitch;
				}
			}else{
				bbb.angle+=caller.angle;
				bbb.pitch+=caller.pitch;
			}
			if(aimoffx)bbb.angle+=aimoffx;
			if(aimoffy)bbb.pitch+=aimoffy;

			bbb.vel=caller.vel;
			double forward=bbb.speed*cos(bbb.pitch);
			double side=0;
			double updown=bbb.speed*sin(-bbb.pitch);
			if(spread){
				forward+=frandom(-spread,spread);
				side+=frandom(-spread,spread);
				updown+=frandom(-spread,spread);
			}
			bbb.A_ChangeVelocity(forward,side,updown,CVF_RELATIVE);
		}while(amount>0);
		return bbb;
	}
	states{
	spawn:
		BLET A -1;
		stop;
	death:
		TNT1 A 1;
		stop;
	}
	override void tick(){
		if(isfrozen())return;
//if(getage()%17)return;
		if(abs(realpos.x)>32000||abs(realpos.y)>32000){destroy();return;}
		if(
			!bmissile
		){
			super.tick();
			return;
		}

		//update position but keep within the sector
		if(
			realpos.xy!=pos.xy
//			&&level.ispointinlevel(realpos)
		)setorigin((
			realpos.xy,
			clamp(
				realpos.z,
				getzat(realpos.x,realpos.y,flags:GZF_ABSOLUTEPOS),
				getzat(realpos.x,realpos.y,flags:GZF_ABSOLUTEPOS|GZF_CEILING)-height
			)
		),true);

		tracelines.clear();
		traceactors.clear();
		tracesectors.clear();

		//if in the sky
		if(
			ceilingz<realpos.z
			&&ceilingz-realpos.z<vel.z
		){
			if(
				!(level.time&(1|2|4|8|16|32|64|128))
				&&(vel.xy dot vel.xy < 64.)
				&&!level.ispointinlevel(pos)
			){
				destroy();
				return;
			}
			bnointeraction=true;
			binvisible=true;
			realpos+=vel;
			ApplyDeceleration();
			vel.z-=getgravity();
			return;
		}
		if(bnointeraction){
			bnointeraction=false;
			binvisible=false;
		}

		if(vel==(0,0,0)){
			vel.z-=max(0.01,getgravity()*0.01);
			return;
		}

		hdbullettracer blt=HDBulletTracer(new("HDBulletTracer"));
		if(!blt)return;
		blt.bullet=hdbulletactor(self);
		blt.shooter=target;
		vector3 oldpos=realpos;
		vector3 newpos=oldpos;

		//get speed, set counter
		bool doneone=false;
		double distanceleft=vel.length();
		double curspeed=distanceleft;
		do{
			A_FaceMovementDirection();
			tracer=null;

			//update distanceleft if speed changed
			if(curspeed>speed){
				distanceleft-=(curspeed-speed);
				curspeed=speed;
			}

			double cosp=cos(pitch);
			vector3 vu=vel.unit();
			blt.trace(
				realpos,
				cursector,
				vu,
				distanceleft,
				TRACE_HitSky
			);
			traceresults bres=blt.results;
			sector sectortodamage=null;


			//check distance until clear of target
			if(
				!bincombat
				&&(
					!target||
					bres.distance>target.height
				)
			){
				bincombat=true;
			}


			if(bres.hittype==TRACE_HasHitSky){
				realpos+=vel;
				ApplyDeceleration();
				ApplyGravity();
				return;
			}else if(bres.hittype==TRACE_HitNone){
				newpos=bres.hitpos;
				realpos=newpos;
				distanceleft-=max(bres.distance,10.); //safeguard against infinite loops
			}else{
				newpos=bres.hitpos-vu*0.1;
				realpos=newpos;
				distanceleft-=max(bres.distance,10.); //safeguard against infinite loops
				if(bres.hittype==TRACE_HitWall){
					setorigin(realpos,true);  //needed for bulletdie and checkmove

					let hitline=bres.hitline;
					tracelines.push(hitline);

					//get the sector on the opposite side of the impact
					sector othersector;
					if(bres.hitsector==hitline.frontsector)othersector=hitline.backsector;
					else othersector=hitline.frontsector;

					//special stuff that guarantees no more bullet
					if(
						hitline.special==Line_Horizon
					){
						bulletdie();
						return;
					}

					//check if the line is even blocking the bullet
					bool isblocking=(
						!(hitline.flags&line.ML_TWOSIDED) //one-sided
						||hitline.flags&line.ML_BLOCKHITSCAN
						||hitline.flags&line.ML_BLOCKPROJECTILE //maybe? they'll penetrate anyway
						//||hitline.flags&line.ML_BLOCKING //too many of these arbitrarily restrict the player
						//||hitline.flags&line.ML_BLOCKEVERYTHING //not the fences on the range!
						//||bres.tier==TIER_FFloor //3d floor - does not work as of 4.2.0
						||hitline.gethealth()>0
						||( //upper or lower tier, not sky
							(
								(bres.tier==TIER_Upper)
								&&(othersector.gettexture(othersector.ceiling)!=skyflatnum)
							)||(
								(bres.tier==TIER_Lower)
								&&(othersector.gettexture(othersector.floor)!=skyflatnum)
							)
						)
						||!checkmove(bres.hitpos.xy+vu.xy*0.4) //if in any event it won't fit
					);
					//if not blocking, pass through and continue
					if(!isblocking){
						hitline.activate(target,bres.side,SPAC_PCross|SPAC_AnyCross);
						realpos+=vu*0.2;
					}else{

						//"SPAC_Impact" is so wonderfully onomatopoeic
						//would add SPAC_Damage but it doesn't work in 4.1.3???
						hitline.activate(target,bres.side,SPAC_Impact);
						HitGeometry(
							hitline,othersector,bres.side,999+bres.tier,vu,
							doneone?bres.distance:999
						);
					}
				}else if(
					bres.hittype==TRACE_HitFloor
					||bres.hittype==TRACE_HitCeiling
				){
					sector hitsector=bres.hitsector;
					tracesectors.push(hitsector);

					if(
						(
							(bres.hittype==TRACE_HitCeiling)
							&&(hitsector.gettexture(hitsector.ceiling)==skyflatnum)
						)||(
							(bres.hittype==TRACE_HitFloor)
							&&(hitsector.gettexture(hitsector.floor)==skyflatnum)
						)
					)continue;

					setorigin(realpos,true);
					HitGeometry(
						null,hitsector,0,
						bres.hittype==TRACE_HitCeiling?SECPART_Ceiling:SECPART_Floor,
						vu,doneone?bres.distance:999
					);
				}else if(bres.hittype==TRACE_HitActor){
					setorigin(realpos,true);
					if(
						bincombat
						||bres.hitactor!=target
					){
						traceactors.push(bres.hitactor);
						onhitactor(bres.hitactor,bres.hitpos,vu);
					}
				}
			}
			doneone=true;


			//find points close to players and spawn crackers
			//also spawn trails if applicable
			if(speed>256){
				name cracker="";
				if(speed>1000){
					if(mass>100) cracker="SupersonicTrailBig";
					else cracker="SupersonicTrail";
				}else if(speed>800){
					cracker="SupersonicTrail";
				}else if(speed>HDCONST_SPEEDOFSOUND){
					cracker="SupersonicTrailSmall";
				}else if(speed>100){
					cracker="SubsonicTrail";
				}
				if(cracker!=""){
					vector3 crackpos=realpos;
					vector3 crackinterval=vu*BULLET_CRACKINTERVAL;
					int j=int(max(1,bres.distance*(1./BULLET_CRACKINTERVAL)));
					for(int i=0;i<j;i++){
						crackpos-=crackinterval;
						if(hd_debug>1)A_SpawnParticle("yellow",SPF_RELVEL|SPF_RELANG,
							size:12,
							xoff:crackpos.x-pos.x,
							yoff:crackpos.y-pos.y,
							zoff:crackpos.z-pos.z,
							velx:speed*cos(pitch)*0.001,
							velz:-speed*sin(pitch)*0.001
						);
						if(missilename)spawn(missilename,crackpos,ALLOW_REPLACE);
						bool gotplayer=false;
						for(int k=0;!gotplayer && k<MAXPLAYERS;k++){
							if(playeringame[k] && players[k].mo){
								if(
									distance3d(players[k].mo)<256
								){
									gotplayer=true;
									spawn(cracker,crackpos,ALLOW_REPLACE);
								}
							}
						}
					}
				}
			}
		}while(
			bmissile
			&&distanceleft>0
		);

		//destroy the linetracer just in case it interferes with savegames
		blt.destroy();

		//update velocity
		vel+=(
			frandom(-pushfactor,pushfactor),
			frandom(-pushfactor,pushfactor),
			frandom(-pushfactor,pushfactor)
		);
		//reduce momentum
		ApplyDeceleration();
		ApplyGravity();

		//sometimes bullets will freeze (or at least move imperceptibly slowly)
		//and not react to gravity or anything until touched.
		//i've never been able to isolate the cause of this.
		//this forces a bullet to die if its net movement is less than 1 in all cardinal directions.
		//(note: if a bullet is shot straight up and hangs perfectly still for a tick,
		//it's almost certainly "in the sky" and the below code would not be executed.
		//also consider grav acceleration: 32 speed straight up from height 0: +32+30+27+23+18+12+5-3..)
		if(
			abs(oldpos.x-realpos.x)<1
			&&abs(oldpos.y-realpos.y)<1
			&&abs(oldpos.z-realpos.z)<1
		)bulletdie();
	}
	//set to full stop, unflag as missile, death state
	void bulletdie(){
		vel=(0,0,0);
		bmissile=false;
		setstatelabel("death");
	}
	//when a bullet hits a flat or wall
	//add 999 to "hitpart" to use the tier # instead
	virtual void HitGeometry(
		line hitline,
		sector hitsector,
		int hitside,
		int hitpart,
		vector3 vu,
		double lastdist
	){
		double pen=penetration();
		//TODO: MATERIALS AFFECTING PENETRATION AMOUNT
		//(take these fancy todos with a grain of salt - we may be reaching computational limits)

		setorigin(pos-vu,false);
		if(pen>1)A_SprayDecal(speed>600?"BulletChip":"BulletChipSmall",4);
		setorigin(pos+vu,false);

		//inflict damage on destructibles
		//GZDoom native first
		int geodmg=int(pen*(1+pushfactor));
		if(hitline){
			destructible.DamageLinedef(hitline,self,geodmg,"SmallArms2",hitpart,pos,false);
		}
		if(hitsector){
			switch(hitpart-999){
			case TIER_Upper:
				hitpart=SECPART_Ceiling;
				break;
			case TIER_Lower:
				hitpart=SECPART_Floor;
				break;
			case TIER_FFloor:
				hitpart=SECPART_3D;
				break;
			default:
				if(hitpart>=999)hitpart=SECPART_Floor;
				break;
			}
			destructible.DamageSector(hitsector,self,geodmg,"SmallArms2",hitpart,pos,false);
		}

		//then doorbuster
		doordestroyer.destroydoor(self,10*pen*0.001*stamina,frandom(stamina*0.0006,pen*0.00005*stamina),1);


		puff();

		//in case the puff() detonated or destroyed the bullet
		if(!self||!bmissile)return;

		//everything below this should be ricochet or penetration
		if(pen<1.){
			bulletdie();
			return;
		}

		//see if the bullet ricochets
		bool didricochet=false;
		//TODO: don't ricochet on meat, require much shallower angle for liquids

		//if impact is too steep, randomly fail to ricochet
		double maxricangle=frandom(50,90)-pen-hardness;

		if(hitline){
			//angle of line
			//above plus 180, normalized
			//pick the one closer to the bullet's own angle

			//deflect along the line
			if(lastdist>128){ //to avoid infinite back-and-forth at certain angles
				double aaa1=hdmath.angleto(hitline.v1.p,hitline.v2.p);
				double aaa2=aaa1+180;
				double ppp=angle;

				double abs1=absangle(aaa1,ppp);
				double abs2=absangle(aaa2,ppp);
				double hitangle=min(abs1,abs2);

				if(hitangle<maxricangle){
					didricochet=true;
					double aaa=(abs1>abs2)?aaa2:aaa1;
					vel.xy=rotatevector(vel.xy,deltaangle(ppp,aaa)*frandom(1.,1.05));

					//transfer some of the deflection upwards or downwards
					double vlz=vel.z;
					if(vlz){
						double xyl=vel.xy.length()*frandom(0.9,1.1);
						double xyvlz=xyl+vlz;
						vel.z*=xyvlz/xyl;
						vel.xy*=xyl/xyvlz;
					}
					vel.z+=frandom(-0.01,0.01)*speed;
					vel*=1.-hitangle*0.011;
				}
			}
		}else if(
			hitpart==SECPART_Floor
			||hitpart==SECPART_Ceiling
		){
			bool isceiling=hitpart==SECPART_CEILING;
			double planepitch=0;

			//get the relative pitch of the surface
			if(lastdist>128){ //to avoid infinite back-and-forth at certain angles
				double zdif;
				if(checkmove(pos.xy+vel.xy.unit()*0.5))zdif=getzat(0.5,flags:isceiling?GZF_CEILING:0)-pos.z;
				else zdif=pos.z-getzat(-0.5,flags:isceiling?GZF_CEILING:0);
				if(zdif)planepitch=atan2(zdif,0.5);

				planepitch+=frandom(0.,1.);
				if(isceiling)planepitch*=-1;

				double hitangle=absangle(-pitch,planepitch);
				if(hitangle>90)hitangle=180-hitangle;

				if(hitangle<maxricangle){
					didricochet=true;
					//at certain angles the ricochet should reverse xy direction
					if(hitangle>90){
						//bullet ricochets "backward"
						pitch=planepitch;
						angle+=180;
					}else{
						//bullet ricochets "forward"
						pitch=-planepitch;
					}
					speed*=(1-frandom(0.,0.02)*(7-hardness)-(hitangle*0.003));
					A_ChangeVelocity(cos(pitch)*speed,0,sin(-pitch)*speed,CVF_RELATIVE|CVF_REPLACE);
					vel*=1.-hitangle*0.011;
				}
			}
		}

		//see if the bullet penetrates
		if(!didricochet){
			//calculate the penetration distance
			//if that point is in the map:
			vector3 pendest=pos;
			bool dopenetrate=false; //"dope netrate". sounds pleasantly fast.
			int penunits=0;
			for(int i=0;i<pen;i++){
				pendest+=vu;
				if(
					level.ispointinlevel(pendest)
					//performance???
					//&&pendest.z>getzat(pendest.x,pendest.y,0,GZF_ABSOLUTEPOS)
					//&&pendest.z<getzat(pendest.x,pendest.y,0,GZF_CEILING|GZF_ABSOLUTEPOS)
				){
					dopenetrate=true;
					penunits=i;
					break;
				}
			}
			if(dopenetrate){
				//warp forwards to that distance
				setorigin(pendest,true);

				//do a REGULAR ACTOR linetrace
				angle-=180;pitch=-pitch;
				flinetracedata penlt;
				LineTrace(
					angle,
					pen+1,
					pitch,
					flags:TRF_THRUACTORS|TRF_ABSOFFSET,
					data:penlt
				);

				//move to emergence point and spray a decal
				setorigin(pendest+vu*0.3,true);
				puff();
				A_SprayDecal(speed>400?"BulletChip":"BulletChipSmall");
				angle+=180;pitch=-pitch;

				if(penlt.hittype==TRACE_HitActor){
					//if it hits an actor, affect that actor
					traceactors.push(penlt.hitactor);
					onhitactor(penlt.hitactor,penlt.hitlocation,vu);
				}

				//reduce momentum, increase tumbling, etc.
				angle+=frandom(-pushfactor,pushfactor)*penunits;
				pitch+=frandom(-pushfactor,pushfactor)*penunits;
				speed=max(0,speed-frandom(-pushfactor,pushfactor)*penunits*10);
				A_ChangeVelocity(cos(pitch)*speed,0,-sin(pitch)*speed,CVF_RELATIVE|CVF_REPLACE);
			}else{
				puff();
				bulletdie();
				return;
			}
		}

		//warp the bullet
		hardness=max(1,hardness-random(0,random(0,3)));
		stamina=max(1,stamina+random(0,(stamina>>1)));
	}

	enum HitActorFlags{
		BLAF_DONTFRAGMENT=1,

		BLAF_ALLTHEWAYTHROUGH=2,
		BLAF_SUCKINGWOUND=4,
	}
	virtual void onhitactor(actor hitactor,vector3 hitpos,vector3 vu,int flags=0){
		if(!hitactor.bshootable)return;
		tracer=hitactor;
		double hitangle=absangle(angle,angleto(hitactor)); //0 is dead centre
		double pen=penetration();

		let hdmb=hdmobbase(hitactor);
		let hdp=hdplayerpawn(hitactor);

		//because radius alone is not correct
		double deemedwidth=hitactor.radius*frandom(1.8,2.);


		//shields
		if(hdmb&&hdmb.shields>0){
			int bulletpower=int(pen*mass*0.1);
			int depleteshield=min(bulletpower,hdmb.shields);
if(hd_debug)console.printf("BLOCKED  "..depleteshield.."    OF  "..bulletpower..",   "..hdmb.shields-bulletpower.." REMAIN");
			if(
				depleteshield>0
				||bulletpower<1
			){
				hdmb.shields-=depleteshield;
				spawn("ShieldNeverBlood",pos,ALLOW_REPLACE);
				if(!bulletpower||bulletpower<=depleteshield){
					bulletdie();
					return;
				}else{
					double reduceproportion=double(bulletpower-depleteshield)/bulletpower;
					speed*=reduceproportion;
					vel*=reduceproportion;
				}
			}
		}


		//checks for standing character with gaps between feet and next to head
		if(
			(
				hdmb
				&&hitactor.height>hdmb.liveheight*0.7
			)||hitactor.height>getdefaultbytype(hitactor.getclass()).height*0.7
		){
			//pass over shoulder
			//intended to be somewhat bigger than the visible head on any sprite
			if(
				(
					hdp
					||(
						hdmb&&hdmb.bsmallhead
					)
				)&&(
					0.8<
					min(
						pos.z-hitactor.pos.z,
						pos.z+vu.z*hitactor.radius*0.6-hitactor.pos.z
					)/hitactor.height
				)
			){
				if(hitangle>40.)return;
				deemedwidth*=0.6;
			}
			//randomly pass through putative gap between legs and feet
			if(
				(
					hdp
					||(
						hdmb
						&&hdmb.bbiped
					)
				)
			){
				double aat=angleto(hitactor);
				double haa=hitactor.angle;
				aat=min(absangle(aat,haa),absangle(aat,haa+180));

				haa=max(
					pos.z-hitactor.pos.z,
					pos.z+vu.z*hitactor.radius-hitactor.pos.z
				)/hitactor.height;

				//do the rest only if the shot is low enough
				if(haa<0.35){
					//if directly in front or behind, assume the space exists
					if(aat<7.){
						if(hitangle<7.)return;
					}else{
						//if not directly in front, increase space as you go down
						//this isn't actually intended to reflect any particular sprite
						int whichtick=level.time&(1|2); //0,1,2,3
						if(hitangle<4.+whichtick*(1.-haa))return;
					}
				}
			}
		}


		//destroy radsuit if worn and pen above threshold
		if(hitactor.countinv("WornRadsuit")&&pen>frandom(1,4)){
			hitactor.A_TakeInventory("WornRadsuit");
			hitactor.A_StartSound("radsuit/burst",CHAN_AUTO,CHANF_OVERLAP);
		}


		//determine bullet resistance
		double penshell;
		if(hdmb)penshell=max(hdmb.bulletresistance(hitangle),hdmb.bulletshell(hitpos,hitangle));
		else penshell=0.6;

		bool hitactoristall=hitactor.height>hitactor.radius*2;

		//apply armour if any
		if(
			hitactor.findinventory("HDArmourWorn")
			&&!(
				//if standing right over an incap'd victim, bypass armour
				pitch>80
				&&(
					(hdp&&hdp.incapacitated)
					||(
						hdmb
						&&hdmb.frame>=hdmb.downedframe
						&&hdmb.instatesequence(hdmb.curstate,hdmb.resolvestate("falldown"))
					)
				)
				&&!!target
				&&abs(target.pos.z-pos.z)<target.height
			)
		){
			let armr=HDArmourWorn(hitactor.findinventory("HDArmourWorn"));
			double hitheight=hitactoristall?((hitpos.z-hitactor.pos.z)/hitactor.height):0.5;

			double addpenshell=armr.mega?30:(10+max(0,((armr.durability-120)>>3)));

			//poorer armour on legs and head
			//sometimes slip through a gap
			int crackseed=int(level.time+angle)&(1|2|4|8|16|32);
			if(hitheight>0.8){
				if(hdmb&&!hdmb.bhashelmet)addpenshell=-1;else{
					//face?
					if(
						crackseed>clamp(armr.durability,1,3)
						&&absangle(angle,hitactor.angle)>(180.-5.)
						&&pitch>-20
						&&pitch<7
					)addpenshell*=frandom(0.1,0.9);else
					//head: thinner material required
					addpenshell=min(addpenshell,frandom(10,20));
				}
			}else if(hitheight<0.4){
				//legs: gaps and thinner (but not that much thinner) material
				if(crackseed>clamp(armr.durability,1,8))
					addpenshell*=frandom(frandom(0,0.9),1.);
			}else if(
				crackseed>max(armr.durability,8)
			){
				//torso: just kinda uneven
				addpenshell*=frandom(0.8,1.1);
			}

			if(addpenshell>0){
				//bullet hits armour

				//degrade and puff
				int ddd=random(-1,(int(min(pen,addpenshell)*stamina)>>12));
				if(ddd<1&&pen>addpenshell)ddd=1;
				if(ddd>0)armr.durability-=ddd;
				if(ddd>2){
					actor p;bool q;
					[q,p]=hitactor.A_SpawnItemEx("FragPuff",
						-hitactor.radius*0.6,0,pos.z-hitactor.pos.z,
						4,0,1,
						0,0,64
					);
					if(p)p.vel+=hitactor.vel;
				}
				if(armr.durability<1)armr.destroy();
			}else if(addpenshell>-0.5){
				//bullet leaves a hole in the webbing
				armr.durability-=max(random(0,1),(stamina>>7));
			}
			else if(hd_debug)console.printf("missed the armour!");

			if(hd_debug)console.printf(hitactor.getclassname().."  armour resistance:  "..addpenshell);
			penshell+=addpenshell;

			if(
				penshell>pen
				&&hitactor.health>0
				&&hitactoristall
			){
				hitactor.vel+=vu*0.001*hitheight*mass;
				if(
					hdp
					&&!hdp.incapacitated
				){
					hdp.hudbobrecoil2+=(frandom(-5.,5.),frandom(2.5,4.))*0.01*hitheight*mass;
					hdp.playrunning();
				}else if(random(0,255)<hitactor.painchance) hdmobbase.forcepain(hitactor);
			}
		}

		if(penshell<=0)penshell=0;
		else penshell*=1.-frandom(0,hitangle*0.004);

		if(hd_debug)A_Log("Armour: "..pen.."    -"..penshell.."    = "..pen-penshell.."     "..hdmath.getname(hitactor));

		//apply final armour and abort if totally blocked
		pen-=penshell;

		//deform the bullet
		hardness=max(1,hardness-random(0,random(0,3)));
		stamina=max(1,stamina+random(0,(stamina>>1)));

		//immediate impact
		//highly random
		double tinyspeedsquared=speed*speed*0.000001;
		double impact=tinyspeedsquared*0.1*mass;

		//bullet hits without penetrating
		//abandon all damage after impact, then check ricochet
		if(pen<deemedwidth*0.01){
			//if bullet too soft and/or slow, just die
			if(speed<32||hardness<random(1,3)||!random(0,6))bulletdie();

			//randomly deflect
			//if deflected, reduce impact
			if(
				bmissile
				&&hitangle>10
			){
				double dump=clamp(0.011*(90-hitangle),0.01,1.);
				impact*=dump;
				speed*=(1.-dump);
				angle+=frandom(10,25)*randompick(1,-1);
				pitch+=frandom(-25,25);
				A_ChangeVelocity(cos(pitch)*speed,0,sin(-pitch)*speed,CVF_RELATIVE|CVF_REPLACE);
			}


			//apply impact damage
			if(impact>(hitactor.spawnhealth()>>2))hdmobbase.forcepain(hitactor);
			if(hd_debug)console.printf(hitactor.getclassname().." resisted, impact:  "..impact);
			hitactor.damagemobj(self,target,int(impact),"bashing");
			return;
		}


		//check if going right through the body
		if(pen>deemedwidth-0.02*hitangle)flags|=BLAF_ALLTHEWAYTHROUGH;

		//both impact and temp cavity do bashing
		impact+=speed*speed*(
			(flags&BLAF_ALLTHEWAYTHROUGH)?
			0.00004:
			0.00005
		);

		int shockbash=int(max(impact,impact*min(pen,deemedwidth))*(frandom(0.2,0.25)+stamina*0.00001));
		if(hd_debug)console.printf("     "..shockbash.." temp cav dmg");

		//apply impact/tempcav damage
		bnoextremedeath=impact<(hitactor.gibhealth<<3);
		hitactor.damagemobj(self,target,shockbash,"bashing",DMG_THRUSTLESS);
		if(!hitactor)return;
		bnoextremedeath=true;


		//spawn entry and exit wound blood
		if(!bbloodlessimpact){
			class<actor>hitblood;
			bool noblood=hitactor.bnoblood;
			if(noblood)hitblood="FragPuff";else hitblood=hitactor.bloodtype;
			double ath=angleto(hitactor);
			double zdif=pos.z-hitactor.pos.z;
			bool gbg;actor blood;
			[gbg,blood]=hitactor.A_SpawnItemEx(
				hitblood,
				-hitactor.radius,0,zdif,
				angle:ath,
					flags:SXF_ABSOLUTEANGLE|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
			);
			if(blood)blood.vel=-vu*(min(3,0.05*impact))
				+(frandom(-0.6,0.6),frandom(-0.6,0.6),frandom(-0.2,0.4)
			);
			if(!noblood)hitactor.TraceBleedAngle((shockbash>>3),angle+180,-pitch);
			if(flags&BLAF_ALLTHEWAYTHROUGH){
				[gbg,blood]=hitactor.A_SpawnItemEx(
					hitblood,
					hitactor.radius,0,zdif,
					angle:ath+180,
					flags:SXF_ABSOLUTEANGLE|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
				);
				if(blood)blood.vel=vu+(frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.4));
				if(!noblood)hitactor.TraceBleedAngle((shockbash>>3),angle,pitch);
			}
		}


		//basic threshold bleeding
		//proportionate to permanent wound channel
		//stamina, pushfactor, hardness
		double channelwidth=
			(
				//if it doesn't bleed, it's probably rigid
				(
					hdmobbase(hitactor)
					&&hdmobbase(hitactor).bdoesntbleed
				)?0.0004:0.0002
			)*stamina
			*frandom(20.,20+pushfactor-hardness)
			+stamina*frandom(0.0005,0.005)
		;

		//reduce momentum, increase tumbling, etc.
		double totalresistance=deemedwidth*((!!hdmb)?hdmb.bulletresistance(hitangle):0.6);
		angle+=frandom(-pushfactor,pushfactor)*totalresistance;
		pitch+=frandom(-pushfactor,pushfactor)*totalresistance;
		speed=max(0,speed-frandom(0,pushfactor)*totalresistance*10);
		A_ChangeVelocity(cos(pitch)*speed,0,-sin(pitch)*speed,CVF_RELATIVE|CVF_REPLACE);

		if(flags&BLAF_ALLTHEWAYTHROUGH)channelwidth*=1.2;
		else bulletdie();


		//add size of channel to damage
		int chdmg=int(max(1,
			channelwidth
			*max(0.1,pen-(hitangle*0.06))
			*0.1
		));

		//see if the bullet may actually gib
		bnoextremedeath=(chdmg<(max(hitactor.spawnhealth(),gibhealth)<<4));
		if(hd_debug)console.printf(hitactor.getclassname().."  wound channel:  "..channelwidth.." x "..pen.."    channel HP damage: "..chdmg);

		//inflict wound
		if(target&&hitactor.isteammate(target))channelwidth*=teamdamage;
		if(channelwidth>0)hdbleedingwound.inflict(
			hitactor,int(pen),int(channelwidth),(flags&BLAF_SUCKINGWOUND),source:target
		);

		//evaluate cns hit/critical and apply damage
		if(
			pen>deemedwidth*0.4
			&&hitangle<12+frandom(0,tinyspeedsquared*7+stamina*0.001)
		){
			double mincritheight=hitactor.height*0.6;
			double basehitz=hitpos.z-hitactor.pos.z;
			if(
				basehitz>mincritheight
				||basehitz+pen*vu.z>mincritheight
			){
				if(hd_debug)console.printf("CRIT!");
				int critdmg=int(
					(chdmg+random((stamina>>5),(stamina>>5)+(int(speed)>>6)))
					*(1.+pushfactor*0.3)
				);
				if(bnoextremedeath)critdmg=min(critdmg,hitactor.health+1);
				flags|=BLAF_SUCKINGWOUND;
				pen*=2;
				channelwidth*=2;
				hdmobbase.forcepain(hitactor);
				hitactor.damagemobj(self,target,critdmg,"Piercing",DMG_THRUSTLESS);
			}
		}else{
			if(frandom(0,pen)>deemedwidth)flags|=BLAF_SUCKINGWOUND;
			hitactor.damagemobj(
				self,target,
				chdmg,
				"Piercing",DMG_THRUSTLESS
			);
		}

		//fragmentation
		if(!(flags&BLAF_DONTFRAGMENT)&&random(0,100)<woundhealth){
			int fragments=clamp(random(2,(woundhealth>>3)),1,5);
			if(hd_debug)console.printf(fragments.." fragments emerged from bullet");
			while(fragments){
				fragments--;
				let bbb=HDBulletActor(spawn("HDBulletActor",pos));
				bbb.target=target;
				bbb.bincombat=false;
				double newspeed;
				speed*=0.6;
				if(!fragments){
					bbb.mass=mass;
					newspeed=speed;
					bbb.stamina=stamina;
				}else{
					//consider distributing this more randomly between the fragments?
					bbb.mass=max(1,random(1,mass-1));
					bbb.stamina=max(1,random(1,stamina-1));
					newspeed=frandom(0,speed-1);
					mass-=bbb.mass;
					stamina=max(1,stamina-bbb.stamina);
					speed-=newspeed;
				}
				bbb.pushfactor=frandom(0.6,5.);
				bbb.accuracy=random(50,300);
				bbb.angle=angle+frandom(-45,45);
				double newpitch=pitch+frandom(-45,45);
				bbb.pitch=newpitch;
				bbb.A_ChangeVelocity(
					cos(newpitch)*newspeed,0,-sin(newpitch)*newspeed,CVF_RELATIVE|CVF_REPLACE
				);
			}
			bulletdie();
			return;
		}
	}
	virtual actor Puff(){
		//TODO: virtual actor puff(textureid hittex,bool reverse=false){}
			//flesh: bloodsplat
			//fluids: splash
			//anything else: puff and add bullet hole

		if(max(abs(pos.x),abs(pos.y))>32000)return null;
		double sp=speed*speed*mass*0.00001;
		name pufftype="BulletPuffBig";
		if(sp>800)pufftype="BulletPuffBig";
		else if(sp>512)pufftype="BulletPuffMedium";
		else pufftype="BulletPuffSmall";
		let aaa=HDBulletPuff(spawn("HDBulletPuff",pos));
		if(aaa){
			aaa.angle=angle;aaa.pitch=pitch;
			aaa.stamina=int(sp*0.01);
			aaa.scarechance=20-int(sp*0.001);
			aaa.scale=(1.,1.)*(0.4+0.05*aaa.stamina);
		}
		return aaa;
	}
}


//trail actors for flyby sounds
class SupersonicTrail:IdleDummy{
	states{
	spawn:
		TNT1 A 10;stop;
	}
	override void postbeginplay(){
		if(
			frandom(0,ceilingz-floorz)<128
		)A_AlertMonsters();
		A_StartSound("weapons/bulletcrack",CHAN_AUTO,volume:0.32);
	}
}
class SupersonicTrailBig:SupersonicTrail{
	override void postbeginplay(){
		A_AlertMonsters();
		A_StartSound("weapons/bulletcrack",CHAN_AUTO,volume:0.64);
	}
}
class SupersonicTrailSmall:SupersonicTrail{
	override void postbeginplay(){
		if(
			frandom(0,ceilingz-floorz)<64
		)A_AlertMonsters();
		A_StartSound("weapons/bulletcrack",CHAN_AUTO,volume:0.1);
	}
}
class SubsonicTrail:SupersonicTrail{
	override void postbeginplay(){
		if(
			frandom(0,ceilingz-floorz)<32
		)A_AlertMonsters();
		A_StartSound("weapons/subfwoosh",CHAN_AUTO,volume:0.03);
	}
}



//#include "zscript/bullet_old.zs"

