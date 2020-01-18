// ------------------------------------------------------------
// Custom skin system
// ------------------------------------------------------------
extend class HDPlayerPawn{
	string lastskin;
	string mugshot;
	int standsprite;
	sound
		tauntsound,
		xdeathsound,
		gruntsound,
		landsound,
		medsound;
		//painsound
		//deathsound

	enum HDSkinVals{
		HDSKIN_SPRITE=0,
		HDSKIN_VOICE=1,
		HDSKIN_MUG=2,
	}
	//to be called in the ticker
	void ApplyUserSkin(){
		if(!player||!hd_skin)return;

		//apply sprite
		if(player.crouchfactor<0.75){
			if(standsprite==crouchsprite)scale.y=player.crouchfactor;
			else sprite=crouchsprite;
		}else sprite=standsprite;

		//retrieve values from cvar
		string skinput=hd_skin.getstring();
		if(skinput==lastskin)return;
		lastskin=skinput;  //update old for future comparisons

		skinput=skinput.makelower();
		skinput.replace(" ","");
		skinput.replace("none","");
		skinput.replace("default","");

		array<string> skinname;
		skinput.split(skinname,",");

		//I'd rather do this than to spam up everything below with null checks
		while(skinname.size()<3){
			skinname.push("");
		}

		class<HDSkin> skinclass="HDSkin";  //initialize default

		//find an actor class that matches
		if(skinname[HDSKIN_SPRITE]!=""){
			for(int i=0;i<allactorclasses.size();i++){
				let aac=allactorclasses[i];
				if(
					(class<HDSkin>)(aac)
					&&aac.getclassname()==skinname[HDSKIN_SPRITE]
				){
					skinclass=(class<HDSkin>)(aac);
					break;
				}
			}
		}


		//set the sprites
		let defskinclass=getdefaultbytype(skinclass);
		let dds=defskinclass.spawnstate;
		if(dds!=null)standsprite=dds.sprite;
		dds=defskinclass.resolvestate("crouch");
		if(dds!=null)crouchsprite=dds.sprite;

		//test if this sound exists
		//otherwise you can cheat by defining an invalid name to get a silent character
		sound testsound="player/"..skinname[HDSKIN_VOICE].."/pain";

		//set the sounds
		if(
			int(testsound)<=0
			||skinname[HDSKIN_VOICE]==""
		){
			tauntsound=defskinclass.tauntsound;
			xdeathsound=defskinclass.xdeathsound;
			gruntsound=defskinclass.gruntsound;
			landsound=defskinclass.landsound;
			medsound=defskinclass.medsound;
			deathsound=defskinclass.deathsound;
			painsound=defskinclass.painsound;
		}else{
			tauntsound="player/"..skinname[HDSKIN_VOICE].."/taunt";
			xdeathsound="player/"..skinname[HDSKIN_VOICE].."/xdeath";
			gruntsound="player/"..skinname[HDSKIN_VOICE].."/grunt";
			landsound="player/"..skinname[HDSKIN_VOICE].."/land";
			medsound="player/"..skinname[HDSKIN_VOICE].."/meds";
			deathsound="player/"..skinname[HDSKIN_VOICE].."/death";
			painsound="player/"..skinname[HDSKIN_VOICE].."/pain";
		}

		//set the mugshot
		if(
			TexMan.CheckForTexture(skinname[HDSKIN_MUG].."st00",TexMan.Type_Any).Exists()
		)mugshot=skinname[HDSKIN_MUG];
		else switch(player.getgender()){
			case 0:mugshot="STF";break;
			case 1:mugshot="SFF";break;
			default:mugshot="STC";break;
		}
	}
}

//base skin actor
class HDSkin:Actor{
	sound
		tauntsound,
		xdeathsound,
		gruntsound,
		landsound,
		medsound;
	property tauntsound:tauntsound;
	property xdeathsound:xdeathsound;
	property gruntsound:gruntsound;
	property landsound:landsound;
	property medsound:medsound;
	string mug;
	property mug:mug;
	default{
		hdskin.tauntsound "*taunt";
		hdskin.xdeathsound "*xdeath";
		hdskin.gruntsound "*grunt";
		hdskin.landsound "*land";
		hdskin.medsound "*usemeds";
		deathsound "*death";
		painsound "*pain";
		hdskin.mug "STC";
	}
	states{
	spawn:PLAY A 0;stop;
	crouch:PLYC A 0;stop;
	}
}

//example syntax for a custom skin
//assets not included
class HDSampleCustomSkin:HDSkin{
	default{
		hdskin.tauntsound "player/oldfdguy/taunt";
		hdskin.xdeathsound "player/oldfdguy/xdeath";
		hdskin.gruntsound "player/oldfdguy/grunt";
		hdskin.landsound "player/oldfdguy/land";
		hdskin.medsound "player/oldfdguy/meds";
		deathsound "player/oldfdguy/death";
		painsound "player/oldfdguy/pain";
		hdskin.mug "FDF";
	}
	states{
	spawn:FRED A 0;stop;
	crouch:FREC A 0;stop;
	}
}


//test
class HDZombieSkin:HDSkin{
	default{
		hdskin.tauntsound "grunt/sight";
		hdskin.xdeathsound "grunt/death3";
		hdskin.gruntsound "grunt/active";
		hdskin.landsound "player/hdguy/land";
		hdskin.medsound "player/hdguy/meds";
		deathsound "grunt/death";
		painsound "grunt/pain";
		hdskin.mug "STC";
	}
	states{
	spawn:crouch:QGUY A -1;stop;
	}
}


class qguy:actor{
	states{
	spawn:
		QGUY A 10;
		PLAY A 10;
		loop;
	}
}

