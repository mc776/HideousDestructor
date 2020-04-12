// ------------------------------------------------------------
// Stuff related to player turning
// ------------------------------------------------------------
extend class HDPlayerPawn{
	vector2 muzzleclimb1;
	vector2 muzzleclimb2;
	vector2 muzzleclimb3;
	vector2 muzzleclimb4;
	vector2 hudbobrecoil1;
	vector2 hudbobrecoil2;
	vector2 hudbobrecoil3;
	vector2 hudbobrecoil4;
	vector2 muzzledrift;
	bool muzzlehit;
	bool totallyblocked;
	bool mousehijacked;
	bool movehijacked;

	enum muzzleblock{
		MB_TOP=1,
		MB_BOTTOM=2,
		MB_LEFT=4,
		MB_RIGHT=8,
	}

	double lastpitch;
	double lastangle;
	void TurnCheck(){
		if(teleported){
			feetangle=angle;
			return;
		}

		//Any changes in this function should only cover those automatic changes
		//that are part of HD's additional adjustments.
		//Anything directly referencing mouse input should go to MovePlayer.
		double anglechange=0;
		double pitchchange=0;
		double vdv=vel dot vel;

		//this is the net result of the above mentioned mouse input,
		//used to measure weapon inertia.
		double lastanglechange=deltaangle(lastangle,angle);
		double lastpitchchange=deltaangle(lastpitch,pitch);


		//get weapon size
		double amt=0;
		double barrellength,barrelwidth,barreldepth;
		bool notnull=false;
		let wp=HDWeapon(player.readyweapon);
		if(wp){
			amt=max(1,wp.gunmass());
			barrellength=wp.barrellength;
			barrelwidth=wp.barrelwidth;
			barreldepth=wp.barreldepth;
			notnull=!(wp is "NullWeapon");
		}

		//better anticipation
		if(vdv>0.25){
			barrelwidth*=clamp(vdv*10,0,2.6);
		}

		//inertia adjustments for other things
		if(stunned){
			amt*=frandom(3,5);
		}else if(countinv("PowerStrength")||countinv("PowerInvulnerable")){
			amt*=0.2;
		}
		if(notnull&&HDWeapon.IsBusy(self)){
			barrellength=radius+2;
			barrelwidth*=2;
			amt=min(amt*1.5,20);
		}


		//muzzle inertia
		//how much to scale movement
		double decelproportion=min(0.042*amt,0.99)*0.7;
		double driftproportion=0.05*amt;


		//apply to weapon
		vector2 apch=(lastanglechange,-lastpitchchange)*0.1*amt;
		if(isFocussing||(wp&&wp.breverseguninertia))apch=-apch;
		hudbobrecoil1+=apch*0.1;
		hudbobrecoil2+=apch*0.2;
		hudbobrecoil3+=apch*0.4;
		hudbobrecoil4+=apch*0.6;
		if(wp){
			if(!wp.bweaponbusy){
				double hdbbx=(hudbobrecoil1.x+hudbob.x)*0.3;
				double hdbby=max(0,(hudbobrecoil1.y+hudbob.y)*0.3);
				A_WeaponOffset(hdbbx,hdbby+WEAPONTOP,WOF_INTERPOLATE);
			}else if(
				player.getpsprite(PSP_WEAPON).y<WEAPONTOP
			){
				A_WeaponOffset(
					player.getpsprite(PSP_WEAPON).x,
					max(player.getpsprite(PSP_WEAPON).y,WEAPONTOP),
					WOF_INTERPOLATE
				);
				bobcounter=69;
			}
		}


		//see if there's any change in velocity overall
		vector3 muzzlevel=lastvel-vel;

		//apply crouch/jump
		double curheight=height;
		muzzlevel.z-=(lastheight-curheight)*0.3;
		lastheight=curheight;

		//determine velocity-based horizontal drift
		//how to tell if it is to left or right?
		//rotate vector so that player is facing east
		//the y value is what we need
		muzzlevel.xy=rotatevector(muzzlevel.xy,-angle);

		muzzledrift+=(muzzlevel.y,muzzlevel.z)*driftproportion;
		if(stunned){
			vector2 muzzleclimbstun=(lastanglechange,lastpitchchange)*frandom(0.1,0.6);
			anglechange+=muzzleclimbstun.x;
			pitchchange+=muzzleclimbstun.y;
			muzzleclimb1+=muzzleclimbstun;
			muzzleclimb2+=muzzleclimbstun;
			muzzleclimb3+=muzzleclimbstun;
		}


		//NOW apply the drift!
		hudbobrecoil1+=muzzledrift;
		muzzledrift*=decelproportion;
		hudbobrecoil2+=muzzledrift;


		//good old jitters!
		//gotta do this after inertia and before collision,
		//to keep this from clipping your gun into the geometry.
		if(
			beatmax<10||
			fatigue>20||
			bloodpressure>20||  
			health<33
		){
			double jitter=0.3;
			if(fatigue)jitter=clamp(0.01*fatigue,0.3,6.);
			if(gunbraced)jitter=0.05;
			else if(health<20)jitter=1;
			hudbobrecoil1+=(frandom(-jitter,jitter),frandom(-jitter,jitter));
			anglechange+=frandom(-jitter,jitter);
			pitchchange+=frandom(-jitter,jitter);
		}


		//muzzle climb - gotta keep this here to make it subject to caps
		pitchchange+=muzzleclimb1.y;
		anglechange+=muzzleclimb1.x;
		muzzleclimb1=muzzleclimb2;
		muzzleclimb2=muzzleclimb3;
		muzzleclimb3=muzzleclimb4;
		muzzleclimb4=(0,0);


		//weapon collision
		if(!(player.cheats&CF_NOCLIP2 || player.cheats&CF_NOCLIP)){
			double highheight=height-HDCONST_CROWNTOEYES;
			double midheight=highheight-max(1,barreldepth)*0.5;
			double lowheight=highheight-max(1,barreldepth);
			double testangle=angle;
			double testpitch=pitch;


			//check for super-collision preventing only aligned sights		
			if(
				!barehanded
				&&linetrace(
					testangle,max(barrellength,HDCONST_MINEYERANGE),testpitch,flags:TRF_NOSKY,
					offsetz:highheight
				)
			){
				nocrosshair=12;
				hudbobrecoil1.y+=10;
				hudbobrecoil2.y+=10;
				hudbobrecoil3.y+=10;
				hudbobrecoil4.y+=10;
				highheight=max(height*0.5,height-HDCONST_CROWNTOSHOULDER);
			}else if(nocrosshair>0)highheight=max(height*0.5,height-HDCONST_CROWNTOSHOULDER);
			barrellength-=(HDCONST_SHOULDERTORADIUS*player.crouchfactor);


			//and now uh do stuff
			vector3 barrelbase=pos+(0,0,midheight);
			actor muzpuf;
			int stuff;
			int muzzleblocked=0;

			double distleft=barrellength;;
			double distright=barrellength;;
			double disttop=barrellength;
			double distbottom=barrellength;

			flinetracedata ltl;
			flinetracedata ltr;
			flinetracedata ltt;
			flinetracedata ltb;


			//top
			linetrace(
				testangle,barrellength,testpitch,flags:TRF_NOSKY,
				offsetz:highheight+cos(pitch)*barreldepth,
				offsetforward:-sin(pitch)*barreldepth,
				offsetside:0,
				data:ltt
			);
			if(
				ltt.hittype==Trace_CrossingPortal
				||(ltt.hitactor&&(
					ltt.hitactor.bnonshootable
					||!ltt.hitactor.bsolid
				))
			)return;
			disttop=ltt.distance;
			if(ltt.distance<barrellength)muzzleblocked|=MB_TOP;

			//bottom
			linetrace(
				testangle,barrellength,testpitch,flags:TRF_NOSKY,
				offsetz:lowheight-cos(pitch)*barreldepth,
				offsetforward:sin(pitch)*barreldepth,
				offsetside:0,
				data:ltb
			);
			if(
				ltb.hittype==Trace_CrossingPortal
				||(ltb.hitactor&&(
					ltb.hitactor.bnonshootable
					||!ltb.hitactor.bsolid
				))
			)return;
			distbottom=ltb.distance;
			if(ltb.distance<barrellength)muzzleblocked|=MB_BOTTOM;


			//left
			linetrace(
				testangle,barrellength,testpitch,flags:TRF_NOSKY,
				offsetz:midheight,
				offsetside:-barrelwidth,
				data:ltl
			);
			if(
				ltl.hittype==Trace_CrossingPortal
				||(ltl.hitactor&&(
					ltl.hitactor.bnonshootable
					||!ltl.hitactor.bsolid
				))
			)return;
			distleft=ltl.distance;
			if(ltl.distance<barrellength)muzzleblocked|=MB_LEFT;

			//right
			linetrace(
				testangle,barrellength,testpitch,flags:TRF_NOSKY,
				offsetz:midheight,
				offsetside:barrelwidth,
				data:ltr
			);
			if(
				ltr.hittype==Trace_CrossingPortal
				||(ltr.hitactor&&(
					ltr.hitactor.bnonshootable
					||!ltr.hitactor.bsolid
				))
			)return;
			distright=ltr.distance;
			if(ltr.distance<barrellength)muzzleblocked|=MB_RIGHT;


			//totally caught
			totallyblocked=muzzleblocked==MB_TOP|MB_BOTTOM|MB_LEFT|MB_RIGHT;


			//set angles
			bool mvng=(lastheight!=height || vdv > 0.25);
			bool hitsnd=(max(abs(anglechange),abs(pitchchange))>1);

//A_Log(string.format("%i %i %i %i",distleft,distright,disttop,distbottom));

			if(notnull){
				if(muzzleblocked&MB_LEFT){
					anglechange=mvng?min(distleft-barrellength,-4):-lastanglechange;
					A_ChangeVelocity(0,-0.05,0,CVF_RELATIVE);
				}
				if(muzzleblocked&MB_RIGHT){
					anglechange=mvng?max(barrellength-distright,4):-lastanglechange;
					A_ChangeVelocity(0,0.05,0,CVF_RELATIVE);
				}

				if(muzzleblocked&MB_BOTTOM){
					pitchchange=mvng?max(distbottom-barrellength,-4):-lastpitchchange;
				}
				if(muzzleblocked&MB_TOP){
					pitchchange=mvng?min(barrellength-disttop,4):-lastpitchchange;
				}
				pitchchange=clamp(pitchchange,-45,45);

				if(totallyblocked){
					vector2 cv=angletovector(pitch,
						clamp(barrellength-disttop,0,barrellength)*0.005);
					A_ChangeVelocity(-cv.x,0,0,CVF_RELATIVE);
				}
			}



			//bump
			if(muzzleblocked>=4){  
				muzzlehit=false;
			}else if(!muzzlehit){
				if(hitsnd)A_StartSound("weapons/guntouch",8,CHANF_OVERLAP,0.6);
				muzzlehit=true;
				gunbraced=true;
			}
		}

//if(abs(anglechange)>45)A_Log(string.format("angle %i",anglechange));
//if(abs(pitchchange)>45)A_Log(string.format("pitch %i",pitchchange));

//if(anglechange)A_Log(string.format("angle %i",anglechange));



		//set everything and update old
		if(anglechange)A_SetAngle(angle+anglechange,SPF_INTERPOLATE);
		if(pitchchange)A_SetPitch(clamp(pitch+pitchchange,player.minpitch,player.maxpitch),SPF_INTERPOLATE);




		//feet angle
		double fac=deltaangle(feetangle,angle);
		if(abs(fac)>(player.crouchfactor<0.7?30:50)){
			vel+=rotatevector((0,fac>0?0.1:-0.1),angle);  
			A_GiveInventory("IsMoving",2);
			feetangle=angle;
			PlayRunning();

			//if on appropriate terrain, easier to quench a fire
			if(player.crouchfactor<0.7){
				int douse=3;
				//the below is equivalent to "if(CheckLiquidTexture())douse=6;"
				//replicated because of the virtual subfunction processing problem
				int lqlength=lq.size();
				for(int i=0;i<lqlength;i++){
					TextureID tx=TexMan.CheckForTexture(lq[i],TexMan.Type_Flat);
					if (tx && floorpic==tx)douse=5;
				}
				A_GiveInventory("HDFireDouse",douse);
			}
		}

		//move pivot point a little behind the player's view
		anglechange=deltaangle(angle,lastangle);
		if(
			!teleported
			&&!incapacitated
			&&player.onground
			&&floorz==pos.z
		){
			bool ongun=gunbraced&&!barehanded&&isFocussing;
			if(abs(anglechange)>(ongun?0.05:0.7)){
				int dir=90;
				if(
					(!ongun&&anglechange<0)
					||(ongun&&anglechange>0)
				)dir=-90;
				trymove(self.pos.xy-(cos(angle+dir),sin(angle+dir))*(ongun?0.3:0.6),false);
			}
			double ptchch=clamp(abs(pitchchange),0,10); //THE CLAMP IS A BANDAID
			if(ptchch>1 && -30<pitch<30){  
				trymove(pos.xy-(cos(angle)*ptchch,sin(angle)*ptchch)*0.1,false);
				PlayRunning();
			}
		}
	}



	//seeing if you're standing on a liquid texture
	static const string lq[]={
		"MFLR8_4","MFLR8_2",
		"SFLR6_1","SFLR6_4",
		"SFLR7_1","SFLR7_4",
		"FWATER1","FWATER2","FWATER3","FWATER4",
		"BLOOD1","BLOOD2","BLOOD3",
		"SLIME1","SLIME2","SLIME3","SLIME4",
		"SLIME5","SLIME6","SLIME7","SLIME8"
	};
	bool CheckLiquidTexture(){
		int lqlength=lq.size();
		let fp=floorpic;
		for(int i=0;i<lqlength;i++){
			TextureID tx=TexMan.CheckForTexture(lq[i],TexMan.Type_Flat);
			if (tx&&fp==tx){
				return true;
			}
		}
		return false;
	}

	//Muzzle climb!
	void A_MuzzleClimb(vector2 mc1,vector2 mc2,vector2 mc3,vector2 mc4,bool wepdot=false){
		double mult=1.;
		if(gunbraced)mult=0.2;
		else if(countinv("IsMoving"))mult=1.6;
		if(stunned)mult*=1.6;
		if(mult){
			mc1*=mult;
			mc2*=mult;
			mc3*=mult;
			mc4*=mult;
		}
		muzzleclimb1+=mc1;
		muzzleclimb2+=mc2;
		muzzleclimb3+=mc3;
		muzzleclimb4+=mc4;
		if(wepdot){
			hudbobrecoil1+=(mc1.x,mc1.y*2)*mult;
			hudbobrecoil2+=(mc2.x,mc2.y*2)*mult;
			hudbobrecoil3+=(mc3.x,mc3.y*2)*mult;
			hudbobrecoil4+=(mc4.x,mc4.y*2)*mult;
		}
	}
}


