// ------------------------------------------------------------
// ZM66 4.26mm UAC Standard Automatic Rifle
// ------------------------------------------------------------
const HDCONST_ZM66COOKOFF=21;
class ZM66AssaultRifle:HDWeapon{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "ZM66 Rifle (All)"
		//$Sprite "RIGLA0"

		+hdweapon.fitsinbackpack
		weapon.selectionorder 20;
		weapon.slotnumber 4;
		inventory.pickupsound "misc/w_pkup";
		inventory.pickupmessage "You got the assault rifle!";
		scale 0.7;
		weapon.bobrangex 0.22;
		weapon.bobrangey 0.9;
		obituary "%o was assaulted by %k.";
		hdweapon.refid HDLD_ZM66GL;
		tag "ZM66 assault rifle";
		inventory.icon "RIGLA0";
	}
	override void tick(){
		super.tick();
		drainheat(ZM66S_HEAT,12);
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override void postbeginplay(){
		super.postbeginplay();
		barrellength=25; //look at the sprites - GL does not extend beyond muzzle
		if(weaponstatus[0]&ZM66F_NOLAUNCHER){
			barrelwidth=0.5;
			barreldepth=1;
			weaponstatus[0]&=~(ZM66F_GLMODE|ZM66F_GRENADELOADED);
			refid=(weaponstatus[0]&ZM66F_NOFIRESELECT)?HDLD_ZM66SMI:HDLD_ZM66AUT;
		}else{
			barrelwidth=1;
			barreldepth=3;
		}
	}
	override double gunmass(){
		if(weaponstatus[0]&ZM66F_NOLAUNCHER){
			return 6.2+weaponstatus[ZM66S_MAG]*0.02;
		}else{
			return 7.7+weaponstatus[ZM66S_MAG]*0.01+(weaponstatus[0]&ZM66F_GRENADELOADED?1.:0.);
		}
	}
	override void GunBounce(){
		super.GunBounce();
		if(!random(0,5))weaponstatus[0]&=~ZM66F_CHAMBERBROKEN;
	}
	override void OnPlayerDrop(){
		if(!random(0,15))weaponstatus[0]|=ZM66F_CHAMBERBROKEN;
		if(owner&&weaponstatus[ZM66S_HEAT]>HDCONST_ZM66COOKOFF)owner.dropinventory(self);
	}
	override string pickupmessage(){
		if(weaponstatus[0]&ZM66F_NOFIRESELECT)return "Picked up a semi-automatic weapon. Time for some carnage!";
		return super.pickupmessage();
	}
	override string,double getpickupsprite(){
		string spr;
		int wepstat0=weaponstatus[0];
		if(wepstat0&ZM66F_NOLAUNCHER){
			if(wepstat0&ZM66F_NOFIRESELECT)
				spr="RIFS";
			else spr="RIFL";
		}else{
			if(wepstat0&ZM66F_NOFIRESELECT)
				spr="RIGS";
			else spr="RIGL";
		}

		//set to no-mag frame
		if(weaponstatus[ZM66S_MAG]<0)spr=spr.."D";
		else spr=spr.."A";

		return spr.."0",1.;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			int nextmagloaded=sb.GetNextLoadMag(hdmagammo(hpl.findinventory("HD4mMag")));
			if(nextmagloaded>50){
				sb.drawimage("ZMAGA0",(-46,-3),sb.DI_SCREEN_CENTER_BOTTOM,scale:(2,2));
			}else if(nextmagloaded<1){
				sb.drawimage("ZMAGC0",(-46,-3),sb.DI_SCREEN_CENTER_BOTTOM,alpha:nextmagloaded?0.6:1.,scale:(2,2));
			}else sb.drawbar(
				"ZMAGNORM","ZMAGGREY",
				nextmagloaded,50,
				(-46,-3),-1,
				sb.SHADER_VERT,sb.DI_SCREEN_CENTER_BOTTOM
			);
			sb.drawnum(hpl.countinv("HD4mMag"),-43,-8,sb.DI_SCREEN_CENTER_BOTTOM,font.CR_BLACK);
			if(!(hdw.weaponstatus[0]&ZM66F_NOLAUNCHER)){
				sb.drawimage("ROQPA0",(-62,-4),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.6,0.6));
				sb.drawnum(hpl.countinv("HDRocketAmmo"),-56,-8,sb.DI_SCREEN_CENTER_BOTTOM,font.CR_BLACK);
			}
		}

		if(!(hdw.weaponstatus[0]&ZM66F_NOFIRESELECT))
		sb.drawwepcounter(hdw.weaponstatus[ZM66S_AUTO],
			-22,-10,"RBRSA3A7","STFULAUT","STBURAUT"
		);
		if(hdw.weaponstatus[0]&ZM66F_GRENADELOADED)sb.drawwepdot(-16,-13,(4,2.6));
		int lod=clamp(hdw.weaponstatus[ZM66S_MAG]%100,0,50);
		sb.drawwepnum(lod,50);
		if(hdw.weaponstatus[0]&ZM66F_CHAMBER){
			sb.drawwepdot(-16,-10,(3,1));
			lod++;
		}
		if(hdw.weaponstatus[ZM66S_MAG]>100)lod=random[shitgun](10,99);
		sb.drawnum(lod,-16,-22,sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,Font.CR_RED);
		if(hdw.weaponstatus[0]&ZM66F_GLMODE){
			int ab=hdw.airburst;
			sb.drawnum(ab,
				-30,-22,sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,
				ab?Font.CR_WHITE:Font.CR_DARKGRAY
			);
			sb.drawwepdot(-30,-42+min(16,ab/10),(4,1));
			sb.drawwepdot(-30,-26,(1,16));
			sb.drawwepdot(-32,-26,(1,16));
		}else sb.drawnum(hdw.weaponstatus[ZM66S_ZOOM],
			-30,-22,sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,Font.CR_DARKGRAY
		);
	}
	override string gethelptext(){
		bool gl=!(weaponstatus[0]&ZM66F_NOLAUNCHER);
		bool glmode=gl&&(weaponstatus[0]&ZM66F_GLMODE);
		return
		WEPHELP_FIRESHOOT
		..(gl?(WEPHELP_ALTFIRE..(glmode?("  Rifle mode\n"):("  GL mode\n"))):"")
		..WEPHELP_RELOAD.."  Reload mag\n"
		..(gl?(WEPHELP_ALTRELOAD.."  Reload GL\n"):"")
		..(glmode?(WEPHELP_FIREMODE.."+"..WEPHELP_UPDOWN.."  Airburst\n")
			:(
			((weaponstatus[0]&ZM66F_NOFIRESELECT)?"":WEPHELP_FIREMODE.."  Semi/Auto/Burst\n")
			..WEPHELP_ZOOM.."+"..WEPHELP_FIREMODE.."+"..WEPHELP_UPDOWN.."  Zoom\n"))
		..WEPHELP_MAGMANAGER
		..WEPHELP_UNLOAD.."  Unload "..(glmode?"GL":"magazine")
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc,string whichdot
	){
		int scaledyoffset=47;
		if(hdw.weaponstatus[0]&ZM66F_GLMODE)sb.drawgrenadeladder(hdw.airburst,bob);
		else{
			double dotoff=max(abs(bob.x),abs(bob.y));
			if(dotoff<20){
				sb.drawimage(
					whichdot,(0,0)+bob*1.6,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					alpha:0.8-dotoff*0.04
				);
			}
			sb.drawimage(
				"riflsite",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
			);
			if(scopeview){
				double degree=(hdw.weaponstatus[ZM66S_ZOOM])*0.1;
				texman.setcameratotexture(hpc,"HDXHCAM3",degree);
				sb.drawimage(
					"HDXHCAM3",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					scale:(0.31,0.31)
				);
				int scaledwidth=57;
				int cx,cy,cw,ch;
				[cx,cy,cw,ch]=screen.GetClipRect();
				sb.SetClipRect(
					-28+bob.x,19+bob.y,scaledwidth,scaledwidth,
					sb.DI_SCREEN_CENTER
				);
				sb.drawimage(
					"scophole",(0,scaledyoffset)+bob*3,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					scale:(0.78,0.78)
				);
				sb.SetClipRect(cx,cy,cw,ch);
				sb.drawimage(
					"zm66scop",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					scale:(0.82,0.82)
				);
				sb.drawnum(degree*10,
					3+bob.x,74+bob.y,sb.DI_SCREEN_CENTER,Font.CR_BLACK
				);
				sb.drawimage(
					"BLETA0",(0,78)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					alpha:0.6,scale:(1.3,1.3)
				);
			}
		}
	}
	override double weaponbulk(){
		double blx=90;
		if(!(weaponstatus[0]&ZM66F_NOLAUNCHER)){
			blx+=25;
			if(weaponstatus[0]&ZM66F_GRENADELOADED)blx+=ENC_ROCKETLOADED;
		}
		int mgg=weaponstatus[ZM66S_MAG];
		return blx+(mgg<0?0:(ENC_426MAG_LOADED+mgg*ENC_426_LOADED));
	}
	override void failedpickupunload(){
		failedpickupunloadmag(ZM66S_MAG,"HD4mMag");
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			if(owner.countinv("FourMilAmmo"))owner.A_DropInventory("FourMilAmmo",amt*50);
			else{
				double angchange=(weaponstatus[0]&ZM66F_NOLAUNCHER)?0:-10;
				if(angchange)owner.angle-=angchange;
				owner.A_DropInventory("HD4mMag",amt);
				if(angchange){
					owner.angle+=angchange*2;
					owner.A_DropInventory("HDRocketAmmo",amt);
					owner.angle-=angchange;
				}
			}
		}
	}
	override void ForceBasicAmmo(){
		owner.A_TakeInventory("FourMilAmmo");
		owner.A_TakeInventory("HD4mMag");
		owner.A_GiveInventory("HD4mMag");
		if(!(weaponstatus[0]&ZM66F_NOLAUNCHER)){
			owner.A_TakeInventory("DudRocketAmmo");
			owner.A_SetInventory("HDRocketAmmo",1);
		}
	}
	action bool brokenround(){
		if(!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBERBROKEN)){
			int hht=invoker.weaponstatus[ZM66S_HEAT];
			hht*=hht;hht>>=10;
			int rnd=
				(invoker.owner?1:10)
				+max(invoker.weaponstatus[ZM66S_AUTO],hht)
				+(invoker.weaponstatus[ZM66S_MAG]>100?10:0);
			if(random(0,2000)<rnd){
				invoker.weaponstatus[ZM66S_FLAGS]|=ZM66F_CHAMBERBROKEN;
			}
		}return invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBERBROKEN;
	}
	states{
	ready:
		RIFG A 1{
			if(
				invoker.weaponstatus[ZM66S_HEAT]>HDCONST_ZM66COOKOFF    
				&&invoker.weaponstatus[0]&ZM66F_CHAMBER
				&&!(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
			){
				setweaponstate("cookoff");
				return;
			}else if(pressingzoom())A_ZoomAdjust(ZM66S_ZOOM,16,70);
			else A_WeaponReady(WRF_ALL);
			if(invoker.weaponstatus[ZM66S_AUTO]>2)invoker.weaponstatus[ZM66S_AUTO]=2;  
		}goto readyend;
	firemode:
		RIFG A 0 A_JumpIf(invoker.weaponstatus[0]&ZM66F_GLMODE,"abadjust");
		RIFG A 1{
			if(invoker.weaponstatus[0]&ZM66F_NOFIRESELECT){
				invoker.weaponstatus[ZM66S_AUTO]=0;
				return;
			}
			if(invoker.weaponstatus[ZM66S_AUTO]>=2)invoker.weaponstatus[ZM66S_AUTO]=0;  
			else invoker.weaponstatus[ZM66S_AUTO]++;
			A_WeaponReady(WRF_NONE);
		}goto nope;


	select0:
		RIFG A 0{
			invoker.weaponstatus[0]&=~ZM66F_GLMODE;
			if(invoker.weaponstatus[0]&ZM66F_NOLAUNCHER){
				invoker.weaponstatus[0]&=~ZM66F_GRENADELOADED;
				setweaponstate("select0small");
			}
		}goto select0big;
	deselect0:
		RIFG A 0{
			if(
				invoker.weaponstatus[ZM66S_HEAT]>HDCONST_ZM66COOKOFF      
				&&!(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
				&&(
					invoker.weaponstatus[ZM66S_MAG]||
					invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER
				)
			){
				DropInventory(invoker);
				return;
			}
			if(invoker.weaponstatus[0]&ZM66F_NOLAUNCHER)setweaponstate("deselect0small");
		}goto deselect0big;
	flash:
		RIFF A 1 bright{
			A_Light1();
			HDFlashAlpha(-16);
			A_PlaySound("weapons/rifle",CHAN_WEAPON);
			A_ZoomRecoil(max(0.95,1.-0.05*min(invoker.weaponstatus[ZM66S_AUTO],3)));

			//shoot the bullet
			//copypaste any changes to spawnshoot as well!
			double brnd=invoker.weaponstatus[ZM66S_HEAT]*0.01;
			HDBulletActor.FireBullet(self,"HDB_426",
				spread:brnd>1.2?brnd:0
			);

			A_MuzzleClimb(
				-frandom(0.1,0.1),-frandom(0,0.1),
				-0.2,-frandom(0.3,0.4),
				-frandom(0.4,1.4),-frandom(1.3,2.6)
			);

			invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_CHAMBER;
			invoker.weaponstatus[ZM66S_HEAT]+=random(3,5);
			A_AlertMonsters();
		}
		goto lightdone;


	fire:
		RIFG A 2{
			if(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_GLMODE)setweaponstate("firefrag");
			else if(invoker.weaponstatus[ZM66S_AUTO]>0)A_SetTics(3);
		}goto shootgun;
	hold:
		RIFG A 0 A_JumpIf(invoker.weaponstatus[0]&ZM66F_GLMODE,"FireFrag");
		RIFG A 0 A_JumpIf(invoker.weaponstatus[0]&ZM66F_NOFIRESELECT,"nope");
		RIFG A 0 A_JumpIf(invoker.weaponstatus[ZM66S_AUTO]>4,"nope");
		RIFG A 0 A_JumpIf(invoker.weaponstatus[ZM66S_AUTO],"shootgun");
	althold:
		---- A 1{
			if(
				invoker.weaponstatus[ZM66S_HEAT]>HDCONST_ZM66COOKOFF      
				&&!(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
				&&invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER
			)setweaponstate("cookoff");
			else A_WeaponReady(WRF_NOFIRE);
		}
		---- A 0 A_Refire();
		goto ready;
	jam:
		RIFG B 1 offset(-1,36){
			A_PlaySound("weapons/riflejam",CHAN_WEAPON);
			invoker.weaponstatus[0]|=ZM66F_CHAMBERBROKEN;
			invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_CHAMBER;
		}
		RIFG B 1 offset(1,30) A_PlaySound("weapons/riflejam",6);
		goto nope;

	shootgun:
		RIFG A 1{
			if(
				//can neither shoot nor chamber
				invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN
				||(
					!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER)
					&&invoker.weaponstatus[ZM66S_MAG]<1
				)
			){
				setweaponstate("nope");
			}else if(!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER)){
				//no shot but can chamber
				setweaponstate("chamber_premanual");
			}else{
				A_GunFlash();
				A_WeaponReady(WRF_NONE);
				if(invoker.weaponstatus[ZM66S_AUTO]>=2)invoker.weaponstatus[ZM66S_AUTO]++;  
			}
		}
	chamber:
		RIFG B 0 offset(0,32){
			if(invoker.weaponstatus[ZM66S_MAG]<1){
				setweaponstate("nope");
				return;
			}
			if(invoker.weaponstatus[ZM66S_MAG]%100>0){  
				if(invoker.weaponstatus[ZM66S_MAG]==51)invoker.weaponstatus[ZM66S_MAG]=50;
				invoker.weaponstatus[ZM66S_MAG]--;
				invoker.weaponstatus[ZM66S_FLAGS]|=ZM66F_CHAMBER;
			}else{
				invoker.weaponstatus[ZM66S_MAG]=min(invoker.weaponstatus[ZM66S_MAG],0);
				A_PlaySound("weapons/rifchamber",5);
			}
			if(brokenround()){
				setweaponstate("jam");
				return;
			}
			A_WeaponReady(WRF_NOFIRE); //not WRF_NONE: switch to drop during cookoff
		}
		RIFG B 0 A_JumpIf(
			invoker.weaponstatus[ZM66S_HEAT]>HDCONST_ZM66COOKOFF    
			&&invoker.weaponstatus[0]&ZM66F_CHAMBER
			&&!(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
		,"cookoff");
		RIFG B 0 A_JumpIf(invoker.weaponstatus[ZM66S_AUTO]<1,"nope");
		RIFG B 0 A_JumpIf(invoker.weaponstatus[ZM66S_AUTO]>4,"nope");
		RIFG B 2 A_JumpIf(invoker.weaponstatus[ZM66S_AUTO]>1,1);
		RIFG B 0 A_Refire();
		goto ready;

	cookoffaltfirelayer:
		TNT1 AAA 1{
			if(JustPressed(BT_ALTFIRE)){
				invoker.weaponstatus[0]^=ZM66F_GLMODE;
				A_SetTics(10);
			}else if(JustPressed(BT_ATTACK)&&invoker.weaponstatus[0]&ZM66F_GLMODE)A_Overlay(11,"nadeflash");
		}stop;
	cookoff:
		RIFG A 0{
			A_ClearRefire();
			if(
				(invoker.weaponstatus[ZM66S_MAG]>=0)	//something to detach
				&&(PressingReload()||PressingUnload())	//trying to detach
			){
				A_PlaySound("weapons/rifleclick2",CHAN_WEAPON);
				A_PlaySound("weapons/rifleload",5);
				HDMagAmmo.SpawnMag(self,"HD4mMag",invoker.weaponstatus[ZM66S_MAG]);
				invoker.weaponstatus[ZM66S_MAG]=-1;
			}else if(!(invoker.weaponstatus[0]&ZM66F_NOLAUNCHER))A_Overlay(10,"cookoffaltfirelayer");
			setweaponstate("shootgun");
		}


	chamber_premanual:
		RIFG A 1 offset(0,33);
		RIFG A 1 offset(-3,34);
		RIFG A 1 offset(-8,37);
		goto chamber_manual;

	user3:
		RIFG A 0 A_MagManager("HD4mMag");
		goto ready;

	user4:
	unload:
		RIFG A 0{
			invoker.weaponstatus[ZM66S_FLAGS]|=ZM66F_UNLOADONLY;
			if(
				invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_GLMODE
			){
				setweaponstate("unloadgrenade");
			}else if(
				invoker.weaponstatus[ZM66S_MAG]>=0  
			){
				setweaponstate("unloadmag");
			}else if(
				invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER
				||invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBERBROKEN
			){
				setweaponstate("unloadchamber");
			}else{
				setweaponstate("unloadmag");
			}
		}
	reload:
		RIFG A 0{
			invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_UNLOADONLY;
			if(	//full mag, no jam, not unload-only - why hit reload at all?
				!(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
				&&invoker.weaponstatus[ZM66S_MAG]%100>=50
				&&!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_UNLOADONLY)
			){
				setweaponstate("nope");
			}else if(	//if jammed, treat as unloading
				invoker.weaponstatus[ZM66S_MAG]<0
				&&invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN
			){
				invoker.weaponstatus[ZM66S_FLAGS]|=ZM66F_UNLOADONLY;
				setweaponstate("unloadchamber");
			}else if(!HDMagAmmo.NothingLoaded(self,"HD4mMag")){
				setweaponstate("unloadmag");
			}
		}goto nope;
	unloadmag:
		RIFG A 1 offset(0,33);
		RIFG A 1 offset(-3,34);
		RIFG A 1 offset(-8,37);
		RIFG B 2 offset(-11,39){
			if(	//no mag, skip unload
				invoker.weaponstatus[ZM66S_MAG]<0
			){
				setweaponstate("magout");
			}
			if(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
				invoker.weaponstatus[ZM66S_FLAGS]|=ZM66F_UNLOADONLY;
			A_SetPitch(pitch-0.3,SPF_INTERPOLATE);
			A_SetAngle(angle-0.3,SPF_INTERPOLATE);
			A_PlaySound("weapons/rifleclick2",CHAN_WEAPON);
		}
		RIFG B 4 offset(-12,40){
			A_SetPitch(pitch-0.3,SPF_INTERPOLATE);
			A_SetAngle(angle-0.3,SPF_INTERPOLATE);
			A_PlaySound("weapons/rifleload",CHAN_WEAPON);
		}
		RIFG B 20 offset(-14,44){
			int inmag=invoker.weaponstatus[ZM66S_MAG]%100;
			invoker.weaponstatus[ZM66S_MAG]=-1;
			if(
				!PressingUnload()&&!PressingReload()
				||A_JumpIfInventory("HD4mMag",0,"null")
			){
				HDMagAmmo.SpawnMag(self,"HD4mMag",inmag);
				A_SetTics(1);
			}else{
				HDMagAmmo.GiveMag(self,"HD4mMag",inmag);
				A_PlaySound("weapons/pocket",CHAN_WEAPON);
				if(inmag<51)A_Log(HDCONST_426MAGMSG,true);
			}
		}
	magout:
		RIFG B 0{
			if(
				invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_UNLOADONLY
				||!countinv("HD4mMag")
			)setweaponstate("reloadend");
		} //fallthrough to loadmag
	loadmag:
		---- A 12{
			let zmag=HD4mMag(findinventory("HD4mMag"));
			if(!zmag){setweaponstate("reloadend");return;}
			A_PlaySound("weapons/pocket",CHAN_WEAPON);
			if(zmag.DirtyMagsOnly())invoker.weaponstatus[0]|=ZM66F_LOADINGDIRTY;
			else{
				invoker.weaponstatus[0]&=~ZM66F_LOADINGDIRTY;
				A_SetTics(10);
			}
		}
		---- A 2 A_JumpIf(invoker.weaponstatus[0]&ZM66F_LOADINGDIRTY,"loadmagdirty");
	loadmagclean:
		RIFG B 8 offset(-15,45)A_PlaySound("weapons/rifleload",CHAN_WEAPON);
		RIFG B 1 offset(-14,44){
			let zmag=HD4mMag(findinventory("HD4mMag"));
			if(!zmag){setweaponstate("reloadend");return;}
			if(zmag.DirtyMagsOnly()){
				setweaponstate("loadmagdirty");
				return;
			}
			invoker.weaponstatus[ZM66S_MAG]=zmag.TakeMag(true);
			A_PlaySound("weapons/rifleclick2",CHAN_WEAPON);
		}goto chamber_manual;
	loadmagdirty:
		RIFG B 0{
			if(PressingReload())invoker.weaponstatus[0]|=ZM66F_STILLPRESSINGRELOAD;
			else invoker.weaponstatus[0]&=~ZM66F_STILLPRESSINGRELOAD;
		}
		RIFG B 3 offset(-15,45)A_PlaySound("weapons/rifleload",CHAN_WEAPON);
		RIFG B 1 offset(-15,42)A_WeaponMessage(HDCONST_426MAGMSG,70);
		RIFG BBBBBBBAAAA 1 offset(-15,41){
			bool prr=PressingReload();
			if(
				prr
				&&!(invoker.weaponstatus[0]&ZM66F_STILLPRESSINGRELOAD)
			){
				setweaponstate("reallyloadmagdirty");
			}
			else if(!PressingReload())invoker.weaponstatus[0]&=~ZM66F_STILLPRESSINGRELOAD;
		}
		goto nope;
	reallyloadmagdirty:
		RIFG B 1 offset(-14,44)A_PlaySound("weapons/rifleclick2",CHAN_WEAPON);
		RIFG A 8 offset(-18,50){
			let zmag=HD4mMag(findinventory("HD4mMag"));
			if(!zmag){setweaponstate("reloadend");return;}
			invoker.weaponstatus[ZM66S_MAG]=zmag.TakeMag(true)+100;
			A_MuzzleClimb(
				-frandom(0.4,0.6),frandom(2.,3.)
				-frandom(0.2,0.3),frandom(1.,1.6)
			);
			A_PlaySound("weapons/rifleclick2",6);
			A_PlaySound("weapons/smack",7);

			string realmessage=HDCONST_426MAGMSG;
			realmessage=realmessage.left(random(13,20));
			realmessage.appendformat("\cgFUCK YOURSELF. \cj--mgmt.");
			A_WeaponMessage(realmessage,70);
		}
		RIFG A 4 offset(-17,49);
		goto chamber_manual;
	chamber_manual:
		RIFG A 4 offset(-15,43){
			if(!invoker.weaponstatus[ZM66S_MAG]%100)invoker.weaponstatus[ZM66S_MAG]=0;
			if(
				!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER)
				&& !(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER)
				&& invoker.weaponstatus[ZM66S_MAG]%100>0
			){
				A_PlaySound("weapons/rifleclick");
				if(invoker.weaponstatus[ZM66S_MAG]==51)invoker.weaponstatus[ZM66S_MAG]=49;
				else invoker.weaponstatus[ZM66S_MAG]--;
				invoker.weaponstatus[ZM66S_FLAGS]|=ZM66F_CHAMBER;
				brokenround();
			}else setweaponstate("reloadend");
			A_WeaponBusy();
		}
		goto nope;
		RIFG B 4 offset(-14,45);
		goto reloadend;

	reloadend:
		RIFG B 2 offset(-11,39);
		RIFG A 1 offset(-8,37) A_MuzzleClimb(frandom(0.2,-2.4),frandom(0.2,-1.4));
		RIFG A 1 offset(-3,34);
		RIFG A 1 offset(0,33);
		goto nope;


	unloadchamber:
		RIFG A 1 offset(-3,34);
		RIFG A 1 offset(-9,39);
		RIFG B 3 offset(-19,44) A_MuzzleClimb(frandom(-0.4,0.4),frandom(-0.4,0.4));
		RIFG A 2 offset(-16,42){
			A_MuzzleClimb(frandom(-0.4,0.4),frandom(-0.4,0.4));
			if(
				invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_CHAMBER
				&&!(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
			){
				A_SpawnItemEx("ZM66DroppedRound",0,0,20,
					random(4,7),random(-2,2),random(-2,1),0,
					SXF_NOCHECKPOSITION
				);
				invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_CHAMBER;
				A_PlaySound("weapons/rifleclick2",CHAN_WEAPON);
			}else if(!random(0,4)){
				invoker.weaponstatus[0]&=~ZM66F_CHAMBERBROKEN;
				invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_CHAMBER;
				A_PlaySound("weapons/rifleclick");
				for(int i=0;i<3;i++)A_SpawnItemEx("TinyWallChunk",0,0,20,
					random(4,7),random(-2,2),random(-2,1),0,SXF_NOCHECKPOSITION
				);
				if(!random(0,5))A_SpawnItemEx("HDSmokeChunk",12,0,height-12,4,frandom(-2,2),frandom(2,4));
			}else if(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN){
				A_PlaySound("weapons/smack",CHAN_WEAPON);
			}
		}goto reloadend;

	nadeflash:
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_GRENADELOADED,1);
		stop;
		TNT1 A 2{
			A_FireHDGL();
			invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_GRENADELOADED;
			A_PlaySound("weapons/grenadeshot",CHAN_WEAPON);
			A_ZoomRecoil(0.95);
		}
		TNT1 A 2 A_MuzzleClimb(
			0,0,0,0,
			-1.2,-3.,
			-1.,-2.8
		);
		stop;
	firefrag:
		RIFG B 2;
		RIFG B 3 A_Gunflash("nadeflash");
		goto nope;


	altfire:
		RIFG A 1 offset(0,34){
			if(invoker.weaponstatus[0]&ZM66F_NOLAUNCHER)return;
			invoker.weaponstatus[0]^=ZM66F_GLMODE;
			invoker.airburst=0;
			A_SetCrosshair(21);
			A_SetHelpText();
		}goto nope;


	altreload:
		RIFG A 0{
			invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_UNLOADONLY;
			if(
				!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_NOLAUNCHER)
				&&!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_GRENADELOADED)
				&&countinv("HDRocketAmmo")
			)setweaponstate("unloadgrenade");
		}goto nope;
	unloadgrenade:
		RIFG B 0{
			A_SetCrosshair(21);
			A_MuzzleClimb(-0.3,-0.3);
		}
		RIFG B 2 offset(0,34);
		RIFG B 1 offset(4,38){
			A_MuzzleClimb(-0.3,-0.3);
		}
		RIFG B 2 offset(8,48){
			A_PlaySound("weapons/grenopen",5);
			A_MuzzleClimb(-0.3,-0.3);
			if(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_GRENADELOADED)A_PlaySound("weapons/grenreload",CHAN_WEAPON);
		}
		RIFG B 10 offset(10,49){
			if(!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_GRENADELOADED)){
				if(!(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_UNLOADONLY))A_SetTics(3);
				return;
			}
			invoker.weaponstatus[ZM66S_FLAGS]&=~ZM66F_GRENADELOADED;
			if(
				!PressingUnload()
				||A_JumpIfInventory("HDRocketAmmo",0,"null")
			){
				A_SpawnItemEx("HDRocketAmmo",
					cos(pitch)*10,0,height-10-10*sin(pitch),vel.x,vel.y,vel.z,0,
					SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}else{
				A_PlaySound("weapons/pocket",5);
				A_GiveInventory("HDRocketAmmo",1);
				A_MuzzleClimb(frandom(0.8,-0.2),frandom(0.4,-0.2));
			}
		}
		RIFG B 0 A_JumpIf(invoker.weaponstatus[ZM66S_FLAGS]&ZM66F_UNLOADONLY,"greloadend");
	loadgrenade:
		RIFG B 4 offset(10,50) A_PlaySound("weapons/pocket",CHAN_WEAPON);
		RIFG BBB 8 offset(10,50) A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
		RIFG B 18 offset(8,50){
			A_TakeInventory("HDRocketAmmo",1,TIF_NOTAKEINFINITE);
			invoker.weaponstatus[ZM66S_FLAGS]|=ZM66F_GRENADELOADED;
			A_PlaySound("weapons/grenreload",CHAN_WEAPON);
		}
	greloadend:
		RIFG B 4 offset(4,44) A_PlaySound("weapons/grenopen",CHAN_WEAPON);
		RIFG B 1 offset(0,40);
		RIFG A 1 offset(0,34) A_MuzzleClimb(frandom(-2.4,0.2),frandom(-1.4,0.2));
		goto nope;

	spawn:
		RIFL DCBA 0;
		RIGL DCBA 0;
		RIFS DCBA 0;
		RIGS DA 0;
		---- A 0{
			//don't jam just because
			if(
				!(invoker.weaponstatus[0]&ZM66F_CHAMBER)
				&&!(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
				&&invoker.weaponstatus[ZM66S_MAG]>0
				&&invoker.weaponstatus[ZM66S_MAG]<51
			){
				invoker.weaponstatus[ZM66S_MAG]--;
				invoker.weaponstatus[0]|=ZM66F_CHAMBER;
				brokenround();
			}
		}
	spawn2:
		---- A -1{
			//set sprite
			if(invoker.weaponstatus[0]&ZM66F_NOLAUNCHER){
				if(invoker.weaponstatus[0]&ZM66F_NOFIRESELECT)
					sprite=getspriteindex("RIFSA0");
				else sprite=getspriteindex("RIFLA0");
			}else{
				if(invoker.weaponstatus[0]&ZM66F_NOFIRESELECT)
					sprite=getspriteindex("RIGSA0");
				else sprite=getspriteindex("RIGLA0");
			}

			//set to no-mag frame
			if(invoker.weaponstatus[ZM66S_MAG]<0){
				frame=3;
			}

			if(
				invoker.weaponstatus[0]&ZM66F_CHAMBER
				&&!(invoker.weaponstatus[0]&ZM66F_CHAMBERBROKEN)
				&&invoker.weaponstatus[ZM66S_HEAT]>HDCONST_ZM66COOKOFF  
			){
				setstatelabel("spawnshoot");
			}
		}
	spawnshoot:
		#### C 1 bright light("SHOT"){
			if(invoker.weaponstatus[0]&ZM66F_NOLAUNCHER){
				sprite=getspriteindex("RIFLA0");
			}else sprite=getspriteindex("RIGLA0");

			//shoot the bullet
			//copy any changes to flash as well!
			double brnd=invoker.weaponstatus[ZM66S_HEAT]*0.01;
			HDBulletActor.FireBullet(self,"HDB_426",
				spread:brnd>1.2?invoker.weaponstatus[ZM66S_HEAT]*0.1:0
			);

			A_ChangeVelocity(frandom(-0.4,0.1),frandom(-0.1,0.08),1,CVF_RELATIVE);
			A_PlaySound("weapons/rifle",CHAN_VOICE);
			invoker.weaponstatus[ZM66S_HEAT]+=random(3,5);
			angle+=frandom(2,-7);
			pitch+=frandom(-4,4);
		}
		#### B 2{
			if(invoker.weaponstatus[ZM66S_AUTO]>1)A_SetTics(0);  
			invoker.weaponstatus[0]&=~(ZM66F_CHAMBER|ZM66F_CHAMBERBROKEN);
			if(invoker.weaponstatus[ZM66S_MAG]%100>0){  
				invoker.weaponstatus[ZM66S_MAG]--;
				invoker.weaponstatus[0]|=ZM66F_CHAMBER;
				brokenround();
			}
		}goto spawn2;
	}

	override void InitializeWepStats(bool idfa){
		weaponstatus[ZM66S_FLAGS]|=ZM66F_GRENADELOADED;
		weaponstatus[ZM66S_MAG]=51;
		if(!idfa && !owner){
			weaponstatus[ZM66S_ZOOM]=30;
			weaponstatus[ZM66S_AUTO]=0;
			weaponstatus[ZM66S_HEAT]=0;
		}
		if(idfa)weaponstatus[0]&=~ZM66F_CHAMBERBROKEN;
	}
	override void loadoutconfigure(string input){
		int nogl=getloadoutvar(input,"nogl",1);
		//disable launchers if rocket grenades blacklisted
		string blacklist=hd_blacklist;
		if(blacklist.IndexOf(HDLD_BLOOPER)>=0)nogl=1;
		if(!nogl){
			weaponstatus[0]&=~ZM66F_NOLAUNCHER;
		}else if(nogl>0){
			weaponstatus[0]|=ZM66F_NOLAUNCHER;
			weaponstatus[0]&=~ZM66F_GRENADELOADED;
		}
		if(!(weaponstatus[0]&ZM66F_NOLAUNCHER))weaponstatus[0]|=ZM66F_GRENADELOADED;

		int zoom=getloadoutvar(input,"zoom",3);
		if(zoom>=0)weaponstatus[ZM66S_ZOOM]=clamp(zoom,16,70);

		int semi=getloadoutvar(input,"semi",1);
		if(semi>0){
			weaponstatus[ZM66S_AUTO]=-1;
			weaponstatus[0]|=ZM66F_NOFIRESELECT;
		}else{
			int firemode=getloadoutvar(input,"firemode",1);
			if(firemode>=0){
				weaponstatus[0]&=~ZM66F_NOFIRESELECT;
				weaponstatus[ZM66S_AUTO]=clamp(firemode,0,2);
			}
		}
		if(
			!(weaponstatus[0]&ZM66F_CHAMBER)
			&&weaponstatus[ZM66S_MAG]>0
		){
			weaponstatus[0]|=ZM66F_CHAMBER;
			if(weaponstatus[ZM66S_MAG]==51)weaponstatus[ZM66S_MAG]=49;
			else weaponstatus[ZM66S_MAG]--;
		}
	}
}
enum zm66status{
	ZM66F_CHAMBER=1,
	ZM66F_CHAMBERBROKEN=2,
	ZM66F_DIRTYMAG=4,
	ZM66F_GRENADELOADED=8,
	ZM66F_NOLAUNCHER=16,
	ZM66F_NOFIRESELECT=32,
	ZM66F_GLMODE=64,
	ZM66F_UNLOADONLY=128,
	ZM66F_STILLPRESSINGRELOAD=256,
	ZM66F_LOADINGDIRTY=512,

	ZM66S_FLAGS=0,
	ZM66S_MAG=1, //-1 is empty
	ZM66S_AUTO=2, //2 is burst, 2-5 counts ratchet
	ZM66S_ZOOM=3,
	ZM66S_HEAT=4,
	ZM66S_AIRBURST=5,
	ZM66S_BORESTRETCHED=6,
};



class ZM66Semi:HDWeaponGiver{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "ZM66 Rifle (Semi)"
		//$Sprite "RIFSA0"
		+hdweapon.fitsinbackpack
		hdweapon.refid HDLD_ZM66SMI;
		tag "ZM66 assault rifle (semi only)";
		hdweapongiver.bulk (90.+(ENC_426MAG_LOADED+50.*ENC_426_LOADED));
		hdweapongiver.weapontogive "ZM66AssaultRifle";
		hdweapongiver.weprefid HDLD_ZM66GL;
		hdweapongiver.config "noglsemi";
		inventory.icon "RIFSA0";
	}
}
class ZM66Regular:ZM66Semi{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "ZM66 Rifle (No GL)"
		//$Sprite "RIFLA0"
		hdweapon.refid HDLD_ZM66AUT;
		tag "ZM66 assault rifle (no GL)";
		hdweapongiver.config "noglsemi0";
		inventory.icon "RIFLA0";
	}
}
class ZM66Irregular:ZM66Semi{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "ZM66 Rifle (Semi GL)"
		//$Sprite "RIGSA0"
		hdweapon.refid HDLD_ZM66SGL;
		tag "ZM66 assault rifle (semi with GL)";
		hdweapongiver.config "nogl0semi";
		inventory.icon "RIGSA0";
	}
}
class ZM66Random:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			let zzz=ZM66AssaultRifle(spawn("ZM66AssaultRifle",pos,ALLOW_REPLACE));
			if(!zzz)return;
			zzz.special=special;
			if(!random(0,2)){
				zzz.weaponstatus[0]|=ZM66F_NOLAUNCHER;
				if(!random(0,3))zzz.weaponstatus[0]|=ZM66F_NOFIRESELECT;
			}
			if(zzz.weaponstatus[0]&ZM66F_NOLAUNCHER){
				spawn("HD4mMag",pos+(7,0,0),ALLOW_REPLACE);
				spawn("HD4mMag",pos+(5,0,0),ALLOW_REPLACE);
			}else{
				spawn("HDRocketAmmo",pos+(10,0,0),ALLOW_REPLACE);
				spawn("HDRocketAmmo",pos+(8,0,0),ALLOW_REPLACE);
				spawn("HD4mMag",pos+(5,0,0),ALLOW_REPLACE);
			}
		}stop;
	}
}


class ZM66CookOff:Inventory{
	override void AttachToOwner(actor other){
		let zzz=ZM66AssaultRifle(other.findinventory("ZM66AssaultRifle"));
		zzz.weaponstatus[0]&=~ZM66F_CHAMBERBROKEN;
		zzz.weaponstatus[0]|=ZM66F_CHAMBER;
		zzz.weaponstatus[ZM66S_HEAT]=99;
		zzz.weaponstatus[ZM66S_MAG]=50;
		destroy();
	}
}

