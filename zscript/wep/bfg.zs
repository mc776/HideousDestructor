// ------------------------------------------------------------
// BFG9k
// ------------------------------------------------------------
class BFG9K:HDCellWeapon replaces BFG9000{
	default{
		//$Category "Weapons/Hideous Destructor"
		//$Title "BFG 9k"
		//$Sprite "BFUGA0"

		weapon.selectionorder 91;
		weapon.slotnumber 7;
		weapon.slotpriority 1;
		weapon.kickback 200;
		weapon.bobrangex 0.4;
		weapon.bobrangey 1.1;
		weapon.bobspeed 1.8;
		weapon.bobstyle "normal";
		scale 0.7;
		hdweapon.barrelsize 32,3.5,7;
		hdweapon.refid HDLD_BFG;
		tag "$TAG_BFG9000";
	}
	override string pickupmessage(){
		return "You got the "..gettag().."! Oh yes.";
	}
	override string getobituary(actor victim,actor inflictor,name mod,bool playerattack){
		if(bplayingid)return "%o was smacked by %k's big green gob.";
		return "%o just got glassed and no one leaves here till we find out %k did it!";
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	//BFG9k.Spark(self,4);
	//BFG9k.Spark(self,4,height-10);
	static void Spark(actor caller,int sparks=1,double sparkheight=10){
		actor a;vector3 spot;
		vector3 origin=caller.pos+(0,0,sparkheight);
		double spp;double spa;
		for(int i=0;i<sparks;i++){
			spp=caller.pitch+frandom(-20,20);
			spa=caller.angle+frandom(-20,20);
			spot=random(32,57)*(cos(spp)*cos(spa),cos(spp)*sin(spa),-sin(spp));
			a=caller.spawn("BFGSpark",origin+spot,ALLOW_REPLACE);
			a.vel+=caller.vel*0.9-spot*0.03;
		}
	}
	override void OnPlayerDrop(){
		if(
			weaponstatus[BFGS_CRITTIMER]>0
		){
			buntossable=false;
			if(owner)owner.DropInventory(self);
		}
	}
	override void doeffect(){
		if(hdplayerpawn(owner)){
			if(weaponstatus[0]&BFGF_STRAPPED&&(owner&&owner.health>0))buntossable=true;    
			else buntossable=false;
			if(
				owner.player&&owner.player.readyweapon==self&&
				!(hdplayerpawn(owner).gunbraced)&&
				!(weaponstatus[0]&BFGF_STRAPPED)&&
				owner.pitch<10
			)hdplayerpawn(owner).A_MuzzleClimb((frandom(-0.05,0.05),0.1),(0,0),(0,0),(0,0));
		}
	}
	override double gunmass(){
		return 15+(weaponstatus[BFGS_BATTERY]>=0?1:0)+(weaponstatus[0]&BFGF_STRAPPED?0:4);
	}
	override double weaponbulk(){
		double blx=(weaponstatus[0]&BFGF_STRAPPED)?400:240;
		return blx+(weaponstatus[BFGS_BATTERY]>=0?ENC_BATTERY_LOADED:0);
	}
	override string,double getpickupsprite(){return "BFUGA0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawbattery(-54,-4,sb.DI_SCREEN_CENTER_BOTTOM,reloadorder:true);
			sb.drawnum(hpl.countinv("HDBattery"),-46,-8,sb.DI_SCREEN_CENTER_BOTTOM,font.CR_BLACK);
		}
		int bffb=hdw.weaponstatus[BFGS_BATTERY];
		if(bffb>0)sb.drawwepnum(bffb,20,posy:-10);
		else if(!bffb)sb.drawstring(
			sb.mamountfont,"00000",
			(-16,-14),sb.DI_TEXT_ALIGN_RIGHT|sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
			Font.CR_DARKGRAY
		);
		if(hdw.weaponstatus[0]&BFGF_STRAPPED){
			sb.drawwepdot(-16,-16,(10,1));
			sb.drawwepdot(-16,-19,(8,1));
			sb.drawwepdot(-16,-22,(5,1));
		}
		sb.drawwepnum(hdw.weaponstatus[BFGS_CHARGE],20);
	}
	override string gethelptext(){
		return
		WEPHELP_FIRE.."  Shoot/Charge\n"
		..WEPHELP_ALTFIRE.."  Toggle harness\n"
		..WEPHELP_RELOAD.."  Abort charge/Reload battery\n"
		..WEPHELP_ALTRELOAD.."  Reload depleted battery\n"
		..WEPHELP_UNLOADUNLOAD
		;
	}
	override void failedpickupunload(){
		failedpickupunloadmag(BFGS_BATTERY,"HDBattery");
	}
	override void consolidate(){
		CheckBFGCharge(BFGS_BATTERY);
		CheckBFGCharge(BFGS_CHARGE);
	}
	states{
	altfire:
	togglestrap:
		#### A 3{
			A_WeaponBusy();
			if(invoker.weaponstatus[0]&BFGF_STRAPPED){
				A_SetTics(6);
				A_StartSound("weapons/bfgclick",8);
			}
		}
		#### AA 1 A_Lower(3);
		#### AAA 1 A_Lower(5);
		#### AA 2 A_Lower(3);
		#### A 4{
			A_StartSound("weapons/bfglock",8);
			if(!(invoker.weaponstatus[0]&BFGF_STRAPPED)){
				A_SetTics(6);
				A_StartSound("weapons/bfgclick",8,CHANF_OVERLAP);
			}
			A_SetBlend("00 00 00",1,6,"00 00 00");
			invoker.weaponstatus[0]^=BFGF_STRAPPED;
			if(invoker.buntossable)invoker.buntossable=false;
				else invoker.buntossable=true;
		}
		#### AA 2 A_Raise(3);
		#### AAA 1 A_Raise(5);
		#### AA 1 A_Raise(3);
		goto nope;
	ready:
		BFGG A 1{
			A_CheckIdSprite("B9KGA0","BFGGA0");
			if(invoker.weaponstatus[0]&BFGF_STRAPPED){
				invoker.bobstyle=Bob_Alpha;
				invoker.bobrangex=1.4;
				invoker.bobrangey=3.5;
			}else{
				invoker.bobstyle=Bob_Normal;
				invoker.bobrangex=5.6;
				invoker.bobrangey=4.2;
			}
			if(invoker.weaponstatus[0]&BFGF_CRITICAL)setweaponstate("shoot");
			A_WeaponReady(WRF_ALL);
		}goto readyend;
	select0:
		B9KG A 0;
		BFGG C 0 A_CheckIdSprite("B9KGA0","BFGGA0");
		goto select0bfg;
	deselect0:
		BFGG C 0 A_CheckIdSprite("B9KGA0","BFGGA0");
		---- A 0 A_JumpIf(
			invoker.weaponstatus[0]&BFGF_STRAPPED
			&&!countinv("NulledWeapon")
			,"togglestrap"
		);
		goto deselect0bfg;
	althold:
		stop;
	flash:
		B9KF B 3 bright{
			A_CheckIdSprite("B9KFA0","BFGFA0",PSP_FLASH);
			A_Light1();
			HDFlashAlpha(0,true);
		}
		#### A 2 bright{
			A_Light2();
			HDFlashAlpha(200);
		}
		#### A 2 bright HDFlashAlpha(128);
		goto lightdone;

	fire:
		#### C 0 {invoker.weaponstatus[BFGS_TIMER]=0;}
	hold:
		#### C 0{
			if(
				invoker.weaponstatus[BFGS_CHARGE]>=20    
				&& invoker.weaponstatus[BFGS_BATTERY]>=20
			)return resolvestate("chargeend");
			else if(
				invoker.weaponstatus[BFGS_CHARGE]>BFGC_MINCHARGE
				||invoker.weaponstatus[BFGS_BATTERY]>BFGC_MINCHARGE    
			)return resolvestate("charge");
			return resolvestate("nope");
		}
	charge:
		#### B 0{
			if(
				PressingReload()
				||invoker.weaponstatus[BFGS_BATTERY]<0
				||(
					invoker.weaponstatus[BFGS_CHARGE]>=20
					&&invoker.weaponstatus[BFGS_BATTERY]>=20    
				)
			)setweaponstate("nope");
		}
		#### B 6{
			invoker.weaponstatus[BFGS_TIMER]++;
			if (invoker.weaponstatus[BFGS_TIMER]>3){
				invoker.weaponstatus[BFGS_TIMER]=0;
				if(invoker.weaponstatus[BFGS_BATTERY]<20){
					invoker.weaponstatus[BFGS_BATTERY]++;
					if(invoker.weaponstatus[BFGS_BATTERY]==20)
						invoker.weaponstatus[0]|=BFGF_DEMON;
				}
				else invoker.weaponstatus[BFGS_CHARGE]++;
			}
			if(invoker.weaponstatus[BFGS_BATTERY]==20)A_SetTics(5);
			if(health<40){
				A_SetTics(4);
				if(health>16)damagemobj(invoker,self,1,"internal");    
			}
			A_WeaponBusy(false);
			A_StartSound("weapons/bfgcharge",CHAN_WEAPON);
			BFG9k.Spark(self,1,height-10);
			A_WeaponReady(WRF_NOFIRE);
		}
		#### B 0{
			if(invoker.weaponstatus[BFGS_CHARGE]==20 && invoker.weaponstatus[BFGS_BATTERY]==20)
			A_Refire("shoot");
			else A_Refire();
		}
		loop;
	chargeend:
		#### B 2{
			BFG9k.Spark(self,1,height-10);
			A_StartSound("weapons/bfgcharge",(invoker.weaponstatus[BFGS_TIMER]>6)?CHAN_AUTO:CHAN_WEAPON);
			A_WeaponReady(WRF_ALLOWRELOAD|WRF_NOFIRE|WRF_DISABLESWITCH);
			A_SetTics(max(1,6-int(invoker.weaponstatus[BFGS_TIMER]*0.3)));
			invoker.weaponstatus[BFGS_TIMER]++;
		}
		#### B 0{
			if(invoker.weaponstatus[BFGS_TIMER]>21)A_Refire("shoot");    
			else A_Refire("chargeend");
		}goto ready;
	shoot:
		#### B 0{
			invoker.weaponstatus[BFGS_TIMER]=0;
			invoker.weaponstatus[0]|=BFGF_CRITICAL;
			invoker.weaponstatus[BFGS_CRITTIMER]=15;
			A_StartSound("weapons/bfgf",CHAN_WEAPON);
			A_GiveInventory("PowerFrightener");
		}
		#### B 3{
			invoker.weaponstatus[BFGS_CRITTIMER]--;
			A_StartSound("weapons/bfgcharge",random(9005,9007));
			BFG9k.Spark(self,1,height-10);
			if(invoker.weaponstatus[BFGS_CRITTIMER]<1){
				invoker.weaponstatus[BFGS_CRITTIMER]=0;
				player.setpsprite(PSP_WEAPON,invoker.findstate("reallyshoot"));
			}else if(invoker.weaponstatus[BFGS_CRITTIMER]<10)A_SetTics(2);
			else if(invoker.weaponstatus[BFGS_CRITTIMER]<5)A_SetTics(1);
		}wait;
	reallyshoot:
		#### A 8{
			A_AlertMonsters();
			A_GiveInventory("PowerFrightener");
		}
		#### B 2{
			A_ZoomRecoil(0.2);
			A_StartSound("weapons/bfgfwoosh",CHAN_WEAPON,CHANF_OVERLAP);
			A_GiveInventory("PowerFrightener",1);

			invoker.weaponstatus[BFGS_CHARGE]=0;
			invoker.weaponstatus[BFGS_BATTERY]=0;
			invoker.weaponstatus[0]&=~BFGF_CRITICAL;
			A_GunFlash();
			if(random(0,7))invoker.weaponstatus[0]&=~BFGF_DEMON;
			A_SpawnItemEx("BFGBallTail",0,0,height-12,
				cos(pitch)*cos(angle)*4+vel.x,
				cos(pitch)*sin(angle)*4+vel.y,
				-sin(pitch)*4+vel.z,
				0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
			);
			A_SpawnItemEx("BFGBalle",0,0,height-12,
				cos(pitch)*cos(angle)*13+vel.x,
				cos(pitch)*sin(angle)*13+vel.y,
				-sin(pitch)*13+vel.z,
				0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|
				SXF_TRANSFERPITCH|SXF_SETMASTER
			);
			A_GiveInventory("PowerFrightener",1);
		}
		#### B 0 A_JumpIf(invoker.weaponstatus[0]&BFGF_STRAPPED,"recoilstrapped");
		#### B 6 A_ChangeVelocity(-2,0,3,CVF_RELATIVE);
		#### C 6{
			A_MuzzleClimb(
				1,3,
				-frandom(0.8,1.2),-frandom(2.4,4.6),
				-frandom(1.8,2.8),-frandom(6.4,9.6),
				1,2
			);
			if(!random(0,5))DropInventory(invoker);
		}goto nope;
	recoilstrapped:
		#### BBBB 1{
			A_ChangeVelocity(-0.3,0,0.06,CVF_RELATIVE);
			A_WeaponOffset(0,2,WOF_KEEPX|WOF_ADD|WOF_INTERPOLATE);
		}
		#### CCCC 1{
			A_WeaponOffset(0,-2,WOF_KEEPX|WOF_ADD|WOF_INTERPOLATE);
			A_MuzzleClimb(
				0.1,0.2,
				-frandom(0.08,0.1),-frandom(0.2,0.3),
				-frandom(0.18,0.24),-frandom(0.6,0.8),
				0.1,0.15
			);
		}goto nope;

	reload:
		#### A 0{
			if(
				invoker.weaponstatus[BFGS_BATTERY]>=20
				||!countinv("HDBattery")
				||(
					invoker.weaponstatus[BFGS_CHARGE]<BFGC_MINCHARGE
					&&HDMagAmmo.NothingLoaded(self,"HDBattery")
				)
			)setweaponstate("nope");
			else invoker.weaponstatus[BFGS_LOADTYPE]=1;
		}goto reload1;
	altreload:
	reloadempty:
		#### A 0{
			if(
				!invoker.weaponstatus[BFGS_BATTERY] //already have an empty loaded
				||!countinv("HDBattery")
			)setweaponstate("nope");
			else invoker.weaponstatus[BFGS_LOADTYPE]=0;
		}goto reload1;
	unload:
		#### A 0{
			if(invoker.weaponstatus[BFGS_BATTERY]<0)setweaponstate("nope");
			invoker.weaponstatus[BFGS_LOADTYPE]=-1;
		}goto reload1;
	reload1:
		#### A 4;
		#### C 2 offset(0,36) A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
		#### C 2 offset(0,38) A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
		#### C 4 offset(0,40){
			A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
			A_StartSound("weapons/bfgclick2",8);
		}
		#### C 2 offset(0,42){
			A_MuzzleClimb(-frandom(1.2,2.4),frandom(1.2,2.4));
			A_StartSound("weapons/bfgopen",8);
			if(invoker.weaponstatus[BFGS_BATTERY]>=0){    
				HDMagAmmo.SpawnMag(self,"HDBattery",invoker.weaponstatus[BFGS_BATTERY]);
				A_SetTics(4);
			}
			if(invoker.weaponstatus[0]&BFGF_DEMON){
				setweaponstate("unloaddemon");
				invoker.weaponstatus[0]&=~BFGF_DEMON;
			}
			invoker.weaponstatus[BFGS_BATTERY]=-1;
		}goto batteryout;
	unloaddemon:
		//effects for a possessed cell
		#### C 0{
			if(!random(0,2))setweaponstate("vile");
			else if(!random(0,15))A_FireProjectile("YokaiSpawner");
		}goto harmless;
	vile:
		---- AAAAA 0 A_FireProjectile("BFGNecroShard",random(170,190),spawnofs_xy:random(-20,20));
		goto batteryout;
	harmless:
		---- AAAAA 0 A_FireProjectile("BFGShard",random(170,190),spawnofs_xy:random(-20,20));
		goto batteryout;
	batteryout:
		#### C 4 offset(0,42){
			if(invoker.weaponstatus[BFGS_LOADTYPE]==-1)setweaponstate("reload3");
			else A_StartSound("weapons/pocket",9);
		}
		#### C 12;
		#### C 12 offset(0,42)A_StartSound("weapons/bfgbattout",8);
		#### C 10 offset(0,36)A_StartSound("weapons/bfgbattpop",8);
		#### C 0{
			let mmm=hdmagammo(findinventory("HDBattery"));
			if(!mmm||mmm.amount<1){setweaponstate("reload3");return;}
			if(!invoker.weaponstatus[BFGS_LOADTYPE]){
				mmm.LowestToLast();
				invoker.weaponstatus[BFGS_BATTERY]=mmm.TakeMag(false);
			}else{
				invoker.weaponstatus[BFGS_BATTERY]=mmm.TakeMag(true);
			}
		}
	reload3:
		#### C 12 offset(0,38) A_StartSound("weapons/bfgopen",8);
		#### C 16 offset(0,37) A_StartSound("weapons/bfgclick2",8);
		#### C 2 offset(0,38);
		#### C 2 offset(0,36);
		#### A 2 offset(0,34);
		#### A 12;
		goto ready;

	user3:
		#### A 0 A_MagManager("HDBattery");
		goto ready;

	spawn:
		BFUG A -1 nodelay{
			if(invoker.weaponstatus[0]&BFGF_CRITICAL)invoker.setstatelabel("bwahahahaha");
		}
	bwahahahaha:
		BFUG A 3{
			invoker.weaponstatus[BFGS_CRITTIMER]--;
			A_StartSound("weapons/bfgcharge",CHAN_AUTO);
			BFG9k.Spark(self,1,6);
			if(invoker.weaponstatus[BFGS_CRITTIMER]<1){
				invoker.weaponstatus[BFGS_CRITTIMER]=0;
				invoker.setstatelabel("heh");
			}else if(invoker.weaponstatus[BFGS_CRITTIMER]<10)A_SetTics(2);
			else if(invoker.weaponstatus[BFGS_CRITTIMER]<5)A_SetTics(1);
		}wait;
	heh:
		BFUG A 8;
		BFUG A 4{
			invoker.A_StartSound("weapons/bfgfwoosh",CHAN_AUTO);
			invoker.weaponstatus[0]&=~BFGF_CRITICAL; //DO NOT DELETE THIS
			invoker.weaponstatus[BFGS_CHARGE]=0;invoker.weaponstatus[BFGS_BATTERY]=0;

			if(random(0,7))invoker.weaponstatus[0]&=~BFGF_DEMON;
			A_SpawnItemEx("BFGBallTail",0,0,height-12,
				cos(pitch)*cos(angle)*4+vel.x,
				cos(pitch)*sin(angle)*4+vel.y,
				-sin(pitch)*4+vel.z,
				0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
			);
			A_SpawnItemEx("BFGBalle",0,0,height-12,
				cos(pitch)*cos(angle)*13+vel.x,
				cos(pitch)*sin(angle)*13+vel.y,
				-sin(pitch)*13+vel.z,
				0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|
				SXF_TRANSFERPITCH|SXF_TRANSFERPOINTERS
			);
		}
		BFUG A 0{
			invoker.A_ChangeVelocity(-cos(pitch)*4,0,sin(pitch)*4,CVF_RELATIVE);
		}goto spawn;
	}

	override void postbeginplay(){
		super.postbeginplay();
		if(owner&&owner.player&&owner.player.readyweapon==self)weaponstatus[0]|=BFGF_STRAPPED;
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[BFGS_CHARGE]=20;
		weaponstatus[BFGS_BATTERY]=20;
		weaponstatus[BFGS_TIMER]=0;
		weaponstatus[BFGS_CRITTIMER]=0;
		if(idfa){
			weaponstatus[0]&=~BFGF_DEMON;
		}else weaponstatus[0]=0;
	}
}
enum bfg9kstatus{
	BFGF_CRITICAL=1,
	BFGF_STRAPPED=2,
	BFGF_DEMON=4,

	BFGS_STATUS=0,
	BFGS_CHARGE=1,
	BFGS_BATTERY=2,
	BFGS_TIMER=3,
	BFGS_LOADTYPE=4,
	BFGS_CRITTIMER=5,

	BFGC_MINCHARGE=6,
};

class BFGSpark:HDActor{
	default{
		+nointeraction +forcexybillboard +bright
		radius 0;height 0;
		renderstyle "add";alpha 0.1; scale 0.16;
	}
	states{
	spawn:
		BFE2 DDDDDDDDDD 1 bright nodelay A_FadeIn(0.1);
		BFE2 D 1 A_FadeOut(0.3);
		wait;
	}
}
class BFGNecroShard:Actor{
	default{
		+ismonster +float +nogravity +noclip +lookallaround +nofear +forcexybillboard +bright
		radius 0;height 0;
		scale 0.16;renderstyle "add";
		speed 24;
	}
	states{
	spawn:
		BFE2 A 0 nodelay{
			A_GiveInventory("ImmunityToFire");
			A_SetGravity(0.1);
		}
	spawn2:
		BFE2 AB 1{
			A_Look();
			A_Wander();
		}loop;
	see:
		BFE2 D 1{
			A_Wander();
			A_SpawnProjectile("BFGSpark",0,random(-24,24),random(-24,24),2,random(-14,14));
			if(!random(0,3))vel.z+=random(-4,8);
			if(alpha<0.2)setstatelabel("see2");
		}
		BFE2 A 1 bright A_Wander();
		BFE2 B 1 bright{
			A_Wander();
			A_FadeOut(0.1);
		}
		loop;
	see2:
		TNT1 AAA 0 A_Wander();
		TNT1 A 5{
			A_VileChase();
			A_SpawnItemEx("BFGSpark",random(-4,4),random(-4,4),random(28,36),random(4,6),random(-1,1),random(-6,6),random(0,360),SXF_NOCHECKPOSITION,200);
		}
		loop;
	heal:
		TNT1 A 1{
			bshootable=true;
			A_Die();
		}wait;
	death:
		BFE2 AAAAAAA 0 A_SpawnItemEx("BFGSpark",random(-4,4),random(-4,4),random(28,36),random(4,6),random(-1,1),random(-6,6),random(0,360),SXF_NOCHECKPOSITION);
		BFE2 AAAA 1 A_SpawnItemEx("BFGSpark",random(-4,4),random(-4,4),random(28,36),random(4,6),random(-1,1),random(-6,6),random(0,360),SXF_NOCHECKPOSITION);
		stop;
	}
}
class BFGShard:BFGNecroShard{
	states{
	see2:
		TNT1 A 0;
		stop;
	}
}


class BFGBalle:HDFireball{
	int ballripdmg;
	bool freedoom;
	default{
		-notelestomp +telestomp
		+skyexplode +forceradiusdmg +ripper -noteleport +notarget
		+bright
		decal "HDBFGLightning";
		renderstyle "add";
		damagefunction(ballripdmg);
		seesound "weapons/plasmaf";
		deathsound "weapons/bfgx";
		obituary "$OB_MPBFG_BOOM";
		alpha 0.9;
		height 6;
		radius 6;
		speed 10;
		gravity 0;
	}
	void A_BFGBallZap(){
		if(pos.z-floorz<12)vel.z+=1;
		else if(ceilingz-pos.z<19)vel.z-=1;

		for(int i=0;i<10;i++){
			A_SpawnParticle(freedoom?"55 88 ff":"55 ff 88",
				SPF_RELATIVE|SPF_FULLBRIGHT,
				35,frandom(4,8),0,
				frandom(-8,8),frandom(-8,8),frandom(0,8),
				frandom(-1,1),frandom(-1,1),frandom(1,2),
				-0.1,frandom(-0.1,0.1),-0.05
			);
		}

		vector2 oldaim=(angle,pitch);
		blockthingsiterator it=blockthingsiterator.create(self,2048);
		while(it.Next()){
			actor itt=it.thing;
			if(
				(itt.bismonster||itt.player)
				&&itt!=target
				&&itt.health>0
				&&!target.isfriend(itt)
				&&!target.isteammate(itt)
				&&checksight(itt)
			){
				A_Face(itt,0,0);
				A_CustomRailgun((0),0,"",freedoom?"55 88 ff":"55 ff 88",
					RGF_CENTERZ|RGF_SILENT|RGF_NOPIERCING|RGF_FULLBRIGHT,
					0,50.0,"BFGPuff",0,0,2048,18,0.2,1.0
				);
				break;
			}
		}
		angle=oldaim.x;pitch=oldaim.y;
	}
	void A_BFGBallSplodeZap(){
		blockthingsiterator it=blockthingsiterator.create(self,2048);
		while(it.Next()){
			actor itt=it.thing;
			if(
				(itt.bismonster||itt.player)
				&&itt!=target
				&&itt.health>0    
				&&!target.isfriend(itt)
				&&!target.isteammate(itt)
				&&checksight(itt)
			){
				A_Face(itt,0,0);
				int hhh=min(itt.health,4096);
				for(int i=0;i<hhh;i+=1024){
					A_CustomRailgun((0),0,"","55 ff 88",
						RGF_CENTERZ|RGF_SILENT|RGF_NOPIERCING|RGF_FULLBRIGHT,
						0,50.0,"BFGPuff",3,3,2048,18,0.2,1.0
					);
				}
			}
		}
	}
	states{
	spawn:
		TNT1 A 0 nodelay{
			A_BFGSpray();
			ballripdmg=1;
			let hdp=hdplayerpawn(target);
			if(hdp&&hdp.scopecamera){
				pitch+=deltaangle(hdp.pitch,hdp.scopecamera.pitch);
				angle+=deltaangle(hdp.angle,hdp.scopecamera.angle);
			}else if(countinv("IsMoving",AAPTR_TARGET)>=6){    
				pitch+=frandom(-3,3);
				angle+=frandom(-1,1);
			}
			freedoom=(Wads.CheckNumForName("FREEDOOM",0)!=-1);
		}
		BFS1 AB 2 A_SpawnItemEx("BFGBallTail",0,0,0,vel.x*0.2,vel.y*0.2,vel.z*0.2,0,168,0);
		BFS1 A 0{
			ballripdmg=random(500,1000);
			bripper=false;
		}
		goto spawn2;
	spawn2:
		BFS1 AB 3 A_SpawnItemEx("BFGBallTail",0,0,0,vel.x*0.2,vel.y*0.2,vel.z*0.2,0,168,0);
		---- A 0 A_BFGBallZap();
		---- A 0 A_Corkscrew();
		loop;
	death:
		BFE1 A 2;
		BFE1 B 2 A_Explode(160,512,0);
		BFE1 B 4{
			DistantQuaker.Quake(self,
				6,100,16384,10,256,512,128
			);
			DistantNoise.Make(self,"world/bfgfar");
		}
		TNT1 AAAAA 0 A_SpawnItemEx("HDSmokeChunk",random(-2,0),random(-3,3),random(-2,2),random(-5,0),random(-5,5),random(0,5),random(100,260),SXF_TRANSFERPOINTERS|SXF_NOCHECKPOSITION,16);
		TNT1 AAAAA 0 A_SpawnItemEx("BFGBallRemains",-1,0,-12,0,0,0,SXF_TRANSFERPOINTERS|SXF_NOCHECKPOSITION,16);
		BFE1 CCCC 2 A_BFGBallSplodeZap();
		BFE1 CCC 0 A_SpawnItemEx("HDSmoke",random(-4,0),random(-3,3),random(0,4),random(-1,1),random(-1,1),random(1,3),0,SXF_TRANSFERPOINTERS|SXF_NOCHECKPOSITION,16);
		BFE1 DEF 6;
		BFE1 F 3 bright A_FadeOut(0.1);
		wait;
	}
}
class BFGBallRemains:IdleDummy{
	string pcol;
	states{
	spawn:
		TNT1 A 0 nodelay{
			pcol=(Wads.CheckNumForName("FREEDOOM",0)!=-1)?"55 88 ff":"55 ff 88";
			stamina=0;
		}
	spawn2:
		TNT1 AAAA 1 A_SpawnParticle(
			pcol,SPF_FULLBRIGHT,35,
			size:frandom(1,8),0,
			frandom(-16,16),frandom(-16,16),frandom(0,8),
			frandom(-1,1),frandom(-1,1),frandom(1,2),
			frandom(-0.1,0.1),frandom(-0.1,0.1),-0.05
		);
		TNT1 A 0 A_SpawnItemEx("HDSmoke",random(-3,3),random(-3,3),random(-3,3),random(-1,1),random(-1,1),random(1,3),0,SXF_TRANSFERPOINTERS|SXF_NOCHECKPOSITION);
		TNT1 A 0{stamina++;}
		TNT1 A 0 A_JumpIf(stamina<10,"spawn2");
		TNT1 AAAAAA 2 A_SpawnParticle(
			pcol,SPF_FULLBRIGHT,35,
			size:frandom(1,8),0,
			frandom(-16,16),frandom(-16,16),frandom(0,8),
			frandom(-1,1),frandom(-1,1),frandom(1,2),
			frandom(-0.1,0.1),frandom(-0.1,0.1),-0.05
		);
		stop;
	}
}
class BFGBallTail:IdleDummy{
	default{
		+forcexybillboard
		scale 0.8;renderstyle "add";
	}
	states{
	spawn:
		BFS1 AB 2 bright A_FadeOut(0.2);
		loop;
	}
}
class BFGPuff:GreenParticleFountain{
	default{
		-invisible +nointeraction +forcexybillboard +bloodlessimpact
		+noblood +alwayspuff -allowparticles +puffonactors +puffgetsowner +forceradiusdmg
		+hittracer
		renderstyle "add";
		damagetype "BFGBallAttack";
		scale 0.8;
		obituary "$OB_MPBFG_BOOM";
	}
	states{
	spawn:
		BFE2 A 1 bright nodelay{
			if(target)target=target.target;
			A_StartSound("misc/bfgrail",9005);
		}
		BFE2 A 3 bright{
			A_Explode(random(196,320),320,0);

			//teleport victim
			if(
				tracer
				&&tracer!=target
				&&!tracer.player
				&&!tracer.special
				&&(
					!tracer.bismonster
					||tracer.health<1
				)
				&&!random(0,3)
			){
				spawn("TeleFog",tracer.pos,ALLOW_REPLACE);
				tracer.setorigin(level.PickDeathmatchStart(),false);
				tracer.vel=(frandom(-10,10),frandom(-10,10),frandom(10,20));
				spawn("TeleFog",tracer.pos,ALLOW_REPLACE);
			}
		}
		BFE2 ABCDE 2 bright A_FadeOut(0.1);
		TNT1 A 0 A_SpawnItemEx("BFGNecroShard",0,0,10,10,0,0,random(0,360),SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS,254);
		stop;
	}
}


//cell weapons get charged by BFG
extend class HDWeapon{
	bool CheckBFGCharge(int whichws){
		if(
			!owner
			||weaponstatus[whichws]<0
		)return false;
		bool chargeable=false;
		let bfug=bfg9k(owner.findinventory("bfg9k"));
		if(!bfug)return false;
		if(
			bfug.weaponstatus[BFGS_BATTERY]>BFGC_MINCHARGE
			||bfug.weaponstatus[BFGS_CHARGE]>BFGC_MINCHARGE
		)chargeable=true;
		if(!chargeable&&owner.findinventory("HDBattery")){
			let batts=HDBattery(owner.findinventory("HDBattery"));
			for(int i=0;i<amount;i++){
				if(batts.mags[i]>=BFGC_MINCHARGE){
					chargeable=true;
					break;
				}
			}
		}
		if(!chargeable&&owner.findinventory("HDBackpack")){
			let bp=HDBackpack(owner.findinventory("HDBackpack"));
			array<string> inbp;inbp.clear();
			int batindex=bp.invclasses.find("hdbattery");
			bp.amounts[batindex].split(inbp," ");
			for(int i=0;i<inbp.size();i++){
				if(inbp[i].toint()>=BFGC_MINCHARGE){
					chargeable=true;
					break;
				}
			}
		}
		if(chargeable)weaponstatus[whichws]=20;
		return chargeable;
	}
}


//until we scriptify the bossbrain properly...
class BFGAccelerator:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			thinkeriterator it=thinkeriterator.create("BFG9k");
			actor bff;
			while(
				bff=inventory(it.Next())
			){
				let bfff=BFG9k(Bff);
				if(bfff){
					int which=randompick(BFGS_BATTERY,BFGS_CHARGE);
					bfff.weaponstatus[which]=min(bfff.weaponstatus[which]+1,20);
				}
			}
		}stop;
	}
}

