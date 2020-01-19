// ------------------------------------------------------------
// Custom skin system
// ------------------------------------------------------------
extend class HDPlayerPawn{
	string lastskin;
	string mugshot;
	int standsprite;
	vector2 skinscale;
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
	void ApplyUserSkin(bool forced=false){
		if(
			!forced
			&&(
				!player
				||!hd_skin
			)
		)return;

		//apply sprite
		if(player.crouchfactor<0.75)sprite=crouchsprite;else sprite=standsprite;
		if(standsprite==crouchsprite)scale.y=skinscale.y*player.crouchfactor;

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
		standsprite=dds.sprite;
		dds=defskinclass.resolvestate("crouch");
		crouchsprite=dds.sprite;
		skinscale=defskinclass.scale;
		scale=skinscale;

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
extend class HDHandlers{
	void ShowSkins(hdplayerpawn ppp){
		string bbb="Available player skins (classname, soundclass (if any), mugshot (if any)):";
		for(int i=0;i<allactorclasses.size();i++){
			if(
				allactorclasses[i] is "HDSkin"
				&&allactorclasses[i]!="HDSkin"
			){
				let aac=getdefaultbytype((class<hdskin>)(allactorclasses[i]));
				bbb=bbb.."\n  "..aac.getclassname()
				.."  "..aac.soundclass
				.."  "..aac.mug;
				
			}
		}
		ppp.A_Log(bbb,true);
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
	string soundclass;
	property soundclass:soundclass;
	default{
		hdskin.tauntsound "*taunt";
		hdskin.xdeathsound "*xdeath";
		hdskin.gruntsound "*grunt";
		hdskin.landsound "*land";
		hdskin.medsound "*usemeds";
		deathsound "*death";
		painsound "*pain";
		hdskin.mug "<none>";
		hdskin.soundclass "<none>";
	}
	states{
	spawn:PLAY A 0;stop;
	crouch:PLYC A 0;stop;
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
	}
	states{
	spawn:crouch:POSS A 0;stop;
	}
}



/*
//example syntax for a custom skin
//assets not included
class HDQuakeSkin:HDSkin{
	default{
		hdskin.tauntsound "player/quakeguy/taunt";
		hdskin.xdeathsound "player/quakeguy/xdeath";
		hdskin.gruntsound "player/quakeguy/grunt";
		hdskin.landsound "player/quakeguy/land";
		hdskin.medsound "player/quakeguy/meds";
		hdskin.soundclass "quakeguy";
		deathsound "player/quakeguy/death";
		painsound "player/quakeguy/pain";
		//hdskin.mug "QGF";
	}
	states{
	spawn:QGUY A 0;stop;
	crouch:QGUY A 0;stop;
	}
}

//and a SNDINFO
player/quakeguy/taunt   dstauntm
player/quakeguy/xdeath  dsqdiehi
player/quakeguy/grunt   dsqnoway
player/quakeguy/land    dsland
player/quakeguy/meds    dsqpain
player/quakeguy/death   dsqdeth
player/quakeguy/pain    dsqpain
*/

