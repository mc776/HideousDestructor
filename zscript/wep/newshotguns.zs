// ------------------------------------------------------------
// Shotgun Shells
// ------------------------------------------------------------



//a thinker to remember which number corresponds to which shell class
class HDShellClasses:Thinker{
	array<string> classnames;
	void init(){
		classnames.clear();
		array<int> bytesums;bytesums.clear();
		for(int i=0;i<allactorclasses.size();i++){
			if(
				allactorclasses[i] is "NewHDShellAmmo"
				&&allactorclasses[i]!="NewHDShellAmmo"
			){
				string ccc=allactorclasses[i].getclassname();
				int bbs=bytesum(ccc,true);
				if(
					bytesums.size()<1
				){
					classnames.push(ccc);
					bytesums.push(bbs);
				}else for(int j=0;j<bytesums.size();j++){
					if(bbs<bytesums[0]){
						classnames.insert(0,ccc);
						bytesums.insert(0,bbs);
						break;
					}
					int jp1=j+1;
					if(
						jp1==bytesums.size()
					){
						classnames.push(ccc);
						bytesums.push(bbs);
						break;
					}
					if(
						bbs>=bytesums[j]
						&&bbs<bytesums[jp1]
					){
						classnames.insert(jp1,ccc);
						bytesums.insert(jp1,bbs);
						break;
					}
				}
			}
		}
		classnames.insert(0,"NewHDShellAmmo");

		if(hd_debug){
			string classlist="Shotgun shell types available:  ";
			for(int i=0;i<classnames.size();i++)classlist=classlist.." "..classnames[i];
			console.printf(classlist);
		}
	}
	static int bytesum(string input,bool forcelower=false){
		if(forcelower)input=input.makelower();
		int total=0;
		for(int i=0;i<input.length();i++){
			total+=input.byteat(i)*i;  //without the multiplier anagrams would have the same value
		}
		return total;
	}

	//convert the number given to the shell class name
	//HDShellClasses.IntToName(_)
	static string IntToName(int which){
		HDShellClasses hdsc=null;
		thinkeriterator hdscit=thinkeriterator.create("HDShellClasses");
		while(hdsc=HDShellClasses(hdscit.next())){
			if(hdsc)break;
		}
		if(!hdsc)hdsc=new("HDShellClasses");
		if(!hdsc.classnames.size())hdsc.init();
		if(which<0||which>=hdsc.classnames.size())return "NewHDShellAmmo";
		return hdsc.classnames[which];
	}

	//HDShellClasses.NameToInt(_)
	static int NameToInt(name which){
		HDShellClasses hdsc=null;
		thinkeriterator hdscit=thinkeriterator.create("HDShellClasses");
		while(hdsc=HDShellClasses(hdscit.next())){
			if(hdsc)break;
		}
		if(!hdsc)hdsc=new("HDShellClasses");
		if(!hdsc.classnames.size())hdsc.init();
		int res=hdsc.classnames.find(which);
		if(res==hdsc.classnames.size())return 0;
		return res;
	}

	//HDShellClasses.NumberOfClasses()
	static int NumberOfClasses(){
		HDShellClasses hdsc=null;
		thinkeriterator hdscit=thinkeriterator.create("HDShellClasses");
		while(hdsc=HDShellClasses(hdscit.next())){
			if(hdsc)break;
		}
		if(!hdsc)hdsc=new("HDShellClasses");
		if(!hdsc.classnames.size())hdsc.init();
		return hdsc.classnames.size();
	}

	//grab one instance of the class
	static NewHDShellAmmo GetShellAmmo(int which){
		string thisclassname=IntToName(which);
		NewHDShellAmmo nsa=null;
		thinkeriterator nsait=thinkeriterator.create("NewHDShellAmmo");
		while(nsa=NewHDShellAmmo(nsait.next())){
			if(nsa&&nsa.getclassname()==thisclassname)break;
		}
		if(!nsa)nsa=NewHDShellAmmo(actor.spawn(thisclassname,(31000,31000,0)));
		return nsa;
	}

	//grab one instance of the class and execute its virtual Fire function
	//HDShellClasses.FireShell(...);
	static void FireShell(
		actor shooter,
		int which,
		double barrellength,
		double choke,
		double xyoffset=0,
		double zoffset=-999,
		double angleoffset=0,
		double pitchoffset=0
	){
		if(zoffset==-999){
			if(shooter.player)zoffset=shooter.player.viewheight-3;
			else zoffset=shooter.height-HDCONST_CROWNTOEYES;
		}
		NewHDShellAmmo saa=GetShellAmmo(which);
		if(saa){
			saa.Fire(shooter,barrellength,choke,xyoffset,zoffset,angleoffset,pitchoffset);
		}
	}
}

class NewHDShellAmmo:HDRoundAmmo{
	default{
		+inventory.ignoreskill
		+hdpickup.multipickup
		inventory.pickupmessage "Picked up a shotgun shell.";
		scale 0.3;
		tag "shotgun shells";
		hdpickup.refid HDLD_SHOTSHL;
		hdpickup.bulk ENC_SHELL;
		inventory.icon "SHELA0";
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("Hunter");
		itemsthatusethis.push("Slayer");
	}
	override void SplitPickup(){
		SplitPickupBoxableRound(4,20,"ShellBoxPickup","SHELA0","SHL1A0");
	}
	override string pickupmessage(){
		if(amount>1)return "Picked up some shotgun shells.";
		return super.pickupmessage();
	}
	states{
	spawn:
		SHL1 A -1;
		stop;
	death:
		ESHL A -1{
			if(Wads.CheckNumForName("id",0)==-1)A_SetTranslation("FreeShell");
			frame=randompick(0,0,0,0,4,4,4,4,2,2,5);
		}stop;
	}

	//this is the function to override for the actual shot
	virtual void Fire(
		actor shooter,
		double barrellength,
		double choke,
		double xyoffset,
		double zoffset,
		double angleoffset,
		double pitchoffset
	){
		console.printf(getclassname().."  "..shooter.gettag());
	}
}

//test, delete later
class NewHDShellAmmo2:NewHDShellAmmo{default{tag "Shell2";}}
class NewHDShellAmmo3:NewHDShellAmmo{default{tag "Shell3";}}
class NewHDShellAmmo4:NewHDShellAmmo{default{tag "Shell4";}}
class NewHDShellAmmo5:NewHDShellAmmo{default{tag "Shell5";}}







// ------------------------------------------------------------
// Shotgun (Common)
// ------------------------------------------------------------
class HDNewShotgun:HDWeapon{
	default{
		+weapon.cheatnotweapon
		+hdweapon.debugonly
hdweapon.refid "sg2";
weapon.slotnumber 3;

		weapon.bobrangex 0.21;
		weapon.bobrangey 0.86;
		scale 0.6;
		inventory.pickupmessage "You got a shotgun!";
		obituary "%o got %h the hot bullets of %k's shotgun to die.";
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}

	//used to track grabbing multiple shells in one hand and fast-loading them in groups
	int handshells[3];
	void EmptyHand(){
		actor caller=owner;
		if(!owner)caller=self;
		for(int i=0;i<handshells.size();i++){
			int hss=handshells[i];
			if(hss>=0){
				handshells[i]=-1;
				let shellclassname=HDShellClasses.IntToName(hss);
				HDPickup.DropItem(caller,shellclassname,1);
			}
		}
	}
	override void DetachFromOwner(){
		EmptyHand();
		super.detachfromowner();
	}

	override void failedpickupunload(){
		int dropped=0;
		for(int i=SGNS_SSSTART;i<=SGNS_SSEND;i++){
			if(dropped>=4)break;
			int which=weaponstatus[i];
			if(which>0){
				dropped++;
				HDPickup.DropItem(self,HDShellClasses.IntToName(which),1);
			}
			weaponstatus[i]=0;
		}
		setstatelabel("spawn");
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,1,10)*4;
			owner.A_DropInventory(HDShellClasses.IntToName(weaponstatus[SGNS_SELECTEDTYPE]),amt);
		}
	}
	override void ForceBasicAmmo(){
		let ccc=HDShellClasses.IntToName(0);
		owner.A_TakeInventory(ccc);
		owner.A_GiveInventory(ccc,20);
	}
	clearscope string getpickupframe(){
		int ssh=0;
		for(int i=SGNS_SSSTART;i<=SGNS_SSEND;i++){
			if(weaponstatus[i]>0)ssh++;
		}
		if(ssh>=11)return "A";
		if(ssh>=9)return "B";
		if(ssh>=7)return "C";
		if(ssh>=5)return "D";
		if(ssh>=3)return "E";
		if(ssh>=1)return "F";
		return "G";
	}

	action void A_FireHDShotgun(
		int chamberslot,
		int choke,
		int barrellength,
		bool rifled,
			double zofs=999,
			double xyofs=0,
			double spread=0,
			double aimoffx=0,
			double aimoffy=0
	){
		HDShellClasses.FireShell(
			self,
			invoker.weaponstatus[chamberslot],
			barrellength,
			choke,
			xyofs,
			zofs,
			aimoffx,
			aimoffy
		);
	}


	//sidesaddle management
	string sstext;
	int ssindex;
	void UpdateSSText(){
		string stext="";
		for(int i=SGNS_SSSTART;i<=SGNS_SSEND;i++){
			string shc=HDShellClasses.IntToName(weaponstatus[i]);

			if(weaponstatus[i]<0)stext=stext..((i==ssindex)?"\ca":"").."< empty >";
			else stext=stext..((i==ssindex)?"\cx":"")..getdefaultbytype(((class<actor>)(shc))).gettag();
			stext=stext.."\n";

			//one more bit of white space
			if(i==(SGNS_SSSTART+5))stext=stext.."\n";
		}
		string shcl=HDShellClasses.IntToName(weaponstatus[SGNS_SELECTEDTYPE]);
		string shnam=getdefaultbytype(
			(
				(class<actor>)
				(shcl)
			)
		).gettag();
		if(owner)shnam=shnam.."  "..owner.countinv(shcl);
		stext=stext.."\n\nSelected: "..shnam;
		sstext=stext;
	}
	action void A_SideSaddleReady(){
		int btns=player.cmd.buttons;
		if(btns)invoker.UpdateSSText();

		if(btns&BT_FIREMODE){
			setweaponstate("ssmanend");
			return;
		}
		if(btns&BT_USER3){
			A_GiveInventory("MagManager");
			A_SelectWeapon("MagManager");
			return;
		}
		A_WeaponReady(WRF_NOFIRE);
		A_WeaponMessage(invoker.sstext,3);

		int ssindex=invoker.ssindex;
		if(justpressed(BT_ATTACK))ssindex--;
		else if(justpressed(BT_ALTATTACK))ssindex++;
		if(ssindex<SGNS_SSSTART)ssindex=SGNS_SSEND;
		else if(ssindex>SGNS_SSEND)ssindex=SGNS_SSSTART;
		invoker.ssindex=ssindex;

		if(
			justpressed(BT_USER1)
		){
			int seldex=invoker.weaponstatus[SGNS_SELECTEDTYPE]+1;
			if(seldex>=HDShellClasses.NumberOfClasses())seldex=0;
			//else if(seldex<0)seldex=HDShellClasses.NumberOfClasses()-1;
			invoker.weaponstatus[SGNS_SELECTEDTYPE]=seldex;
		}else if(
			justpressed(BT_RELOAD)
			&&invoker.weaponstatus[ssindex]<0
		){
			int seltype=invoker.weaponstatus[SGNS_SELECTEDTYPE];
			string gsc=HDShellClasses.IntToName(seltype);
			if(countinv(gsc)){
				A_TakeInventory(gsc,1);
				invoker.weaponstatus[ssindex]=seltype;
			}
		}else if(
			justpressed(BT_UNLOAD)
			&&invoker.weaponstatus[ssindex]>=0
		){
			string gsc=HDShellClasses.IntToName(invoker.weaponstatus[ssindex]);
			A_GiveInventory(gsc,1);
			invoker.weaponstatus[ssindex]=-1;
		}
	}


	states{
	//shotgun
ready:
	ssmanready:
		TNT1 A 0{
			invoker.ssindex=0;
			invoker.UpdateSSText();
		}
		TNT1 A 1 A_SideSaddleReady();
		wait;
	ssmanend:
		TNT1 A 0;
		goto nope;
	}
}





//for mob shots
extend class HDMobMan{
	int loadedshells[8];  //0-1 for slayer, 0-7 hunter
	int chokes[2];
	int barrellength[2];
	bool rifledshotgun;
	//A_FireHDNPCShotgun(loadedshells[0],chokes[0],barrellength[0],rifledshotgun,xyofs:SLAYER_BARRELOFFLEFT,aimoffx:SLAYER_BARRELTILTLEFT);	//A_FireHDNPCShotgun(loadedshells[1],chokes[1],barrellength[1],rifledshotgun,xyofs:SLAYER_BARRELOFFRIGHT,aimoffx:SLAYER_BARRELTILTRIGHT);
	//A_FireHDNPCShotgun(loadedshells[0],chokes[0],barrellength[0],rifledshotgun);
	virtual void A_FireHDNPCShotgun(
		int chamberslot,
		int choke,
		int barrellength,
		bool rifled,
			double zofs=999,
			double xyofs=0,
			double spread=0,
			double aimoffx=0,
			double aimoffy=0
	){
		int shelltypeindex=loadedshells[chamberslot];
		if(shelltypeindex<1)shelltypeindex=0;

		HDShellClasses.FireShell(
			self,
			chamberslot,
			barrellength,
			choke,
			xyofs,
			zofs,
			aimoffx,
			aimoffy
		);

		//replace chamber with spent
		loadedshells[chamberslot]=-shelltypeindex;
	}
}




enum newhdshottystatus{
	SGNS_SSSTART=1,
	SGNS_SSEND=12,  //SGNS_SSSTART+12-1
	SGNS_SELECTEDTYPE=13,  //SGNS_SSEND+1
}


//TODO: move to respective weapon ZS files
enum newslayerstatus{
	SGN2F_UNLOADONLY=1,
	SGN2F_DOUBLE=2,
	SGN2F_FROMPOCKETS=4,
	SGN2F_RIFLED1=8,
	SGN2F_RIFLED2=16,

	SGN2S_CHAMBER1=14,  //SGNS_SELECTEDTYPE+1
	SGN2S_CHAMBER2=15,
	SGN2S_HEAT1=16,
	SGN2S_HEAT2=17,
	SGN2S_CHOKE1=18,
	SGN2S_CHOKE2=19,
	SGN2S_BARRELLENGTH1=20,
	SGN2S_BARRELLENGTH2=21,
//TODO: ADD BARRELLENGTH TO INITIALIZEWEPSTATS (32)
}
enum newhunterstatus{
	SGN1F_CANFULLAUTO=1,
	SGN1F_JAMMED=2,
	SGN1F_UNLOADONLY=4,
	SGN1F_FROMPOCKETS=8,
	SGN1F_ALTHOLDING=16,
	SGN1F_HOLDING=32,
	SGN1F_EXPORT=64,
	SGN1F_RIFLED=128,

	SGN1S_TUBESTART=14,  //SGNS_SELECTEDTYPE+1
	SGN1S_TUBEEND=20,  //SGN1S_TUBESTART+HUNT_TUBELONG-1
	SGN1S_CHAMBER=21,
	SGN1S_FIREMODE=22,
	SGN1S_TUBE=23,
	SGN1S_TUBESIZE=24,
	SGN1S_HAND=25,
	SGN1S_CHOKE=26,
	SGN1S_BARRELLENGTH=27,

	SGN1_TUBELONG=7,
	SGN1_TUBESHORT=4,
}







/*

original attempt, broken, just steal the shot code itself

//TODO: move this to shellammo.zs
extend class HDShellAmmo{
	class<actor> emptytype;
	property emptytype:emptytype;
	class<actor> fumbletype;
	property fumbletype:fumbletype;
	default{
		// **MODDERS**: this is what you need to change
		hdshellammo.emptytype "HDSpentShell";
		hdshellammo.fumbletype "HDFumblingShell";
	}
	//fires shell, returns shotpower value to be used for recoil and action
	// **MODDERS**: this is what you need to change
	virtual double FireShell(
		actor shooter,
		int choke,
		int barrellength,
			//these are replicated from HDBulletActor.FireBullet
			//really only useful here for adjusting double-barreled offsets
			double zofs=999, //999=use default
			double xyofs=0,
			double spread=0, //range of random velocity added
			double aimoffx=0,
			double aimoffy=0
	){
		//this is the default HD 00 buckshot.
		choke=clamp(choke,0,7);
		spread=6.5-0.5*choke;
		double speedfactor=
			1.
			+0.02857*choke
			-(0.3-0.01*barrellength)
		;
		double shotpower=frandom(0.9,1.05);
		spread*=shotpower;
		speedfactor*=shotpower;
		HDBulletActor.FireBullet(caller,"HDB_wad",
			zofs,xyofs,spread,speedfactor
		);
		let p=HDBulletActor.FireBullet(caller,"HDB_00",
			zofs,xyofs,spread,speedfactor,
			amount:10,
			distantsound:"world/shotgunfar"
		);
		caller.A_StartSound("weapons/hunter",CHAN_WEAPON,CHANF_OVERLAP);
		return shotpower;
	}
}
*/


