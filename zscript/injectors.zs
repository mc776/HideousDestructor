//-------------------------------------------------
// Stims and berserk
//-------------------------------------------------
class HDInjectorMaker:HDMagAmmo{
	class<weapon>injectortype;
	property injectortype:injectortype;
	override bool IsUsed(){return true;}
	default{
		+inventory.invbar
	}
	states{
	use:
		TNT1 A 0{
			A_GiveInventory(invoker.injectortype);
			A_SelectWeapon(invoker.injectortype);
		}
		fail;
	}
}
class PortableStimpack:HDInjectorMaker{
	default{
		//$Category "Items/Hideous Destructor/Supplies"
		//$Title "Stimpack"
		//$Sprite "PSTIA0"

		scale 0.37;
		-hdpickup.droptranslation
		inventory.pickupmessage "Picked up a stimpack.";
		inventory.icon "PSTIA0";
		hdpickup.bulk ENC_STIMPACK;
		tag "stimpack";
		hdpickup.refid HDLD_STIMPAK;
		+inventory.ishealth
		hdinjectormaker.injectortype "HDStimpacker";
	}
	states{
	spawn:
		STIM A -1;
	}
}
class SpentZerk:HDDebris{
	default{
		translation "112:127=107:111";
		xscale 0.32;yscale 0.28;radius 3;height 3;
		bouncesound "misc/fragknock";bouncefactor 0.8;
	}
	states{
	spawn:
		SYRG A 0;
	spawn2:
		---- A 1{
			A_SetRoll(roll+60,SPF_INTERPOLATE);
		}wait;
	death:
		---- A -1{
			roll=0;
			if(!random(0,1))scale.x*=-1;
		}stop;
	}
}
class SpentStim:SpentZerk{
	default{
		translation "176:191=80:95";
	}
	states{
	spawn:
		SYRG A 0 nodelay A_JumpIf(Wads.CheckNumForName("id",0)==-1,1);
		goto spawn2;
		STIM A 0 A_SetScale(0.37,0.37);
		STIM A 0 A_SetTranslation("FreeStimSpent");
		goto spawn2;
		death:
		---- A -1{
			if(Wads.CheckNumForName("id",0)!=-1)roll=0;
			else if(abs(roll)<20)roll+=40;
			if(!random(0,1))scale.x*=-1;
		}stop;
	}
}
class SpentBottle:SpentStim{
	default{
		alpha 0.6;renderstyle "translucent";
		bouncesound "misc/casing";bouncefactor 0.7;scale 0.3;radius 4;height 4;
		translation "10:15=241:243","150:151=206:207";
	}
	override void ondestroy(){
		plantbit.spawnplants(self,7,33);
		actor.ondestroy();
	}
	states{
	spawn:
		BON1 A 0;
		goto spawn2;
	death:
		---- A 100{
			if(random(0,7))roll=randompick(90,270);else roll=0;
			if(roll==270)scale.x*=-1;
		}
		---- A random(2,4){
			if(frandom(0.1,0.9)<alpha){
				angle+=random(-12,12);pitch=random(45,90);
				actor a=spawn("HDGunSmoke",pos,ALLOW_REPLACE);
				a.scale=(0.4,0.4);a.angle=angle;
			}
			A_FadeOut(frandom(-0.03,0.032));
		}wait;
	}
}
class SpentCork:SpentBottle{
	default{
		bouncesound "misc/casing3";scale 0.6;
		translation "224:231=64:71";
	}
	override void ondestroy(){
		plantbit.spawnplants(self,1,0);
		actor.ondestroy();
	}
	states{
	spawn:
		PBRS A 2 A_SetRoll(roll+90,SPF_INTERPOLATE);
		wait;
	}
}
class HDStimpacker:HDWoundFixer{
	class<actor> injecttype;
	class<actor> spentinjecttype;
	class<inventory> inventorytype;
	string noerror;
	property injecttype:injecttype;
	property spentinjecttype:spentinjecttype;
	property inventorytype:inventorytype;
	property noerror:noerror;
	override inventory CreateTossable(int amount){
		HDWoundFixer.DropMeds(owner,0);
		return null;
	}
	override string,double getpickupsprite(){return "STIMA0",1.;}
	override string gethelptext(){return "\cuStimpack\n"..WEPHELP_INJECTOR;}
	default{
		+hdweapon.dontdisarm
		hdstimpacker.injecttype "InjectStimDummy";
		hdstimpacker.spentinjecttype "SpentStim";
		hdstimpacker.inventorytype "PortableStimpack";
		hdstimpacker.noerror "No stimpacks.";
		weapon.selectionorder 1003;
		hdwoundfixer.injectoricon "STIMA0";
		hdwoundfixer.injectortype "PortableStimpack";
	}
	states{
	spawn:
		TNT1 A 1;
		stop;
	select:
		TNT1 A 0{
			bool helptext=getcvar("hd_helptext");
			if(!countinv(invoker.inventorytype)){
				if(helptext)A_WeaponMessage(invoker.noerror);
				A_SelectWeapon("HDFist");
			}else if(helptext)A_WeaponMessage("\cd<<< \cjSTIMPACK \cd>>>\c-\n\n\nStimpacks help reduce\nbleeding temporarily\n\nand boost performance when injured.\n\n\Press altfire to use on someone else.\n\n\cgDO NOT OVERDOSE.");
		}
		goto super::select;
	deselecthold:
		TNT1 A 1;
		TNT1 A 0 A_Refire("deselecthold");
		TNT1 A 0{
			A_SelectWeapon("HDFist");
			A_WeaponReady(WRF_NOFIRE);
		}goto nope;
	fire:
	hold:
		TNT1 A 1;
		TNT1 A 0{
			bool helptext=getcvar("hd_helptext");
			if(!countinv(invoker.inventorytype)){
				if(helptext)A_WeaponMessage(invoker.noerror);
				A_Refire("deselecthold");
			}else if(countinv("PortableRadsuit") && countinv("WornRadsuit")){
				if(helptext)A_WeaponMessage("Take off your environment suit first!",2);
				A_Refire("nope");
			}else if(pitch<55){
				A_SetPitch(pitch+8,SPF_INTERPOLATE);
				A_Refire();
			}else{
				A_Refire("inject");
			}
		}goto nope;
	inject:
		TNT1 A 1{
			A_TakeInjector(invoker.inventorytype);
			A_SetBlend("7a 3a 18",0.1,4);
			A_SetPitch(pitch+2,SPF_INTERPOLATE);
			if(hdplayerpawn(self))A_StartSound(hdplayerpawn(self).medsound,CHAN_VOICE);
			else A_StartSound("*usemeds",CHAN_VOICE);
			A_StartSound("misc/bulletflesh",CHAN_WEAPON);
			actor a=spawn(invoker.injecttype,pos,ALLOW_REPLACE);
			a.accuracy=40;a.target=self;
		}
		TNT1 AAAA 1 A_SetPitch(pitch-0.5,SPF_INTERPOLATE);
		TNT1 A 6;
		TNT1 A 0{
			actor a=spawn(invoker.spentinjecttype,pos+(0,0,height-8),ALLOW_REPLACE);
			a.angle=angle;a.vel=vel;a.A_ChangeVelocity(3,1,2,CVF_RELATIVE);
			a.A_StartSound("weapons/grenopen",8);
		}
		goto injectedhold;
	altfire:
		TNT1 A 10;
		TNT1 A 0 A_Refire();
		goto nope;
	althold:
		TNT1 A 0{
			if(!countinv(invoker.inventorytype)){
				if(getcvar("hd_helptext"))A_WeaponMessage(invoker.noerror);
				A_Refire("deselecthold");
			}
		}
		TNT1 A 8{
			bool helptext=getcvar("hd_helptext");
			flinetracedata injectorline;
			linetrace(
				angle,42,pitch,
				offsetz:height-12,
				data:injectorline
			);
			let c=HDPlayerPawn(injectorline.hitactor);
			if(!c){
				let ccc=HDMobMan(injectorline.hitactor);
				if(
					ccc
					&&invoker.getclassname()=="HDStimpacker"
				){
					if(
						ccc.stunned<100
						||ccc.health<10
					){
						if(helptext)A_WeaponMessage("They don't need it.",2);
						return resolvestate("nope");
					}
					A_TakeInjector(invoker.inventorytype);
					ccc.A_StartSound(ccc.painsound,CHAN_VOICE);
					ccc.stunned=max(0,ccc.stunned>>1);
					if(!countinv(invoker.inventorytype))return resolvestate("deselecthold");
					return resolvestate("injected");
				}
				if(helptext)A_WeaponMessage("Nothing to be done here.\n\nStimulate thyself? (press fire)",2);
				return resolvestate("nope");
			}else if(c.countinv("IsMoving")>4){
				bool chelptext=c.getcvar("hd_helptext");
				if(c.stimcount){
					if(chelptext)c.A_Print(string.format("Run away!!!\n\n%s is trying to overdose you\n\n(and possibly bugger you)...",player.getusername()));
					if(helptext)A_WeaponMessage("They seem a bit fidgety...");
				}else{
					if(chelptext)c.A_Print(string.format("Stop squirming!\n\n%s only wants to\n\ngive you some drugs...",player.getusername()));
					if(helptext)A_WeaponMessage("You'll need them to stay still...");
				}
				return resolvestate("nope");
			}else if(
				//because poisoning people should count as friendly fire!
				(teamplay || !deathmatch)&&
				(
					(
						invoker.injecttype=="InjectStimDummy"
						&& c.stimcount
					)||
					(
						invoker.injecttype=="InjectZerkDummy"
						&& c.zerk
					)
				)
			){
				if(c.getcvar("hd_helptext"))c.A_Print(string.format("Run away!!!\n\n%s is trying to overdose you\n\n(and possibly bugger you)...",player.getusername()));
				if(getcvar("hd_helptext"))A_WeaponMessage("They seem a bit fidgety already...");
				return resolvestate("nope");
			}else{
				//and now...
				A_TakeInjector(invoker.inventorytype);
				c.A_StartSound(hdplayerpawn(c).medsound,CHAN_VOICE);
				c.A_SetBlend("7a 3a 18",0.1,4);
				actor a=spawn(invoker.injecttype,c.pos,ALLOW_REPLACE);
				a.accuracy=40;a.target=c;
				if(!countinv(invoker.inventorytype))return resolvestate("deselecthold");
				return resolvestate("injected");
			}
		}
	injected:
		TNT1 A 0{
			actor a=spawn(invoker.spentinjecttype,pos+(0,0,height-8),ALLOW_REPLACE);
			a.angle=angle;a.vel=vel;a.A_ChangeVelocity(-2,1,4,CVF_RELATIVE);
			A_StartSound("weapons/grenopen",CHAN_VOICE);
		}
	injectedhold:
		TNT1 A 1 A_ClearRefire();
		TNT1 A 0 A_JumpIf(pressingfire(),"injectedhold");
		TNT1 A 10 A_SelectWeapon("HDFist");
		TNT1 A 1 A_WeaponReady(WRF_NOFIRE);
		goto readyend;
	}
}
class InjectStimDummy:IdleDummy{
	hdplayerpawn tg;
	states{
	spawn:
		TNT1 A 6 nodelay{
			tg=HDPlayerPawn(target);
			if(!tg||tg.bkilled){destroy();return;}
			if(tg.zerk)tg.aggravateddamage+=int(ceil(accuracy*0.01*random(1,3)));
		}
		TNT1 A 1{
			if(target.bkilled||accuracy<1){destroy();return;}
			if(!(accuracy%2))tg.stimcount++;
			accuracy--;
		}wait;
	}
}



class PortableBerserkPack:hdinjectormaker{
	default{
		//$Category "Items/Hideous Destructor/Supplies"
		//$Title "Berserk"
		//$Sprite "PSTRA0"

		inventory.pickupmessage "Picked up a berserk pack.";
		inventory.icon "PPSTA0";
		scale 0.3;
		hdpickup.bulk ENC_STIMPACK;
		tag "berserk pack";
		hdpickup.refid HDLD_BERSERK;
		+inventory.ishealth
		hdinjectormaker.injectortype "HDBerserker";
	}
	states{
	spawn:
		PSTR A -1 nodelay{if(invoker.amount>2)invoker.scale=(0.4,0.35);else invoker.scale=(0.3,0.3);}
	}
}
class HDBerserker:HDStimpacker{
	default{
		hdstimpacker.injecttype "InjectZerkDummy";
		hdstimpacker.spentinjecttype "SpentZerk";
		hdstimpacker.inventorytype "PortableBerserkPack";
		hdstimpacker.noerror "No berserk packs.";
		weapon.selectionorder 1002;
		hdwoundfixer.injectoricon "PSTRA0";
		hdwoundfixer.injectortype "PortableBerserkPack";
	}
	override string,double getpickupsprite(){return "PSTRA0",1.;}
	override string gethelptext(){return "\cuBerserk Pack\n"..WEPHELP_INJECTOR;}
	states{
	select:
		TNT1 A 0{
			if(!countinv(invoker.inventorytype)){
				if(getcvar("hd_helptext"))A_WeaponMessage(invoker.noerror);
				A_SelectWeapon("HDFist");
			}else if(getcvar("hd_helptext"))A_WeaponMessage("\cr*** \caBERSERK \cr***\c-\n\n\nBerserk packs help increase\ncombat capabilities temporarily.\n\n\Press altfire to use on someone else.");
		}
		goto HDWoundFixer::select;
	}
}
class InjectZerkDummy:InjectStimDummy{
	states{
	spawn:
		TNT1 A 35 nodelay{
			tg=HDPlayerPawn(target);
		}
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAA 1{
			if(!tg||tg.bkilled){destroy();return;}
		}
		TNT1 A 1{
			if(tg.zerk<666){
				if(hdplayerpawn(tg))tg.A_StartSound(hdplayerpawn(tg).xdeathsound,CHAN_VOICE);
				else tg.A_StartSound("*xdeath",CHAN_VOICE);
				HDPlayerPawn.Disarm(self);
				tg.A_SelectWeapon("HDFist");
			}else{
				if(hdplayerpawn(tg))tg.A_StartSound(hdplayerpawn(tg).painsound,CHAN_VOICE);
				else tg.A_StartSound("*pain",CHAN_VOICE);
			}
			tg.A_GiveInventory("PowerStrength");
			tg.zerk+=4100;
			tg.haszerked++;
			if(tg.stimcount)tg.aggravateddamage+=int(ceil(tg.stimcount*0.05*random(1,3)));
			else tg.aggravateddamage++;
		}stop;
	}
}






class BluePotion:hdinjectormaker{
	default{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Healing Potion"
		//$Sprite "BON1A0"

		hdmagammo.mustshowinmagmanager true;
		inventory.pickupmessage "Picked up a health potion.";
		inventory.pickupsound "potion/swish";
		inventory.icon "PBONA0";
		scale 0.3;
		tag "healing potion";
		hdmagammo.maxperunit 12;
		hdmagammo.magbulk ENC_BLUEPOTION*0.7;
		hdmagammo.roundbulk ENC_BLUEPOTION*0.04;
		+inventory.ishealth
		hdinjectormaker.injectortype "HDBlueBottler";
	}
	override string,string,name,double getmagsprite(int thismagamt){
		return "BON1A0","TNT1A0","BluePotion",0.3;
	}
	override int getsbarnum(int flags){return mags.size()?mags[0]:0;}
	override bool Extract(){return false;}
	override bool Insert(){
		if(amount<2)return false;
		int lowindex=mags.size()-1;
		if(
			mags[lowindex]>=maxperunit
			||mags[0]<1
		)return false;
		mags[0]--;
		mags[lowindex]++;
		owner.A_StartSound("potion/swish",8);
		if(mags[0]<1){
			mags.delete(0);
			amount--;
			owner.A_StartSound("potion/open",CHAN_WEAPON);
			actor a=owner.spawn("SpentBottle",owner.pos+(0,0,owner.height-4),ALLOW_REPLACE);
			a.angle=owner.angle+2;a.vel=owner.vel;a.A_ChangeVelocity(3,1,4,CVF_RELATIVE);
			a=owner.spawn("SpentCork",owner.pos+(0,0,owner.height-4),ALLOW_REPLACE);
			a.angle=owner.angle+3;a.vel=owner.vel;a.A_ChangeVelocity(5,3,4,CVF_RELATIVE);
		}
		return true;
	}
	states{
	use:
		TNT1 A 0 A_JumpIf(
			player.cmd.buttons&BT_USE
			&&(
				!findinventory("hdbluebottler")
				||!hdbluebottler(findinventory("hdbluebottler")).bweaponbusy
			)
		,1);
		goto super::use;
	cycle:
		TNT1 A 0{
			invoker.syncamount();
			int firstbak=invoker.mags[0];
			int limamt=invoker.amount-1;
			for(int i=0;i<limamt;i++){
				invoker.mags[i]=invoker.mags[i+1];
			}
			invoker.mags[limamt]=firstbak;
			A_StartSound("potion/swish",CHAN_WEAPON,CHANF_OVERLAP,0.5);
			A_StartSound("weapons/pocket",9,volume:0.3);
		}fail;
	spawn:
		BON1 ABCDCB 2 light("HEALTHPOTION") A_SetTics(random(1,3));
		loop;
	}
}
class HDBlueBottler:HDWoundFixer{
	default{
		weapon.selectionorder 1000;
		hdwoundfixer.injectoricon "BON1A0";
		hdwoundfixer.injectortype "BluePotion";
	}
	override string,double getpickupsprite(){return "BON1A0",1.;}
	override string gethelptext(){return "\cuPotion\n"
		..WEPHELP_FIRE.."  Drink\n"
		..WEPHELP_USE.." + "..WEPHELP_USE.."(item)  Cycle"
		;
	}
	override inventory CreateTossable(int amount){
		owner.A_DropInventory("BluePotion",amount);
		if(!owner.countinv("BluePotion"))destroy();
		return null;
	}
	states{
	spawn:
		TNT1 A 1;
		stop;
	select:
		TNT1 A 0{
			if(!countinv("BluePotion")){
				if(getcvar("hd_helptext"))A_WeaponMessage("No potion.");
				A_SelectWeapon("HDFist");
			}else if(getcvar("hd_helptext"))A_WeaponMessage("\ct\(\(\( \cnPOTION \ct\)\)\)\c-\n\n\nNot made\nby human hands.\n\nBeware.");
			A_StartSound("potion/swish",8,CHANF_OVERLAP);
		}
		goto super::select;
	deselecthold:
		TNT1 A 1;
		TNT1 A 0 A_Refire("deselecthold");
		TNT1 A 0{
			A_SelectWeapon("HDFist");
			A_WeaponReady(WRF_NOFIRE);
		}goto nope;
	fire:
		TNT1 A 0{
			if(!countinv("BluePotion")){
				if(getcvar("hd_helptext"))A_WeaponMessage("No potion.");
				A_Refire("deselecthold");
			}else if(countinv("PortableRadsuit") && countinv("WornRadsuit")){
				if(getcvar("hd_helptext"))A_WeaponMessage("Take off your environment suit first!",2);
				A_Refire("nope");
			}
		}
		TNT1 A 4 A_WeaponReady(WRF_NOFIRE);
		TNT1 A 1{
			A_StartSound("potion/open",CHAN_WEAPON);
			A_Refire();
		}
		TNT1 A 0 A_StartSound("potion/swish",8);
		goto nope;
	hold:
		TNT1 A 1;
		TNT1 A 0{
			A_WeaponBusy();
			if(!countinv("BluePotion")){
				if(getcvar("hd_helptext"))A_WeaponMessage("No potion.");
				A_Refire("deselecthold");
			}else if(countinv("PortableRadsuit") && countinv("WornRadsuit")){
				if(getcvar("hd_helptext"))A_WeaponMessage("Take off your environment suit first!",2);
				A_Refire("nope");
			}else if(pitch>-55){
				A_SetPitch(pitch-8,SPF_INTERPOLATE);
				A_Refire();
			}else{
				A_Refire("inject");
			}
		}
		TNT1 A 0 A_StartSound("potion/away",CHAN_WEAPON,volume:0.4);
		goto nope;
	inject:
		TNT1 A 7{
			let bp=BluePotion(findinventory("BluePotion"));
			if(!bp.mags.size()||bp.mags[0]<1){
				setweaponstate("injectend");
				return;
			}
			bp.mags[0]--;
			A_SetPitch(pitch-2,SPF_INTERPOLATE);
			A_StartSound("potion/chug",CHAN_VOICE);
			let onr=HDPlayerPawn(self);
			if(onr)onr.regenblues+=12;
		}
		TNT1 AAAAA 1 A_SetPitch(pitch+0.5,SPF_INTERPOLATE);
		TNT1 A 5 A_JumpIf(!pressingfire(),"injectend");
		goto hold;
	injectend:
		TNT1 A 6;
		TNT1 A 0{
			let bp=BluePotion(findinventory("BluePotion"));
			if(!bp){setweaponstate("nope");return;}
			if(bp.mags.size()&&bp.mags[0]>0){
				A_StartSound("potion/away",CHAN_WEAPON,volume:0.4);
				setweaponstate("nope");
				return;
			}
			bp.mags.delete(0);
			bp.amount--;
			A_StartSound("potion/open",8);
			actor a=spawn("SpentBottle",pos+(0,0,height-4),ALLOW_REPLACE);
			a.angle=angle+2;a.vel=vel;a.A_ChangeVelocity(3,1,4,CVF_RELATIVE);
			a=spawn("SpentCork",pos+(0,0,height-4),ALLOW_REPLACE);
			a.angle=angle+3;a.vel=vel;a.A_ChangeVelocity(5,3,4,CVF_RELATIVE);
		}
	injectedhold:
		TNT1 A 1 A_ClearRefire();
		TNT1 A 0 A_JumpIf(pressingfire(),"injectedhold");
		TNT1 A 10 A_SelectWeapon("HDFist");
		TNT1 A 1 A_WeaponReady(WRF_NOFIRE);
		goto readyend;
	}
}


