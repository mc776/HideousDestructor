// ------------------------------------------------------------
// Prototype weapon
// ------------------------------------------------------------
class HDWeapon:Weapon{
	int HDWeaponFlags;
	flagdef DropTranslation:HDWeaponFlags,0;
	flagdef WeaponBusy:HDWeaponFlags,1;
	flagdef FitsInBackpack:HDweaponFlags,2;
	flagdef DontFistOnDrop:HDweaponFlags,3;
	flagdef JustChucked:HDWeaponFlags,4;
	flagdef ReverseGunInertia:HDWeaponFlags,5;
	flagdef AlwaysShowStatus:HDWeaponFlags,6;
	flagdef DontDefaultConfigure:HDWeaponFlags,7;

	double barrellength;
	double barrelwidth;
	double barreldepth;
	property barrelsize:barrellength,barrelwidth,barreldepth;
	string refid;
	property refid:refid;
	string nicename;
	property nicename:nicename;
	int weaponstatus[8];
	int msgtimer;
	int actualamount;
	string wepmsg;
	enum HDWeaponFlagsets{
		WRF_ALL=WRF_ALLOWRELOAD|WRF_ALLOWZOOM|WRF_ALLOWUSER1|WRF_ALLOWUSER2|WRF_ALLOWUSER3|WRF_ALLOWUSER4,
		WRF_NONE=WRF_NOFIRE|WRF_DISABLESWITCH,
		BT_ALTFIRE=BT_ALTATTACK,
		BT_ALTRELOAD=BT_USER1,
		BT_FIREMODE=BT_USER2,
		BT_UNLOAD=BT_USER4,
	}
	default{
		+solid
		+weapon.ammo_optional +weapon.alt_ammo_optional +weapon.noalert +weapon.noautoaim
		+weapon.no_auto_switch
		+noblockmonst +notrigger +dontgib
		+usebouncestate +hittracer
		-hdweapon.dontfistondrop
		-hdweapon.fitsinbackpack
		weapon.ammogive 0;weapon.ammogive2 0;
		weapon.ammouse1 0;weapon.ammouse2 0;
		weapon.bobstyle "Alpha";
		inventory.pickupsound "misc/w_pkup";
		radius 12;height 12;

		weapon.bobspeed 2.4;
		weapon.bobrangex 0.2;
		weapon.bobrangey 0.8;
		hdweapon.barrelsize 0,0,0;
		hdweapon.refid "";
		hdweapon.nicename "";
	}
	override bool getnoteleportfreeze(){return true;}
	override bool cancollidewith(actor other,bool passive){return bmissile||HDPickerUpper(other);}
	//wrapper for setpsprite
	action void SetWeaponState(statelabel st,int layer=PSP_WEAPON){
		if(player)player.setpsprite(layer,invoker.findstate(st));
	}
	//use target to help a dropped weapon remember its immediately prior owner
	override void detachfromowner(){
		actor oldowner=owner;
		if(!bdontfistondrop&&oldowner.player&&!oldowner.player.readyweapon){
			oldowner.A_SelectWeapon("HDFist");
			let fff=HDFist(oldowner.findinventory("HDFist"));
			if(fff)fff.washolding=true;
		}
		angle=oldowner.angle;pitch=oldowner.pitch;
		target=oldowner;
		if(bdroptranslation)translation=oldowner.translation;
		super.detachfromowner();
	}
	//wrapper for HDMath.MaxInv because we're gonna need this a lot
	action int AmmoCap(class<inventory> inv){
		return HDMath.MaxInv(self,inv);
	}
	//wrapper for checking if gun is braced
	action bool gunbraced(){
		return hdplayerpawn(self)&&hdplayerpawn(self).gunbraced;
	}
	//set the weapon as "busy" to reduce movement, etc.
	action void A_WeaponBusy(bool yes=true){invoker.bweaponbusy=yes;}
	static void SetBusy(actor onr,bool yes=true){
		if(onr.player&&hdweapon(onr.player.readyweapon))
		hdweapon(onr.player.readyweapon).bweaponbusy=yes;
	}
	static bool IsBusy(actor onr){
		return(
			onr.player
			&&hdweapon(onr.player.readyweapon)
			&&hdweapon(onr.player.readyweapon).bweaponbusy
		);
	}
	//use this to set flash translucency and make it additive
	action void HDFlashAlpha(int variance=0,bool noalpha=false,int layer=PSP_FLASH){
		A_OverlayFlags(layer,PSPF_ALPHA|PSPF_ADDBOB|PSPF_RENDERSTYLE,true);
		A_OverlayRenderstyle(layer,STYLE_Add);
		double fa;
		if(noalpha){
			A_OverlayAlpha(layer,1.);
		}else{
			int lg=cursector.lightlevel-variance*frandom(0.6,1.);
			fa=1.-(lg*0.003);
			A_OverlayAlpha(layer,fa);
		}
		if(noalpha||fa>0.1)setstatelabel("melee");
	}
	//wrapper for HDWeapon and ActionItem
	//remember: LEFT and DOWN
	action void A_MuzzleClimb(
		double mc10=0,double mc11=0,
		double mc20=0,double mc21=0,
		double mc30=0,double mc31=0,
		double mc40=0,double mc41=0,
		bool wepdot=true
	){
		let hdp=HDPlayerPawn(self);
		if(hdp){
			hdp.A_MuzzleClimb((mc10,mc11),(mc20,mc21),(mc30,mc31),(mc40,mc41),wepdot);
		}else{ //I don't even know why
			vector2 mc0=(mc10,mc11)+(mc20,mc21)+(mc30,mc31)+(mc40,mc41);
			A_SetPitch(pitch+mc0.y,SPF_INTERPOLATE);
			A_SetAngle(angle+mc0.x,SPF_INTERPOLATE);
		}
	}
	action void A_ZoomRecoil(double prop){
		let hdp=hdplayerpawn(self);
		if(hdp){
			if(hdp.zerk)prop=(prop+1.)*0.5;
			if(hdp.gunbraced)prop=(prop+1.)*0.5;
			hdp.recoilfov=(hdp.recoilfov+prop)*0.5;
		}
	}
	//do these whenever the gun is ready
	action void A_ReadyEnd(){
		A_WeaponBusy(false);
		if(invoker.msgtimer>0){
			invoker.msgtimer--;
			if(invoker.msgtimer<1)invoker.wepmsg="";
		}
		let p=HDPlayerPawn(self);
		if(!p)return;
		p.mousehijacked=false;
		p.movehijacked=false;
		if(
			player&&
			p&&!p.beatcount&&p.zerk>900
			&&!random(0,(invoker is "HDFist")?20:100)
		)player.cmd.buttons|=BT_ATTACK;

		if(
			player.bot&&
			!random(0,3)
		)setweaponstate("botreload");
	}

	//for when the player dies or collapses
	virtual void OnPlayerDrop(){}

	//forces you to have some ammo, called in encumbrance
	virtual void ForceBasicAmmo(){}

	//activate a laser rangefinder
	//because every gun should have one of these
	action void FindRange(){
		eventhandler.sendnetworkevent("hd_findrange",0,0,0);
	}

	//stops turning input
	action void HijackMouse(){
		let ppp=hdplayerpawn(self);if(ppp)ppp.mousehijacked=true;
		else player.cmd.pitch=0;player.cmd.yaw=0;
	}

	//stops moving input
	action void HijackMove(){
		let ppp=hdplayerpawn(self);if(ppp)ppp.movehijacked=true;
		else player.cmd.forwardmove=0;player.cmd.sidemove=0;
	}

	//for throwing a weapon
	override inventory CreateTossable(int amount){
		let onr=hdplayerpawn(owner);
		bool throw=(
			onr&&(
				onr.zerk
				||(
					onr.player
					&&onr.player.cmd.buttons&BT_ZOOM
				)
			)
		);
		bool isreadyweapon=onr&&onr.player&&onr.player.readyweapon==self;
		if(!isreadyweapon)throw=false;
		let thrown=super.createtossable(amount);
		if(!thrown)return null;
		let newwep=GetSpareWeapon(onr,doselect:isreadyweapon);
		hdweapon(thrown).bjustchucked=true;
		thrown.target=onr;
		if(throw){
			thrown.bmissile=true;
			thrown.bBOUNCEONWALLS=true;
			thrown.bBOUNCEONFLOORS=true;
			thrown.bALLOWBOUNCEONACTORS=true;
			thrown.bBOUNCEAUTOOFF=true;
		}else{
			thrown.bmissile=false;
			thrown.bBOUNCEONWALLS=false;
			thrown.bBOUNCEONFLOORS=false;
			thrown.bALLOWBOUNCEONACTORS=false;
			thrown.bBOUNCEAUTOOFF=false;
		}
		return thrown;
	}
	//an override is needed because DropInventory will undo anything done in CreateTossable
	double throwvel;
	override void Tick(){
		super.Tick();
		if(bjustchucked&&target){
			double cp=cos(target.pitch);
			if(bmissile){
				vel=target.vel+
					(cp*cos(target.angle),cp*sin(target.angle),-sin(target.pitch))
					*min(20,1000/weaponbulk())
					*((hdplayerpawn(target)&&hdplayerpawn(target).zerk>0)?frandom(1,4):1
				);
			}else vel=target.vel+2*(cp*cos(target.angle),cp*sin(target.angle),-sin(target.pitch))*2;
			setz(target.pos.z+target.height-16);
			throwvel=vel dot vel;
			bjustchucked=false;
		}
		if(owner){
			if(amount<1){
				destroy();
				return;
			}else{
				//update count
				actualamount=1;
				if(owner&&owner.findinventory("SpareWeapons")){
					let spw=spareweapons(owner.findinventory("SpareWeapons"));
					string gcn=getclassname();
					for(int i=0;i<spw.weapontype.size();i++){
						if(spw.weapontype[i]==gcn)actualamount++;
					}
				}
			}
			let onr=hdplayerpawn(owner);
			if(
				!bwimpy_weapon
				&&!hdfist(self)
				&&onr
				&&onr.player
				&&onr.player.readyweapon==self
				&&!onr.barehanded
				&&onr.zerk
				&&(
					onr.player.cmd.buttons&BT_ATTACK
					||onr.player.cmd.buttons&BT_ALTATTACK
					||onr.player.cmd.buttons&BT_ZOOM
					||bweaponbusy
					||onr.vel.xy==(0,0)
				)
				&&!random(0,511)
			){
				onr.A_PlaySound(random(0,5)?"*xdeath":"*taunt",CHAN_VOICE);
				onr.A_AlertMonsters();
				onr.dropinventory(self);
			}
		}
	}
	action void A_GunBounce(){invoker.GunBounce();}
	virtual void GunBounce(){
		bmissile=false;
		bBOUNCEONWALLS=false;
		bBOUNCEONFLOORS=false;
		bALLOWBOUNCEONACTORS=false;
		bBOUNCEAUTOOFF=false;
		double wb=weaponbulk();
		int dmg=int(throwvel*wb*wb*frandom(0.000001,0.00002));
		if(tracer){
			tracer.damagemobj(self,target,dmg,"Bashing");
			if(hd_debug)A_Log(tracer.getclassname().." hit for "..dmg.." damage with thrown "..getclassname());
		}
		A_PlaySound("weapons/smack",CHAN_BODY,min(0.5,dmg*0.02));
		setstatelabel("spawn");
	}

	//zoom adjuster for rifles
	action void A_ZoomAdjust(int slot,int minzoom,int maxzoom,int secondbutton=BT_USER2){
		if(!PressingZoom()){
			setweaponstate("nope");
			return;
		}
		if(!(player.cmd.buttons&secondbutton)){
			A_WeaponReady(WRF_ALL);
			return;
		}
		int inputamt=player.cmd.pitch>>5;
		inputamt+=(justpressed(BT_ATTACK)?1:justpressed(BT_ALTATTACK)?-1:0);
		HijackMouse();
		invoker.weaponstatus[slot]=clamp(
			invoker.weaponstatus[slot]-inputamt,minzoom,maxzoom
		);
		A_WeaponReady(WRF_NOFIRE);
	}

	//determine mass for weapon inertia purposes
	virtual double gunmass(){return 0;}
	//determine bulk for weapon encumbrance purposes
	virtual double weaponbulk(){return 0;}

	//for consolidating stuff between maps
	virtual void Consolidate(){}

	//what to do when hitting the "drop one unit of ammo" key
	virtual void DropOneAmmo(int amt=1){}

	//for smoking barrels
	void drainheat(int ref,int smklength=18){
		if(isfrozen())return;
		if(weaponstatus[ref]>0){
			weaponstatus[ref]--;
			if(random(1,10)>weaponstatus[ref])return;
			vector3 smkpos=pos;
			vector3 smkvel=vel;
			double smkang=angle;
			if(owner){
				smkpos=owner.pos;
				if(owner.player && owner.player.readyweapon==self){
					//spawn smoke from muzzle
					if(hdplayerpawn(owner)&&hdplayerpawn(owner).scopecamera){
						let sccam=hdplayerpawn(owner).scopecamera;
						smkang=sccam.angle;
						smkpos.z+=owner.height-9-sin(sccam.pitch)*smklength;
						smkpos.xy+=cos(sccam.pitch)*smklength*(cos(smkang),sin(smkang));
					}else{
						smkang=owner.angle;
						smkpos.z+=owner.height-9-sin(owner.pitch)*smklength;
						smkpos.xy+=cos(owner.pitch)*smklength*(cos(smkang),sin(smkang));
					}
				}else{
					//spawn smoke from behind owner
					smkang=owner.angle;
					smkpos.z+=owner.height*0.6;
					smkpos.xy-=10*(cos(smkang),sin(smkang));
				}
				smkvel=owner.vel;
			}
			actor a=spawn("HDGunsmoke",smkpos,ALLOW_REPLACE);
			smkvel*=0.4;
			a.angle=smkang;a.vel+=smkvel;
			a.A_ChangeVelocity(3,0,0,CVF_RELATIVE);
			for(int i=30;i<weaponstatus[ref];i+=30){
				if(!random(0,3)){
					a=spawn("HDGunsmoke",smkpos,ALLOW_REPLACE);
					a.angle=smkang;a.vel+=smkvel;
					a.A_ChangeVelocity(3,frandom(-2,2),frandom(-2,2),CVF_RELATIVE);
				}
			}
		}
	}
	//interface stuff
	virtual clearscope string,double getpickupsprite(){return "",1.;}
	virtual ui int getsbarnum(int flags=0){return -1000000;}
	virtual ui void DrawHUDStuff(HDStatusBar sb,HDWeapon wp,HDPlayerPawn hpl){}
	virtual ui void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hcp,
		string whichdot="redpxl"
	){}
	virtual string gethelptext(){return "";}
	action void A_SetHelpText(){
		let hdp=hdplayerpawn(self);if(hdp){
			string ttt=invoker.gethelptext();
			if(ttt!="")hdp.wephelptext="\cu"..invoker.nicename.."\n"..ttt;
			else hdp.wephelptext=ttt;
		}
	}
	//that said, why get picky when you can just shoot twice?
	action void A_MagManager(name type){
		A_SetInventory("MagManager",1);
		let mmm=MagManager(findinventory("MagManager"));
		mmm.thismag=hdmagammo(findinventory(type));mmm.thismagtype=type;
		UseInventory(mmm);
	}

	//for picking up
	override void touch(actor toucher){}
	virtual void actualpickup(actor other,bool silent=false){
		let oldwep=hdweapon(other.findinventory(getclassname()));
		if(
			oldwep
			&&hdplayerpawn(other)
			&&hdplayerpawn(other).neverswitchonpickup.getbool()
		){
			addspareweapon(other);
			return;
		}
		if(
			oldwep
			&&!oldwep.AddSpareWeapon(other)
		){
			//fast-unload weapon without picking it up
			angle=other.angle-70;
			failedpickupunload();
			return;
		}
		if(!self)return;
		if(!silent){
			other.A_Log(string.format("\cg%s",pickupmessage()),true);
			other.A_PlaySound(pickupsound,CHAN_AUTO);
		}
		attachtoowner(other);
	}

	//when you have the same gun, just strip the new one
	virtual void failedpickupunload(){}
	void failedpickupunloadmag(int magslot,class<hdmagammo> type){
		if(weaponstatus[magslot]<0)return;
		A_PlaySound("weapons/rifleclick2",CHAN_WEAPON);
		A_PlaySound("weapons/rifleload",5);
		HDMagAmmo.SpawnMag(self,type,weaponstatus[magslot]);
		weaponstatus[magslot]=-1;
		setstatelabel("spawn");
	}

	//swap out alternative "fixed" weapon sprites - id
	action void A_CheckIdSprite(string altsprite,string regsprite,int layer=PSP_WEAPON){
		bool needspritefix=false;
		if(
			Wads.CheckNumForName("id",0)!=-1
			&&texman.checkfortexture(altsprite,texman.type_sprite).isvalid()
		){
			int i=-1,counter=0;
			do{
				i=wads.findLump(regsprite,i+1,1);
				counter++;
			}until (i<0);
			if(counter<=2)needspritefix=true; //original + textures replacement = 2
		}
		if(needspritefix)Player.GetPSprite(layer).sprite=GetSpriteIndex(altsprite);
		else Player.GetPSprite(layer).sprite=GetSpriteIndex(regsprite);
	}

	//because weapons don't use proper "ammo" anymore for loaded items
	virtual void InitializeWepStats(bool idfa=false){}
	override void beginplay(){
		for(int i=0;i<8;i++)weaponstatus[i]=0;
		msgtimer=0;wepmsg="";
		initializewepstats();
		bobrangex*=3;bobrangey*=3;
		bdontbob=true;
		super.beginplay();
	}

	//parse what would normally be the amount string as a set of variables
	virtual void loadoutconfigure(string input){}
	//retrieves the entire hd_weapondefaults cvar for a given player
	static string getdefaultcvar(playerinfo pl){
		if(!pl)return "";
		string weapondefaults=cvar.getcvar("hd_weapondefaults",pl).getstring();
		weapondefaults=weapondefaults.makelower();
		weapondefaults.replace(" ","");
		return weapondefaults;
	}
	//apply config from owner's hd_weapondefaults cvar
	void defaultconfigure(playerinfo whichplayer,string weapondefaults="cvar"){
		bdontdefaultconfigure=true;
		if(!whichplayer)return;
		if(weapondefaults=="cvar")weapondefaults=hdweapon.getdefaultcvar(whichplayer);
		if(weapondefaults=="")return;
		weapondefaults.replace(" ","");
		weapondefaults.makelower();
		int defvarstart=weapondefaults.indexof(refid);
		if(defvarstart>=0){
			string wepdefault=weapondefaults.mid(defvarstart);
			int defcomma=wepdefault.indexof(",");
			if(defcomma>=0)wepdefault=wepdefault.left(defcomma);
			loadoutconfigure(wepdefault);
		}
	}
	//parse a weapon loadout variable to an int
	int getloadoutvar(string input,string varname,int maxdigits=int.MAX){
		int varstart=input.indexof(varname);
		if(varstart<0)return -1;
		int digitstart=varstart+varname.length();
		string inp=input.mid(digitstart,maxdigits);
		if(inp=="0")return 0;
		if(inp.indexof("e")>=0)inp=inp.left(inp.indexof("e")); //"123e45"
		if(inp.indexof("x")>=0)inp=inp.left(inp.indexof("x")); //"0xffffff..."
		int inpint=inp.toint();
		if(!inpint)return 1; //var merely mentioned with no number
		return inpint;
	}

	override void postbeginplay(){
		super.postbeginplay();
		if(hdpickup.checkblacklist(self,refid))return;
		if(!bwimpy_weapon)bno_auto_switch=false;
		if(!bdontdefaultconfigure&&owner&&owner.player)defaultconfigure(owner.player);
	}
	//because A_Print doesn't cut it
	action void A_WeaponMessage(string msg,int time=100){
		invoker.wepmsg=msg;
		invoker.msgtimer=abs(time);
		if(time<0)A_Log(msg,true);
	}
	//because I'm too lazy to retype all that shit
	action bool PressingFire(){return player.cmd.buttons&BT_ATTACK;}
	action bool PressingAltfire(){return player.cmd.buttons&BT_ALTATTACK;}
	action bool PressingReload(){return player.cmd.buttons&BT_RELOAD;}
	action bool PressingZoom(){return player.cmd.buttons&BT_ZOOM;}
	action bool PressingAltReload(){return player.cmd.buttons&BT_USER1;}
	action bool PressingFiremode(){return player.cmd.buttons&BT_USER2;}
	action bool PressingUser3(){return player.cmd.buttons&BT_USER3;}
	action bool PressingUnload(){return player.cmd.buttons&BT_USER4;}
	action bool PressingUse(){return player.cmd.buttons&BT_USE;}
	action bool Pressing(int whichbuttons){return player.cmd.buttons&whichbuttons;}
	action bool JustPressed(int whichbutton){return(
		player.cmd.buttons&whichbutton&&!(player.oldbuttons&whichbutton)
	);}
	action bool JustReleased(int whichbutton){return(
		!(player.cmd.buttons&whichbutton)&&player.oldbuttons&whichbutton
	);}
	action void A_StartDeselect(bool gotodzero=true){
		A_WeaponBusy();
		A_SetCrosshair(21);
		invoker.wepmsg="";invoker.msgtimer=0;
		if(gotodzero)setweaponstate("deselect0");
	}
	states{
	spawn:
		TNT1 A 0;
		stop;
	bounce:
	death:
		---- A 0 A_GunBounce();
		goto spawn;
	select:
		TNT1 A 0{
			//these two don't actually work???
			A_OverlayFlags(PSP_WEAPON,PSPF_CVARFAST|PSPF_POWDOUBLE,false);
			A_OverlayFlags(PSP_FLASH,PSPF_CVARFAST|PSPF_POWDOUBLE,false);

			A_WeaponBusy();
			A_SetCrosshair(21);
			A_SetHelpText();

			return resolvestate("select0");
		}
	select0:
		---- A 0 A_Raise();
		wait;
	deselect:
		TNT1 A 0 A_StartDeselect();
	deselect0:
		---- A 0 A_Lower();
		wait;

	select0big:
		---- A 2 A_JumpIfInventory("NulledWeapon",1,"select1big");
		---- A 0 A_TakeInventory("NulledWeapon");
		---- A 1 A_Raise(30);
		---- A 1 A_Raise(30);
		---- A 1 A_Raise(24);
		---- A 1 A_Raise(11);
		---- A 1 A_WeaponOffset(0,-4,WOF_ADD);
		---- A 1 A_WeaponOffset(0,1,WOF_ADD);
		---- A 1 A_WeaponOffset(0,2,WOF_ADD);
		---- A 1 A_Raise(0);
		wait;
	deselect0big:
		---- A 0 A_JumpIfInventory("NulledWeapon",1,"deselect1big");
		---- A 1 A_Lower(0);
		---- A 1 A_Lower(1);
		---- AA 1 A_Lower(1);
		---- A 1 A_Lower(3);
		---- AA 1 A_Lower();
		---- A 1 A_Lower(12);
		---- A 1 A_Lower(24);
		---- A 1 A_Lower(30);
		---- A 1 A_Lower();
		wait;
	deselect1big:
		---- AA 1 A_Lower(1);
		---- AA 1 A_Lower(2);
		---- A 1 A_Lower(24);
		---- A 1 A_Lower(24);
		---- A 1 A_Lower(30);
		wait;
	select1big:
		---- A 0 A_TakeInventory("NulledWeapon");
		---- A 1 A_Raise(36);
		---- A 1 A_Raise(35);
		---- A 1 A_Raise(24);
		---- A 1 A_WeaponOffset(0,-4,WOF_ADD);
		---- A 1 A_WeaponOffset(0,1,WOF_ADD);
		---- A 1 A_WeaponOffset(0,2,WOF_ADD);
		---- A 1 A_Raise(0);
		wait;
	select0small:
		---- A 1 A_JumpIfInventory("NulledWeapon",1,"select1small");
		---- A 0 A_TakeInventory("NulledWeapon");
		---- A 1 A_Raise(10);
		---- A 1 A_Raise(36);
		---- A 1 A_Raise(30);
		---- A 1 A_Raise(12);
		---- A 1 A_Raise(6);
		---- A 1 A_WeaponOffset(0,-2,WOF_ADD);
		---- A 1 A_WeaponOffset(0,1,WOF_ADD);
		---- A 1 A_Raise(1);
		wait;
	deselect0small:
		---- A 0 A_JumpIfInventory("NulledWeapon",1,"deselect1small");
		---- A 1 A_Lower(1);
		---- AA 1 A_Lower(2);
		---- AA 1 A_Lower();
		---- A 1 A_Lower(12);
		---- A 1 A_Lower(30);
		---- A 1 A_Lower(36);
		---- A 1 A_Lower();
		wait;
	deselect1small:
		---- A 1 A_Lower(1);
		---- A 1 A_Lower();
		---- A 1 A_Lower(12);
		---- A 1 A_Lower(24);
		---- A 1 A_Lower(30);
		---- A 1 A_Lower(36);
		wait;
	select1small:
		---- A 0 A_TakeInventory("NulledWeapon");
		---- A 1 A_Raise(36);
		---- A 1 A_Raise(30);
		---- A 1 A_Raise(16);
		---- A 1 A_Raise(12);
		---- A 1 A_WeaponOffset(0,2,WOF_ADD);
		---- A 1 A_Raise(1);
		wait;
	select0bfg:
		---- A 3 A_JumpIfInventory("NulledWeapon",1,"select1bfg");
		---- A 0 A_TakeInventory("NulledWeapon");
		---- A 1 A_Raise();
		---- A 1 A_Raise(24);
		---- A 1 A_Raise(18);
		---- A 1 A_Raise(12);
		---- AAA 1 A_Raise();
		---- A 1 A_Raise(-2);
		---- AA 1 A_Raise(-1);
		---- AA 1{
			A_MuzzleClimb(0.3,0.8);
			A_Raise(-1);
		}
		---- AA 1 A_MuzzleClimb(-0.1,-0.4);
		---- AA 1 A_Raise();
		---- A 1 A_Raise();
		---- A 1 A_Raise(12);
		---- A 1 A_Raise(12);
		wait;
	deselect0bfg:
		---- A 0 A_JumpIfHealthLower(1,"deselect1big");
		---- A 0 A_JumpIfInventory("NulledWeapon",1,"deselect1bfg");
		---- AA 1 A_Lower(0);
		---- AA 1 A_Lower();
		---- A 1 A_Lower(1);
		---- AA 1 A_Lower(1);
		---- AA 1{
			A_MuzzleClimb(0.3,0.8);
			A_Lower(0);
		}
		---- AA 1{
			A_MuzzleClimb(-0.1,-0.4);
			A_Lower(2);
		}
		---- AAAA 1 A_Lower();
		---- A 1 A_Lower(12);
		---- A 1 A_Lower(18);
		---- A 1 A_Lower(18);
		---- A 1 A_Lower(24);
		wait;
	deselect1bfg:
		---- AA 1 A_Lower(-2);
		---- A 1 A_Lower(0);
		---- AAA 1 A_Lower();
		---- A 1 A_Lower(18);
		---- A 1 A_Lower(18);
		---- A 1 A_Lower(24);
		wait;
	select1bfg:
		---- A 0 A_TakeInventory("NulledWeapon");
		---- A 1 A_Raise(36);
		---- A 1 A_Raise(30);
		---- A 1 A_Raise(16);
		---- A 1 A_Raise(12);
		---- A 1{
			A_WeaponOffset(0,-6,WOF_ADD);
			A_MuzzleClimb(-0.1,-1.);
		}
		---- AA 1 A_WeaponOffset(0,2,WOF_ADD);
		---- A 1 A_Raise(1);
		wait;

	ready:
		TNT1 A 1 A_WeaponReady(WRF_ALL);
	readyend:
		---- A 0 A_ReadyEnd();
		---- A 0 A_Jump(256,"ready");
	user1:
		---- A 0 A_Jump(256,"altreload");
	user2:
		---- A 0 A_Jump(256,"firemode");
	user3:
		---- A 0 A_MagManager("HDBattery");
		goto readyend;
	user4:
		---- A 0 A_Jump(256,"unload");
	fire:
	altfire:
	hold:
	althold:
	reload:
	altreload:
	firemode:
	unload:
	nope:
		---- A 1{
			A_ClearRefire();
			A_WeaponReady(WRF_NOFIRE);
			if(invoker.bweaponbusy){
				let ppp=hdplayerpawn(self);
				if(!ppp)return;
				double hdbbx=(ppp.hudbobrecoil1.x+ppp.hudbob.x)*0.5;
				double hdbby=max(0,(ppp.hudbobrecoil1.y+ppp.hudbob.y)*0.5+invoker.bobrangey*2);
				A_WeaponOffset(hdbbx,hdbby+WEAPONTOP,WOF_INTERPOLATE);
			}
		}
		---- A 0{
			int inp=getplayerinput(MODINPUT_BUTTONS);
			if(
				inp&BT_ATTACK||
				inp&BT_ALTATTACK||
				inp&BT_RELOAD||
//				inp&BT_ZOOM||
				inp&BT_USER1||
				inp&BT_USER2||
				inp&BT_USER3||
				inp&BT_USER4
			)setweaponstate("nope");
		}
		---- A 0 A_Jump(256,"ready");

	botreload:
		TNT1 A 10;
		TNT1 A 40{
			invoker.initializewepstats(true);
		}goto readyend;
	}
}



// Null weapon for lowering weapon
class NulledWeapon:InventoryFlag{}
class NullWeapon:HDWeapon{
	default{
		+weapon.wimpy_weapon
		+weapon.cheatnotweapon
		+nointeraction
		+weapon.noalert
		+inventory.untossable

		//this needs to be longer than any "real" weapon to ensure there is enough space to raise
		hdweapon.barrelsize 40,1,1;
	}
	override inventory CreateTossable(int amount){
		let onr=hdplayerpawn(owner);
		if(onr){
			if(onr.lastweapon)onr.DropInventory(onr.lastweapon);
		}
		return null;
	}
	override double gunmass(){
		return 12;
	}
	override string gethelptext(){
		return "\cuSprinting\n"
		..WEPHELP_ZOOM.."+"..WEPHELP_USE.."  Try to kick down a door\n"
		;
	}
	states{
	spawn:
		TNT1 A 0;
		stop;
	select0:
		TNT1 A 0{
			A_TakeInventory("PowerFrightener");
			A_SetInventory("NulledWeapon",1);
			A_SetCrosshair(21);
		}
		TNT1 A 0 A_Raise();
		wait;
	deselect0:
		TNT1 A 0 A_SetCrosshair(21);
		TNT1 A 0 A_Lower();
		wait;
	ready:
		TNT1 A 1 A_WeaponReady(WRF_NOFIRE);
		TNT1 A 0 A_WeaponBusy(false);
		loop;
	fire:
		TNT1 A 1;
		goto ready;
	}
}


// ------------------------------------------------------------
// Database for spare weapons
// ------------------------------------------------------------
class SpareWeapons:HDPickup{
	array<double> weaponbulk;
	array<string> weapontype;
	array<int> weaponstatus0;
	array<int> weaponstatus1;
	array<int> weaponstatus2;
	array<int> weaponstatus3;
	array<int> weaponstatus4;
	array<int> weaponstatus5;
	array<int> weaponstatus6;
	array<int> weaponstatus7;
	array<string> weaponmisc;
	default{
		+nointeraction
		-inventory.invbar
		hdpickup.bulk 0;
	}
	override bool isused(){return owner&&owner.player&&!(owner.player.cmd.buttons&BT_ZOOM);}
	double,int getwepbulk(){
		//in encumbrance, have a special check for this actor - add to weapon count
		int i;
		double bulksum;
		for(i=0;i<weaponbulk.size();i++){
			bulksum+=weaponbulk[i];
		}
		return bulksum,i;
	}
	override inventory createtossable(int amount){
		while(weapontype.size()){
			let newwep=hdweapon(spawn(weapontype[0],(owner.pos.xy,owner.pos.z+owner.height*0.6)));
			weapontype.delete(0);
			newwep.weaponstatus[0]=weaponstatus0[0];
			weaponstatus0.delete(0);
			newwep.weaponstatus[1]=weaponstatus1[0];
			weaponstatus1.delete(0);
			newwep.weaponstatus[2]=weaponstatus2[0];
			weaponstatus2.delete(0);
			newwep.weaponstatus[3]=weaponstatus3[0];
			weaponstatus3.delete(0);
			newwep.weaponstatus[4]=weaponstatus4[0];
			weaponstatus4.delete(0);
			newwep.weaponstatus[5]=weaponstatus5[0];
			weaponstatus5.delete(0);
			newwep.weaponstatus[6]=weaponstatus6[0];
			weaponstatus6.delete(0);
			newwep.weaponstatus[7]=weaponstatus7[0];
			weaponstatus7.delete(0);
			newwep.ApplySpareWeaponMisc(weaponmisc[0]);
			weaponmisc.delete(0);
			weaponbulk.delete(0);
			newwep.vel+=owner.vel+(frandom(-1,1),frandom(-1,1),frandom(0,2));
			newwep.angle=owner.angle;
			newwep.A_ChangeVelocity(2,0,0,CVF_RELATIVE);
		}
		return null;
	}
	states{
	spawn:
		TNT1 A 1;
		stop;
	use:
		TNT1 A 0{
			if(!player)return;
			let thwep=hdweapon(player.readyweapon);
			if(
				thwep is "NullWeapon"
				||thwep is "HDFist"
			)return;
			A_GiveInventory("WeaponStashSwitcher");
			let wss=WeaponStashSwitcher(findinventory("WeaponStashSwitcher"));
			wss.thisweapon=thwep;
			A_SelectWeapon("WeaponStashSwitcher");
		}fail;
	}
}
class WeaponStashSwitcher:HDWeapon{
	default{
		+weapon.wimpy_weapon
		+weapon.cheatnotweapon
	}
	hdweapon thisweapon;
	states{
	spawn:TNT1 A 0;stop;
	ready:
		TNT1 A 1{
			A_WeaponReady(WRF_NOFIRE);
			let sww=SpareWeapons(GiveInventoryType("SpareWeapons"));
			let hdw=invoker.thisweapon;
			if(
				sww
				&&hdw
				&&hdw.addspareweapon(self)
			){
				hdw.getspareweapon(self,reverse:true);
			}
			invoker.thisweapon=null;
		}
		TNT1 A 1 A_SelectWeapon("HDFist");
		goto readyend;
	}
}
extend class HDWeapon{
	//override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	//override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	virtual string AddSpareWeaponMisc(actor newowner){return "";}
	virtual void ApplySpareWeaponMisc(string input){}
	virtual bool AddSpareWeapon(actor newowner){return false;}
	bool AddSpareWeaponRegular(actor newowner){
		double wbulk=weaponbulk();
		let hdp=hdplayerpawn(newowner);
		if(hdp){
			hdp.overloaded=hdp.CheckEncumbrance();
			if(
				(wbulk+hdp.enc)*hdmath.getencumbrancemult()
				>((hdp.zerk>0)?4000:2000)
			){
				if(hdp.getage()>10)hdp.A_Log("You can't even move to put away your weapon. Throw something out!",true);
				return false;
			}
		}
		let mwt=SpareWeapons(newowner.findinventory("SpareWeapons"));
		if(!mwt){
			mwt=SpareWeapons(newowner.giveinventorytype("SpareWeapons"));
			mwt.amount=1;
			mwt.weaponbulk.clear();
			mwt.weapontype.clear();
			mwt.weaponmisc.clear();
			mwt.weaponstatus0.clear();
			mwt.weaponstatus1.clear();
			mwt.weaponstatus2.clear();
			mwt.weaponstatus3.clear();
			mwt.weaponstatus4.clear();
			mwt.weaponstatus5.clear();
			mwt.weaponstatus6.clear();
			mwt.weaponstatus7.clear();
		}
		mwt.weaponbulk.insert(0,wbulk);
		mwt.weapontype.insert(0,getclassname());
		mwt.weaponmisc.insert(0,addspareweaponmisc(newowner));
		mwt.weaponstatus0.insert(0,weaponstatus[0]);
		mwt.weaponstatus1.insert(0,weaponstatus[1]);
		mwt.weaponstatus2.insert(0,weaponstatus[2]);
		mwt.weaponstatus3.insert(0,weaponstatus[3]);
		mwt.weaponstatus4.insert(0,weaponstatus[4]);
		mwt.weaponstatus5.insert(0,weaponstatus[5]);
		mwt.weaponstatus6.insert(0,weaponstatus[6]);
		mwt.weaponstatus7.insert(0,weaponstatus[7]);
		destroy();
		return true;
	}
	virtual hdweapon GetSpareWeapon(actor newowner,bool reverse=false,bool doselect=true){return null;}
	hdweapon GetSpareWeaponRegular(actor newowner,bool reverse=false,bool doselect=true){
		if(!newowner)return null;
		let mwt=SpareWeapons(newowner.findinventory("SpareWeapons"));
		if(!mwt)return null;

		int getindex;
		if(reverse){
			getindex=mwt.weapontype.size();
			let checkclassname=getclassname();
			for(int i=getindex-1;i>=0;i--){
				if(mwt.weapontype[i]==checkclassname){
					getindex=i;
					break;
				}
				else if(!i)return null;
			}
		}else{
			getindex=mwt.weapontype.find(getclassname());
			if(getindex==mwt.weapontype.size())return null;
		}

		//apply each of the items at getindex and delete the entry from the spares
		let newwep=hdweapon(newowner.giveinventorytype(getclassname()));
		if(!newwep)return null;
		newwep.bdontdefaultconfigure=true;
		mwt.weapontype.delete(getindex);
		newwep.weaponstatus[0]=mwt.weaponstatus0[getindex];
		mwt.weaponstatus0.delete(getindex);
		newwep.weaponstatus[1]=mwt.weaponstatus1[getindex];
		mwt.weaponstatus1.delete(getindex);
		newwep.weaponstatus[2]=mwt.weaponstatus2[getindex];
		mwt.weaponstatus2.delete(getindex);
		newwep.weaponstatus[3]=mwt.weaponstatus3[getindex];
		mwt.weaponstatus3.delete(getindex);
		newwep.weaponstatus[4]=mwt.weaponstatus4[getindex];
		mwt.weaponstatus4.delete(getindex);
		newwep.weaponstatus[5]=mwt.weaponstatus5[getindex];
		mwt.weaponstatus5.delete(getindex);
		newwep.weaponstatus[6]=mwt.weaponstatus6[getindex];
		mwt.weaponstatus6.delete(getindex);
		newwep.weaponstatus[7]=mwt.weaponstatus7[getindex];
		mwt.weaponstatus7.delete(getindex);
		newwep.ApplySpareWeaponMisc(mwt.weaponmisc[getindex]);
		mwt.weaponmisc.delete(getindex);
		mwt.weaponbulk.delete(getindex);
		if(doselect)HDWeaponSelector.Select(newowner,newwep.getclassname(),max(4,newwep.gunmass()));
		return newwep;
	}
}



//defaults for weapon helptext
const WEPHELP_BTCOL="\cy";
const WEPHELP_RGCOL="\cj";
const WEPHELP_FIRE=WEPHELP_BTCOL.."Fire"..WEPHELP_RGCOL;
const WEPHELP_ALTFIRE=WEPHELP_BTCOL.."Altfire"..WEPHELP_RGCOL;
const WEPHELP_RELOAD=WEPHELP_BTCOL.."Reload"..WEPHELP_RGCOL;
const WEPHELP_ZOOM=WEPHELP_BTCOL.."Zoom"..WEPHELP_RGCOL;
const WEPHELP_ALTRELOAD=WEPHELP_BTCOL.."Alt.Reload"..WEPHELP_RGCOL;
const WEPHELP_FIREMODE=WEPHELP_BTCOL.."Firemode"..WEPHELP_RGCOL;
const WEPHELP_USER3=WEPHELP_BTCOL.."User3"..WEPHELP_RGCOL;
const WEPHELP_UNLOAD=WEPHELP_BTCOL.."Unload"..WEPHELP_RGCOL;

const WEPHELP_UPDOWN=WEPHELP_BTCOL.."Mouselook"..WEPHELP_RGCOL;
const WEPHELP_USE=WEPHELP_BTCOL.."Use"..WEPHELP_RGCOL;
const WEPHELP_DROP=WEPHELP_BTCOL.."Drop"..WEPHELP_RGCOL;
const WEPHELP_DROPONE=WEPHELP_BTCOL.."Drop One"..WEPHELP_RGCOL;

const WEPHELP_FIRESHOOT=WEPHELP_FIRE.."  Shoot\n";
const WEPHELP_RELOADRELOAD=WEPHELP_RELOAD.."  Reload\n";
const WEPHELP_UNLOADUNLOAD=WEPHELP_UNLOAD.."  Unload\n";
const WEPHELP_MAGMANAGER=WEPHELP_USER3.."  Magazine Manager\n";
const WEPHELP_INJECTOR=WEPHELP_FIRE.."  Use on yourself\n"..WEPHELP_ALTFIRE.."  Use on someone else";





