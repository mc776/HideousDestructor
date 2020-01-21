// ------------------------------------------------------------
// Backpack
// ------------------------------------------------------------
const HDCONST_BPMAX=1000;
class HDBackpack:HDWeapon{
	int index;

	array<string> nicenames;
	array<string> refids;
	array<string> invclasses;

	array<string> amounts;
	//because the last time I tried nested dynamic arrays it did not work.
	//"10" for 10 rounds/medikits/whatever; "0 10 20" for 3 mags
	//"0 0 0 0 0 0 0 0 0" for a single weapon: first # is bulk

	double maxcapacity;
	property maxcapacity:maxcapacity;

	default{
		//$Category "Items/Hideous Destructor/Gear"
		//$Title "Backpack"
		//$Sprite "BPAKA0"

		+inventory.invbar
		+weapon.wimpy_weapon
		+weapon.no_auto_switch
		+hdweapon.droptranslation
		+hdweapon.fitsinbackpack
		+hdweapon.alwaysshowstatus
		+hdweapon.ignoreloadoutamount
		weapon.selectionorder 1010;

		inventory.icon "BPAKA0";
		inventory.pickupmessage "Picked up a backpack to help fill your life with ammo!";
		inventory.pickupsound "weapons/pocket";

		tag "backpack";
		hdweapon.refid HDLD_BACKPAK;

		hdbackpack.maxcapacity HDCONST_BPMAX;
	}
	override void DropOneAmmo(int amt){
		if(owner){
			RemoveFromBackpack(index,false);
			if(
				havenone(index)
				&&(
					!findinventory(invclasses[index])
					||(
						hdweapon(findinventory(invclasses[index]))
						&&!hdweapon(findinventory(invclasses[index])).bfitsinbackpack
					)
				)
			)updatemessage(index+1);
		}
	}

	int bpindex;
	int maxindex;
	void UpdateCapacity(){
		maxcapacity=getdefaultbytype(getclass()).maxcapacity/max(hd_encumbrance,0.01);
	}
	override void InitializeWepStats(bool idfa){
		if(idfa)return;

		UpdateCapacity();

		nicenames.clear();
		refids.clear();
		invclasses.clear();
		for(int i=0;i<allactorclasses.size();i++){
			class<actor> reff=allactorclasses[i];
			if(!(reff is "Inventory"))continue;
			let invd=getdefaultbytype((class<inventory>)(reff));
			if(
				!invd
				||invd.bnointeraction
				||invd.bundroppable
				||invd.buntossable
			)continue;
			string ref="";
			string nnm="";
			if(reff is "HDPickup"){
				let gdb=getdefaultbytype((class<hdpickup>)(reff));
				if(gdb.bfitsinbackpack){
					nnm=gdb.gettag();
					if(nnm==gdb.getclassname())nnm="";
					ref=gdb.refid;
				}
			}else if(reff is "HDWeapon"){
				let gdb=getdefaultbytype((class<hdweapon>)(reff));
				if(gdb.bfitsinbackpack){
					nnm=gdb.gettag();
					if(nnm==gdb.getclassname())nnm="";
					ref=gdb.refid;
				}
			}
			if(nnm!=""){
				invclasses.push(reff.getclassname());
				nicenames.push(nnm);
				refids.push(ref);
				amounts.push("");
			}
		}
		bpindex=invclasses.find(getclassname());
		maxindex=invclasses.size()-1;
	}
	void initializeamount(string loadlist){
		array<string> whichitem;whichitem.clear();
		array<string> howmany;howmany.clear();
		loadlist.replace(" ","");
		loadlist.split(whichitem,",");
		for(int i=0;i<whichitem.size();i++){
			howmany.push((whichitem[i].mid(3,whichitem[i].length())));
			whichitem[i]=whichitem[i].left(3);
		}
		string weapondefaults="";
		if(owner&&owner.player)weapondefaults=hdweapon.getdefaultcvar(owner.player);
		for(int i=0;i<whichitem.size();i++){
			string ref=whichitem[i].makelower();
			if(ref=="")continue;
			int refindex=refids.find(ref);
			if(refindex>=refids.size())continue;

			let wep=(class<hdweapon>)(invclasses[refindex]);
			let mag=(class<hdmagammo>)(invclasses[refindex]);
			let pkgv=(class<hdpickupgiver>)(invclasses[refindex]);
			let pkup=(class<hdpickup>)(invclasses[refindex]);

			int howmanyi=max(1,howmany[i].toint());
			if(wep||mag){
				for(int j=0;j<howmanyi;j++){
					inventory iii=inventory(spawn(invclasses[refindex],pos,ALLOW_REPLACE));
					if(hdweapongiver(iii)){
						hdweapongiver(iii).spawnactualweapon();
						let newwep=hdweapongiver(iii).actualweapon;
						itemtobackpack(newwep);
					}else{
						if(wep){
							hdweapon(iii).loadoutconfigure(weapondefaults);
							hdweapon(iii).loadoutconfigure(howmany[i]);
						}
						itemtobackpack(iii);
					}
					if(iii)iii.destroy();
				}
			}else if(pkgv){
				for(int j=0;j<howmanyi;j++){
					inventory iii=inventory(spawn(invclasses[refindex],pos,ALLOW_REPLACE));
					hdpickupgiver(iii).spawnactualitem();
					itemtobackpack(hdpickupgiver(iii).actualitem);
					if(iii)iii.destroy();
				}
			}else if(pkup){
				let iii=spawn(invclasses[refindex],pos,ALLOW_REPLACE);
				if(iii){
					iii.destroy();
					double bulkmax=(maxcapacity-bulk)/max(1,getdefaultbytype(pkup).bulk);
					int addamt=int(max(1,min(bulkmax,howmanyi)));
					if(addamt>0){
						int amt=amounts[refindex].toint(10);
						amounts[refindex]=""..amt+addamt;
						updatemessage(index);
					}
				}
			}
		}
	}

	double bulk;
	override double weaponbulk(){
		double blk=0;
		for(int i=0;i<invclasses.size();i++){
			if(havenone(i))continue;
			class<actor> reff=invclasses[i];
			array<string> theseamounts;
			theseamounts.clear();
			if(((class<hdmagammo>)(reff))){
				amounts[i].split(theseamounts," ");
				let mmm=getdefaultbytype((class<hdmagammo>)(reff));
				bool armour=!!((class<HDArmour>)(reff));
				bool usemagbulk=(mmm.magbulk>0||mmm.roundbulk>0);
				for(int j=0;j<theseamounts.size();j++){
					int thamt=theseamounts[j].toint();
					if(armour)blk+=thamt>=1000?ENC_BATTLEARMOUR:ENC_GARRISONARMOUR;
					else{
						if(usemagbulk)blk+=mmm.magbulk+thamt*mmm.roundbulk;
						else blk+=mmm.bulk;
					}
				}
				if(!blk)blk=mmm.bulk*theseamounts.size();
			}else if(((class<hdweapon>)(reff))){
				amounts[i].split(theseamounts," ");
				for(int j=0;j<theseamounts.size();j++){
					if(!((j+1)%(HDWEP_STATUSSLOTS+1)))blk+=theseamounts[j].toint();
				}
			}else if(((class<hdpickup>)(reff))){
				let classref=((class<hdpickup>)(reff));
				//presets required for default ammos because of One Man Army
				double unitbulk;
				if(classref is "HDShellAmmo")unitbulk=ENC_SHELL;
				else if(classref is "FourMilAmmo")unitbulk=ENC_426;
				else if(classref is "SevenMilAmmo")unitbulk=ENC_776;
				else if(classref is "HDPistolAmmo")unitbulk=ENC_9;
				else if(classref is "HDRocketAmmo")unitbulk=ENC_ROCKET;
				else if(classref is "HDBattery")unitbulk=ENC_BATTERY;
				else if(classref is "BrontornisRound")unitbulk=ENC_BRONTOSHELL;
				else if(classref is "HEATAmmo")unitbulk=ENC_HEATROCKET;
				else if(classref is "HDFragGrenadeAmmo")unitbulk=ENC_FRAG;
				else unitbulk=getdefaultbytype(classref).bulk;
				blk+=amounts[i].toint()*unitbulk;
			}
		}
		bulk=blk;
		return max(blk*0.7,100);
	}

	int GetAmount(class<inventory> type){
		int thisindex=invclasses.find(type.getclassname());
		if(thisindex>=invclasses.size())return 0;
		if(amounts[thisindex]=="")return 0;
		let wep=(class<hdweapon>)(type);
		let mag=(class<hdmagammo>)(type);
		let pkup=(class<hdpickup>)(type);
		if(wep||mag){
			array<string>amts;
			amounts[thisindex].split(amts," ");
			if(wep)return amts.size()/(HDWEP_STATUSSLOTS+1);
			else return amts.size();
		}
		return amounts[thisindex].toint();
	}
	void AddAmount(class<inventory> type,int amt,int magamount=-1){
		let wep=(class<hdweapon>)(type);
		let mag=(class<hdmagammo>)(type);
		let pkup=(class<hdpickup>)(type);
		if((wep||mag)&&amt<1)return; //non-positive input for simple items only
		int thisindex=invclasses.find(type.getclassname());
		if(wep){
			for(int i=0;i<amt;i++){
				let itb=inventory(spawn(wep));
				itemtobackpack(itb);
			}
			return;
		}
		if(mag){
			if(magamount<0)magamount=getdefaultbytype(mag).maxperunit;
			else magamount=min(magamount,getdefaultbytype(mag).maxperunit);
			for(int i=0;i<amt;i++){
				string newamts=amounts[thisindex];
				if(havenone(thisindex))newamts=newamts.." ";
				newamts=newamts..magamount;
				amounts[thisindex]=newamts;
			}
			return;
		}
		if(pkup){
			int newamt=amounts[thisindex].toint()+amt;
			if(newamt<1)amounts[thisindex]="";
			else amounts[thisindex]=""..newamt;
		}
	}

	int showindices[4];
	int selectedinbackpack;int selectedininventory;
	ui textureid,vector2 BPInvIcon(int which){
		let item=getdefaultbytype((class<inventory>)(invclasses[which]));
		let ddi=item.icon;
		vector2 ddv=(1.,1.);

		//static virtuals aren't a thing, so any other exceptions will be going here :(
		string specicon="";
		if((HDArmour)(item)){
			specicon=amounts[which].toint()>=1000?"ARMCA0":"ARMSA0";
		}else if((HDWeapon)(item)){
			array<string> wepstatus;
			amounts[which].split(wepstatus," ");
			if(wepstatus.size()>=(HDWEP_STATUSSLOTS+1)){
				if((HDPistol)(item)){
					specicon=(wepstatus[0].toint()&PISF_SELECTFIRE)?"PISTC0":"PISTA0";
				}else if((ZM66AssaultRifle)(item)){
					string fr=(wepstatus[ZM66S_MAG].toint()<0)?"D":"A";
					int st=wepstatus[0].toint();
					if(!(st&ZM66F_NOLAUNCHER)){
						if(st&ZM66F_NOFIRESELECT)specicon="RIGS";
						else specicon="RIGL";
					}else if(st&ZM66F_NOFIRESELECT)specicon="RIFS";
					else specicon="RIFL";
					specicon=specicon..fr..0;
				}else if((LiberatorRifle)(item)){
					bool ul=(wepstatus[LIBS_MAG].toint()<0);
					int st=wepstatus[0].toint();
					if(st&LIBF_NOLAUNCHER)specicon=ul?"BRFLC0":"BRFLA0";
					else specicon=ul?"BRFLD0":"BRFLB0";
				}else if((HDSMG)(item)){
					specicon=(wepstatus[SMGS_MAG].toint()<0)?"SMGNB0":"SMGNA0";
				}
			}
		}
		if(specicon!="")ddi=texman.checkfortexture(specicon,texman.type_any);

		if(!ddi){
			let dds=item.spawnstate;
			if(dds!=null)ddi=dds.GetSpriteTexture(0);
		}
		if(ddi){
			vector2 dds=texman.getscaledsize(ddi);
			if(min(dds.x,dds.y)<8.){
				ddv*=(8./min(dds.x,dds.y));
			}
		}
		return ddi,ddv;
	}
	override string,double getpickupsprite(){return "BPAKA0",1.;}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		for(int i=0;i<4;i++){
			if(showindices[i]>=0){
				textureid bpi;vector2 bps;
				[bpi,bps]=BPInvIcon(showindices[i]);
				int xofs=-80;
				switch(i){
					case 1:xofs=-40;break;
					case 2:xofs=40;break;
					case 3:xofs=80;break;
					default:break;
				}
				if(bpi&&showindices[0]>=0)sb.drawtexture(bpi,(xofs,0),
					sb.DI_ITEM_CENTER|sb.DI_SCREEN_CENTER,
					alpha:amounts[showindices[0]]==""?0.3:0.6,
					scale:bps
				);
			}
		}
		//if(index>=0&&index<invclasses.size()){
		if(index>=0&&index<invclasses.size()){
			textureid bpi;vector2 bps;
			[bpi,bps]=BPInvIcon(index);
			if(bpi)sb.drawtexture(bpi,(0,0),
				sb.DI_ITEM_CENTER_BOTTOM|sb.DI_SCREEN_CENTER,
				alpha:amounts[index]==""?0.6:1.,
				scale:bps
			);
			sb.drawstring(
				sb.pSmallFont,nicenames[index],
				(0,18),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_CENTER,
				font.CR_FIRE
			);
			sb.drawstring(
				sb.pSmallFont,"In Backpack:  "..selectedinbackpack,
				(-44,30),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_LEFT,
				selectedinbackpack?font.CR_BROWN:font.CR_DARKBROWN
			);
			sb.drawstring(
				sb.pSmallFont,"On Person:    "..selectedininventory,
				(-44,38),sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_LEFT,
				selectedininventory?font.CR_WHITE:font.CR_DARKGRAY
			);
		}
	}
	override string gethelptext(){
		return
		WEPHELP_FIRE.."/"..WEPHELP_ALTFIRE.."  Previous/Next item\n"
		..WEPHELP_FIREMODE.."+"..WEPHELP_UPDOWN.."  Scroll through items\n"
		..WEPHELP_RELOAD.."  Insert\n"
		..WEPHELP_UNLOAD.."  Remove\n"
		..WEPHELP_DROPONE.."  Remove and drop\n"
		..WEPHELP_ALTRELOAD.."  Dump\n"
		;
	}
	void UpdateMessage(int num){
		if(!owner)return;
		UpdateCapacity();

		//set index as necessary
		int nnsiz=nicenames.size();
		if(num==index)weaponbulk();
		if(num!=index&&owner){
			int toadd=num>index?1:-1;
			do{
				index+=toadd;
				if(index>maxindex)index=0;
				else if(index<0)index=maxindex;
			}while(
				index!=bpindex
				&&havenone(index)
				&&(
					!owner.countinv(invclasses[index])
					||(
						hdweapon(owner.findinventory(invclasses[index]))
						&&!hdweapon(owner.findinventory(invclasses[index])).bfitsinbackpack
					)
				)
			);
		}else if(max(0-num,num-nnsiz)<maxindex){
			while(num<0)num+=nnsiz;
			while(num>maxindex)num-=nnsiz;
			index=num;
		}

		showindices[0]=-1;showindices[1]=-1;showindices[2]=-1;showindices[3]=-1;
		int bpindex=invclasses.find(getclassname());
		for(int i=1;i<nnsiz;i++){
			int plusi=index+i;
			if(plusi>=nnsiz)plusi-=nnsiz;
			if(
				!havenone(plusi)
				||(
					owner.countinv(invclasses[plusi])
					&&(
						!hdweapon(owner.findinventory(invclasses[plusi]))
						||hdweapon(owner.findinventory(invclasses[plusi])).bfitsinbackpack
					)
				)
			){
				if(showindices[2]<0)showindices[2]=plusi;
				else if(showindices[3]<0)showindices[3]=plusi;
			}

			plusi=index-i;
			if(plusi<0)plusi+=nnsiz;
			if(
				!havenone(plusi)
				||(
					owner.countinv(invclasses[plusi])
					&&(
						!hdweapon(owner.findinventory(invclasses[plusi]))
						||hdweapon(owner.findinventory(invclasses[plusi])).bfitsinbackpack
					)
				)
			){
				if(showindices[1]<0)showindices[1]=plusi;
				else if(showindices[0]<0)showindices[0]=plusi;
			}
		}
		let thisinv=(class<inventory>)(invclasses[index]);
		selectedinbackpack=getamount(thisinv);
		selectedininventory=owner.countinv(thisinv);

		//display selected item name and amounts carried
		wepmsg="\cs[] [] [] \cbBackpack \cs[] [] []\nfiremode=fast scroll  unload/reload=take/insert\n\n"
			.."\n\nTotal Bulk: \cf"..int(bulk);
	}
	//generic code for inserting into backpack
	//return 1 to indicate a FAILED pickup
	int ItemToBackpack(inventory item){
		if(item==self&&amount<2)return 1;
		let wep=HDWeapon(item);
		let mag=HDMagAmmo(item);
		let pkup=HDPickup(item);
		if(!wep&&!pkup)return 1;
		if(
			(wep&&!wep.bfitsinbackpack)
			||(pkup&&!pkup.bfitsinbackpack)
		)return 1;
		int newindex=invclasses.find(item.getclassname());
		if(newindex>=invclasses.size())return 1;
		index=newindex;
		UpdateMessage(newindex);

		if(wep){
			if(wep is "HDBackpack"&&HDBackpack(wep).bulk>0){
				if(owner)owner.A_Log("Empty this backpack first.",true);
				return 1;
			}
			if(wep.weaponbulk()+bulk>maxcapacity){
				if(owner)owner.A_Log("Your backpack is too full.",true);
				return 1;
			}
			if(wep.owner)wep=HDWeapon(owner.dropinventory(wep));
			string newwep=""..wep.weaponstatus[0];
			for(int i=1;i<HDWEP_STATUSSLOTS;i++){
				newwep=newwep.." "..wep.weaponstatus[i];
			}
			newwep=newwep.." "..
				int(wep.weaponbulk())..
				(amounts[index]==""?"":" ");
			amounts[index]=newwep..amounts[index];
			if(hd_debug){
				A_Log(nicenames[index]..":  "..wep.getclassname().."  "..newwep);
				A_Log(amounts[index]);
			}
			wep.amount--;if(wep.amount<1)wep.destroy();
			weaponbulk();
			UpdateMessage(index);
			return 12;
		}else if(mag){
			if(mag.magbulk+bulk>maxcapacity){
				if(owner)owner.A_Log("Your backpack is too full.",true);
				return 1;
			}
			int tookmag=mag.TakeMag(false);if(item.amount<1)item.destroy();
			if(amounts[index]=="")amounts[index]=""..tookmag;
			else amounts[index]=tookmag.." "..amounts[index];
		}else{
			int units=item.owner?1:item.amount;
			if(pkup.bulk*units+bulk>maxcapacity){
				if(owner)owner.A_Log("Your backpack is too full.",true);
				return 1;
			}
			amounts[index]=""..max(0,amounts[index].toint())+units;
			item.amount-=units;if(item.amount<1)item.destroy();
		}
		weaponbulk();
		UpdateMessage(index);
		if(pkup.bmultipickup)return 4;else return 10;
	}
	//returns whether empty
	bool havenone(int which){
		return(
			amounts[which]==""
			||(
				amounts[which].toint()<1
				&&!((class<HDMagAmmo>)(invclasses[which]))
				&&!((class<HDWeapon>)(invclasses[which]))
			)
		);
	}
	//configure from loadout
	//syntax: bak item1. item2. item3 (basically use dots instead of commas)
	override void loadoutconfigure(string input){
		input.replace(".",",");
		if(hd_debug&&!!owner)owner.A_Log("Backpack Loadout: "..input);
		initializeamount(input);
	}
	//generic code for removing from backpack
	int RemoveFromBackpack(int which=-1,bool trytopocket=true){
		if(which<0||which>=invclasses.size())which=index;
		if(havenone(which))return 1;
		array<string>tempamounts;
		bool basicpickup=false;
		amounts[which].split(tempamounts," ");
		if(tempamounts.size()<1)return 1;
		int ticks=0;
		let hdp=hdplayerpawn(owner);
		let wepth=(class<hdweapon>)(invclasses[which]);
		let thisclass=(class<hdpickup>)(invclasses[which]);
		if(wepth){
			let newp=HDWeapon(spawn(wepth,owner.pos+(0,0,owner.height-12),ALLOW_REPLACE));
			newp.bdontdefaultconfigure=true;
			newp.angle=owner.angle;newp.A_ChangeVelocity(1,1,1,CVF_RELATIVE);
			for(int i=0;i<(HDWEP_STATUSSLOTS+1);i++){
				if(i<newp.weaponstatus.size())newp.weaponstatus[i]=tempamounts[0].toint();
				tempamounts.delete(0);
			}
			if(trytopocket&&owner.countinv(wepth)<getdefaultbytype(wepth).maxamount){
				newp.actualpickup(owner);
				ticks=12;
			}else{
				ticks=10;
				if(newp.bdroptranslation)newp.translation=owner.translation;
			}
		}
		if(thisclass){
			int thisamt=max(0,tempamounts[0].toint());
			bool multipi=getdefaultbytype(thisclass).bmultipickup;

			let mt=(class<HDMagAmmo>)(thisclass);
			if(
				owner.A_JumpIfInventory(thisclass,0,"null")
				||HDPickup.MaxGive(owner,thisclass,
					mt?(getdefaultbytype(mt).roundbulk*getdefaultbytype(mt).maxperunit+getdefaultbytype(mt).magbulk)
					:getdefaultbytype(thisclass).bulk
				)<1
			)trytopocket=false;

			if(mt){
				if(trytopocket)HDMagAmmo.GiveMag(owner,thisclass,thisamt);
				else HDMagAmmo.SpawnMag(owner,thisclass,thisamt);
				tempamounts.delete(0);
			}else{
				basicpickup=true;
				thisamt--;
				if(!trytopocket){
					int moar=0;
					if(multipi&&thisamt>0)moar=min(random(10,50),thisamt);
					let iii=inventory(spawn(thisclass,owner.pos+(0,0,owner.height-20),ALLOW_REPLACE));
					iii.angle=owner.angle;iii.vel=owner.vel;
					iii.A_ChangeVelocity(1,0,1,CVF_RELATIVE);
					iii.amount=1+moar;
					if(hdpickup(iii)&&hdpickup(iii).bdroptranslation)iii.translation=owner.translation;
					thisamt-=moar;
				}
				else HDF.Give(owner,thisclass,1);
				tempamounts[0]=""..thisamt;
			}
			//allow continuous move for smaller items
			if(multipi)ticks=6;else ticks=10;
		}
		//put the string back together
		string newamounts="";
		if(basicpickup){
			if(tempamounts[0].toint()>0)newamounts=tempamounts[0];
		}else{
			for(int i=0;i<tempamounts.size();i++){
				newamounts=newamounts..(i?" ":"")..tempamounts[i];
			}
		}
		amounts[which]=newamounts;
		if(havenone(which)&&!owner.countinv(invclasses[which]))UpdateMessage(which+1);
		UpdateMessage(index);
		return ticks;
	}
	//main interface
	string curamt;
	action void A_BPReady(){
		if(pressingfiremode()){
			int inputamt=player.cmd.pitch>>5;
			invoker.UpdateMessage(invoker.index-inputamt);
			HijackMouse();
		}
		int ttt=1;
		if(justpressed(BT_ATTACK))invoker.UpdateMessage(invoker.index-1);
		else if(justpressed(BT_ALTATTACK))invoker.UpdateMessage(invoker.index+1);
		else if(pressingreload()&&countinv(invoker.invclasses[invoker.index])){
			ttt=invoker.ItemToBackpack(findinventory(invoker.invclasses[invoker.index]));
		}else if(pressingunload()){
			ttt=invoker.RemoveFromBackpack(invoker.index,true);
		}else if(pressing(BT_ALTRELOAD)){
			invoker.RemoveFromBackpack(invoker.index,false);
			invoker.updatemessage(invoker.index+1);
			if(self is "HDPlayerPawn")ttt=randompick(0,0,0,0,0,1);
			if(!invoker.bulk){
				DropInventory(invoker);
				return;
			}
		}
		if(!pressing(BT_ALTRELOAD)){
			A_WeaponMessage(invoker.wepmsg,ttt+1);
			A_SetTics(max(1,ttt));
		}else A_SetTics(ttt);
		A_WeaponReady(
			WRF_NOFIRE|WRF_ALLOWUSER3
			|((player.cmd.buttons&(BT_RELOAD|BT_UNLOAD|BT_USE))?WRF_DISABLESWITCH:0)
		);
	}
	states{
	spawn:
		BPAK ABC -1 nodelay{
			invoker.weaponbulk();
			if(!invoker.bulk)frame=1;
			else if(target){
				translation=target.translation;
				frame=2;
			}
			invoker.bno_auto_switch=false;
		}
	select0:
		TNT1 A 10{
			A_StartSound("weapons/pocket",CHAN_WEAPON);
			if(invoker.bulk>(HDBPC_CAPACITY*0.7))A_SetTics(20);
			invoker.index=clamp(invoker.index,0,invoker.maxindex);
			if(invoker.havenone(invoker.index))invoker.updatemessage(invoker.index+1);
			else invoker.UpdateMessage(invoker.index);
		}goto super::select0;
	ready:
		TNT1 A 1 A_BPReady();
		goto readyend;
	nope:
		TNT1 A 0 A_WeaponMessage(invoker.wepmsg,5);
		goto super::nope;
	}
}
enum HDBackpackItems{
	HDBPC_CAPACITY=1000,
}








//semi-filled backpacks at random
class WildBackpack:IdleDummy replaces Backpack{
		//$Category "Items/Hideous Destructor/Gear"
		//$Title "Backpack (Random Spawn)"
		//$Sprite "BPAKC0"
	override void postbeginplay(){
		super.postbeginplay();
		let aaa=HDBackpack(spawn("HDBackpack",pos,ALLOW_REPLACE));
		aaa.RandomContents();
		destroy();
	}
}
extend class HDBackpack{
	void RandomContents(){
		if(hd_debug)A_Log("\n*  Backpack:  *");
		for(int i=0;i<5;i++){
			int thisitem=random(1,invclasses.size())-1;
			let wep=(class<hdweapon>)(invclasses[thisitem]);
			let pkup=(class<hdpickup>)(invclasses[thisitem]);
			let mag=(class<hdmagammo>)(pkup);
			int howmany=0;
			if(wep){
				let iii=inventory(spawn(wep,pos,ALLOW_REPLACE));
				if(hdweapongiver(iii))itemtobackpack(hdweapongiver(iii).actualweapon);
				else if(hdpickupgiver(iii))itemtobackpack(hdpickupgiver(iii).actualitem);
				else itemtobackpack(iii);
			}else if(mag){
				howmany=int(min(
					random(1,random(1,20)),
					getdefaultbytype(mag).maxamount,
					maxcapacity/(
						max(1.,getdefaultbytype(mag).roundbulk)
						*max(1.,getdefaultbytype(mag).magbulk)
						*5.
					)
				));
				for(int j=0;j<howmany;j++){
					inventory iii=inventory(spawn(mag,pos,ALLOW_REPLACE));
					if(iii){
						itemtobackpack(iii);
						if(iii)iii.destroy();
					}
				}
			}else if(pkup){
				let iii=spawn(pkup,pos,ALLOW_REPLACE);
				if(iii){
					iii.destroy();
					howmany=int(min(
						random(1,getdefaultbytype(pkup).bmultipickup?random(1,80):random(1,random(1,20))),
						getdefaultbytype(pkup).maxamount,
						maxcapacity/(max(1.,getdefaultbytype(pkup).bulk)*5.)
					));
					if(
						getdefaultbytype(pkup).refid==""
					){
						howmany=random(-2,howmany);
					}
					amounts[thisitem]=""..howmany;
					if(amounts[thisitem].toint()<1)amounts[thisitem]="";
				}
			}
			if(hd_debug)A_Log(invclasses[thisitem].."  "..howmany);
		}
		weaponbulk();
		updatemessage(index);
	}


	override void Consolidate(){
		//go through all backpacked items and call their respective Consolidate()s
		for(int i=0;i<invclasses.size();i++){
			if(havenone(i))continue;
			let type=(class<hdpickup>)(invclasses[i]);
			if(!type)continue;
			int onperson=BPToInv(owner,type);

			let thisinv=hdpickup(owner.findinventory(type));
			int maxinvbak=thisinv.maxamount;
			thisinv.maxamount=int.MAX;

			thisinv.Consolidate();

			//then put everything back
			if(thisinv.amount<1)return;
			int inbackpack=thisinv.amount-onperson;
			if(type is "HDMagAmmo"){
				let thismags=hdmagammo(thisinv);
				string ibp="";
				for(int j=0;j<inbackpack;j++){
					int thismagindex=thismags.mags.size()-1; //replace with "0" to reverse order
					ibp=ibp..(ibp==""?"":" ")..thismags.mags[thismagindex];
					thismags.mags.delete(thismagindex); //don't "pop" in case i want to reverse
					thismags.amount--;
				}
				amounts[i]=ibp;
			}else{
				amounts[i]=""..max(0,inbackpack);
				thisinv.amount=onperson;
			}

			thisinv.maxamount=maxinvbak;
		}

		//arbitrary hard-code: repair *E.R.P.s even if all of them have been backpacked.
		//wanted: sane way to give weapons the same unpack-consolidate-repack treatment.
		if(!owner.findinventory("HERPUsable"))herpusable.backpackrepairs(owner,self);
		if(!owner.findinventory("DERPUsable"))derpusable.backpackrepairs(owner,self);
	}

	//increase maxamount by backpackamount
	//take backpack contents and put them in inventory
	//return original amount on person
	static int BPToInv(actor caller,class<inventory> type){
		int originalamount=caller.countinv(type);
		let bp=hdbackpack(caller.findinventory("hdbackpack"));
		if(
			bp
			&&bp.invclasses.find(type.getclassname())>=0
		){
			int bpindex=bp.invclasses.find(type.getclassname());
			string addamt=bp.amounts[bpindex];
			if(addamt!=""){
				if(type is "HDMagAmmo"){
					array<string> bpmags;bpmags.clear();
					addamt.split(bpmags," ");
					hdmagammo onp=hdmagammo(caller.findinventory(type));
					for(int i=0;i<bpmags.size();i++){
						caller.A_GiveInventory(type,1);
						if(!onp){
							onp=hdmagammo(caller.findinventory(type));
							onp.mags.clear();
						}
						onp.maxamount=max(onp.maxamount,originalamount+bpmags.size());
						onp.mags.push(bpmags[i].toint());
					}
				}else if(type is "HDPickup"&&addamt.toint()>0){
					int bpamt=addamt.toint();
					let cfi=caller.findinventory(type);
					if(!cfi){
						cfi=caller.giveinventorytype(type);
						cfi.amount=0;
					}
					if(cfi){
						cfi.maxamount=max(cfi.maxamount,originalamount+bpamt);
						cfi.amount+=bpamt;
					}
				}
			}
			bp.amounts[bpindex]="";
		}
		return originalamount;
	}
}





//modding extension: remove a specified item type from all backpacks
//returns true if something was deleted
extend class HDBackpack{
	bool DeleteItem(string invclass){
		int dexof=invclasses.find(invclass);
		if(
			dexof==invclasses.size()
			||!amounts[dexof]
			||amounts[dexof]==""
		)return false;
		amounts[dexof]="";
		return true;
	}
}




