// ------------------------------------------------------------
// The Bullet!
// ------------------------------------------------------------

class bltest:hdweapon{
	default{hdweapon.refid "blt";}
	states{
	fire:
		TNT1 A 0{
			HDBulletActor.FireBullet(self);
		}goto nope;
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
				||(results.hitactor==shooter&&bullet.getage()<2)
			)return TRACE_Skip;
			int skipsize=bullet.traceactors.size();
			for(int i=0;i<skipsize;i++){
				if(bullet.traceactors[i]==results.hitactor)return TRACE_Skip;
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
		+solid //+noblockmap
		+missile
		+noextremedeath
		height 0.1;radius 0.1;
		/*
			speed: 200-1000
			mass: 500-2000
			pushfactor: 0.05-5.0 - imagine it being horizontal speed blowing in the wind
			accuracy: 0,200,200-700 - angle of outline from perpendicular, round deemed to be 20
			stamina: 900, 776, 426, you get the idea
			hardness: 1-5 - 1=pure lead, 5=steel (NOTE: this setting's bullets are (Teflon-coated) steel by default; will implement lead casts "later")
		*/
		hdbulletactor.distantsounder "none";
		hdbulletactor.hardness 5;
		pushfactor 0.05;
		speed 1100;
		mass 1344;
		accuracy 600;
		stamina 776;


//00
		pushfactor 0.9;
		mass 576;
		speed 700;
		accuracy 200;
		stamina 838;

//zm
		pushfactor 0.4;
		mass 320;
		speed 1200;
		accuracy 666;
		stamina 426;

//9mm
		pushfactor 0.5;
		mass 1539;
		speed 420;
		accuracy 200;
		stamina 900;

//776
		pushfactor 0.05;
		speed 1100;
		mass 1344;
		accuracy 600;
		stamina 776;


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
				+(1000.*accuracy)/stamina
			)
			*(1./50000)
		;
		if(pushfactor>0)pen/=(1.+pushfactor);
console.printf("penetration:  "..pen);
		return pen;
	}
	override bool cancollidewith(actor other,bool passive){
		return !passive;
	}
	virtual void GunSmoke(){}
	static HDBulletActor FireBullet(
		actor caller,
		class<HDBulletActor> type="HDBulletActor",
		double zofs=999
	){
		if(zofs==999)zofs=caller.height-6;
		let bbb=HDBulletActor(spawn(type,(caller.pos.x,caller.pos.y,caller.pos.z+zofs)));
		bbb.target=caller;
		bbb.angle=caller.angle;bbb.pitch=caller.pitch;
		bbb.vel=caller.vel;
		bbb.A_ChangeVelocity(bbb.speed*cos(bbb.pitch),0,bbb.speed*sin(-bbb.pitch),CVF_RELATIVE);
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
		if(!bmissile){
			super.tick();
			return;
		}
		if(vel==(0,0,0))bmissile=false;

		tracelines.clear();
		traceactors.clear();
		tracesectors.clear();

		hdbullettracer blt=HDBulletTracer(new("HDBulletTracer"));
		if(!blt)return;
		blt.bullet=hdbulletactor(self);
		blt.shooter=target;
		vector3 newpos=pos;

		//if in the sky
		if(
			ceilingz<pos.z
			&&ceilingz-pos.z<vel.z
		){
			setorigin(pos+vel,false);
			vel.z-=getgravity();
			return;
		}

		//get speed, set counter
		double distanceleft=vel.length();
		speed=distanceleft;
		do{
			A_FaceMovementDirection();

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
				setorigin(pos+vel,false);
				vel.z-=getgravity();
				return;
			}else if(bres.hittype==TRACE_HitNone){
				newpos=bres.hitpos;
				setorigin(newpos,true);
				distanceleft-=max(bres.distance,0.01); //safeguard against infinite loops
			}else{
				//the decal must be shot out from here to be reliable
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
						||hitline.flags&line.ML_BLOCKING
						||hitline.flags&line.ML_BLOCKHITSCAN
						//||hitline.flags&line.ML_BLOCKPROJECTILE //let's say they go too fast for now
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
						HitGeometry(hitline,othersector,bres.side,999+bres.tier,vu);
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

					HitGeometry(null,hitsector,0,bres.hittype==TRACE_HitCeiling?SECPART_Ceiling:SECPART_Floor,vu);
				}else if(bres.hittype==TRACE_HitActor){
					onhitactor(bres.hitactor,bres.hitpos,vu);
				}
			}


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
		vel.z-=getgravity();
	}
	//when a bullet hits a flat or wall
	//add 999 to "hitpart" to use the tier # instead
	virtual void HitGeometry(line hitline,sector hitsector,int hitside,int hitpart,vector3 vu){
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

		//see if the bullet ricochets
		bool didricochet=false;
			//don't ricochet on meat
			//require much shallower angle for liquids

			//reduce penetration and streamlinedness

		//if impact is too steep, randomly fail to ricochet
		double maxricangle=frandom(50,90)-pen;

		if(hitline){
			//angle of line
			//above plus 180, normalized
			//pick the one closer to the bullet's own angle

			//deflect along the line
			double aaa1=hdmath.angleto(hitline.v1.p,hitline.v2.p);
			double aaa2=aaa1+180;
			double ppp=angle;

			double abs1=absangle(aaa1,ppp);
			double abs2=absangle(aaa2,ppp);
			double hitangle=min(abs1,abs2);

			if(hitangle<maxricangle){
				didricochet=true;
				double aaa=(abs1>abs2)?aaa2:aaa1;
				vel.xy=rotatevector(vel.xy,deltaangle(ppp,aaa)*frandom(1.,1.2));

				//transfer some of the deflection upwards or downwards
				double vlz=vel.z;
				if(vlz){
					double xyl=vel.xy.length()*frandom(0.9,1.1);
					double xyvlz=xyl+vlz;
					vel.z*=xyvlz/xyl;
					vel.xy*=xyl/xyvlz;
				}
			}
		}else if(
			hitpart==SECPART_Floor
			||hitpart==SECPART_Ceiling
		){
			bool isceiling=hitpart==SECPART_CEILING;
			double planepitch=0;

			//get the relative pitch of the surface
			double zdif;
			if(checkmove(pos.xy+vel.xy.unit()*0.5))zdif=getzat(0.5,flags:isceiling?GZF_CEILING:0)-pos.z;
			else zdif=pos.z-getzat(-0.5,flags:isceiling?GZF_CEILING:0);
			if(zdif)planepitch=atan2(zdif,0.5);

			if(isceiling)planepitch-=frandom(0.,10.);
			else planepitch+=frandom(0.,10.);

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
				A_ChangeVelocity(cos(pitch),0,sin(-pitch),CVF_RELATIVE|CVF_REPLACE);
				vel*=speed;
			}
		}

		//see if the bullet penetrates
		if(!didricochet){
			//calculate the penetration distance
			//if that point is in the map:
			vector3 pendest=pos;
			bool dopenetrate=false; //"dope netrate". sounds pleasantly fast.
			for(int i=0;i<pen;i++){
				pendest+=vu;
				if(
					level.ispointinlevel(pendest)
					//performance???
					//&&pendest.z>getzat(pendest.x,pendest.y,0,GZF_ABSOLUTEPOS)
					//&&pendest.z<getzat(pendest.x,pendest.y,0,GZF_CEILING|GZF_ABSOLUTEPOS)
				){
					dopenetrate=true;
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
				}
				//reduce momentum, increase tumbling, etc.
				//reduce remaining distance left
			}else{
				puff();
				bmissile=false;
				setstatelabel("death");
				return;
			}
		}
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
		traceactors.push(hitactor);
		if(!hitactor.bshootable)return;

		double hitangle=absangle(angle,angleto(hitactor)); //0 is dead centre
		double pen=penetration();

		double bff;
		if(hdmobbase(hitactor))bff=hdmobbase(hitactor).bulletfactor();
		else bff=0.6;

		//decelerate
		vel-=vu*pen/max(0.0001,bff);

		pen*=bff;
		//if not deep enough, treat as bashing and ricochet or splat
		bool deepenough=pen>hitactor.radius*frandom(0.06,0.3);

		//deform the bullet
		hardness=max(1,hardness-random(0,random(0,3)));
		stamina+=random(0,(stamina>>1));

		//immediate impact
		//highly random
		double tinyspeedsquared=speed*speed*0.000001;
		double impact=tinyspeedsquared*0.01*mass;

		//bullet hits without penetrating
		//abandon all damage after impact, then check ricochet
		if(!deepenough){
			//if bullet too soft and/or slow, just die
			if(speed<32||hardness<random(1,3)){
				bmissile=false;
				setstatelabel("death");
			}

			//randomly deflect
			//if deflected, reduce impact
			if(
				bmissile
				&&hitangle>10
			){
				double dump=min(1.,0.01*(90-hitangle));
				impact*=dump;
				speed*=(1.-dump);
				angle+=frandom(-45,45);
				pitch+=frandom(-45,45);
				A_ChangeVelocity(cos(pitch),0,sin(-pitch),CVF_RELATIVE|CVF_REPLACE);
			}

			hitactor.damagemobj(self,target,impact,"Bashing",DMG_THRUSTLESS);
			forcepain(hitactor);
			return;
		}

		//bullet penetrated, both impact and temp cavity do bashing
		//if over 10% maxhealth, force pain
		impact+=tinyspeedsquared*frandom(6,16);
		if(speed>HDCONST_SPEEDOFSOUND){
			hitactor.damagemobj(self,target,impact*frandom(0.6,1.6),"Bashing",DMG_THRUSTLESS);
			forcepain(hitactor);
		}

		//check if going right through the body
		//it's not "deep enough", it's "too deep" now!
		deepenough=pen<hitactor.radius*2-frandom(0,0.01*hitangle);

		//determine what kind of blood to use
		class<actor>hitblood;
		if(hitactor.bnoblood)hitblood="FragPuff";else hitblood=hitactor.bloodtype;

		//basic threshold bleeding
		//proportionate to permanent wound channel
		//stamina, pushfactor, hardness
		double channelwidth=
			stamina*0.001
			*frandom(10.,10+pushfactor)
			*(1+frandom(0.,max(0,6-hardness)))
		;
		if(deepenough){
			bmissile=false;
			setstatelabel("death");
		}else{
			channelwidth*=1.1;
			//then spawn exit wound blood
			for(int i=0;i<pen;i+=10){
				bool gbg;actor blood;
				[gbg,blood]=hitactor.A_SpawnItemEx(
					hitblood,
					hitactor.radius*0.6,0,pos.z-hitactor.pos.z,
					angle:hitactor.angleto(self),
					flags:SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
				);
				if(blood)blood.vel=vu*(0.6*pen)
					+(frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.4))
				;
			}
		}
		if(hd_debug)console.printf("wound channel:  "..channelwidth.." x "..pen);

		//major-artery incurable bleeding
		//can't be done on "just" a graze (abs(angle,angleto(hitactor))>50)
		//random chance depending on amount of penetration
		bool suckingwound=frandom(0,pen*2)>hitactor.radius;

		//spawn entry wound blood
		//do more if there's a sucking wound
		for(int i=-1;i<suckingwound;i++){
			bool gbg;actor blood;
			[gbg,blood]=hitactor.A_SpawnItemEx(
				hitblood,
				-hitactor.radius*0.6,0,pos.z-hitactor.pos.z,
				angle:hitactor.angleto(self),
				flags:SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
			);
			if(blood)blood.vel=-vu*(0.03*impact)
				+(frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.4))
			;
		}

		//cns severance
		//small column in middle centre
		//only if NET penetration is at least hitactor.radius
		//add size of channel to damage
		if(
			hitangle<8
			&&hitpos.z-hitactor.pos.z>hitactor.height*0.6
			&&frandom(0,pen*1.2)>hitactor.radius
		){
			if(hd_debug)console.printf("CRIT!");
			hitactor.damagemobj(self,target,random(impact,hitactor.health),"Piercing",DMG_THRUSTLESS);
			forcepain(hitactor);
			suckingwound=true;
		}

		//inflict wound
		//note the suckingwound bool
		hdbleedingwound.inflict(hitactor,channelwidth,pen,suckingwound);
	}
	virtual actor Puff(){
		setstatelabel("death");
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
		if(ticker>0){
			ticker--;
			return;
		}
		if(
			!bleedpoints
			||!bleeder
			||bleeder.health<1
		){
			destroy();
			return;
		}
		bleedpoints--;
		ticker=max(0,BLEED_MAXTICS-bleedrate);
		int bleeds=1;
		int excessbleedrate=bleedrate-BLEED_MAXTICS;
		if(excessbleedrate>0)bleeds+=random(0,excessbleedrate);
		for(int i=0;i<bleeds;i++){
			bleeder.damagemobj(bleeder,null,bleeds,"bleedout",DMG_NO_PAIN);
			if(bleeder.health<1&&bleedrate<random(10,60))bleeder.deathsound="";
			bleeder.A_SpawnItemEx(bleeder.bloodtype,
				frandom(-12,12),frandom(-12,12),
				flags:SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION
			);
		}
	}
	static void inflict(
		actor bleeder,
		int bleedpoints,
		int bleedrate=17,
		bool hitvital=false
	){
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

