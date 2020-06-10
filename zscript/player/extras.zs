// ------------------------------------------------------------
// Additional player functions
// ------------------------------------------------------------
class PlayerAntenna:HDActor{
	default{
		radius 3;
		height 2;
	}
}
extend class HDPlayerPawn{
	actor antenna;
	void A_MoveAntenna(vector3 newpos){
		if(!antenna)antenna=spawn("PlayerAntenna",newpos,ALLOW_REPLACE);
		else antenna.setorigin(newpos,false);
	}

	//check mantling
	//returns: -1 cannot mantle; 0 cannot mantle but on ground; 1 can mantle
	int MantleCheck(){
		bool onground=player.onground;
		int res=onground?0:-1;

		//determine max height
		int mantlemax=36;
		if(
			!mustwalk
			&&barehanded
			&&(
				zerk||
				stimcount>10||
				fatigue<HDCONST_SPRINTFATIGUE
			)
		){
			if(zerk>0||onground)mantlemax=64;
			else mantlemax=56;
		}
		//place the antenna
		A_MoveAntenna(pos+vel+((cos(angle),sin(angle))*(radius+1),mantlemax));

		//check if blocked
		bool checkmovesuccessful=false;
		bool checkmoveunsuccessful=false;
		int mmfinal=mantlemax;
		for(int i=0;i<mantlemax;i++){
			antenna.addz(-1);
			if(
				antenna.checkmove(antenna.pos.xy)
			){
				checkmovesuccessful=true;
			}else if(
				mmfinal>maxstepheight
				&&checkmovesuccessful //must always end with a checkmoveunsuccessful after a successful
			){
				checkmoveunsuccessful=true;
				break;
			}
			mmfinal--;
		}
		if(!checkmovesuccessful||!checkmoveunsuccessful)return res;

		//thrust player upwards and forwards
		if(
			onground
			&&!(oldinput & BT_JUMP)
		){
			if(
				zerk<1
				&&fatigue>HDCONST_SPRINTFATIGUE
			)vel.z+=4;
			else vel.z+=7;
			fatigue+=random(1,2);
		}else{
			double pdif=zerk>0?5.:((antenna.floorz-pos.z)*0.03);
			if(pdif>0)vel.z+=pdif;
			vel.z+=getgravity();
		}
		return 1;
	}
	double jumppower(){
		double jumppower=5;
		if(zerk>0)jumppower=10;else{
			if(fatigue>30) jumppower=3;
			else if(fatigue>20) jumppower=3.5;
		}
		if(overloaded)jumppower/=max(1,overloaded);
		if(countinv("WornRadSuit"))jumppower*=0.7;
		return jumppower;
	}
	//and jump. don't separate from mantling.
	override void CheckJump(){}
	virtual void JumpCheck(double fm,double sm,bool forceslide=false){
		if(
			!forceslide
			&&player.cmd.buttons&BT_JUMP
		){
			if(player.crouchoffset){
				// Jumping while crouching will force an un-crouch but not jump
				player.crouching=1;
			}
			else if(waterlevel>=2){
				vel.z=4*speed;
			}
			else if(bnogravity){
				vel.z=3;
			}
			else if(
				(
					fatigue<HDCONST_SPRINTFATIGUE
					||zerk
					||cansprint
				)
				&&!MantleCheck()
				&&!stunned
				&&!(oldinput & BT_JUMP)
			){
				double jumppower=jumppower();
				double jz=jumppower*0.65;
				if(!sm){
					if(!fm)vel.z+=jumppower*1.3; //straight up vertical leap
					else if(fm>0){ //forwards
						jumppower*=1.5;
						A_ChangeVelocity(jumppower,0,jz,CVF_RELATIVE);
					}else{ //backwards
						A_ChangeVelocity(-jumppower,0,jz,CVF_RELATIVE);
					}
				}else if(!fm){ //side jump
					if(sm>0) jumppower*=-1;
					stunned+=10;
					A_ChangeVelocity(0,jumppower,jz,CVF_RELATIVE);
				}else{ //diagonal jump
					int smult=1;
					int fmult=1;
					if(fm<0) fmult=-1;
					if(sm>0) smult=-1;
					jumppower*=HDCONST_ONEOVERSQRTTWO;
					stunned+=10;
					A_ChangeVelocity(jumppower*fmult,jumppower*smult,jz,CVF_RELATIVE);
				}
				if(height<40){
					if(bloodpressure<40)bloodpressure+=7;
					fatigue+=7;
				}
				else{
					if(bloodpressure<40)bloodpressure+=4;
					fatigue+=4;
				}
			}
		}
		//slides, too!
		else if(
			forceslide||(
				(fm||sm)
				&&floorz==pos.z
				&&player.crouchdir<0&&height>46
				&&countinv("IsMoving")>1
				&&(
					runwalksprint>0
					||!hd_noslide.getbool()
				)
			)
		){
			double mm=jumppower()*1.5;
			double fmm=fm>0?mm:fm<0?-mm*0.6:0;
			double smm=sm>0?-mm:sm<0?mm:0;
			A_ChangeVelocity(fmm,smm,-0.6,CVF_RELATIVE);
			if(bloodpressure<40)bloodpressure+=2;
			fatigue++;
			stunned+=30;
			smm*=-0.3;
			if(fmm<0)A_MuzzleClimb((smm*1.2,-5.2),(smm,-4.),(smm,-2.),(smm*0.8,-1.));
			else if(fmm>0){
				A_MuzzleClimb((smm*1.2,7.2),(smm,4.),(smm,2.),(smm*0.8,1.));
				totallyblocked=true;
			}
		}
	}


	//all use button stuff other than normal using should go here
	virtual void UseButtonCheck(int input){
		if(corpsekicktimer>0)corpsekicktimer--;
		if(!(input&BT_USE)){
			bpickup=false;
			return;
		}
		if(oldinput&BT_ATTACK)hasgrabbed=true;
		else if(!(oldinput&BT_USE))hasgrabbed=false;

		//check here because we still need the above pickup checks when incap'd
		if(incapacitated)return;

		//door kicking
		if(
			input&BT_SPEED
			&&input&BT_ZOOM
			&&!corpsekicktimer
			&&player.crouchfactor>0.8
			&&linetrace(angle,42,pitch,flags:TRF_THRUACTORS,offsetz:height*0.4)
		){
			hasgrabbed=true;
			corpsekicktimer=20+(unstablewoundcount>>1);
			stunned+=25;
			bool zk=zerk>0;
			double kickback=zk?1:4;
			bool db=doordestroyer.destroydoor(self,frandom(32,zk?196:72),frandom(0,frandom(1,zk?48:16)),ofsz:24);
			if(!random(0,db?7:3)){
				corpsekicktimer+=20;
				damagemobj(self,self,random(1,5),"Bashing");
				stunned+=70;
				kickback*=frandom(1,2);
				A_MuzzleClimb((frandom(-1,1),4),(frandom(-1,1),-1),(frandom(-1,1),-1),(frandom(-1,1),-1));
			}
			if(!random(0,db?3:6))woundcount++;
			A_MuzzleClimb((0,-1),(0,-1),(0,-1),(0,-1));
			A_ChangeVelocity(-kickback,0,0,CVF_RELATIVE);
			A_StartSound("*fist",CHAN_BODY,CHANF_OVERLAP);
			LineAttack(angle,48,pitch,0,"none",
				zk?"BulletPuffBig":"BulletPuffMedium",
				flags:LAF_OVERRIDEZ,
				offsetz:height*0.3
			);
		}

		bpickup=!hasgrabbed;
		PickupGrabber();

		//corpse kicking
		if(
			!corpsekicktimer
			&&floorz==pos.z
			&&height>45
			&&beatmax>10
		){
			bool kicked=false;
			actor k=spawn("kickchecker",pos,ALLOW_REPLACE);
			k.angle=angle;k.target=self;
			vector2 kv=AngleToVector(angle,5);
			for(int i=7;i;i--){
				if(!k.TryMove(k.pos.xy+kv,true) && k.blockingmobj){
					hasgrabbed=true;
					let kbmo=k.blockingmobj;
					double kbmolowerby=pos.z-kbmo.pos.z;
					if(
						kbmolowerby>4
						||kbmolowerby<-16
					)continue;
					if(
						kbmo.bcorpse
						||kbmo is "HDFragGrenade"
						||kbmo is "HDFragGrenadeRoller"
					){
						if(!(oldinput&BT_USE)){
							int forc=80;if(zerk>0)forc*=3;
							corpsekicktimer=20+(unstablewoundcount>>1);
							kbmo.vel+=(kv.x,kv.y,4)*forc/kbmo.mass;
							kbmo.A_StartSound("misc/punch",CHAN_BODY,CHANF_OVERLAP);
							kbmo.A_DropInventory("HDArmourWorn");
							kicked=true;
						}
					}else if(
						kbmo.bismonster
						||(
							kbmo.player
							&&!isteammate(kbmo)
						)
					){
						corpsekicktimer=17+(unstablewoundcount>>1);
						kicked=true;
						HDFist.kick(self,kbmo,k);
					}else{
						double forc=0.4;if(zerk>0)forc=1.2;
						corpsekicktimer=20+unstablewoundcount*3/5;
						vel-=(kv.x,kv.y,4)*forc;
						kbmo.A_StartSound("misc/punch",CHAN_BODY,CHANF_OVERLAP);
						kicked=true;
					}
					break;
				}
			}
			if(kicked){
				fatigue++;bloodpressure++;stunned+=2;
			}
			if(k)k.destroy();
		}
	}
}



extend class HDHandlers{
	static void FindRange(hdplayerpawn ppp){
		flinetracedata frt;
		ppp.linetrace(
			ppp.angle,65536,ppp.pitch,flags:TRF_NOSKY,
			offsetz:ppp.height-6,
			data:frt
		);
		double c=frt.distance;
		double b=c/HDCONST_ONEMETRE;
		ppp.A_Log(string.format("\cd[\cuRF\cd]\cj \cf%.2f\cj metre%s",b,b==1?"":"s"),true);
		if(hd_debug)ppp.A_Log(string.format("("..(ppp.player?ppp.player.getusername():"something").." measured %.2f DU%s)",c,c==1?"":"s"),true);
	}
	void Taunt(hdplayerpawn ppp){
		ppp.A_StartSound(ppp.tauntsound,CHAN_VOICE);
		ppp.A_TakeInventory("powerfrightener");
		ppp.A_SpawnItemEx("DelayedTaunter",12,0,ppp.height-6,
			flags:SXF_NOCHECKPOSITION|SXF_SETTARGET
		);
		if(ppp.findinventory("HDBlurSphere"))
			HDBlursphere(ppp.findinventory("HDBlurSphere")).intensity=-200;
	}
	void ClearWeaponSpecial(hdplayerpawn ppp){
		if(!ppp.player)return;
		let www=hdweapon(ppp.player.readyweapon);
		if(www)www.special=0;
	}
}
class DelayedTaunter:IdleDummy{
	states{
	spawn:
		TNT1 A 18;
		TNT1 A 0 A_AlertMonsters();
		stop;
	}
}


