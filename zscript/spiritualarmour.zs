//-------------------------------------------------
// Not against flesh and blood.
//-------------------------------------------------
class SpiritualArmour:HDPickup{
	default{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Spiritual Armour"
		//$Sprite "BON2A0"

		+inventory.alwayspickup
		+inventory.undroppable
		+hdpickup.nevershowinpickupmanager
		-inventory.invbar
		inventory.pickupmessage "Picked up an armour bonus.";
		inventory.amount 1;
		inventory.maxamount 3;
		inventory.pickupsound "misc/p_pkup";
		scale 0.8;
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(Wads.CheckNumForName("id",0)==-1)scale=(0.6,0.5);
	}
	action void A_PsalterReading(){
		string ps=SpiritualArmour.FromPsalter();
		double pstime=ps.length()*0.05;
		A_Print(ps,pstime,"newsmallfont");
	}
	states{
	use:TNT1 A 0;fail;
	spawn:
		BON2 A 6 A_SetTics(random(7,144));
		BON2 BC 6 A_SetTics(random(1,2));
		BON2 D 6 light("ARMORBONUS") A_SetTics(random(0,4));
		BON2 CB 6 A_SetTics(random(1,3));
		loop;
	pickup:
		TNT1 A 0{
			A_GiveInventory("PowerFrightener");
			A_TakeInventory("HDBlurSphere");
			let hdp=HDPlayerPawn(self);
			if(hdp){
				hdp.woundcount=0;
				hdp.oldwoundcount+=hdp.unstablewoundcount;
				hdp.unstablewoundcount=0;
				hdp.aggravateddamage=max(0,hdp.aggravateddamage-1);
			}
			A_PsalterReading();
		}
		stop;
	}

	static string FromPsalter(){
		string psss=Wads.ReadLump(Wads.CheckNumForName("psalms",0));
		array<string> pss;pss.clear();
		psss.split(pss,"Psalm ");
		pss.delete(0); //don't get anything before "Psalm 1:1"
		string ps=pss[random(0,pss.size()-1)];
		ps=ps.mid(ps.indexof(" ")+1);
		ps.replace("/","\n\n");
		ps.replace("|","\n");
		return ps;
	}
}


