// ------------------------------------------------------------
// HD's modified FastProjectile
// Because "fast" means something else entirely
// For reference, the rocket can go up to just under 400
// ------------------------------------------------------------
class SlowProjectile:HDActor{
	/*
		special usages:
		woundhealth: extra damage other than raw impact.
	*/
	double divrad;
	double distancetravelled;
	int airburst;
	bool primed;
	double skyz;


	double grav;
	bool inthesky;
	vector3 skypos;

	default{
		projectile; -nogravity
		+noextremedeath +cannotpush +hittracer +forcexybillboard
		+bloodlessimpact -noteleport +forcexybillboard
		+notelestomp

		radius 1.;height 1.;
		missileheight 8; projectilekickback 20; damagetype "Bashing";
		speed 18;

//		missiletype "BulletTail"; //testing and random eye candy
	}
	override void PostBeginPlay(){
		HDActor.PostBeginPlay();
		grav=getgravity();
		LongArmWobble();
		Gunsmoke();
		divrad=radius*1.9;
		if(target)master=target;
		distancetravelled=0;
	}
	void LongArmWobble(){
		let hdp=hdplayerpawn(target);
		if(hdp&&hdp.scopecamera){
			pitch+=deltaangle(hdp.pitch,hdp.scopecamera.pitch);
			angle+=deltaangle(hdp.angle,hdp.scopecamera.angle);
		}else if(countinv("IsMoving",AAPTR_TARGET)>=10){
			pitch+=frandom(-2,2);
			angle+=frandom(-1,1);
		}
	}
	virtual void Gunsmoke(){
		actor gs;
		double j=cos(pitch);
		vector3 vk=(j*cos(angle),j*sin(angle),-sin(pitch));
		j=max(1,speed*min(mass,100)*0.00001);
		for(int i=0;i<j;i++){
			gs=spawn("HDGunSmoke",pos+i*vk,ALLOW_REPLACE);
			gs.pitch=pitch;gs.angle=angle;gs.vel=vk*j;
		}
	}
	override void Tick(){
		if(isfrozen())return;
		if(!bmissile){
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
		if(inthesky){
			setorigin(pos+(vel.xy,0),true);
			if(max(abs(pos.x),abs(pos.y))>=32768){destroy();return;}
			skyz+=vel.z;
			vel.z-=grav;
			if(ceilingz>skyz){
				if(ceilingpic!=skyflatnum){
					destroy();return;
				}
				inthesky=false;
				binvisible=false;
				if(skyz<floorz)setz(ceilingz-0.1);
				else setz(skyz);
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
			return;
		}

		//point actor in velocity
		if(hd_debug && speed>600)A_Log(String.Format("%s is over speed 600. Consider using HDBullet for this.",getclassname()));

		// force some lateral movement so that collision detection works as intended.
		if(vel.xy==(0,0))vel.xy=angletovector(angle,0.01);

		// Handle movement
		fcheckposition tm;
		speed=vel.length();
		vector3 posbak=pos;

		int count=max(2,speed*divrad);
		vector3 frac=vel/count;
		double speedfrac=speed/count;
		for(int i=0;i<count;i++){
			if(!TryMove(pos.xy+frac.xy,true,true,tm)){

				//hack to prevent exploding on lower sky
				let l=tm.ceilingline;
				let p=tm.ceilingpic;
				if(l&&l.backsector){
					if(
						tm.ceilingpic==skyflatnum
						&&tm.pos.z>=tm.ceilingz
					){
						destroy();
						return;
					}
				}

				//[RH] Don't explode on horizon lines.
				if(BlockingLine && BlockingLine.special == Line_Horizon){
					destroy();
					return;
				}

				//upon hitting an actor
				if(!target)target=master;
				if(blockingmobj){
					tracer=blockingmobj;
					int idmg=speed*speed*mass*0.000005;
					if(idmg>40)tracer.A_StartSound("misc/bulletflesh",CHAN_AUTO);
					if(hd_debug)A_Log(String.Format("%s hit %s",getclassname(),blockingmobj.getclassname()));
					if(!bnodamage)tracer.damagemobj(self,target,idmg,"bashing");
				}
				explodeslowmissile(blockingline,blockingmobj);
				return;
			}
			CheckPortalTransition();

			addz(frac.z,true);
			UpdateWaterLevel();

			//hit the floor
			if(pos.z<=floorz){
				if(floorpic==skyflatnum){
					destroy();return;
				}
				setz(floorz);
				hitfloor();
				explodeslowmissile(null,null);
				return;
			}
			//hit the ceiling or sky
			else if(pos.z+height>ceilingz){
				if(ceilingpic!=skyflatnum){
					setz(ceilingz-height);
					explodeslowmissile(null,null);
					return;
				}else{
					if(grav<=0){destroy();return;} //it's not coming back down
					inthesky=true;
					binvisible=true;
					setorigin(posbak+vel,true);
					vel.z-=grav;
					skyz=pos.z;
					return;
				}
			}else{
				inthesky=false;
				binvisible=false;
			}

			if(speed && !inthesky
				&& bmissile && missilename && speed*radius>=240
			){
				actor tr=spawn(missilename,pos,ALLOW_REPLACE);
				tr.vel=vel*0.4;
			}

			//track distance travelled
			distancetravelled+=speedfrac;
			if(airburst&&distancetravelled>airburst){
				primed=true;
				ExplodeSlowMissile();
				return;
			}
		}
		//bullet drop again, updating the actual velocity
		vel.z-=grav;

		//thus ends the "handle movement" part

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
	virtual void ExplodeSlowMissile(line blockingline=null,actor blockingobject=null){
		if(max(abs(pos.x),abs(pos.y))>=32768){destroy();return;}
		actor a=spawn("IdleDummy",pos,ALLOW_REPLACE);
		a.stamina=10;
		a.A_StartSound(speed>50?"misc/punch":"misc/fragknock",CHAN_AUTO);
		explodemissile(blockingline,null);
	}
	states{
	spawn:
		BAL1 A 1 nodelay;
		BAL1 A -1{
			//so that you can kill yourself by shooting into the sky
			if(target && !master) master=target;target=null;
		}
	death:
		TNT1 A 4{
			bnointeraction=true;
			bmissile=false;
		}stop;
	}
}
class BulletTail:IdleDummy{
	default{
		scale 0.5; renderstyle "add"; alpha 0.3; +forcexybillboard;
	}
	states{
	spawn:
		BAL7 A 10 A_FadeOut(0.1);
		wait;
	}
}
