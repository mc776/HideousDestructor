// ------------------------------------------------------------
// The player!
// ------------------------------------------------------------
const HDCONST_SPRINTMAXHEARTRATE=20;
const HDCONST_SPRINTFATIGUE=30;
const HDCONST_WALKFATIGUE=40;
const HDCONST_DAMAGEFATIGUE=80;
const HDCONST_PLAYERHEIGHT=54;
class HDPlayerPawn:PlayerPawn{
	vector3 lastpos;vector3 lastvel;double lastheight;
	bool teleported;

	int oldinput;
	double oldfm;double oldsm;

	actor playercorpse;
	actor scopecamera;

	hdweapon lastweapon;
	bool barehanded;
	bool gunbraced;
	
	double overloaded;

	bool mustwalk;bool cansprint;
	int runwalksprint;

	double feetangle;

	int stunned;
	int fatigue;
	int nocrosshair;
	double recoilfov;

	int armourlevel;

	bool hasgrabbed;
	int corpsekicktimer;
	bool isFocussing;

	bool flip;

	string wephelptext;

	double bobcounter;
	vector2 hudbob;

	string classloadout;
	property loadout:classloadout;

	default{
		+interpolateangles
		telefogsourcetype "";
		telefogdesttype "";

		-playerpawn.nothrustwheninvul
		-pickup
		+forceybillboard //zoom actor will fuck up otherwise

		+nomenu
		+noskin

		height HDCONST_PLAYERHEIGHT;radius 12;
		mass 150;gibhealth 180;
		deathheight 24;

		player.viewheight 48;
		player.attackzoffset 21;
		player.damagescreencolor "12 06 04";
		player.jumpz 0;
		player.colorrange 112,127;
		maxstepheight 24;
		player.gruntspeed 99999999999.0;
		player.displayname "Operator";
		player.crouchsprite "PLYC";

		hdplayerpawn.loadout "";
		hdplayerpawn.maxpocketspace HDCONST_MAXPOCKETSPACE;
		player.startitem "CustomLoadoutGiver";
	}
	override bool cancollidewith(actor other,bool passive){
		return(
			!player
			||other.floorz==other.pos.z
			||!hdfist(player.readyweapon)
			||hdfist(player.readyweapon).grabbed!=other
		);
	}
	override void PostBeginPlay(){
		super.PostBeginPlay();
		cachecvars();

		standsprite=sprite;
		if(player)ApplyUserSkin(true);

		lastpos=pos;
		lastvel=vel;
		lastheight=height;
		lastangle=angle;
		lastpitch=pitch;
		beatcap=35;beatmax=35;
		feetangle=angle;

		if(!scopecamera)scopecamera=spawn("ScopeCamera",pos+(0,0,height-6),ALLOW_REPLACE);
		scopecamera.target=self;

		if(player&&player.bot&&hd_nobots&&!hdlivescounter.wiped(playernumber()))ReplaceBot();
		A_TakeInventory("NullWeapon");

		A_SetTeleFog("TeleportFog","TeleportFog");

		hdlivescounter.updatefragcounts(hdlivescounter.get());
		showgametip();
	}
	void A_CheckGunBraced(){
		if(incapacitated||HDWeapon.IsBusy(self))gunbraced=false;
		else if(
			!barehanded
			&&!gunbraced
			&&zerk<1
			&&floorz==pos.z
			&&!countinv("IsMoving")
		){
			double zat2=getzat(16)-floorz-height;
			if(zat2<0 && zat2>-30){
				gunbraced=true;
				muzzleclimb1.y-=0.1;
				muzzleclimb2.y+=0.05;
				muzzleclimb3.y+=0.05;
			}else{
				gunbraced=false;
				flinetracedata glt;
				linetrace(
					angle+22,12,pitch,
					offsetz:height-7,
					offsetforward:cos(pitch)*10,
					data:glt
				);
				if(glt.hittype==Trace_HitWall){
					muzzleclimb1.x+=0.1;
					muzzleclimb2.x-=0.05;
					muzzleclimb3.x-=0.05;
					gunbraced=true;
				}else{
					linetrace(
						angle-22,12,pitch,
						offsetz:height-7,
						offsetforward:cos(pitch)*10,
						data:glt
					);
					if(glt.hittype==Trace_HitWall){
						muzzleclimb1.x-=0.1;
						muzzleclimb2.x+=0.05;
						muzzleclimb3.x+=0.05;
						gunbraced=true;
					}
				}
			}
			if(gunbraced)A_StartSound("weapons/guntouch",8,CHANF_OVERLAP,0.3);
		}
	}
	void A_CheckSeeState(){
		if(!player)return;
		gunbraced=false;
		overloaded=CheckEncumbrance();
		feetangle=angle;

		//random low health stumbling
		if(floorz>=pos.z && !random(1,2)){
			if(health<random(35,45)){
				if(player.crouchfactor<0.7)A_ChangeVelocity(
					random(-4,2),frandom(-3,3),random(-1,0),CVF_RELATIVE
				);
				vel.xy*=frandom(0.7,1.0);
			}else if(health<random(60,65)){
				if(player.crouchfactor<0.7)A_ChangeVelocity(
					random(-2,1),frandom(-1,1),random(-1,0),CVF_RELATIVE
				);
				vel.xy*=frandom(0.9,1.0);
			}
		}
		if(stunned)setstatelabel("seestun");
		else if(cansprint && runwalksprint>0){
			if(bloodpressure<30)bloodpressure+=2;
			setstatelabel("seesprint");
		}else if(runwalksprint<0){
			setstatelabel("seewalk");
		}

		if(player.readyweapon&&player.readyweapon!=WP_NOCHANGE){
			player.readyweapon.bobspeed=getdefaultbytype(player.readyweapon.getclass()).bobspeed;
			if(stunned||mustwalk||runwalksprint<0){
				player.readyweapon.bobspeed*=0.6;
			}
		}
	}
	states{
	spawn:
		PLAY A 4 nodelay ApplyUserSkin();
	spawn2:
		#### E 5;
		---- A 0 A_TakeInventory("IsMoving");
		---- A 0 A_CheckGunBraced();
		---- AAAAAA 5 A_CheckGunBraced();
		loop;
	see:
		---- A 0 A_Jump(256,"see0");
	seepreview:
		PLAY ABCD 4;
		loop;
	see0:
		---- A 0 A_CheckSeeState();
		#### ABCD 4;
		goto spawn;
	seestun:
		#### ABCD random(2,10) A_GiveInventory("IsMoving",2);
		goto spawn;
	seewalk:
		#### ABCD 6{
			if(height>40 && runwalksprint<0)A_TakeInventory("IsMoving",5);
		}
		goto spawn;
	seesprint:
		---- A 4 A_TakeInventory("PowerFrightener");
		#### B 2;
		#### C 4;
		#### D 2;
		goto spawn;

	missile:
		#### E 4{
			overloaded=CheckEncumbrance();
			A_TakeInventory("PowerFrightener");
			if(findinventory("HDBlurSphere")&&(!player||!(player.readyweapon is "HDFist")))
				HDBlursphere(findinventory("HDBlurSphere")).intensity-=100;
		}
		---- A 0 A_Jump(256,"spawn2");
	melee:
		#### F 2 bright light("SHOT"){
			if(findinventory("HDBlurSphere"))
				HDBlursphere(findinventory("HDBlurSphere")).intensity-=100;
			A_TakeInventory("PowerFrightener");
		}
		---- A 0 A_Jump(256,"missile");
	}
	transient cvar hd_nozoomlean;
	transient cvar hd_aimsensitivity;
	transient cvar hd_bracesensitivity;
	transient cvar hd_noslide;
	transient cvar hd_usefocus;
	transient cvar hd_lasttip;
	transient cvar hd_helptext;
	transient cvar hd_voicepitch;
	transient cvar hd_maglimit;
	transient cvar hd_skin;
	transient cvar hd_give;
	transient cvar neverswitchonpickup;
	void cachecvars(){
		playerinfo plr;
		if(player)plr=player;
		else{
			for(int i=0;i<MAXPLAYERS;i++){
				if(playeringame[i]){
					plr=players[i];
					break;
				}
			}
		}
		hd_nozoomlean=cvar.getcvar("hd_nozoomlean",plr);
		hd_aimsensitivity=cvar.getcvar("hd_aimsensitivity",plr);
		hd_bracesensitivity=cvar.getcvar("hd_bracesensitivity",plr);
		hd_noslide=cvar.getcvar("hd_noslide",plr);
		hd_usefocus=cvar.getcvar("hd_usefocus",plr);
		hd_lasttip=cvar.getcvar("hd_lasttip",plr);
		hd_helptext=cvar.getcvar("hd_helptext",plr);
		hd_voicepitch=cvar.getcvar("hd_voicepitch",plr);
		hd_maglimit=cvar.getcvar("hd_maglimit",plr);
		hd_skin=cvar.getcvar("hd_skin",plr);
		hd_give=cvar.getcvar("hd_give",plr);
		neverswitchonpickup=cvar.getcvar("neverswitchonpickup",plr);
	}
	override void Tick(){
		if(!player||!player.mo||player.mo!=self){super.tick();return;} //anti-voodoodoll
		let player=self.player;

		//cache cvars as necessary
		if(!hd_nozoomlean)cachecvars();

		//check some cvars that are used to pass string commands
		CheckGiveCheat();

		lastpos=pos;

		if(!flip)flip=true;else flip=false; //for things that must alternate every tic

		//for fadeout of tips
		if(specialtipalpha>0.){
			specialtipalpha-=0.1;
			if(
				specialtipalpha>999.
				&&specialtipalpha<1000.
			)specialtipalpha=specialtipalpha=12.+0.08*specialtip.length();
		}

		if(hd_voicepitch)A_SoundPitch(CHAN_VOICE,clamp(hd_voicepitch.getfloat(),0.7,1.3));

		//only do anything below this while the player is alive!
		if(bkilled||health<1){
			super.Tick();
			return;
		}

		//log all new inputs
		int input=player.cmd.buttons;
		double fm=player.cmd.forwardmove;
		double sm=player.cmd.sidemove;
		isFocussing=(
			(
				player.cmd.buttons&BT_ZOOM
				||(
					player.cmd.buttons&BT_USE
					&&hd_usefocus.GetBool()
				)
			)&&!countinv("IsMoving")
		);

		//re-enable item selection after de-incapacitation
		if(
			!incapacitated
			&&(
				!invsel
				||invsel.owner!=self
			)
		){
			for(let item=inv;item!=null;item=item.inv){
				if(
					item.binvbar
				){
					invsel=item;
					break;
				}
			}
		}



		super.Tick();



		HeartTicker(fm,sm,input);
		if(inpain>0)inpain--;
		if(!player||!player.mo||player.mo!=self){super.tick();return;} //that xkcd xorg graph, but with morphing


		ApplyUserSkin();


		//prevent odd screwups that leave you unable to throw grenades or something
		if(!countinv("HDFist"))GiveBasics();
		if(!player.readyweapon)A_SelectWeapon("HDFist");

		//gross hack, but i have no way of telling when a savegame is being loaded
		if(!countinv("PortableLiteAmp"))Shader.SetEnabled(player,"NiteVis",false);

		//same thing with scope camera
		if(!scopecamera)scopecamera=spawn("ScopeCamera",pos,ALLOW_REPLACE);
		scopecamera.target=self;


		//check if teleported
		//fastest you can voluntarily go (berserk, invuln, soulsphere) is mid-90s
		vector2 posdif=lastpos.xy-pos.xy;
		if(bteleport||posdif dot posdif>10000)teleported=true;else teleported=false;

		//if this is put into playermove bad things happen
		TurnCheck();
		if(!incapacitated){
			JumpCheck(fm,sm);
			CrouchCheck();
		}

		//prevent some support exploits
		if(vel dot vel>1)gunbraced=false;

		//add inventory flags for inputs
		//this will be used a few times hereon in
		bool weaponbusy=(
			HDWeapon.IsBusy(self)
			||input&BT_RELOAD
			||input&BT_USER1
//			||input&BT_USER2
			||input&BT_USER3
			||input&BT_USER4
		);
		HDWeapon.SetBusy(self,weaponbusy);
		if((fm||sm)&&runwalksprint>=0&&vel!=(0,0,0))A_GiveInventory("IsMoving");
		if(striptime>0)striptime--;


		//terminal velocity
		if(vel.z<-64)vel.z+=getgravity()*1.1;


		//"falling" damage
		double fallvel=teleported?0:(lastvel-vel).length();

		if(fallvel>8){
			//check collision with shootables
			double zbak=pos.z;
			addz(lastvel.z);
			blockingmobj=null;
			if(
				!checkmove(pos.xy+lastvel.xy,PCM_NOLINES)
				&&blockingmobj
			){
				let bmob=blockingmobj;
				if(
					!bmob.bdontthrust
					&&bmob.mass>0
					&&bmob.mass<1000
				){
					bmob.A_StartSound("weapons/smack",CHAN_AUTO,CHANF_OVERLAP);
					A_StartSound("weapons/smack",CHAN_AUTO,CHANF_OVERLAP);
					bmob.vel+=lastvel*90/bmob.mass;
					vel+=lastvel*0.05;
					bmob.damagemobj(self,self,int(fallvel*frandom(1,8)),"bashing");
				}
			}
			setz(zbak);
		}

		if(fallvel>10){
			if(barehanded)fallvel-=4;
			if(fallvel<=15)A_StartSound("weapons/smack",CHAN_AUTO,volume:0.4);
			else{
				A_StartSound("weapons/smack",CHAN_AUTO);
				if(countinv("PowerStrength"))fallvel/=2;
				int fdmg=int(fallvel*frandom(2,3));
				damagemobj(self,self,fdmg,"falling");
				beatmax-=(fdmg>>1);
				if(frandom(1,fallvel)>7)Disarm(self);
			}
		}
		if(stunned>0)stunned--;


		//see if player is intentionally walking, running or sprinting
		//-1 = walk, 0 = run, 1 = sprint
		if(input & BT_SPEED)runwalksprint=1;
		else if(6400<max(abs(fm),abs(sm)))runwalksprint=0;
		else runwalksprint=-1;

		//check if hands free
		barehanded=(
			hdweapon(player.readyweapon)
			&&hdweapon(player.readyweapon).bdontnull
		);

		//reduce stepheight if crouched
		if(height<40 && !barehanded) maxstepheight=12;
		else maxstepheight=24;


		//get angle for checking high floors
		double checkangle;
		if(!vel.y&&!vel.x)checkangle=angle;else checkangle=atan2(vel.y,vel.x);

		//conditions for forcing walk
		if(
			stunned
			||health<25
			||(zerk<1 && fatigue>HDCONST_WALKFATIGUE && stimcount<8)
			||LineTrace(
				checkangle,26,0,
				TRF_THRUACTORS,
				offsetz:15
			)
			||(
				runwalksprint<1
				&&(fm||sm)
				&&floorz>=pos.z
				&&floorz-getzat(fm*0.004,sm*0.004)>16
			)
		){
			mustwalk=true;
			runwalksprint=-1;
		}else mustwalk=false;

		//conditions for allowing sprint
		if(
			!mustwalk
			&&barehanded
			&&(
				zerk>0||
				stimcount>10||
				fatigue<HDCONST_SPRINTFATIGUE
			)
			&&!LineTrace(
				checkangle,56,0,
				TRF_THRUACTORS,
				offsetz:10
			)
		)cansprint=true;else cansprint=false;


		//encumbrance
		if(findinventory("HDArmourWorn"))
			armourlevel=((HDArmourWorn(findinventory("HDArmourWorn")).mega)?3:1);
			else armourlevel=0;
		double maxspeed=min(
			2.8
			*(countinv("PowerStrength")?1.5:1.)
			*(height<40?0.6:1.),
			countinv("WornRadsuit")?1.8:(
				armourlevel==3?2.:(
					armourlevel==1?3.:999.
				)
			)
		);
		double targetviewbob=VB_MAX*0.4;
		if(overloaded>1.){
			maxspeed=max(0.02,min(maxspeed,4.-overloaded));
			if(maxspeed<0.3){
				targetviewbob=VB_MAX;
				mustwalk=true;
				cansprint=false;
			}else if(maxspeed<0.4){
				targetviewbob=(VB_MAX*0.82);
				cansprint=false;
			}else if(maxspeed<1.){
				targetviewbob=(VB_MAX*0.65);
				cansprint=false;
			}else if(overloaded<1.2){
				targetviewbob=(VB_MAX*0.5);
			}
		}
		if(viewbob>targetviewbob)viewbob=max(viewbob-0.1,targetviewbob);
		else viewbob=min(viewbob+0.1,targetviewbob);

		//apply all movement speed modifiers
		speed=1.-overloaded*0.02;
		//walk
		if(mustwalk||cmdleanmove||runwalksprint<0)speed=0.36;
		else if(cansprint && runwalksprint>0){
			//sprint
			if(!sm && fm>0){
				speed=hd_lowspeed?1.8:2.8;
				viewbob=max(viewbob,(VB_MAX*0.8));
			}else speed=hd_lowspeed?1.3:1.6;
			if(hd_lowspeed)speed-=armourlevel*0.05;
		}
		//cap speed depending on weapon status
		if(weaponbusy)speed=min(speed,0.6);
		else if(
			//weapons so bulky they get in the way physically
			//as a rule of thumb, anything that uses the "swinging" weapon hudbob
			player.readyweapon is "Vulcanette"||
			player.readyweapon is "BFG9k"||
			player.readyweapon is "HDBackpack"
		)speed=min(speed,0.7);
		if(countinv("PowerStrength"))speed*=1.5;
		if(height<40)speed*=0.6;
		speed=min(speed,maxspeed);

		//then snap to 1 of only 3 speeds if necessary
		if(multiplayer && hd_3speed){
			if(speed>2.)speed=2.6;
			else if(speed>0.5)speed=1.;
			else speed=0.36;
		}

		//special hud bobbing
		double bobvel=max((mustwalk&&vel.xy!=(0,0))?1:0,abs(vel.x),abs(vel.y))*viewbob;
		let pr=weapon(player.readyweapon);
		if(player.onground&&bobvel&&pr){
			bobcounter+=5.3*pr.bobspeed;
			if(bobvel<0.1&&(89<bobcounter<90||269<bobcounter<270))bobcounter=90;
			else if(bobcounter>360)bobcounter=0;
		}
		hudbob=(
			cos(bobcounter)*(sm?5.:2.)*(pr?pr.bobrangex:1.),
			(sin(bobcounter*2)+1.)*6.*(pr?pr.bobrangey:1.)
		)*bobvel*((!mustwalk&&runwalksprint<0)?0.5:1.)+hudbobrecoil1;
		hudbobrecoil1=hudbobrecoil1*0.2+hudbobrecoil2;
		hudbobrecoil2=hudbobrecoil3;
		hudbobrecoil3=hudbobrecoil4;
		hudbobrecoil4=(0,0);

		if(recoilfov!=1.)recoilfov=(recoilfov+1.)*0.5;


		//lowering weapon for sprint/mantle/jump
		if(
			totallyblocked
			||input&BT_SPEED
			||input&BT_JUMP
		){
			if(!barehanded){
				let lw=hdweapon(player.readyweapon);
				A_SetInventory("NulledWeapon",1);
				A_SetInventory("NullWeapon",1);
				A_SelectWeapon("NullWeapon");
				if(lw){
					lastweapon=lw;
					let nw=hdweapon(findinventory("NullWeapon"));
					nw.barrellength=lw.barrellength+0.1;
					nw.barrelwidth=lw.barrelwidth+0.1;
					nw.barreldepth=lw.barreldepth+0.1;
				}
			}
		}else if(
			player.readyweapon is "NullWeapon"
		){
			if(lastweapon&&lastweapon.owner==self)A_SelectWeapon(lastweapon.getclassname());
			else A_SelectWeapon("HDFist");
		}else if(player.readyweapon is "HDFist")lastweapon=null;

		//display crosshair
		if(
			weaponbusy
			||(
				input&BT_RELOAD
//				||input&BT_USER1
//				||input&BT_USER2
				||input&BT_USER3
				||input&BT_USER4
				||input&BT_JUMP
			)
			||abs(player.cmd.yaw)>16384
			||countinv("PowerInvulnerable")
		)nocrosshair=12;
		else nocrosshair--;


		UseButtonCheck(input);


		//this must be at the end since it needs to overwrite a lot of what has just happened
		IncapacitatedCheck();

		//record old shit
		oldfm=fm;
		oldsm=sm;
		lastvel=vel;

		oldinput=input;
	}
}
const VB_MAX=0.9;




//Camera actor for player's scope
class ScopeCamera:IdleDummy{
	hdplayerpawn hpl;
	override void postbeginplay(){
		super.postbeginplay();
		hpl=hdplayerpawn(target);
	}
	override void tick(){
		if(!hpl){
			destroy();
			return;
		}
		A_SetAngle(hpl.angle-hpl.hudbob.x*0.54,SPF_INTERPOLATE);
		A_SetPitch(hpl.pitch+hpl.hudbob.y*0.27,SPF_INTERPOLATE);
		A_SetRoll(hpl.roll);
		vector2 fwd=angletovector(angle,0.3);

		double cf=(!!hpl.player)?hpl.player.viewheight:HDCONST_PLAYERHEIGHT-6;

		if(abs(pitch)>89)setxyz(hpl.pos+(
			fwd*max(0.5,cos(pitch))*2,
			sin(-pitch)*6+cf
		));else setxyz(hpl.pos+(
			fwd*cos(pitch)*6,
			sin(-pitch)*6+cf
		));
	}
}



//stuff to reset upon entering a new level
extend class HDHandlers{
	override void PlayerEntered(PlayerEvent e){
		let p=HDPlayerPawn(players[e.PlayerNumber].mo);
		if(p){
			//do NOT put anything here that must be done for everyone at the very start of the game!
			//Players 5-8 will not work.

			if(deathmatch)p.spawn("TeleFog",p.pos,ALLOW_REPLACE);

			p.levelreset();  //reset if changing levels
			hdlivescounter.get();  //only needs to be done once

			//replace bot if changing levels
			if(
				hd_nobots
				&&players[e.PlayerNumber].bot
				&&!hdlivescounter.wiped(e.playernumber)
			){
				p.ReplaceBot();
			}
		}
	}
}

extend class HDPlayerPawn{
	//reset various... things.
	void levelreset(){
		lastpos=pos;
		lastvel=vel;
		lastheight=height;
		lastangle=angle;
		lastpitch=pitch;

		incapacitated=0;
		incaptimer=0;

		beatcap=35;beatmax=35;
		bloodpressure=0;beatcounter=0;
		fatigue=0;
		stunned=0;
		stimcount=0;
		zerk=0;
		haszerked=0;

		bloodloss=0;
		
		A_Capacitated();

		feetangle=angle;
		hasgrabbed=false;

		oldwoundcount+=woundcount+unstablewoundcount;
		woundcount=0;
		unstablewoundcount=0;

		oldwoundcount=min(90,oldwoundcount-1);
		burncount=min(90,burncount-1);
		if(!random(0,7))aggravateddamage--;

		if(secondflesh>0){
			int seconded=min(secondflesh,oldwoundcount);
			secondflesh=0;
			oldwoundcount-=seconded;
			seconded=random(-100,seconded);
			if(seconded>0)aggravateddamage+=seconded;
		}

		givebody(max(0,maxhealth()-health));

		overloaded=CheckEncumbrance();

		HDWeapon.SetBusy(self,false);
		A_TakeInventory("IsMoving");
		A_TakeInventory("Heat");
		gunbraced=false;

		GiveBasics();

		A_WeaponOffset(0,30); //reset the weaponoffset so weapon floatiness in playerturn works after level change

		let hbl=HDBlurSphere(findinventory("HDBlurSphere"));
		if(!hbl||!hbl.worn){
			bshadow=false;
			bnotarget=false;
			bnevertarget=false;
			a_setrenderstyle(1.,STYLE_Normal);
		}

		A_GiveInventory("PowerFrightener",1);
		if(
			player
			&&player
			&&cvar.getcvar("hd_consolidate",player).getbool()
		)ConsolidateAmmo();

		if(player){
			Shader.SetEnabled(player,"NiteVis",false);
			Shader.SetEnabled(player,"NiteVisRed",false);
			if(getage()>10)showgametip();
		}
	}
}
class kickchecker:actor{
	default{
		projectile;
		radius 6;height 10;
	}
	override bool cancollidewith(actor other,bool passive){
		return(
			other.bshootable
			&&!other.bghost
			&&!(other is "HDPickup")
			&&!(other is "HDUPK")
			&&!(other is "HDWeapon")
		);
	}
}


