// ------------------------------------------------------------
// Cell ammo for Lumberjack and others
// ------------------------------------------------------------
class HDBattery:HDMagAmmo{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Cell Battery"
		//$Sprite "CELLA0"

		hdmagammo.maxperunit 20;
		hdmagammo.roundtype "";
		tag "battery";
		hdpickup.refid HDLD_BATTERY;
		hdpickup.bulk ENC_BATTERY;
		hdmagammo.magbulk ENC_BATTERY;
		hdmagammo.mustshowinmagmanager true;
		inventory.pickupmessage "Picked up a battery.";
		inventory.icon "CELLA0";
		scale 0.4;
	}
	enum BatteryChargeModes{
		BATT_UNDEFINED=0,
		BATT_DONTCHARGE=1,
		BATT_CHARGEMAX=2,
		BATT_CHARGETOP=3,
		BATT_CHARGEDEFAULT=BATT_CHARGETOP;
	}
	int ticker;
	int lastamount;
	int chargemode;
	override void doeffect(){
		//testingdoeffect();return;
		if(chargemode==BATT_UNDEFINED)chargemode=BATT_CHARGEDEFAULT;
		if(chargemode==BATT_DONTCHARGE){
			super.doeffect();
			return;
		}
		if(lastamount!=amount){
			ticker=0;
			lastamount=amount;
		}else if(ticker>350){
			ticker=0;
			ChargeBattery(1,chargemode==BATT_CHARGETOP);
		}else ticker++;
		super.doeffect();
	}
	override double getbulk(){return amount*bulk;}
	override bool Extract(){return false;}
	override bool Insert(){
		chargemode++;
		if(chargemode>BATT_CHARGETOP)chargemode=BATT_DONTCHARGE;
		return false;
	}
	bool BFGChargeable(){
		if(!owner)return false;
		let bfug=bfg9k(owner.findinventory("bfg9k"));
		if(bfug&&(
			bfug.weaponstatus[BFGS_BATTERY]>BFGC_MINCHARGE
			||bfug.weaponstatus[BFGS_CHARGE]>BFGC_MINCHARGE
		))return true;
		for(int i=0;i<amount;i++){
			if(mags[i]>=BFGC_MINCHARGE)return true;
		}
		return false;
	}

	//thanks to Quarki for explaining how the principle should work
	//as long as the chargors total more than the chargee's desired amount,
	//a transfer may happen in favour of the chargee.
	override void Consolidate(){
		if(owner&&owner.countinv("BFG9k")&&BFGChargeable()){
			MaxCheat();
			return;
		}
		ChargeBattery(usetop:true);
		ChargeBattery();
	}
	void ChargeBattery(int chargestodo=-1,bool usetop=false){
		SyncAmount();
		if(amount<1)return;

		int batcount=0;
		int totalchargeable=0;
		int biggestindex=-1;
		int biggestamt=0;
		int smallestindex=-1;
		int smallestamt=20;
		int maxindex=amount-1;

		//get the smallest and biggest amounts, and number usable for this
		for(int i=0;i<amount;i++){
			int chargeamt=mags[i];
			if(chargeamt>0){
				totalchargeable+=chargeamt;
				batcount++;
				if(
					!usetop
					&&biggestamt<chargeamt
					&&chargeamt<20
				){
					biggestamt=chargeamt;
					biggestindex=i;
				}
				if(
					smallestamt>=chargeamt
				){
					smallestamt=chargeamt;
					smallestindex=i;
				}
			}
		}
		if(usetop){
			biggestindex=maxindex;
			biggestamt=mags[maxindex];
		}
		if(
			biggestindex<0
			||smallestindex<0
			||smallestamt>=20
			||biggestamt>=20
			||biggestindex==smallestindex
		){
			if(chargemode==BATT_CHARGETOP){
				if(biggestamt>=20){
					owner.A_Log("Battery configuration error: full battery selected. Rerouting.");
				}else if(
					biggestindex==smallestindex
					&&biggestindex==maxindex
				){
					owner.A_Log("Battery configuration error: lowest battery selected. Rerouting.");
				}
				chargemode=BATT_CHARGEMAX;
			}
			return;
		}
		if(
			batcount<3	//need at least 3 to increase any one
			||totalchargeable-biggestamt-2<biggestamt	//min. chargor value must exceed target amount
		)return;

		//keep going until exactly ONE battery is fully drained or charged
		while(
			chargestodo
			&&mags[smallestindex]>0
			&&mags[biggestindex]<20
		){
			chargestodo--;
			mags[smallestindex]--;
			if(random(0,39))mags[biggestindex]++;
		}
		if(hd_debug)LogAmounts();
	}
	override string,string,name,double getmagsprite(int thismagamt){
		string magsprite;
		if(thismagamt>13)magsprite="CELLA0";
		else if(thismagamt>6)magsprite="CELLB0";
		else if(thismagamt>0)magsprite="CELLC0";
		else magsprite="CELLD0";
		return magsprite,"CELPA0","HDBattery",0.8;
	}
	override void DrawRoundCount(HDStatusBar sb,HDPlayerPawn hpl,name roundsprite,double scl,int offx,int offy){
		bool helptext=cvar.getcvar("hd_helptext",hpl.player).getbool();
		offx+=40;
		scl=0.4;
		let battt=chargemode;
		string batts="uNone";
		if(battt==hdbattery.BATT_CHARGEMAX)batts="eAuto";
		else if(battt==hdbattery.BATT_CHARGETOP)batts="ySelected";
		sb.drawstrings(
			sb.pSmallFont,string.format("%s\c%s%s",helptext?"Charging: ":"",batts,helptext?"\n(\cqReload\cu to cycle)":""),
			(offx+2,offy),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_LEFT
		);
		sb.drawimage("CELPA0",(offx,offy),
			sb.DI_SCREEN_CENTER|sb.DI_ITEM_RIGHT_TOP,
			scale:(scl,scl)
		);
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("BFG9k");
		itemsthatusethis.push("ThunderBuster");
		itemsthatusethis.push("Vulcanette");
		itemsthatusethis.push("Lumberjack");
		itemsthatusethis.push("HERPUsable");
		itemsthatusethis.push("PortableLiteAmp");
	}
	states(actor){
	spawn:
		CELL CAB -1 nodelay{
			int amt=mags[0];
			if(amt>13)frame=0;
			else if(amt>6)frame=1;
		}stop;
	spawnempty:
		CELL D -1;
		stop;
	}
}
class HDCellpackEmpty:IdleDummy{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Cell Battery (Spent)"
		//$Sprite "CELLD0"
	}
	override void postbeginplay(){
		super.postbeginplay();
		angle=frandom(0,360);
		HDMagAmmo.SpawnMag(self,"HDBattery",0);
		destroy();
	}
}




