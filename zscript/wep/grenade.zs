// ------------------------------------------------------------
// GRENADE!
// ------------------------------------------------------------
class HDGrenadeThrower:HDWeapon{
	class<inventory> grenadeammotype;
	property ammotype:grenadeammotype;
	class<actor> throwtype;
	property throwtype:throwtype;
	class<actor> spoontype;
	property spoontype:spoontype;
	class<weapon> wiretype;
	property wiretype:wiretype;
	default{
		+weapon.no_auto_switch +weapon.noalert +weapon.wimpy_weapon
		+hdweapon.dontdisarm
		+hdweapon.dontnull
		+nointeraction
		weapon.bobstyle "Alpha";
		weapon.bobspeed 2.5;weapon.bobrangex 0.1;weapon.bobrangey 0.5;

		//adding the frag grenade defaults here to prevent needless crashes
		hdgrenadethrower.ammotype "HDFragGrenadeAmmo";
		hdgrenadethrower.throwtype "HDFragGrenade";
		hdgrenadethrower.spoontype "HDFragSpoon";
		hdgrenadethrower.wiretype "TripwireFrag";
	}
	override void DoEffect(){
		if(weaponstatus[0]&FRAGF_SPOONOFF){
			weaponstatus[FRAGS_TIMER]++;
			if(
				owner.health<1
				||weaponstatus[FRAGS_TIMER]>136
			)TossGrenade(true);
		}else if(
			weaponstatus[0]&FRAGF_INHAND
			&&weaponstatus[0]&FRAGF_PINOUT
			&&owner.player.cmd.buttons&BT_ATTACK
			&&owner.player.cmd.buttons&BT_ALTFIRE
			&&!(owner.player.oldbuttons&BT_ALTFIRE)
		){
			StartCooking();
		}
		super.doeffect();
	}
	override string,double getpickupsprite(){return "FRAGA0",0.6;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage(
				(weaponstatus[0]&FRAGF_PINOUT)?"FRAGF0":"FRAGA0",
				(-52,-4),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.6,0.6)
			);
			sb.drawnum(hpl.countinv("HDFragGrenadeAmmo"),-45,-8,sb.DI_SCREEN_CENTER_BOTTOM,font.CR_BLACK);
		}
		sb.drawwepnum(
			hpl.countinv("HDFragGrenadeAmmo"),
			(HDCONST_MAXPOCKETSPACE/ENC_FRAG)
		);
		sb.drawwepnum(hdw.weaponstatus[FRAGS_FORCE],50,posy:-10,alwaysprecise:true);
		if(!(hdw.weaponstatus[0]&FRAGF_SPOONOFF)){
			sb.drawwepdot(-16,-15,(5,4));
			if(!(hdw.weaponstatus[0]&FRAGF_PINOUT))sb.drawwepdot(-22,-16,(3,2));
		}else{
			int timer=hdw.weaponstatus[FRAGS_TIMER];
			if(timer%3)sb.drawwepnum(140-timer,140,posy:-15,alwaysprecise:true);
		}
	}
	override string gethelptext(){
		if(weaponstatus[0]&FRAGF_SPOONOFF)return
		WEPHELP_FIRE.."  Wind up, release to throw\n(\cxSTOP READING AND DO THIS"..WEPHELP_RGCOL..")";
		return
		WEPHELP_FIRE.."  Pull pin/wind up (release to throw)\n"
		..WEPHELP_ALTFIRE.."  Pull pin, again to drop spoon\n"
		..WEPHELP_RELOAD.."  Abort/Replace pin\n"
		..WEPHELP_ZOOM.."  Start planting tripwire traps"
		;
	}
	override inventory CreateTossable(int amount){
		ReturnHandToOwner();
		owner.A_DropInventory(grenadeammotype,owner.countinv(grenadeammotype));
		owner.A_GiveInventory("HDFist");
		owner.A_SelectWeapon("HDFist");
		return null;
	}
	override void InitializeWepStats(bool idfa){
		//if(idfa)owner.A_SetInventory(grenadeammotype,max(3,owner.countinv(grenadeammotype)));
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			owner.A_DropInventory(grenadeammotype,1);
		}
	}
	override void ForceBasicAmmo(){
		owner.A_SetInventory("HDFragGrenadeAmmo",1);
	}
	//for involuntary dropping
	override void OnPlayerDrop(){
		if(
			weaponstatus[0]&FRAGF_SPOONOFF
			||weaponstatus[0]&FRAGF_PINOUT
		)TossGrenade(true);
	}
	void DropGrenade(){
		if(
			weaponstatus[0]&FRAGF_SPOONOFF
			||weaponstatus[0]&FRAGF_PINOUT
		){
			TossGrenade(true);
		}else{
			bool inhand=weaponstatus[0]&FRAGF_INHAND;
			if(inhand||owner.countinv(grenadeammotype)){
				if(!inhand)A_TakeInventory(grenadeammotype,1);
				A_DropItem(grenadeammotype);
			}
			weaponstatus[0]&=~FRAGF_INHAND;
		}
	}
	//any reset should do this
	action void A_ReturnHandToOwner(){invoker.ReturnHandToOwner();}
	void ReturnHandToOwner(){
		if(!owner)return;
		int wepstat=weaponstatus[0];
		if(wepstat&FRAGF_INHAND){
			if(wepstat&FRAGF_SPOONOFF)TossGrenade(true);
			else{
				if(wepstat&FRAGF_PINOUT){
					owner.A_PlaySound("weapons/fragpinout",CHAN_WEAPON);
					weaponstatus[0]&=~FRAGF_PINOUT;
				}
				if(
					owner.A_JumpIfInventory(grenadeammotype,0,"null")
				)owner.A_DropItem(grenadeammotype);
				else HDF.Give(owner,grenadeammotype,1);
			}
		}
		weaponstatus[0]&=~FRAGF_INHAND;
		weaponstatus[FRAGS_FORCE]=0;
		weaponstatus[FRAGS_REALLYPULL]=0;
	}
	vector3 SwingThrow(){
		vector2 iyy=(owner.angle,owner.pitch);
		double cosp=cos(iyy.y);
		vector3 oldpos=(
			cosp*cos(iyy.x),
			cosp*sin(iyy.x),
			sin(iyy.y)
		);
		iyy+=(
				owner.getplayerinput(MODINPUT_YAW),
				owner.getplayerinput(MODINPUT_PITCH)
			)
			*(360./65536.);
		cosp=cos(iyy.y);
		vector3 newpos=(
			cosp*cos(iyy.x),
			cosp*sin(iyy.x),
			sin(iyy.y)
		);
		return newpos-oldpos;
	}
	//because it's tedious to type each time
	action bool NoFrags(){
		return !(invoker.weaponstatus[0]&FRAGF_INHAND)&&!countinv(invoker.grenadeammotype);
	}
	//pull the pin
	action void A_PullPin(){
		invoker.weaponstatus[FRAGS_REALLYPULL]=0;
		invoker.weaponstatus[0]|=(FRAGF_PINOUT|FRAGF_INHAND);
		A_TakeInventory(invoker.grenadeammotype,1,TIF_NOTAKEINFINITE);
		A_PlaySound("weapons/fragpinout",CHAN_WEAPON);
	}
	//drop the spoon
	action void A_StartCooking(){
		invoker.StartCooking();
		A_SetHelpText();
	}
	void StartCooking(){
		if(!owner)return;
		bool gbg;actor spn;
		double ptch=owner.pitch;
		double cpp=cos(ptch);double spp=sin(ptch);
		[gbg,spn]=owner.A_SpawnItemEx(spoontype,
			cpp*4,-1,height-6-spp*4,
				cpp*4+vel.x,
				0,
				-sin(pitch)*4+vel.z,
			0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
		spn.vel+=owner.vel;
		weaponstatus[0]|=FRAGF_SPOONOFF;
		if(cvar.getcvar("hd_helptext",owner.player).getbool()){
			wepmsg="\cgThe fuze is lit!\n\n\n\n\cgRemember to throw!";
			msgtimer=100;
		}
		owner.A_PlaySound("weapons/fragspoonoff",0,1,0,20);
	}
	//we need to start from the inventory itself so it can go into DoEffect
	action void A_TossGrenade(bool oshit=false){
		invoker.TossGrenade(oshit);
		A_SetHelpText();
	}
	void TossGrenade(bool oshit=false){
		if(!owner)return;
		int garbage;actor ggg;
		double cpp=cos(owner.pitch);
		double spp=sin(owner.pitch);

		//create the spoon
		if(!(weaponstatus[0]&FRAGF_SPOONOFF)){
			[garbage,ggg]=owner.A_SpawnItemEx(
				spoontype,cpp*-4,-3,owner.height-6-spp*-4,
				cpp*3,0,-sin(owner.pitch+random(10,20))*3,
				frandom(33,45),SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
			);
			ggg.vel+=owner.vel;
		}

		//create the grenade
		[garbage,ggg]=owner.A_SpawnItemEx(throwtype,
			0,0,owner.height-6,
			cpp*4,
			0,
			-spp*4,
			0,SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
		ggg.vel+=owner.vel;

		//force calculation
		double gforce=clamp(weaponstatus[FRAGS_FORCE],4,40+owner.health*0.1);
		if(oshit)gforce=min(gforce,frandom(10,20));
		if(owner.countinv("powerstrength"))gforce*=2;

		let grenade=HDFragGrenade(ggg);if(!grenade)return;
		grenade.fuze=weaponstatus[FRAGS_TIMER];

		if(owner.player){
			grenade.vel+=SwingThrow()*gforce;
		}
		grenade.a_changevelocity(
			cpp*gforce*0.6,
			0,
			-spp*gforce*0.6,
			CVF_RELATIVE
		);
		weaponstatus[FRAGS_TIMER]=0;
		weaponstatus[FRAGS_FORCE]=0;
		weaponstatus[0]&=~FRAGF_PINOUT;
		weaponstatus[0]&=~FRAGF_SPOONOFF;
		weaponstatus[FRAGS_REALLYPULL]=0;

		weaponstatus[0]&=~FRAGF_INHAND;
		weaponstatus[0]|=FRAGF_JUSTTHREW;
	}
	states{
	select0:
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		TNT1 A 8{
			if(!countinv("NulledWeapon"))A_SetTics(tics+4);
			A_TakeInventory("NulledWeapon");
			invoker.weaponstatus[FRAGS_REALLYPULL]=0;
			invoker.weaponstatus[FRAGS_FORCE]=0;
		}
		FRGG B 1 A_Raise(32);
		wait;
	selectinstant:
		TNT1 A 0 A_SelectWeapon("HDFist");
		TNT1 A 1 A_WeaponReady(WRF_NOFIRE);
		wait;
	deselect0:
		---- A 1{
			if(invoker.weaponstatus[0]&FRAGF_PINOUT)A_SetTics(8);
			else if(NoFrags())setweaponstate("deselectinstant");
			invoker.ReturnHandToOwner();
		}
		---- A 1 A_Lower(72);
		wait;
	deselectinstant:
		TNT1 A 0 A_SelectWeapon("HDFist");
		TNT1 A 0 A_Lower(999);
		wait;
	ready:
		FRGG B 0{
			invoker.weaponstatus[FRAGS_FORCE]=0;
			invoker.weaponstatus[FRAGS_REALLYPULL]=0;
		}
		FRGG B 1 A_WeaponReady(WRF_ALL);
		goto ready3;
	ready3:
		---- A 0{
			invoker.weaponstatus[0]&=~FRAGF_JUSTTHREW;
			A_WeaponBusy(false);
		}goto readyend;

	zoom:
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		TNT1 A 0{
			let wiretype=invoker.wiretype;
			A_GiveInventory(wiretype);
			A_SelectWeapon(wiretype);
			A_WeaponReady(WRF_NOFIRE);
		}goto nope;

	pinout:
		FRGG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		loop;

	altfire:
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_SPOONOFF,"nope");
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_PINOUT,"startcooking");
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		TNT1 A 0 A_Refire();
		goto ready;
	althold:
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_SPOONOFF,"nope");
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_PINOUT,"nope");
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		goto startpull;
	startpull:
		FRGG B 1{
			if(invoker.weaponstatus[FRAGS_REALLYPULL]>=26)setweaponstate("endpull");
			else invoker.weaponstatus[FRAGS_REALLYPULL]++;
		}
		FRGG B 0 A_Refire();
		goto ready;
	endpull:
		FRGG B 1 offset(0,34);
		FRGG B 1 offset(0,36);
		FRGG B 1 offset(0,38);
		TNT1 A 6;
		TNT1 A 3 A_PullPin();
		TNT1 A 0 A_Refire();
		goto ready;
	startcooking:
		TNT1 A 6 A_StartCooking();
		TNT1 A 0 A_Refire();
		goto ready;
	fire:
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_JUSTTHREW,"nope");
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		TNT1 A 0 A_JumpIfInventory("PowerStrength",1,3);
		FRGG B 1 offset(0,34);
		FRGG B 1 offset(0,36);
		FRGG B 1 offset(0,38);
		TNT1 A 0 A_Refire();
		goto ready;
	hold:
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_JUSTTHREW,"nope");
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_PINOUT,"hold2");
		TNT1 A 6 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE]>=1,"hold2");
		TNT1 A 6 A_JumpIfInventory("PowerStrength",1,1);
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		TNT1 A 3 A_PullPin();
	hold2:
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		FRGG E 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE]>=40,"hold3a");
		FRGG D 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE]>=30,"hold3a");
		FRGG C 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE]>=20,"hold3");
		FRGG B 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE]>=10,"hold3");
		goto hold3;
	hold3a:
		FRGG # 0{
			if(invoker.weaponstatus[FRAGS_FORCE]<50)invoker.weaponstatus[FRAGS_FORCE]++;
		}
	hold3:
		FRGG # 1{
			A_WeaponReady(
				invoker.weaponstatus[0]&FRAGF_SPOONOFF?WRF_NOFIRE:WRF_NOFIRE|WRF_ALLOWRELOAD
			);
			if(invoker.weaponstatus[FRAGS_FORCE]<50)invoker.weaponstatus[FRAGS_FORCE]++;
		}
		TNT1 A 0 A_Refire();
		goto throw;
	throw:
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		FRGG A 1 offset(0,34) A_TossGrenade();
		FRGG A 1 offset(0,38);
		FRGG A 1 offset(0,48);
		FRGG A 1 offset(0,52);
		FRGG A 0 A_Refire();
		goto ready;
	reload:
		TNT1 A 0 A_JumpIf(NoFrags(),"selectinstant");
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[FRAGS_FORCE]>=1,"pinbackin");
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[0]&FRAGF_PINOUT,"altpinbackin");
		goto ready;
	pinbackin:
		FRGG B 1 offset(0,34) A_ReturnHandToOwner();
		FRGG B 1 offset(0,36);
		FRGG B 1 offset(0,38);
	altpinbackin:
		FRGG A 0 A_JumpIf(invoker.weaponstatus[FRAGS_TIMER]>0,"juststopthrowing");
		TNT1 A 8 A_ReturnHandToOwner();
		TNT1 A 0 A_Refire("nope");
		FRGG B 1 offset(0,38);
		FRGG B 1 offset(0,36);
		FRGG B 1 offset(0,34);
		goto ready;
	juststopthrowing:
		TNT1 A 10;
		FRGG A 0{invoker.weaponstatus[FRAGS_FORCE]=0;}
		TNT1 A 0 A_Refire();
		FRGG B 1 offset(0,38);
		FRGG B 1 offset(0,36);
		FRGG B 1 offset(0,34);
		goto ready;
	spawn:
		TNT1 A 1;
		TNT1 A 0 A_SpawnItemEx(invoker.grenadeammotype,SXF_NOCHECKPOSITION);
		stop;
	}
}
enum GrenadeWepNums{
	FRAGF_INHAND=1,
	FRAGF_PINOUT=2,
	FRAGF_SPOONOFF=4,
	FRAGF_JUSTTHREW=8,

	FRAGS_REALLYPULL=1,
	FRAGS_TIMER=2,
	FRAGS_FORCE=3,
}




// ------------------------------------------------------------
// The only grenades in base HD.
// ------------------------------------------------------------
class HDFragGrenades:HDGrenadethrower{
	default{
		weapon.selectionorder 1020;
		weapon.slotnumber 0;
		tag "fragmentation grenades";
		hdgrenadethrower.ammotype "HDFragGrenadeAmmo";
		hdgrenadethrower.throwtype "HDFragGrenade";
		hdgrenadethrower.spoontype "HDFragSpoon";
		hdgrenadethrower.wiretype "Tripwire";
	}
}
class HDFragGrenadeRoller:HDActor{
	int fuze;
	vector3 keeprolling;
	default{
		-noextremedeath -floorclip +shootable +noblood +forcexybillboard
		+activatemcross -noteleport +noblockmonst
		+missile +bounceonactors +usebouncestate 
			bouncetype "doom";bouncesound "misc/fragknock";
		radius 2;height 2;damagetype "none";
		scale 0.3;
		obituary "%o was fragged by %k.";
		radiusdamagefactor 0.04;pushfactor 1.4;maxstepheight 2;mass 30;
	}
	override bool used(actor user){
		angle=user.angle;
		A_PlaySound(bouncesound);
		if(hdplayerpawn(user)&&hdplayerpawn(user).incapacitated)A_ChangeVelocity(4,0,1,CVF_RELATIVE);
		else A_ChangeVelocity(12,0,4,CVF_RELATIVE);
		return true;
	}
	states{
	spawn:
		FRAG A 0 nodelay{
			HDMobAI.Frighten(self,512);
		}
	spawn2:
		#### BCD 2{
			if(abs(vel.z-keeprolling.z)>10)A_PlaySound("misc/fragknock",CHAN_BODY);
			else if(floorz>=pos.z)A_PlaySound("misc/fragroll");
			keeprolling=vel;
			if(abs(vel.x)<0.4 && abs(vel.y)<0.4) setstatelabel("death");
		}loop;
	bounce:
		---- A 0{
			bmissile=false;
			vel*=0.3;
		}goto spawn2;
	death:
		---- A 2{
			if(abs(vel.z-keeprolling.z)>3){
				A_PlaySound("misc/fragknock",CHAN_BODY);
				keeprolling=vel;
			}
			if(abs(vel.x)>0.4 || abs(vel.y)>0.4) setstatelabel("spawn");
		}wait;
	destroy:
		TNT1 A 1{
			bsolid=false;bpushable=false;bmissile=false;bnointeraction=true;bshootable=false;
			A_HDBlast(
				pushradius:256,pushamount:128,fullpushradius:96,
				fragradius:1024
			);
			DistantQuaker.Quake(self,4,35,512,10);
			A_PlaySound("world/explode",1,7);
			A_AlertMonsters();
			actor xpl=spawn("WallChunker",self.pos-(0,0,1),ALLOW_REPLACE);
				xpl.target=target;xpl.master=master;xpl.stamina=stamina;
			xpl=spawn("HDExplosion",self.pos-(0,0,1),ALLOW_REPLACE);
				xpl.target=target;xpl.master=master;xpl.stamina=stamina;
			A_SpawnChunks("BigWallChunk",14,4,12);
			A_SpawnChunks("HDB_frag",360,300,900);
			spawn("DistantRocket",pos,ALLOW_REPLACE);
		}
		stop;
	}
	override void tick(){
		if(isfrozen())return;
		else if(bnointeraction){
			//nexttic
			if(CheckNoDelay()){
				if(tics>0)tics--;  
				while(!tics){
					if(!SetState(CurState.NextState)){
						return;
					}
				}
			}
			return;
		}else{
			fuze++;
			if(fuze>=140 && !bnointeraction){
				setstatelabel("destroy");
				//nexttic
				if(CheckNoDelay()){
					if(tics>0)tics--;  
					while(!tics){
						if(!SetState(CurState.NextState)){
							return;
						}
					}
				}
				return;
			}else super.tick();
		}
	}
}
class HDFragGrenade:SlowProjectile{
	int fuze;
	vector3 keeprolling;
	class<actor> rollertype;
	property rollertype:rollertype;
	default{
		-noextremedeath -floorclip +bloodlessimpact
		+shootable -noblockmap +noblood
		+activatemcross -noteleport
		radius 5;height 5;damagetype "none";
		scale 0.3;
		obituary "%o was fragged by %k.";
		mass 500;
		hdfraggrenade.rollertype "HDFragGrenadeRoller";
	}
	override void tick(){
		ClearInterpolation();
		if(isfrozen())return;
		if(!bmissile){
			hdactor.tick();return;
		}else if(fuze<140){
			fuze++;
			keeprolling=vel;
			super.tick();
		}else{
			if(inthesky){
				spawn("DistantRocket",pos,ALLOW_REPLACE);
				A_SpawnChunks("HDB_frag",360,300,900);
				destroy();return;
			}
			let gr=HDFragGrenadeRoller(spawn(rollertype,pos,ALLOW_REPLACE));
			gr.target=self.target;gr.master=self.master;gr.vel=self.vel;
			gr.fuze=fuze;
			destroy();return;
		}
	}
	override void postbeginplay(){
		actor.postbeginplay();
		divrad=1./(radius*1.9);
		grav=getgravity();
	}
	states{
	spawn:
		FRAG BCD 2;
		loop;
	death:
		TNT1 A 10{
			bmissile=false;
			let gr=HDFragGrenadeRoller(spawn(rollertype,self.pos,ALLOW_REPLACE));
			if(!gr)return;
			gr.target=self.target;gr.master=self.master;
			gr.fuze=self.fuze;
			gr.vel=self.keeprolling;
			gr.keeprolling=self.keeprolling;
			gr.A_PlaySound("misc/fragknock",CHAN_BODY);
			HDMobAI.Frighten(gr,512);
		}stop;
	}
}
class HDFragSpoon:HDDebris{
	default{
		scale 0.3;bouncefactor 0.8;
		bouncesound "misc/casing4";
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_PlaySound("weapons/grenopen",0,2);
	}
	states{
	spawn:
		FRGP A 2{roll+=40;}wait;
	death:
		FRGP A -1;
	}
}

class HDFragGrenadeAmmo:HDAmmo{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Frag Grenade"
		//$Sprite "FRAGA0"

		+forcexybillboard
		inventory.icon "FRAGA0";
		inventory.amount 1;
		scale 0.3;
		inventory.maxamount 50;
		inventory.pickupmessage "Picked up a fragmentation hand grenade.";
		inventory.pickupsound "weapons/pocket";
		tag "fragmentation grenades";
		hdpickup.refid HDLD_GREFRAG;
		hdpickup.bulk ENC_FRAG;
	}
	override bool IsUsed(){return true;}
	states{
	spawn:
		FRAG A -1;stop;
	}
}
class FragP:HDUPK{
	default{
		+forcexybillboard
		scale 0.3;height 3;radius 3;
		hdupk.amount 1;
		hdupk.pickuptype "HDFragGrenadeAmmo";
		hdupk.pickupmessage "Picked up a fragmentation hand grenade.";
		hdupk.pickupsound "weapons/rifleclick2";
		stamina 1;
	}
	override void postbeginplay(){
		super.postbeginplay();
		pickupmessage=getdefaultbytype("HDFragGrenadeAmmo").pickupmessage();
	}
	states{
	spawn:
		FRAG A -1;
	}
}

