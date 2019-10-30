//-------------------------------------------------
// Environment/Radiation Suit
//-------------------------------------------------
class WornRadsuit:InventoryFlag{
	default{-inventory.untossable}
	states{spawn:TNT1 A 0;stop;}
	override inventory createtossable(int amount){
		let rrr=owner.findinventory("PortableRadsuit");
		if(rrr)owner.useinventory(rrr);else destroy();
		return null;
	}
	override void attachtoowner(actor owner){	
		if(!owner.countinv("PortableRadsuit"))owner.A_GiveInventory("PortableRadsuit");
		super.attachtoowner(owner);
	}
	override void DetachFromOwner(){
		owner.A_TakeInventory("PortableRadsuit",1);
		owner.A_PlaySound("weapons/pocket",CHAN_AUTO);
		let onr=HDPlayerPawn(self);
		if(onr)onr.stunned+=60;
		super.DetachFromOwner();
	}
	override void DoEffect(){
		if(stamina>0)stamina--;
	}
}
class PortableRadsuit:HDPickup replaces RadSuit{
	default{
		//$Category "Gear/Hideous Destructor/Supplies"
		//$Title "Environment Suit"
		//$Sprite "SUITA0"

		inventory.maxamount 7;
		inventory.pickupmessage "Environmental shielding suit.";
		inventory.pickupsound "weapons/pocket";
		inventory.icon "SUITB0";
		hdpickup.bulk ENC_RADSUIT;
		tag "Environment Suit";
		hdpickup.refid HDLD_RADSUIT;
	}
	override void DetachFromOwner(){
		owner.A_TakeInventory("WornRadsuit");
		target=owner;
		super.DetachFromOwner();
	}
	override void actualpickup(actor user){
		HDF.TransferFire(self,user);
		super.actualpickup(user);
	}
	states{
	spawn:
		SUIT A 1;
		SUIT A -1{
			if(!target)return;
			HDF.TransferFire(target,self);
		}
	use:
		TNT1 A 0{
			A_PlaySound("weapons/pocket");
			if(countinv("HDBackpack")){
				A_DropInventory("HDBackpack");
				return;
			}
			A_SetBlend("00 00 00",1,6,"00 00 00");
			A_ChangeVelocity(0,0,2);
			let onr=HDPlayerPawn(self);
			if(onr)onr.stunned+=60;
			if(!countinv("WornRadsuit")){
				int fff=HDF.TransferFire(self,self);
				if(fff){
					if(random(1,fff)>30){
						A_PlaySound("misc/fwoosh",CHAN_AUTO);
						A_TakeInventory("PortableRadsuit",1);
						return;
					}else{
						HDF.TransferFire(self,null);
						if(onr){
							onr.fatigue+=fff;
							onr.stunned+=fff;
						}
					}
				}
				A_GiveInventory("WornRadsuit");
			}else{
				actor a;int b;
				inventory wrs=findinventory("wornradsuit");
				[b,a]=A_SpawnItemEx("PortableRadsuit",0,0,height/2,2,0,4);
				if(a &&  wrs){
					//transfer sticky fire
					if(wrs.stamina){
						let aa=HDActor(a);
						if(aa)aa.A_Immolate(a,self,wrs.stamina);
					}
					//transfer heat
					let hhh=heat(findinventory("heat"));
					if(hhh){
						double realamount=hhh.realamount;
						double intosuit=clamp(realamount*0.9,0,min(200,realamount));
						let hhh2=heat(a.GiveInventoryType("heat"));
						if(hhh2){
							hhh2.realamount+=intosuit;
							hhh.realamount=max(0,hhh.realamount-intosuit);
						}
					}
				}
				A_TakeInventory("WornRadsuit");
			}
		}fail;
	}
}


//-------------------------------------------------
// Light Amplification Visor
//-------------------------------------------------
class PortableLiteAmp:HDMagAmmo replaces Infrared{
	default{
		//$Category "Gear/Hideous Destructor/Supplies"
		//$Title "Light Amp"
		//$Sprite "PVISB0"

		+inventory.invbar
		inventory.pickupmessage "Light amplification visor.";
		inventory.icon "PVISA0";
		scale 0.5;
		hdpickup.bulk ENC_LITEAMP;
		tag "Lite-Amp Goggles";
		hdpickup.refid HDLD_LITEAMP;

		hdmagammo.maxperunit NITEVIS_MAGMAX;
	}
	bool worn;
	PointLight nozerolight;
	override double getbulk(){return bulk;}
	override void DetachFromOwner(){
		worn=false;
		if(owner&&owner.player){
			if(cvar.getcvar("hd_nv",owner.player).getfloat()==999.){
				if(owner.player.fixedcolormap==5)owner.player.fixedcolormap=-1;
				owner.player.fixedlightlevel=-1;
			}
			Shader.SetEnabled(owner.player,"NiteVis",false);
		}
		super.DetachFromOwner();
	}
	double amplitude;
	double lastcvaramplitude;
	override bool isused(){return true;}
	override int getsbarnum(int flags){return amplitude;}
	override void AttachToOwner(actor other){
		super.AttachToOwner(other);
		if(owner&&owner.player)amplitude=cvar.getcvar("hd_nv",owner.player).getfloat();
		else amplitude=frandom(-NITEVIS_MAX,NITEVIS_MAX);
		lastcvaramplitude=amplitude;
	}
	int getintegrity(int index=0){return (mags[index]%NITEVIS_CYCLEUNIT);}
	int setintegrity(int newamt,int index=0,bool relative=false){
		if(amount!=mags.size())syncamount();
		int integrity=getintegrity(index);
		mags[index]-=integrity;

		if(relative)integrity+=newamt;
		else integrity=newamt;

		integrity=clamp(integrity,0,NITEVIS_MAXINTEGRITY);
		mags[index]+=integrity;
		return integrity;
	}
	override void DoEffect(){
		super.DoEffect();
		if(owner && owner.player){
			bool oldliteamp=(
				(sv_cheats||!multiplayer)
				&&cvar.getcvar("hd_nv",owner.player).getfloat()==999.
			);

			//charge
			let bbb=HDBattery(owner.findinventory("HDBattery"));
			if(bbb){
				//get the lowest non-empty
				int bbbindex=bbb.mags.size()-1;
				int bbblowest=20;
				for(int i=bbbindex;i>=0;i--){
					if(
						bbb.mags[i]>0
						&&bbb.mags[i]<bbblowest
					){
						bbbindex=i;
						bbblowest=bbb.mags[i];
					}
				}
				if(mags[0]<NITEVIS_MAGMAXCHARGE){
					mags[0]+=NITEVIS_CYCLEUNIT;
					if(!random[rand1](0,(NITEVIS_BATCYCLE>>1)))bbb.mags[bbbindex]--;
				}
			}

			int chargedamount=mags[0];

//console.printf(chargedamount.."   "..NITEVIS_MAXINTEGRITY-(chargedamount%NITEVIS_CYCLEUNIT));

			if(
				worn
				&&!owner.countinv("PowerInvisibility")
				&&(!oldliteamp||owner.player.fixedcolormap<0||owner.player.fixedcolormap==5)
			){

				//check if totally drained
				if(chargedamount<NITEVIS_CYCLEUNIT){
					owner.A_SetBlend("01 00 00",0.8,16);
					worn=false;
					return;
				}

				int spent=0;

				//update amplitude if player has set in the console
				double thiscvaramplitude=cvar.getcvar("hd_nv",owner.player).getfloat();
				if(thiscvaramplitude!=lastcvaramplitude){
					lastcvaramplitude=thiscvaramplitude;
					amplitude=thiscvaramplitude;
				}

				//actual goggle effect
				owner.player.fov=min(owner.player.fov,90);
				double nv=min(chargedamount*(NITEVIS_MAX/20.),NITEVIS_MAX);
				if(!nv){
					if(thiscvaramplitude<0)amplitude=-0.00001;
					return;
				}
				if(oldliteamp){
					spent+=(NITEVIS_MAX/10);
					owner.player.fixedcolormap=5;
					owner.player.fixedlightlevel=1;
					Shader.SetEnabled(owner.player,"NiteVis",false);
				}else{
					nv=clamp(amplitude,-nv,nv);
					spent+=max(1,abs(nv*0.1));
					Shader.SetEnabled(owner.player,"NiteVis",true);
					Shader.SetUniform1f(owner.player,"NiteVis","exposure",nv);
				}

				//flicker
				int integrity=(mags[0]%NITEVIS_CYCLEUNIT);
				if(integrity<NITEVIS_MAXINTEGRITY){
					int bkn=(integrity)+(chargedamount>>17)-abs(nv);
					A_LogInt(bkn);
					if(!random[rand1](0,max(0,random[rand1](1,bkn)))){
						if(oldliteamp){
							owner.player.fixedcolormap=-1;
							owner.player.fixedlightlevel=-1;
						}
						Shader.SetEnabled(owner.player,"NiteVis",false);
					}
				}

				//drain
				if(!(level.time&(1|2|4|8|16|32)))mags[0]-=NITEVIS_CYCLEUNIT*spent;

			}else{
				if(oldliteamp){
					if(owner.player.fixedcolormap==5)owner.player.fixedcolormap=-1;
					owner.player.fixedlightlevel=-1;
				}
				Shader.SetEnabled(owner.player,"NiteVis",false);
			}
		}
	}
	enum NiteVis{
		NITEVIS_MAX=100,
		NITEVIS_MAXINTEGRITY=400,
		NITEVIS_CYCLEUNIT=NITEVIS_MAXINTEGRITY+1,
		NITEVIS_BATCYCLE=20000,
		NITEVIS_MAGMAXCHARGE=NITEVIS_CYCLEUNIT*NITEVIS_BATCYCLE,
		NITEVIS_MAGMAX=NITEVIS_MAGMAXCHARGE+NITEVIS_MAXINTEGRITY,
	}
	states{
	spawn:
		PVIS A -1;
	use:
		TNT1 A 0{
			int cmd=player.cmd.buttons;
			if(cmd&BT_USE){
				double am=cmd&BT_ZOOM?-5:5;
				double plitude=max(0,(am+abs(invoker.amplitude))%NITEVIS_MAX);
				invoker.amplitude=invoker.amplitude<0?-plitude:plitude;
			}else if(cmd&BT_ZOOM){
				invoker.amplitude=-invoker.amplitude;
			}else if(cmd&BT_USER3){
				invoker.firsttolast();
				int amt=invoker.mags[0];
				A_Log("Goggles at "..amt*100/NITEVIS_MAGMAXCHARGE.."% charge and "..((amt%NITEVIS_CYCLEUNIT)>>2).."% integrity.",true);
			}else{
				A_SetBlend("01 00 00",0.8,16);
				if(HDMagAmmo.NothingLoaded(self,"PortableLiteAmp")){
					A_Log("No power for lite-amp. Need at least 1 battery on you.",true);
					invoker.worn=false;
					return;
				}
				if(invoker.worn)invoker.worn=false;else{
					invoker.worn=true;
					if(!invoker.nozerolight)invoker.nozerolight=PointLight(spawn("visorlight",pos,ALLOW_REPLACE));
					invoker.nozerolight.target=self;
				}
			}
		}fail;
	}
}
class VisorLight:PointLight{
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=1;
		args[1]=0;
		args[2]=0;
		args[3]=256;
		args[4]=0;
	}
	override void tick(){
		if(!target){
			destroy();
			return;
		}
		if(
			target.findinventory("PortableLiteAmp")
			&&portableliteamp(target.findinventory("PortableLiteAmp")).worn
		)args[3]=256;else args[3]=0;
		setorigin((target.pos.xy,target.pos.z+target.height-6),true);
	}
}
