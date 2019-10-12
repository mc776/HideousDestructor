// ------------------------------------------------------------
// 9mm Ammo
// ------------------------------------------------------------
class HDPistolAmmo:HDRoundAmmo{
	default{
		+inventory.ignoreskill
		+cannotpush
		+forcexybillboard
		+rollsprite +rollcenter
		+hdpickup.multipickup
		xscale 0.7;
		yscale 0.6;
		inventory.pickupmessage "Picked up a 9mm round.";
		hdpickup.refid HDLD_NINEMIL;
		tag "9mm Round";
		hdpickup.bulk ENC_9;
		inventory.icon "TEN9A0";
	}
	override void SplitPickup(){
		SplitPickupBoxableRound(10,100,"HD9mBoxPickup","TEN9A0");
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("DERPUsable");
		itemsthatusethis.push("DERPDEAD");
		itemsthatusethis.push("HDPistol");
		itemsthatusethis.push("HDRevolver");
		itemsthatusethis.push("HDSMG");
	}
	states{
	spawn:
		PRND A -1;
		TEN9 A -1;
	}
}

class HD9mMag15:HDMagAmmo{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Pistol Magazine"
		//$Sprite "CLP2A0"

		hdmagammo.maxperunit 15;
		hdmagammo.roundtype "HDPistolAmmo";
		hdmagammo.roundbulk ENC_9_LOADED;
		hdmagammo.magbulk ENC_9MAG_EMPTY;
		tag "9mm Pistol Magazine";
		inventory.pickupmessage "Picked up a pistol magazine.";
		hdpickup.refid HDLD_NIMAG15;
	}
	override string,string,name,double getmagsprite(int thismagamt){
		string magsprite=(thismagamt>0)?"CLP2NORM":"CLP2EMPTY";
		return magsprite,"PBRSA0","HDPistolAmmo",0.6;
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("DERPUsable");
		itemsthatusethis.push("DERPDEAD");
		itemsthatusethis.push("HDPistol");
	}
	states{
	spawn:
		CLP2 A -1;
		stop;
	spawnempty:
		CLP2 B -1{
			brollsprite=true;brollcenter=true;
			roll=randompick(0,0,0,0,2,2,2,2,1,3)*90;
		}stop;
	}
}
class HD9mMag30:HD9mMag15{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "SMG Magazine"
		//$Sprite "CLP3A0"

		hdmagammo.maxperunit 30;
		hdmagammo.magbulk ENC_9MAG30_EMPTY;
		tag "9mm SMG Magazine";
		inventory.pickupmessage "Picked up an SMG magazine.";
		hdpickup.refid HDLD_NIMAG30;
	}
	override string,string,name,double getmagsprite(int thismagamt){
		string magsprite=(thismagamt>0)?"CLP3A0":"CLP3B0";
		return magsprite,"PBRSA0","HDPistolAmmo",2.;
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("HDSMG");
	}
	states{
	spawn:
		CLP3 A -1;
		stop;
	spawnempty:
		CLP3 B -1{
			brollsprite=true;brollcenter=true;
			roll=randompick(0,0,0,0,2,2,2,2,1,3)*90;
		}stop;
	}
}


class HDSpent9mm:HDDebris{
	override void postbeginplay(){
		super.postbeginplay();
		//should we just put this in the weapon itself? but right now they're all the same...
		A_ChangeVelocity(frandom(-1,1),frandom(-8,-9),frandom(-1,1),CVF_RELATIVE);
	}
	default{
		bouncesound "misc/casing3";scale 0.6;
	}
	states{
	spawn:
		PBRS A 2 nodelay{
			A_SetRoll(roll+45,SPF_INTERPOLATE);
		}loop;
	death:
		PBRS # -1;
	}
}
class HDLoose9mm:HDSpent9mm{
	override void postbeginplay(){
		HDDebris.postbeginplay();
	}
	default{
		bouncefactor 0.5;
	}
	states{
	death:
		TNT1 A 1{
			actor a=spawn("HDPistolAmmo",self.pos,ALLOW_REPLACE);
			a.roll=self.roll;a.vel=self.vel;
		}stop;
	}
}

class HDPistolEmptyMag:IdleDummy{
	override void postbeginplay(){
		super.postbeginplay();
		HDMagAmmo.SpawnMag(self,"HD9mMag15",0);
		destroy();
	}
}
class HDSMGEmptyMag:IdleDummy{
	override void postbeginplay(){
		super.postbeginplay();
		HDMagAmmo.SpawnMag(self,"HD9mMag30",0);
		destroy();
	}
}


class HD9mBoxPickup:HDUPK{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Box of 9mm"
		//$Sprite "9BOXA0"

		scale 0.4;
		hdupk.amount 100;
		hdupk.pickupsound "weapons/pocket";
		hdupk.pickupmessage "Picked up some 9mm ammo.";
		hdupk.pickuptype "HDPistolAmmo";
	}
	states{
	spawn:
		9BOX A -1;
	}
}

