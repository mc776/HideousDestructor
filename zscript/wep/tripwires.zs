//-------------------------------------------------
// Frag on a string: the real IED
//-------------------------------------------------
class TripwirePlacerPuff:IdleDummy{
	default{
		-alwayspuff -puffonactors +bloodlessimpact
		stamina 1;radius 0;height 0;
	}
}
class TripwireCheckerPuff:IdleDummy{
	default{
		-alwayspuff +puffonactors +hittracer +bloodlessimpact
		stamina 1;radius 0.1;height 0.1;
	}
}
class Tripwire:HDWeapon{
	class<inventory> grenadeammotype;
	property ammotype:grenadeammotype;
	class<actor> throwtype;
	property throwtype:throwtype;
	class<actor> spoontype;
	property spoontype:spoontype;
	class<weapon> weptype;
	property weptype:weptype;
	default{
		+hdweapon.dontnull
		+nointeraction

		//adding the frag grenade defaults here to prevent needless crashes
		weapon.selectionorder 1021;
		tripwire.ammotype "HDFragGrenadeAmmo";
		tripwire.throwtype "TrippingFrag";
		tripwire.spoontype "HDFragSpoon";
		tripwire.weptype "HDFragGrenades";
	}
	override string,double getpickupsprite(){return "FRAGA0",0.6;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage("FRAGA0",(-52,-4),sb.DI_SCREEN_CENTER_BOTTOM,scale:(0.6,0.6));
			sb.drawnum(hpl.countinv("HDFragGrenadeAmmo"),-45,-8,sb.DI_SCREEN_CENTER_BOTTOM,font.CR_BLACK);
		}
		sb.drawwepnum(
			hpl.countinv("HDFragGrenadeAmmo"),
			(ENC_FRAG/HDCONST_MAXPOCKETSPACE)
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
		return
		WEPHELP_FIRE.."  Place "..(gumspot?"grenade":"end of string").."\n"
		..WEPHELP_ALTFIRE.."  Abort\n"
		;
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10);
			owner.A_DropInventory(grenadeammotype,1);
		}
	}
	actor grenade;
	actor gumspot;
	action void UndoAll(){
		if(invoker.grenade){
			invoker.grenade.master=null;
			invoker.grenade=null;
		}
		if(invoker.gumspot){
			invoker.gumspot.destroy();
			A_Log("Setup aborted.",true);
		}
	}
	override inventory CreateTossable(int amount){
		UndoAll();
		owner.A_DropInventory(grenadeammotype,owner.countinv(grenadeammotype));
		owner.A_GiveInventory("HDFist");
		owner.A_SelectWeapon("HDFist");
		return null;
	}
	states{
	altfire:
		TNT1 A 0 UndoAll();
		goto nope;
	deselect0:
		TNT1 A 10{
			UndoAll();
			A_StartSound("weapons/pocket",9);
			if(countinv("NulledWeapon"))A_SetTics(0);
		}goto super::deselect0;
	select:
		TNT1 A 10{
			if(!countinv(invoker.grenadeammotype)){
				if(getcvar("hd_helptext"))A_Print("No grenades.");
				A_SelectWeapon("HDFist");
			}else if(getcvar("hd_helptext"))A_WeaponMessage("\cp\--- \cqTRIPWIRES \cp---\c-\n\n\nHit fire to set one end of the line,\n\nthen hit fire again to plant the grenade.\nby human hands.\n\nMove carefully.");
			A_StartSound("weapons/pocket",9);
			if(countinv("NulledWeapon"))A_SetTics(0);
		}goto super::select;
	ready:
		TNT1 A 1{
			if(!countinv(invoker.grenadeammotype))A_SelectWeapon("HDFist");
			else A_SetCrosshair(0);
			A_WeaponBusy(invoker.gumspot!=null);
			A_WeaponReady(WRF_ALLOWUSER3);
		}goto readyend;
	fire:
		TNT1 A 0{
			flinetracedata gumline;
			linetrace(
				angle,64,pitch,flags:0,
				offsetz:height-8,
				data:gumline
			);
			let othersector=hdmath.oppositesector(gumline.hitline,gumline.hitsector);
			if(
				gumline.hittype==Trace_HitNone
				||(
					gumline.hittype!=Trace_HitWall
					&&gumline.hittype!=Trace_HitFloor
					&&gumline.hittype!=Trace_HitCeiling
				)||hdf.linetracehitsky(gumline)
			){
				A_Log(string.format(
					"You need to stick the %s on to something stable.",
					invoker.gumspot?"wire":"grenade"
				),true);
				return;
			}
			if(!invoker.gumspot){
				actor aaa=spawn("GumAndString",gumline.hitlocation-gumline.hitdir*0.6,ALLOW_REPLACE);
				aaa.target=self;aaa.master=self;aaa.angle=angle;
				aaa.A_StartSound("tripwire/gumsplat",CHAN_BODY);
				invoker.gumspot=aaa;
				A_Log("Wire end secured. Now to set the grenade...",true);
			}else{
				actor aaa=spawn(invoker.throwtype,gumline.hitlocation-gumline.hitdir*2,ALLOW_REPLACE);
				aaa.target=self;aaa.master=self;aaa.angle=angle;
				aaa.A_StartSound("tripwire/fragclick",CHAN_BODY);
				invoker.grenade=aaa;
				invoker.gumspot.tracer=invoker.grenade;
				invoker.grenade.tracer=invoker.gumspot;
				invoker.grenade.master=self;
				invoker.grenade.target=self;
				A_Log("Grenade secured! Now be very, very careful...",true);
				A_TakeInventory(invoker.grenadeammotype,1,TIF_NOTAKEINFINITE);
				invoker.gumspot=null;
			}
		}goto nope;
	}
}
class GumAndString:IdleDummy{
	bool trapisset;
	double stringlength;
	vector3 ddd;double bbb;float ii;
	sector stuckto;
	double stucktoheight;
	int stucktier;
	default{
		+spriteangle
		spriteangle 0;
		scale 0.1;translation 2;
		radius 0.5;height 0.5;
	}
	void GumTicker(){
		if(
			!tracer&&
			(trapisset||!master||master.health<1)
		){
			destroy();
			return;
		}

		//if gone into floor or ceiling, abort
		if(floorz>pos.z||ceilingz<pos.z){    
			ForceAbort();
			return;
		}

		//check for the actual thing
		if(tracer)A_FaceTracer(0,0,flags:FAF_TOP,-1);
		else if(master)A_FaceMaster(0,0,flags:FAF_TOP,-1);
		flinetracedata wirecheck;
		linetrace(
			angle,512,pitch,flags:0,
			offsetz:0,
			offsetside:0,
			data:wirecheck
		);
		bool carefulplayer=false;
		let atpl=HDPlayerPawn(wirecheck.hitactor);
		if(
			atpl && atpl!=master && atpl.runwalksprint<0
			&& wirecheck.hitlocation.z-atpl.pos.z<24
			&& max(abs(atpl.vel.x),abs(atpl.vel.y),abs(atpl.vel.z))<5
		){
			carefulplayer=true;
			atpl.stunned=max(atpl.stunned,10);
		}

		actor wiretripper=wirecheck.hitactor;
		if(!master && !carefulplayer && wiretripper && wiretripper!=tracer){
			vector3 vvv;
			vvv=wiretripper.vel*0.5;
			PullPin(vvv.x,vvv.y,vvv.z);
			return;
		}
		else if(tracer && wiretripper==tracer)master=null;

		if(
			!wiretripper
			||(tracer && wiretripper==master)
			||(!tracer && wiretripper!=master)
		){
			ForceAbort();
			return;
		}


		//draw a line of particles
		if(!tracer && !master)return;

		//set all the numbers
		if(!trapisset){
			if(tracer)ddd=tracer.pos+(0,0,4);
			else ddd=master.pos+(0,0,master.height-8);

			ddd-=pos;
			stringlength=max(ddd.length(),1);
			bbb=stringlength*0.3;
			ddd/=bbb;

			ii=min(bbb,40)*0.0001;

			if(tracer && !master)trapisset=true;
		}else if(tracer && (tracer.pos+(0,0,4)-pos).length()>stringlength+1){
			PullPin();
			return;
		}

		vector3 ccc;
		for(int i=0;i<bbb;i++){
			ccc=ddd*i*frandom(1-ii,1+ii);
			A_SpawnParticle(
				"white",
				lifetime:1,size:0.5,
				xoff:ccc.x,yoff:ccc.y,zoff:ccc.z,
				startalphaf:0.8
			);
		}

		//set height
		//centerfloor works, as long as dynamic slope alterations don't.
		//if those do, see how the DERP does it.
		switch(stucktier){
		case 1:
			setz(stuckto.centerceiling()+stucktoheight);break;
		case -1:
			setz(stuckto.centerfloor()+stucktoheight);break;
		default:
			break;
		}
	}
	override void postbeginplay(){
		super.postbeginplay();
		trapisset=false;
		stucktoheight=0;
		stucktier=0;

		//and now to find some shit
		flinetracedata flt;
		linetrace(angle,1,pitch,flags:TRF_THRUACTORS,data:flt);
		sector othersector=hdmath.oppositesector(flt.hitline,flt.hitsector);

		if(othersector){
			stuckto=othersector;
			double otherfloorz=othersector.floorplane.zatpoint(flt.hitlocation.xy+flt.hitdir.xy);
			double otherceilingz=othersector.ceilingplane.zatpoint(flt.hitlocation.xy+flt.hitdir.xy);
			if(otherfloorz>flt.hitlocation.z){
				stucktier=-1;
				stucktoheight=flt.hitlocation.z-othersector.centerfloor();
			}else if(otherceilingz<flt.hitlocation.z){
				stucktier=1;
				stucktoheight=flt.hitlocation.z-othersector.centerceiling();
			}
		}else if(flt.hittype==Trace_HitFloor){
			brelativetofloor=true;
			bmovewithsector=true;
		}else if(flt.hittype==Trace_HitCeiling){
			bceilinghugger=true;
			bmovewithsector=true;
		}
	}
	states{
	spawn:
		BAL7 A 1 nodelay GumTicker();
		wait;
	}
	void PullPin(double vvx=0,double vvy=0,double vvz=0){
		let trc=trippinggrenade(tracer);
		if(!tracer)return;
		actor ggg=trc.spawn(trc.rollertype,trc.pos,ALLOW_REPLACE);
		ggg.target=trc.target;
		ggg.vel=(pos-ggg.pos).unit();
		actor hhh=trc.spawn(trc.spoontype,trc.pos,ALLOW_REPLACE);
		hhh.vel=ggg.vel*5;
		ggg.vel*=3;ggg.vel.z++;
		ggg.A_StartSound("weapons/fragpinout",8);
		ggg.vel+=(vvx,vvy,vvz);
		hhh.vel+=(vvx,vvy,vvz);
		if(tracer)tracer.destroy();
		destroy();
	}
	void ForceAbort(){
		A_StartSound("tripwire/break",CHAN_AUTO);
		let trc=trippinggrenade(tracer);
		if(trc){
			actor trcr=spawn(trc.rollertype,trc.pos,ALLOW_REPLACE);
			trcr.A_StartSound("tripwire/break",CHAN_AUTO);
			trc.destroy();
		}else if(master)master.A_StartSound("tripwire/break",CHAN_AUTO);
		if(master)master.A_Log("Welp, there goes that one. Try again?",true);
		destroy();
	}
}
class TrippingGrenade:HDUPK{
	sector stuckto;
	double stucktoheight;
	int stucktier;
	int user_pitch;
	class<actor> rollertype;
	property rollertype:rollertype;
	class<actor> spoontype;
	property spoontype:spoontype;
	class<actor> droptype;
	property droptype:droptype;
	default{
		// SPECIAL MAPPING NOTE
		// user_pitch sets the starting pitch!

		+nogravity +shootable +noblood +nodamage +notargetswitch
		health int.MAX;painchance 256; mass 10;
		radius 2;height 2;

		hdupk.pickupmessage "Picked up a grenade.";
	}
	override void OnGrab(actor grabber){
		if(tracer)tracer.destroy();
		bnogravity=false;
		bshootable=false;
		stucktier=999;
	}
	override void postbeginplay(){
		super.postbeginplay();

		//add a gumwad if none exists
		if(!tracer){
			pitch=user_pitch;
			flinetracedata gum;
			linetrace(
				angle,512,pitch,flags:TRF_THRUACTORS,
				offsetz:0,
				offsetside:0,
				data:gum
			);
			if(gum.hittype!=Trace_HitNone){
				tracer=spawn("GumAndString",gum.hitlocation-gum.hitdir*0.4,ALLOW_REPLACE);
				tracer.tracer=self;
				tracer.A_Face(self,0,0);
			}
			angle+=180;pitch=-pitch;
		}

		stucktoheight=0;
		stucktier=0;

		//and now to find some shit
		flinetracedata flt;
		linetrace(angle,1,pitch,flags:TRF_THRUACTORS,data:flt);
		sector othersector=hdmath.oppositesector(flt.hitline,flt.hitsector);

		if(othersector){
			stuckto=othersector;
			double otherfloorz=othersector.floorplane.zatpoint(flt.hitlocation.xy+flt.hitdir.xy);
			double otherceilingz=othersector.ceilingplane.zatpoint(flt.hitlocation.xy+flt.hitdir.xy);
			if(otherfloorz>flt.hitlocation.z){
				stucktier=-1;
				stucktoheight=flt.hitlocation.z-othersector.centerfloor();
			}else if(otherceilingz<flt.hitlocation.z){
				stucktier=1;
				stucktoheight=flt.hitlocation.z-othersector.centerceiling();
			}
		}else if(flt.hittype==Trace_HitFloor){
			brelativetofloor=true;
			bmovewithsector=true;
		}else if(flt.hittype==Trace_HitCeiling){
			bceilinghugger=true;
			bmovewithsector=true;
		}
	}
	void A_TrackStuckHeight(){
		//set height
		switch(stucktier){
		case 1:
			setz(stuckto.centerceiling()+stucktoheight);break;
		case -1:
			setz(stuckto.centerfloor()+stucktoheight);break;
		case 999:
			bceilinghugger=false;
			bfloorhugger=false;
			break;
		default:
			break;
		}
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(!random(0,9)){
			actor ggg=spawn(rollertype,pos,ALLOW_REPLACE);
			ggg.target=target;
			if(tracer){
				ggg.vel=(tracer.pos-ggg.pos).unit()*3+(0,0,1);
				tracer.destroy();
			}else ggg.vel=(random(-1,1),random(-1,1),1);
			ggg.A_StartSound("tripwire/fragpain",CHAN_AUTO);
			actor hhh=spawn(spoontype,pos,ALLOW_REPLACE);
			hhh.vel=ggg.vel*2;
			bshootable=false;
			destroy();return -1;
		}else if(!random(0,4)){
			if(tracer)tracer.destroy();
			actor aaa=spawn(droptype,pos,ALLOW_REPLACE);
			aaa.vel=vel;
			bshootable=false;
			destroy();return -1;
		}else setstatelabel("spawn");
		return -1;
	}
	states{
	spawn:
		---- A -1;
		stop;
	}
}



class TripwireFrag:Tripwire{
	default{
		weapon.selectionorder 1021;
		tripwire.ammotype "HDFragGrenadeAmmo";
		tripwire.throwtype "TrippingFrag";
		tripwire.spoontype "HDFragSpoon";
		tripwire.weptype "HDFragGrenades";
	}
}
class TrippingFrag:TrippingGrenade{
	default{
		//$Category "Misc/Hideous Destructor/Traps"
		//$Title "Tripwire Grenade"
		//$Sprite "FRAGA0"

		scale 0.3;
		trippinggrenade.rollertype "HDFragGrenadeRoller";
		trippinggrenade.spoontype "HDFragSpoon";
		trippinggrenade.droptype "HDFragGrenadeAmmo";
		hdupk.pickuptype "HDFragGrenadeAmmo";
	}
	override void postbeginplay(){
		super.postbeginplay();
		pickupmessage=getdefaultbytype("HDFragGrenadeAmmo").pickupmessage();
	}
	states{
	spawn:
		FRAG A 1 nodelay A_TrackStuckHeight();
		wait;
	}
}


