//-------------------------------------------------
// Armour
//-------------------------------------------------
const HDCONST_BATTLEARMOUR=70;
const HDCONST_GARRISONARMOUR=144;

class HDArmour:HDMagAmmo{
	default{
		+inventory.invbar
		+hdpickup.cheatnogive
		+hdpickup.notinpockets
		inventory.amount 1;
		inventory.maxamount 3;
		hdmagammo.maxperunit (HDCONST_BATTLEARMOUR+1000);
		hdmagammo.magbulk ENC_GARRISONARMOUR;
		tag "armour";
		inventory.icon "ARMSB0";
		inventory.pickupmessage "Picked up the security armour.";
	}
	bool mega;
	int cooldown;
	override bool isused(){return true;}
	override int getsbarnum(int flags){
		if(mags.size()<1)return -1000000;
		return mags[0]%1000;
	}
	override string pickupmessage(){
		if(mags[0]>=1000)return "Picked up the battle armour!";
		return super.pickupmessage();
	}
	//because it can intentionally go over the maxperunit amount
	override void AddAMag(int addamt){
		if(addamt<0)addamt=HDCONST_GARRISONARMOUR;
		mags.push(addamt);
		amount=mags.size();
	}
	//keep types the same when maxing
	override void MaxCheat(){
		syncamount();
		for(int i=0;i<amount;i++){
			if(mags[i]>=1000)mags[i]=(HDCONST_BATTLEARMOUR+1000);
			else mags[i]=HDCONST_GARRISONARMOUR;
		}
	}
	action void A_WearArmour(){
		bool helptext=cvar.getcvar("hd_helptext",player).getbool();
		invoker.syncamount();
		int dbl=invoker.mags[0];
		//if holding use, cycle to next armour
		if(player.cmd.buttons&BT_USE){
			invoker.mags.push(dbl);
			invoker.mags.delete(0);
			invoker.syncamount();
			return;
		}

		//strip intervening items on doubleclick
		if(
			invoker.cooldown<1
			&&!HDPlayerPawn.CheckStrip(self,-1,false)
		){
			invoker.cooldown=10;
			return;
		}
		if(!HDPlayerPawn.CheckStrip(self,-1))return;

		//and finally put on the actual armour
		HDArmour.ArmourChangeEffect(self);
		let worn=HDArmourWorn(GiveInventoryType("HDArmourWorn"));
		if(dbl>=1000){
			dbl-=1000;
			worn.mega=true;
		}
		worn.durability=dbl;
		invoker.amount--;
		invoker.mags.delete(0);

		if(helptext){
			string blah=string.format("You put on the %s armour. ",worn.mega?"combat":"security");
			double qual=double(worn.durability)/(worn.mega?HDCONST_BATTLEARMOUR:HDCONST_GARRISONARMOUR);
			if(qual<0.1)A_Log(blah.."Just don't get hit.",true);
			else if(qual<0.3)A_Log(blah.."You cover your shameful nakedness with your filthy rags.",true);
			else if(qual<0.6)A_Log(blah.."It's better than nothing.");
			else if(qual<0.75)A_Log(blah.."This armour has definitely seen better days.",true);
			else if(qual<0.95)A_Log(blah.."This armour does not pass certification.",true);
		}

		invoker.syncamount();
	}
	override void doeffect(){
		if(cooldown>0)cooldown--;
		if(!amount)destroy();
	}
	override void syncamount(){
		if(amount<1){destroy();return;}
		super.syncamount();
		for(int i=0;i<amount;i++){
			if(mags[i]>=1000)mags[i]=max(mags[i],1001);
			else mags[i]=min(mags[i],HDCONST_GARRISONARMOUR);
		}
		checkmega();
	}
	override inventory createtossable(int amount){
		let sct=super.createtossable(amount);
		if(self)checkmega();
		return sct;
	}
	void checkmega(){
		mega=mags.size()&&mags[0]>1000;
		icon=texman.checkfortexture(mega?"ARMCB0":"ARMSB0",TexMan.Type_MiscPatch);
	}
	override void beginplay(){
		cooldown=0;
		mega=icon==texman.checkfortexture("ARMCB0",TexMan.Type_MiscPatch);
		mags.push((mega?(1000+HDCONST_BATTLEARMOUR):HDCONST_GARRISONARMOUR));
		super.beginplay();
	}
	override void consolidate(){}
	override double getbulk(){
		syncamount();
		checkmega();
		double blk=0;
		for(int i=0;i<amount;i++){
			if(mags[i]>=1000)blk+=ENC_BATTLEARMOUR;
			else blk+=ENC_GARRISONARMOUR;
		}
		return blk;
	}
	override void actualpickup(actor other){
		cooldown=0;
		if(!other)return;
		int durability=mags[0];
		HDArmour aaa=HDArmour(other.findinventory("HDArmour"));
		//put on the armour right away
		if(
			other.player&&other.player.cmd.buttons&BT_USE
			&&HDPlayerPawn.CheckStrip(other,-1,false)
		){
			HDArmour.ArmourChangeEffect(other);
			let worn=HDArmourWorn(other.GiveInventoryType("HDArmourWorn"));
			if(durability>=1000){
				durability-=1000;
				worn.mega=true;
			}
			worn.durability=durability;
			destroy();
			return;
		}
		//one megaarmour = 2 regular armour
		if(aaa){
			int totalbulk=(durability>=1000)?2:1;
			for(int i=0;i<aaa.mags.size();i++){
				totalbulk+=(aaa.mags[i]>=1000)?2:1;
			}
			if(totalbulk>aaa.maxamount)return;
		}
		if(!trypickup(other))return;
		aaa=HDArmour(other.findinventory("HDArmour"));
		aaa.syncamount();
		aaa.mags.insert(0,durability);
		aaa.mags.pop();
		aaa.checkmega();
		other.A_StartSound(pickupsound,CHAN_AUTO);
		other.A_Log(string.format("\cg%s",pickupmessage()),true);
	}
	static void ArmourChangeEffect(actor owner){
		owner.A_SetBlend("00 00 00",1,6,"00 00 00");
		owner.A_StartSound("weapons/pocket",CHAN_BODY);
		owner.A_ChangeVelocity(0,0,2);
		let onr=HDPlayerPawn(owner);
		if(onr)onr.stunned+=90;
	}
	states{
	spawn:
		ARMS A -1 nodelay A_JumpIf(invoker.mega,1);
		ARMC A -1;
		stop;
	use:
		TNT1 A 0 A_WearArmour();
		fail;
	}
}
class HDArmourWorn:HDPickup{
	int durability;
	bool mega;property ismega:mega;
	default{
		-inventory.invbar
		-hdpickup.fitsinbackpack
		+hdpickup.notinpockets
		+hdpickup.nevershowinpickupmanager
		HDArmourworn.ismega false;
		inventory.maxamount 1;
		tag "garrison armour";
	}
	override void beginplay(){
		durability=mega?HDCONST_BATTLEARMOUR:HDCONST_GARRISONARMOUR;
		super.beginplay();
		if(mega)settag("battle armour");
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(mega)settag("battle armour");
	}
	override double getbulk(){
		return mega?(ENC_BATTLEARMOUR*0.1):(ENC_GARRISONARMOUR*0.1);
	}
	override inventory CreateTossable(int amount){
		if(!HDPlayerPawn.CheckStrip(owner,STRIP_ARMOUR))return null;

		//armour sometimes crumbles into dust
		if(durability<random(1,3)){
			for(int i=0;i<10;i++){
				actor aaa=spawn("WallChunk",owner.pos+(0,0,owner.height-24),ALLOW_REPLACE);
				vector3 offspos=(frandom(-12,12),frandom(-12,12),frandom(-16,4));
				aaa.setorigin(aaa.pos+offspos,false);
				aaa.vel=owner.vel+offspos*frandom(0.3,0.6);
				aaa.scale*=frandom(0.8,2.);
			}
			destroy();
			return null;
		}

		//finally actually take off the armour
		HDArmour.ArmourChangeEffect(owner);
		let tossed=HDArmour(owner.spawn("HDArmour",
			(owner.pos.x,owner.pos.y,owner.pos.z+owner.height-20),
			ALLOW_REPLACE
		));
		tossed.mags.clear();
		tossed.mags.push(mega?durability+1000:durability);
		tossed.amount=1;
		destroy();
		return tossed;
	}
	states{
	spawn:
		TNT1 A 0;
		stop;
	}
}



class BattleArmour:HDPickupGiver replaces BlueArmor{
	default{
		//$Category "Items/Hideous Destructor"
		//$Title "Battle Armour"
		//$Sprite "ARMCA0"
		+missilemore
		+hdpickup.fitsinbackpack
		inventory.icon "ARMCA0";
		hdpickupgiver.pickuptogive "HDArmour";
		hdpickup.bulk ENC_BATTLEARMOUR;
		hdpickup.refid HDLD_ARMB;
		tag "battle armour (spare)";
		inventory.pickupmessage "Picked up the battle armour.";
	}
	override void configureactualpickup(){
		let aaa=HDArmour(actualitem);
		aaa.mags.clear();
		aaa.mags.push(bmissilemore?(1000+HDCONST_BATTLEARMOUR):HDCONST_GARRISONARMOUR);
		aaa.syncamount();
	}
}
class GarrisonArmour:BattleArmour replaces GreenArmor{
	default{
		//$Category "Items/Hideous Destructor"
		//$Title "Garrison Armour"
		//$Sprite "ARMSA0"
		-missilemore
		inventory.icon "ARMSA0";
		hdpickup.bulk ENC_GARRISONARMOUR;
		hdpickup.refid HDLD_ARMG;
		tag "garrison armour (spare)";
		inventory.pickupmessage "Picked up the garrison armour.";
	}
}


class BattleArmourWorn:HDPickup{
	default{
		+missilemore
		-hdpickup.fitsinbackpack
		hdpickup.refid HDLD_ARWB;
		tag "battle armour";
		inventory.maxamount 1;
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(owner){
			owner.A_GiveInventory("HDArmourWorn");
			let ga=HDArmourWorn(owner.findinventory("HDArmourWorn"));
			ga.durability=(bmissilemore?HDCONST_BATTLEARMOUR:HDCONST_GARRISONARMOUR);
			ga.mega=bmissilemore;
		}
		destroy();
	}
}
class GarrisonArmourWorn:BattleArmourWorn{
	default{
		-missilemore
		-hdpickup.fitsinbackpack
		inventory.icon "ARMCB0";
		hdpickup.refid HDLD_ARWG;
		tag "garrison armour";
	}
}

