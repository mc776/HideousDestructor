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
				||results.hitactor==shooter
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
	double penetration; //more juvenile giggling
	property penetration:penetration;
	array<line> tracelines;
	array<actor> traceactors;
	array<sector> tracesectors;

	int hdbulletflags;
	flagdef neverricochet:hdbulletflags,0;

	default{
		+noblockmap
		+missile
		height 0.1;radius 0.1;
		hdbulletactor.penetration 0;
		speed 128;
	}
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
		TNT1 A 0;
		stop;
	}
	override void tick(){
		if(isfrozen())return;
if(level.time%17)return;
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
			vel.z--;
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
				TRACE_NoSky
			);
			traceresults bres=blt.results;
			sector sectortodamage=null;

console.printf(blt.results.hittype.."  F"..TRACE_HitFloor.."  C"..TRACE_HitCeiling.."  A"..TRACE_HitActor.."  W"..TRACE_HitWall);
spawn("BulletPuff",bres.hitpos);


			if(bres.hittype==TRACE_HitNone){
				newpos=bres.hitpos;
				setorigin(newpos,true);
				distanceleft-=max(bres.distance,0.01); //safeguard against infinite loops
			}else{
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
						||bres.tier==TIER_FFloor //3d floor
						||( //the tier being hit is not sky
							(
								(bres.tier==TIER_Upper)
								&&(othersector.gettexture(othersector.ceiling)!=skyflatnum)
							)||(
								(bres.tier==TIER_Lower)
								&&(othersector.gettexture(othersector.floor)!=skyflatnum)
							)
						)
					);
					//if not blocking, pass through and continue
					if(!isblocking){
						hitline.activate(target,bres.side,SPAC_PCross|SPAC_AnyCross);
						setorigin(newpos+vu*0.2,true);
					}else{
						//"SPAC_Impact" is so wonderfully onomatopoeic
						//would add SPAC_Damage but it doesn't work in 4.1.3???
						hitline.activate(target,bres.side,SPAC_Impact|SPAC_Use);
						HitGeometry(hitline,othersector,bres.side,999+bres.tier);
					}
				}else if(
					bres.hittype==TRACE_HitFloor
					||bres.hittype==TRACE_HitCeiling
				){
console.printf("FC "..bres.hittype);
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

					HitGeometry(null,hitsector,0,bres.hittype==TRACE_HitCeiling?SECPART_Ceiling:SECPART_Floor);
				}else if(bres.hittype==TRACE_HitActor){
					let hitactor=bres.hitactor;
					traceactors.push(hitactor);
					//set up the damage thinker
					//move a little into the actor
					//spawn blood as necessary
					//see if the bullet ricochets
						//just have it fly off in a random direction, we can revisit this later
						//reduce penetration and streamlinedness
					//if not ricochet, see if the bullet penetrates, and if it does:
						//move to the other side of the actor
						//spawn more blood for the exit wound
					//destroy if not ricocheting or penetrating
				}
			}
		}while(distanceleft>0);



		//destroy the linetracer just in case it interferes with savegames
		blt.destroy();

		//update velocity
		vel.z--;
	}
	//when a bullet hits a flat or wall
	//add 999 to "hitpart" to use the tier # instead
	virtual void HitGeometry(line hitline,sector hitsector,int hitside,int hitpart){
		//inflict damage on destructibles
			//GZDoom native first
			int geodmg=100; //placeholder
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
		//"puff"
			//virtual void puff(textureid hittex,bool reverse=false){}
				//flesh: bloodsplat
				//fluids: splash
				//anything else: puff and add bullet hole
		//see if the bullet penetrates:
			//virtual bool checkpenetration(actor hitactor,line hitline,sector hitsector){}
				//if penetration rating is less than zero, just say no
				//"ispointinlevel" loop up to max penetration point (check 3d floor first)
				//http://www.how-i-did-it.org/drywall/ammunition.html
					//note: according to this test, buckshot penetrated everything
					//fast makes this penetrate LESS
					//hardness
					//mass
					//tumbling
				//check pointinmap in a loop up to max penetration point
		//if it DOES penetrate:
			//move to the other side
			//check the texture immediately behind the new position
				//"puff"
				//add a bullet hole
			//reduce penetration and streamlinedness
		//if it does NOT penetrate:
			//ricochet:
				//don't ricochet on meat
				//angle of line
				//above plus 180, normalized
				//pick the one closer to the bullet's own angle
				//if impact is too steep, randomly fail to ricochet
				//reduce penetration and streamlinedness

				if(hitline){
					//deflect along the line
					double aaa1=hdmath.angleto(hitline.v1.p,hitline.v2.p);
					double aaa2=aaa1+180;
					double ppp=angle;
					double aaa=(absangle(aaa1,ppp)>absangle(aaa2,ppp))?aaa2:aaa1;
					vel.xy=rotatevector(vel.xy,deltaangle(ppp,aaa)*frandom(1.,1.2));

					//transfer some of the deflection upwards or downwards
					double vlz=vel.z;
					if(vlz){
						double xyl=vel.xy.length()*frandom(0.9,1.1);
						double xyvlz=xyl+vlz;
						vel.z*=xyvlz/xyl;
						vel.xy*=xyl/xyvlz;
					}
				}else if(
					hitpart==SECPART_Floor
					||hitpart==SECPART_Ceiling
				){
					secplane plaen=hitsector.floorplane;
					if(hitpart==SECPART_CEILING)hitsector.ceilingplane;
					double zdiff=plaen.zatpoint(pos.xy+vel.xy.unit())-plaen.zatpoint(pos.xy);
					double plaenpitch=atan2(zdiff,1.);

					if(hitpart==SECPART_FLOOR)plaenpitch+=frandom(0.,10.);
					else plaenpitch-=frandom(0.,10.);

					if(absangle(-pitch,plaenpitch)>90){
						//bullet ricochets "backward"
						pitch=plaenpitch;
						angle+=180;
					}else{
						//bullet ricochets "forward"
						pitch=-plaenpitch;
					}
					A_ChangeVelocity(cos(pitch),0,sin(-pitch),CVF_RELATIVE|CVF_REPLACE);
					vel*=speed;
console.printf("pp"..plaenpitch.."   v"..speed);
				}


			//set death if not ricochet
	}
	virtual void HitActor(actor hitactor,out vector3 newpos){
	}
}











#include "zscript/bullet_old.zs"

