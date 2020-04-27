// ------------------------------------------------------------
// Shotgun Shells
// ------------------------------------------------------------



//a thinker to remember which number corresponds to which shell class
//class HDShellClasses:Thinker{
class HDShellClasses:Actor{
	array<string> classnames;
	override void PostBeginPlay(){
		super.PostBeginPlay();

		//test
		FireShell(self,0,32,7);
		FireShell(players[0].mo,1,32,7);
		FireShell(self,2,32,7);
		FireShell(self,3,32,7);
	}
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
		if(!hdsc)hdsc=HDShellClasses(spawn("HDShellClasses",(0,0,0)));//new("HDShellClasses");
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
		if(!hdsc)hdsc=HDShellClasses(spawn("HDShellClasses",(0,0,0)));//new("HDShellClasses");
		if(!hdsc.classnames.size())hdsc.init();
		int res=hdsc.classnames.find(which);
		if(res==hdsc.classnames.size())return 0;
		return res;
	}

	//grab one instance of the class
	static NewHDShellAmmo GetShellAmmo(int which){
		string thisclassname=IntToName(which);
		NewHDShellAmmo nsa=null;
		thinkeriterator nsait=thinkeriterator.create("NewHDShellAmmo");
		while(nsa=NewHDShellAmmo(nsait.next())){
			if(nsa&&nsa.getclassname()==thisclassname)break;
		}
		if(!nsa)nsa=NewHDShellAmmo(spawn(thisclassname,(31000,31000,0)));
		return nsa;
	}

	//grab one instance of the class and execute its virtual Fire function
	//NewHDShellAmmo.FireShell(...);
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
class NewHDShellAmmo2:NewHDShellAmmo{}
class NewHDShellAmmo3:NewHDShellAmmo{}
class NewHDShellAmmo4:NewHDShellAmmo{}
class NewHDShellAmmo5:NewHDShellAmmo{}









// ------------------------------------------------------------
// Shotgun (Common)
// ------------------------------------------------------------
class HDNewShotgun:HDWeapon{
	default{
		+weapon.cheatnotweapon
		+hdweapon.debugonly

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


/*

	//sidesaddle management
	string sstext;
	int ssindex;
	void UpdateSSText(){
		string stext="";
		for(int i=SGNS_SSSTART;i<=SGNS_SSEND;i++){
			stext=stext..((i==ssindex)?">  ":"   ");
			if(weaponstatus[i]<1)stext=stext.."< empty >";
			else stext=stext..getdefaultbytype(getshellclass(weaponstatus[i])).gettag();
			stext=stext.."\n";
			//one more bit of white space
			if(i==(SGNS_SSSTART+5))stext=stext.."\n";
		}
		sstext=stext;
	}
	action void A_SideSaddleReady(){
		if(pressingfiremode){
			setweaponstate("ssmanend");
			return;
		}
		if(justpressed(BT_USER3)){
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
			justpressed(BT_RELOAD)
			&&!invoker.weaponstatus[ssindex]
		){
			let gsc=getshellclass(invoker.weaponstatus[SGNS_SELECTEDTYPE]);
			let igsc=findinventory(gsc);
			if(igsc){
				A_TakeInventory(gsc,1);
				invoker.weaponstatus[ssindex]=hdhandlers.getshellclassnum(gsc);
			}
		}else if(
			justpressed(BT_UNLOAD)
			&&invoker.weaponstatus[ssindex]
		){
			A_GiveInventory(getshellclass(invoker.weaponstatus[ssindex]),1);
			invoker.weaponstatus[ssindex]=0;
		}
	}


	states{
	//shotgun
	ssmanready:
		TNT1 A 1 A_SideSaddleReady();
		loop;
	ssmanend:
		TNT1 A 0;
		goto nope;
	}
}




//recording the shell classes in HDHandlers to be used by any actor
//(the alternative is to keep a full copy for every shotgun, shotgun guy and marine - bad!)
extend class HDHandlers{
	array<string> shellclassnames;
	array<string> shelltags;
	void populateshellclasses(){
		shellclassnames.clear();
		shelltags.clear();

		//position 0 can't be inverted, don't use it
		shellclassnames.push("");
		shelltags.push("nothing");

		for(int i=0;i<allactorclasses.size();i++){
			if(
				(class<HDShellAmmo>)(allactorclasses[i])
			){
				if(allactorclasses[i]=="HDShellAmmo"){
					shellclassnames.insert(0,allactorclasses[i].getclassname());
					shelltags.insert(0,getdefaultbytype(allactorclasses[i].getclassname()).gettag());
				}else{
					shellclassnames.push(allactorclasses[i].getclassname());
					shelltags.push(allactorclasses[i].gettag());
				}
			}
		}
	}
}





//for mob shots
extend class HDMobMan{
	int loadedshells[8];  //0-1 for slayer, 0-7 hunter
	int chokes[2];
	int barrellength[2];
	bool rifledshotgun;
	//A_FireHDNPCShotgun(loadedshells[0],chokes[0],barrellength[0],rifledshotgun,xyofs:SLAYER_BARRELOFFLEFT,aimoffx:SLAYER_BARRELTILTLEFT);	//A_FireHDNPCShotgun(loadedshells[1],chokes[1],barrellength[1],rifledshotgun,xyofs:SLAYER_BARRELOFFRIGHT,aimoffx:SLAYER_BARRELTILTRIGHT);
	//bool chambered=A_FireHDNPCShotgun(loadedshells[0],chokes[0],barrellength[0],rifledshotgun)>HUNTER_MINSHOTPOWER;
	virtual double A_FireHDNPCShotgun(
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
		if(shelltypeindex<1)return 0;
		double shotpower=0;
		let shellclass=hdhandlers.getshellclass(shelltypeindex);

		//if a reference actor already exists, just use that, otherwise spawn a dummy
		hdshellammo hhh=hdshellammo(findinventory(shellclass));
		bool dummyspawn;
		if(!hhh){
			hhh=HDShellAmmo(spawn(shellclass,(-32000,-32000,-32000)));
			dummyspawn=true;
		}else dummyspawn=false;
		//call the fire function and destroy the dummy if present
		if(hhh){
			shotpower=hhh.FireShell(
				self,
				choke,
				barrellength,
					zofs,
					xyofs,
					spread,
					aimoffx,
					aimoffy
			);
			if(dummyspawn)hhh.destroy();
		}

		//replace chamber with spent
		loadedshells[chamberslot]=-shelltypeindex;

		//shotpower used for recoil and cycling
		return shotpower;
	}

*/
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


