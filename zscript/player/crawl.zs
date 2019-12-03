// ------------------------------------------------------------
// CRAAAAAAAAAAAWWWWLING IN MY SKIN
// ------------------------------------------------------------
extend class HDHandlers{
	void PlayDead(hdplayerpawn ppp){
		if(!ppp||ppp.incapacitated>0)return;
		ppp.A_Incapacitated(hdplayerpawn.HDINCAP_FAKING);
	}
}
const HDCONST_MINSTANDHEALTH=12;
extend class HDPlayerPawn{
	int incapacitated;
	int incaptimer;
	inventory invselbak;
	void IncapacitatedCheck(){
		if(!incapacitated)return;
		if(incaptimer>0){
			incaptimer--;
			muzzleclimb1.y+=(level.time&1)?-1:1;
		}

		if(incapacitated>0){
			A_SetSize(radius,max(16,height-3));
			if(!countinv("HDIncapWeapon")){
				A_SetInventory("HDIncapWeapon",1);
				if(player&&player.readyweapon){
					if(
						player.cmd.buttons&(
							BT_ATTACK|BT_ALTATTACK|BT_RELOAD|BT_ZOOM
							|BT_USER1|BT_USER2|BT_USER3|BT_USER4
						)||(
							hdweapon(player.readyweapon)
							&&hdweapon(player.readyweapon).bweaponbusy
						)
					)DropInventory(player.readyweapon);
					else player.setpsprite(PSP_WEAPON,player.readyweapon.findstate("deselect"));
				}
			}else{
				A_SelectWeapon("HDIncapWeapon");
			}
		}else{
			A_SetSize(radius,min(48,height+3));
		}
		player.viewz=min(ceilingz-6,pos.z+viewheight*(height/48.)+hudbob.y*0.1);

		if(invsel){
			invselbak=invsel;
			invsel=null;
		}

		frame=clamp(6+abs(incapacitated>>2),6,11);

		if(incapacitated<((11-6)<<2)){
			if(zerk>0&&incapacitated<0)incapacitated=min(0,incapacitated+4);
			incapacitated++;
		}

		if(pitch<70)muzzleclimb1.y+=frandom(0.1,0.4);

		runwalksprint=-1;
		speed=0.02;
		userange=20;
		if(
			health>HDCONST_MINSTANDHEALTH+1
			&&incapacitated>0
			&&incaptimer<1
			&&(
				player.cmd.buttons&BT_JUMP
				||player.bot
				||(zerk>500&&!random(0,255))
			)
		){
			scale.y=1.;
			incapacitated=-((11-6)<<2);
		}
		if(
			incaptimer>0
			&&health>HDCONST_MINSTANDHEALTH
			&&health<HDCONST_MINSTANDHEALTH+3
		){
			damagemobj(null,null,min(5,health-10),"maxhpdrain");
		}

		if(
			!incapacitated
			||zerk>4000
		){
			A_Capacitated();
		}
	}
	void A_Capacitated(){
		incapacitated=0;
		A_TakeInventory("HDIncapWeapon");
		A_SetSize(getdefaultbytype("HDPlayerPawn").radius,getdefaultbytype("HDPlayerPawn").height);
		userange=getdefaultbytype("HDPlayerPawn").userange;
		player.viewheight=viewheight*player.crouchfactor;
		if(invselbak&&invselbak.owner==self)invsel=invselbak;else{
			for(let item=inv;item!=null;item=item.inv){
				if(
					item.binvbar
				){
					invsel=item;
					break;
				}
			}
		}
		if(pos.z+height>ceilingz)player.crouchfactor=((ceilingz-pos.z)/height);
		setstatelabel("spawn");
	}
	void A_Incapacitated(int flags=0,int incaptime=35){
		let ppp=player;
		if(!ppp)return;
		if(
			!(flags&HDINCAP_FAKING)
			&&!random(0,15)
		)Disarm(self);
		else{
			let www=hdweapon(ppp.readyweapon);
			if(www)www.OnPlayerDrop();
			if(flags&HDINCAP_SCREAM)A_PlayerScream();
		}
		if(
			!(flags&HDINCAP_FAKING)
			&&health<10
		)GiveBody(7);
		incapacitated=1;
		incaptimer=incaptime;
		setstatelabel("spawn");
	}
	enum IncapFlags{
		HDINCAP_FAKING=1,
		HDINCAP_SCREAM=2,
	}
}


class HDIncapWeapon:SelfBandage{
	class<actor> injecttype;
	class<actor> spentinjecttype;
	class<inventory> inventorytype;
	default{
		+hdweapon.reverseguninertia
		weapon.bobspeed 0.7;
	}
	action void A_PickInventoryType(){
		static const class<inventory> types[]={
			"HDIncapWeapon",
			"PortableStimpack",
			"PortableBerserkpack",
			"HDFragGrenadeAmmo"
		};

		if(
			!invoker.weaponstatus[INCS_INDEX]
			&&!countinv("PortableStimpack")
			&&countinv("PortableMedikit")
		){
			UseInventory(findinventory("PortableMedikit"));
			invoker.spentinjecttype="SpentStim";
			invoker.injecttype="InjectStimDummy";
			return;
		}


		int which=invoker.weaponstatus[INCS_INDEX];
		do{
			which++;
			if(which>=types.size())which=0;
		}while(!countinv(types[which]));
		invoker.weaponstatus[INCS_INDEX]=which;

		let inventorytype=types[which];
		if(
			!countinv(inventorytype)
		){
			inventorytype="HDIncapWeapon";
			return;
		}else if(inventorytype=="PortableBerserkPack"){
			invoker.spentinjecttype="SpentZerk";
			invoker.injecttype="InjectZerkDummy";
		}
		else if(inventorytype=="PortableStimpack"){
			invoker.spentinjecttype="SpentStim";
			invoker.injecttype="InjectStimDummy";
		}
		else if(inventorytype=="HDFragGrenadeAmmo"){
			invoker.spentinjecttype="HDFragSpoon";
			invoker.injecttype="HDFragGrenadeRoller";
		}
		invoker.inventorytype=inventorytype;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		super.DrawHUDStuff(sb,hdw,hpl);
		if(hpl.player.cmd.buttons&BT_ATTACK)return;
		int yofss=weaponstatus[INCS_YOFS]-((hpl.player.cmd.buttons&BT_ALTATTACK)?(50+5*hpl.flip):60);
		vector2 bob=(hpl.hudbob.x*0.2,hpl.hudbob.y*0.2+yofss);
		if(inventorytype=="HDFragGrenadeAmmo"){
			sb.drawimage(
				(weaponstatus[0]&INCF_PINOUT)?"FRAGF0":"FRAGA0",
				bob,sb.DI_SCREEN_CENTER_BOTTOM,scale:(1.6,1.6)
			);
		}else if(inventorytype=="PortableBerserkpack"){
			sb.drawimage("PSTRA0",bob,sb.DI_SCREEN_CENTER_BOTTOM,scale:(2.,2.));
		}else if(inventorytype=="PortableStimpack"){
			sb.drawimage("STIMA0",bob,sb.DI_SCREEN_CENTER_BOTTOM,scale:(2.,2.));
		}
	}
	override string gethelptext(){
		return
		WEPHELP_FIRE.."  Try to stop the bleeding\n"
		..WEPHELP_RELOAD.."  Take off armour\n"
		..WEPHELP_ALTFIRE.."  Use the item in hand\n"
		..WEPHELP_FIREMODE.."  Fumble for something else\n"
		..((
			hdplayerpawn(owner)
			&&hdplayerpawn(owner).incapacitated
			&&hdplayerpawn(owner).incaptimer<1
		)?(WEPHELP_BTCOL.."Jump"..WEPHELP_RGCOL.."  Get up\n"):"")
		;
	}
	states{
	select:
		TNT1 A 0 A_Raise();
		wait;
	ready:
		TNT1 A 0 A_WeaponReady(WRF_ALLOWUSER2|WRF_ALLOWRELOAD|WRF_DISABLESWITCH);
		TNT1 A 1{
			invoker.weaponstatus[INCS_YOFS]=invoker.weaponstatus[INCS_YOFS]*2/3;
			A_SetHelpText();
		}
		goto readyend;
	firemode:
		TNT1 A 1{
			int yofs=max(4,invoker.weaponstatus[INCS_YOFS]*3/2);
			if(
				yofs>100
				&&pressingfiremode()
			)setweaponstate("fumbleforsomething");
			else invoker.weaponstatus[INCS_YOFS]=yofs;
		}
		TNT1 A 0 A_JumpIf(pressingfiremode(),"firemode");
		goto readyend;
	fumbleforsomething:
		TNT1 A 20 A_PlaySound("weapons/pocket",CHAN_WEAPON);
		TNT1 A 0 A_PickInventoryType();
		goto nope;
	altfire:
	althold:
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&INCF_PINOUT,"holdfrag");
		TNT1 A 10 A_JumpIf(health<HDCONST_MINSTANDHEALTH&&!random(0,7),"nope");
		TNT1 A 20 A_PlaySound("weapons/pocket",CHAN_WEAPON);
		TNT1 A 0 A_JumpIf(!countinv(invoker.inventorytype),"fumbleforsomething");
		TNT1 A 0 A_JumpIf(invoker.inventorytype=="HDFragGrenadeAmmo","pullpin");
		TNT1 A 0 A_JumpIf(
			invoker.inventorytype=="PortableStimpack"
			||invoker.inventorytype=="PortableBerserkpack"
			,"injectstim");
		goto nope;
	injectstim:
		TNT1 A 1{
			A_SetBlend("7a 3a 18",0.1,4);
			A_SetPitch(pitch+2,SPF_INTERPOLATE);
			A_PlaySound("*usemeds",CHAN_VOICE);
			A_PlaySound("misc/bulletflesh",CHAN_WEAPON);
			actor a=spawn(invoker.injecttype,pos,ALLOW_REPLACE);
			a.accuracy=40;a.target=self;
		}
		TNT1 AAAA 1 A_SetPitch(pitch-0.5,SPF_INTERPOLATE);
		TNT1 A 6;
		TNT1 A 0{
			actor a=spawn(invoker.spentinjecttype,pos+(0,0,height-8),ALLOW_REPLACE);
			a.angle=angle;a.vel=vel;a.A_ChangeVelocity(3,1,2,CVF_RELATIVE);
			a.A_PlaySound("weapons/grenopen",CHAN_WEAPON);
			A_TakeInjector(invoker.inventorytype);
			invoker.inventorytype="";
		}
		goto nope;
	pullpin:
		TNT1 A 3 A_JumpIf(health<HDCONST_MINSTANDHEALTH&&!random(0,4),"readyend");
		TNT1 A 0{
			if(!countinv(invoker.inventorytype))return;
			invoker.weaponstatus[0]|=INCF_PINOUT;
			A_PlaySound("weapons/fragpinout",CHAN_WEAPON);
			A_TakeInventory(invoker.inventorytype,1);
		}
		//fallthrough
	holdfrag:
		TNT1 A 2 A_ClearRefire();
		TNT1 A 0{
			int buttons=player.cmd.buttons;
			if(buttons&BT_RELOAD)setweaponstate("pinbackin");
			else if(buttons&BT_ALTFIRE)setweaponstate("holdfrag");
		}
		TNT1 A 10;
		TNT1 A 0{invoker.DropFrag();}
		goto readyend;
	pinbackin:
		TNT1 A 10;
		TNT1 A 0 A_JumpIf(health<HDCONST_MINSTANDHEALTH&&!random(0,2),"holdfrag");
		TNT1 A 20{
			A_PlaySound("weapons/fragpinout",CHAN_WEAPON);
			invoker.weaponstatus[0]&=~INCF_PINOUT;
			A_GiveInventory("HDFragGrenadeAmmo",1);
		}
		goto nope;
	}
	override void OwnerDied(){
		DropFrag();
		super.OwnerDied();
	}
	override void DetachFromOwner(){
		DropFrag();
		super.DetachFromOwner();
	}
	override inventory CreateTossable(){
		if(owner){
			owner.A_DropInventory("PortableMedikit");
			owner.A_DropInventory("HDMedikitter");
		}
		return null;
	}
	void DropFrag(){
		if(
			!(weaponstatus[0]&INCF_PINOUT)
			||!owner
		)return;
		weaponstatus[0]&=~INCF_PINOUT;
		//create the spoon
		owner.A_SpawnItemEx(spentinjecttype,
			-4,-3,owner.height-8,
			1,2,3,
			frandom(33,45),SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
		//create the grenade
		owner.A_SpawnItemEx(injecttype,
			0,0,owner.height,
			2,0,-2,
			0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
		inventorytype="";
	}
	enum CrawlingInts{
		INCF_PINOUT=1,
		INCS_YOFS=1,
		INCS_INDEX=2,
	}
}

