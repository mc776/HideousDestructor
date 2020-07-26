//-------------------------------------------------
// Medikit
//-------------------------------------------------
class PortableMedikit:HDPickup{
	default{
		//$Category "Items/Hideous Destructor/Supplies"
		//$Title "Medikit"
		//$Sprite "PMEDA0"

		-hdpickup.droptranslation
		inventory.pickupmessage "Picked up a medikit.";
		inventory.icon "PMEDA0";
		scale 0.4;
		hdpickup.bulk ENC_MEDIKIT;
		tag "medikit";
		hdpickup.refid HDLD_MEDIKIT;
		+inventory.ishealth
	}
	states{
	spawn:
		MEDI A -1;
		stop;
	use:
		TNT1 A 0{
			if(
				!FindInventory("HDMedikitter")
				||player.cmd.buttons&BT_USE
			){
				let mdk=HDMedikitter(spawn("HDMedikitter",pos));
				mdk.actualpickup(self,true);
				if(A_JumpIfInventory("PortableStimpack",0,"null"))A_DropItem("PortableStimpack");
				else A_GiveInventory("PortableStimpack");
				if(A_JumpIfInventory("SecondBlood",0,"null"))A_DropItem("SecondBlood");
				else A_GiveInventory("SecondBlood");
				A_TakeInventory("PortableMedikit",1);
			}else{
				A_Log("You pull out the medikit you've already unwrapped.",true);
			}
			if(!hdplayerpawn(self)||!hdplayerpawn(self).incapacitated)A_SelectWeapon("HDMedikitter");
			A_StartSound("weapons/pocket",9);
		}
		fail;
	}
}

class HDWoundFixer:HDWeapon{
	default{
		+weapon.wimpy_weapon +weapon.no_auto_switch +weapon.cheatnotweapon
		+nointeraction
		hdwoundfixer.injectoricon "TNT1A0";
	}
	int checkwoundcount(bool checkunstable=false){
		let onr=HDPlayerPawn(owner);
		if(onr){
			if(checkunstable)return onr.woundcount+onr.unstablewoundcount;
			else return onr.woundcount;
		}
		return 0;
	}
	static bool DropMeds(actor caller,int amt=1){
		if(!caller)return false;
		array<inventory> items;items.clear();
		for(inventory item=caller.inv;item!=null;item=!item?null:item.inv){
			if(
				item.bishealth
			){
				items.push(item);
			}
		}
		if(!items.size())return false;
		double aang=caller.angle;
		double ch=items.size()?20.:0;
		caller.angle-=ch*(items.size()-1)*0.5;
		for(int i=0;i<items.size();i++){
			caller.a_dropinventory(items[i].getclassname(),amt>0?amt:items[i].amount);
			caller.angle+=ch;
		}
		caller.angle=aang;
		return true;
	}
	string injectoricon;property injectoricon:injectoricon;
	class<inventory> injectortype;property injectortype:injectortype;
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		sb.drawimage(
			injectoricon,(-23,-7),
			sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT
		);
		sb.drawnum(hpl.countinv(injectortype),-22,-8,sb.DI_SCREEN_CENTER_BOTTOM,font.CR_BLACK);
	}
	override void DropOneAmmo(int amt){
		DropMeds(owner,clamp(amt,1,10));
	}
	//used for injectors
	action void A_TakeInjector(class<inventory> injectortype){
		let mmm=HDMagAmmo(findinventory(injectortype));
		if(mmm){
			mmm.amount--;
			if(mmm.amount<1)mmm.destroy();
			else if(mmm.mags.size())mmm.mags.pop();
		}
	}
	states{
	reload:
		TNT1 A 4{
			if(player&&!(player.oldbuttons&BT_RELOAD))HDPlayerPawn.CheckStrip(self,-1);
			A_ClearRefire();
		}
		goto readyend;
	}
}
enum MediNums{
	MEDIKIT_FLESHGIVE=5,
	MEDIKIT_MAXFLESH=42,
	MEDIKIT_NOTAPLAYER=MAXPLAYERS+1,

	MEDS_SECONDFLESH=1,
	MEDS_USEDON=2,
	MEDS_ACCURACY=3,
	MEDS_BLOOD=4,
}
class HDMedikitter:HDWoundFixer{
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	default{
		-weapon.no_auto_switch
		+inventory.invbar
		-nointeraction
		weapon.selectionorder 1001;
		weapon.slotnumber 9;
		scale 0.3;
		tag "Second Flesh applicator";
		hdweapon.refid HDLD_FINJCTR;
	}
	override void initializewepstats(bool idfa){
		weaponstatus[MEDS_SECONDFLESH]=MEDIKIT_MAXFLESH;
		weaponstatus[MEDS_USEDON]=-1;
	}
	override double weaponbulk(){
		return ENC_MEDIKIT;
	}
	override string,double getpickupsprite(){
		return (weaponstatus[MEDS_USEDON]<0)?"MEDIB0":"MEDIC0",0.6;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		let ww=hdmedikitter(hdw);
		int of=0;
		if(
			hpl.woundcount
			&&(weaponstatus[MEDS_USEDON]<0||weaponstatus[MEDS_USEDON]==hpl.playernumber())
		){
			of=clamp(int(hpl.woundcount*0.1),1,3);
			if(hpl.flip)of=-of;
		}
		sb.drawrect(-29,-17+of,2,6);
		sb.drawrect(-31,-15+of,6,2);
		if(ww.weaponstatus[MEDS_USEDON]>=0)sb.drawimage(
			"BLUDC0",(-14,-7),
			sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT,
			0.8
		);
		int btn=hpl.player.cmd.buttons;
		if(!(btn&BT_FIREMODE))sb.drawwepnum(ww.weaponstatus[MEDS_SECONDFLESH],MEDIKIT_MAXFLESH);
		sb.drawnum(hpl.countinv("PortableMedikit"),-43,-8,sb.DI_SCREEN_CENTER_BOTTOM,font.CR_BLACK);

		int usedon=weaponstatus[MEDS_USEDON];
		if(usedon>=0){
			string patientname=
			(
				(usedon<MAXPLAYERS&&playeringame[usedon])?players[usedon].getusername():
				"\ca*** UNKNOWN ***"
			);
			sb.DrawString(sb.psmallfont,patientname,(-43,-24),
				sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_TEXT_ALIGN_CENTER,
				Font.CR_RED
			);
		}
	}
	override string gethelptext(){
		int usedon=weaponstatus[MEDS_USEDON];
		return
		WEPHELP_RELOAD.."  Take off armour\n"
		..WEPHELP_INJECTOR
		.."\n  ...while pressing:\n"
		.."  <\cunothing"..WEPHELP_RGCOL..">  Treat wounds\n"
		.."  "..WEPHELP_ZOOM.."  Treat burns\n"
		.."  "..WEPHELP_FIREMODE.."  Run diagnostic"
		;
	}
	void patchwound(int amt,actor targ){
		let slf=HDPlayerPawn(targ);
		if(slf){
			if(!random(0,1)&&(slf.alpha<1||slf.bshadow))amt-=random(0,amt+1);
			int wound=max(slf.woundcount,0);
			int unstablewound=max(slf.unstablewoundcount,0);
			if(wound){
				slf.woundcount=max(0,wound-amt);
			}else if(unstablewound){
				slf.unstablewoundcount=max(0,unstablewound-amt);
			}else amt=0;
			slf.oldwoundcount+=amt;
		}else{
			HDBleedingWound bldw=null;
			thinkeriterator bldit=thinkeriterator.create("HDBleedingWound");
			while(bldw=HDBleedingWound(bldit.next())){
				if(
					bldw
					&&bldw.bleeder==targ
				)break;
			}
			if(bldw)bldw.bleedpoints=max(0,bldw.bleedpoints-amt);
		}
	}
	action void A_MedikitReady(){
		A_WeaponReady(WRF_NOFIRE|WRF_ALLOWUSER1|WRF_ALLOWUSER3);
		if(!player)return;
		int bt=player.cmd.buttons;

		//don't do the other stuff if holding reload
		//LET THE RELOAD STATE HANDLE EVERYTHING ELSE
		if(bt&BT_RELOAD){
			setweaponstate("reload");
			return;
		}

		//wait for the player to decide what they're doing
		if(bt&BT_ATTACK&&bt&BT_ALTATTACK)return;

		//use on someone else
		if(bt&BT_ALTATTACK){
			if(
				(bt&BT_FIREMODE)
				&&!(bt&BT_ZOOM)
			)setweaponstate("diagnoseother");
			else if(invoker.weaponstatus[MEDS_SECONDFLESH]<1){
				A_WeaponMessage("You are out of Auto-Sutures.");
				setweaponstate("nope");
			}else setweaponstate("fireother");
			return;
		}

		//self
		if(bt&BT_ATTACK){
			//radsuit blocks everything
			if(countinv("WornRadsuit")){
				if(!countinv("PortableRadsuit"))A_TakeInventory("WornRadsuit");
				else{
					if(getcvar("hd_autostrip"))setweaponstate("reload");
					else{
						if(getcvar("hd_helptext"))A_WeaponMessage("Take off your environment suit first!\n\n(toggle it in your inventory or hit reload)",100);
						setweaponstate("nope");
					}
					return;
				}
			}
			if(pitch<min(player.maxpitch,80)){
				//move downwards
				let hdp=hdplayerpawn(self);
				if(hdp)hdp.gunbraced=false;
				A_MuzzleClimb(0,5,0,5);
			}else{
				bool scanning=bt&BT_FIREMODE;
				//armour blocks everything except scan
				if(
					!scanning
					&&countinv("HDArmourWorn")
				){
					if(getcvar("hd_autostrip"))setweaponstate("reload");
					else{
						if(getcvar("hd_helptext"))A_WeaponMessage("Take off your armour first!\n\n(\cdhd_strip\c- in the console\n\nor hit reload)",100);
						A_Refire("nope");
					}
					return;
				}
				//diagnose
				if(scanning){
					setweaponstate("diagnose");
					return;
				}
				//act upon flesh
				if(invoker.weaponstatus[MEDS_SECONDFLESH]<1){
					A_WeaponMessage("You are out of Auto-Sutures.");
					setweaponstate("nope");
					return;
				}
				if(bt&BT_ZOOM){
					//treat burns
					let a=HDPlayerPawn(self);
					if(a){
						if(a.burncount<1){
							A_WeaponMessage("You have no burns to treat.");
							setweaponstate("nope");
						}else setweaponstate("patchburns");
						return;
					}
				}else{
					//treat wounds
					if(!invoker.checkwoundcount(true)){
						A_WeaponMessage("You have no wounds to treat.");
						setweaponstate("nope");
					}else setweaponstate("patchup");
					return;
				}
			}
		}
	}
	states{
	select:
		TNT1 A 10{
			if(!getcvar("hd_helptext")) return;
			A_WeaponMessage("\cg+++ \cjMEDIKIT \cg+++\c-\n\n\nPress and hold Fire\nto patch yourself up.",175);
		}
		goto super::select;
	ready:
		TNT1 A 1 A_MedikitReady();
		goto readyend;
	flashstaple:
		TNT1 A 1{
			A_StartSound("medikit/staple",CHAN_WEAPON);
			A_StartSound("misc/bulletflesh",CHAN_BODY,CHANF_OVERLAP);
			invoker.weaponstatus[MEDS_BLOOD]+=random(0,2);
			if(hdplayerpawn(self)){
				hdplayerpawn(self).secondflesh++;
			}else givebody(3);
		}goto flashend;
	flashnail:
		TNT1 A 1{
			A_StartSound("medikit/stopper",CHAN_WEAPON,CHANF_OVERLAP);
			A_StartSound("misc/bulletflesh",CHAN_BODY,CHANF_OVERLAP);
			invoker.weaponstatus[MEDS_BLOOD]+=random(1,2);
		}goto flashend;
	flashend:
		TNT1 A 1{
			givebody(1);
			damagemobj(invoker,self,1,"staples");
			A_ZoomRecoil(0.9);
			A_ChangeVelocity(frandom(-1,0.1),frandom(-1,1),0.5,CVF_RELATIVE);
		}
		stop;
	altfire:
	althold:
	fireother:
		TNT1 A 0 A_JumpIf(pressingfiremode()&&!pressingzoom(),"diagnoseother");
		TNT1 A 10{
			flinetracedata mediline;
			linetrace(
				angle,42,pitch,
				offsetz:height-12,
				data:mediline
			);
			let c=HDPlayerPawn(mediline.hitactor);
			if(!c){
				//resolve where the target is not an HD player
				if(
					mediline.hitactor
					&&mediline.hitactor.bsolid
					&&!mediline.hitactor.bnoblood
					&&(
						mediline.hitactor.bloodtype=="HDMasterBlood"
						||mediline.hitactor.bloodtype=="Blood"
					)
					&&(
						mediline.hitactor is "HDMobMan"
					)
				){
					let mb=hdmobbase(mediline.hitactor);
					if(
						mediline.hitactor.health<mediline.hitactor.spawnhealth()
						||(
							mb
							&&mb.bodydamage>0
						)
					){
						if(invoker.weaponstatus[MEDS_SECONDFLESH]<1){
							A_WeaponMessage("You are out of Auto-Sutures.");
							return resolvestate("nope");
						}
						invoker.target=mediline.hitactor;
						return resolvestate("applythatshit");
					}else{
						A_WeaponMessage("They have no injuries to treat.");
						return resolvestate("nope");
					}
				}else{
					if(getcvar("hd_helptext"))A_WeaponMessage("Nothing to be done here.\n\nHeal thyself? (press fire)",150);
					return resolvestate("nope");
				}
			}
			if(
				c.player
				&&invoker.weaponstatus[MEDS_USEDON]>=0
				&&invoker.weaponstatus[MEDS_USEDON]!=c.playernumber()
			){
				if(c.getcvar("hd_helptext"))c.A_Print(string.format("Get the hell away!\n\n%s is trying to stab you\n\nwith a used syringe!!!",player.getusername()));
				if(getcvar("hd_helptext"))A_Print("Why are you attacking your teammate\n\nwith used medical equipment!?");
			}else if(c.countinv("IsMoving")>4){
				if(c.getcvar("hd_helptext"))c.A_Print(string.format("Stop squirming!\n\n%s is trying to heal you\n\nnot bugger you...",player.getusername()));
				if(getcvar("hd_helptext"))A_WeaponMessage("You'll need them to stay still...");
				return resolvestate("nope");
			}
			if(!c.player.bot && c.countinv("WornRadsuit") && c.countinv("PortableRadsuit")){
				if(getcvar("hd_helptext"))A_WeaponMessage("Get them to take off their environment suit first!\n\n(toggle it in the inventory)",100);
				return resolvestate("nope");
			}
			if(!c.player.bot && c.countinv("HDArmourWorn")){
				if(getcvar("hd_helptext"))A_WeaponMessage("Get them to take off their armour first!\n\n(\cdhd_strip\c- in the console)",100);
				return resolvestate("nope");
			}
			if(
				!(getplayerinput(MODINPUT_BUTTONS)&BT_ZOOM)
				&&c.woundcount<1
				&&c.unstablewoundcount<1
			){
				A_WeaponMessage("They have no wounds to treat.");
				return resolvestate("nope");
			}
			if(
				getplayerinput(MODINPUT_BUTTONS)&BT_ZOOM
				&&c.burncount<1
			){
				A_WeaponMessage("They have no burns to treat.");
				return resolvestate("nope");
			}
			if(invoker.weaponstatus[MEDS_SECONDFLESH]<1){
				A_WeaponMessage("You are out of Auto-Sutures.");
				return resolvestate("nope");
			}
			invoker.target=c;
			return resolvestate("applythatshit");
		}goto nope;
	applythatshit:
		TNT1 A 0{
			if(invoker.target){
				if(invoker.target.player)invoker.weaponstatus[MEDS_USEDON]=invoker.target.playernumber();
				else invoker.weaponstatus[MEDS_USEDON]=MEDIKIT_NOTAPLAYER;
			}
		}
		TNT1 A 0 A_JumpIf(pressingzoom(),"applythathotshit");
		TNT1 A 10{
			invoker.weaponstatus[MEDS_SECONDFLESH]--;
			if(invoker.target){
				invoker.target.A_StartSound("medikit/stopper",CHAN_WEAPON,CHANF_OVERLAP);
				invoker.target.A_StartSound("misc/bulletflesh",CHAN_BODY,CHANF_OVERLAP);
			}
		}
		TNT1 AAAAA 3{
			A_StartSound("medikit/staple",CHAN_WEAPON);
			invoker.weaponstatus[MEDS_BLOOD]+=random(0,1);
			let itg=invoker.target;
			if(itg){
				itg.A_StartSound("misc/smallslop",CHAN_BODY,CHANF_OVERLAP);
				if(!random(0,3))invoker.setstatelabel("patchupend");
				itg.givebody(1);
				itg.damagemobj(invoker,null,1,"staples",DMG_FORCED);

				if(hdplayerpawn(itg)){
					hdplayerpawn(itg).secondflesh++;
				}else{
					if(hdmobbase(itg))hdmobbase(itg).bodydamage-=3;
					itg.givebody(3);
					hdmobbase.forcepain(itg);
				}
			}
		}goto patchupend;
	applythathotshit:
		TNT1 A 10{
			if(invoker.target){
				invoker.weaponstatus[MEDS_BLOOD]+=random(1,2);
				int fleshgive=min(MEDIKIT_FLESHGIVE,invoker.weaponstatus[MEDS_SECONDFLESH]);
				invoker.weaponstatus[MEDS_SECONDFLESH]-=fleshgive;
				invoker.target.A_StartSound("medikit/stopper",CHAN_WEAPON);
				invoker.target.A_StartSound("misc/bulletflesh",CHAN_BODY,CHANF_OVERLAP);
				invoker.target.A_StartSound("misc/smallslop",CHAN_BODY,CHANF_OVERLAP);
				actor a=spawn("SecondFleshBeast",invoker.target.pos,ALLOW_REPLACE);
				a.target=invoker.target;
				a.stamina=fleshgive;
			}
		}
		goto nope;
	patchup:
		TNT1 A 10;
		TNT1 A 0{
			if(invoker.weaponstatus[MEDS_SECONDFLESH]<1){
				A_WeaponMessage("You are out of Auto-Sutures.");
				setweaponstate("nope");
				return;
			}
			if(invoker.weaponstatus[MEDS_USEDON]<0)
				invoker.weaponstatus[MEDS_USEDON]=playernumber();
			invoker.weaponstatus[MEDS_SECONDFLESH]--;
		}
		TNT1 A 10 A_Overlay(3,"flashnail");
		TNT1 AAAAA random(4,5){
			invoker.target=self;
			A_Overlay(3,"flashstaple");
			if(!random(0,3))invoker.setstatelabel("patchupend");
		}goto patchupend;
	patchupend:
		TNT1 A 10{
			let itg=invoker.target;
			if(itg)invoker.patchwound(1,itg);
		}
		TNT1 A 0 A_ClearRefire();
		goto ready;
	patchburns:
		TNT1 A 6;
		TNT1 A 8{
			if(!(self is "HDPlayerPawn"))return;
			if(invoker.weaponstatus[MEDS_USEDON]<0)
				invoker.weaponstatus[MEDS_USEDON]=playernumber();
			int fleshgive=min(MEDIKIT_FLESHGIVE,invoker.weaponstatus[MEDS_SECONDFLESH]);
			invoker.weaponstatus[MEDS_SECONDFLESH]-=fleshgive;
			A_StartSound("medikit/stopper",CHAN_WEAPON);
			A_StartSound("misc/bulletflesh",CHAN_BODY,CHANF_OVERLAP);
			A_StartSound("misc/smallslop",CHAN_BODY,CHANF_OVERLAP);
			actor a=spawn("SecondFleshBeast",pos,ALLOW_REPLACE);
			a.target=self;
			a.stamina=fleshgive;
		}
		goto ready;

	diagnose:
		TNT1 A 0 A_WeaponMessage("\cdMedikit Auto-Diagnostic Tool engaged.\c-\n\n\ccScanning, please wait...");
		TNT1 AAAAAAAAAAAA 2{
			A_StartSound("medikit/scan",CHAN_WEAPON,volume:0.5);
			A_SetBlend("aa aa 88",0.04,1);
		}
		TNT1 A 0 A_ScanResults(self,12);
		TNT1 A 0 A_Refire("nope");
		goto readyend;
	diagnoseother:
		TNT1 A 0{
			A_WeaponMessage("\cdMedikit Auto-Diagnostic Tool engaged.\c-\n\n\ccScanning, please wait...");
			invoker.target=null;
			invoker.weaponstatus[MEDS_ACCURACY]=0;
		}
		TNT1 AAAAAAAAAAAA 2{
			A_StartSound("medikit/scan",CHAN_WEAPON,volume:0.4);
			flinetracedata mediline;
			linetrace(
				angle,42,pitch,
				offsetz:height-12,
				data:mediline
			);
			let mha=mediline.hitactor;
			if(
				!mha
				||(invoker.target&&mha!=invoker.target)
			){
				invoker.target=null;
				invoker.weaponstatus[MEDS_ACCURACY]=0;
				return;
			}
			invoker.target=mha;
			invoker.weaponstatus[MEDS_ACCURACY]++;
		}
		TNT1 A 0 A_ScanResults(invoker.target,invoker.weaponstatus[MEDS_ACCURACY]);
		TNT1 A 0 A_Refire("nope");
		goto readyend;

	spawn:
		MEDI B -1 nodelay{
			if(
				invoker.weaponstatus[MEDS_USEDON]>=0
			){
				frame=2;
				if(invoker.weaponstatus[MEDS_BLOOD]>0){
					actor bbb=spawn("BloodSplatSilent",pos,ALLOW_REPLACE);
					if(bbb)bbb.vel=vel;
					tics=random(10,500-invoker.weaponstatus[MEDS_BLOOD]);
					invoker.weaponstatus[MEDS_BLOOD]--;
				}
			}
		}wait;
	}
	action void A_ScanResults(actor scanactor,int scanaccuracy){
		A_StartSound("medikit/done",CHAN_WEAPON);
		int thrownoff=scanaccuracy-12;
		if(!scanactor||abs(thrownoff)>10){
			A_WeaponMessage("\caMedikit Auto-Diagnostic Tool failed.");
			invoker.target=null;
			invoker.weaponstatus[MEDS_ACCURACY]=0;
			return;
		}
		string scanactorname=HDMath.GetName(scanactor);
		let slf=HDPlayerPawn(scanactor);
		if(!slf){
			int scanactorhealthpercent=scanactor.health*100/scanactor.spawnhealth();
			A_WeaponMessage(string.format("Medikit Auto-Diagnostic complete.

			Status report:

			\ccPatient: \cy%s

			\ccOverall Health: \cg%u%%

			\cu(all numbers are based on %% of minimum
			\cuconsidered to be lethal in all situations.)",
			scanactorname,scanactorhealthpercent+random(-thrownoff,thrownoff)),210);

			A_Log(string.format("Medikit Auto-Diagnostic:
\ccPatient: \cy%s
\ccOverall Health: \cg%u%%",scanactorname,scanactorhealthpercent),true);
			return;
		}
		int uw=slf.unstablewoundcount;
		int ww=slf.woundcount;
		int ow=slf.oldwoundcount;
		int bb=slf.burncount;
		double bl=double(slf.bloodloss)/(HDCONST_BLOODBAGAMOUNT<<2);
		int ag=int(slf.aggravateddamage*0.2+countinv("IsMoving")+abs(thrownoff));
		int wg=random(-thrownoff,thrownoff);
		if(ww||uw)wg+=2;
		if(countinv("HDArmourWorn"))wg+=5;
		ow=max(ow+random(-ag,ag),0);
		bb=max(bb+random(-ag,ag),0);
		uw=max(uw+random(-wg,wg),0);
		ww=max(ww+random(-wg,wg),0);
		bl=max(bl+frandom(-wg,wg),0);
		A_WeaponMessage(string.format("Medikit Auto-Diagnostic complete.

		Status report:

		\ccPatient: \cy%s

		\ccOpen wounds: \cg%u%%

		\ccWounds temporarily bandaged: \ca%u%%
		\ccWounds already treated: \cd%u%%
		\ccBurns: \cq%u%%

		\ccBlood loss: \ca%.1f \cctransfusion units

		\cu(%% is of total generally considered to be lethal except where noted.)",
		scanactorname,ww,uw,ow,bb,bl),210);

		A_Log(string.format("Medikit Auto-Diagnostic:
\ccPatient: \cy%s
\ccOpen wounds: \cg%u%%
\ccWounds temporarily bandaged: \ca%u%%
\ccWounds already treated: \cd%u%%
\ccBurns: \cq%u%%
\ccBlood loss: \ca%.1f units"
,scanactorname,ww,uw,ow,bb,bl),true);
	}
	override string pickupmessage(){
		if(weaponstatus[MEDS_SECONDFLESH]<MEDIKIT_MAXFLESH)return "Picked up a used medikit.";
		return "Picked up an opened medikit.";
	}
}
class SecondFleshBeast:IdleDummy{
	states{
	spawn:
		TNT1 A 30;
		TNT1 A 12{target.A_Scream();}
		TNT1 A 4{
			let tgt=HDPlayerPawn(target);
			if(!tgt||tgt.bkilled||stamina<1){destroy();return;}
			if(tgt.health>10)tgt.damagemobj(tgt,tgt,min(tgt.health-10,3),"internal",DMG_NO_ARMOR);
			tics=clamp(200-stamina,4,random(4,40));
			if(tics<10)tgt.A_StartSound(tgt.painsound,CHAN_VOICE);
			tgt.stunned+=10;
			tgt.burncount--;
			if(!random(0,200))tgt.aggravateddamage++;
			stamina--;
			if(hd_debug)A_Log(string.format("aggro %i  old %i  unstable %i",tgt.aggravateddamage,tgt.oldwoundcount,tgt.unstablewoundcount));
		}wait;
	}
}


class SelfBandage:HDWoundFixer{
	default{
		+hdweapon.dontdisarm
		weapon.selectionorder 1004;
		weapon.slotnumber 9;
		tag "improvised bandaging";
	}
	void bandagewound(int amt,actor targ){
		let slf=HDPlayerPawn(targ);
		if(slf){
			if(!random(0,2)&&(slf.alpha<1||slf.bshadow))amt-=random(0,amt+1);
			int wound=max(slf.woundcount,0);
			amt=min(amt,wound);
			if(wound){
				amt=min(amt,wound);
				slf.woundcount-=amt;
				slf.unstablewoundcount+=amt;
			}
		}else{
			HDBleedingWound bldw=null;
			thinkeriterator bldit=thinkeriterator.create("HDBleedingWound");
			while(bldw=HDBleedingWound(bldit.next())){
				if(
					bldw
					&&bldw.bleeder==targ
				)break;
			}
			if(bldw)bldw.bleedpoints=max(0,bldw.bleedpoints-amt);
			if(
				(!bldw||bldw.bleedpoints<1)
				&&owner
				&&owner!=targ
			){
				wepmsg="There is no wound to treat.";
				msgtimer=70;
				if(owner.player)owner.player.setpsprite(PSP_WEAPON,findstate("nope"));
			}
		}
	}
	override string,double getpickupsprite(){return "BLUDC0",1.;}
	override string gethelptext(){return WEPHELP_INJECTOR
		.."\n"..WEPHELP_ALTRELOAD.."  Remove blood feeder"
		..(owner.countinv("BloodBagWorn")?"":"(if any)");}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		int of=0;
		if(hpl.woundcount){
			sb.drawimage(
				"BLUDC0",(-17,-6),
				sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT,
				0.6
			);
			of=clamp(int(hpl.woundcount*0.2),1,3);
			if(hpl.flip)of=-of;
		}
		sb.drawrect(-24,-18+of,2,10);
		sb.drawrect(-29,-14+of,12,2);
	}
	override inventory CreateTossable(int amount){
		DropMeds(owner,0);
		return null;
	}
	int targetlock;
	states{
	select:
		TNT1 A 0{
			if(!getcvar("hd_helptext")) return;
			if(invoker.checkwoundcount())A_WeaponMessage("\cu--- \ccBANDAGING \cu---\c-\n\n\nPress and hold Fire\n\nwhile standing still\n\nto try to not die.",210);
			else A_WeaponMessage("\cu--- \ccBANDAGING \cu---\c-\n\n\nPress and hold Fire to bandage\n\nyourself when you are bleeding.\n\n\n\nPress and hold Altfire\n\nto bandage someone else.",210);
		}
		goto super::select;
	abort:
		TNT1 A 1{
			if(getcvar("hd_helptext"))A_WeaponMessage("You must stay still\n\nto bandage yourself!",70);
		}
		TNT1 A 0 A_Refire("lower");
		goto nope;
	fire:
		TNT1 A 0{
			bool nope=false;
			if(countinv("PortableRadsuit") && countinv("WornRadsuit")){
				if(getcvar("hd_helptext"))A_WeaponMessage("Take off your environment suit first!",70);
				nope=true;
			}
			else if(!invoker.checkwoundcount()){
				if(getcvar("hd_helptext"))A_WeaponMessage("You are not bleeding.",70);
				nope=true;
			}
			if(nope)player.setpsprite(PSP_WEAPON,invoker.findstate("nope"));
		}
	hold:
	lower:
		TNT1 A 0 A_JumpIf(pitch>45,"try");
		TNT1 A 1 A_SetPitch(max(90,pitch+6),SPF_INTERPOLATE);
		TNT1 A 0 A_JumpIfInventory("IsMoving",4,"abort");
		TNT1 A 0 A_Refire("lower");
		goto ready;
	try:
		TNT1 A random(15,25);
		TNT1 A 0{
			A_MuzzleClimb(frandom(-1.5,1.8),frandom(-2.4,2.4));
			if(hdplayerpawn(self))hdplayerpawn(self).fatigue+=2;
		}
		TNT1 A 0 A_Jump(32,2);
		TNT1 A random(5,15) damagemobj(self,self,1,"bleedout");
		TNT1 A 0 A_JumpIfInventory("IsMoving",4,"abort");
	try2:
		TNT1 A 0{
			A_MuzzleClimb(frandom(-1.5,1.8),frandom(-2.4,2.4));
			if(hdplayerpawn(self))hdplayerpawn(self).fatigue+=2;
		}
		TNT1 A random(1,3) A_Jump(32,2,4);
		TNT1 A 0 A_Jump(256,2);
		TNT1 A random(1,3) A_PlaySkinSound(SKINSOUND_GRUNT,"*usefail");
		TNT1 A 0 A_Jump(256,2);
		TNT1 A random(1,3) A_PlaySkinSound(SKINSOUND_GRUNT,"*grunt");
		TNT1 A 0 A_Jump(200,2);
		TNT1 A 0 A_StartSound("bandage/rip",CHAN_WEAPON,CHANF_OVERLAP,0.4);
		TNT1 A 0 A_Refire("try4");
		goto ready;
	try3:
		TNT1 A random(20,40){
			A_MuzzleClimb(frandom(-1.6,1.8),frandom(-2.4,2.4));
			if(hdplayerpawn(self))hdplayerpawn(self).fatigue+=2;
		}
		TNT1 A 0 A_Jump(200,2);
		TNT1 A 0 A_StartSound("bandage/rustle",CHAN_BODY,CHANF_OVERLAP);
		TNT1 A random(10,20);
		TNT1 A 0 A_JumpIfInventory("IsMoving",4,"abort");
		TNT1 A 0 A_Refire("try4");
		goto ready;
	try4:
		TNT1 A 0 A_CheckFloor(2);
		TNT1 A 0 A_Jump(240,2);
		TNT1 A 0 A_ChangeVelocity(frandom(-0.5,0.5),frandom(-0.5,0.5),frandom(-2,2));
		TNT1 A 0{
			A_MuzzleClimb(frandom(-1.5,1.7),frandom(-2.4,2.4));
			if(hdplayerpawn(self))hdplayerpawn(self).fatigue+=2;
		}
		TNT1 A 0 A_Jump(240,2);
		TNT1 A random(1,3) A_PlaySkinSound(SKINSOUND_GRUNT,"*grunt");
		TNT1 A 0 A_Jump(140,2);
		TNT1 A 0 A_StartSound("bandage/rustle",CHAN_BODY,CHANF_OVERLAP);
		TNT1 A random(10,20);
		TNT1 A 0 A_JumpIfInventory("IsMoving",4,"abort");
		TNT1 A 0 A_Refire("try5");
		goto ready;
	try5:
		TNT1 A 0 A_MuzzleClimb(frandom(-1.8,1.8),frandom(-2.4,2.4));
		TNT1 A 0 A_Jump(8,"try2");
		TNT1 A 0 A_Jump(12,"try3");
		TNT1 A 0 A_Jump(16,"try4");
		TNT1 A 0 A_Jump(80,2);
		TNT1 A 0 A_StartSound("bandage/rustle",CHAN_BODY);
		TNT1 A random(10,20);
		TNT1 A 0 A_Jump(80,2);
		TNT1 A 0 A_StartSound("weapons/pocket",9);
		TNT1 A random(10,20);
		TNT1 A 0 A_JumpIfInventory("IsMoving",4,"abort");
		TNT1 A 0 A_JumpIf(invoker.checkwoundcount(),2);
		TNT1 A 0 {
			if(getcvar("hd_helptext"))A_WeaponMessage("You seem to be stable.",144);
		}goto nope;
		TNT1 A 0 A_Jump(42,2);
		TNT1 A 0 A_JumpIfInventory("HDArmourWorn",1,2);
		TNT1 A 4 A_Jump(100,2,3);
		TNT1 A 0 {invoker.bandagewound(random(1,3),self);}
		TNT1 A 0 A_MuzzleClimb(frandom(-2.4,2.4),frandom(-2.4,2.4));
		TNT1 A 0 A_Refire("try2");
		goto ready;
	nope:
		TNT1 A 0{invoker.targetlock=0;}
		goto super::nope;
	altfire:
	althold:
		TNT1 A 1;
		TNT1 A 0{
			actor a;int b;
			[a,b]=LineAttack(angle,42,pitch,0,"none",
				"CheckPuff",flags:LAF_NORANDOMPUFFZ|LAF_NOINTERACT
			);
			let c=a.tracer;
			if(!HDBleedingWound.canbleed(c,true)){
				A_WeaponMessage("Nothing to be done here.\n\nHeal thyself?");
				return resolvestate("nope");
			}
			let hdp=HDPlayerPawn(c);
			if(c.countinv("IsMoving")>4){
				c.A_Print(string.format("Stop squirming!\n\n%s is trying to bandage you\n\nnot bugger you...",player.getusername()));
				A_WeaponMessage("You'll need them to stay still...");
				return resolvestate("nope");
			}
			if(hdp&&hdp.woundcount<1){
				A_WeaponMessage("They're not bleeding.");
				return resolvestate("nope");
			}
			invoker.target=c;
			invoker.targetlock++;
			if(invoker.targetlock>10){
				A_Refire("injectbandage");
			}else A_Refire();
			return resolvestate(null);
		}goto nope;
	injectbandage:
		TNT1 A random(7,14){
			if(invoker.target){
				if(random(0,2)){
					if(!random(0,2))invoker.target.A_StartSound("bandage/rustle",CHAN_BODY);
					return;
				}
				invoker.target.A_StartSound("weapons/pocket",CHAN_BODY,CHANF_OVERLAP);
				invoker.bandagewound(random(3,5),invoker.target);
			}
		}goto ready;

	altreload:
		TNT1 A 0 A_StartSound("weapons/pocket",9);
		TNT1 A 15 A_JumpIf(!countinv("BloodBagWorn")||countinv("WornRadsuit"),"nope");
		TNT1 A 10{
			A_SetBlend("7a 3a 18",0.1,4);
			A_SetPitch(pitch+2,SPF_INTERPOLATE);
			A_PlaySkinSound(SKINSOUND_MEDS,"*usemeds");
			A_DropInventory("BloodBagWorn");
		}
		goto nope;


	spawn:
		TNT1 A 1;
		stop;
	}
}



