// ------------------------------------------------------------
// 7.76mm Reloading Bot
// ------------------------------------------------------------
class AutoReloadingThingy:HDWeapon{
	int powders;
	int brass;
	bool makinground;
	override void beginplay(){
		super.beginplay();
		brass=0;powders=0;makinground=false;
	}
	override void Consolidate(){
		int totalpowder=owner.countinv("FourMilAmmo");
		int totalbrass=owner.countinv("SevenMilBrass");
		int onppowder=totalpowder;
		int onpbrass=totalbrass;
		let bp=hdbackpack(owner.findinventory("hdbackpack"));
		if(bp){
			totalpowder+=bp.getamount("fourmilammo");
			totalbrass+=bp.getamount("sevenmilbrass");
		}
		if(!totalbrass||totalpowder<4)return;
		int canmake=min(totalbrass,totalpowder/4);
		//matter is being lost in this exchange. if you have a backpack you WILL have space.
		int onpspace=HDPickup.MaxGive(owner,"SevenMilAmmo",ENC_776);
		if(!bp)canmake=min(canmake,onpspace);

		//evaluate amounts
		totalpowder-=canmake*4;
		totalbrass-=canmake;
		int didmake=canmake-random(0,canmake/10);

		//deduct inventory
		//remove inv first, then bp
		int deductfrombp=canmake-onpbrass;
		owner.A_TakeInventory("sevenmilbrass",canmake);
		if(deductfrombp>0)bp.addamount("sevenmilbrass",-deductfrombp);
		deductfrombp=canmake*4-onppowder;
		owner.A_TakeInventory("fourmilammo",canmake*4);
		if(deductfrombp>0)bp.addamount("fourmilammo",-deductfrombp);

		//add resulting rounds
		//fill up inv first, then bp
		if(didmake<1)return;
		int bpadd=didmake-onpspace;
		owner.A_GiveInventory("SevenMilAmmo",didmake);
		if(bpadd>0)bp.addamount("sevenmilammo",bpadd);

		owner.A_Log("You reloaded "..didmake.." 7.76mm rounds during your downtime.",true);
	}
	override void actualpickup(actor other,bool silent){
		super.actualpickup(other,silent);
		if(!owner)return;
		while(powders>0){
			powders--;
			if(owner.A_JumpIfInventory("FourMilAmmo",0,"null"))
				owner.A_SpawnItemEx("FourMilAmmo",0,0,owner.height-16,2,0,1);
			else HDF.Give(owner,"FourMilAmmo",1);
		}
		while(brass>0){
			brass--;
			if(owner.A_JumpIfInventory("SevenMilBrass",0,"null"))
				owner.A_SpawnItemEx("SevenMilBrass",0,0,owner.height-16,2,0,1);
			else HDF.Give(owner,"SevenMilBrass",1);
		}
	}
	void A_Chug(){
		A_StartSound("roundmaker/chug1",8);
		A_StartSound("roundmaker/chug2",9);
		vel.z+=randompick(-1,1);
		vel.xy+=(frandom(-0.3,0.3),frandom(-0.3,0.3));
	}
	void A_MakeRound(){
		if(brass<1||powders<4){
			makinground=false;
			setstatelabel("spawn");
			return;
		}
		brass--;powders-=4;
		A_StartSound("roundmaker/pop",10);
		if(!random(0,63)){
			A_SpawnItemEx("HDExplosion");
			A_Explode(32,32);
		}else A_SpawnItemEx("HDLoose7mm",0,0,0,1,0,3,0,SXF_NOCHECKPOSITION);
	}
	action void A_CheckChug(bool anyotherconditions=true){
		if(
			anyotherconditions
			&&countinv("SevenMilBrass")
			&&countinv("FourMilAmmo")>=4
		){
			invoker.makinground=true;
			int counter=min(10,countinv("SevenMilBrass"));
			invoker.brass=counter;A_TakeInventory("SevenMilBrass",counter);
			counter=min(30,countinv("FourMilAmmo"));
			invoker.powders=counter;A_TakeInventory("FourMilAmmo",counter);
			dropinventory(invoker);
		}
	}
	states{
	chug:
		---- AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 3{invoker.A_Chug();}
		---- A 10{invoker.A_MakeRound();}
		---- A 0 A_Jump(256,"spawn");
	}
}
class AutoReloader:AutoReloadingThingy{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "7.76mm Auto-Reloader"
		//$Sprite "RLDRA0"

		+weapon.wimpy_weapon
		+inventory.invbar
		+hdweapon.fitsinbackpack
		inventory.pickupsound "misc/w_pkup";
		inventory.pickupmessage "You got the 7.76 reloading machine!";
		scale 0.5;
		hdweapon.refid HDLD_776RL;
		tag "7.76mm reloading device";
	}
	override double gunmass(){return 0;}
	override double weaponbulk(){
		return 20*amount;
	}
	override string,double getpickupsprite(){return "RLDRA0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		vector2 bob=hpl.hudbob*0.3;
		int brass=hpl.countinv("SevenMilBrass");
		int fourm=hpl.countinv("FourMilAmmo");
		double lph=(brass&&fourm>=4)?1.:0.6;
		sb.drawimage("RLDRA0",(0,-64)+bob,
			sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_CENTER,
			alpha:lph,scale:(2,2)
		);
		sb.drawimage("RBRSA3A7",(-30,-64)+bob,
			sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_CENTER|sb.DI_ITEM_RIGHT,
			alpha:lph,scale:(2.5,2.5)
		);
		sb.drawimage("RCLSA3A7",(30,-64)+bob,
			sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_CENTER|sb.DI_ITEM_LEFT,
			alpha:lph,scale:(1.9,4.7)
		);
		sb.drawstring(
			sb.psmallfont,""..brass,(-30,-54)+bob,
			sb.DI_TEXT_ALIGN_RIGHT|sb.DI_SCREEN_CENTER_BOTTOM,
			fourm?Font.CR_GOLD:Font.CR_DARKGRAY,alpha:lph
		);
		sb.drawstring(
			sb.psmallfont,""..fourm,(30,-54)+bob,
			sb.DI_TEXT_ALIGN_LEFT|sb.DI_SCREEN_CENTER_BOTTOM,
			fourm?Font.CR_LIGHTBLUE:Font.CR_DARKGRAY,alpha:lph
		);
	}
	override string gethelptext(){
		return
		WEPHELP_FIRE.."  Assemble rounds\n"
		..WEPHELP_UNLOAD.."+"..WEPHELP_USE.."  same"
		;
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	states{
	select0:
		TNT1 A 0 A_Raise(999);
		wait;
	deselect0:
		TNT1 A 0 A_Lower(999);
		wait;
	ready:
		TNT1 A 1 A_WeaponReady(WRF_ALLOWUSER4);
		goto readyend;
	fire:
		TNT1 A 0 A_CheckChug();
		goto ready;
	hold:
		TNT1 A 1;
		TNT1 A 0 A_Refire("hold");
		goto ready;
	user4:
	unload:
		TNT1 A 1 A_CheckChug(pressinguse());
		goto ready;
	spawn:
		RLDR A -1 nodelay A_JumpIf(
			invoker.makinground
			&&invoker.brass>0
			&&invoker.powders>=3,
		"chug");
		stop;
	}
}


// ------------------------------------------------------------
// Liberator Battle Rifle
// ------------------------------------------------------------
class LiberatorRifle:AutoReloadingThingy{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Liberator"
		//$Sprite "BRFLB0"

		+hdweapon.fitsinbackpack
		weapon.slotnumber 6;
		weapon.slotpriority 2;
		weapon.kickback 20;
		weapon.selectionorder 27;
		inventory.pickupsound "misc/w_pkup";
		inventory.pickupmessage "You got the battle rifle!";
		weapon.bobrangex 0.22;
		weapon.bobrangey 0.9;
		scale 0.7;
		obituary "%o was liberated by %k.";
		hdweapon.refid HDLD_LIB;
		tag "Liberator battle rifle";
		inventory.icon "BRFLB0";
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	override void postbeginplay(){
		super.postbeginplay();
		if(weaponstatus[0]&LIBF_NOLAUNCHER){
			barrelwidth=0.7;
			barreldepth=1.2;
			weaponstatus[0]&=~(LIBF_GRENADEMODE|LIBF_GRENADELOADED);
		}else{
			barrelwidth=1;
			barreldepth=3;
		}
		if(weaponstatus[0]&LIBF_NOBULLPUP){
			barrellength=32;
			bfitsinbackpack=false;
		}else{
			barrellength=27;
		}
	}
	override double gunmass(){
		if(weaponstatus[0]&LIBF_NOBULLPUP){
			double howmuch=11;
			if(weaponstatus[0]&LIBF_NOLAUNCHER)return howmuch+weaponstatus[LIBS_MAG]*0.04;
			return howmuch+1.1+weaponstatus[LIBS_MAG]*0.05+(weaponstatus[0]&LIBF_GRENADELOADED?1.2:0.9);
		}else{
			double howmuch=9;
			if(weaponstatus[0]&LIBF_NOLAUNCHER)return howmuch+weaponstatus[LIBS_MAG]*0.04;
			return howmuch+1.+weaponstatus[LIBS_MAG]*0.04+(weaponstatus[0]&LIBF_GRENADELOADED?1.:0.6);
		}
	}
	override double weaponbulk(){
		double blx=(weaponstatus[0]&LIBF_NOBULLPUP)?120:100;
		if(!(weaponstatus[0]&LIBF_NOLAUNCHER)){
			blx+=28;
			if(weaponstatus[0]&LIBF_GRENADELOADED)blx+=ENC_ROCKETLOADED;
		}
		int mgg=weaponstatus[LIBS_MAG];
		return blx+(mgg<0?0:(ENC_776MAG_LOADED+mgg*ENC_776_LOADED));
	}
	override string,double getpickupsprite(){
		string spr;
		// A: -g +m
		// B: +g +m
		// C: -g -m
		// D: +g -m
		if(weaponstatus[0]&LIBF_NOLAUNCHER){
			if(weaponstatus[LIBS_MAG]<0)spr="C";
			else spr="A";
		}else{
			if(weaponstatus[LIBS_MAG]<0)spr="D";
			else spr="B";
		}
		return ((weaponstatus[0]&LIBF_NOBULLPUP)?"BRLL":"BRFL")..spr.."0",1.;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			int nextmagloaded=sb.GetNextLoadMag(hdmagammo(hpl.findinventory("HD7mMag")));
			if(nextmagloaded>=30){
				sb.drawimage("RMAGNORM",(-46,-3),sb.DI_SCREEN_CENTER_BOTTOM);
			}else if(nextmagloaded<1){
				sb.drawimage("RMAGEMPTY",(-46,-3),sb.DI_SCREEN_CENTER_BOTTOM,alpha:nextmagloaded?0.6:1.);
			}else sb.drawbar(
				"RMAGNORM","RMAGGREY",
				nextmagloaded,30,
				(-46,-3),-1,
				sb.SHADER_VERT,sb.DI_SCREEN_CENTER_BOTTOM
			);
			sb.drawnum(hpl.countinv("HD7mMag"),-43,-8,sb.DI_SCREEN_CENTER_BOTTOM);
			if(!(hdw.weaponstatus[0]&LIBF_NOLAUNCHER)){
				sb.drawimage("ROQPA0",(-62,-4),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.6,0.6));
				sb.drawnum(hpl.countinv("HDRocketAmmo"),-56,-8,sb.DI_SCREEN_CENTER_BOTTOM);
			}
		}
		if(!(hdw.weaponstatus[0]&LIBF_NOAUTO)){
			string llba="RBRSA3A7";
			if(hdw.weaponstatus[0]&LIBF_FULLAUTO)llba="STFULAUT";
			sb.drawimage(
				llba,(-22,-10),
				sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TRANSLATABLE|sb.DI_ITEM_RIGHT
			);
		}
		if(hdw.weaponstatus[0]&LIBF_GRENADELOADED)sb.drawwepdot(-16,-13,(4,2.6));
		int lod=max(hdw.weaponstatus[LIBS_MAG],0);
		sb.drawwepnum(lod,30);
		if(hdw.weaponstatus[LIBS_CHAMBER]==2){
			sb.drawwepdot(-16,-10,(3,1));
			lod++;
		}
		if(hdw.weaponstatus[0]&LIBF_GRENADEMODE){
			int ab=hdw.airburst;
			sb.drawnum(ab,
				-30,-22,sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,
				ab?Font.CR_WHITE:Font.CR_DARKGRAY
			);
			sb.drawwepdot(-30,-42+min(16,ab/10),(4,1));
			sb.drawwepdot(-30,-26,(1,16));
			sb.drawwepdot(-32,-26,(1,16));
		}
	}
	override string gethelptext(){
		bool gl=!(weaponstatus[0]&LIBF_NOLAUNCHER);
		bool glmode=gl&&(weaponstatus[0]&LIBF_GRENADEMODE);
		return
		WEPHELP_FIRESHOOT
		..(gl?(WEPHELP_ALTFIRE..(glmode?("  Rifle mode\n"):("  GL mode\n"))):"")
		..WEPHELP_RELOAD.."  Reload mag\n"
		..(gl?(WEPHELP_ALTRELOAD.."  Reload GL\n"):"")
		..(glmode?(WEPHELP_FIREMODE.."+"..WEPHELP_UPDOWN.."  Airburst\n")
			:(
			(WEPHELP_FIREMODE.."  Semi/Auto\n")
			..WEPHELP_ZOOM.."+"..WEPHELP_FIREMODE.."+"..WEPHELP_UPDOWN.."  Zoom\n"))
		..WEPHELP_MAGMANAGER
		..WEPHELP_UNLOAD.."  Unload "..(glmode?"GL\n":"magazine\n")
		..WEPHELP_UNLOAD.."+"..WEPHELP_USE.."  Assemble rounds"
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc,string whichdot
	){
		if(hdw.weaponstatus[0]&LIBF_GRENADEMODE)sb.drawgrenadeladder(hdw.airburst,bob);
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
				int scaledyoffset=60;
				int scaledwidth=72;
				double degree=hdw.weaponstatus[LIBS_ZOOM]*0.1;
				double deg=1/degree;
				int cx,cy,cw,ch;
				[cx,cy,cw,ch]=screen.GetClipRect();
				sb.SetClipRect(
					-36+bob.x,24+bob.y,scaledwidth,scaledwidth,
					sb.DI_SCREEN_CENTER
				);
				string reticle=
					hdw.weaponstatus[0]&LIBF_ALTRETICLE?"reticle2":"reticle1";
				texman.setcameratotexture(hpc,"HDXHCAM3",degree);
				sb.drawimage(
					"HDXHCAM3",(0,scaledyoffset)+bob,
					sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					scale:(0.5,0.5)
				);
				if(hdw.weaponstatus[0]&LIBF_FRONTRETICLE){
					sb.drawimage(
						reticle,(0,scaledyoffset)+bob*5,
						sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
						scale:(1.6,1.6)*deg
					);
				}else{
					sb.drawimage(
						reticle,(0,scaledyoffset)+bob,
						sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
						scale:(0.52,0.52)
					);
				}
				sb.drawimage(
					"scophole",(0,scaledyoffset)+bob*5,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					scale:(0.95,0.95)
				);
				screen.SetClipRect(cx,cy,cw,ch);
				sb.drawimage(
					"libscope",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER
				);
				sb.drawstring(
					sb.mAmountFont,string.format("%.1f",degree),
					(6+bob.x,95+bob.y),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_RIGHT,
					Font.CR_BLACK
				);
				sb.drawstring(
					sb.mAmountFont,string.format("%.1f",hdw.weaponstatus[LIBS_DROPADJUST]*0.1),
					(6+bob.x,17+bob.y),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_RIGHT,
					Font.CR_BLACK
				);
			}
		}
	}
	override void failedpickupunload(){
		failedpickupunloadmag(LIBS_MAG,"HD7mMag");
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			if(owner.countinv("SevenMilAmmo"))owner.A_DropInventory("SevenMilAmmo",30);
			else{
				double angchange=(weaponstatus[0]&LIBF_NOLAUNCHER)?0:-10;
				if(angchange)owner.angle-=angchange;
				owner.A_DropInventory("HD7mMag",1);
				if(angchange){
					owner.angle+=angchange*2;
					owner.A_DropInventory("HDRocketAmmo",1);
					owner.angle-=angchange;
				}
			}
		}
	}
	override void ForceBasicAmmo(){
		owner.A_TakeInventory("SevenMilAmmo");
		owner.A_TakeInventory("SevenMilBrass");
		owner.A_TakeInventory("FourMilAmmo");
		owner.A_TakeInventory("HD7mMag");
		owner.A_GiveInventory("HD7mMag");
		if(!(weaponstatus[0]&LIBF_NOLAUNCHER)){
			owner.A_TakeInventory("DudRocketAmmo");
			owner.A_SetInventory("HDRocketAmmo",1);
		}
	}
	override void tick(){
		super.tick();
		drainheat(LIBS_HEAT,8);
	}
	action void A_Chamber(bool unloadonly=false){
		A_StartSound("weapons/libchamber",8,CHANF_OVERLAP);
		actor brsss=null;
		if(invoker.weaponstatus[LIBS_CHAMBER]==1){
			if(invoker.weaponstatus[0]&LIBF_NOBULLPUP){
				double cosp=cos(pitch);
				[cosp,brsss]=A_SpawnItemEx("HDSpent7mm",
					cosp*6,0,height-8-sin(pitch)*6,
					cosp*2,-1,2-sin(pitch),
					0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
				brsss.vel+=vel;
				brsss.A_StartSound(brsss.bouncesound,volume:0.4);
			}else{
				int bss=invoker.weaponstatus[LIBS_BRASS];
				if(bss<random(1,7)){
					invoker.weaponstatus[LIBS_BRASS]++;
					A_StartSound("misc/casing",8,CHANF_OVERLAP);
				}else{
					double fc=max(pitch*0.01,5);
					double cosp=cos(pitch);
					[cosp,brsss]=A_SpawnItemEx("HDSpent7mm",
						cosp*12,0,height-8-sin(pitch)*12,
						cosp*fc,0.2*randompick(-1,1),-sin(pitch)*fc,
						0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
					);
					brsss.vel+=vel;
					brsss.A_StartSound(brsss.bouncesound,volume:0.4);
				}
			}
		}else if(invoker.weaponstatus[LIBS_CHAMBER]==2){
			double fc=max(pitch*0.01,5);
			double cosp=cos(pitch);
			[cosp,brsss]=A_SpawnItemEx("HDLoose7mm",
				cosp*12,0,height-8-sin(pitch)*12,
				cosp*fc,0.2*randompick(-1,1),-sin(pitch)*fc,
				0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
			);
			brsss.vel+=vel;
			brsss.A_StartSound(brsss.bouncesound,volume:0.4);
		}
		if(!unloadonly && invoker.weaponstatus[LIBS_MAG]>0){
			invoker.weaponstatus[LIBS_MAG]--;
			invoker.weaponstatus[LIBS_CHAMBER]=2;
		}else{
			invoker.weaponstatus[LIBS_CHAMBER]=0;
			if(brsss!=null)brsss.vel=vel+(cos(angle),sin(angle),-2);
		}
	}
	states{
	brasstube:
		TNT1 A 4{
			if(
				invoker.weaponstatus[LIBS_BRASS]>0
				&&(
					pitch>5
					||IsBusy(self)
				)
			){
				double fc=max(pitch*0.01,5);
				double cosp=cos(pitch);
				actor brsss;
				[cosp,brsss]=A_SpawnItemEx("HDSpent7mm",
					cosp*12,0,height-8-sin(pitch)*12,
					cosp*fc,0.2*randompick(-1,1),-sin(pitch)*fc,
					0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
				brsss.vel+=vel;
				brsss.A_StartSound(brsss.bouncesound,volume:0.4);
				invoker.weaponstatus[LIBS_BRASS]--;
			}
		}wait;
	select0:
		BRFG A 0{
			A_Overlay(776,"brasstube");
			invoker.weaponstatus[0]&=~LIBF_GRENADEMODE;
		}goto select0big;
	deselect0:
		BRFG A 0{
			while(invoker.weaponstatus[LIBS_BRASS]>0){
				double cosp=cos(pitch);
				actor brsss;
				[cosp,brsss]=A_SpawnItemEx("HDSpent7mm",
					cosp*12,0,height-8-sin(pitch)*12,
					cosp*3,0.2*randompick(-1,1),-sin(pitch)*3,
					0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
				brsss.vel+=vel;
				brsss.A_StartSound(brsss.bouncesound,volume:0.4);
				invoker.weaponstatus[LIBS_BRASS]--;
			}
		}goto deselect0big;
	ready:
		BRFG A 1{
			if(pressingzoom()){
				if(player.cmd.buttons&BT_USE){
					A_ZoomAdjust(LIBS_DROPADJUST,0,600,BT_USE);
				}else if(invoker.weaponstatus[0]&LIBF_FRONTRETICLE)A_ZoomAdjust(LIBS_ZOOM,20,40);
				else A_ZoomAdjust(LIBS_ZOOM,6,70);
				A_WeaponReady(WRF_NONE);
			}else A_WeaponReady(WRF_ALL);
		}goto readyend;
	user3:
		---- A 0 A_JumpIf(!(invoker.weaponstatus[0]&LIBF_GRENADEMODE),1);
		goto super::user3;
		---- A 0 A_MagManager("HD7mMag");
		goto ready;

	fire:
		BRFG A 0{
			if(
				invoker.weaponstatus[0]&LIBF_NOLAUNCHER
				||!(invoker.weaponstatus[0]&LIBF_GRENADEMODE)
			){
				setweaponstate("firegun");
			}else setweaponstate("firegrenade");
		}
	hold:
		BRFG A 1{
			if(
				invoker.weaponstatus[0]&LIBF_GRENADEMODE
				||!(invoker.weaponstatus[0]&LIBF_FULLAUTO)
				||(invoker.weaponstatus[0]&LIBF_NOAUTO)
				||invoker.weaponstatus[LIBS_CHAMBER]!=2
			)setweaponstate("nope");
		}goto shoot;

	firegun:
		BRFG A 1{
			if(invoker.weaponstatus[0]&LIBF_NOBULLPUP)A_SetTics(0);
			else if(invoker.weaponstatus[0]&LIBF_FULLAUTO)A_SetTics(2);
		}
	shoot:
		BRFG A 1{
			if(invoker.weaponstatus[LIBS_CHAMBER]==2)A_Gunflash();
			else setweaponstate("chamber_manual");
			A_WeaponReady(WRF_NONE);
		}
		BRFG B 1 A_Chamber();
		BRFG A 0 A_Refire();
		goto nope;
	flash:
		BRFF A 1 bright{
			A_Light1();
			A_StartSound("weapons/bigrifle",CHAN_WEAPON);

			HDBulletActor.FireBullet(self,"HDB_776",
				aimoffy:(-1./600.)*invoker.weaponstatus[LIBS_DROPADJUST]
			);
/*
			actor p=spawn("HDBullet776",pos+(0,0,height-6),ALLOW_REPLACE);
			p.target=self;p.angle=angle;p.pitch=pitch;
			p.vel+=self.vel;
			p.pitch-=(1./600.)*invoker.weaponstatus[LIBS_DROPADJUST];
*/
			if(invoker.weaponstatus[0]&LIBF_NOBULLPUP){
				HDFlashAlpha(16);
				A_ZoomRecoil(0.90);
				A_MuzzleClimb(
					0,0,
					-0.07,-0.14,
					-frandom(0.3,0.6),-frandom(1.,1.4),
					-frandom(0.2,0.4),-frandom(1.,1.4)
				);
			}else{
				HDFlashAlpha(32);
				A_ZoomRecoil(0.95);
				A_MuzzleClimb(
					0,0,
					-0.2,-0.4,
					-frandom(0.5,0.9),-frandom(1.7,2.1),
					-frandom(0.5,0.9),-frandom(1.7,2.1)
				);
			}

			invoker.weaponstatus[LIBS_CHAMBER]=1;
			invoker.weaponstatus[LIBS_HEAT]+=2;
			A_AlertMonsters();
		}
		goto lightdone;
	chamber_manual:
		BRFG A 1 offset(-1,34){
			if(
				invoker.weaponstatus[LIBS_CHAMBER]==2
				||invoker.weaponstatus[LIBS_MAG]<1
			)setweaponstate("nope");
		}
		BRFG B 1 offset(-2,36)A_StartSound("weapons/libchamber",8);
		BRFG B 1 offset(-2,38)A_Chamber();
		BRFG A 1 offset(-1,34);
		goto nope;


	firemode:
		---- A 0{
			if(invoker.weaponstatus[0]&LIBF_GRENADEMODE)setweaponstate("abadjust");
			else if(!(invoker.weaponstatus[0]&LIBF_NOAUTO))invoker.weaponstatus[0]^=LIBF_FULLAUTO;
		}goto nope;


	unloadchamber:
		BRFG B 1 offset(-1,34){
			if(
				invoker.weaponstatus[LIBS_CHAMBER]<1
			)setweaponstate("nope");
		}
		BRFG B 1 offset(-2,36)A_Chamber(true);
		BRFG B 1 offset(-2,38);
		BRFG A 1 offset(-1,34);
		goto nope;

	loadchamber:
		BRFG A 0 A_JumpIf(invoker.weaponstatus[LIBS_CHAMBER]>0,"nope");
		BRFG A 0 A_JumpIf(!countinv("SevenMilAmmo"),"nope");
		BRFG A 1 offset(0,34) A_StartSound("weapons/pocket",9);
		BRFG A 1 offset(2,36);
		BRFG B 1 offset(5,40);
		BRFG B 4 offset(4,39){
			if(countinv("SevenMilAmmo")){
				A_TakeInventory("SevenMilAmmo",1,TIF_NOTAKEINFINITE);
				invoker.weaponstatus[LIBS_CHAMBER]=2;
				A_StartSound("weapons/libchamber2",8);
				A_StartSound("weapons/libchamber2a",8,CHANF_OVERLAP,0.7);
			}
		}
		BRFG B 7 offset(5,37);
		BRFG B 1 offset(2,36);
		BRFG A 1 offset(0,34);
		goto readyend;

	user4:
	unload:
		---- A 1 A_CheckChug(pressinguse()); //DO NOT set this frame to zero
		BRFG A 0{
			invoker.weaponstatus[0]|=LIBF_JUSTUNLOAD;
			if(
				invoker.weaponstatus[0]&LIBF_GRENADEMODE
			){
				return resolvestate("unloadgrenade");
			}else if(
				invoker.weaponstatus[LIBS_MAG]>=0  
			){
				return resolvestate("unmag");
			}else if(
				invoker.weaponstatus[LIBS_CHAMBER]>0  
			){
				return resolvestate("unloadchamber");
			}
			return resolvestate("nope");
		}
	reload:
		BRFG A 0{
			int inmag=invoker.weaponstatus[LIBS_MAG];
			invoker.weaponstatus[0]&=~LIBF_JUSTUNLOAD;
			if(
				//no point reloading
				inmag>=30
				||(
					//no mags to load and can't directly load chamber
					!countinv("HD7mMag")
					&&(
						inmag>=0
						||invoker.weaponstatus[LIBS_CHAMBER]>0
						||!countinv("SevenMilAmmo")
					)
				)
			)return resolvestate("nope");
			else if(
				//no mag, empty chamber, have loose rounds
				inmag<0
				&&!countinv("HD7mMag")
				&&invoker.weaponstatus[LIBS_CHAMBER]<1
				&&countinv("SevenMilAmmo")
			)return resolvestate("loadchamber");
			else if(
				invoker.weaponstatus[LIBS_MAG]>0  
			){
				//if full mag and unchambered, chamber
				if(
					invoker.weaponstatus[LIBS_MAG]>=30  
					&&invoker.weaponstatus[LIBS_CHAMBER]!=2
				){
					return resolvestate("chamber_manual");
				}				
			}return resolvestate("unmag");
		}

	unmag:
		BRFG A 1 offset(0,34);
		BRFG A 1 offset(2,36);
		BRFG B 1 offset(4,40);
		BRFG B 2 offset(8,42){
			A_MuzzleClimb(-frandom(0.4,0.8),frandom(0.4,1.4));
			A_StartSound("weapons/rifleclick2",8);
		}
		BRFG B 4 offset(14,46){
			A_MuzzleClimb(-frandom(0.4,0.8),frandom(0.4,1.4));
			A_StartSound ("weapons/rifleload",8,CHANF_OVERLAP);
		}
		BRFG B 0{
			int magamt=invoker.weaponstatus[LIBS_MAG];
			if(magamt<0){setweaponstate("magout");return;}
			invoker.weaponstatus[LIBS_MAG]=-1;
			if(
				!PressingReload()
				&&!PressingUnload()
			){
				HDMagAmmo.SpawnMag(self,"HD7mMag",magamt);
				setweaponstate("magout");
			}else{
				HDMagAmmo.GiveMag(self,"HD7mMag",magamt);
				setweaponstate("pocketmag");
			}
		}
	pocketmag:
		BRFG B 7 offset(12,52)A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
		BRFG B 0 A_StartSound("weapons/pocket",9);
		BRFG BB 7 offset(14,54)A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
		BRFG B 0{
		}goto magout;
	magout:
		BRFG B 4{
			invoker.weaponstatus[LIBS_MAG]=-1;
			if(invoker.weaponstatus[0]&LIBF_JUSTUNLOAD)setweaponstate("reloaddone");
		}goto loadmag;


	loadmag:
		BRFG B 0 A_StartSound("weapons/pocket",9);
		BRFG BB 7 offset(14,54)A_MuzzleClimb(frandom(-0.2,0.4),frandom(-0.2,0.8));
		BRFG B 6 offset(12,52){
			let mmm=hdmagammo(findinventory("HD7mMag"));
			if(mmm){
				invoker.weaponstatus[LIBS_MAG]=mmm.TakeMag(true);
				A_StartSound("weapons/rifleclick",8);
				A_StartSound("weapons/rifleload",8,CHANF_OVERLAP);
			}
		}
		BRFG B 2 offset(8,46) A_StartSound("weapons/rifleclick2",8,CHANF_OVERLAP);
		goto reloaddone;

	reloaddone:
		BRFG B 1 offset (4,40);
		BRFG A 1 offset (2,36){
			if(
				invoker.weaponstatus[LIBS_CHAMBER]!=2
				&&invoker.weaponstatus[LIBS_MAG]>0  
			)A_Chamber();
		}
		BRFG A 1 offset (0,34);
		goto nope;


	altfire:
		BRFG A 1 offset(0,34){
			if(invoker.weaponstatus[0]&LIBF_NOLAUNCHER){
				invoker.weaponstatus[0]&=~(LIBF_GRENADEMODE|LIBF_GRENADELOADED);
				setweaponstate("nope");
			}else invoker.airburst=0;
		}
		BRFG A 1 offset(2,36);
		BRFG B 1 offset(4,40);
		BRFG B 1 offset(2,36);
		BRFG A 1 offset(0,34);
		BRFG A 0{
			invoker.weaponstatus[0]^=LIBF_GRENADEMODE;
			A_SetHelpText();
			A_Refire();
		}goto ready;
	althold:
		BRFG A 0;
		goto nope;


	firegrenade:
		BRFG B 2{
			if(invoker.weaponstatus[0]&LIBF_GRENADELOADED){
				A_FireHDGL();
				invoker.weaponstatus[0]&=~LIBF_GRENADELOADED;
				if(invoker.weaponstatus[0]&LIBF_NOBULLPUP){
					A_ZoomRecoil(0.99);
					A_MuzzleClimb(
						0,0,
						-0.8,-2.,
						-0.4,-1.
					);
				}else{
					A_ZoomRecoil(0.95);
					A_MuzzleClimb(
						0,0,
						-1.2,-3.,
						-0.6,-1.4
					);
				}
			}else setweaponstate("nope");
		}
		BRFG B 2;
		BRFG A 0 A_Refire("nope");
		goto ready;
	altreload:
		BRFG A 0{
			if(!(invoker.weaponstatus[0]&LIBF_NOLAUNCHER)){
				invoker.weaponstatus[0]&=~LIBF_JUSTUNLOAD;
				setweaponstate("unloadgrenade");
			}
		}goto nope;
	unloadgrenade:
		BRFG A 1 offset(0,34){
			A_SetCrosshair(21);
			if(
				(
					//just unloading but no grenade
					invoker.weaponstatus[0]&LIBF_JUSTUNLOAD
					&&!(invoker.weaponstatus[0]&LIBF_GRENADELOADED)
				)||(
					//reloading but no ammo or already loaded
					!(invoker.weaponstatus[0]&LIBF_JUSTUNLOAD)
					&&(
						!countinv("HDRocketAmmo")
						||invoker.weaponstatus[0]&LIBF_GRENADELOADED
					)
				)
			){
				setweaponstate("nope");
			}
		}
		BRFG A 1 offset(-5,40);
		BRFG A 1 offset(-10,50);
		BRFG A 1 offset(-15,56);
		BRFG A 4 offset(-14,54){
			A_StartSound("weapons/pocket",9);
			A_StartSound("weapons/grenopen",8);
		}
		BRFG A 3 offset(-16,56){
			if(invoker.weaponstatus[0]&LIBF_GRENADELOADED){
				if(
					(PressingReload()||PressingUnload())
					&&!A_JumpIfInventory("HDRocketAmmo",0,"null")
				){
					A_GiveInventory("HDRocketAmmo");
					A_StartSound("weapons/pocket",9);
					A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
					A_SetTics(6);
				}else A_SpawnItemEx("HDRocketAmmo",
					cos(pitch)*12,0,height-10-12*sin(pitch),
					vel.x,vel.y,vel.z,
					0,SXF_SETTARGET|SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
				invoker.weaponstatus[0]&=~LIBF_GRENADELOADED;
			}
		}
		BRFG A 0{
			if(invoker.weaponstatus[0]&LIBF_JUSTUNLOAD)setweaponstate("altreloaddone");
		}
		BRFG AA 8 offset(-16,56)A_MuzzleClimb(frandom(-0.2,0.8),frandom(-0.2,0.4));
		BRFG A 18 offset(-14,54)A_StartSound("weapons/grenreload",8);
		BRFG B 4 offset(-12,50){
			A_StartSound("weapons/grenopen",8);
			A_TakeInventory("HDRocketAmmo",1,TIF_NOTAKEINFINITE);
			invoker.weaponstatus[0]|=LIBF_GRENADELOADED;
		}
	altreloaddone:
		BRFG A 1 offset(-15,56);
		BRFG A 1 offset(-10,50);
		BRFG A 1 offset(-5,40);
		BRFG A 1 offset(0,34);
		goto nope;

	spawn:
		BRFL ABCDEFGH -1 nodelay{
			if(invoker.weaponstatus[0]&LIBF_NOBULLPUP){
				sprite=getspriteindex("BRLLA0");
			}
			// A: -g +m +a
			// B: +g +m +a
			// C: -g -m +a
			// D: +g -m +a
			if(invoker.weaponstatus[0]&LIBF_NOLAUNCHER){
				if(invoker.weaponstatus[LIBS_MAG]<0)frame=2;
				else frame=0;
			}else{
				if(invoker.weaponstatus[LIBS_MAG]<0)frame=3;
				else frame=1;
			}

			// E: -g +m -a
			// F: +g +m -a
			// G: -g -m -a
			// H: +g -m -a
			if(invoker.weaponstatus[0]&LIBF_NOAUTO)frame+=4;

			if(
				invoker.makinground
				&&invoker.brass>0
				&&invoker.powders>=3
			)setstatelabel("chug");
		}
		BRLL ABCDEFGH -1;
		stop;
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[LIBS_FLAGS]|=LIBF_GRENADELOADED;
		weaponstatus[LIBS_MAG]=30;
		weaponstatus[LIBS_CHAMBER]=2;
		if(!idfa&&!owner){
			weaponstatus[LIBS_ZOOM]=30;
			weaponstatus[LIBS_HEAT]=0;
			weaponstatus[LIBS_DROPADJUST]=160;
		}
	}
	override void loadoutconfigure(string input){
		int nogl=getloadoutvar(input,"nogl",1);
		//disable launchers if rocket grenades blacklisted
		string blacklist=hd_blacklist;
		if(blacklist.IndexOf(HDLD_BLOOPER)>=0)nogl=1;
		if(!nogl){
			weaponstatus[0]&=~LIBF_NOLAUNCHER;
		}else if(nogl>0){
			weaponstatus[0]|=LIBF_NOLAUNCHER;
			weaponstatus[0]&=~LIBF_GRENADELOADED;
		}
		if(!(weaponstatus[0]&LIBF_NOLAUNCHER))weaponstatus[0]|=LIBF_GRENADELOADED;

		int nobp=getloadoutvar(input,"nobp",1);
		if(!nobp)weaponstatus[0]&=~LIBF_NOBULLPUP;
		else if(nobp>0)weaponstatus[0]|=LIBF_NOBULLPUP;
		if(weaponstatus[0]&LIBF_NOBULLPUP)bfitsinbackpack=false;
		else bfitsinbackpack=true;

		int altreticle=getloadoutvar(input,"altreticle",1);
		if(!altreticle)weaponstatus[0]&=~LIBF_ALTRETICLE;
		else if(altreticle>0)weaponstatus[0]|=LIBF_ALTRETICLE;

		int frontreticle=getloadoutvar(input,"frontreticle",1);
		if(!frontreticle)weaponstatus[0]&=~LIBF_FRONTRETICLE;
		else if(frontreticle>0)weaponstatus[0]|=LIBF_FRONTRETICLE;

		int bulletdrop=getloadoutvar(input,"bulletdrop",3);
		if(bulletdrop>=0)weaponstatus[LIBS_DROPADJUST]=clamp(bulletdrop,0,600);

		int zoom=getloadoutvar(input,"zoom",3);
		if(zoom>=0)weaponstatus[LIBS_ZOOM]=
			(weaponstatus[0]&LIBF_FRONTRETICLE)?
			clamp(zoom,20,40):
			clamp(zoom,6,70);

		int firemode=getloadoutvar(input,"firemode",1);
		if(firemode>0)weaponstatus[0]|=LIBF_FULLAUTO;
		else weaponstatus[0]&=~LIBF_FULLAUTO;

		int semi=getloadoutvar(input,"semi",1);
		if(semi>0){
			weaponstatus[0]|=LIBF_NOAUTO;
			weaponstatus[0]&=~LIBF_FULLAUTO;
		}else weaponstatus[0]&=~LIBF_NOAUTO;
	}
}
enum liberatorstatus{
	LIBF_FULLAUTO=1,
	LIBF_JUSTUNLOAD=2,
	LIBF_GRENADELOADED=4,
	LIBF_NOLAUNCHER=8,
	LIBF_FRONTRETICLE=32,
	LIBF_ALTRETICLE=64,
	LIBF_GRENADEMODE=128,
	LIBF_UNLOADONLY=256,
	LIBF_NOBULLPUP=512,
	LIBF_NOAUTO=1024,

	LIBS_FLAGS=0,
	LIBS_CHAMBER=1,
	LIBS_MAG=2, //-1 is ampty
	LIBS_ZOOM=3,
	LIBS_HEAT=4,
	LIBS_BRASS=5,
	LIBS_AIRBURST=6,
	LIBS_DROPADJUST=7,
};


class LiberatorNoGL:HDWeaponGiver{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Liberator (no GL)"
		//$Sprite "BRFLA0"
		tag "Liberator rifle (no GL)";
		hdweapongiver.bulk (100.+(ENC_776MAG_LOADED+30.*ENC_776_LOADED));
		hdweapongiver.weapontogive "LiberatorRifle";
		hdweapongiver.weprefid HDLD_LIB;
		hdweapongiver.config "noglnobp0";
		inventory.icon "BRFLA0";
	}
}

class LiberatorNoBullpup:HDWeaponGiver{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Liberator (Classic)"
		//$Sprite "BRLLB0"
		tag "Liberator rifle (classic)";
		hdweapongiver.bulk (145.+(ENC_776MAG_LOADED+30.*ENC_776_LOADED)+ENC_ROCKETLOADED);
		hdweapongiver.weapontogive "LiberatorRifle";
		hdweapongiver.config "nogl0nobp";
		inventory.icon "BRLLB0";
	}
}
class LiberatorNoBullpupNoGL:HDWeaponGiver{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "Liberator (Classic no GL)"
		//$Sprite "BRLLA0"
		tag "Liberator rifle (classic no GL)";
		hdweapongiver.bulk (120.+(ENC_776MAG_LOADED+30.*ENC_776_LOADED));
		hdweapongiver.weapontogive "LiberatorRifle";
		hdweapongiver.config "noglnobp";
		inventory.icon "BRLLA0";
	}
}

class LiberatorRandom:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			let lll=LiberatorRifle(spawn("LiberatorRifle",pos,ALLOW_REPLACE));
			if(!lll)return;
			lll.special=special;
			lll.vel=vel;
			if(!random(0,2))lll.weaponstatus[0]|=LIBF_FRONTRETICLE;
			if(!random(0,2))lll.weaponstatus[0]|=LIBF_ALTRETICLE;
			if(!random(0,2))lll.weaponstatus[0]|=LIBF_NOLAUNCHER;
			if(!random(0,3))lll.weaponstatus[0]|=LIBF_NOBULLPUP;
			if(!random(0,5))lll.weaponstatus[0]|=LIBF_NOAUTO;

			if(lll.weaponstatus[0]&LIBF_NOLAUNCHER){
				spawn("HD7mMag",pos+(7,0,0),ALLOW_REPLACE);
				spawn("HD7mMag",pos+(5,0,0),ALLOW_REPLACE);
			}else{
				spawn("HDRocketAmmo",pos+(10,0,0),ALLOW_REPLACE);
				spawn("HDRocketAmmo",pos+(8,0,0),ALLOW_REPLACE);
				spawn("HD7mMag",pos+(5,0,0),ALLOW_REPLACE);
			}
		}stop;
	}
}
