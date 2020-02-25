// ------------------------------------------------------------
// 4.26 UAC Standard ammo
// ------------------------------------------------------------
class FourMilAmmo:HDAmmo{
	default{
		+inventory.ignoreskill
		+hdpickup.cheatnogive
		+hdpickup.multipickup
		xscale 0.5; yscale 0.6;
		tag "4.26mm UAC Standard round";
		hdpickup.refid HDLD_FOURMIL;
		hdpickup.bulk ENC_426;
//		inventory.maxamount 300;
		inventory.icon "RCLSA3A7";
	}
	override string pickupmessage(){
		string pms="Picked up a stray 4.26 UAC Standard round.";
		if(amount>1)pms="Picked up a stray block of 4.26 UAC Standard rounds.";
		pms.appendformat("\nNOTE:  %s",HDCONST_426MAGMSG);
		return pms;
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(owner)return;
		if(amount==1)return;
		int amm=min(amount,random(21,50));
		while(amount>amm){
			int ld=min(amount,random(21,50));
			actor a=spawn("FourMilAmmo",pos);
			a.vel+=vel+(frandom(-1,1),frandom(-1,1),frandom(-1,1));
			a.angle=frandom(0,360);
			inventory(a).amount=ld;
			amount-=ld;
		}if(amount<1){
			destroy();
			return;
		}
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("HERPUsable");
		itemsthatusethis.push("ZM66AssaultRifle");
		itemsthatusethis.push("Vulcanette");
		itemsthatusethis.push("LiberatorRifle");
		itemsthatusethis.push("AutoReloader");
	}
	states(actor){
	spawn:
		RCLS A -1 nodelay{
			if(amount>1){
				scale.y*=max(0.333,amount*0.1);
				frame=1;
			}
		}
		stop;
	}
}
class HD4mMag:HDMagAmmo{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "4.26mm UAC Standard Mag"
		//$Sprite "CLIPB0"

		hdmagammo.maxperunit 51;  //NOTE: *only* the guns do the "+100 for dirty mag" thing
		hdmagammo.roundtype "FourMilAmmo";
		hdmagammo.roundbulk ENC_426_LOADED;
		hdmagammo.magbulk ENC_426MAG_EMPTY;

		tag "4.26mm UAC Standard magazine";
		hdpickup.refid HDLD_FOURMAG;
		inventory.pickupmessage "Picked up a 4.26 UAC Standard magazine.";
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("HERPUsable");
		itemsthatusethis.push("HERPDEAD");
		itemsthatusethis.push("ZM66AssaultRifle");
		itemsthatusethis.push("Vulcanette");
	}
	override void postbeginplay(){
		super.postbeginplay();
		sealtimer=0;
		breakchance=0;
	}
	int breakchance;
	int sealtimer;
	override void doeffect(){
		if(sealtimer>0)sealtimer--;
		if(breakchance>0)breakchance--;
		super.doeffect();
	}
	override string pickupmessage(){
		string pms="Picked up a 4.26 UAC Standard magazine.";
		if(mags[0]<51)pms.appendformat(" %s",HDCONST_426MAGMSG);
		return pms;
	}
	override string,string,name,double getmagsprite(int thismagamt){
		string magsprite;
		if(thismagamt>=51)magsprite="ZMAGA0";
		else if(thismagamt>0)magsprite="ZMAGB0";
		else magsprite="ZMAGC0";
		return magsprite,"RBRSBRN","FourMilAmmo",2.;
	}
	override int GetMagHudCount(int input){
		if(input==51)return 50;
		return input;
	}
	bool DirtyMagsOnly(){
		if(mags.size()!=amount)return false;
		for(int i=0;i<amount;i++){
			if(mags[i]>=51)return false;
		}
		return true;
	}
	override bool Extract(){
		SyncAmount();
		int mindex=mags.size()-1;
		if(
			mags.size()<1
			||mags[mindex]<1
			||owner.A_JumpIfInventory(roundtype,0,"null")
		)return false;
		if(mags[mindex]==51){
			if(sealtimer<1){
				owner.A_Log(string.format("%s\nDo you really want to do that?",HDCONST_426MAGMSG),true);
				sealtimer=10;
				extracttime=9;
				return false;
			}else{
				mags[mindex]=50;
				extracttime=12;
				owner.A_StartSound("weapons/rifleclick",CHAN_WEAPON,CHANF_OVERLAP);
				return false;
			}
		}
		int totake=min(random(1,24),mags[mindex]);
		if(totake<HDPickup.MaxGive(owner,"FourMilAmmo",roundbulk))HDF.Give(owner,roundtype,totake);
		else{
			let mmm=FourMilAmmo(owner.spawn("FourMilAmmo",(owner.pos.xy,owner.pos.z+owner.height-12),ALLOW_REPLACE));
			mmm.angle=owner.angle;
			mmm.A_ChangeVelocity(2,0,-1,CVF_RELATIVE);
			mmm.vel+=owner.vel;
			mmm.amount=totake;
		}
		owner.A_StartSound("weapons/rifleclick2",CHAN_WEAPON);
		owner.A_StartSound("weapons/rockreload",CHAN_WEAPON,CHANF_OVERLAP,0.4);
		mags[mindex]-=totake;
		return true;
	}
	override bool Insert(){
		SyncAmount();
		if(
			mags[mags.size()-1]>=50
			||!owner.countinv(roundtype)
		)return false;
		owner.A_TakeInventory(roundtype,1,TIF_NOTAKEINFINITE);
		owner.A_StartSound("weapons/rifleclick2",8);
		if(random(0,80)<=breakchance){
			owner.A_StartSound("weapons/bigcrack",8,CHANF_OVERLAP);
			owner.A_SpawnItemEx("HDSmokeChunk",12,0,owner.height-12,4,frandom(-2,2),frandom(2,4));
			owner.damagemobj(self,owner,1,"Thermal",DMG_NO_ARMOR);
			breakchance=min(breakchance+25,80);
			return false;
		}
		breakchance=max(breakchance,24);
		owner.A_StartSound("weapons/pocket",9,volume:frandom(0.1,0.6));
		mags[mags.size()-1]++;
		return true;
	}
	override void Consolidate(){
		SyncAmount();
		if(amount<2)return;
		int totalrounds=0;
		for(int i=0;i<amount;i++){
			if(mags[i]==51)continue;
			totalrounds+=mags[i]%50;
			mags[i]=0; //keep the empties, do NOT call clear()!
		}
		for(int i=0;i<amount;i++){
			if(mags[i]==51)continue;
			int toinsert=int(min(50,totalrounds)*frandom(0.9,1.));
			mags[i]=toinsert;
			totalrounds-=toinsert;
			if(totalrounds<1)break;
		}
	}
	states(actor){
	spawn:
		ZMAG AB -1 nodelay{
			int mmm=mags[0];
			if(mmm>51)mags[0]=mmm%50;
			if(mmm<51)frame=1;
		}stop;
	spawnempty:
		ZMAG C -1{
			brollsprite=true;brollcenter=true;
			roll=randompick(0,0,0,0,2,2,2,2,1,3)*90;
		}stop;
	}
}



class ZM66DroppedRound:HDDebris{
	default{
		projectile;
		+cannotpush +forcexybillboard -nogravity +doombounce +bounceonactors
		xscale 0.5; yscale 0.6; height 2; radius 2;
		damagefunction(0);bouncefactor 0.2;seesound "misc/casing3";
	}
	states{
	spawn:
		RCLS A 2 A_SetAngle(angle+45);
		wait;
	death:
		---- A -1{
			inventory bl=inventory(spawn("FourMilAmmo",pos));
			bl.amount=1;bl.angle=angle;
			destroy();
		}
	}
}
class HD4mmMagEmpty:IdleDummy{
	override void postbeginplay(){
		super.postbeginplay();
		HDMagAmmo.SpawnMag(self,"HD4mMag",0);
		destroy();
	}
}
class HDDirtyMagazine:IdleDummy{
	override void postbeginplay(){
		super.postbeginplay();
		HDMagAmmo.SpawnMag(self,"HD4mMag",random(1,50));
		destroy();
	}
}

