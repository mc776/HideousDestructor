// ------------------------------------------------------------
// 7.76mm Ammo
// ------------------------------------------------------------
class SevenMilAmmo:HDRoundAmmo{
	default{
		+forcexybillboard +cannotpush
		+inventory.ignoreskill
		+hdpickup.multipickup
		xscale 0.7;yscale 0.8;
		inventory.pickupmessage "Picked up a 7.76mm round.";
		hdpickup.refid HDLD_SEVNMIL;
		tag "7.76mm round";
		hdpickup.bulk ENC_776;
		inventory.icon "TEN7A0";
	}
	override void SplitPickup(){
		SplitPickupBoxableRound(10,50,"HD7mBoxPickup","TEN7A0","RBRSA0");
		if(amount==10)scale.y=(0.8*0.83);
		else scale.y=0.8;
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("LiberatorRifle");
		itemsthatusethis.push("BossRifle");
		itemsthatusethis.push("AutoReloader");
	}
	states{
	spawn:
		RBRS A -1;
		TEN7 A -1;
	}
}
class HD7mMag:HDMagAmmo{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Liberator Magazine"
		//$Sprite "RMAGA0"

		hdmagammo.maxperunit 30;
		hdmagammo.roundtype "SevenMilAmmo";
		hdmagammo.roundbulk ENC_776_LOADED;
		hdmagammo.magbulk ENC_776MAG_EMPTY;
		hdpickup.refid HDLD_SEVNMAG;
		tag "7.76mm magazine";
		inventory.pickupmessage "Picked up a 7.76mm magazine.";
		scale 0.8;
	}
	override string,string,name,double getmagsprite(int thismagamt){
		string magsprite=(thismagamt>0)?"RMAGA0":"RMAGB0";
		return magsprite,"RBRSA3A7","SevenMilAmmo",1.7;
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("LiberatorRifle");
	}
	states{
	spawn:
		RMAG A -1;
		stop;
	spawnempty:
		RMAG B -1{
			brollsprite=true;brollcenter=true;
			roll=randompick(0,0,0,0,2,2,2,2,1,3)*90;
		}stop;
	}
}
class HD7mClip:HDMagAmmo{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Boss Clip"
		//$Sprite "RCLPA0"

		hdmagammo.maxperunit 10;
		hdmagammo.roundtype "SevenMilAmmo";
		hdmagammo.roundbulk ENC_776;
		hdmagammo.magbulk ENC_776CLIP_EMPTY;
		hdpickup.refid HDLD_SEVCLIP;
		tag "7.76mm clip";
		inventory.pickupmessage "Picked up a 7.76mm clip.";
		scale 0.6;
		inventory.maxamount 1000;
	}
	override string,string,name,double getmagsprite(int thismagamt){
		string magsprite;
		if(thismagamt>8)magsprite="RCLPA0";
		else if(thismagamt>6)magsprite="RCLPB0";
		else if(thismagamt>4)magsprite="RCLPC0";
		else if(thismagamt>2)magsprite="RCLPD0";
		else if(thismagamt>0)magsprite="RCLPE0";
		else magsprite="RCLPF0";
		return magsprite,"RBRSA3A7","SevenMilAmmo",1.5;
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("BossRifle");
	}
	states(actor){
	spawn:
		RCLP ABCDE -1 nodelay{
			int amt=mags[0];
			if(amt>8)frame=0;
			else if(amt>6)frame=1;
			else if(amt>4)frame=2;
			else if(amt>2)frame=3;
			else if(amt>0)frame=4;
		}stop;
	spawnempty:
		RCLP F -1{
			brollsprite=true;brollcenter=true;
			roll=randompick(1,1,1,1,3,3,3,3,0,2)*90;
		}stop;
	}
}
//(primers and bullet lead can be cannibalized from 4.26mm rounds)
class SevenMilBrass:HDAmmo{
	default{
		+inventory.ignoreskill +forcexybillboard +cannotpush
		+hdpickup.multipickup
		+hdpickup.cheatnogive
		height 16;radius 8;
		tag "7.76mm casing";
		hdpickup.refid HDLD_SEVNBRA;
		hdpickup.bulk ENC_776B;
		xscale 0.7;yscale 0.8;
		inventory.pickupmessage "Picked up some brass.";
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("LiberatorRifle");
		itemsthatusethis.push("AutoReloader");
	}
	states{
	spawn:
		RBRS A -1;
		stop;
	}
}

class LiberatorEmptyMag:IdleDummy{
	override void postbeginplay(){
		super.postbeginplay();
		HDMagAmmo.SpawnMag(self,"HD7mMag",0);
		destroy();
	}
}
class HDSpent7mm:HDUPK{
	override void postbeginplay(){
		super.postbeginplay();
		A_ChangeVelocity(frandom(-3,3),frandom(-0.4,0.4),0,CVF_RELATIVE);
	}
	default{
		+missile
		+hdupk.multipickup
		height 4;radius 2;
		bouncetype "doom";
		hdupk.pickuptype "SevenMilBrass";
		hdupk.pickupmessage "Picked up some brass.";

		bouncesound "misc/casing";
		xscale 0.7;yscale 0.8;
		maxstepheight 0.6;
	}
	states{
	spawn:
		RBRS A 2{
			angle+=45;
			if(floorz==pos.z&&!vel.z)A_Countdown();
		}wait;
	death:
		RBRS A -1{
			actor p=spawn("SevenMilBrass",self.pos,ALLOW_REPLACE);
			p.vel=self.vel;p.vel.xy*=3;p.angle=angle;
			if(p.vel!=(0,0,0)){
				p.A_FaceMovementDirection();
				p.angle+=90;
			}
			destroy();
		}stop;
	}
}
class HDLoose7mm:HDSpent7mm{
	override void postbeginplay(){
		HDUPK.postbeginplay();
	}
	default{
		bouncefactor 0.6;
		hdupk.pickuptype "SevenMilAmmo";
		hdupk.pickupmessage "Picked up a 7.76mm round.";
	}
	states{
	death:
		---- A 1{
			actor a=spawn("SevenMilAmmo",pos,ALLOW_REPLACE);
			a.angle=self.angle;a.vel=self.vel;
			destroy();
		}stop;
	}
}

class HD7mBoxPickup:HDUPK{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Box of 7.76mm"
		//$Sprite "7BOXA0"

		scale 0.4;
		hdupk.amount 50;
		hdupk.pickupsound "weapons/pocket";
		hdupk.pickupmessage "Picked up some 7.76mm ammo.";
		hdupk.pickuptype "SevenMilAmmo";
	}
	states{
	spawn:
		7BOX A -1;
	}
}

