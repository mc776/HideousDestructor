// ------------------------------------------------------------
// Setting things on fire
// ------------------------------------------------------------
class ImmunityToFire:InventoryFlag{
	override void attachtoowner(actor user){
		super.attachtoowner(user);
		if(owner){
			actoriterator it=level.createactoriterator(-7677,"HDFire");
			actor fff;
			while(fff=it.next()){
				if(fff.target==owner){
					fff.destroy();
				}
			}
		}
	}
}
class HDFireEnder:InventoryFlag{
	default{
		inventory.maxamount 5;
	}
}
class HDFireDouse:InventoryFlag{
	default{
		inventory.maxamount 20;
	}
	override void DoEffect(){
		if(amount>0)amount--;
	}
}


//how to immolate
extend class HDActor{
	//should be in HDActor once all conversions are done
	//A_Immolate(tracer,target);
	virtual void A_Immolate(
		actor victim,
		actor perpetrator,
		int duration=0
	){
		if(!victim
			||(
				perpetrator&&
				perpetrator.bdontharmspecies&&
				perpetrator.getspecies()==victim.getspecies()
			)
		){
			victim=spawn("PersistentDamager",self.pos,ALLOW_REPLACE);
			victim.target=perpetrator;
		}
		actor f=victim.spawn("HDFire",victim.pos,ALLOW_REPLACE);
		f.target=victim;f.master=perpetrator;
		if(duration<1) f.stamina=random(40,80);
		else f.stamina=duration;
		if(victim is "PlayerPawn")f.changetid(-7677);
	}
}
//fire actor
class HDFire:IdleDummy{
	double halfrad,minz,maxz,lastheight;
	default{
		+bloodlessimpact
		obituary "%o was burned by %k.";
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(target){
			stamina=target.ApplyDamageFactor("Thermal",stamina);
			if(target is "PlayerPawn" || target is "HDPlayerCorpse"){
				changetid(-7677);
				stamina=int(max(1,(!skill)?(hd_damagefactor*0.3*stamina):(hd_damagefactor*stamina)));
			}
			if(!target.bshootable && stamina>20)stamina=20;
		}
		if(
			A_CheckProximity("null","HDFire",64,12,CPXF_CHECKSIGHT|CPXF_SETTRACER)
			&&(!target||tracer.target==target)
		){
			tracer.stamina+=stamina;
			destroy();
			return;
		}
		if(hd_debug)A_Log(string.format("fire duration \ci%i",stamina));
	}
	override void ondestroy(){
		if(target&&target is "PersistentDamager")target.destroy();
		super.ondestroy();
	}
	states{
	spawn:
		TNT1 A 3{
			if(target&&target.countinv("ImmunityToFire")){
				destroy();return;
			}

			if(!master)master=self;
			if(!target){
				target=spawn("PersistentDamager",self.pos,ALLOW_REPLACE);
				target.target=master;
				if(stamina>20)stamina=20;
			}

			setorigin(target.pos,false);

			//check if player
			let tgt=HDPlayerPawn(target);
			if(tgt){
				if(tgt.playercorpse){
					target=tgt.playercorpse;
				}
				A_AlertMonsters();
				A_TakeFromTarget("PowerFrightener");
				A_GiveToTarget("IsMoving",4);
				HDWeapon.SetBusy(target);
			}else stamina-=3; //monsters assumed to be trying to douse

			int wlvl=target.waterlevel;
			if(wlvl>1){
				destroy();
				if(wlvl<2)spawn("HDSmoke",pos,ALLOW_REPLACE);
				return;
			}
			A_SetTics(clamp(random(3,int(30-stamina*0.1)),2,12));
			if(stamina<=0 || target.countinv("HDFireEnder")){
				A_TakeFromTarget("HDFireEnder");
				spawn("HDSmoke",pos,ALLOW_REPLACE);
				destroy();
				return;
			}
			int ds=target.countinv("HDFireDouse");
			if(ds){
				target.A_TakeInventory("HDFireDouse",ds);
				stamina-=ds;
			}
			stamina--;

			//set flame spawn point
			if(lastheight!=target.height){ //poll only height
				halfrad=max(4,target.radius*0.5);
				lastheight=target.height;
				minz=lastheight*0.2;
				maxz=max(lastheight*0.75,4);
			}

			//position and spawn flame
			setorigin(pos+(
					frandom(-halfrad,halfrad),
					frandom(-halfrad,halfrad),
					frandom(minz,maxz)
			),false);
			actor sp=spawn("HDFlameRed",pos,ALLOW_REPLACE);
			sp.vel+=target.vel+(frandom(-2,2),frandom(-2,2),frandom(-1,3));
			A_StartSound("misc/firecrkl",CHAN_AUTO,volume:0.4,attenuation:6.);

			//heat up the target
			target.A_GiveInventory("Heat",clamp(stamina,20,random(20,80)));
		}
		wait;
	}
}




//an invisible actor that constantly damages anything it collides with
class PersistentDamager:HDActor{
	vector3 relpos;
	default{
		+noblockmap
		damagetype "Thermal";

		height 8;radius 8;
		stamina 8;
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(master)relpos=self.pos-master.pos;
	}
	int ticker;
	override void tick(){
		if(isfrozen())return;

		if(master)setorigin(master.pos+relpos,false);
		if(ticker<4)ticker++;else{
			ticker=0;
			blockthingsiterator ccw=blockthingsiterator.create(self);
			while(ccw.next()){
				actor ccc=ccw.thing;
				if(
					ccc.bnodamage
					||!ccc.bshootable
					||ccc.pos.z<pos.z-ccc.height
				)continue;
				stamina--;
				if(damagetype=="Thermal")HDF.Give(ccc,"Heat",stamina*10);
				ccc.damagemobj(self,target,stamina,damagetype);
			}
			stamina--;
			if(stamina<1){destroy();return;}
		}

		//nexttic
		if(CheckNoDelay()){
			if(tics>0)tics--;  
			while(!tics){
				if(!SetState(CurState.NextState)){
					return;
				}
			}
		}
	}
	states{
	spawn:
		TNT1 A -1;
	}
}


//new shit

class Heat:Inventory{
	double volume;
	double volumeratio;
	double inversevolumeratio;
	double baseinversevolumeratio;
	double realamount;
	int burnoutthreshold;
	int burnouttimer;
	actor heatfield;
	actor heatlight;
	enum HeatNumbers{
		HEATNUM_DEFAULTVOLUME=12*12*48*4,
	}
	states{spawn:TNT1 A 0;stop;}
	default{
		+inventory.untossable //for some reason this works without it
		inventory.amount 1;
		inventory.maxamount 9999999;
		obituary "%o was too hot to handle.";
	}
	static double GetAmount(actor heated){
		let htt=Heat(heated.findinventory("Heat"));
		if(!htt)return 0;
		return htt.realamount;
	}
	override void attachtoowner(actor user){
		super.attachtoowner(user);
		volume=(user.radius*user.radius*user.height)*4;
		baseinversevolumeratio=HEATNUM_DEFAULTVOLUME/max(0.000001,volume);
		inversevolumeratio=baseinversevolumeratio;
		volumeratio=1/baseinversevolumeratio;
		burnoutthreshold=max(0,(user.gibhealth+user.spawnhealth())<<hdmobbase.HDMOB_GIBSHIFT);
		A_SetSize(owner.radius,owner.height);
		heatlight=HDFireLight(spawn("HDFireLight",pos,ALLOW_REPLACE));
		heatlight.target=owner;hdfirelight(heatlight).heattarget=self;
	}
	override void DoEffect(){
		if(!owner){destroy();return;}
		if(!owner.player&&isfrozen())return;

		//make adjustments based on armour and player status
		let hdp=hdplayerpawn(owner);
		if(hdp){
			inversevolumeratio=baseinversevolumeratio;
			int al=hdp.armourlevel;
			if(al==1)inversevolumeratio*=0.4;
			else if(al==3)inversevolumeratio*=0.6;

			if(
				hdp.health<1&&
				hdp.playercorpse
			){
				hdp.playercorpse.A_GiveInventory("Heat",1);
				Heat(hdp.playercorpse.findinventory("Heat")).realamount+=realamount;
				destroy();
				return;
			}
		}

		//convert given to real
		if(amount){
			realamount+=amount*inversevolumeratio;
			amount=0;
		}
		//clamp number to zero
		if(realamount<1){
			realamount=0;
			return;
		}
		int ticker=level.time;

		//flame
		if(
			!(ticker%3)
			&&realamount>frandom(100,140)
			&&owner.bshootable
			&&!owner.bnodamage
			&&!owner.countinv("ImmunityToFire")
			&&burnoutthreshold>(hdmobbase(owner)?burnouttimer
		){
			if(owner.bshootable){
				realamount+=frandom(1.2,3.0);
			}
			if(owner.waterlevel<=random(0,1)){
				actor aaa;
				if(
					owner is "PersistentDamager"
					||realamount<600
				){
					burnouttimer++;
					aaa=spawn("HDFlameRed",owner.pos+(
						frandom(-radius,radius),
						frandom(-radius,radius),
						frandom(2,owner.height)
					),ALLOW_REPLACE);
				}else{
					burnouttimer+=2;
					aaa=spawn("HDFlameRedBig",owner.pos+(
						frandom(-radius,radius)*0.6,
						frandom(-radius,radius)*0.6,
						frandom(5,owner.height*0.2)
					),ALLOW_REPLACE);
					aaa.scale=(randompick(-1,1)*frandom(0.9,1.2),frandom(0.9,1.1))*clamp((realamount-600)*0.0003,0.6,2.);
					if(!heatlight)heatlight=HDFireLight(spawn("HDFireLight",pos,ALLOW_REPLACE));
					heatlight.target=owner;hdfirelight(heatlight).heattarget=self;
					heatlight.args[0]=200;
					heatlight.args[1]=150;
					heatlight.args[2]=90;
					heatlight.args[3]=int(min(realamount*0.1,256));
				}
				aaa.target=owner;
				aaa.A_StartSound("misc/firecrkl",CHAN_BODY,volume:clamp(realamount*0.001,0,0.2));
			}
		}

		//damage
		if(
			!(ticker%3)
			&&owner.bshootable&&!owner.bnodamage
			&&(owner.countinv("WornRadsuit")?realamount*0.1:realamount)>random(random(7,12),70)
		){
			double dmgamt=realamount*0.01;
			if(
				dmgamt<1.
				&&(frandom(0.,1.)<dmgamt)
			)dmgamt=1.;
			setxyz(owner.pos);
			owner.damagemobj(self,self,int(dmgamt),"thermal",DMG_NO_ARMOR|DMG_THRUSTLESS);
			if(!owner){destroy();return;}
		}


		//convection, kinda
		if(ticker>20){
			flinetracedata hlt;
			double aimdist=max(10,realamount*0.01);
			owner.linetrace(
				frandom(0,360),aimdist,frandom(-80,-90),
				offsetz:0,
				data:hlt
			);
			if(
				hlt.hitactor
				&&(
					!hlt.hitactor.findinventory("Heat")
					||heat(hlt.hitactor.findinventory("Heat")).realamount<realamount
				)
			){
				let htt=heat(hlt.hitactor.findinventory("Heat"));
				if(!htt)htt=heat(hlt.hitactor.GiveInventoryType("heat"));
				double distdiff=hlt.distance/aimdist;
				double togive=realamount*(1.-distdiff)*0.01*volume/max(1.,htt.volume);
				if(togive>0){
					htt.realamount+=togive;
					realamount-=togive;
				}
				if(togive>2)hlt.hitactor.damagemobj(self,owner,1,"thermal",DMG_NO_ARMOR|DMG_THRUSTLESS);
			}
		}

		//I don't know specifically *what* in Universal Gibs can cause a killerbarrel
		//to be destroyed by the above damagemobj call, but whatever.
		if(!owner){destroy();return;}

		//cooldown
		double reduce=inversevolumeratio*max(realamount*0.001,1.);
		if(owner.vel dot owner.vel > 4)reduce*=1.6;

		if(owner.waterlevel>2)reduce*=10;
		else if(owner.waterlevel>1)reduce*=4;
		else if(owner.countinv("HDFireDouse"))reduce*=2;

		double aang=absangle(angle,owner.angle);
		if(aang>4.)reduce*=clamp(aang*0.4,1.,4.);
		if((!skill)&&owner.player)reduce*=2;
		realamount-=reduce;
		angle=owner.angle;

//if(owner.player)A_LogFloat(realamount);
	}
}

class HDFireLight:PointLight{
	heat heattarget;
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=200;
		args[1]=150;
		args[2]=100;
		args[3]=0;
		args[4]=0;
	}
	override void tick(){
		if(!heattarget||!target){destroy();return;}
		if(isfrozen())return;
		setorigin(target.pos,true);
		if(args[3]<1){
			args[0]=0;
			args[1]=0;
			args[2]=0;
			args[3]=0;
		}
		else args[3]=int(frandom(0.9,0.99)*args[3]);
	}
}


