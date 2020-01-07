// ------------------------------------------------------------
// Your home away from home.
// ------------------------------------------------------------
class HDLoadBox:switchabledecoration{
	default{
		//$Category "Misc/Hideous Destructor/"
		//$Title "Magic Ammo Box"
		//$Sprite "AMBXA0"

		+usespecial
		height 20;radius 20;gravity 0.8;
		activation THINGSPEC_Switch|THINGSPEC_ThingTargets;
	}
	states{
	active:
	inactive:
		AMBX A 5{
			A_StartSound("misc/chat2",CHAN_AUTO);
			busespecial=false;
		}
		AMBX B 18{
			target.A_SetInventory("HDFragGrenadeAmmo",max(3,target.countinv("HDFragGrenadeAmmo")));
			A_GiveToTarget("HDLoaded");
			if(
				!target.countinv("HEATAmmo")
				&&target.countinv("HDRL")
			)A_GiveToTarget("HEATAmmo");
			target.A_Print("Weapons reloaded.");
			target.A_StartSound("misc/w_pkup",CHAN_AUTO);
		}
	spawn:
		AMBX A -1{
			busespecial=true;
		}
	}
}
class HDLoaded:ActionItem{
	//THIS IS ALSO USED FOR DEATH AND RESPAWN
	states{
	pickup:
		TNT1 A 0{
			for(inventory hdww=inv;hdww!=null;hdww=hdww.inv){
				let hdw=hdweapon(hdww);
				if(hdw&&!hdbackpack(hdw))hdw.initializewepstats(true);
				let hdm=hdmagammo(hdww);
				if(hdm)hdm.maxcheat();
			}
		}fail;
	}
}



class TargetBarrel:Actor{
	default{
		//$Category "Misc/Hideous Destructor/"
		//$Title "Moving Target Barrel"
		//$Sprite "BEXPB0"

		+nevertarget +shootable +quicktoretaliate +float +nogravity +nodamage +noblood
		height 28;radius 10;mass 25;painchance 256;speed 2;
	}
	//3.7.1 does not allow painstates with +nodamage.
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(!bnopain)setstatelabel("pain");
		return 0;
	}
	states{
	spawn:
		BEXP B 2{
			A_ChangeVelocity(frandom(-0.4,0.4),frandom(-0.4,0.4),frandom(-1,1));
			A_Wander();
		}
		TNT1 A 0 A_JumpIf(vel.x>4||vel.y>4||vel.z>4,"spawn");
		BEXP B 1 A_SetTics(random(10,100));
		loop;
	pain:
		BEXP B 3{
			bnopain=true;
			vel.x+=10;
			bnogravity=false;
			spawn("HDExplosion",pos+(0,0,16),ALLOW_REPLACE);
			spawn("HDSmoke",pos+(0,0,16),ALLOW_REPLACE);
		}
		TNT1 A 0{
			bnopain=0;
			DistantNoise.Make(self,"world/rocketfar");
		}
	pain2:
		BEXP B 1{
			spawn("HDSmoke",pos+(0,0,16),ALLOW_REPLACE);
			if(floorz>=pos.z)setstatelabel("pain3");
		}wait;
	pain3:
		BEXP B 10{
			vel.z*=-0.3;
			bnogravity=true;
			A_StartSound("weapons/smack");
		}goto spawn;
	}
}

class PunchDummy:HDActor{
	default{
		//$Category "Misc/Hideous Destructor/"
		//$Title "Punching Dummy"
		//$Sprite "BEXPB0"

		+noblood +shootable +ghost
		height 54;radius 12;health TELEFRAG_DAMAGE;
		xscale 1.22;
		yscale 1.69;
		translation "0:255=%[0,0,0]:[1.7,1.3,0.4]";
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(!inflictor||!source)return 0;
		if(
			inflictor is "HDFistPuncher"
			||(inflictor.player && inflictor.player.readyweapon is "HDFist")
		){
			vel.z+=damage*0.1;
			string d="u";
			if(damage>100){
				d="x";
				A_StartSound("misc/p_pkup",CHAN_WEAPON,attenuation:0.6);
			}else if(damage>60)d="y";
			else if(damage>30)d="g";
			if(!hd_debug&&source)source.A_Log(
				string.format("\ccPunched for \c%s%i\cc damage!",d,damage)
			,true);
			A_StartSound("misc/punch",CHAN_AUTO);
		}
		return 0; //indestructible
	}
	states{
	spawn:
	pain:
		BEXP B -1;
	}
}


