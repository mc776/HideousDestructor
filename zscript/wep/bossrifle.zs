// ------------------------------------------------------------
// Bolt-Action Rifle
// ------------------------------------------------------------
class BossRifleSpawner:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			A_SpawnItemEx("HD7mClip",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
			A_SpawnItemEx("HD7mClip",3,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
			A_SpawnItemEx("HD7mClip",1,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
			A_SpawnItemEx("BossRifle",-3,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
		}stop;
	}
}
class BossRifle:HDWeapon{
	default{
		weapon.slotnumber 8;
		weapon.slotpriority 1;
		weapon.kickback 15;
		weapon.selectionorder 80;
		inventory.pickupSound "misc/w_pkup";
		inventory.pickupMessage "You got the bolt-action rifle!";
		weapon.bobrangex 0.28;
		weapon.bobrangey 1.1;
		scale 0.75;
		Obituary "%o sure showed %k who was the boss!";
		hdweapon.barrelsize 40,1,2;
		hdweapon.refid HDLD_BOSS;
		tag "Boss rifle";
		inventory.maxamount 3; //1 use user setting; 2 custom chamber; 3 regular
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	action void A_ChamberGrit(int amt,bool onlywhileempty=false){
		int ibg=invoker.weaponstatus[BOSSS_GRIME];
		bool customchamber=(invoker.weaponstatus[0]&BOSSF_CUSTOMCHAMBER);
		if(amt>0&&customchamber)amt>>=1;
		if(!onlywhileempty||invoker.weaponstatus[BOSSS_CHAMBER]<1)ibg+=amt;
		else if(!random(0,4))ibg++;
		invoker.weaponstatus[BOSSS_GRIME]=clamp(ibg,0,100);
		//if(hd_debug)A_Log(string.format("Boss grit level: %i",invoker.weaponstatus[BOSSS_GRIME]));
	}
	int pickuprounds;
	override void tick(){
		super.tick();
		drainheat(BOSSS_HEAT,4);
	}
	override double gunmass(){
		return 12;
	}
	override double weaponbulk(){
		return 144+weaponstatus[BOSSS_MAG]*ENC_776_LOADED;
	}
	override void GunBounce(){
		super.GunBounce();
		weaponstatus[BOSSS_GRIME]+=random(-7,3);
		if(weaponstatus[BOSSS_CHAMBER]>2&&!random(0,7))weaponstatus[BOSSS_CHAMBER]-=2;
	}
	int jamchance(){
		int jc=
		weaponstatus[BOSSS_GRIME]
		+(weaponstatus[BOSSS_HEAT]>>2)
		+weaponstatus[BOSSS_CHAMBER]
		;
		if(weaponstatus[0]&BOSSF_CUSTOMCHAMBER)return jc>>5;
		return jc;
	}
	override string,double getpickupsprite(){return "BORFA0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			int nextmagloaded=sb.GetNextLoadMag(hdmagammo(hpl.findinventory("HD7mClip")));
			if(nextmagloaded<1){
				sb.drawimage("RCLPF0",(-58,-3),sb.DI_SCREEN_CENTER_BOTTOM,alpha:nextmagloaded?0.6:1.,scale:(1.6,1.6));
			}else if(nextmagloaded<3){
				sb.drawimage("RCLPE0",(-58,-3),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1.6,1.6));
			}else if(nextmagloaded<5){
				sb.drawimage("RCLPD0",(-58,-3),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1.6,1.6));
			}else if(nextmagloaded<7){
				sb.drawimage("RCLPC0",(-58,-3),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1.6,1.6));
			}else if(nextmagloaded<9){
				sb.drawimage("RCLPB0",(-58,-3),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1.6,1.6));
			}else sb.drawimage("RCLPA0",(-58,-3),sb.DI_SCREEN_CENTER_BOTTOM,scale:(1.6,1.6));
			sb.drawnum(hpl.countinv("HD7mClip"),-45,-8,sb.DI_SCREEN_CENTER_BOTTOM);
		}
		sb.drawwepnum(hdw.weaponstatus[BOSSS_MAG],10);
		sb.drawwepcounter(hdw.weaponstatus[BOSSS_CHAMBER],
			-16,-10,"blank","RBRSA1A5","RBRSA3A7","RBRSA4A6"
		);
		sb.drawstring(
			sb.mAmountFont,string.format("%.1f",hdw.weaponstatus[BOSSS_ZOOM]*0.1),
			(-36,-18),sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,Font.CR_DARKGRAY
		);
		sb.drawstring(
			sb.mAmountFont,string.format("%.1f",hdw.weaponstatus[BOSSS_DROPADJUST]*0.1),
			(-16,-18),sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_RIGHT,Font.CR_WHITE
		);
	}
	override string gethelptext(){
		return
		WEPHELP_FIRESHOOT
		..WEPHELP_ALTFIRE.."  Work bolt\n"
		..WEPHELP_RELOAD.."  Reload rounds/clip\n"
		..WEPHELP_ZOOM.."+"..WEPHELP_FIREMODE.."  Zoom\n"
		..WEPHELP_ZOOM.."+"..WEPHELP_USE.."  Bullet drop\n"
		..WEPHELP_ALTFIRE.."+"..WEPHELP_UNLOAD.."  Unload chamber/Clean rifle\n"
		..WEPHELP_UNLOADUNLOAD
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc,string whichdot
	){
		int cx,cy,cw,ch;
		[cx,cy,cw,ch]=Screen.GetClipRect();
		sb.SetClipRect(
			-16+bob.x,-4+bob.y,32,16,
			sb.DI_SCREEN_CENTER
		);
		vector2 bobb=bob*2;
		bobb.y=clamp(bobb.y,-8,8);
		sb.drawimage(
			"frntsite",(0,0)+bobb,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.9,scale:(1.6,2)
		);
		sb.SetClipRect(cx,cy,cw,ch);
		sb.drawimage(
			"backsite",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			scale:(2,1)
		);

		if(scopeview){
			int scaledyoffset=60;
			int scaledwidth=89;
			vector2 sclhalf=(0.5,0.5);
			double degree=0.1*hdw.weaponstatus[BOSSS_ZOOM];
			double deg=1/degree;
			int cx,cy,cw,ch;
			[cx,cy,cw,ch]=screen.GetClipRect();
			sb.SetClipRect(-44+bob.x,16+bob.y,scaledwidth,scaledwidth,
				sb.DI_SCREEN_CENTER);
			texman.setcameratotexture(hpc,"HDXHCAM3",degree);
			sb.drawimage(
				"HDXHCAM3",(0,scaledyoffset)+bob,
				sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				scale:sclhalf
			);
			if(hdw.weaponstatus[0]&BOSSF_FRONTRETICLE){
				sb.drawimage(
					"reticle1",(0,scaledyoffset)+bob*deg*5,
					sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					scale:(1.6,1.6)*deg
				);
			}else{
				sb.drawimage(
					"reticle1",(0,scaledyoffset)+bob,
					sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
					scale:sclhalf
				);
			}
			sb.drawimage(
				"scophole",(0,scaledyoffset)+bob*5,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				scale:(1.5,1.5)
			);
			screen.SetClipRect(cx,cy,cw,ch);
			sb.drawimage(
				"libscope",(0,scaledyoffset)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
				scale:(1.24,1.24)
			);
			sb.drawstring(
				sb.mAmountFont,string.format("%.1f",degree),
				(6+bob.x,105+bob.y),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_RIGHT,
				Font.CR_BLACK
			);
			sb.drawstring(
				sb.mAmountFont,string.format("%.1f",hdw.weaponstatus[BOSSS_DROPADJUST]*0.1),
				(6+bob.x,9+bob.y),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_RIGHT,
				Font.CR_BLACK
			);
		}
		// the scope display is in 10ths of an arcminute.
		// one dot = 6 arcminutes.
	}
	override void consolidate(){
		weaponstatus[BOSSS_GRIME]=random(0,20);
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			if(owner.countinv("SevenMilAmmo"))owner.A_DropInventory("SevenMilAmmo",10);
			else owner.A_DropInventory("HD7mClip",1);
		}
	}
	override void ForceBasicAmmo(){
		owner.A_SetInventory("SevenMilAmmo",11);
		owner.A_TakeInventory("SevenMilBrass");
		owner.A_TakeInventory("FourMilAmmo");
		owner.A_TakeInventory("HD7mClip");
		owner.A_GiveInventory("HD7mClip");
	}
	states{
	select0:
		BARG A 0;
		goto select0bfg;
	deselect0:
		BARG A 0;
		goto deselect0big;

	ready:
		BARG A 1{
			if(pressingzoom()){
				if(player.cmd.buttons&BT_USE){
					A_ZoomAdjust(BOSSS_DROPADJUST,0,600,BT_USE);
				}else if(invoker.weaponstatus[0]&BOSSF_FRONTRETICLE)A_ZoomAdjust(BOSSS_ZOOM,12,40);
				else A_ZoomAdjust(BOSSS_ZOOM,5,60);
				A_WeaponReady(WRF_NONE);
			}else A_WeaponReady(WRF_ALL);
		}goto readyend;
	user3:
		---- A 0 A_MagManager("HD7mClip");
		goto ready;
	fire:
		BARG A 1 A_JumpIf(invoker.weaponstatus[BOSSS_CHAMBER]==2,"shoot");
		goto ready;
	shoot:
		BARG A 1{
			A_Gunflash();
			invoker.weaponstatus[BOSSS_CHAMBER]=1;
			A_StartSound("weapons/bigrifle2",CHAN_WEAPON,CHANF_OVERLAP,
				pitch:!(invoker.weaponstatus[0]&BOSSF_CUSTOMCHAMBER)?1.1:1.
			);
			A_AlertMonsters();

			HDBulletActor.FireBullet(self,"HDB_776",
				aimoffy:(-1./600.)*invoker.weaponstatus[BOSSS_DROPADJUST],
				speedfactor:(invoker.weaponstatus[0]&BOSSF_CUSTOMCHAMBER)?0.99:1.07
			);
			A_MuzzleClimb(
				0,0,
				-frandom(0.2,0.4),-frandom(0.6,1.),
				-frandom(0.4,0.7),-frandom(1.2,2.1),
				-frandom(0.4,0.7),-frandom(1.2,2.1)
			);
		}
		BARG F 1;
		BARG F 1 A_JumpIf(gunbraced(),"ready");
		goto ready;
	flash:
		BARF A 1 bright{
			A_Light1();
			HDFlashAlpha(-96);
			A_ZoomRecoil(0.93);
			A_ChamberGrit(randompick(0,0,0,0,0,1,1,1,1,-1));
		}
		TNT1 A 0 A_Light0();
		stop;
	altfire:
		BARG A 1 offset(0,34) A_WeaponBusy();
		BARG B 2 offset(2,36) A_JumpIf(invoker.weaponstatus[0]&BOSSF_CUSTOMCHAMBER,1);
		BARG B 1 offset(4,38){
			if(invoker.weaponstatus[BOSSS_CHAMBER]>2)setweaponstate("jamderp");
		}
		BARG B 1 offset(0,34);
		BARG B 0 A_ChamberGrit(randompick(0,0,0,0,-1,1,2),true);
		BARG B 0 A_Refire("chamber");
		goto ready;
	althold:
		BARG E 1 A_WeaponReady(WRF_NOFIRE);
		BARG E 1{
			A_ClearRefire();
			bool eww=invoker.weaponstatus[BOSSS_GRIME]>10;
			bool chempty=invoker.weaponstatus[BOSSS_CHAMBER]<1;
			if(pressingunload()){
				if(chempty){
					return resolvestate("altholdclean");
				}else{
					invoker.weaponstatus[0]|=BOSSF_UNLOADONLY;
					return resolvestate("loadchamber");
				}
			}else if(pressingreload()){
				if(
					!chempty
				){
					invoker.weaponstatus[0]|=BOSSF_UNLOADONLY;
					return resolvestate("loadchamber");
				}else if(
					eww
				){
					return resolvestate("altholdclean");
				}else if(
					countinv("SevenMilAmmo")
				){
					invoker.weaponstatus[0]&=~BOSSF_UNLOADONLY;
					return resolvestate("loadchamber");
				}
			}
			if(pressingaltfire())return resolvestate("althold");
			return resolvestate("altholdend");
		}
	altholdend:
		BARG E 0 A_StartSound("weapons/boltfwd",8);
		BARG DC 2 A_WeaponReady(WRF_NOFIRE);
		BARG B 3 offset(2,36){
			A_WeaponReady(WRF_NOFIRE);
			if(invoker.weaponstatus[0]&BOSSF_CUSTOMCHAMBER)A_SetTics(1);
		}
		goto ready;
	loadchamber:
		BARG E 1 offset(2,36) A_ClearRefire();
		BARG E 1 offset(3,38);
		BARG E 1 offset(5,42);
		BARG E 1 offset(8,48) A_StartSound("weapons/pocket",9);
		BARG E 1 offset(9,52) A_MuzzleClimb(frandom(-0.2,0.2),0.2,frandom(-0.2,0.2),0.2,frandom(-0.2,0.2),0.2);
		BARG E 2 offset(8,60);
		BARG E 2 offset(7,72);
		TNT1 A 18 A_StartSound("weapons/pocket",9);
		TNT1 A 4{
			A_StartSound("weapons/bossload",8,volume:0.7);
			if(invoker.weaponstatus[0]&BOSSF_UNLOADONLY){
				int chm=invoker.weaponstatus[BOSSS_CHAMBER];
				invoker.weaponstatus[BOSSS_CHAMBER]=0;
				if(chm<2||A_JumpIfInventory("SevenMilAmmo",0,"null")){
					class<actor> whatkind=chm==2?"HDLoose7mm":"HDSpent7mm";
					actor rrr=spawn(whatkind,pos+(cos(angle)*10,sin(angle)*10,height-12),ALLOW_REPLACE);
					rrr.angle=angle;rrr.A_ChangeVelocity(1,2,1,CVF_RELATIVE);
				}else HDF.Give(self,"SevenMilAmmo",1);
				A_ChamberGrit(randompick(0,0,0,0,-1,1),true);
			}else{
				A_TakeInventory("SevenMilAmmo",1,TIF_NOTAKEINFINITE);
				invoker.weaponstatus[BOSSS_CHAMBER]=2;
			}
		} 
		BARG E 2 offset(7,72);
		BARG E 2 offset(8,60);
		BARG E 1 offset(7,52);
		BARG E 1 offset(5,42);
		BARG E 1 offset(3,38);
		BARG E 1 offset(3,35);
		goto althold;
	altholdclean:
		BARG E 1 offset(2,36) A_ClearRefire();
		BARG E 1 offset(3,38);
		BARG E 1 offset(5,42) A_Log("Looking inside that chamber...",true);
		BARG E 1 offset(8,48) A_StartSound("weapons/pocket",9);
		BARG E 1 offset(7,52) A_MuzzleClimb(frandom(-0.2,0.2),0.2,frandom(-0.2,0.2),0.2,frandom(-0.2,0.2),0.2);
		TNT1 A 3 A_StartSound("weapons/pocket",10);
		TNT1 AAAA 4 A_MuzzleClimb(frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2));
		TNT1 A 3 A_StartSound("weapons/pocket",9);
		TNT1 AAAA 4 A_MuzzleClimb(frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2),frandom(-0.2,0.2));
		TNT1 A 40{
			A_StartSound("weapons/pocket",9);
			int amt=invoker.weaponstatus[BOSSS_GRIME];
			string amts="There doesn't seem to be much. ";
			if(amt>40)amts="What the FUCK. ";
			else if(amt>30)amts="About time - this gun is barely functional. ";
			else if(amt>20)amts="This is starting to gum up badly. ";
			else if(amt>10)amts="It can use some cleaning. ";

			static const string cleanverbs[]={"extract","scrape off","wipe away","carefully remove","dump out","pick out","blow off","shake out","scrub off","fish out"};
			static const string contaminants[]={"some dust","a lot of dust","a bit of powder residue","a disturbing amount of powder residue","some excess grease","a layer of soot","some iron filings","a bit of hair","an eyelash","a patch of dried blood","a bit of rust","a crumb","a dead insect","ashes","some loose bits of skin","a sticky fluid of some sort","wow some fucking *gunk*","a booger","trace fecal matter","yet even more of that anonymous grey debris that all those bullet impacts make","a dollop of strawberry jam","a tiny cancerous nodule of Second Flesh","some crystalline buildup of congealed Frag","a nesting queen space ant","a single modern-day transistor","a tiny Boss rifle (also jammed)","a colourless film of darkness made visible"};
			static const string actionparts[]={"bolt carrier","main extractor","auxiliary extractor","cam pin","bolt head","striker","firing pin spring","ejector slot","striker spring","ejector spring"};
			for(int i=amt;i>0;i-=random(8,16))amts.appendformat("You %s %s from the %s. ",
				cleanverbs[random(0,cleanverbs.size()-1)],
				contaminants[random(0,random(0,contaminants.size()-1))],
				actionparts[random(0,random((actionparts.size()>>1),actionparts.size()-1))]
			);
			amts.appendformat("\n");

			amt=randompick(-3,-5,-5,-random(8,16));

			A_ChamberGrit(amt,true);
			amt=invoker.weaponstatus[BOSSS_GRIME];
			if(amt>40)amts.appendformat("You barely scrape the surface of this all-encrusting abomination.");
			else if(amt>30)amts.appendformat("The gun will need a lot more work than this before it can be deployed again.");
			else if(amt>20)amts.appendformat("You might get a few shots out of it now.");
			else if(amt>10)amts.appendformat("It's better, but still not good.");
			else amts.appendformat("Good to go.");
			A_Log(amts,true);
		}
		BARG E 1 offset(7,52);
		BARG E 1 offset(8,48);
		BARG E 1 offset(5,42);
		BARG E 1 offset(3,38);
		BARG E 1 offset(2,36);
		goto althold;
	jam:
		BARG A 0{
			int chm=invoker.weaponstatus[BOSSS_CHAMBER];
			if(chm<1)setweaponstate("chamber");
			else if(chm<3)invoker.weaponstatus[BOSSS_CHAMBER]+=2;
		}
	jamderp:
		BARG A 0 A_StartSound("weapons/rifleclick",8,CHANF_OVERLAP);
		BARG D 1 offset(4,38);
		BARG D 2 offset(2,36);
		BARG D 2 offset(4,38)A_MuzzleClimb(frandom(-0.5,0.6),frandom(-0.3,0.6));
		BARG D 3 offset(2,36){
			A_MuzzleClimb(frandom(-0.5,0.6),frandom(-0.3,0.6));
			if(random(0,invoker.jamchance())<12){
				setweaponstate("chamber");
				if(invoker.weaponstatus[BOSSS_CHAMBER]>2)  
					invoker.weaponstatus[BOSSS_CHAMBER]-=2;
			}
		}
		BARG D 2 offset(4,38);
		BARG D 3 offset(2,36);
		BARG A 0 A_Refire("jamderp");
		goto ready;
	chamber:
		BARG C 2 offset(4,38){
			if(
				random(0,max(2,invoker.weaponstatus[BOSSS_GRIME]>>3))
				&&invoker.weaponstatus[BOSSS_CHAMBER]>2
			){
				invoker.weaponstatus[BOSSS_CHAMBER]+=2;
				A_MuzzleClimb(
					-frandom(0.6,2.3),-frandom(0.6,2.3),
					-frandom(0.6,1.3),-frandom(0.6,1.3),
					-frandom(0.6,1.3),-frandom(0.6,1.3)
				);
				setweaponstate("jamderp");
			}else A_StartSound("weapons/boltback",8);
		}
		BARG D 2 offset(6,42)A_JumpIf(invoker.weaponstatus[0]&BOSSF_CUSTOMCHAMBER,1);
		BARG D 1 offset(6,42){
			if(gunbraced())A_MuzzleClimb(
				frandom(-0.1,0.3),frandom(-0.1,0.3)
			);else A_MuzzleClimb(
				frandom(-0.2,0.8),frandom(-0.4,0.8)
			);
			int jamch=invoker.jamchance();
			if(hd_debug)A_Log("jam chance: "..jamch);
			if(random(0,100)<jamch)setweaponstate("jam");
		}
		BARG D 2 offset(6,42){
			//eject
			int chm=invoker.weaponstatus[BOSSS_CHAMBER];
			if(chm>1){  
				A_SpawnItemEx(
					"HDLoose7mm",cos(pitch)*8,1,height-7-sin(pitch)*8,
					cos(pitch)*cos(angle-80)*4+vel.x,
					cos(pitch)*sin(angle-80)*4+vel.y,
					-sin(pitch)*4+vel.z,
					0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}else if(chm==1){
				A_SpawnItemEx(
					"HDSpent7mm",cos(pitch)*8,1,height-7-sin(pitch)*8,
					cos(pitch)*cos(angle-80)*6+vel.x,
					cos(pitch)*sin(angle-80)*6+vel.y,
					-sin(pitch)*6+vel.z,
					0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}
			//cycle new
			if(invoker.weaponstatus[BOSSS_MAG]>0){  
				invoker.weaponstatus[BOSSS_CHAMBER]=2;
				invoker.weaponstatus[BOSSS_MAG]--;
			}else invoker.weaponstatus[BOSSS_CHAMBER]=0;
		}
		BARG E 1 offset(6,42) A_WeaponReady(WRF_NOFIRE);
		BARG E 0 A_Refire("althold");
		goto altholdend;
	reload:
		---- A 0{invoker.weaponstatus[0]&=~BOSSF_DONTUSECLIPS;}
		goto reloadstart;
	altreload:
		---- A 0{invoker.weaponstatus[0]|=BOSSF_DONTUSECLIPS;}
		goto reloadstart;
	reloadstart:
		BARG A 1 offset(0,34);
		BARG A 1 offset(2,36);
		BARG A 1 offset(4,40);
		BARG A 2 offset(8,42){
			A_StartSound("weapons/rifleclick2",8,CHANF_OVERLAP,0.9,pitch:0.95);
			A_MuzzleClimb(-frandom(0.4,0.8),frandom(0.4,1.4));
		}
		BARG A 4 offset(14,46){
			A_StartSound("weapons/rifleload",8,CHANF_OVERLAP);
			A_MuzzleClimb(-frandom(0.4,0.8),frandom(0.4,1.4));
		}
		BARG A 0{
			int mg=invoker.weaponstatus[BOSSS_MAG];
			if(mg==10)setweaponstate("reloaddone");
			else if(invoker.weaponstatus[0]&BOSSF_DONTUSECLIPS)setweaponstate("loadhand");
			else if(
				(
					mg<1
					||!countinv("SevenMilAmmo")
				)&&!HDMagAmmo.NothingLoaded(self,"HD7mClip")
			)setweaponstate("loadclip");
		}
	loadhand:
		BARG A 0 A_JumpIfInventory("SevenMilAmmo",1,"loadhandloop");
		goto reloaddone;
	loadhandloop:
		BARG A 4{
			int hnd=min(
				countinv("SevenMilAmmo"),3,
				10-invoker.weaponstatus[BOSSS_MAG]
			);
			if(hnd<1){
				setweaponstate("reloaddone");
				return;
			}else{
				A_TakeInventory("SevenMilAmmo",hnd,TIF_NOTAKEINFINITE);
				invoker.weaponstatus[BOSSS_HAND]=hnd;
				A_StartSound("weapons/pocket",9);
			}
		}
	loadone:
		BARG A 2 offset(16,50) A_JumpIf(invoker.weaponstatus[BOSSS_HAND]<1,"loadhandnext");
		BARG A 4 offset(14,46){
			invoker.weaponstatus[BOSSS_HAND]--;
			invoker.weaponstatus[BOSSS_MAG]++;
			A_StartSound("weapons/rifleclick2",8);
		}loop;
	loadhandnext:
		BARG A 8 offset(16,48){
			if(
				PressingReload()||
				PressingFire()||
				PressingAltFire()||
				PressingZoom()||
				!countinv("SevenMilAmmo")	//don't strip clips automatically
			)setweaponstate("reloaddone");
			else A_StartSound("weapons/pocket",9);
		}goto loadhandloop;
	loadclip:
		BARG A 0 A_JumpIf(invoker.weaponstatus[BOSSS_MAG]>9,"reloaddone");
		BARG A 3 offset(16,50){
			let ccc=hdmagammo(findinventory("HD7mClip"));
			if(ccc){
				//find the last mag that has anything in it and load from that
				int magindex=-1;
				for(int i=ccc.mags.size()-1;i>=0;i--){
					if(ccc.mags[i]>0){
						magindex=i;
						break;
					}
				}
				if(magindex<0){
					setweaponstate("reloaddone");
					return;
				}

				//load the whole clip at once if possible
				if(
					ccc.mags[magindex]>=10
					&&invoker.weaponstatus[BOSSS_MAG]<1
				){
					setweaponstate("loadwholeclip");
					return;
				}

				//strip one round and load it
				A_StartSound("weapons/rifleclick2",CHAN_WEAPONBODY);
				invoker.weaponstatus[BOSSS_MAG]++;
				ccc.mags[magindex]--;
			}
		}
		BARG A 5 offset(16,52) A_JumpIf(
			PressingReload()||
			PressingFire()||
			PressingAltFire()||
			PressingZoom()
		,"reloaddone");
		loop;
	loadwholeclip:
		BARG A 4 offset(16,50) A_StartSound("weapons/rifleclick2",8);
		BARG AAA 3 offset(17,52) A_StartSound("weapons/rifleclick2",8,pitch:1.01);
		BARG AAA 2 offset(16,50) A_StartSound("weapons/rifleclick2",8,CHANF_OVERLAP,pitch:1.02);
		BARG AAA 1 offset(15,48) A_StartSound("weapons/rifleclick2",8,CHANF_OVERLAP,pitch:1.02);
		BARG A 2 offset(14,46){
			A_StartSound("weapons/rifleclick",CHAN_WEAPONBODY);
			let ccc=hdmagammo(findinventory("HD7mClip"));
			if(ccc){
				invoker.weaponstatus[BOSSS_MAG]=ccc.TakeMag(true);
				if(pressingreload()){
					ccc.addamag(0);
					A_SetTics(10);
					A_StartSound("weapons/pocket",CHAN_POCKETS);
				}else HDMagAmmo.SpawnMag(self,"HD7mClip",0);
			}
		}goto reloaddone;
	reloaddone:
		BARG A 1 offset(4,40);
		BARG A 1 offset(2,36);
		BARG A 1 offset(0,34);
		goto nope;
	unload:
		BARG A 1 offset(0,34);
		BARG A 1 offset(2,36);
		BARG A 1 offset(4,40);
		BARG A 2 offset(8,42){
			A_MuzzleClimb(-frandom(0.4,0.8),frandom(0.4,1.4));
			A_StartSound("weapons/rifleclick2",8);
		}
		BARG A 4 offset (14,46){
			A_MuzzleClimb(-frandom(0.4,0.8),frandom(0.4,1.4));
			A_StartSound("weapons/rifleload",8);
		}
	unloadloop:
		BARG A 4 offset(3,41){
			if(invoker.weaponstatus[BOSSS_MAG]<1)setweaponstate("unloaddone");
			else{
				A_StartSound("weapons/rifleclick2",8);
				invoker.weaponstatus[BOSSS_MAG]--;
				if(A_JumpIfInventory("SevenMilAmmo",0,"null")){
					A_SpawnItemEx(
						"HDLoose7mm",cos(pitch)*8,0,height-7-sin(pitch)*8,
						cos(pitch)*cos(angle-40)*1+vel.x,
						cos(pitch)*sin(angle-40)*1+vel.y,
						-sin(pitch)*1+vel.z,
						0,SXF_ABSOLUTEMOMENTUM|
						SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
					);
				}else A_GiveInventory("SevenMilAmmo",1);
			}
		}
		BARG A 2 offset(2,42);
		BARG A 0{
			if(
				PressingReload()||
				PressingFire()||
				PressingAltFire()||
				PressingZoom()
			)setweaponstate("unloaddone");
		}loop;
	unloaddone:
		BARG A 2 offset(2,42);
		BARG A 3 offset(3,41);
		BARG A 1 offset(4,40) A_StartSound("weapons/rifleclick",8);
		BARG A 1 offset(2,36);
		BARG A 1 offset(0,34);
		goto ready;

	spawn:
		BORF A -1;
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[BOSSS_CHAMBER]=2;
		weaponstatus[BOSSS_MAG]=10;
		if(!idfa){
			weaponstatus[BOSSS_HEAT]=0;
		}
		if(!owner){
			if(randompick(0,0,1))weaponstatus[0]&=~BOSSF_FRONTRETICLE;
				else weaponstatus[0]|=BOSSF_FRONTRETICLE;
			if(random(0,3))weaponstatus[0]&=~BOSSF_CUSTOMCHAMBER;
				else weaponstatus[0]|=BOSSF_CUSTOMCHAMBER;
			weaponstatus[BOSSS_ZOOM]=20;
			weaponstatus[BOSSS_DROPADJUST]=160;
		}
	}
	override void loadoutconfigure(string input){
		int customchamber=getloadoutvar(input,"customchamber",1);
		if(!customchamber)weaponstatus[0]&=~BOSSF_CUSTOMCHAMBER;
		else if(customchamber>0)weaponstatus[0]|=BOSSF_CUSTOMCHAMBER;

		int frontreticle=getloadoutvar(input,"frontreticle",1);
		if(!frontreticle)weaponstatus[0]&=~BOSSF_FRONTRETICLE;
		else if(frontreticle>0)weaponstatus[0]|=BOSSF_FRONTRETICLE;

		int bulletdrop=getloadoutvar(input,"bulletdrop",3);
		if(bulletdrop>=0)weaponstatus[BOSSS_DROPADJUST]=clamp(bulletdrop,0,600);

		int zoom=getloadoutvar(input,"zoom",3);
		if(zoom>0)weaponstatus[BOSSS_ZOOM]=
			(weaponstatus[0]&BOSSF_FRONTRETICLE)?
			clamp(zoom,12,40):
			clamp(zoom,5,60);
	}
}
enum bossstatus{
	BOSSF_FRONTRETICLE=1,
	BOSSF_CUSTOMCHAMBER=2,
	BOSSF_UNLOADONLY=4,
	BOSSF_DONTUSECLIPS=8,

	BOSSS_CHAMBER=1, //0=nothing, 1=brass, 2=loaded, 3/4=jammed brass/round
	BOSSS_MAG=2,
	BOSSS_ZOOM=3,
	BOSSS_DROPADJUST=4,
	BOSSS_HEAT=5,
	BOSSS_HAND=6,
	BOSSS_GRIME=7,
}


