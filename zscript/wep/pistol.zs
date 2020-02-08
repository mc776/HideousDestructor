// ------------------------------------------------------------
// Pistol
// ------------------------------------------------------------
class HDHandgunRandomDrop:RandomSpawner{
	default{
		dropitem "HDPistol",16,5;
		dropitem "HDRevolver",16,1;
	}
}
class HDHandgun:HDWeapon{
	bool wronghand;
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	action void A_SwapHandguns(){
		let mwt=SpareWeapons(findinventory("SpareWeapons"));
		if(!mwt){
			setweaponstate("whyareyousmiling");
			return;
		}
		int pistindex=mwt.weapontype.find(invoker.getclassname());
		if(pistindex==mwt.weapontype.size()){
			setweaponstate("whyareyousmiling");
			return;
		}
		A_WeaponBusy();

		array<string> wepstat;
		string wepstat2="";
		mwt.weaponstatus[pistindex].split(wepstat,",");
		for(int i=0;i<wepstat.size();i++){
			if(i)wepstat2=wepstat2..",";
			wepstat2=wepstat2..invoker.weaponstatus[i];
			invoker.weaponstatus[i]=wepstat[i].toint();
		}
		mwt.weaponstatus[pistindex]=wepstat2;

		invoker.wronghand=!invoker.wronghand;
	}
}
class HDPistol:HDHandgun replaces Pistol{
	default{
		+hdweapon.fitsinbackpack
		+hdweapon.reverseguninertia
		scale 0.63;
		weapon.selectionorder 50;
		weapon.slotnumber 2;
		weapon.slotpriority 2;
		weapon.kickback 30;
		weapon.bobrangex 0.1;
		weapon.bobrangey 0.6;
		weapon.bobspeed 2.5;
		weapon.bobstyle "normal";
		obituary "%o got capped by %k's pea shooter.";
		inventory.pickupmessage "You got the pistol!";
		tag "pistol";
		hdweapon.refid HDLD_PISTOL;
		hdweapon.barrelsize 10,0.3,0.5;
		inventory.maxamount 3;
	}
	override double weaponbulk(){
		int mgg=weaponstatus[PISS_MAG];
		return 30+(mgg<0?0:(ENC_9MAG_LOADED+mgg*ENC_9_LOADED));
	}
	override double gunmass(){
		return 10;
	}
	override void failedpickupunload(){
		failedpickupunloadmag(PISS_MAG,"HD9mMag15");
	}
	override string,double getpickupsprite(){
		string spr;
		if(weaponstatus[PISS_CHAMBER]<1){
			if(weaponstatus[0]&PISF_SELECTFIRE)spr="D";
			else spr="B";
		}else{
			if(weaponstatus[0]&PISF_SELECTFIRE)spr="C";
			else spr="A";
		}
		return "PIST"..spr.."0",1.;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			int nextmagloaded=sb.GetNextLoadMag(hdmagammo(hpl.findinventory("HD9mMag15")));
			if(nextmagloaded>=15){
				sb.drawimage("CLP2NORM",(-46,-3),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1,1));
			}else if(nextmagloaded<1){
				sb.drawimage("CLP2EMPTY",(-46,-3),sb.DI_SCREEN_CENTER_BOTTOM,alpha:nextmagloaded?0.6:1.,scale:(1,1));
			}else sb.drawbar(
				"CLP2NORM","CLP2GREY",
				nextmagloaded,15,
				(-46,-3),-1,
				sb.SHADER_VERT,sb.DI_SCREEN_CENTER_BOTTOM
			);
			sb.drawnum(hpl.countinv("HD9mMag15"),-43,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		if(hdw.weaponstatus[0]&PISF_SELECTFIRE)sb.drawwepcounter(hdw.weaponstatus[0]&PISF_FIREMODE,
			-22,-10,"RBRSA3A7","STFULAUT"
		);
		sb.drawwepnum(hdw.weaponstatus[PISS_MAG],15);
		if(hdw.weaponstatus[PISS_CHAMBER]==2)sb.drawwepdot(-16,-10,(3,1));
	}
	override string gethelptext(){
		return
		WEPHELP_FIRESHOOT
		..((weaponstatus[0]&PISF_SELECTFIRE)?(WEPHELP_FIREMODE.."  Semi/Auto\n"):"")
		..WEPHELP_ALTRELOAD.."  Quick-Swap (if available)\n"
		..WEPHELP_RELOADRELOAD
		..WEPHELP_MAGMANAGER
		..WEPHELP_UNLOADUNLOAD
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc,string whichdot
	){
		int cx,cy,cw,ch;
		[cx,cy,cw,ch]=screen.GetClipRect();
		vector2 scc;
		vector2 bobb=bob*1.6;

		//if slide is pushed back, throw sights off line
		if(hpl.player.getpsprite(PSP_WEAPON).frame>=2){
			sb.SetClipRect(
				-10+bob.x,-5+bob.y,20,14,
				sb.DI_SCREEN_CENTER
			);
			scc=(0.7,0.8);
			bobb.y=clamp(bobb.y*1.1-3,-10,10);
		}else{
			sb.SetClipRect(
				-8+bob.x,-4+bob.y,16,10,
				sb.DI_SCREEN_CENTER
			);
			scc=(0.6,0.6);
			bobb.y=clamp(bobb.y,-8,8);
		}
		sb.drawimage(
			"frntsite",(0,0)+bobb,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.9,scale:scc
		);
		sb.SetClipRect(cx,cy,cw,ch);
		sb.drawimage(
			"backsite",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			scale:scc
		);
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			if(owner.countinv("HDPistolAmmo"))owner.A_DropInventory("HDPistolAmmo",amt*15);
			else owner.A_DropInventory("HD9mMag15",amt);
		}
	}
	override void ForceBasicAmmo(){
		owner.A_TakeInventory("HDPistolAmmo");
		owner.A_TakeInventory("HD9mMag15");
		owner.A_GiveInventory("HD9mMag15");
	}
	action void A_CheckPistolHand(){
		if(invoker.wronghand)player.getpsprite(PSP_WEAPON).sprite=getspriteindex("PI2GA0");
	}
	states{
	select0:
		PISG A 0{
			if(!countinv("NulledWeapon"))invoker.wronghand=false;
			A_TakeInventory("NulledWeapon");
			A_CheckPistolHand();
		}
		#### A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,2);
		#### C 0;
		---- A 1 A_Raise();
		---- A 1 A_Raise(30);
		---- A 1 A_Raise(30);
		---- A 1 A_Raise(24);
		---- A 1 A_Raise(18);
		wait;
	deselect0:
		PISG A 0 A_CheckPistolHand();
		#### A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,2);
		#### C 0;
		---- AAA 1 A_Lower();
		---- A 1 A_Lower(18);
		---- A 1 A_Lower(24);
		---- A 1 A_Lower(30);
		wait;

	ready:
		PISG A 0 A_CheckPistolHand();
		#### A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,2);
		#### C 0;
		#### # 0 A_SetCrosshair(21);
		#### # 1 A_WeaponReady(WRF_ALL);
		goto readyend;
	user3:
		---- A 0 A_MagManager("HD9mMag15");
		goto ready;
	user2:
	firemode:
		---- A 0{
			if(invoker.weaponstatus[0]&PISF_SELECTFIRE)
			invoker.weaponstatus[0]^=PISF_FIREMODE;
			else invoker.weaponstatus[0]&=~PISF_FIREMODE;
		}goto nope;
	altfire:
		---- A 0{
			invoker.weaponstatus[0]&=~PISF_JUSTUNLOAD;
			if(
				invoker.weaponstatus[PISS_CHAMBER]!=2
				&&invoker.weaponstatus[PISS_MAG]>0
			)setweaponstate("chamber_manual");
		}goto nope;
	chamber_manual:
		---- A 0{
			if(
				!(invoker.weaponstatus[0]&PISF_JUSTUNLOAD)
				&&(
					invoker.weaponstatus[PISS_CHAMBER]==2
					||invoker.weaponstatus[PISS_MAG]<1
				)
			)setweaponstate("nope");
		}
		#### B 3 offset(0,34);
		#### C 4 offset(0,37){
			A_MuzzleClimb(frandom(0.4,0.5),-frandom(0.6,0.8));
			A_StartSound("weapons/pismagclick",8);
			int psch=invoker.weaponstatus[PISS_CHAMBER];
			invoker.weaponstatus[PISS_CHAMBER]=0;
			if(psch==2){
				A_SpawnItemEx("HDPistolAmmo",cos(pitch*12),0,height-9-sin(pitch)*12,1,2,3,0);
			}else if(psch==1){
				A_SpawnItemEx("HDSpent9mm",
					cos(pitch)*12,0,height-9-sin(pitch)*12,
					vel.x,vel.y,vel.z,
					0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}
			if(invoker.weaponstatus[PISS_MAG]>0){
				invoker.weaponstatus[PISS_CHAMBER]=2;
				invoker.weaponstatus[PISS_MAG]--;
			}
		}
		#### B 3 offset(0,35);
		#### B 0 A_ReFire();
		goto ready;
	althold:
	hold:
		goto nope;
	fire:
		---- A 0{
			invoker.weaponstatus[0]&=~PISF_JUSTUNLOAD;
			if(invoker.weaponstatus[PISS_CHAMBER]==2)setweaponstate("shoot");
			else if(invoker.weaponstatus[PISS_CHAMBER]>0)setweaponstate("chamber_manual");
		}goto nope;
	shoot:
		#### B 1{
			if(invoker.weaponstatus[PISS_CHAMBER]==2)A_GunFlash();
		}
		#### C 1{
			if(hdplayerpawn(self)){
				hdplayerpawn(self).gunbraced=false;
				A_GiveInventory("IsMoving",1);
			}
			A_MuzzleClimb(
				-frandom(0.8,1.),-frandom(1.2,1.6),
				frandom(0.4,0.5),frandom(0.6,0.8)
			);
		}
		#### C 0{
			A_SpawnItemEx("HDSpent9mm",
				cos(pitch)*12,0,height-9-sin(pitch)*12,
				vel.x,vel.y,vel.z,
				0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
			);
			invoker.weaponstatus[PISS_CHAMBER]=0;
			if(invoker.weaponstatus[PISS_MAG]<1){
				A_StartSound("weapons/pistoldry",8,CHANF_OVERLAP,0.9);
				setweaponstate("nope");
			}
		}
		#### B 1{
			A_WeaponReady(WRF_NOFIRE);
			invoker.weaponstatus[PISS_CHAMBER]=2;
			invoker.weaponstatus[PISS_MAG]--;
			if(
				(invoker.weaponstatus[0]&(PISF_FIREMODE|PISF_SELECTFIRE))
				==(PISF_FIREMODE|PISF_SELECTFIRE)
			){
				let pnr=HDPlayerPawn(self);
				if(
					pnr&&countinv("IsMoving")
					&&pnr.fatigue<12
				)pnr.fatigue++;
				A_GiveInventory("IsMoving",5);
				A_Refire("fire");
			}else A_Refire();
		}goto ready;
	flash:
		PI2F A 0 A_JumpIf(invoker.wronghand,2);
		PISF A 0;
		---- A 1 bright{
			HDFlashAlpha(64);
			A_Light1();
			let bbb=HDBulletActor.FireBullet(self,"HDB_9",spread:2.,speedfactor:frandom(0.97,1.03));
			if(
				frandom(0,ceilingz-floorz)<bbb.speed*0.3
			)A_AlertMonsters(256);

			invoker.weaponstatus[PISS_CHAMBER]=1;
			A_ZoomRecoil(0.995);
			A_MuzzleClimb(-frandom(0.4,1.2),-frandom(0.4,1.6));
		}
		---- A 0 A_StartSound("weapons/pistol",CHAN_WEAPON);
		---- A 0 A_Light0();
		stop;
	unload:
		---- A 0{
			invoker.weaponstatus[0]|=PISF_JUSTUNLOAD;
			if(invoker.weaponstatus[PISS_MAG]>=0)setweaponstate("unmag");
		}goto chamber_manual;
	loadchamber:
		---- A 0 A_JumpIf(invoker.weaponstatus[PISS_CHAMBER]>0,"nope");
		---- A 1 offset(0,34) A_StartSound("weapons/pocket",9);
		---- A 1 offset(2,36);
		#### C 3 offset(5,40);
		#### C 6 offset(4,39){
			if(countinv("HDPistolAmmo")){
				A_TakeInventory("HDPistolAmmo",1,TIF_NOTAKEINFINITE);
				invoker.weaponstatus[PISS_CHAMBER]=2;
				A_StartSound("weapons/pischamber1",8);
			}
		}
		#### B 3 offset(2,36);
		#### B 2 offset(0,34);
		goto readyend;
	reload:
		---- A 0{
			invoker.weaponstatus[0]&=~PISF_JUSTUNLOAD;
			if(invoker.weaponstatus[PISS_MAG]>=15)setweaponstate("nope");
			else if(HDMagAmmo.NothingLoaded(self,"HD9mMag15")){
				if(countinv("HDPistolAmmo"))setweaponstate("loadchamber");
				else setweaponstate("nope");
			}
		}goto unmag;
	unmag:
		---- A 1 offset(0,34) A_SetCrosshair(21);
		---- A 1 offset(1,38);
		---- A 2 offset(2,42);
		---- A 3 offset(3,46) A_StartSound("weapons/pismagclick",8,CHANF_OVERLAP);
		---- A 0{
			int pmg=invoker.weaponstatus[PISS_MAG];
			invoker.weaponstatus[PISS_MAG]=-1;
			if(pmg<0)setweaponstate("magout");
			else if(
				(!PressingUnload()&&!PressingReload())
				||A_JumpIfInventory("HD9mMag15",0,"null")
			){
				HDMagAmmo.SpawnMag(self,"HD9mMag15",pmg);
				setweaponstate("magout");
			}
			else{
				HDMagAmmo.GiveMag(self,"HD9mMag15",pmg);
				A_StartSound("weapons/pocket",9);
				setweaponstate("pocketmag");
			}
		}
	pocketmag:
		---- AAA 5 offset(0,46) A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
		goto magout;
	magout:
		---- A 0{
			if(invoker.weaponstatus[0]&PISF_JUSTUNLOAD)setweaponstate("reloadend");
			else setweaponstate("loadmag");
		}

	loadmag:
		---- A 4 offset(0,46) A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
		---- A 0 A_StartSound("weapons/pocket",9);
		---- A 5 offset(0,46) A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
		---- A 3;
		---- A 0{
			let mmm=hdmagammo(findinventory("HD9mMag15"));
			if(mmm){
				invoker.weaponstatus[PISS_MAG]=mmm.TakeMag(true);
				A_StartSound("weapons/pismagclick",8);
			}
			if(
				invoker.weaponstatus[PISS_CHAMBER]<1
				&&invoker.weaponstatus[PISS_MAG]>0
			){
				invoker.weaponstatus[PISS_CHAMBER]=2;
				invoker.weaponstatus[PISS_MAG]--;
			}else setweaponstate("reloadend");
		}
		#### A 3 offset(0,48) A_StartSound("weapons/pischamber2",8,CHANF_OVERLAP);
		#### A 2 offset(0,45);
		goto reloadend;
	reloadend:
		---- A 2 offset(3,46);
		---- A 1 offset(2,42);
		---- A 1 offset(2,38);
		---- A 1 offset(1,34);
		---- A 0 A_JumpIf(pressingreload()||pressingunload(),"nope");
		goto ready;

	user1:
	altreload:
	swappistols:
		---- A 0 A_SwapHandguns();
		---- A 0{
			bool id=(Wads.CheckNumForName("id",0)!=-1);
			bool offhand=invoker.wronghand;
			bool lefthanded=(id!=offhand);
			if(lefthanded){
				A_Overlay(1025,"raiseleft");
				A_Overlay(1026,"lowerright");
			}else{
				A_Overlay(1025,"raiseright");
				A_Overlay(1026,"lowerleft");
			}
		}
		TNT1 A 5;
		PISG A 0 A_CheckPistolHand();
		goto nope;
	lowerleft:
		PISG A 0 A_JumpIf(Wads.CheckNumForName("id",0)!=-1,2);
		PI2G A 0;
		#### B 1 offset(-6,38);
		#### B 1 offset(-12,48);
		#### B 1 offset(-20,60);
		#### B 1 offset(-34,76);
		#### B 1 offset(-50,86);
		stop;
	lowerright:
		PI2G A 0 A_JumpIf(Wads.CheckNumForName("id",0)!=-1,2);
		PISG A 0;
		#### B 1 offset(6,38);
		#### B 1 offset(12,48);
		#### B 1 offset(20,60);
		#### B 1 offset(34,76);
		#### B 1 offset(50,86);
		stop;
	raiseleft:
		PISG A 0 A_JumpIf(Wads.CheckNumForName("id",0)!=-1,2);
		PI2G A 0;
		#### A 1 offset(-50,86);
		#### A 1 offset(-34,76);
		#### A 1 offset(-20,60);
		#### A 1 offset(-12,48);
		#### A 1 offset(-6,38);
		stop;
	raiseright:
		PI2G A 0 A_JumpIf(Wads.CheckNumForName("id",0)!=-1,2);
		PISG A 0;
		#### A 1 offset(50,86);
		#### A 1 offset(34,76);
		#### A 1 offset(20,60);
		#### A 1 offset(12,48);
		#### A 1 offset(6,38);
		stop;
	whyareyousmiling:
		#### B 1 offset(0,48);
		#### B 1 offset(0,60);
		#### B 1 offset(0,76);
		TNT1 A 7;
		PISG A 0{
			invoker.wronghand=!invoker.wronghand;
			A_CheckPistolHand();
		}
		#### B 1 offset(0,76);
		#### B 1 offset(0,60);
		#### B 1 offset(0,48);
		goto nope;


	spawn:
		PIST ABCD -1 nodelay{
			if(invoker.weaponstatus[PISS_CHAMBER]<1){
				if(invoker.weaponstatus[0]&PISF_SELECTFIRE)frame=3;
				else frame=1;
			}else{
				if(invoker.weaponstatus[0]&PISF_SELECTFIRE)frame=2;
				else frame=0;
			}
		}stop;
	}
	override void initializewepstats(bool idfa){
		weaponstatus[PISS_MAG]=15;
		weaponstatus[PISS_CHAMBER]=2;
	}
	override void loadoutconfigure(string input){
		int selectfire=getloadoutvar(input,"selectfire",1);
		if(!selectfire){
			weaponstatus[0]&=~PISF_SELECTFIRE;
			weaponstatus[0]&=~PISF_FIREMODE;
		}else if(selectfire>0){
			weaponstatus[0]|=PISF_SELECTFIRE;
		}
		if(weaponstatus[0]&PISF_SELECTFIRE){
			int firemode=getloadoutvar(input,"firemode",1);
			if(!firemode)weaponstatus[0]&=~PISF_FIREMODE;
			else if(firemode>0)weaponstatus[0]|=PISF_FIREMODE;
		}
	}
}
enum pistolstatus{
	PISF_SELECTFIRE=1,
	PISF_FIREMODE=2,
	PISF_JUSTUNLOAD=4,

	PISS_FLAGS=0,
	PISS_MAG=1,
	PISS_CHAMBER=2, //0 empty, 1 spent, 2 loaded
};



//use this to give an autopistol in a custom loadout
class HDAutoPistol:HDWeaponGiver{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Pistol (select-fire)"
		//$Sprite "PISTA0"
		tag "pistol (select-fire)";
		hdweapongiver.bulk 34;
		hdweapongiver.weapontogive "HDPistol";
		hdweapongiver.config "selectfire";
		hdweapongiver.weprefid HDLD_PISTOL;
		inventory.icon "PISTC0";
	}
}

