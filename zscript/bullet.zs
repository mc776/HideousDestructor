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
			HDBulletActor.FireBullet(self,"HDB_9");
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
		TNT1 AAAAAAA 0{
			let bbb=HDBulletActor.FireBullet(self,"HDB_00",spread:6);
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
		hdbulletactor.hardness 2;
	}
}
class HDB_776:HDBulletActor{
	default{
		pushfactor 0.05;
		mass 160;
		speed 1100;
		accuracy 600;
		stamina 776;
	}
}
class HDB_9:HDBulletActor{
	default{
		pushfactor 0.5;
		mass 86;
		speed 420;
		accuracy 200;
		stamina 900;
		hdbulletactor.hardness 3;
	}
}
class HDB_355:HDBulletActor{
	default{
		pushfactor 0.4;
		mass 83;
		speed 440;
		accuracy 200;
		stamina 900;
	}
}
class HDB_00:HDBulletActor{
	default{
		pushfactor 0.6;
		mass 32;
		speed 700;
		accuracy 200;
		stamina 838;
	}
}
class HDB_frag:HDBulletActor{
	default{
		pushfactor 0.8;
		mass 30;
		speed 700;
		accuracy 200;
		stamina 800;
	}
	override void gunsmoke(){}
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
				||(results.hitactor==shooter&&bullet.getage()<2)
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
class HDBulletActor:Actor{
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
		super.postbeginplay();
		gunsmoke();
		if(distantsounder!="none"){
			actor m=spawn(distantsounder,pos,ALLOW_REPLACE);
			m.target=target;
		}
	}
	double penetration(){ //still juvenile giggling
		double pen=
			clamp(speed,0,hardness*200)
			*(
				mass
				+(100.*accuracy)/stamina
			)
			*(1./4000)
		;
		if(pushfactor>0)pen/=(1.+pushfactor);
if(hd_debug)console.printf("penetration:  "..pen.."   "..pos.x..","..pos.y);
		return pen;
	}
	override bool cancollidewith(actor other,bool passive){
		return !passive;
	}
	static HDBulletActor FireBullet(
		actor caller,
		class<HDBulletActor> type="HDBulletActor",
		double zofs=999, //default: height-6
		double spread=0, //range of random velocity added
		double aimoffx=0,
		double aimoffy=0
	){
		if(zofs==999)zofs=caller.height-6;
		let bbb=HDBulletActor(spawn(type,(caller.pos.x,caller.pos.y,caller.pos.z+zofs)));
		bbb.target=caller;
		bbb.traceactors.push(caller);

		if(hdplayerpawn(caller)){
			let hdpc=hdplayerpawn(caller).scopecamera;
			if(hdpc){
				aimoffx+=hdpc.angle;
				aimoffy+=hdpc.pitch;
			}else{
				let hdp=hdplayerpawn(caller);
				aimoffx+=hdp.angle;
				aimoffy+=hdp.pitch;
			}
		}else{
			aimoffx+=caller.angle;
			aimoffy+=caller.pitch;
		}
		bbb.angle=aimoffx;
		bbb.pitch=aimoffy;

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
		if(vel==(0,0,0))bmissile=false;
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
			setxyz(pos+vel);
			vel-=vel.unit()*pushfactor;
			vel.z-=getgravity();
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

			if(bres.hittype==TRACE_HasHitSky){
				setxyz(pos+vel);
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
						//||bres.tier==TIER_FFloor //3d floor - does not work as of 4.1.3
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
						hitline.activate(target,bres.side,SPAC_Impact|SPAC_Use);
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
					traceactors.push(bres.hitactor);
					onhitactor(bres.hitactor,bres.hitpos,vu);
				}
			}
			iterations++;


			//find points close to players and spawn crackers
			//also spawn trails if applicable
			if(speed>256){
				name cracker="";
				if(speed>1000){
					if(mass>200) cracker="SupersonicTrailBig";
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
			frandom(-pushfactor,0),
			frandom(-pushfactor,pushfactor),
			frandom(-pushfactor,pushfactor)-1,
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

		//inflict damage on destructibles
		//GZDoom native first
		int geodmg=int(pen*(1+pushfactor));
		if(hitline)destructible.DamageLinedef(hitline,self,geodmg,"SmallArms2",hitpart,pos,false);
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
		stamina=stamina+random(0,(stamina>>1));
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
		double deemedwidth=hitactor.radius*frandom(0.9,1.);//10.+hitactor.radius*frandom(0.08,0.1);
		deemedwidth*=2;


		//decelerate
		let hdmb=hdmobbase(hitactor);
		double hitactorresistance=hdmb?hdmb.bulletresistance(hitangle):0.6;
		double penshell=max(
			hdmb?hdmb.bulletshell(hitpos,hitangle):0,
			hitactorresistance*deemedwidth*0.03
		);
		double shortpen=pen-penshell;
		vel*=shortpen/pen;
		pen=shortpen;

		bool deepenough=pen>deemedwidth*0.04;

		//deform the bullet
		hardness=max(1,hardness-random(0,random(0,3)));
		stamina=stamina+random(0,(stamina>>1));

		//immediate impact
		//highly random
		double tinyspeedsquared=speed*speed*0.000001;
		double impact=tinyspeedsquared*0.1*mass;

		//bullet hits without penetrating
		//abandon all damage after impact, then check ricochet
		if(!deepenough){
			//if bullet too soft and/or slow, just die
			if(speed<32||hardness<random(1,3))bulletdie();

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

			hitactor.damagemobj(self,target,impact,"Bashing",DMG_THRUSTLESS);
			if(impact>(hitactor.health>>3))forcepain(hitactor);
			return;
		}

		//bullet penetrated, both impact and temp cavity do bashing
		//if over 10% maxhealth, force pain
		impact+=tinyspeedsquared*frandom(0.03,0.08)*stamina;
		if(speed>HDCONST_SPEEDOFSOUND){
			hitactor.damagemobj(self,target,max(random(1,5),impact),"Bashing",DMG_THRUSTLESS);
			forcepain(hitactor);
		}else hitactor.damagemobj(self,target,max(1,impact),"Bashing",DMG_THRUSTLESS);

		//check if going right through the body
		//it's not "deep enough", it's "too deep" now!
		deepenough=pen<deemedwidth-0.02*hitangle;

		//determine what kind of blood to use
		class<actor>hitblood;
		if(hitactor.bnoblood)hitblood="FragPuff";else hitblood=hitactor.bloodtype;

		//basic threshold bleeding
		//proportionate to permanent wound channel
		//stamina, pushfactor, hardness
		double channelwidth=
			stamina
			*(
				//if it doesn't bleed, it's probably rigid
				(
					hdmobbase(hitactor)
					&&hdmobbase(hitactor).bdoesntbleed
				)?0.0002:0.0001
			)
			*frandom(10.,10+pushfactor)
			*(1+frandom(0.,max(0,6-hardness)))
		;
		if(deepenough)bulletdie();
		else{
			channelwidth*=1.1;
			//then spawn exit wound blood
			if(!bbloodlessimpact){
				for(int i=0;i<pen;i+=10){
					bool gbg;actor blood;
					[gbg,blood]=hitactor.A_SpawnItemEx(
						hitblood,
						hitactor.radius*0.6,0,pos.z-hitactor.pos.z,
						angle:hitactor.angleto(self),
						flags:SXF_ABSOLUTEANGLE|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
					);
					if(blood)blood.vel=vu*(0.6*min(pen*0.2,12))
						+(frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.4))
					;
				}
			}
			//reduce momentum, increase tumbling, etc.
			double totalresistance=hitactorresistance*deemedwidth;
			angle+=frandom(-pushfactor,pushfactor)*totalresistance;
			pitch+=frandom(-pushfactor,pushfactor)*totalresistance;
			speed=max(0,speed-frandom(-pushfactor,pushfactor)*totalresistance*10);
			A_ChangeVelocity(cos(pitch)*speed,0,-sin(pitch)*speed,CVF_RELATIVE|CVF_REPLACE);
		}
		if(hd_debug)console.printf("wound channel:  "..channelwidth.." x "..pen);

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
					angle:hitactor.angleto(self),
						flags:SXF_ABSOLUTEANGLE|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
				);
				if(blood)blood.vel=-vu*(0.03*impact)
					+(frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.4))
				;
			}
		}

		//add size of channel to damage
		int chdmg=int(channelwidth*pen)>>5;
if(hd_debug)console.printf("channel HP damage: "..chdmg);
		bnoextremedeath=(chdmg<<2)<getdefaultbytype(hitactor.getclass()).health;

		//cns severance
		//small column in middle centre
		//only if NET penetration is at least deemedwidth
		if(
			hitangle<12
			&&hitpos.z-hitactor.pos.z>hitactor.height*0.6
			&&pen*frandom(1.,1.5)>deemedwidth
		){
			if(hd_debug)console.printf("CRIT!");
			hitactor.damagemobj(
				self,target,
				chdmg+random(0,hitactor.health),
				"Piercing",DMG_THRUSTLESS
			);
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

		setorigin(hitpos+vu*shortpen,true);
	}
	virtual void AdditionalEffects(actor hitactor,double pen,vector3 vu){}
	virtual actor Puff(){
		//TODO: virtual actor puff(textureid hittex,bool reverse=false){}
			//flesh: bloodsplat
			//fluids: splash
			//anything else: puff and add bullet hole
		let aaa=spawn("FragPuff",pos,ALLOW_REPLACE);
		aaa.pitch=pitch;aaa.angle=angle;
		return aaa;
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
			bleeder.A_SpawnItemEx(bleeder.bloodtype,
				frandom(-12,12),frandom(-12,12),
				flags:SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
			);
		}while(bleeds>0);
		int bled=bleeder.damagemobj(bleeder,null,bleedrate,"bleedout",DMG_NO_PAIN|DMG_THRUSTLESS);
		if(bled<1){
			destroy();
			return;
		}
		if(bleeder&&bleeder.health<1&&bleedrate<random(10,60))bleeder.deathsound="";
		if(hd_debug&&bleeder)console.printf(bleeder.getclassname().." bled to "..bleeder.health);
	}
	static void inflict(
		actor bleeder,
		int bleedpoints,
		int bleedrate=17,
		bool hitvital=false
	){
		//TODO: proper array of wounds for the player
		if(hdplayerpawn(bleeder)){
			hdplayerpawn(bleeder).woundcount+=bleedpoints;
			return;
		}

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

		let wwnd=new("HDBleedingWound");
		wwnd.bleeder=bleeder;
		wwnd.ticker=0;
		wwnd.bleedrate=bleedrate;
		if(hitvital)wwnd.bleedpoints=-1;
		else wwnd.bleedpoints=bleedpoints;
	}
}




#include "zscript/bullet_old.zs"

