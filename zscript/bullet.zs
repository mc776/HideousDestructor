// ------------------------------------------------------------
// The Bullet!
// ------------------------------------------------------------

class bltest:hdweapon{
	default{
		+inventory.undroppable
		weapon.slotnumber 1;
		hdweapon.refid "blt";
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
			HDBulletActor.FireBullet(self,"HDB_00",spread:6,amount:7);
		}goto nope;
	}
}
class HDB_426:HDBulletActor{
	default{
		pushfactor 0.4;
		mass 55;
		speed 1200;
		accuracy 666;
		stamina 426;
		woundhealth 40;
		hdbulletactor.hardness 2;
		hdbulletactor.distantsounder "DistantRifle";
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
		hdbulletactor.distantsounder "DoubleDistantRifle";
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
		mass 35;
		speed 720;
		accuracy 200;
		stamina 838;
		woundhealth 3;
		// hdbulletactor.distantsounder "DoubleDistantRifle"; //don't enable this here
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
		mass 30;
		speed 600;
		accuracy 100;
		stamina 500;
		woundhealth 5;
	}
	override void gunsmoke(){}
	virtual double setscalefactor(){return frandom(0.5,3.);}
	override void resetrandoms(){
		double scalefactor=setscalefactor();
		pushfactor=1./scalefactor;
		mass=max(1,getdefaultbytype(getclass()).mass*pushfactor);
		speed*=scalefactor;
		accuracy=max(1,getdefaultbytype(getclass()).accuracy*scalefactor);
		stamina=max(1,getdefaultbytype(getclass()).stamina*pushfactor);
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
	}
	override double setscalefactor(){return frandom(0.6,6.);}
}
class HDB_bronto:HDBulletActor{
	default{
		pushfactor 0.05;
		mass 5000;
		speed 500;
		accuracy 600;
		stamina 3700;

		hdbulletactor.distantsounder "DoubleDistantShotgun";
		missiletype "HDGunsmoke";
		scale 0.08;translation "128:151=%[1,1,1]:[0.2,0.2,0.2]";
		seesound "weapons/riflecrack";
		obituary "%o played %k's cannon.";
	}
	override actor Puff(){
		setorigin(pos-(2*(cos(angle),sin(angle)),0),false);
		bulletdie();
		bmissile=false;
		return null;
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
	spawn:
		MISL A -1;
	death:
		TNT1 A 16{
			A_SprayDecal("BrontoScorch",16);
			bmissile=false;
			vel*=0.01;
			if(tracer)tracer.damagemobj( //warhead damage
				self,target,
				random(12,24)*60,
				"SmallArms3",DMG_THRUSTLESS
			);
			doordestroyer.destroydoor(self,128,frandom(24,36),6);
			A_HDBlast(
				fragradius:256,fragtype:"HDB_scrap",fragvariance:3.,
				immolateradius:64,immolateamount:random(4,20),immolatechance:32,
				source:target
			);
			DistantQuaker.Quake(self,3,35,256,12);

			if(max(abs(pos.x),abs(pos.y))>=32768)return;
			actor aaa=Spawn("WallChunker",pos,ALLOW_REPLACE);
			A_SpawnChunks("BigWallChunk",20,4,20);
			A_SpawnChunks("HDSmoke",4,1,7);
			aaa=spawn("HDExplosion",pos,ALLOW_REPLACE);aaa.vel.z=2;
			spawn("DistantRocket",pos,ALLOW_REPLACE);
			vel.z+=10;
			A_SpawnChunks("HDSmokeChunk",random(3,4),6,12);
		}
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

	int hdbulletflags;
	flagdef neverricochet:hdbulletflags,0;

	int hardness;
	property hardness:hardness;

	class<actor> distantsounder;
	property distantsounder:distantsounder;

	enum BulletConsts{
		BULLET_TERMINALVELOCITY=-277,
		BULLET_CRACKINTERVAL=64,

		BLT_HITTOP=1,
		BLT_HITBOTTOM=2,
		BLT_HITMIDDLE=3,
		BLT_HITONESIDED=4,
	}


	default{
//		+solid
		+noblockmap
		+missile
		+noextremedeath
		+cannotpush
		height 0.1;radius 0.1;
		/*
			speed: 200-1000
			mass: in tenths of a gram
			pushfactor: 0.05-5.0 - imagine it being horizontal speed blowing in the wind
			accuracy: 0,200,200-700 - angle of outline from perpendicular, round deemed to be 20
			stamina: 900, 776, 426, you get the idea
			hardness: 1-5 - 1=pure lead, 5=steel (NOTE: this setting's bullets are (Teflon-coated) steel by default; will implement lead casts "later")
		*/
		hdbulletactor.distantsounder "none";
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
		gunsmoke();
		if(distantsounder!="none"){
			actor m=spawn(distantsounder,pos,ALLOW_REPLACE);
			m.target=target;
		}
	}
	double penetration(){ //still juvenile giggling
		double pen=
			clamp(speed*0.02,0,((hardness*mass)>>2))
			+(
				mass
				+double(accuracy)/max(1,stamina)
			)*0.16
		;
		if(pushfactor>0)pen/=(1.+pushfactor*2.);
		if(stamina<100)pen*=stamina*0.01;

		if(hd_debug>1)console.printf("penetration:  "..pen.."   "..pos.x..","..pos.y);
		return pen;
	}
	override bool cancollidewith(actor other,bool passive){
		return !passive;
	}
	static HDBulletActor FireBullet(
		actor caller,
		class<HDBulletActor> type="HDBulletActor",
		double zofs=999, //default: height-6
		double xyofs=0,
		double spread=0, //range of random velocity added
		double aimoffx=0,
		double aimoffy=0,
		double speedfactor=0,
		int amount=1
	){
		if(zofs==999)zofs=caller.height-6;
		HDBulletActor bbb=null;
		do{
			amount--;
			bbb=HDBulletActor(spawn(type,(caller.pos.x,caller.pos.y,caller.pos.z+zofs)));
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
		BAL1 A -1 nodelay A_JumpIf(!hd_debug,1);
		BLET A -1 A_SetScale(0.3);
		stop;
	death:
		TNT1 A 1;
		stop;
	}
	override void tick(){
		if(isfrozen())return;
//if(getage()%17)return;
		if(abs(pos.x)>32000||abs(pos.y)>32000){destroy();return;}
		if(!bmissile){
			super.tick();
			return;
		}

		tracelines.clear();
		traceactors.clear();
		tracesectors.clear();

		//if in the sky
		if(
			ceilingz<pos.z
			&&ceilingz-pos.z<vel.z
		){
			bnointeraction=true;
			setorigin(pos+vel,false);
			vel-=vel.unit()*pushfactor;
			vel.z-=getgravity();
			return;
		}
		if(bnointeraction)bnointeraction=false;

		if(vel.xy==(0,0)&&abs(vel.z)<64){
			bulletdie();
			return;
		}

		hdbullettracer blt=HDBulletTracer(new("HDBulletTracer"));
		if(!blt)return;
		blt.bullet=hdbulletactor(self);
		blt.shooter=target;
		vector3 oldpos=pos;
		vector3 newpos=oldpos;

		//get speed, set counter
		int iterations=0;
		double distanceleft=vel.length();
		double curspeed=distanceleft;
		do{
			A_FaceMovementDirection();
			//update distanceleft if speed changed
			if(curspeed>speed){
				distanceleft-=(curspeed-speed);
				curspeed=speed;
			}

			double cosp=cos(pitch);
			vector3 vu=vel.unit();
			blt.trace(
				pos,
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
				setorigin(pos+vel,true);
				vel-=vel.unit()*pushfactor;
				vel.z-=getgravity();
				return;
			}else if(bres.hittype==TRACE_HitNone){
				newpos=bres.hitpos;
				setorigin(newpos,true);
				distanceleft-=max(bres.distance,0.01); //safeguard against infinite loops
			}else{
				//the decal must be shot out from here to be reliable
				if(bres.hittype==TRACE_HitWall)
					A_SprayDecal(speed>400?"BulletChip":"BulletChipSmall",distanceleft+100);

				newpos=bres.hitpos-vu*0.1;
				setorigin(newpos,true);
				distanceleft-=max(bres.distance,0.01); //safeguard against infinite loops
				if(bres.hittype==TRACE_HitWall){
					let hitline=bres.hitline;
					tracelines.push(hitline);

					//get the sector on the opposite side of the impact
					sector othersector;
					if(bres.hitsector==hitline.frontsector)othersector=hitline.backsector;
					else othersector=hitline.frontsector;

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
						setorigin(newpos+vu*0.2,true);
					}else{
						//"SPAC_Impact" is so wonderfully onomatopoeic
						//would add SPAC_Damage but it doesn't work in 4.1.3???
						hitline.activate(target,bres.side,SPAC_Impact);
						HitGeometry(
							hitline,othersector,bres.side,999+bres.tier,vu,
							iterations?bres.distance:999
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

					HitGeometry(
						null,hitsector,0,
						bres.hittype==TRACE_HitCeiling?SECPART_Ceiling:SECPART_Floor,
						vu,iterations?bres.distance:999
					);
				}else if(bres.hittype==TRACE_HitActor){
					if(
						bincombat
						||bres.hitactor!=target
					){
						traceactors.push(bres.hitactor);
						onhitactor(bres.hitactor,bres.hitpos,vu);
					}
				}
			}
			iterations++;


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
					vector3 crackbak=pos;
					vector3 crackinterval=vu*BULLET_CRACKINTERVAL;
					int j=max(1,bres.distance*(1./BULLET_CRACKINTERVAL));
					for(int i=0;i<j;i++){
						setxyz(crackbak+crackinterval*i);
						if(hd_debug>1)A_SpawnParticle("yellow",SPF_RELVEL|SPF_RELANG,
							size:12,
							velx:speed*cos(pitch)*0.001,
							velz:-speed*sin(pitch)*0.001
						);
						if(missilename)spawn(missilename,pos,ALLOW_REPLACE);
						bool gotplayer=false;
						for(int k=0;!gotplayer && k<MAXPLAYERS;k++){
							if(playeringame[k] && players[k].mo){
								if(
									distance3d(players[k].mo)<256
								){
									gotplayer=true;
									spawn(cracker,pos,ALLOW_REPLACE);
								}
							}
						}
					}
					setxyz(crackbak);
				}
			}
		}while(
			bmissile
			&&distanceleft>0
		);

		//destroy the linetracer just in case it interferes with savegames
		blt.destroy();

		//update velocity
		A_ChangeVelocity(
			frandom(-pushfactor,pushfactor),
			frandom(-pushfactor,pushfactor),
			-getgravity(),
			CVF_RELATIVE
		);

		//force disappearance if stuck
		//not a fix but a workaround
		if(oldpos==pos)bulletdie();
	}
	//set to full stop, unflag as missile, death state
	void bulletdie(){
		vel=(0,0,0);
		bmissile=false;
		setstatelabel("death");
	}
	//when a bullet hits a flat or wall
	//add 999 to "hitpart" to use the tier # instead
	void HitGeometry(
		line hitline,
		sector hitsector,
		int hitside,
		int hitpart,
		vector3 vu,
		double lastdist
	){
		double pen=penetration();
//TODO: MATERIALS AFFECTING PENETRATION AMOUNT

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
		//then doorbuster??? --do later, maybe

		puff();

		//in case the puff() detonated or destroyed the bullet
		if(!self||!bmissile)return;

		//no one cares after this
		if(pen<1.){
			bulletdie();
			return;
		}

		//see if the bullet ricochets
		bool didricochet=false;
			//don't ricochet on meat
			//require much shallower angle for liquids

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
	void forcepain(actor victim){
		if(
			victim
			&&!victim.bnopain
			&&victim.health>0
			&&victim.findstate("pain")
		)victim.setstatelabel("pain");
	}
	void onhitactor(actor hitactor,vector3 hitpos,vector3 vu){
		if(!hitactor.bshootable)return;
		double hitangle=absangle(angle,angleto(hitactor)); //0 is dead centre
		double pen=penetration();


		//because radius alone is not correct
		double deemedwidth=hitactor.radius*frandom(1.8,2.);


		//pass over shoulder, kinda
		//intended to be somewhat bigger than the visible head on any sprite
		if(
			(
				hdplayerpawn(hitactor)
				||(
					hdmobbase(hitactor)&&hdmobbase(hitactor).bsmallhead
				)
			)
			&&hitactor.height>42
		){
			double haa=min(
				pos.z-hitactor.pos.z,
				pos.z+vu.z*hitactor.radius*0.6-hitactor.pos.z
			)/hitactor.height;
			if(haa>0.8){
				if(hitangle>40.)return;
				deemedwidth*=0.6;
			}
		}
		//randomly pass through putative gap between legs and feet
		if(
			(
				hdplayerpawn(hitactor)
				||(
					hdmobbase(hitactor)&&hdmobbase(hitactor).bbiped
				)
			)
			&&hitactor.height>42
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


		//determine bullet resistance
		double hitactorresistance;
		double penshell;
		let hdmb=hdmobbase(hitactor);
		if(hdmb){
			hitactorresistance=hdmb.bulletresistance(hitangle);
			penshell=hdmb.bulletshell(hitpos,hitangle);
		}else{
			hitactorresistance=0.6;
			penshell=0;
		}

		//destroy radsuit if worn and pen above threshold
		if(hitactor.countinv("WornRadsuit")&&pen>frandom(1,4)){
			hitactor.A_TakeInventory("WornRadsuit");
			hitactor.A_PlaySound("misc/fwoosh",CHAN_AUTO);
		}

		//apply armour if any
		let armr=HDArmourWorn(hitactor.findinventory("HDArmourWorn"));
		if(armr){
			double hitheight=(hitpos.z-hitactor.pos.z)/hitactor.height;

			double addpenshell=0;

			int hitlevel;
			if(hitheight>0.8)hitlevel=2;
			else if(hitheight>0.4)hitlevel=1;
			else hitlevel=0;

			int alv=armr.mega?3:1;
			if(!random(0,max((armr.durability>>2),3)))alv=-1; //slips through a gap
			else if(
				hitlevel==2
				&&(
					hitactor is "hdplayerpawn"
					||(
						!!hdmb
						&&hdmb.bhashelmet
					)
				)
			)alv=randompick(0,1,random(0,alv),alv);
			else if(hitlevel==0)alv=max(alv-randompick(0,0,0,1,1,1,1,2),0);

			if(alv>0){
				addpenshell=frandom(9,11)*alv;

				//degrade and puff
				int ddd=int(min(pen,addpenshell)*stamina)>>14;
				if(ddd<1&&pen>addpenshell)ddd=1;
				armr.durability-=ddd;
				if(ddd>2){
					actor p;bool q;
					[q,p]=hitactor.A_SpawnItemEx("FragPuff",
						0,0,0,
						4,0,1,
						0,0,64
					);
					if(p)p.vel+=hitactor.vel;
				}

				//TODO: side effects
			}else if(!alv){
				//bullet leaves a hole in the webbing
				armr.durability-=max(random(0,1),(stamina>>7));
			}
			else if(hd_debug)console.printf("missed the armour!");
			if(hd_debug)console.printf(hitactor.getclassname().."  armour resistance:  "..addpenshell);
			addpenshell*=60./mass;
			penshell+=addpenshell;
		}

		penshell=max(
			0,
			penshell,
			hitactorresistance
		)*(HDCONST_SPEEDOFSOUND+stamina)/(speed+accuracy)*(1.-hitangle*0.006);


		//decelerate
		double shortpen=pen-penshell;
		if(shortpen<0.1){
			puff();
			bulletdie();
			return;
		}
		double shortshortpen=min(shortpen,hitactor.radius*2); //used to place bullet on other side of actor
		double sspratio=shortpen/pen;
		if(sspratio<1.){
			vel*=sspratio;
			speed*=sspratio;
		}
		pen=shortpen;

		bool deepenough=pen>deemedwidth*0.01;

		//deform the bullet
		hardness=max(1,hardness-random(0,random(0,3)));
		stamina=max(1,stamina+random(0,(stamina>>1)));

		//immediate impact
		//highly random
		double tinyspeedsquared=speed*speed*0.000001;
		double impact=tinyspeedsquared*0.1*mass;

		//bullet hits without penetrating
		//abandon all damage after impact, then check ricochet
		if(!deepenough){
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

			hitactor.damagemobj(self,target,impact,"bashing");
			if(impact>(hitactor.spawnhealth()>>2))forcepain(hitactor);
			if(hd_debug)console.printf(hitactor.getclassname().." resisted, impact:  "..impact);
			return;
		}

		//check if going right through the body
		//it's not "deep enough", it's "too deep" now!
		deepenough=pen<deemedwidth-0.02*hitangle;

		//bullet penetrated, both impact and temp cavity do bashing
		impact+=tinyspeedsquared*(deepenough?frandom(0.07,0.1):frandom(0.03,0.08))*stamina;

		bnoextremedeath=impact<(hitactor.gibhealth<<3);
		hitactor.damagemobj(self,target,max(impact,pen*impact*0.03*hitactorresistance),"bashing",DMG_THRUSTLESS);
		bnoextremedeath=true;

		//determine what kind of blood to use
		class<actor>hitblood;
		if(hitactor.bnoblood)hitblood="FragPuff";else hitblood=hitactor.bloodtype;

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
		;
		if(deepenough)bulletdie();
		else{
			channelwidth*=1.1;
			//then spawn exit wound blood
			if(!bbloodlessimpact){
				double hrad=hitactor.radius*0.6;
				for(int i=0;i<pen;i+=10){
					bool gbg;actor blood;
					[gbg,blood]=hitactor.A_SpawnItemEx(
						hitblood,
						hrad,0,pos.z-hitactor.pos.z,
						angle:hitactor.angleto(self),
						flags:SXF_ABSOLUTEANGLE|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
					);
					if(blood){
						blood.vel=vu*(0.6*min(pen*0.2,12))
						+(frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.4)
						);
						if(!i)blood.A_PlaySound(blood.seesound,CHAN_BODY);
					}
				}
			}
			//reduce momentum, increase tumbling, etc.
			double totalresistance=hitactorresistance*deemedwidth;
			angle+=frandom(-pushfactor,pushfactor)*totalresistance;
			pitch+=frandom(-pushfactor,pushfactor)*totalresistance;
			speed=max(0,speed-frandom(-pushfactor,pushfactor)*totalresistance*10);
			A_ChangeVelocity(cos(pitch)*speed,0,-sin(pitch)*speed,CVF_RELATIVE|CVF_REPLACE);
		}

		//major-artery incurable bleeding
		//can't be done on "just" a graze (abs(angle,angleto(hitactor))>50)
		//random chance depending on amount of penetration
		bool suckingwound=frandom(0,pen)>deemedwidth;

		//spawn entry wound blood
		//do more if there's a sucking wound
		if(!bbloodlessimpact){
			for(int i=-1;i<suckingwound;i++){
				bool gbg;actor blood;
				[gbg,blood]=hitactor.A_SpawnItemEx(
					hitblood,
					-hitactor.radius*0.6,0,pos.z-hitactor.pos.z,
					angle:angleto(hitactor),
						flags:SXF_ABSOLUTEANGLE|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
				);
				if(blood){
					blood.vel=-vu*(0.03*min(12,impact))
						+(frandom(-0.6,0.6),frandom(-0.6,0.6),frandom(-0.2,0.4)
					);
					if(!i)blood.A_PlaySound(blood.seesound,CHAN_BODY);
				}
			}
		}

		//add size of channel to damage
		int chdmg=max(1,channelwidth*max(0.1,pen-(hitangle*0.06))*0.3);
if(hd_debug)console.printf(hitactor.getclassname().."  wound channel:  "..channelwidth.." x "..pen.."    channel HP damage: "..chdmg);
		bnoextremedeath=(chdmg<(max(hitactor.spawnhealth(),gibhealth)<<4));

		//cns severance
		//small column in middle centre
		double mincritheight=hitactor.height*0.6;
		double basehitz=hitpos.z-hitactor.pos.z;
		if(
			hitangle<10+tinyspeedsquared*7
			&&(
				basehitz>mincritheight
				||basehitz+shortpen*vu.z>mincritheight
			)
			&&pen>deemedwidth*0.4
		){
			if(hd_debug)console.printf("CRIT!");
			int critdmg=(chdmg+random((stamina>>4),(stamina>>3)+(int(speed)>>5)))*(1.+pushfactor);
			if(bnoextremedeath)critdmg=min(critdmg,hitactor.health+1);
			hitactor.damagemobj(self,target,critdmg,"Piercing",DMG_THRUSTLESS);
			forcepain(hitactor);
			suckingwound=true;
			pen*=2;
			channelwidth*=2;
		}else{
			hitactor.damagemobj(
				self,target,
				chdmg,
				"Piercing",DMG_THRUSTLESS
			);
		}

		//inflict wound
		//note the suckingwound bool
		hdbleedingwound.inflict(hitactor,pen,channelwidth,suckingwound);

		//is there anything else you would like to share
		additionaleffects(hitactor,pen,vu);

		if(hitactor)tracer=hitactor;
		setorigin(hitpos+vu*shortshortpen,true);

		//fragmentation
		if(random(0,100)<woundhealth){
			int fragments=clamp(random(2,(woundhealth>>4)),1,5);
			while(fragments){
				fragments--;
				let bbb=HDBulletActor(spawn("HDBulletActor",pos));
				bbb.target=target;
				bbb.bincombat=true;
				double newspeed;
				speed*=0.8;
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
	virtual void AdditionalEffects(actor hitactor,double pen,vector3 vu){}
	virtual actor Puff(){
		//TODO: virtual actor puff(textureid hittex,bool reverse=false){}
			//flesh: bloodsplat
			//fluids: splash
			//anything else: puff and add bullet hole

		if(max(abs(pos.x),abs(pos.y))>32000)return null;
		double sp=speed;
		name pufftype="BulletPuffBig";
		if(sp>800)pufftype="BulletPuffBig";
		else if(sp>512)pufftype="BulletPuffMedium";
		else pufftype="BulletPuffSmall";
		let aaa=spawn(pufftype,pos);
		aaa.angle=angle;aaa.pitch=pitch;
		return aaa;
	}
}



#include "zscript/bullet_old.zs"

