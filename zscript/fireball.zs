// ------------------------------------------------------------
// Fireball
// a pocket of almost-lighter-than-air hot charged gas,
// held together by magic and capable of propelling itself
// ------------------------------------------------------------

//persistent tail actor that need not be spawned constantly
class HDFireballTail:IdleDummy{
	default{
		+forcexybillboard +rollsprite +rollcenter +bright +noclip
		renderstyle "add";
		speed -0.3;height 1.0;radius 0.6;deathheight 0.7;friction 1.1;
	}
	override void tick(){
		if(isfrozen()){
			clearinterpolation();
			return;
		}
		if(!master){
			destroy();
			return;
		}else if(!master.bmissile){
			A_FadeOut(0.3);
			vel.xy*=0.9;
			vel.z+=0.1;
			setorigin(pos+vel,true);
			return;
		}
		if(alpha<0.3){
			setorigin(master.pos,true);
			clearinterpolation();
			vel=master.vel*speed+(frandom(-0.1,0.1),frandom(-0.1,0.1),frandom(0.5,1));
			alpha=height;
			scale.x=radius;scale.y=radius;
			roll=frandom(0,360);
		}else{
			alpha*=deathheight;
			scale*=friction;
		}
		//nexttic
		if(CheckNoDelay()){
			if(tics>0)tics--;
			while(!tics){
				if(!SetState(CurState.NextState)){
					return;
				}
			}
		}
	}
}

//damage would be balefire, electro, radioactivity or heat/immolation
//missiletype: tail used in A_FBTail()
//activesound: looping sound
class HDFireball:HDActor{
	vector3 oldvel;
	vector3 frac;
	int fracc;
	double seekspeed;
	double zat;
	double grav;
	default{
		+notelestomp
		+missile +seekermissile +noblockmap +dropoff +activateimpact +activatepcross +hittracer
		+forcexybillboard +rollsprite +rollcenter +bright

		renderstyle "add";
		radius 4;height 4;speed 12;gravity 0.05;deathheight 30;
		damagetype "thermal";damagefunction(1);

		seesound "imp/attack";deathsound "imp/shotx";
		activesound "misc/firecrkl";
	}
	override void postbeginplay(){
		super.postbeginplay();
		seekspeed=speed*0.2;
		grav=getgravity();
		fracc=speed/radius;
		frac=vel/fracc;
		A_StartSound(seesound,CHAN_VOICE);
		A_StartSound(activesound,CHAN_BODY,volume:0.4,attenuation:4.);
		corkscrew=0;
	}
	bool A_FBSeek(
		int seekradius=256,
		bool inlosonly=true
	){
		if(!tracer)return false;
		vector3 totracer=(0,0,0);
		if(pos.z>tracer.pos.z+tracer.height*0.6)totracer.z=0;
			else totracer.z=tracer.height*0.6;
		totracer+=tracer.pos-self.pos;
		double disttotracer=distance3d(tracer);
		if(
			(!inlosonly||checksight(tracer))
			&&
			(disttotracer<seekradius)
		){
			vel+=totracer.unit()*seekspeed;
			return true;
		}
		return false;
	}
	void A_FBFloat(
		double jitter=0.02
	){
		if(jitter){
			jitter*=radius;
			vel+=(
				frandom(-jitter,jitter),
				frandom(-jitter,jitter),
				frandom(-jitter,jitter)
			);
		}
		zat=pos.z-floorz;
		if(zat<deathheight&&vel.z<0)vel.z+=(deathheight-zat)*0.06;
	}
	void A_FBTail(){
		if(!missilename) return;
		actor a=spawn(missilename,pos,ALLOW_REPLACE);
		a.master=self;a.vel=self.vel*0.9;
	}
	int corkscrew;
	void A_Corkscrew(double turnspeed=1.,bool clockwise=false,int adjustdegree=45){
		if(!corkscrew)turnspeed*=0.5;
		vector2 turnamt=angletovector(clockwise?corkscrew:-corkscrew,turnspeed);
		A_ChangeVelocity(sin(pitch)*turnamt.y,turnamt.x,cos(pitch)*turnamt.y,CVF_RELATIVE);
		corkscrew+=adjustdegree;if(corkscrew>720)corkscrew-=360;
	}
	override void Tick(){
		if(isfrozen()){
			clearinterpolation();
			return;
		}
		if(!bmissile){
			//I don't anticipate any use other than death state...
			trymove(pos.xy+vel.xy,true);
			if(pos.z<floorz)setz(floorz);
			else if(pos.z+height>ceilingz)setz(ceilingz-height);
			else addz(vel.z,true);
			vel*=0.9;
			//nexttic
			if(CheckNoDelay()){
				if(tics>0)tics--;
				while(!tics){
					if(!SetState(CurState.NextState)){
						return;
					}
				}
			}
			return;
		}
		if(vel.xy==(0,0))A_Recoil(-0.001);

		//update frac
		if(oldvel!=vel){
			oldvel=vel;
			fracc=max(vel.xy.length()/radius,1);
			frac=vel/fracc;
		}

		//the iterator
		for(int i=0;i<fracc;i++){
			fcheckposition tm;

			//hit something while moving horizontally
			if(!trymove(pos.xy+frac.xy,true,true,tm)){
				if(!bSkyExplode){
					let l=tm.ceilingline;
					let p=tm.ceilingpic;
					if(l&&l.backsector){
						if(
							ceilingpic==skyflatnum
							&&tm.ceilingpic==skyflatnum
							&&tm.pos.z>=tm.ceilingz
						){
							destroy();
							return;
						}
					}
				}
				if(!target)target=master;
				explodemissile(BlockingLine,BlockingMobj);
				return;
			}

			if(blockingline&&blockingline.special==Line_Horizon){
				destroy();
				return;
			}

			CheckPortalTransition();
			addz(frac.z,true);

			//check skyfloor first before usual
			if(
				!bSkyExplode
				&& floorpic==skyflatnum
				&& pos.z<floorz
			){
				destroy();
				return;
			}else if(pos.z<floorz){
				setz(floorz);
				hitfloor();
				explodemissile(null,null);
				return;
			}

			//by the time it comes back down it would have dissipated!
			//(this rationalization is subject to change)
			if(
				!bSkyExplode
				&& ceilingpic==skyflatnum
				&& pos.z+height>ceilingz
			){
				destroy();
				return;
			}else if(pos.z+height>ceilingz){
				setz(ceilingz-height);
				explodemissile(null,null);
				return;
			}
		}
		if(grav)vel.z-=grav;
		//nexttic
		if(CheckNoDelay()){
			if(tics>0)tics--;
			while(!tics){
				if(!SetState(CurState.NextState)){
					return;
				}
			}
		}
	}
}


