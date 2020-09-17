// ------------------------------------------------------------
// Encumbrance
// ------------------------------------------------------------

//a battery should be about the size of your old flip phone but significantly heavier.
const ENC_BATTERY=18;
const ENC_BATTERY_LOADED=ENC_BATTERY*0.4;

//a ZM66 mag should be roughly the size of a battery.
//50 single rounds should inconvenience you far LESS than a single mag.
//https://www.youtube.com/watch?v=mjuEJjzon-g
const ENC_426MAG=16;
const ENC_426MAG_EMPTY=ENC_426MAG*0.4;
const ENC_426_LOADED=(ENC_426MAG*0.6)/50.;
const ENC_426=ENC_426_LOADED*1.4;
const ENC_426MAG_LOADED=ENC_426MAG_EMPTY*0.4;

const ENC_776MAG=42;
const ENC_776MAG_EMPTY=ENC_776MAG*0.5;
const ENC_776_LOADED=(ENC_776MAG*0.5)/30.;
const ENC_776=ENC_776_LOADED*1.8;
const ENC_776MAG_LOADED=ENC_776MAG_EMPTY*0.5;
const ENC_776B=ENC_776*0.3;
const ENC_776CLIP_EMPTY=ENC_776B;
const ENC_776CLIP=ENC_776CLIP_EMPTY+ENC_776*10;

const ENC_9MAG=10;
const ENC_9MAG_EMPTY=ENC_9MAG*0.3;
const ENC_9_LOADED=(ENC_9MAG*0.7)/15.;
const ENC_9=ENC_9_LOADED*1.4;
const ENC_9MAG_LOADED=ENC_9MAG_EMPTY*0.1; //it's almost entirely inside the handle!

const ENC_9MAG30_EMPTY=ENC_9MAG_EMPTY*2.4;
const ENC_9MAG30=ENC_9MAG30_EMPTY+ENC_9_LOADED*30;
const ENC_9MAG30_LOADED=ENC_9MAG30*0.9; //it's almost entirely outside!

const ENC_355=ENC_9*1.3;
const ENC_355_LOADED=ENC_9MAG_LOADED*1.3;


//other things
const ENC_SHELL=1.8;
const ENC_SHELLLOADED=0.6;
const ENC_ROCKET=ENC_426MAG*0.9;
const ENC_ROCKETLOADED=ENC_ROCKET*0.5;
const ENC_HEATROCKET=ENC_ROCKET*1.2;
const ENC_HEATROCKETLOADED=ENC_ROCKETLOADED*1.2;
const ENC_BRONTOSHELL=ENC_426MAG*1.1;
const ENC_BRONTOSHELLLOADED=ENC_BRONTOSHELL*0.4;
const ENC_FRAG=ENC_ROCKET*1.6;

//more things
const ENC_BATTLEARMOUR=700;
const ENC_GARRISONARMOUR=360;
const ENC_RADSUIT=50;
const ENC_IEDKIT=3;
const ENC_SQUADSUMMONER=7;
const ENC_BLUEPOTION=12;
const ENC_LITEAMP=20;
const ENC_MEDIKIT=45;
const ENC_STIMPACK=7;
const ENC_LADDER=70;
const ENC_DERP=55;
const ENC_HERP=125;
const ENC_DOORBUSTER=ENC_HEATROCKET;


const HDCONST_MAXPOCKETSPACE=600.;


extend class HDPlayerPawn{
	double enc;
	double itemenc;
	double pocketenc;
	double maxpocketspace;property maxpocketspace:maxpocketspace;
	double CheckEncumbrance(){
		if(!player)return 0;
		//separate counters for encumbrance evaluations other than penalty
		double weaponenc=0;
		double weaponencsel=0;
		itemenc=0;

		//add everything up
		double stacker=1.;
		for(inventory hdww=inv;hdww!=null;hdww=hdww.inv){
			let hdw=hdweapon(hdww);
			if(hdw&&!(hdw is "HDBackpack")){
				bool thisweapon=(
					hdw==player.readyweapon
					||(hdw==lastweapon&&nullweapon(player.readyweapon))
				);
				double gunbulk=hdw.weaponbulk();
				if(gunbulk>0){
					if(thisweapon)weaponencsel=gunbulk;
					else{
						weaponenc+=gunbulk;
						if(gunbulk>70){
							double stacked=(gunbulk-70)*0.0003;
							stacker+=stacked;
						}
					}
					//A_Log(string.format("%s  %.2f",hdw.getclassname(),gunbulk));
				}
			}else{
				let hdp=hdpickup(hdww);
				if(hdp)itemenc+=abs(hdp.getbulk());
			}
		}
		weaponenc*=stacker;

		//now add the spare weapons
		let spares=SpareWeapons(findinventory("SpareWeapons"));
		if(spares){
			double sparebulk;int sparesize;
			[sparebulk,sparesize]=spares.getwepbulk();
			if(sparesize>0){
				double avg=sparebulk*0.0003/sparesize;
				for(int i=0;i<sparesize;i++){
					stacker*=1.+avg;
				}
				weaponenc+=sparebulk*stacker;
			}
		}

		//add backpack
		double bpenc=0;
		let bp=hdbackpack(findinventory("HDBackpack"));
		if(bp)bpenc=bp.weaponbulk();


		//if sv_infiniteammo is on, give just enough to reload a gun once
		if(sv_infiniteammo){
			let www=hdweapon(player.readyweapon);
			if(www)www.ForceBasicAmmo();
		}



		double carrymax=
			400+
			(zerk>0?100:0)+
			min(regenblues,150)+
			stimcount*2
		;
		enc=weaponenc+weaponencsel+itemenc+bpenc;


		//if you're somehow carrying more than pocket space allows
		pocketenc=HDPickup.PocketSpaceTaken(self);
		double overpocket=pocketenc/maxpocketspace;
		if(overpocket>1.){
			carrymax/=overpocket;
			//just randomly shake off stuff until you can move again
			if(
				player
				&&(
					player.cmd.buttons&BT_SPEED
					||player.cmd.buttons&BT_JUMP
				)
			){
				muzzleclimb3=(frandom(-5,5),frandom(-5,5));
				muzzleclimb4=(frandom(-5,5),frandom(-5,5));
				for(inventory hdww=inv;hdww!=null;hdww=hdww.inv){
					let hdp=hdpickup(hdww);
					if(
						hdp
						&&!WornRadsuit(hdp) //just in case
						&&!HDArmourWorn(hdp)
						&&(!PortableLiteAmp(hdp)||!PortableLiteAmp(hdp).worn)
					)DropInventory(hdp,random(0,max(1,hdp.amount>>3)));
				}
			}
		}


		//include encumbrance multiplier before outputting final
		return enc*hdmath.getencumbrancemult()/carrymax;
	}
}
