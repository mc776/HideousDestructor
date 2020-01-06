// ------------------------------------------------------------
// Super Shotgun
// ------------------------------------------------------------
class Slayer:HDShotgun replaces HDShotgun{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Slayer"
		//$Sprite "SLAYA0"

		weapon.selectionorder 30;
		weapon.slotnumber 3;
		inventory.pickupmessage "You got the double-barreled shotgun!";
		obituary "$OB_MPSSHOTGUN";
		weapon.bobrangex 0.18;
		weapon.bobrangey 0.7;
		scale 0.6;
		hdweapon.barrelsize 26,1,1;
		tag "Slayer";
		hdweapon.refid HDLD_SLAYER;
	}
	static void Fire(actor caller,bool right,int choke=7){
		double shotpower=getshotpower();
		double spread=3.;
		double speedfactor=1.2;
		let sss=Slayer(caller.findinventory("Slayer"));
		if(sss){
			choke=sss.weaponstatus[right?SLAYS_CHOKE2:SLAYS_CHOKE1];
			sss.shotpower=shotpower;
		}

		choke=clamp(choke,0,7);
		spread=6.5-0.5*choke;
		speedfactor=1.+0.02857*choke;

		spread*=shotpower;
		speedfactor*=shotpower;
		vector2 barreladjust=(0.8,-0.05);
		if(right)barreladjust=-barreladjust;
		HDBulletActor.FireBullet(caller,"HDB_wad",xyofs:barreladjust.x,aimoffx:barreladjust.y);
		let p=HDBulletActor.FireBullet(caller,"HDB_00",xyofs:barreladjust.x,
			spread:spread,aimoffx:barreladjust.y,speedfactor:speedfactor,amount:10
		);
		p.spawn("DistantShotgun",p.pos,ALLOW_REPLACE);
	}
	override string,double getpickupsprite(){return "SLAY"..getpickupframe().."0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage("SHL1A0",(-47,-10),sb.DI_SCREEN_CENTER_BOTTOM);
			sb.drawnum(hpl.countinv("HDShellAmmo"),-46,-8,sb.DI_SCREEN_CENTER_BOTTOM,font.CR_BLACK);
		}
		int loffs=-28;int rofs=-16;
		if(hdw.weaponstatus[0]&SLAYF_DOUBLE){
			loffs=-24;rofs=-20;
			sb.drawimage("STBURAUT",(-23,-17),sb.DI_SCREEN_CENTER_BOTTOM);
		}
		if(hdw.weaponstatus[SLAYS_CHAMBER1]>1){
			sb.drawwepdot(loffs,-10,(3,5));
			sb.drawwepdot(loffs,-7,(3,2));
		}else if(hdw.weaponstatus[SLAYS_CHAMBER1]>0){
			sb.drawwepdot(loffs,-7,(3,2));
		}
		if(hdw.weaponstatus[SLAYS_CHAMBER2]>1){
			sb.drawwepdot(rofs,-10,(3,5));
			sb.drawwepdot(rofs,-7,(3,2));
		}else if(hdw.weaponstatus[SLAYS_CHAMBER2]>0){
			sb.drawwepdot(rofs,-7,(3,2));
		}
		for(int i=hdw.weaponstatus[SHOTS_SIDESADDLE];i>0;i--){
			sb.drawwepdot(-10-i*2,-2,(1,3));
		}
	}
	override string gethelptext(){
		return
		WEPHELP_FIRE.."  Shoot Left (choke: "..weaponstatus[SLAYS_CHOKE1]..")\n"
		..WEPHELP_ALTFIRE.."  Shoot Right (choke: "..weaponstatus[SLAYS_CHOKE2]..")\n"
		..WEPHELP_RELOAD.."  Reload (side saddles first)\n"
		..WEPHELP_ALTRELOAD.."  Reload (pockets only)\n"
		..WEPHELP_FIREMODE.."  Hold to force double shot\n"
		..WEPHELP_FIREMODE.."+"..WEPHELP_RELOAD.."  Load side saddles\n"
		..WEPHELP_USE.."+"..WEPHELP_UNLOAD.."  Steal ammo from Hunter\n"
		..WEPHELP_UNLOADUNLOAD
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc,string whichdot
	){
		int cx,cy,cw,ch;
		[cx,cy,cw,ch]=screen.GetClipRect();
		sb.SetClipRect(
			-16+bob.x,-4+bob.y,32,12,
			sb.DI_SCREEN_CENTER
		);
		vector2 bobb=bob*3;
		bobb.y=clamp(bobb.y,-8,8);
		sb.drawimage(
			"frntsite",(0,0)+bobb,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.9,scale:(0.7,1)
		);
		sb.SetClipRect(cx,cy,cw,ch);
		sb.drawimage(
			"dbbaksit",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
		);
	}
	override void PostBeginPlay(){
		if(Wads.CheckNumForName("SHT2B0",wads.ns_sprites,-1,false)<0){
			if(owner){
				actor ownor=owner;
				ownor.A_GiveInventory("Hunter");
				if(ownor.player&&ownor.player.readyweapon==self)
					ownor.A_SelectWeapon("Hunter");
				if(hd_debug)ownor.A_Log("doom 1 shotty lol",true);
				destroy();
			}else{
				spawn("Hunter",pos,ALLOW_REPLACE);
				destroy();
			}
			return;
		}
		super.postbeginplay();
	}
	override double gunmass(){
		return 6+weaponstatus[SHOTS_SIDESADDLE]*0.06;
	}
	override double weaponbulk(){
		return 100+weaponstatus[SHOTS_SIDESADDLE]*ENC_SHELLLOADED;
	}
	//so you don't switch to the hunter every IDFA in D1
	override void detachfromowner(){
		if(Wads.CheckNumForName("SHT2B0",wads.ns_sprites,-1,false)<0){
			weapon.detachfromowner();
		}else hdweapon.detachfromowner();
	}
	transient cvar swapbarrels;
	states{
	select0:
		SH2G A 0{invoker.swapbarrels=cvar.getcvar("hd_swapbarrels",player);}
		goto select0small;
	deselect0:
		SH2G A 0;
		goto deselect0small;
	fire:
	altfire:
		#### A 0 A_ClearRefire();
	ready:
		TNT1 A 0; //let the PostBeginPlay handle the presence of the relevant sprite
		SH2G A 0 A_JumpIf(pressingunload()&&(pressinguse()||pressingzoom()),"cannibalize");
		#### A 1{
			if(PressingFireMode()){
				invoker.weaponstatus[0]|=SLAYF_DOUBLE;
				if(pressingreload()&&invoker.weaponstatus[SHOTS_SIDESADDLE]<12){
					invoker.weaponstatus[0]&=~SLAYF_DOUBLE;
					setweaponstate("reloadss");
					return;
				}
			}else invoker.weaponstatus[0]&=~SLAYF_DOUBLE;

			int pff;
			if(invoker.swapbarrels&&invoker.swapbarrels.getbool()){
				pff=PressingAltfire();
				if(PressingFire())pff|=2;
			}else{
				pff=PressingFire();
				if(PressingAltfire())pff|=2;
			}

			bool ch1=invoker.weaponstatus[SLAYS_CHAMBER1]==2;
			bool ch2=invoker.weaponstatus[SLAYS_CHAMBER2]==2;

			bool dbl=invoker.weaponstatus[0]&SLAYF_DOUBLE;
			if(ch1&&ch2){
				if(pff==3){
					A_Overlay(PSP_FLASH,"flashboth");
					return;
				}
				else if(pff&&dbl){
					setweaponstate("double");
					return;
				}
			}else if(pff&&dbl){
				if(ch1)A_Overlay(11,"flashleft");
				if(ch2)A_Overlay(12,"flashright");
			}
			if(ch1&&pff%2)A_Overlay(11,"flashleft");
			else if(ch2&&pff>1)A_Overlay(12,"flashright");
			else A_WeaponReady((WRF_ALL|WRF_NOFIRE)&~WRF_ALLOWUSER2);
		}
		#### A 0 A_WeaponReady();
		goto readyend;
	double:
		#### A 1 offset(0,34);
		#### A 1 offset(0,33);
		#### A 0 A_Overlay(PSP_FLASH,"flashboth");
		goto readyend;

	flashleft:
		SH2F A 1 bright{
			A_Light2();
			HDFlashAlpha(64,false,overlayid());
			A_StartSound("weapons/slayersingle",CHAN_WEAPON,CHANF_OVERLAP);
			A_ZoomRecoil(0.9);
			invoker.weaponstatus[SLAYS_CHAMBER1]=1;

			invoker.Fire(self,0);
		}
		TNT1 A 1{
			A_Light0();
			double shotpower=invoker.shotpower;
			A_MuzzleClimb(0.8*shotpower,-1.6*shotpower,0.8*shotpower,-1.6*shotpower);
		}goto flasheither;
	flashright:
		SH2F B 1 bright{
			A_Light2();
			HDFlashAlpha(64,false,overlayid());
			A_StartSound("weapons/slayersingle",CHAN_WEAPON,CHANF_OVERLAP);
			A_ZoomRecoil(0.9);
			invoker.weaponstatus[SLAYS_CHAMBER2]=1;

			invoker.Fire(self,1);
		}
		TNT1 A 1{
			A_Light0();
			double shotpower=invoker.shotpower;
			A_MuzzleClimb(-0.8*shotpower,-1.6*shotpower,-0.8*shotpower,-1.6*shotpower);
		}goto flasheither;
	flasheither:
		TNT1 A 0 A_AlertMonsters();
		TNT1 A 0 setweaponstate("recoil");
		stop;
	flashboth:
		SH2F C 1 bright{
			A_Light2();
			HDFlashAlpha(128);
			A_StartSound("weapons/slayersingle",CHAN_WEAPON,CHANF_OVERLAP);
			A_StartSound("weapons/slayersingle",CHAN_WEAPON,CHANF_OVERLAP);
			A_ZoomRecoil(0.7);
			invoker.weaponstatus[SLAYS_CHAMBER1]=1;
			invoker.weaponstatus[SLAYS_CHAMBER2]=1;

			invoker.Fire(self,0);
			invoker.Fire(self,1);
		}
		TNT1 A 1{
			A_Light0();
			double shotpower=invoker.shotpower;
			double mlt=(invoker.bplayingid?0.6:-0.6)*shotpower;
			double mlt2=-3.*shotpower;
			A_MuzzleClimb(mlt,mlt2,mlt,mlt2);
		}goto flasheither;
	recoil:
		#### K 1;
		goto ready;

	altreload:
		#### A 0{
			if(
				countinv("HDShellAmmo")
				&&(
					invoker.weaponstatus[SLAYS_CHAMBER1]<2
					||invoker.weaponstatus[SLAYS_CHAMBER2]<2
				)
			)
				invoker.weaponstatus[0]|=SLAYF_FROMPOCKETS;
			else setweaponstate("nope");
		}goto reloadstart;
	reload:
		#### A 0{
			if(
				invoker.weaponstatus[SLAYS_CHAMBER1]>1&&
				invoker.weaponstatus[SLAYS_CHAMBER2]>1
			)setweaponstate("reloadss");

			invoker.weaponstatus[0]&=~SLAYF_UNLOADONLY;
			if(invoker.weaponstatus[SHOTS_SIDESADDLE]>0)
				invoker.weaponstatus[0]&=~SLAYF_FROMPOCKETS;
			else if(countinv("HDShellAmmo"))
				invoker.weaponstatus[0]|=SLAYF_FROMPOCKETS;
			else setweaponstate("nope");
		}goto reloadstart;
	reloadstart:
	unloadstart:
		#### K 2 offset(0,34) EmptyHand();
		#### K 1 offset(0,40);
		#### K 3 offset(0,46);
		#### K 5 offset(0,47) A_StartSound("weapons/sshoto",8);
		#### B 4 offset(0,46) A_MuzzleClimb(
			frandom(0.6,1.2),frandom(0.6,1.2),
			frandom(0.6,1.2),frandom(0.6,1.2),
			frandom(1.2,2.4),frandom(1.2,2.4)
		);
		#### C 3 offset(0,36){
			//eject whatever is already loaded
			for(int i=0;i<2;i++){
				int chm=invoker.weaponstatus[SLAYS_CHAMBER1+i];
				invoker.weaponstatus[SLAYS_CHAMBER1+i]=0;
				if(chm>1){
					if(health<90&&countinv("IsMoving"))A_SpawnItemEx("HDFumblingShell",
						cos(pitch)*5,-1,height-7-sin(pitch)*5,
						cos(pitch-45)*cos(angle+random(-2,2))*random(1,4)+vel.x,
						cos(pitch-45)*sin(angle+random(-2,2))*random(1,4)+vel.y,
						-sin(pitch-45)*random(1,4)+vel.z,
						0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
					);else A_SpawnItemEx("HDUnspentShell",
						cos(pitch)*5,0,height-7-sin(pitch)*5,
						vel.x,vel.y,vel.z+1,
						0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
					);
				}else if(chm==1)A_SpawnItemEx("HDSpentShell",
					cos(pitch)*5,0,height-7-sin(pitch)*5,
					cos(pitch-45)*cos(angle+random(-2,2))*random(1,4)+vel.x,
					cos(pitch-45)*sin(angle+random(-2,2))*random(1,4)+vel.y,
					-sin(pitch-45)*random(1,4)+vel.z,
					0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}
		}
		#### C 2 offset(1,34);
		#### C 2 offset(2,34);
		#### C 2 offset(4,34);
		#### C 8 offset(0,36){
			if(invoker.weaponstatus[0]&SLAYF_UNLOADONLY){
				setweaponstate("unloadend");
				return;
			}

			//play animation to search pockets as appropriate
			if(invoker.weaponstatus[0]&SLAYF_FROMPOCKETS)
				A_StartSound("weapons/pocket",9);
				else setweaponstate("reloadnopocket");
		}
		#### C 4 offset(2,35);
		#### C 4 offset(0,35);
		#### C 4 offset(0,34);
	reloadnopocket:
		#### D 5 offset(1,35);
		#### D 2 offset(0,36);
		#### E 2 offset(0,40);
		#### E 1 offset(0,46);
		#### E 2 offset(0,54);

		TNT1 A 4{
			//take up to 2 shells in hand
			int ssh=0;
			if(invoker.weaponstatus[0]&SLAYF_FROMPOCKETS){
				ssh=min(2,countinv("HDShellAmmo"));
				if(ssh>0)A_TakeInventory("HDShellAmmo",ssh);
			}else{
				ssh=min(2,invoker.weaponstatus[SHOTS_SIDESADDLE]);
				invoker.weaponstatus[SHOTS_SIDESADDLE]-=ssh;
			}

			//if the above leaves you with nothing, abort
			if(ssh<1){
				A_SetTics(0);
				return;
			}

			//transfer from hand to chambers
			ssh--;
			while(ssh>=0){
				invoker.weaponstatus[SLAYS_CHAMBER2-ssh]=2;
				ssh--;
			}
		}
		TNT1 A 4 A_StartSound("weapons/sshotl",8);
		SH2G B 2 offset(0,46);
		#### B 1 offset(0,42);
		#### K 2 offset(0,42) A_StartSound("weapons/sshotc",8);
		#### A 2;
		goto ready;
	unloadend:
		SH2G C 5 A_StartSound("weapons/sshotl",8,CHANF_OVERLAP);
		#### B 2 offset(0,46);
		#### B 1 offset(0,42);
		#### K 2 offset(0,42) A_StartSound("weapons/sshotc",8);
		#### A 1;
		goto nope;

	reloadss:
		#### A 0 A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]>=12,"nope");
		#### A 1 offset(1,34);
		#### A 2 offset(2,34);
		#### A 3 offset(3,36);
	reloadssrestart:
		#### A 6 offset(3,35);
		#### A 9 offset(4,34) A_StartSound("weapons/pocket",9);
	reloadssloop1:
		#### A 0{
			if(invoker.weaponstatus[SHOTS_SIDESADDLE]>=12)setweaponstate("reloadssend");

			//load shells into hand
			int ssh=min(3,countinv("HDShellAmmo"));
			if(ssh<1){
				setweaponstate("reloadssend");
				return;
			}
			ssh=min(3,ssh,max(1,health/20),12-invoker.weaponstatus[SHOTS_SIDESADDLE]);
			invoker.weaponstatus[SHOTS_SIDESADDLE]+=ssh;
			A_TakeInventory("HDShellAmmo",ssh,TIF_NOTAKEINFINITE);
		}
	reloadssend:
		#### A 4 offset(3,34);
		#### A 0{
			if(
				invoker.weaponstatus[SHOTS_SIDESADDLE]<12
				&&(pressingreload()||pressingaltreload())
				&&countinv("HDShellAmmo")
			)setweaponstate("reloadssrestart");
		}
		#### A 3 offset(2,34);
		#### A 1 offset(1,34) emptyhand(careful:true);
		goto nope;
	unloadss:
		#### A 0 EmptyHand();
		#### A 2 offset(2,34) A_JumpIf(invoker.weaponstatus[SHOTS_SIDESADDLE]<1,"nope");
		#### A 1 offset(3,36);
	unloadssloop1:
		#### A 4 offset(4,36);
		#### A 2 offset(5,37) A_UnloadSideSaddle();
		#### A 3 offset(4,36){	//decide whether to loop
			if(
				invoker.weaponstatus[SHOTS_SIDESADDLE]>0
				&&!pressingfire()
				&&!pressingaltfire()
				&&!pressingreload()
			)setweaponstate("unloadssloop1");
		}
		#### A 3 offset(4,35);
		#### A 2 offset(3,35);
		#### A 1 offset(2,34);
		goto nope;
	unload:
		#### K 2 offset(0,34){
			if(invoker.weaponstatus[SHOTS_SIDESADDLE]>0)setweaponstate("unloadss");
			else invoker.weaponstatus[0]|=SLAYF_UNLOADONLY;
		}goto unloadstart;

	cannibalize:
		#### A 0 EmptyHand();
		#### A 2 offset(0,36) A_JumpIf(!countinv("Hunter"),"nope");
		#### A 2 offset(0,40) A_StartSound("weapons/pocket",9);
		#### A 8 offset(0,42);
		#### A 8 offset(0,44);
		#### A 8 offset(0,42);
		#### A 2 offset(0,36) A_CannibalizeOtherShotgun();
		goto ready;

	spawn:
		SLAY ABCDEFG -1 nodelay{
			int ssh=invoker.weaponstatus[SHOTS_SIDESADDLE];
			if(ssh>=11)frame=0;
			else if(ssh>=9)frame=1;
			else if(ssh>=7)frame=2;
			else if(ssh>=5)frame=3;
			else if(ssh>=3)frame=4;
			else if(ssh>=1)frame=5;
			else frame=6;
		}
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[SLAYS_CHAMBER1]=2;
		weaponstatus[SLAYS_CHAMBER2]=2;
		weaponstatus[SHOTS_SIDESADDLE]=12;
		if(!idfa){
			weaponstatus[SLAYS_CHOKE1]=7;
			weaponstatus[SLAYS_CHOKE2]=7;
		}
		handshells=0;
	}
	override void loadoutconfigure(string input){
		int choke=min(getloadoutvar(input,"lchoke",1),7);
		if(choke>=0)weaponstatus[SLAYS_CHOKE1]=choke;
		choke=min(getloadoutvar(input,"rchoke",1),7);
		if(choke>=0)weaponstatus[SLAYS_CHOKE2]=choke;
	}
}
enum slayerstatus{
	SLAYF_UNLOADONLY=1,
	SLAYF_DOUBLE=2,
	SLAYF_FROMPOCKETS=4,

	SLAYS_CHAMBER1=1,
	SLAYS_CHAMBER2=2,
	//3 is for side saddles
	SLAYS_HEAT1=4,
	SLAYS_HEAT2=5,
	SLAYS_CHOKE1=6,
	SLAYS_CHOKE2=7
};

class SlayerRandom:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			let ggg=Slayer(spawn("Slayer",pos,ALLOW_REPLACE));
			if(!ggg)return;
			ggg.special=special;
			ggg.vel=vel;
			if(!random(0,7)){
				ggg.weaponstatus[SLAYS_CHOKE1]=random(random(0,7),7);
				ggg.weaponstatus[SLAYS_CHOKE2]=random(random(0,7),7);
			}
		}stop;
	}
}
