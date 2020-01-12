// ------------------------------------------------------------
// Loadout-related stuff!
// ------------------------------------------------------------
extend class HDPlayerPawn{
	//basic stuff every player should have
	virtual void GiveBasics(){
		if(!player)return;
		A_GiveInventory("HDFist");
		A_GiveInventory("SelfBandage");
		A_GiveInventory("HDFragGrenades");
		A_GiveInventory("MagManager");
	}
}

//loadout common to all soldier classes
class SoldierExtras:HDPickup{
	default{
		-hdpickup.fitsinbackpack
		hdpickup.refid HDLD_SOLDIER;
		tag "elite soldier kit";
	}
	states{
	pickup:
		TNT1 A 0{
			A_SetInventory("PortableMedikit",max(1,countinv("PortableMedikit")));
			A_SetInventory("PortableStimpack",max(2,countinv("PortableStimpack")));
			A_SetInventory("GarrisonArmourWorn",1);

			A_SetInventory("HDPistol",max(countinv("HDPistol"),1));
			A_SetInventory("HD9mMag15",max(3,countinv("HD9mMag15")));

			A_SetInventory("HDFragGrenadeAmmo",max(3,countinv("HDFragGrenadeAmmo")));
			A_SetInventory("DERPUsable",max(1,countinv("DERPUsable")));
			A_SetInventory("PortableLadder",max(1,countinv("PortableLadder")));
		}fail;
	}
}



//reset inventory
class InvReset:Inventory{
	void ReallyClearInventory(actor resetee,bool keepkeys=false){
		for(inventory item=resetee.inv;item!=null;item=!item?null:item.inv){
			if(
				(!keepkeys||!(item is "Key"))
			){
				item.destroy();
				item=resetee.inv;
			}
		}
		resetee.ClearInventory();
	}
	void GiveStartItems(actor resetee){
		//now get all the "dropitems" (i.e. player's startitems) and give them
		let drop=getdefaultbytype(resetee.getclass()).getdropitems();
		if(drop){
			for(dropitem di=drop;di;di=di.Next){
				if(di.Name=='None')continue;
				resetee.A_GiveInventory(di.Name,di.Amount);
			}
		}
		let d=HDPlayerPawn(resetee);
		if(d)d.GiveCustomItems(d.classloadout);
	}
	override void attachtoowner(actor other){
		reallyclearinventory(other);
		givestartitems(other);
		destroy();
	}
}
class DoomguyLoadout:InvReset{
	override void attachtoowner(actor other){
		reallyclearinventory(other,true);
		let d=HDPlayerPawn(other);
		if(d)d.GiveBasics();
		other.A_GiveInventory("HDPistol");
		other.A_GiveInventory("HD9mMag15",2);
		other.A_GiveInventory("HDPistolAmmo",4);
		HDWeaponSelector.Select(other,"HDPistol",1);
		destroy();
	}
}
//wait a moment and then select a weapon
//used to override default to fist on weapon removal
class HDWeaponSelector:Thinker{
	actor other;
	class<Weapon> weptype;
	static void Select(actor caller,class<Weapon> weptype,int waittime=10){
		let thth=new("HDWeaponSelector");
		thth.weptype=weptype;
		thth.other=caller;
		thth.ticker=waittime;
	}
	int ticker;
	override void Tick(){
		ticker--;
		if(ticker>0)return;
		if(other)other.A_SelectWeapon(weptype);
		destroy();
	}
}




//these need to be defined ONLY where an item
//needs to be selectable through custom loadouts.
//all in one place for ease of checking for conflicts.

const HDLD_SOLDIER="sol";

const HDLD_NINEMIL="9mm";
const HDLD_NIMAG15="915";
const HDLD_NIMAG30="930";

const HDLD_355="355";

const HDLD_SEVNMIL="7mm";
const HDLD_SEVNMAG="730";
const HDLD_SEVCLIP="710";
//const HDLD_SEVNBUL="7bl";
const HDLD_SEVNBRA="7br";
const HDLD_776RL=  "7rl";

const HDLD_FOURMIL="4mm";
const HDLD_FOURMAG="450";

const HDLD_BATTERY="bat";
const HDLD_SHOTSHL="shl";
const HDLD_ROCKETS="rkt";
const HDLD_HEATRKT="rkh";
const HDLD_BROBOLT="brb";
const HDLD_GREFRAG="frg";

const HDLD_STIMPAK="stm";
const HDLD_MEDIKIT="med";
const HDLD_FINJCTR="2fl";
const HDLD_BERSERK="zrk";
const HDLD_BLODPAK="bld";
const HDLD_RADSUIT="rad";
const HDLD_LITEAMP="lit";
const HDLD_LADDER= "lad";
const HDLD_DOORBUS="dbs";
const HDLD_IEDKIT= "ied";
const HDLD_JETPACK="jet";
const HDLD_BACKPAK="bak";

const HDLD_KEY=    "key";
const HDLD_MAP=    "map";

const HDLD_DERPBOT="drp";
const HDLD_HERPBOT="hrp";

//const HDLD_ARMGINV="arm";
const HDLD_ARMG="arg";
const HDLD_ARMB="arb";
const HDLD_ARWG="awg";
const HDLD_ARWB="awb";

const HDLD_FIST=    "fis";
const HDLD_CHAINSW= "saw";
const HDLD_REVOLVER="rev";
const HDLD_PISTOL= "pis"; 
const HDLD_PISTAUT="pia";
const HDLD_SMG    ="smg";
const HDLD_HUNTER= "hun";
const HDLD_SLAYER= "sla";
const HDLD_ZM66GL= "z66";
const HDLD_ZM66AUT="z6a";
const HDLD_ZM66SMI="z6s";
const HDLD_ZM66SGL="z6g";
const HDLD_VULCETT="vul";
const HDLD_LAUNCHR="lau";
const HDLD_BLOOPER="blo";
const HDLD_THUNDER="thu";
const HDLD_LIBGL=  "lib";
const HDLD_LIBNOGL="lia";
const HDLD_LIBNOBP="lnb";
const HDLD_LIBNOBPNOGL="lna";
const HDLD_BFG=    "bfg";
const HDLD_BRONTO= "bro";
const HDLD_BOSS=   "bos";

//hacky shit: used to set player cvar in the status bar
class LoadoutMenuHackToken:InventoryFlag{
	override void tick(){
		super.tick();
		stamina++;
		if(stamina>1)destroy();
	}
}


//used for loadout configurations and custom spawns
class HDPickupGiver:HDPickup{
	class<hdpickup> pickuptogive;
	property pickuptogive:pickuptogive;
	hdpickup actualitem;
	virtual void configureactualpickup(){}
	override void postbeginplay(){
		super.postbeginplay();
		spawnactualitem();
	}
	void spawnactualitem(){
		//check if the owner already has this pickup
		if(owner)actualitem=hdpickup(owner.findinventory(pickuptogive));

		//spawn or give the pickup
		if(actualitem){
			//if actor present, just give more
			owner.A_GiveInventory(pickuptogive);
		}else{
			actualitem=hdpickup(spawn(pickuptogive,pos));
			actualitem.special=special;
			actualitem.changetid(tid);
			if(owner)actualitem.attachtoowner(owner);
		}

		//now apply the changes this pickupgiver is for
		configureactualpickup();
		destroy();
	}
	//this stuff must be done after the first tick,
	//as the loadout configurator needs time to read the actualpickup
	override void tick(){
		super.tick();
		destroy();
	}
}
class HDWeaponGiver:HDWeapon{
	class<hdweapon> weapontogive;
	property weapontogive:weapontogive;
	string weprefid;
	property weprefid:weprefid;
	string config;
	property config:config;
	double bulk;property bulk:bulk;
	hdweapon actualweapon;
	default{
		+nointeraction
		-inventory.invbar
		inventory.maxamount 1;
		hdweapongiver.config "";
		hdweapongiver.weprefid "";
	}
	override void postbeginplay(){
		super.postbeginplay();
		spawnactualweapon();
	}
	virtual void spawnactualweapon(){
		//check blacklist for the target weapon
		if(hdpickup.checkblacklist(self,weprefid))return;

		//check if the owner already has this weapon
		bool hasprevious=(
			owner
			&&owner.findinventory(weapontogive)
		);

		//spawn the weapon
		actualweapon=hdweapon(spawn(weapontogive,pos));
		actualweapon.special=special;
		actualweapon.changetid(tid);
		if(owner){
			actualweapon.attachtoowner(owner);

			//apply defaults from owner
			actualweapon.defaultconfigure(player);
		}

		//apply config applicable to this weapongiver
		actualweapon.loadoutconfigure(config);

		//if there was a previous weapon, bring this one down to the spares
		if(hasprevious&&owner.getage()>5){
			actualweapon.AddSpareWeaponRegular(owner);
		}
	}
	//this stuff must be done after the first tick,
	//as the loadout configurator needs time to read the actualweapon
	override void tick(){
		super.tick();
		if(
			owner
			&&owner.player
			&&owner.player.readyweapon==self
			&&actualweapon is "HDWeapon"
		){
			let wp=actualweapon.getclassname();
			owner.A_SelectWeapon(wp);
		}
		destroy();
	}
}


class CustomLoadoutGiver:Inventory{
	//must be DoEffect as AttachToOwner and Pickup are not called during a range reset!
	override void doeffect(){
		let hdp=HDPlayerPawn(owner);
		if(hdp)hdp.GiveCustomItems(hdp.classloadout);
		destroy();
	}
}
extend class HDPlayerPawn{
	string startingloadout;property startingloadout:startingloadout;
	void GiveCustomItems(string loadinput){
		if(!player)return;
		if(HDPlayerPawn(self))HDPlayerPawn(self).GiveBasics();

		string weapondefaults=hdweapon.getdefaultcvar(player);

		//special conditions that completely overwrite the loadout giving
		if(
			hd_forceloadout!=""
			&&hd_forceloadout!="0"
			&&hd_forceloadout!="false"
			&&hd_forceloadout!="none"
		){
			loadinput=hd_forceloadout;
			A_Log("Loadout settings forced by administrator:  "..hd_forceloadout,true);
		}
		if(loadinput.left(3)~=="hd_"){
			loadinput=cvar.getcvar(loadinput,player).getstring();
		}
		string loadoutname;
		[loadinput,loadoutname]=HDMath.GetLoadoutStrings(loadinput);
		if(loadoutname!="")A_Log("Starting Loadout: "..loadoutname,true);
		if(loadinput=="")return;
		if(loadinput~=="doomguy")loadinput="pis,9152,9mm4";
		if(loadinput~=="insurgent"){
			A_GiveInventory("InsurgentLoadout");
			return;
		}

		string blacklist=hd_blacklist;
		if(blacklist!=""){
			blacklist=blacklist.makelower();
			blacklist.replace(" ","");
			array<string>blist;blist.clear();
			A_Log("Some items in your loadout may have been blacklisted from this game and removed or substituted at start: "..blacklist,true);
			blacklist.split(blist,",");
			for(int i=0;i<blist.size();i++){
				string blisti=blist[i];
				if(blisti.length()>=3){
					if(blisti.indexof("=")>0){
						string replacement=blisti.mid(blisti.indexof("=")+1);
						loadinput.replace(blisti.left(3),replacement);
					}else loadinput.replace(blisti.left(3),"fis");
				}
			}
		}


		array<string> whichitem;whichitem.clear();
		array<int> whichitemclass;whichitemclass.clear();
		array<string> howmany;howmany.clear();
		array<string> loadlist;loadlist.clear();

		string firstwep="";


		loadinput.split(loadlist,"-");
		loadlist[0].split(whichitem,",");
		if(hd_debug)A_Log("Loadout: "..loadlist[0]);
		for(int i=0;i<whichitem.size();i++){
			whichitemclass.push(-1);
			howmany.push(whichitem[i].mid(3,whichitem[i].length()));
			whichitem[i]=whichitem[i].left(3);
		}
		for(int i=0;i<allactorclasses.size();i++){
			class<actor> reff=allactorclasses[i];
			if(reff is "HDPickup"||reff is "HDWeapon"){
				string ref;
				if(reff is "HDPickup")ref=getdefaultbytype((class<hdpickup>)(reff)).refid;
				else ref=getdefaultbytype((class<hdweapon>)(reff)).refid;
				if(ref=="")continue;
				for(int j=0;j<whichitem.size();j++){
					if(
						whichitemclass[j]<0
						&&whichitem[j]~==ref
					)whichitemclass[j]=i;
				}
			}
		}
		hdweapon firstwepactor;
		for(int i=whichitemclass.size()-1;i>=0;i--){
			if(whichitemclass[i]<0){
				A_Log("\ca*** Unknown loadout code:  \"\cx"..whichitem[i].."\ca\"",true);
				continue;
			}
			class<actor> reff=allactorclasses[whichitemclass[i]];
			if(reff is "HDWeapon"){
				if(
					getdefaultbytype((class<HDWeapon>)(reff)).bdebugonly
					&&hd_debug<=0
				){
					A_Log("\caLoadout code \"\cx"..whichitem[i].."\ca\" ("..getdefaultbytype(reff).gettag()..") can only be used in debug mode.",true);
					continue;
				}
				if(!i){
					if(reff is "HDWeaponGiver"){
						let greff=getdefaultbytype((class<HDWeaponGiver>)(reff)).weapontogive;
						if(greff)firstwep=greff.getclassname();
					}else{
						firstwep=reff.getclassname();
					}
				}

				int thismany;
				if(getdefaultbytype((class<hdweapon>)(reff)).bignoreloadoutamount)thismany=1;
				else thismany=clamp(howmany[i].toint(),1,40);

				while(thismany>0){
					thismany--;
					hdweapon newwep;
					if(reff is "HDWeaponGiver"){
						let newgiver=hdweapongiver(spawn(reff,pos));
						newgiver.spawnactualweapon();
						newwep=newgiver.actualweapon;
						newgiver.destroy();
						if(newwep&&hdpickup.checkblacklist(newwep,newwep.refid,true))return;
					}else{
						newwep=hdweapon(spawn(reff,pos));
					}
					if(newwep){
						//clear any randomized garbage
						newwep.weaponstatus[0]=0;
						//apply the default based on user cvar first
						newwep.defaultconfigure(player);
						//now apply the loadout input to overwrite the defaults
						string wepinput=howmany[i];
						wepinput.replace(" ","");
						wepinput=wepinput.makelower();
						newwep.loadoutconfigure(wepinput);
						//the only way I know to force the weapongiver to go last: make it go again
						if(reff is "HDWeaponGiver"){
							let hdwgreff=(class<hdweapongiver>)(reff);
							let gdhdwgreff=getdefaultbytype(hdwgreff);
							newwep.loadoutconfigure(gdhdwgreff.config);
						}
						newwep.actualpickup(self,true);
					}
				}
			}else{
				A_GiveInventory(
					reff.getclassname(),
					clamp(howmany[i].toint(),1,int.MAX)
				);
				let iii=hdpickup(findinventory(reff.getclassname()));
				if(iii){
					iii.amount=min(iii.amount,iii.maxamount);
					if(hdmagammo(iii))hdmagammo(iii).syncamount();
				}
			}
		}

		//attend to backpack and contents
		if(loadinput.indexof("-")>=0){
			A_Log("Warning: deprecated loadout code for backpack. This may not be supported in future versions of Hideous Destructor.",true);
			if(hd_debug)A_Log("Backpack Loadout: "..loadlist[1]);
			A_GiveInventory("HDBackpack");
			hdbackpack(findinventory("HDBackpack")).initializeamount(loadlist[1]);
		}

		//select the correct weapon
		HDWeaponSelector.Select(self,firstwep);
	}
}


class LoadoutCode:custominventory{
	default{
		inventory.maxamount 999;
	}
	states{
	pickup:
		TNT1 A 0{
			string lll="";
			bool first=true;
			for(inventory hdppp=inv;hdppp!=null;hdppp=hdppp.inv){
				let hdw=hdweapon(hdppp);
				let hdp=hdpickup(hdppp);
				string refid=(hdw?hdw.refid:hdp?hdp.refid:"");
				if(refid=="")continue;
				if(first){
					lll=refid.." "..hdppp.amount;
					first=false;
				}else if(hdw&&hdw==player.readyweapon){
					//readyweapon gets first position
					lll=hdw.refid.." 1, "..lll;
				}else{
					//append all items to end
					lll=lll..", "..refid.." "..hdppp.amount;
				}
			}

			int havekey=0;
			if(countinv("BlueCard"))havekey|=1;
			if(countinv("YellowCard"))havekey|=2;
			if(countinv("RedCard"))havekey|=4;
			if(havekey)lll=lll..", key "..havekey;

			let bp=HDBackpack(findinventory("HDBackpack"));
			if(bp){
				int imax=bp.invclasses.size();
				bool first=true;
				if(bp.bulk>0){
					lll=lll.." - ";
					for(int i=0;i<imax;i++){
						if(bp.havenone(i))continue;
						let wep=(class<hdweapon>)(bp.invclasses[i]);
						let mag=(class<hdmagammo>)(bp.invclasses[i]);
						let pkup=(class<hdpickup>)(bp.invclasses[i]);
						int amt;
						if(wep||mag){
							array<string> amts;amts.clear();
							bp.amounts[i].split(amts," ");
							if(wep)amt=amts.size()/8;
							else amt=amts.size();
						}else{
							amt=bp.amounts[i].toint(10);
						}
						if(first)first=false;else lll=lll..", "; 
						lll=lll..bp.refids[i].." "..amt;
					}
				}
			}

			string outstring="The loadout code for your current gear is:\n"..(lll==""?"nothing, you're naked.":"\cy"..lll);
			A_Log(outstring,true);
			if(invoker.amount>900){
				string warning="\cxYour \cyhd_loadout1\cx has been automatically updated.";
				A_Log(warning,true);
				let lodstor=giveinventorytype("loadoutmenuhacktoken");
				lodstor.species=lll;
			}
		}fail;
	}
}


class LoadoutItemList:CustomInventory{
	states{
	pickup:
		TNT1 A 0{
			string blah="All loadout codes for all items including loaded mods:";
			for(int i=0;i<allactorclasses.size();i++){
				class<actor> reff=allactorclasses[i];
				string ref="";
				string nnm="";
				if(reff is "HDPickup"){
					let gdb=getdefaultbytype((class<hdpickup>)(reff));
					nnm=gdb.gettag();if(nnm=="")nnm=gdb.getclassname();
					ref=gdb.refid;
				}else if(reff is "HDWeapon"){
					let gdb=getdefaultbytype((class<hdweapon>)(reff));
					nnm=gdb.gettag();if(nnm=="")nnm=gdb.getclassname();
					ref=gdb.refid;
				}
				if(ref!=""){
					blah=blah.."\n"..ref.."   "..nnm;
				}
			}
			A_Log(blah,true);
		}fail;
	}
}






class InsurgentLoadout:Inventory{
	override void Tick(){
		if(!owner){destroy();return;}
		//pick one or two random weapons
		class<inventory> ammoforwep=null;
		for(int i=0;i<randompick(1,1,1,1,1,1,1,1,1,2,2,2,3);i++){
			string thiswep="";
			switch(4+random(0,13)){
			case 0:
				thiswep="HDPistol";
				owner.A_GiveInventory(thiswep);
				owner.A_SelectWeapon(thiswep);
				ammoforwep="HD9mMag15";
				break;
			case 1:
				thiswep="ZM66Semi";
				owner.A_GiveInventory(thiswep);
				owner.A_SelectWeapon(thiswep);
				ammoforwep="HD4mMag";
				break;
			case 2:
				thiswep="Hunter";
				owner.A_GiveInventory(thiswep);
				owner.A_SelectWeapon(thiswep);
				ammoforwep="HDShellAmmo";
				break;
			case 3:
				thiswep="Slayer";
				owner.A_GiveInventory(thiswep);
				owner.A_SelectWeapon(thiswep);
				ammoforwep="HDShellAmmo";
				break;
			case 4:
				thiswep="Lumberjack";
				owner.A_GiveInventory(thiswep);
				owner.A_SelectWeapon(thiswep);
				ammoforwep="HDBattery";
				break;
			case 5:
				owner.A_GiveInventory("LiberatorNoGL");
				HDWeaponSelector.Select(owner,"LiberatorRifle");
				ammoforwep="HD7mMag";
				break;
			case 6:
				owner.A_GiveInventory("ZM66Regular");
				HDWeaponSelector.Select(owner,"ZM66AssaultRifle");
				ammoforwep="HD4mMag";
				break;
			case 7:
				thiswep="HDSMG";
				owner.A_GiveInventory(thiswep);
				owner.A_SelectWeapon(thiswep);
				ammoforwep="HD9mMag30";
				break;
			case 8:
				thiswep="BossRifle";
				owner.A_GiveInventory(thiswep);
				owner.A_SelectWeapon(thiswep);
				ammoforwep="HD7mClip";
				break;
			case 9:
				owner.A_GiveInventory("HDAutoPistol");
				HDWeaponSelector.Select(owner,"HDPistol");
				ammoforwep="HD9mMag15";
				break;
			case 10:
				thiswep="ZM66AssaultRifle";
				owner.A_GiveInventory(thiswep);
				owner.A_SelectWeapon(thiswep);
				ammoforwep="HD4mMag";
				owner.A_SetInventory("HDRocketAmmo",max(owner.countinv("HDRocketAmmo"),random(0,4)));
				break;
			case 11:
				thiswep="LiberatorRifle";
				owner.A_GiveInventory(thiswep);
				owner.A_SelectWeapon(thiswep);
				ammoforwep="HD7mMag";
				owner.A_SetInventory("HDRocketAmmo",max(owner.countinv("HDRocketAmmo"),random(0,4)));
				break;
			case 12:
				thiswep="Vulcanette";
				owner.A_GiveInventory(thiswep);
				owner.A_SelectWeapon(thiswep);
				ammoforwep="HD4mMag";
				owner.A_SetInventory("HDBattery",max(owner.countinv("HDBattery"),random(0,1)));
				break;
			case 13:
				thiswep="Blooper";
				owner.A_GiveInventory(thiswep);
				owner.A_SelectWeapon(thiswep);
				ammoforwep="HDRocketAmmo";
				break;
			case 14:
				thiswep="HDRL";
				owner.A_GiveInventory(thiswep);
				owner.A_SelectWeapon(thiswep);
				ammoforwep="HDRocketAmmo";
				break;
			case 15:
				thiswep="ThunderBuster";
				owner.A_GiveInventory(thiswep);
				owner.A_SelectWeapon(thiswep);
				ammoforwep="HDBattery";
				break;
			case 16:
				thiswep="Brontornis";
				owner.A_GiveInventory(thiswep);
				owner.A_SelectWeapon(thiswep);
				ammoforwep="BrontornisRound";
				break;
			case 17:
				thiswep="BFG9k";
				owner.A_GiveInventory(thiswep);
				owner.A_SelectWeapon(thiswep);
				ammoforwep="HDBattery";
				break;
			default:
				break;
			}
			//give some random ammo for the new weapon
			if(ammoforwep){
				let thisinv=hdpickup(owner.giveinventorytype(ammoforwep));

				let thismag=hdmagammo(thisinv);
				if(thismag)thismag.syncamount();

				int thismax=max(1,HDPickup.MaxGive(owner,thisinv.getclass(),
					thismag?thismag.getbulk():thisinv.bulk
				));

				thisinv.amount=random(1,max(1,thismax>>2));
				if(thismag)thismag.syncamount();
			}
		}
		//give random other gear
		array<string> supplies;supplies.clear();
		for(int i=0;i<allactorclasses.size();i++){
			let thisclass=((class<hdpickup>)(allactorclasses[i]));
			if(thisclass && getdefaultbytype(thisclass).refid!=""){
				supplies.push(thisclass.getclassname());
				continue;
			}
			let thiswclass=((class<hdweapon>)(allactorclasses[i]));
			if(
				thiswclass
				&&getdefaultbytype(thiswclass).binvbar
				&&getdefaultbytype(thiswclass).refid!=""
			){
				supplies.push(thiswclass.getclassname());
				continue;
			}
		}
		int imax=random(3,6);
		int smax=supplies.size()-1;
		for(int i=0;i<imax;i++){
			let thisclass=supplies[random(0,smax)];
			let thisitem=HDPickup(owner.GiveInventoryType(thisclass));
			int thismax=1;
			if(thisitem){
				if(hd_debug)A_Log("insurgent input: "..thisclass);
				let thismag=hdmagammo(thisitem);
				if(thismag)thismag.syncamount();

				thismax=max(1,HDPickup.MaxGive(owner,thisitem.getclass(),
					thismag?thismag.getbulk():thisitem.bulk
				));

				thisitem.amount=random(1,max(1,thismax>>2));
				if(thismag)thismag.syncamount();
				if(hd_debug)A_Log(thisitem.getclassname().."  "..thisitem.amount);
			}else{
				let thiswitem=HDWeapon(owner.GiveInventoryType(thisclass));
				if(thiswitem){
					if(hd_debug)A_Log("insurgent input: "..thisclass);

					let wb=thiswitem.weaponbulk();
					if(wb)thismax=int(max(1,HDCONST_MAXPOCKETSPACE/wb));
					else thismax=thiswitem.maxamount>>3;

					thiswitem.amount=random(1,max(1,thismax>>2));
					if(hd_debug)A_Log(thiswitem.getclassname().."  "..thiswitem.amount);
				}
			}
		}
		//randomize integrity of armour
		let armourstored=HDArmour(owner.findinventory("HDArmour"));
		if(armourstored){
			armourstored.syncamount();
			bool nomega=armourstored.amount>2;
			for(int i=0;i<armourstored.amount;i++){
				if(
					!nomega
					&&!random(0,12)
				){
					armourstored.mags[i]=random(1001,1000+HDCONST_BATTLEARMOUR);
				}else{
					armourstored.mags[i]=random(1,HDCONST_GARRISONARMOUR);
				}
			}
		}
		let armourworn=HDArmourWorn(owner.findinventory("HDArmourWorn"));
		if(armourworn){
			armourworn.mega=!random(0,12);
			armourworn.durability=random(1,
				armourworn.mega?HDCONST_BATTLEARMOUR:HDCONST_GARRISONARMOUR
			);
		}

		let bp=hdbackpack(owner.findinventory("HDBackpack"));
		if(bp&&!random(0,31))bp.randomcontents();

		destroy();
	}
}




