// ------------------------------------------------------------
// Vulcanette
// ------------------------------------------------------------
enum vulcstatus{
	VULCF_FAST=1,
	VULCF_SPINNINGFAST=2,
	VULCF_JUSTUNLOAD=4,
	VULCF_LOADCELL=8,

	VULCF_CHAMBER1=16,
	VULCF_CHAMBER2=32,
	VULCF_CHAMBER3=64,
	VULCF_CHAMBER4=128,
	VULCF_CHAMBER5=256,
	VULCF_ALLCHAMBERED=VULCF_CHAMBER1|VULCF_CHAMBER2|VULCF_CHAMBER3|VULCF_CHAMBER4|VULCF_CHAMBER5,
	VULCF_BROKEN1=512,
	VULCF_BROKEN2=1024,
	VULCF_BROKEN3=2048,
	VULCF_BROKEN4=4096,
	VULCF_BROKEN5=8192,
	VULCF_ALLBROKEN=VULCF_BROKEN1|VULCF_BROKEN2|VULCF_BROKEN3|VULCF_BROKEN4|VULCF_BROKEN5,
	VULCF_ALLCHAMBER1=VULCF_CHAMBER1|VULCF_BROKEN1,

	VULCF_DIRTYMAG=16384,

	VULCS_MAGS=1,
	VULCS_BATTERY=2,
	VULCS_ZOOM=3,
	VULCS_HEAT=4,
	VULCS_BREAKCHANCE=5,
	VULCS_CHANNEL=6,
	VULCS_PERMADAMAGE=7,

	/*
		For counting mags in VULCS_MAGS.
		After each multiple of VULC_MAGBASE:
		0=unloaded, 1=empty, 51=full but seal broken, 52=full and sealed.
		So the first mag is 52, the second mag is 2756, etc.
		Or, in "base 53": 52, 5200, ...
		(I originally tried using base 100 but int.MAX is under 3 billion whereas we'd need 5.3 billion for this.)
	*/
	VULC_MAGBASE=53,
	VULC_MAG_FULLSEALED=VULC_MAGBASE-1,
	VULC_MAGS_MAX=
		(VULC_MAGBASE*VULC_MAGBASE*VULC_MAGBASE*VULC_MAGBASE*VULC_MAG_FULLSEALED)
		+(VULC_MAGBASE*VULC_MAGBASE*VULC_MAGBASE*VULC_MAG_FULLSEALED)
		+(VULC_MAGBASE*VULC_MAGBASE*VULC_MAG_FULLSEALED)
		+(VULC_MAGBASE*VULC_MAG_FULLSEALED)
		+VULC_MAG_FULLSEALED,
};
class Vulcanette:HDWeapon{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Vulcanette"
		//$Sprite "VULCA0"

		scale 0.8;
		inventory.pickupmessage "You got the Vulcanette!";
		weapon.selectionorder 40;
		weapon.slotnumber 4;
		weapon.kickback 24;
		weapon.bobrangex 1.4;
		weapon.bobrangey 3.5;
		weapon.bobspeed 2.1;
		weapon.bobstyle "normal";
		obituary "%o met the budda-budda-budda on the street, and %k killed %h.";
		hdweapon.barrelsize 30,3,4;
		hdweapon.refid HDLD_VULCETT;
		tag "Vulcanette";
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override string pickupmessage(){
		string msg=super.pickupmessage();
		int bc=weaponstatus[VULCS_BREAKCHANCE];
		if(!bc)msg=msg.." It's coward killing time!";
		else if(bc>500)msg=msg.." that might be salvaged for ammo.";
		else if(bc>200)msg=msg.." in dire need of repair.";
		else if(bc>100)msg=msg..". It has seen better days.";
		if(bc>100){
			msg.replace("!","");
			msg.replace("the","a");
		}
		return msg;
	}
	override void tick(){
		super.tick();
		drainheat(VULCS_HEAT,18);
	}
	override inventory createtossable(){
		let ctt=vulcanette(super.createtossable());
		if(!ctt)return null;
		if(ctt.bmissile)ctt.weaponstatus[VULCS_BREAKCHANCE]+=random(0,70);
		return ctt;
	}

	//translate the number from and to the internal stored data in the vulc.
	//REMEMBER: 1 = EMPTY, 2 = ONE SHOT LEFT, 52 = FIFTY PLUS SEAL
	static const int magmultindex[]={
		1,
		VULC_MAGBASE,
		VULC_MAGBASE*VULC_MAGBASE,
		VULC_MAGBASE*VULC_MAGBASE*VULC_MAGBASE,
		VULC_MAGBASE*VULC_MAGBASE*VULC_MAGBASE*VULC_MAGBASE,
		VULC_MAGBASE*VULC_MAGBASE*VULC_MAGBASE*VULC_MAGBASE*VULC_MAGBASE
	};
	static const int chamberflag[]={
		VULCF_CHAMBER1,
		VULCF_CHAMBER2,
		VULCF_CHAMBER3,
		VULCF_CHAMBER4,
		VULCF_CHAMBER5
	};
	int getmagcount(int which){
		if(which>4||which<0)return 0;
		return (weaponstatus[VULCS_MAGS]/magmultindex[which])%VULC_MAGBASE;
	}
	int setmagcount(int which,int count){
		if(which>4||which<0)return 0;
		count=clamp(count,0,VULC_MAG_FULLSEALED);
		int res=weaponstatus[VULCS_MAGS];
		int mags[5];
		int returntotal=0;
		for(int i=0;i<5;i++){
			if(i==which)mags[i]=count;
			else mags[i]=getmagcount(i);
			for(int j=0;j<i;j++){
				mags[i]*=VULC_MAGBASE;
			}
			returntotal+=mags[i];
		}
		weaponstatus[VULCS_MAGS]=returntotal;
		return returntotal;
	}
	override double gunmass(){
		double amt=12+weaponstatus[VULCS_BATTERY]<0?0:1;
		int mags=weaponstatus[VULCS_MAGS];
		for(int i=0;i<5;i++){
			if(
				mags>magmultindex[i]
				||(!i&&mags>0)
			)amt+=3.6;
		}
		return amt;
	}
	override double weaponbulk(){
		double blx=200+(weaponstatus[VULCS_BATTERY]>=0?ENC_BATTERY_LOADED:0);
		int mags=weaponstatus[VULCS_MAGS];
		for(int i=0;i<5;i++){
			if(
				mags>magmultindex[i]
				||(!i&&mags>0)
			)blx+=ENC_426MAG_LOADED+(ENC_426_LOADED*getmagcount(i));
		}
		return blx;
	}
	override string,double getpickupsprite(){return "VULCA0",1.;}
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
			sb.drawbattery(-64,-4,sb.DI_SCREEN_CENTER_BOTTOM,reloadorder:true);
			sb.drawnum(hpl.countinv("HD4mMag"),-43,-8,sb.DI_SCREEN_CENTER_BOTTOM,font.CR_BLACK);
			sb.drawnum(hpl.countinv("HDBattery"),-56,-8,sb.DI_SCREEN_CENTER_BOTTOM,font.CR_BLACK);
		}
		bool bat=hdw.weaponstatus[VULCS_BATTERY]>0;
		int mags=hdw.weaponstatus[VULCS_MAGS];
		for(int i=1;i<5;i++){
			if(
				mags>magmultindex[i]
				||(!i&&mags>0)
			)sb.drawwepdot(-16-i*4,-13,(3,2));
			if(bat&&hdw.weaponstatus[0]&chamberflag[i])sb.drawimage(
				"GREENPXL",(-14,-15+i*2),
				sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TRANSLATABLE|sb.DI_ITEM_RIGHT,
				1,(4,1)
			);
		}
		sb.drawwepnum(
			(hdw.weaponstatus[VULCS_MAGS]%VULC_MAGBASE)-1,
			50,posy:-10
		);
		sb.drawwepcounter(hdw.weaponstatus[0]&VULCF_FAST,
			-28,-16,"blank","STFULAUT"
		);
		if(bat){
			int lod;
			if(hdw.weaponstatus[0]&VULCF_DIRTYMAG)lod=random[shitgun](10,99);
			else lod=clamp((mags%VULC_MAGBASE)-1,0,50);
			sb.drawnum(lod,-20,-22,
				sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,Font.CR_RED
			);
			sb.drawwepnum(hdw.weaponstatus[VULCS_BATTERY],20);
		}else if(!hdw.weaponstatus[VULCS_BATTERY])sb.drawstring(
			sb.mamountfont,"00000",(-16,-8),
			sb.DI_TEXT_ALIGN_RIGHT|sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
			Font.CR_DARKGRAY
		);
		sb.drawnum(hdw.weaponstatus[VULCS_ZOOM],
			-30,-22,
			sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,
			Font.CR_DARKGRAY
		);
	}
	override string gethelptext(){
		return
		WEPHELP_FIRESHOOT
		..WEPHELP_RELOAD.."  Reload mags\n"
		..WEPHELP_ALTRELOAD.."  Reload battery\n"
		..WEPHELP_FIREMODE.."  Switch to "..(weaponstatus[0]&VULCF_FAST?"2100":"700").." RPM\n"
		..WEPHELP_ZOOM.."+"..WEPHELP_FIREMODE.."+"..WEPHELP_UPDOWN.."  Zoom\n"
		..WEPHELP_MAGMANAGER
		..WEPHELP_UNLOADUNLOAD
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc,string whichdot
	){
		if(hpl.countinv("IsMoving")>2){
			sb.drawimage(
				"riflsite",(bob.x,bob.y+48),sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
			);
			return;
		}
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
		int scaledyoffset=47;
		if(scopeview){
			double degree=(hdw.weaponstatus[VULCS_ZOOM])*0.1;
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
				scale:(0.8,0.8)
			);
			sb.drawnum(degree*10,
				3+bob.x,73+bob.y,sb.DI_SCREEN_CENTER,Font.CR_BLACK
			);
			sb.drawimage(
				"BLETA0",(0,77)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				alpha:0.6,scale:(1.3,1.3)
			);
		}
	}
	override void consolidate(){
		CheckBFGCharge(VULCS_BATTERY);
		if(weaponstatus[VULCS_BREAKCHANCE]>0){
			int bc=weaponstatus[VULCS_BREAKCHANCE];
			if(bc>weaponstatus[VULCS_PERMADAMAGE])weaponstatus[VULCS_PERMADAMAGE]+=max(1,bc>>7);
			int oldbc=bc;
			weaponstatus[VULCS_BREAKCHANCE]=random(bc*2/3,bc)+weaponstatus[VULCS_PERMADAMAGE];
			if(!owner)return;
			string msg="You try to unwarp some of the parts of your Vulcanette";
			if(bc>oldbc)msg=msg..", but only made things worse.";
			else if(bc<oldbc*9/10)msg=msg..". It seems to scroll more smoothly now.";
			else msg=msg..", to little if any avail.";
			owner.A_Log(msg,true);
		}
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			if(owner.countinv("FourMilAmmo"))owner.A_DropInventory("FourMilAmmo",50);
			else{
				owner.angle-=10;
				owner.A_DropInventory("HD4mMag",1);
				owner.angle+=20;
				owner.A_DropInventory("HDBattery",1);
				owner.angle-=10;
			}
		}
	}
	override void ForceBasicAmmo(){
		owner.A_TakeInventory("FourMilAmmo");
		owner.A_TakeInventory("HD4mMag");
		owner.A_GiveInventory("HD4mMag",5);
		owner.A_TakeInventory("HDBattery");
		owner.A_GiveInventory("HDBattery");
	}
	states{
	select0:
		GTLG A 0 A_Overlay(2,"droop");
		goto select0bfg;
	deselect0:
		GTLG A 0;
		goto deselect0bfg;

	droop:
		TNT1 A 1{
			if(pitch<frandom(5,8)&&(!gunbraced())){
				if(countinv("IsMoving")>2 && countinv("PowerStrength")<1){    
					A_MuzzleClimb(frandom(-0.1,0.1),
						frandom(0.1,clamp(1-pitch,0.1,0.3)));
				}else{
					A_MuzzleClimb(frandom(-0.06,0.06),
						frandom(0.1,clamp(1-pitch,0.06,0.12)));
				}
			}
		}loop;

	ready:
		GTLG A 1{
			A_SetCrosshair(21);
			if(pressingzoom())A_ZoomAdjust(VULCS_ZOOM,16,70);
			else if(justpressed(BT_FIREMODE|BT_ALTFIRE)){
				invoker.weaponstatus[0]^=VULCF_FAST;
				A_StartSound("weapons/fmswitch",CHAN_WEAPON,CHANF_OVERLAP,0.4);
				A_SetHelpText();
				A_WeaponReady(WRF_NONE);
			}else A_WeaponReady(WRF_ALL);
		}
		goto readyend;

	fire:
		GTLG A 1{
			A_WeaponReady(WRF_NONE);
			if(
				invoker.weaponstatus[VULCS_BATTERY]>0 
				&&!random(0,max(0,700-(invoker.weaponstatus[VULCS_BREAKCHANCE]>>1)))
			)invoker.weaponstatus[VULCS_BATTERY]--;
		}goto shoot;
	hold:
		GTLG A 0{
			if(invoker.weaponstatus[VULCS_BATTERY]<1)setweaponstate("nope");
		}
	shoot:
		GTLG A 2{
			A_WeaponReady(WRF_NOFIRE);
			if(
				invoker.weaponstatus[VULCS_BATTERY]>0    
				&&!random(0,invoker.weaponstatus[0]&VULCF_SPINNINGFAST?200:210)
			)invoker.weaponstatus[VULCS_BATTERY]--;
			invoker.weaponstatus[0]&=~VULCF_SPINNINGFAST;

			//check speed and then shoot
			if(
				invoker.weaponstatus[0]&VULCF_FAST
				&&invoker.weaponstatus[0]&VULCF_CHAMBER1
				&&invoker.weaponstatus[VULCS_BATTERY]>=4
				&&invoker.weaponstatus[VULCS_BREAKCHANCE]<random(100,5000)
			){
				A_SetTics(1);
				invoker.weaponstatus[0]|=VULCF_SPINNINGFAST;
			}else if(invoker.weaponstatus[VULCS_BATTERY]<2){
				A_SetTics(random(3,4));
			}else if(invoker.weaponstatus[VULCS_BATTERY]<3){
				A_SetTics(random(2,3));
			}
			VulcShoot();
			VulcNextRound();
		}
		GTLG B 1{
			A_WeaponReady(WRF_NOFIRE);
			//check speed and then shoot
			if(
				invoker.weaponstatus[0]&VULCF_SPINNINGFAST
				&&invoker.weaponstatus[0]&VULCF_CHAMBER1
			){
				A_SetTics(1);
				VulcShoot(true);
				VulcNextRound();
			}else if(invoker.weaponstatus[VULCS_BATTERY]<2){
				A_SetTics(random(3,4));
			}else if(invoker.weaponstatus[VULCS_BATTERY]<3){
				A_SetTics(random(2,3));
			}
		}
		GTLG B 1{
			A_WeaponReady(WRF_NONE);
			if(invoker.weaponstatus[VULCS_BATTERY]<1)setweaponstate("spindown");
			else A_Refire("holdswap");
		}goto spindown;
	holdswap:
		GTLG A 0{
			if(invoker.getmagcount(0)<2){
				VulcNextMag();
				A_StartSound("weapons/vulcshunt",CHAN_WEAPON,CHANF_OVERLAP);
			}
		}goto hold;
	spindown:
		GTLG B 0{
			A_ClearRefire();
			if(!(invoker.weaponstatus[0]&VULCF_SPINNINGFAST))setweaponstate("nope");
			invoker.weaponstatus[0]&=~VULCF_SPINNINGFAST;
		}
		GTLG AB 1{
			A_WeaponReady(WRF_NONE);
			A_MuzzleClimb(frandom(0.4,0.6),-frandom(0.4,0.6));
		}
		GTLG ABAABB 2 A_WeaponReady(WRF_NOFIRE|WRF_NOSWITCH);
		goto ready;


	flash2:
		VULF B 0;
		goto flashfollow;
	flash:
		VULF A 0;
		goto flashfollow;
	flashfollow:
		---- A 0{
			A_MuzzleClimb(0,0,-frandom(0.1,0.3),-frandom(0.4,0.8));
			A_ZoomRecoil(0.99);
			HDFlashAlpha(invoker.weaponstatus[VULCS_HEAT]*48);
		}
		---- A 1 bright A_Light2();
		goto lightdone;


	reload:
		GTLG A 0{
			if(
				//abort if all mag slots taken or no spare ammo
				(
					invoker.weaponstatus[VULCS_MAGS]>invoker.magmultindex[0]
					&&invoker.weaponstatus[VULCS_MAGS]>invoker.magmultindex[1]
					&&invoker.weaponstatus[VULCS_MAGS]>invoker.magmultindex[2]
					&&invoker.weaponstatus[VULCS_MAGS]>invoker.magmultindex[3]
					&&invoker.weaponstatus[VULCS_MAGS]>invoker.magmultindex[4]
				)
				||!countinv("HD4mMag")
			)setweaponstate("nope");else{
				invoker.weaponstatus[0]&=~(VULCF_JUSTUNLOAD|VULCF_LOADCELL);
				setweaponstate("lowertoopen");
			}
		}
	altreload:
	cellreload:
		GTLG A 0{
			if(
				//abort if full battery loaded or no spares
				invoker.weaponstatus[VULCS_BATTERY]>=20    
				||!countinv("HDBattery")
			)setweaponstate("nope");else{
				invoker.weaponstatus[0]&=~VULCF_JUSTUNLOAD;
				invoker.weaponstatus[0]|=VULCF_LOADCELL;
				setweaponstate("lowertoopen");
			}
		}
	unload:
		GTLG A 0{
			invoker.weaponstatus[0]&=~VULCF_LOADCELL;
			invoker.weaponstatus[0]|=VULCF_JUSTUNLOAD;
			setweaponstate("lowertoopen");
		}
	//what key to use for cellunload???
	cellunload:
		GTLG A 0{
			//abort if no cell to unload
			if(invoker.weaponstatus[VULCS_BATTERY]<0)
			setweaponstate("nope");else{
				invoker.weaponstatus[0]|=VULCF_JUSTUNLOAD;
				invoker.weaponstatus[0]|=VULCF_LOADCELL;
				setweaponstate("uncell");
			}
		}

	//lower the weapon, open it, decide what to do
	lowertoopen:
		GTLG A 2 offset(0,36);
		GTLG A 2 offset(4,38){
			A_StartSound("weapons/rifleclick2",CHAN_WEAPON);
			A_MuzzleClimb(-frandom(1.2,1.8),-frandom(1.8,2.4));
		}
		GTLG A 6 offset(9,41)A_StartSound("weapons/pocket",CHAN_WEAPON);
		GTLG A 8 offset(12,43)A_StartSound("weapons/vulcopen1",CHAN_WEAPON,CHANF_OVERLAP);
		GTLG A 5 offset(10,41)A_StartSound("weapons/vulcopen2",CHAN_WEAPON,CHANF_OVERLAP);
		GTLG A 0{
			if(invoker.weaponstatus[0]&VULCF_LOADCELL)setweaponstate("uncell");
			else if(invoker.weaponstatus[0]&VULCF_JUSTUNLOAD)setweaponstate("unmag");
		}goto loadmag;

	uncell:
		GTLG A 10 offset(11,42){
			int btt=invoker.weaponstatus[VULCS_BATTERY];
			invoker.weaponstatus[VULCS_BATTERY]=-1;
			if(btt<0)setweaponstate("cellout");
			else if(
				!PressingUnload()
				&&!PressingAltReload()
				&&!PressingReload()
			){
				A_SetTics(4);
				HDMagAmmo.SpawnMag(self,"HDBattery",btt);
				
			}else{
				A_StartSound("weapons/pocket",CHAN_WEAPON);
				HDMagAmmo.GiveMag(self,"HDBattery",btt);
			}
		}goto cellout;

	cellout:
		GTLG A 0 offset(10,40) A_JumpIf(invoker.weaponstatus[0]&VULCF_JUSTUNLOAD,"reloadend");
	loadcell:
		GTLG A 0{
			let bbb=HDMagAmmo(findinventory("HDBattery"));
			if(bbb)invoker.weaponstatus[VULCS_BATTERY]=bbb.TakeMag(true);
		}goto reloadend;

	reloadend:
		GTLG A 3 offset(9,41);
		GTLG A 2 offset(6,38);
		GTLG A 3 offset(2,34);
		goto ready;


	unchamber:
		GTLG B 4{
			A_StartSound("weapons/vulcextract",CHAN_AUTO,CHANF_DEFAULT,0.3);
			VulcNextRound();
		}GTLG A 4;
		GTLG A 0 A_JumpIf(PressingUnload(),"unchamber");
		goto nope;
	unmag:
		//if no mags, remove battery
		//if not even battery, remove rounds from chambers
		GTLG A 0{
			if(invoker.weaponstatus[VULCS_MAGS]<1){
				if(invoker.weaponstatus[VULCS_BATTERY]>=0)setweaponstate("cellunload");    
				else setweaponstate("unchamber");
			}
		}
		//first, check if there's a mag2-5.
		//if there's no mag2 but stuff after that, shunt everything over until there is.
		//if there's nothing but mag1, unload mag1.
		GTLG A 6 offset(10,40){
			if(
				!invoker.weaponstatus[0]&VULCF_JUSTUNLOAD
			)setweaponstate("loadmag");
			A_StartSound("weapons/rifleload");
			A_MuzzleClimb(-frandom(1.2,1.8),-frandom(1.8,2.4));
		}
	//remove mag #2 first, #1 only if out of options
	unmagpick:
		GTLG A 0{
			if(invoker.getmagcount(1)>0)setweaponstate("unmag1");    
			else if(
				invoker.getmagcount(2)>0
				||invoker.getmagcount(3)>0
				||invoker.getmagcount(4)>0  
			)setweaponstate("unmagshunt");
			else if(
				invoker.getmagcount(0)>0    
			)setweaponstate("unmag0");
		}goto reloadend;
	unmagshunt:
		GTLG A 0{
			for(int i=0;i<5;i++){
				invoker.setmagcount(i,invoker.getmagcount(i+1));
			}
			A_StartSound("weapons/vulcshunt",CHAN_WEAPON,CHANF_OVERLAP);
		}
		GTLG AB 2 A_MuzzleClimb(-frandom(0.4,0.6),frandom(0.4,0.6));
		goto ready;

	unmag1:
		VULC A 0{
			int mg=invoker.getmagcount(1);
			invoker.setmagcount(1,0);
			if(mg<1){
				setweaponstate("mag1out");
				return;
			}
			if(
				!PressingUnload()
				&&!PressingReload()
			){
				HDMagAmmo.SpawnMag(self,"HD4mMag",mg-1);
				setweaponstate("mag1out");
			}else{
				HDMagAmmo.GiveMag(self,"HD4mMag",mg-1);
				setweaponstate("pocketmag");
			}
		}goto mag1out;
	unmag0:
		VULC A 0{
			int mg=invoker.getmagcount(0);
			invoker.setmagcount(0,0);
			if(mg<1){
				setweaponstate("mag1out");
				return;
			}
			if(
				!PressingUnload()
				&&!PressingReload()
			){
				HDMagAmmo.SpawnMag(self,"HD4mMag",mg-1);
				setweaponstate("mag1out"); //this really is mag1 not mag0
			}else{
				HDMagAmmo.GiveMag(self,"HD4mMag",mg-1);
				setweaponstate("pocketmag");
			}
		}goto reloadend;
	pocketmag:
		GTLG A 0 A_StartSound("weapons/pocket");
		GTLG AA 6 A_MuzzleClimb(frandom(0.4,0.6),-frandom(0.4,0.6));
		goto mag1out;
	mag1out:
		GTLG A 1{
			int starti=(invoker.getmagcount(0)>0)?1:0;
			for(int i=starti;i<5;i++){
				invoker.setmagcount(i,invoker.getmagcount(i+1));
			}
			A_StartSound("weapons/vulcshunt",CHAN_WEAPON,CHANF_OVERLAP);
		}
		GTLG AB 2 A_MuzzleClimb(-frandom(0.4,0.6),frandom(0.4,0.6));
		GTLG A 6{
			if(
				invoker.weaponstatus[VULCS_MAGS]<VULC_MAGBASE
			)setweaponstate("reloadend");
		}goto unmag1;

	loadmag:
		//pick the first empty slot and fill that
		GTLG A 0 A_StartSound("weapons/pocket");
		GTLG AA 6 A_MuzzleClimb(-frandom(0.4,0.6),frandom(-0.4,0.4));
		GTLG A 6 offset(10,41){
			if(HDMagAmmo.NothingLoaded(self,"HD4mMag")){setweaponstate("reloadend");return;}
			int lod=HDMagAmmo(findinventory("HD4mMag")).TakeMag(true);

			int magslot=-1;
			for(int i=0;i<5;i++){
				if(invoker.getmagcount(i)<1){
					magslot=i;
					break;
				}
			}
			if(magslot<0){
				setweaponstate("reloadend");
				return;
			}

			//REMEMBER: IN THE VULC, ADD ONE
			if(lod<51){
				if(!random(0,7)){
					A_StartSound("weapons/vulcforcemag",CHAN_WEAPON,CHANF_OVERLAP);
					lod=min(0,lod-random(0,1));
					A_Log(HDCONST_426MAGMSG,true);
				}
				invoker.setmagcount(magslot,lod+1);
			}else invoker.setmagcount(magslot,VULC_MAG_FULLSEALED);

			A_MuzzleClimb(-frandom(0.4,0.8),-frandom(0.5,0.7));
		}
		GTLG A 8 offset(9,38){
			A_StartSound("weapons/rifleclick",CHAN_WEAPON,CHANF_OVERLAP);
			A_MuzzleClimb(
				-frandom(0.2,0.8),-frandom(0.2,0.3)
				-frandom(0.2,0.8),-frandom(0.2,0.3)
			);
		}
		GTLG A 0{
			if(
				(
					PressingReload()
					||PressingUnload()
					||PressingFire()
					||!countinv("HD4mMag")
				)||(
					invoker.getmagcount(0)>0
					&&invoker.getmagcount(1)>0
					&&invoker.getmagcount(2)>0
					&&invoker.getmagcount(3)>0
					&&invoker.getmagcount(4)>0
				)
			)setweaponstate("reloadend");
		}goto loadmag;

	user3:
		VULC A 0 A_MagManager("HD4mMag");
		goto ready;

	spawn:
		VULC A -1;
	}


	override void InitializeWepStats(bool idfa){
		weaponstatus[VULCS_BATTERY]=20;
		weaponstatus[VULCS_ZOOM]=30;
		weaponstatus[VULCS_MAGS]=VULC_MAGS_MAX;
		if(idfa)weaponstatus[0]|=VULCF_ALLCHAMBERED;
		weaponstatus[0]&=~VULCF_ALLBROKEN;
	}
	override void loadoutconfigure(string input){
		int fast=getloadoutvar(input,"fast",1);
		if(!fast)weaponstatus[0]&=~VULCF_FAST;
		else if(fast>0)weaponstatus[0]|=VULCF_FAST;

		int zoom=getloadoutvar(input,"zoom",3);
		if(zoom>=0)weaponstatus[VULCS_ZOOM]=clamp(zoom,16,70);
	}

	//shooting and cycling actions
	//move this somewhere sensible
	action void VulcShoot(bool flash2=false){
		invoker.weaponstatus[VULCS_BREAKCHANCE]+=random(0,random(0,invoker.weaponstatus[VULCS_HEAT]/256));
		if(
			!(invoker.weaponstatus[0]&VULCF_CHAMBER1)
			||invoker.weaponstatus[0]&VULCF_BROKEN1
		){
			if(invoker.weaponstatus[0]&VULCF_BROKEN1)invoker.weaponstatus[VULCS_BREAKCHANCE]+=random(0,7);
			else if(!random(0,127))invoker.weaponstatus[VULCS_BREAKCHANCE]++;
			if(hd_debug)A_Log("Break chance: "..invoker.weaponstatus[VULCS_BREAKCHANCE]);
			return;
		}
		if(random(random(1,500),5000)<invoker.weaponstatus[VULCS_BREAKCHANCE]){
			setweaponstate("nope");
			return;
		}

		if(flash2)A_GunFlash("flash2");else A_GunFlash("flash");
		A_StartSound("weapons/vulcanette",CHAN_WEAPON,CHANF_OVERLAP);

		int cm=countinv("IsMoving");if(
			invoker.weaponstatus[0]&VULCF_FAST
			&&!countinv("PowerStrength")
		)cm*=2;
		double offx=frandom(-0.1,0.1)*cm;
		double offy=frandom(-0.1,0.1)*cm;

		int heat=min(50,invoker.weaponstatus[VULCS_HEAT]);
		HDBulletActor.FireBullet(self,"HDB_426",zofs:height-8,
			spread:heat>20?heat*0.1:0,
			distantsounder:"DistantVulc"
		);
/*
		actor b=spawn("HDBullet426",pos+(0,0,height-8),ALLOW_REPLACE);
		b.target=self;b.vel+=vel;b.angle=angle+offx;b.pitch=pitch+offy;
		if(heat>20)b.vel+=(frandom(-heat,heat),frandom(-heat,heat),frandom(-heat,heat))*0.1;    
*/
		invoker.weaponstatus[VULCS_HEAT]+=2;

		if(random(0,8192)<min(10,heat))invoker.weaponstatus[VULCS_BATTERY]++;

		invoker.weaponstatus[0]&=~VULCF_ALLCHAMBER1;
	}
	action void VulcNextMag(){
		int thismag=invoker.getmagcount(0);
		if(thismag>0){
			double cp=cos(pitch);double ca=cos(angle+60);
			double sp=sin(pitch);double sa=sin(angle+60);
			actor mmm=HDMagAmmo.SpawnMag(self,"HD4mMag",thismag-1);
			mmm.setorigin(pos+(
				cp*ca*16,
				cp*sa*16,
				height-12-12*sp
			),false);
			mmm.vel=vel+(
				cp*cos(angle+random(55,65)),
				cp*sin(angle+random(55,65)),
				sp
			);
		}
		for(int i=0;i<5;i++){
			invoker.setmagcount(i,invoker.getmagcount(i+1));
		}
		int intothismag=invoker.getmagcount(0);
		if(intothismag&&intothismag!=VULC_MAG_FULLSEALED){
			invoker.weaponstatus[0]|=VULCF_DIRTYMAG;
		}
	}
	action void VulcNextRound(){
		if(
			invoker.weaponstatus[0]&VULCF_CHAMBER1
			||invoker.weaponstatus[0]&VULCF_BROKEN1
		){
			//spit out a misfired, wasted or broken round
			if(invoker.weaponstatus[0]&VULCF_BROKEN1){
				for(int i=0;i<5;i++){
					A_SpawnItemEx("TinyWallChunk",3,0,height-18,
						random(4,7),random(-2,2),random(-2,1),
						-30,SXF_NOCHECKPOSITION
					);
				}
			}else{
				A_SpawnItemEx("ZM66DroppedRound",3,0,height-18,
					random(4,7),random(-2,2),random(-2,1),
					-30,SXF_NOCHECKPOSITION
				);
			}
			A_MuzzleClimb(frandom(0.6,2.4),frandom(1.2,2.4));
		}

		//cycle all chambers
		invoker.weaponstatus[0]&=~VULCF_ALLCHAMBER1;
		if(invoker.weaponstatus[0]&VULCF_BROKEN2)invoker.weaponstatus[0]|=VULCF_BROKEN1;
		else if(invoker.weaponstatus[0]&VULCF_CHAMBER2)invoker.weaponstatus[0]|=VULCF_CHAMBER1;

		invoker.weaponstatus[0]&=~(VULCF_BROKEN2|VULCF_CHAMBER2);
		if(invoker.weaponstatus[0]&VULCF_BROKEN3)invoker.weaponstatus[0]|=VULCF_BROKEN2;
		else if(invoker.weaponstatus[0]&VULCF_CHAMBER3)invoker.weaponstatus[0]|=VULCF_CHAMBER2;

		invoker.weaponstatus[0]&=~(VULCF_BROKEN3|VULCF_CHAMBER3);
		if(invoker.weaponstatus[0]&VULCF_BROKEN4)invoker.weaponstatus[0]|=VULCF_BROKEN3;
		else if(invoker.weaponstatus[0]&VULCF_CHAMBER4)invoker.weaponstatus[0]|=VULCF_CHAMBER3;

		invoker.weaponstatus[0]&=~(VULCF_BROKEN4|VULCF_CHAMBER4);
		if(invoker.weaponstatus[0]&VULCF_BROKEN5)invoker.weaponstatus[0]|=VULCF_BROKEN4;
		else if(invoker.weaponstatus[0]&VULCF_CHAMBER5)invoker.weaponstatus[0]|=VULCF_CHAMBER4;

		invoker.weaponstatus[0]&=~(VULCF_CHAMBER5|VULCF_BROKEN5);
		if(invoker.getmagcount(0)==VULC_MAG_FULLSEALED){
			invoker.setmagcount(0,50); //open the seal
			invoker.weaponstatus[0]&=~VULCF_DIRTYMAG;
		}

		//figure out what's in the mag and load it to the final chamber
		int inmag=invoker.getmagcount(0);
		if(inmag>1){
			A_StartSound("weapons/vulcchamber",CHAN_WEAPON,CHANF_OVERLAP);
			invoker.weaponstatus[0]|=VULCF_CHAMBER5;
			if(random(0,2000)<=
				1+(invoker.weaponstatus[0]&VULCF_DIRTYMAG?(invoker.weaponstatus[0]&VULCF_FAST?13:9):0)
			)invoker.weaponstatus[0]|=VULCF_BROKEN5;
			invoker.setmagcount(0,inmag-1);
		}
	}
}


