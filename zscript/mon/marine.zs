// ------------------------------------------------------------
// Molon labe, Games Workshop.
// ------------------------------------------------------------

/*
	SPECIAL NOTE FOR MAPPERS
	You can customize individual marines using the user_ variables:

	user_weapon may be set 1-4 for ZM66, shotgun, SMG or RL.
	user_colour may be set 1-3 for white, brown or black.
		(technically any number not 1 or 3 is brown)
		add 100 to force male, 200 to female; below 100 is random.

	Invert user_colour (e.g., -3 for dark skin) to use the tango red.
	Set an variable to zero to use the actor default. (HDMarine is random)
*/

class HDMarine:HDMobMan replaces ScriptedMarine{
	default{
		//$Category "Monsters/Hideous Destructor/Marines"
		//$Title "Marine"
		//$Sprite "PLAYA1"

		monster;
		+friendly
		+quicktoretaliate
		+hdmobbase.hashelmet
		speed 16;
		maxdropoffheight 48;
		maxstepheight 48;
		maxtargetrange 65536;
		minmissilechance 24;
		mass 150;
		seesound "marine/sight";
		painchance 240;
		obituary "$OB_MARINE";
		hitobituary "$OB_MARINEHIT";
		tag "$CC_MARINE";

		accuracy 0; //set to hdmw_*+1
		stamina 0; //+1 for setting
	}
	int user_weapon;
	int user_colour;
	double spread;
	double turnamount;
	int gunloaded;
	int gunmax;
	int gunspent;
	int pistolloaded;
	bool glloaded;
	int timesdied;
	bool jammed;
	int wep;
	double rocketdisttoenemy;
	override void die(actor source,actor inflictor,int dmgflags){
		if(
			bfriendly
			&&!bhasdropped
			&&!(self is "GhostMarine")
			&&!(self is "BotBot")
		)A_Log(string.format("\cf%s died.",nickname));
		timesdied++;
		super.die(source,inflictor,dmgflags);
	}
	override void beginplay(){
		super.beginplay();
		givensprite=getspriteindex("PLAYA1");
		bhasdropped=false;
		spread=0;
		timesdied=0;
		jammed=0;

		//weapon
		pistolloaded=15;
		glloaded=true;
		if(user_weapon)accuracy=user_weapon;
		wep=accuracy?accuracy:clamp(random(1,4)-random(0,3),1,4);

		if(wep==HDMW_ZM66)gunmax=50;
		else if(wep==HDMW_HUNTER)gunmax=8;
		else if(wep==HDMW_SMG)gunmax=30;
		else if(wep==HDMW_ROCKET)gunmax=6;
		gunloaded=gunmax;


		//appearance
		if(user_colour)stamina=user_colour;

		int voiceboxshape=abs(stamina);
		voiceboxshape=(voiceboxshape>=200)?2:((voiceboxshape>=100)?1:random(1,2));
		if(voiceboxshape==2){
			painsound="marinef/pain";
			deathsound="marinef/death";
		}else{
			painsound="marine/pain";
			deathsound="marine/death";
		}
		stamina%=100;

		string trnsl="";
		if(stamina<0||self is "Tango")trnsl="Tango";else{
			if(wep==HDMW_ZM66)trnsl="Rifleman";
			else if(wep==HDMW_HUNTER)trnsl="Enforcer";
			else if(wep==HDMW_SMG)trnsl="Infiltrator";
			else if(wep==HDMW_ROCKET)trnsl="Rocketeer";
		}

		int melanin=stamina?abs(stamina):random(1,3);
		if(melanin==1)trnsl=string.format("White%s",trnsl);
		else if(melanin==3)trnsl=string.format("Black%s",trnsl);
		else trnsl=string.format("Brown%s",trnsl);

		A_SetTranslation(trnsl);
	}
	string nickname;
	virtual string SetNickname(){
		if(!bfriendly){
			nickname="Anonymous";
			return nickname;
		}
		array<string>mnamebases;mnamebases.clear();
		string mmmn=Wads.ReadLump(Wads.CheckNumForName("marinenames",0));
		mmmn=mmmn.left(mmmn.indexof("\n---"));
		mmmn.split(mnamebases,"\n");

		nickname="";
		do{nickname=mnamebases[random(0,mnamebases.size()-1)];}
		while(nickname=="");

		bool isunique;
		array<string> nicknames;nicknames.clear();
		for(int i=0;i<MAXPLAYERS;i++){
			if(playeringame[i])nicknames.push(players[i].getusername());
		}
		hdmarine nmm;
		thinkeriterator nmit=thinkeriterator.create("HDMarine",STAT_DEFAULT);
		while(nmm=hdmarine(nmit.Next(exact:false))){
			if(nmm!=self)nicknames.push(nmm.nickname);
		}
		do{
			isunique=random(0,15);
			for(int i=0;i<nicknames.size();i++){
				if(nickname==nicknames[i]){
					isunique=false;
					nickname=nickname..random(0,999);
				}
			}
		}while(!isunique);

		if(!random(0,3)){
			array<string>titles;titles.clear();
			string titleset=Wads.ReadLump(Wads.CheckNumForName("marinenames",0));
			titleset=titleset.mid(titleset.indexof("\n---")+5);
			titleset=titleset.left(titleset.indexof("\n---"));
			titleset.split(titles,"\n");
			string title="";
			do{title=titles[random(0,titles.size()-1)];}
			while(title=="");

			title.replace(" ","_");
			if(!random(0,2))title.replace("_","");
			title.replace("NNN",nickname);
			nickname=title;
		}
		if(!random(0,16))nickname.makeupper();
		else if(!random(0,16))nickname.makelower();
		if(!random(0,7)){
			array<string>titles;titles.clear();
			string titleset=Wads.ReadLump(Wads.CheckNumForName("marinenames",0));
			titleset=titleset.mid(titleset.indexof("\n---")+5);
			titleset=titleset.mid(titleset.indexof("\n---")+5);
			if(titleset!=""){
				titleset.split(titles,"\n");
				string title="";
				do{title=titles[random(0,titles.size()-1)];}
				while(title=="");
				title.replace("NNN",nickname);
				nickname=title;
			}
		}

		return nickname;
	}
	virtual void A_HDMScream(){
		A_Scream();
	}
	int givensprite;
	override void postbeginplay(){
		super.postbeginplay();
		hdmobster.spawnmobster(self);
		givearmour(1.,0.12,0.6);
		SetNickname();
	}
	int lastinginjury;
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(
			health>0
			&&damage>=health
			&&mod!="raisedrop"
			&&mod!="spawndead"
			&&damage<random(12,300-(lastinginjury<<1))
			&&(
				(mod=="bleedout"&&random(0,12))
				||(random(0,2))
			)
		){
			lastinginjury+=max((mod=="bashing"?0:1),(damage>>5));
			damage=health-5;
		}
		return super.damagemobj(inflictor,source,damage,mod,flags,angle);
	}
	override void deathdrop(){
		if(bhasdropped){
			class<actor> dropammo="";
			if(wep==HDMW_SMG)dropammo="HD9mMag30";
			else if(wep==HDMW_ZM66)dropammo="HD4mMag";
			else if(wep==HDMW_ROCKET)dropammo="HDRocketAmmo";
			else if(wep==HDMW_HUNTER)dropammo="ShellPickup";
			if(!random(0,timesdied))A_DropItem(dropammo);
			if(!random(0,12+timesdied))A_DropItem("HD9mMag15");
			if(
				!random(0,timesdied)&&wep==HDMW_SMG
			)A_DropItem("HDRocketAmmo");
		}else{
			bhasdropped=true;
			hdweapon dropped=null;
			if(wep==HDMW_SMG){
				dropped=hdweapon(spawn("HDSMG",pos,ALLOW_REPLACE));
				if(gunloaded){
					dropped.weaponstatus[SMGS_MAG]=gunloaded-1;
					dropped.weaponstatus[SMGS_CHAMBER]=2;
				}else{
					dropped.weaponstatus[SMGS_MAG]=0;
					dropped.weaponstatus[SMGS_CHAMBER]=0;
				}
			}else if(wep==HDMW_ZM66){
				dropped=hdweapon(spawn("ZM66AssaultRifle",pos,ALLOW_REPLACE));
				if(gunloaded){
					dropped.weaponstatus[ZM66S_MAG]=gunloaded-1;
					dropped.weaponstatus[0]|=ZM66F_CHAMBER;
				}else{
					dropped.weaponstatus[ZM66S_MAG]=0;
					dropped.weaponstatus[0]&=~ZM66F_CHAMBER;
				}
				if(jammed||!random(0,15))dropped.weaponstatus[0]|=ZM66F_CHAMBERBROKEN;
				if(glloaded)dropped.weaponstatus[0]|=ZM66F_GRENADELOADED;
			}else if(wep==HDMW_ROCKET){
				dropped=hdweapon(spawn("HDRL",pos,ALLOW_REPLACE));
				if(gunloaded){
					dropped.weaponstatus[RLS_MAG]=gunloaded-1;
					dropped.weaponstatus[RLS_CHAMBER]=1;
				}else{
					dropped.weaponstatus[RLS_MAG]=0;
					dropped.weaponstatus[RLS_CHAMBER]=0;
				}
			}else if(wep==HDMW_HUNTER){
				dropped=hdweapon(spawn("Hunter",pos,ALLOW_REPLACE));
				if(gunloaded){
					dropped.weaponstatus[HUNTS_TUBE]=gunloaded-1;
					dropped.weaponstatus[HUNTS_CHAMBER]=2;
				}else{
					dropped.weaponstatus[HUNTS_TUBE]=0;
					dropped.weaponstatus[HUNTS_CHAMBER]=0;
				}
				dropped.weaponstatus[SHOTS_SIDESADDLE]=random(0,12);
				dropped.weaponstatus[HUNTS_FIREMODE]=1;
				if(!random(0,31))dropped.weaponstatus[0]|=HUNTF_CANFULLAUTO;
				else dropped.weaponstatus[0]&=~HUNTF_CANFULLAUTO;
			}
			dropped.addz(32);
			dropped.vel=vel+(frandom(-1,1),frandom(-1,1),2);

			//drop the pistol
			dropped=hdweapon(spawn("HDPistol",pos,ALLOW_REPLACE));
			dropped.addz(32);
			dropped.vel=vel+(frandom(-1,1),frandom(-1,1),2);
			if(pistolloaded){
				dropped.weaponstatus[PISS_MAG]=pistolloaded-1;
				dropped.weaponstatus[PISS_CHAMBER]=2;
			}else{
				dropped.weaponstatus[PISS_MAG]=0;
				dropped.weaponstatus[PISS_CHAMBER]=0;
			}

			//drop the blooper
			if(wep!=HDMW_SMG&&wep!=HDMW_HUNTER)return;
			dropped=hdweapon(spawn("Blooper",pos,ALLOW_REPLACE));
			dropped.addz(32);
			dropped.vel=vel+(frandom(-1,1),frandom(-1,1),2);
			if(glloaded)dropped.weaponstatus[0]|=BLOPF_LOADED;
		}
	}

	//returns true if area around target is clear of friendlies
	bool A_CheckBlast(actor tgt=null,double checkradius=256){
		if(!tgt)tgt=target;
		if(!tgt)return true;
		blockthingsiterator itt=blockthingsiterator.create(tgt,checkradius);
		while(itt.next()){
			actor it=itt.thing;
			if(
				it.health>0&&
				(isfriend(it)||isteammate(it))
			)return false;
		}
		return true;
	}

	// #### E 1 A_LeadTarget1();
	// #### E 3{
	//	A_LeadTarget2(shotspeed:getdefaultbytype(missilename).speed);
	//	hdmobai.DropAdjust(self,missilename);
	// }
	// #### F 1 bright light("SHOT") A_MarineShot(missilename);
	// maybe generalize this later?
	vector2 leadoldaim;vector2 leadaim;
	vector2 A_LeadTarget1(){
		if(!target){
			leadoldaim=(angle,pitch);
			return leadoldaim;
		}
		vector2 aimbak=(angle,pitch);
		A_FaceTarget(0,0);
		leadoldaim=(angle,pitch);
		angle=aimbak.x;pitch=aimbak.y;
		return leadoldaim;
	}
	vector2 A_LeadTarget2(
		double dist=-1,
		double shotspeed=20,
		vector2 oldaim=(-1,-1),
		double adjusttics=1
	){
		if(!target||!shotspeed)return(0,0);

		//get current angle for final calculation
		vector2 aimbak=(angle,pitch);

		//distance defaults to distance from target
		if(dist<0)dist=distance3d(target);

		//figure out how many tics to adjust
		double ticstotarget=dist/shotspeed+adjusttics;
		if(ticstotarget<1.)return(0,0);

		//retrieve result from A_LeadTarget1
		if(oldaim==(-1,-1))oldaim=leadoldaim;

		//check the aim to change and revert immediately
		//I could use angleto but the pitch calculations would be awkward
		A_FaceTarget(0,0);
		vector2 aimadjust=(
			deltaangle(oldaim.x,angle),
			deltaangle(oldaim.y,pitch)
		);

		//something fishy is going on
		if(abs(aimadjust.x)>45)return (0,0);

		//multiply by tics
		aimadjust*=ticstotarget;

		//apply and return
		angle=aimbak.x+aimadjust.x;pitch=aimbak.y+aimadjust.y;
		return aimadjust;
	}
	actor A_MarineShot(class<actor> missiletype,bool userocket=false){
		actor mmm=spawn(missiletype,pos+(0,0,height-6),ALLOW_REPLACE);
		mmm.pitch=pitch+frandom(0,spread)-frandom(0,spread);
		mmm.angle=angle+frandom(0,spread)-frandom(0,spread);
		mmm.target=self;

		//one very special case
		if(userocket&&mmm is "GyroGrenade")gyrogrenade(mmm).isrocket=true;
		else userocket=false;

		if(!(mmm is "SlowProjectile"))mmm.A_ChangeVelocity(
			mmm.speed*cos(mmm.pitch),0,mmm.speed*sin(mmm.pitch),CVF_RELATIVE
		);
		return mmm;
	}
	//replaces with zombie if dying while zombie-sprited
	void A_DeathZombieZombieDeath(){
		if(
			sprite==getspriteindex("POSSA1")
			||sprite==getspriteindex("SPOSA1")
		){
			actor zzz=spawn("ZombieStormtrooper",pos,ALLOW_REPLACE);
			zzz.vel=vel;
			zzz.A_Die("extreme");
			destroy();
		}
	}
	enum HDMarineStats{
		HDMW_RANDOM=0,
		HDMW_ZM66=1,
		HDMW_HUNTER=2,
		HDMW_SMG=3,
		HDMW_ROCKET=4,

		HDMBC_WARPLIMIT=4,
	}
	bool checkedin;
	states{
	spawn:
		PLAY A 0{sprite=givensprite;}
		#### AA 4{hdmobai.wander(self);}
		#### A 0 A_Look();
		#### BB 4{hdmobai.wander(self);}
		#### A 0 A_Look();
		#### CC 4{hdmobai.wander(self);}
		#### A 0 A_Look();
		#### DD 4{hdmobai.wander(self);}
	spawn2:
		#### A 0 A_Jump(60,"spawn");
		#### A 0{angle+=random(-30,30);}
		#### EEE 3 A_Look();
		#### A 0{angle+=random(-30,30);}
		#### EEE 3 A_Look();
		#### A 0 A_Jump(60,"spawn");
		loop;
	see:
		#### A 0{if(target)rocketdisttoenemy=distance2d(target);}
		#### AABBCCDD 2{
			hdmobai.chase(self,
				flee:(wep==HDMW_ROCKET&&rocketdisttoenemy<720)
			);
		}
		#### A 0{
			speed=max(0,16-random((lastinginjury>>1),lastinginjury));
			if(lastinginjury>0&&!random(0,50+lastinginjury))lastinginjury--;

			A_SetSolid();
			if(
				(
					//must reload
					!gunloaded
					&&(!pistolloaded||!random(0,3))
				)||(
					//may reload
					!random(0,7)
					&&(
						gunloaded<1
						||pistolloaded<1
						||(wep!=HDMW_ROCKET&&!glloaded)
					)
					&&(!target||!checksight(target))
				)
			)setstatelabel("reload");
		}
		#### E 0 A_JumpIfTargetInLOS("see");
	spwander:
		#### E 0 A_ClearTarget();
		#### AA 3{hdmobai.wander(self);}
		#### A 0 A_Chase("melee","missile",CHF_DONTMOVE);
		#### BB 3{hdmobai.wander(self);}
		#### A 0 A_Chase("melee","missile",CHF_DONTMOVE);
		#### CC 3{hdmobai.wander(self);}
		#### A 0 A_Chase("melee","missile",CHF_DONTMOVE);
		#### DD 3{hdmobai.wander(self);}
		#### E 0 A_Jump(128,"spwander");
	spwander2:
		#### A 0 A_Look();
		#### A 0 A_Jump(4,"spawn");
		#### A 0{angle+=random(-30,30);}
		#### EEE 2 A_Chase("melee","missile",CHF_DONTMOVE);
		#### A 0{angle+=random(-30,30);}
		#### EEE 2 A_Chase("melee","missile",CHF_DONTMOVE);
		#### A 0 A_Jump(60,"spwander");
		#### E 0 A_JumpIfTargetInLOS("see");
		---- A 0 setstatelabel("spwander");

	missile:
		#### A 0{
			if(
				(
					//must reload
					!gunloaded
					&&!pistolloaded
				)
			)setstatelabel("reload");
		}
		#### A 0 A_JumpIfTargetInLOS(3,120);
		#### CD 3 A_FaceTarget(40);
	missile2:
		#### A 0{
			if(!target){
				setstatelabel("noshot");
				return;
			}
			double dist=distance3d(target);
			if(dist<500)turnamount=20;
			else if(dist<1200)turnamount=10;
			else if(dist<2400)turnamount=3;
			else turnamount=1;
		}
	turntoaim:
		#### E 2 A_FaceTarget(turnamount,turnamount);
		#### A 0 A_JumpIfTargetInLOS(2);
		---- A 0 setstatelabel("see");
		#### A 0 A_JumpIfTargetInLOS(1,10);
		loop;
		#### A 0 A_FaceTarget(turnamount,turnamount);
		#### E 1 A_SetTics(random(1,int(100/max(1,turnamount))));
		#### E 0{
			spread=turnamount*0.08;
			A_SetTics(int(16/spread));
			spread+=min(timesdied,15);
		}
		//fallthrough to shoot
	shoot:
		#### E 1{
			if(!target||(checksight(target)&&target.health<1)){
				target=null;
				setstatelabel("noshot");
				return;
			}
			A_FaceTarget(0,0); //can't lead without this
			double dist=distance3d(target);

			int settics=clamp(int(dist*0.002),0,30);
			if(lastinginjury>0)settics+=random(0,min(lastinginjury,(35*5)));
			A_SetTics(settics);
		}
		#### E 4{
			if(!target)return;
			double dist=distance3d(target);
			if(
				!hdmobai.tryshoot(self,
					range:min(1024,dist*1.1),
					pradius:min(target.radius*0.6,4),
					pheight:min(target.height*0.6,4)
				)
			){
				return;
			}
			if(lastinginjury>0){
				double lic=min(lastinginjury,10);
				angle+=frandom(-0.4,0.4)*lic;
				pitch+=frandom(-0.5,0.2)*lic;
			}

			//grenade
			if(
				dist<5000
				&&dist>600
				&&(
					(wep==HDMW_ROCKET&&gunloaded>0)
					||(glloaded&&!random(0,10))
				)
			){
				setstatelabel("shootgl");
				return;
			}

			//pistol
			if(
				gunloaded<1
				||(wep==HDMW_ROCKET&&dist<600)
			){
				if(pistolloaded<1||!random(0,3))setstatelabel("ohforfuckssake");
				else setstatelabel("shootpistol");
				return;
			}

			//all other guns
			if(wep==HDMW_SMG)setstatelabel("shootsmg");
			else if(wep==HDMW_HUNTER)setstatelabel("shootsg");
			else if(wep==HDMW_ZM66)setstatelabel("shootzm66");
			else if(wep==HDMW_ROCKET)setstatelabel("shootrl");
		}
		---- A 0 setstatelabel("see");
	shootzm66:
		#### E 1;
		#### E 1 A_LeadTarget1();
		#### E 1{
			if(jammed){
				setstatelabel("unjam");
				return;
			}
			class<actor> mn="HDB_426";
			A_LeadTarget2(shotspeed:getdefaultbytype(mn).speed,adjusttics:1);
			hdmobai.DropAdjust(self,mn);
			gunspent=min(gunloaded,randompick(1,1,1,1,1,3));
		}
	firezm66:
		#### FFF 1 bright light("SHOT"){
			if(gunloaded<1||gunspent<1)setstatelabel("firezm66end");
			gunloaded--;gunspent--;
			A_StartSound("weapons/rifle",CHAN_WEAPON);
			HDBulletActor.FireBullet(self,"HDB_426");
			if(!random(0,1999-gunspent)){
				jammed=true;
				setstatelabel("unjam");
			}
		}
	firezm66end:
		#### E 2 A_AlertMonsters(0,bfriendly?AMF_TARGETEMITTER:0);
		#### E 0 A_JumpIf(gunloaded>0&&random(0,2),"firezm66");
		#### E 0 A_MonsterRefire(20,"see");
		---- A 0 setstatelabel("missile");
	shootsmg:
		#### E 1 A_LeadTarget1();
		#### E 1{
			class<actor> mn="HDB_9";
			A_LeadTarget2(shotspeed:getdefaultbytype(mn).speed,adjusttics:1);
			hdmobai.DropAdjust(self,mn);
		}
	firesmg:
		#### F 1 bright light("SHOT"){
			gunloaded--;
			A_StartSound("weapons/smg",CHAN_WEAPON,volume:0.7);
			HDBulletActor.FireBullet(self,"HDB_9",speedfactor:1.1);
			if(!random(0,7))A_AlertMonsters(0,bfriendly?AMF_TARGETEMITTER:0);
		}
		#### E 2 A_SpawnItemEx("HDSpent9mm",
			cos(pitch)*10,0,height-8-sin(pitch)*10,
			vel.x,vel.y,vel.z,
			0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
		#### E 0 A_JumpIf(gunloaded>0&&random(0,2),"firesmg");
		#### E 0 A_MonsterRefire(20,"see");
		---- A 0 setstatelabel("missile");
	shootsg:
		#### E 1;
		#### E 1 A_LeadTarget1();
		#### E 1{
			class<actor> mn="HDB_00";
			A_LeadTarget2(shotspeed:getdefaultbytype(mn).speed,adjusttics:1);
			hdmobai.DropAdjust(self,mn);
		}
		#### F 1 bright light("SHOT"){
			gunloaded--;
			A_AlertMonsters(0,bfriendly?AMF_TARGETEMITTER:0);

			//semi is for nubs
			Hunter.Fire(self);
		}
		#### E 1{
			if(random(0,4)){
				gunspent=0;
				A_SpawnItemEx("HDSpentShell",
					cos(pitch)*8,0,height-7-sin(pitch)*8,
					vel.x+cos(pitch)*cos(angle-random(86,90))*6,
					vel.y+cos(pitch)*sin(angle-random(86,90))*6,
					vel.z+sin(pitch)*random(5,7),0,
					SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}else gunspent=1;
		}
		#### E 1{
			if(gunspent){
				gunspent=0;
				A_StartSound("weapons/huntrack",8);
				A_SetTics(random(4,6));
				A_SpawnItemEx("HDSpentShell",
					cos(pitch)*8,0,height-7-sin(pitch)*8,
					vel.x+cos(pitch)*cos(angle-random(86,90))*6,
					vel.y+cos(pitch)*sin(angle-random(86,90))*6,
					vel.z+sin(pitch)*random(5,7),0,
					SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
				);
			}
		}
		#### E 0 A_MonsterRefire(20,"see");
		---- A 0 setstatelabel("missile");
	shootrl:
		#### E 2;
		#### E 1{
			if(A_CheckBlast(target))A_LeadTarget1();
			else setstatelabel("noshot");
		}
		#### E 1{
			class<actor> mn="GyroGrenade";
			A_LeadTarget2(shotspeed:getdefaultbytype(mn).speed*6.4,adjusttics:1);
			hdmobai.DropAdjust(self,mn,speedmult:6.4);
		}
		#### F 2 bright light("SHOT"){
			if(wep==HDMW_ROCKET)gunloaded--;else glloaded=false;
			A_StartSound("weapons/rockignite",CHAN_WEAPON);
			A_StartSound("weapons/bronto",CHAN_WEAPON,CHANF_OVERLAP);
			A_MarineShot("GyroGrenade",userocket:true);
			A_AlertMonsters(0,bfriendly?AMF_TARGETEMITTER:0);
		}
		#### E 5{
			A_Recoil(-4);
			A_StartSound("weapons/rocklaunch",CHAN_WEAPON,CHANF_OVERLAP,0.6);
		}
		#### E 0 A_StartSound("weapons/huntrack",8);
		---- A 0 setstatelabel("see");
	shootgl:
		#### E 1{
			if(A_CheckBlast(target))A_LeadTarget1();
			else setstatelabel("noshot");
		}
		#### E 2{
			class<actor> mn="GyroGrenade";
			A_LeadTarget2(shotspeed:getdefaultbytype(mn).speed,adjusttics:2);
			hdmobai.DropAdjust(self,mn);
		}
		#### F 1 bright{
			if(wep==HDMW_ROCKET)gunloaded--;else glloaded=false;
			A_StartSound("weapons/grenadeshot",CHAN_WEAPON);
			A_MarineShot("GyroGrenade");
		}
		#### E 4;
		#### E 0 A_MonsterRefire(20,"see");
		---- A 0 setstatelabel("missile");

	shootpistol:
		#### E 1 A_LeadTarget1();
		#### E 1{
			class<actor> mn="HDB_9";
			A_LeadTarget2(shotspeed:getdefaultbytype(mn).speed,adjusttics:random(1,4));
			hdmobai.DropAdjust(self,mn);
		}
		#### F 1 bright light("SHOT"){
			pistolloaded--;
			A_StartSound("weapons/pistol",CHAN_WEAPON);
			HDBulletActor.FireBullet(self,"HDB_9",spread:2.,speedfactor:frandom(0.97,1.03));
			if(!random(0,3))A_AlertMonsters(0,bfriendly?AMF_TARGETEMITTER:0);
		}
		#### E random(1,4) A_SpawnItemEx("HDSpent9mm",
			cos(pitch)*12,0,height-7-sin(pitch)*12,
			vel.x,vel.y,vel.z,
			0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
		);
		#### E 0 A_MonsterRefire(20,"see");
		---- A 0 setstatelabel("missile");
	noshot:
		#### E 6;
		---- A 0 setstatelabel("see");

	unjam:
		#### E 10;
		#### E 0{
			if(gunloaded>0){
				let ooo=HDMagAmmo(spawn("HD4mMag",pos+(0,0,40),ALLOW_REPLACE));
				ooo.vel+=vel;
				ooo.mags.clear();
				ooo.mags.push(gunloaded);
				ooo.amount=1;
				gunloaded=-1;
			}else if(!random(0,3)){
				jammed=false;
				A_StartSound("weapons/rifleclick",8);
				if(!random(0,5))A_SpawnItemEx("HDSmokeChunk",12,0,height-12,4,frandom(-2,2),frandom(2,4));
				A_SpawnItemEx("BulletPuffBig",12,0,42,1,0,1);
				setstatelabel("reload");
			}
		}
		#### ABCD 3{hdmobai.chase(self,"melee",null,true);}
		loop;

	ohforfuckssake:
		#### E 4 A_StartSound("weapons/rifleclick2",8);
		---- A 0 setstatelabel("reload");

	reload:
		#### A 0{
			if(
				pistolloaded<1
				||wep==HDMW_SMG
				||wep==HDMW_ZM66
			)setstatelabel("reloadmag");
			else if(gunloaded<gunmax){
				if(wep==HDMW_HUNTER)setstatelabel("reloadsg");
				if(wep==HDMW_ROCKET)setstatelabel("reloadrl");
			}else if(!glloaded&&wep!=HDMW_ROCKET)setstatelabel("reloadgl");
		}---- A 0 setstatelabel("see");
	reloadsg:
		#### A 0 A_StartSound("weapons/huntopen",8);
		#### AB 3{hdmobai.chase(self,"melee",null,true);}
	reloadsgloop:
		#### A 0 A_StartSound("weapons/pocket",9);
		#### CDAB 3{hdmobai.chase(self,"melee",null,true);}
		#### BBC 3{
			if(!random(0,1))hdmobai.chase(self,"melee",null,true);
			if(gunloaded<gunmax){
				gunloaded++;
				A_StartSound("weapons/sshotl",8);
			}
		}
		#### A 0 A_JumpIf(gunloaded<gunmax,"reloadsgloop");
		---- A 0 setstatelabel("see");
	reloadrl:
		#### A 0 A_StartSound("weapons/rifleclick2",8);
		#### AB 3{hdmobai.chase(self,"melee",null,true);}
	reloadrlloop:
		#### A 0 A_StartSound("weapons/pocket",9);
		#### CDAB 3{hdmobai.chase(self,"melee",null,true);}
		#### C 4{
			if(!random(0,3))hdmobai.chase(self,"melee",null,true);
			if(gunloaded<gunmax){
				gunloaded++;
				A_StartSound("weapons/rockreload",8,CHANF_OVERLAP);
			}
		}
		#### A 0 A_JumpIf(gunloaded<gunmax,"reloadsgloop");
		---- A 0 setstatelabel("see");
	reloadmag:
		#### AB 3{hdmobai.chase(self,"melee",null,true);}
		#### C 3{
			hdmobai.chase(self,"melee",null,true);
			A_StartSound("weapons/rifleclick",8);
			A_StartSound("weapons/rifleload",8,CHANF_OVERLAP);
			name oldthing="";
			if(
				pistolloaded<1
				&&(
					gunloaded<1
					||wep!=HDMW_SMG
					||wep!=HDMW_ZM66
				)
			)oldthing="HD9mMag15";
			else if(wep==HDMW_SMG)oldthing="HD9mMag30";
			else if(wep==HDMW_ZM66){
				if(jammed){
					setstatelabel("unjam");
					return;
				}
				oldthing="HD4mMag";
			}
			if(oldthing)HDMagAmmo.SpawnMag(self,oldthing,0);
		}
		#### DABC 3{hdmobai.chase(self,"melee",null,true);}
		#### D 2 A_StartSound("weapons/rifleload",8);
		#### A 3{
			A_StartSound("weapons/rifleclick",8,CHANF_OVERLAP);
			hdmobai.chase(self,"melee",null);
			if(
				pistolloaded<1
				&&(
					gunloaded<1
					||wep!=HDMW_SMG
					||wep!=HDMW_ZM66
				)
			)pistolloaded=15;
			else gunloaded=gunmax;
		}
		---- A 0 setstatelabel("see");
	reloadgl:
		#### A 0 A_StartSound("weapons/grenopen",8);
		#### ABCD 3{hdmobai.chase(self,"melee",null,true);}
		#### AB 2 A_StartSound("weapons/rockreload",8);
		#### C 3{
			A_StartSound("weapons/grenopen",CHAN_WEAPON,CHANF_OVERLAP);
			hdmobai.chase(self,"melee",null);
			glloaded=1;
		}
		#### D 4;
		---- A 0 setstatelabel("see");

	melee:
		#### C 7 A_FaceTarget();
		#### D 2;
		#### E 6 A_CustommeleeAttack(
			random(10,100),"weapons/smack","","none",randompick(0,0,0,1)
		);
		#### ABCD 2{
			if(target&&!target.bcorpse&&distance3d(target)-target.radius<meleerange){
				setstatelabel("melee");
				return;
			}
			if(gunloaded>0){
				setstatelabel("missile");
				return;
			}
			A_FaceTarget(0,0);
			A_Recoil(-3);
		}---- A 0 setstatelabel("see");
	pain:
		#### G 3;
		#### G 3 A_Pain();
		#### G 0 A_Jump(100,"see");
		#### AB 2 A_FaceTarget(50,50);
		#### CD 3 A_ChangeVelocity(
			frandom(-1,1),
			frandom(1,max(0,5-lastinginjury*0.1))*randompick(-1,1),
			0,CVF_RELATIVE
		);
		#### G 0 A_CPosRefire();
		#### E 0 A_Jump(256,"missile");

	death.bleedout:
		#### HI 5;
		---- A 0 setstatelabel("deathpostscream");
	death:
		---- A 0 A_DeathZombieZombieDeath();
		#### H 5;
		#### I 5 A_HDMScream();
	deathpostscream:
		#### JK 5;
		---- A 0 setstatelabel("dead");

	dead:
		#### K 3 canraise A_JumpIf(abs(vel.z)<2.,1);
		loop;
		#### LMN 5 canraise A_JumpIf(abs(vel.z)>=2.,"dead");
		wait;
	raise:
		#### A 0{
			nickname=LightBearer.randomname();

			lastinginjury=random(0,(lastinginjury>>3));
			A_SetSolid();
		}
		#### MMK 7 A_SpawnItemEx("MegaBloodSplatter",0,0,4,
			vel.x,vel.y,vel.z,0,
			SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
		);
		#### JHE 4;
		#### H 0{
			scale.x=1;
			if(!random(0,15+timesdied))return;
			else if(!random(0,10-timesdied))A_Die("raisebotch");
			else{
				speed=max(1,speed-random(0,1));
				damagemobj(
					self,self,
					min(random(0,3*timesdied),health-1),
					"balefire",
					DMG_NO_PAIN|DMG_NO_FACTOR|DMG_THRUSTLESS
				);
				seesound="grunt/sight";
				painsound="grunt/pain";
				deathsound="grunt/death";
				A_StartSound(seesound,CHAN_VOICE);
			}
		}---- A 0 setstatelabel("see");

	xdeath:
		---- A 0 A_DeathZombieZombieDeath();
		#### O 5;
		#### P 5{
			A_SpawnItemEx("MegaBloodSplatter",0,0,34,flags:SXF_NOCHECKPOSITION);
			A_XScream();
		}
		#### Q 5 A_SpawnItemEx("MegaBloodSplatter",0,0,34,flags:SXF_NOCHECKPOSITION);
		#### Q 0 A_SpawnItemEx("MegaBloodSplatter",0,0,34,flags:SXF_NOCHECKPOSITION);
		#### RSTUV 5;
	xdead:
		#### W -1 canraise;
		stop;
	death.raisebotch:
	xxxdeath:
		---- A 0{
			bodydamage=666;
			A_DeathZombieZombieDeath();
		}
		#### O 5;
		#### P 5 A_XScream();
		#### QRSTUV 5;
		#### W -1 canraise;
		stop;
	ungib:
		#### W 0 A_JumpIf((random(1,12)-timesdied)<5,"RaiseZombie");
		#### WW 8;
		#### VUT 7;
		#### SRQ 5;
		#### POH 4;
		---- A 0 setstatelabel("checkraise");
	raisezombie:
		#### U 4 A_UnsetShootable();
		#### U 8;
		#### T 4;
		#### T 2 A_StartSound("weapons/bigcrack",16);
		#### T 0{
			if(bplayingid)sprite=getspriteindex("POSS");
			else{
				sprite=getspriteindex("SPOS");
				A_SetTranslation("FreedoomGreycoat");
			}
		}
		#### S 2 A_StartSound("misc/wallchunks",17);
		#### AAAAA 0 A_SpawnItemEx("HugeWallChunk",0,0,40,random(4,6),0,random(-2,7),random(1,360));
		#### SRQ 6;
		#### PONMH 4;
		#### IJKL 4;
		#### M 0 spawn("DeadZombieStormtrooper",pos,ALLOW_REPLACE);
		stop;
		POSS SRQPONMHIJKL 0;
		SPOS SRQPONMHIJKL 0;
		stop;
	}
}

class Rifleman:HDMarine{
	default{
		//$Category "Monsters/Hideous Destructor/Marines"
		//$Title "Marine (Rifle)"
		//$Sprite "PLAYA1"
		accuracy HDMW_ZM66;
}}
class BlackRifleman:Rifleman{default{stamina 3;}}
class BrownRifleman:Rifleman{default{stamina 2;}}
class WhiteRifleman:Rifleman{default{stamina 1;}}
class RifleFistman:Rifleman replaces MarineFist{}
class RifleChaingunman:Rifleman replaces MarineChaingun{}

class Enforcer:HDMarine{
	default{
		//$Category "Monsters/Hideous Destructor/Marines"
		//$Title "Marine (Shotgun)"
		//$Sprite "PLAYA1"
		accuracy HDMW_HUNTER;
}}
class BlackEnforcer:Enforcer{default{stamina 3;}}
class BrownEnforcer:Enforcer{default{stamina 2;}}
class WhiteEnforcer:Enforcer{default{stamina 1;}}
class EnforcerShot:Enforcer replaces MarineShotgun {}
class EnforcerSuperShot:Enforcer replaces MarineSSG {}
class EnforcerNoShot:Enforcer replaces MarineBerserk {}

class Infiltrator:HDMarine{
	default{
		//$Category "Monsters/Hideous Destructor/Marines"
		//$Title "Marine (SMG)"
		//$Sprite "PLAYA1"
		accuracy HDMW_SMG;
}}
class BlackInfiltrator:Infiltrator{default{stamina 3;}}
class BrownInfiltrator:Infiltrator{default{stamina 2;}}
class WhiteInfiltrator:Infiltrator{default{stamina 1;}}
class InfiltratorPistol:Infiltrator replaces MarinePistol{}
class InfiltratorChainsaw:Infiltrator replaces MarineChainsaw{}

class Rocketeer:HDMarine{
	default{
		//$Category "Monsters/Hideous Destructor/Marines"
		//$Title "Marine (Rocket)"
		//$Sprite "PLAYA1"
		accuracy HDMW_ROCKET;
}}
class BlackRocketeer:Rocketeer{default{stamina 3;}}
class BrownRocketeer:Rocketeer{default{stamina 2;}}
class WhiteRocketeer:Rocketeer{default{stamina 1;}}
class RRocketeer:Rocketeer replaces MarineRocket{}
class BFuglyteer:Rocketeer replaces MarineBFG{}
class Plasmateer:Rocketeer replaces MarinePlasma{}
class Railgunteer:Rocketeer replaces MarineRailgun{}


class Tango:HDMarine{
	default{
		//$Category "Monsters/Hideous Destructor/Marines"
		//$Title "Tango"
		//$Sprite "PLAYA1"
		-friendly
}}
class BlackTango:Tango{default{stamina 3;}}
class BrownTango:Tango{default{stamina 2;}}
class WhiteTango:Tango{default{stamina 1;}}

class RifleTango:Tango{
	default{
		//$Category "Monsters/Hideous Destructor/Marines"
		//$Title "Tango (Rifle)"
		//$Sprite "PLAYA1"
		accuracy HDMW_ZM66;
}}
class BlackRifleTango:RifleTango{default{stamina 3;}}
class BrownRifleTango:RifleTango{default{stamina 2;}}
class WhiteRifleTango:RifleTango{default{stamina 1;}}

class ShotTango:Tango{
	default{
		//$Category "Monsters/Hideous Destructor/Marines"
		//$Title "Tango (Shotgun)"
		//$Sprite "PLAYA1"
		accuracy HDMW_HUNTER;
}}
class BlackShotTango:ShotTango{default{stamina 3;}}
class BrownShotTango:ShotTango{default{stamina 2;}}
class WhiteShotTango:ShotTango{default{stamina 1;}}

class SMGTango:Tango{
	default{
		//$Category "Monsters/Hideous Destructor/Marines"
		//$Title "Tango (SMG)"
		//$Sprite "PLAYA1"
		accuracy HDMW_SMG;
}}
class BlackSMGTango:SMGTango{default{stamina 3;}}
class BrownSMGTango:SMGTango{default{stamina 2;}}
class WhiteSMGTango:SMGTango{default{stamina 1;}}

class RocketTango:Tango{
	default{
		//$Category "Monsters/Hideous Destructor/Marines"
		//$Title "Tango (Rocket)"
		//$Sprite "PLAYA1"
		accuracy HDMW_ROCKET;
}}
class BlackRocketTango:RocketTango{default{stamina 3;}}
class BrownRocketTango:RocketTango{default{stamina 2;}}
class WhiteRocketTango:RocketTango{default{stamina 1;}}



// ------------------------------------------------------------
// Marine corpse
// ------------------------------------------------------------
class UndeadRifleman:HDMarine{
	default{
		//$Category "Monsters/Hideous Destructor/"
		//$Title "Undead Marine"
		//$Sprite "PLAYA1"
		-friendly
	}
	override void postbeginplay(){
		super.postbeginplay();
		givearmour(0.6,0.12,0.1);
		timesdied+=random(1,3);
		bhasdropped=true;
		speed=max(1,speed-random(0,2));
		damagemobj(
			self,self,
			min(random(0,3*timesdied),health-1),
			"balefire",
			DMG_NO_PAIN|DMG_NO_FACTOR|DMG_THRUSTLESS
		);
		seesound="grunt/sight";
		painsound="grunt/pain";
		deathsound="grunt/death";
	}
}
class DeadRifleman:HDMarine replaces DeadMarine{
	override void postbeginplay(){
		super.postbeginplay();
		A_TakeInventory("HDArmourWorn");
		bhasdropped=true;
		A_Die("spawndead");
	}
	states{
	death.spawndead:
		---- A 0 givearmour(0.6,0.12,0.1);
		---- A 0 setstatelabel("dead");
	}
}
class ReallyDeadRifleman:DeadRifleman replaces GibbedMarine{
	states{
	death.spawndead:
		---- A 1;
		---- A 0{
			A_UnsetShootable();
			timesdied++;
			bodydamage=2000;
			bgibbed=true;
		}
		---- A 0 setstatelabel("xdead");
	}
}
class DeadRiflemanCrouched:DeadRifleman{
	states{
	death.spawndead:
		PLYC A 0;
		goto super::death.spawndead;
	raise:
		PLAY A 0;
		goto super::raise;
	}
}
class ReallyDeadRiflemanCrouched:ReallyDeadRifleman replaces GibbedMarineExtra{
	states{
	death.spawndead:
		PLYC A 0;
		goto super::death.spawndead;
	raise:
		PLAY A 0;
		goto super::raise;
	}
}




// ------------------------------------------------------------
// You have no authority to order them around, but...
// ------------------------------------------------------------
extend class HDMarine{
	static void PlayerCheckIn(actor caller){
		if(!caller||!caller.player||caller.health<1)return;
		string msg=string.format(
			"%s\cd: Operator reporting in at [%i,%i].",
			caller.player.getusername(),caller.pos.x,caller.pos.y
		);
		HDTeamSay(caller,msg,true);
	}
	static void HDTeamSay(actor caller,string msg,bool includeself=false){
		for(int i=0;i<MAXPLAYERS;i++){
			if(
				playeringame[i]
				&&(includeself||!caller.player||players[i]!=caller.player)
				&&players[i].mo
				&&(
					caller.isfriend(players[i].mo)
					||caller.isteammate(players[i].mo)
				)
			){
				actor pmo=players[i].mo;
				pmo.A_StartSound("misc/chat",CHAN_VOICE,CHANF_UI|CHANF_NOPAUSE|CHANF_LOCAL);
				pmo.A_Log(msg,true);
			}
		}
	}
	static void CallCheckIn(actor caller){
		if(!caller.player)return;
		HDTeamSay(caller,string.format("%s\cd: Report in, team.",caller.player.getusername()),true);
		//all players check in
		for(int i=0;i<MAXPLAYERS;i++){
			PlayerCheckIn(players[i].mo);
		}
		//all HDMarines check in
		hdmarine nmm;
		thinkeriterator nmit=thinkeriterator.create("HDMarine",STAT_DEFAULT);
		while(nmm=hdmarine(nmit.Next(exact:false))){
			if(
				nmm.isfriend(caller)
				||nmm.isteammate(caller)
			)nmm.HDMCheckIn();
		}
	}
	virtual void HDMCheckIn(){
		if(
			health<1
			||(!bfriendly&&random(0,15))
		)return;
		int x;int y;
		if(!bfriendly){
			nickname="Anonymous";
			x=random(-32700,32700);
			y=random(-32700,32700);
		}

		string msg=string.format(
			"%s\cd: Operator reporting in at [%i,%i].",
			nickname,pos.x,pos.y
		);

		for(int i=0;i<MAXPLAYERS;i++){
			if(
				playeringame[i]
				&&players[i].mo
				&&(
					isfriend(players[i].mo)
					||isteammate(players[i].mo)
				)
			){
				if(target&&target.health>0)msg.appendformat(
					" I need some backup."
				);
				actor pmo=players[i].mo;
				if(checksight(pmo)||distance3d(pmo)<512)msg.appendformat(
					" I'm right here, watch your fire!"
				);
				pmo.A_StartSound("misc/chat",CHAN_VOICE,CHANF_UI|CHANF_NOPAUSE|CHANF_LOCAL);
				pmo.A_Log(msg,true);
			}
		}
	}
}




// ------------------------------------------------------------
// Raging Erech shun.
// ------------------------------------------------------------
class GhostMarine:HDMobBase{
	bool A_GhostShot(actor victim){
		if(!victim||absangle(angle,angleto(victim))>20)return false;
		bool np=victim.bnopain;
		bool nf=victim.bnofear;
		if(np&&nf){
			target=null;
			return false;
		}

		int tmp=victim.painchance;
		int tmpt=victim.painthreshold;
		victim.givebody(1);
		victim.painchance=256;
		victim.painthreshold=0;
		victim.bnopain=false;
		victim.bnofear=false;
		victim.bfrightened=true;
		victim.damagemobj(self,self,1,
			"GhostSquadAttack",DMG_THRUSTLESS|DMG_NO_ARMOR|DMG_NO_FACTOR
		);

		//in case target destroyed
		if(!victim)return true;

		//reset
		victim.painchance=tmp;
		victim.painthreshold=tmpt;
		victim.bnopain=np;
		victim.bnofear=nf;
		return true;
	}
	int gonnaleave;
	override void beginplay(){
		super.beginplay();
		gonnaleave=0;

		//appearance
		if(master&&teamplay){
			translation=master.translation;
		}else{
			string trnsl="Rifleman";

			int melanin=random(0,2);
			if(!melanin)trnsl=string.format("White%s",trnsl);
			else if(melanin==1)trnsl=string.format("Brown%s",trnsl);
			else if(melanin==2)trnsl=string.format("Black%s",trnsl);

			A_SetTranslation(trnsl);
		}

		if(random(0,1)){
			painsound="marinef/pain";
			deathsound="marinef/death";
		}else{
			painsound="marine/pain";
			deathsound="marine/death";
		}
	}
	default{
		+noblooddecals
		+shootable +noblockmonst +ghost +shadow -solid
		+nopain +nofear +seeinvisible +nodamage +nonshootable
		+noclip
		+frightening
		+friendly
		damagefactor "GhostSquadAttack",0;
		maxdropoffheight 40;
		maxstepheight 40;
		health 200000000;
		gibhealth 500;
		renderstyle "add";
		bloodtype "NullPuff";
		seesound "imp/sight";
		height 52;
		radius 7;
		speed 8;
		dropitem "SquadSummoner",8;
	}
	states{
	spawn:
		PLAY A 0;
		#### E 10 A_Look();
		wait;
	see:
		#### AABBCCDD 2 A_Chase();
		#### A 0{
			if(!random(0,7))A_AlertMonsters(0,AMF_TARGETEMITTER);
			A_ClearTarget();
			givebody(spawnhealth());
			gonnaleave++;
			if(gonnaleave>=360)A_Die("fade");
		}loop;
	death.fade:
		#### A 0 A_NoBlocking();
	fade:
		#### ABCD 2{
			A_Wander();
			A_FadeOut(0.1);
		}loop;
	missile:
		#### E 1{
			if(bfriendly)A_AlertMonsters(0,AMF_TARGETEMITTER);
			if(!deathmatch)gonnaleave=0;
			A_SetTics(random(0,3));
		}
	missile2:
		#### E 3 A_FaceTarget(0,0);
		#### F 1 bright light("SHOT"){
			if(!A_GhostShot(target)){
				A_SetTics(0);
				return;
			}
			A_StartSound("weapons/bigrifle",CHAN_WEAPON);
			pitch+=frandom(-1,1);
			if(!random(0,7))A_AlertMonsters(0,AMF_TARGETEMITTER);
		}
		#### E 6 A_SetTics(random(1,4));
		#### A 0 A_MonsterRefire(20,"see");
		---- A 0 setstatelabel("missile2");
	melee:
		#### E 0{
			if(!deathmatch)gonnaleave=0;
		}
		#### C 8 A_FaceTarget(0,0);
		#### D 4;
		#### E 4{
			if(target&&distance3d(target)<56&&A_GhostShot(target)){
				A_StartSound("weapons/smack",CHAN_WEAPON);
			}
		}
		#### E 4 A_FaceTarget(0,0);
		---- A 0 setstatelabel("see");

	pain:
		#### G 4;
		#### G 4 A_Pain();
		#### G 0 A_Jump(100,"see");
		#### AB 2 A_FaceTarget(0,0);
		#### CD 3 A_FastChase();
		#### G 0 A_CPosRefire();
		#### E 0 A_Jump(256,"missile");
	death:
	xdeath:
		#### H 6;
		#### I 6 A_Scream();
		#### J 6 A_NoBlocking();
		#### KKKLLLMMM 2 A_FadeOut(0.1);
		#### N 2 A_FadeOut(0.1);
		wait;
	raise:
		stop;
	}
}
class GhostGyroGrenade:GyroGrenade{
	default{
		 +forcepain +nodamage
		renderstyle "add";
		damagetype "GhostSquadAttack";
	}
	override void ExplodeSlowMissile(line blockingline,actor blockingobject){
		let gm=GhostMarine(target);
		if(!gm)return;
		actor tb=gm.target;
		blockthingsiterator itt=blockthingsiterator.create(self,512);
		while(itt.next()){
			actor it=itt.thing;
			if(
				!gm.isfriend(it)
				&&!gm.isteammate(it)
			){
				gm.A_GhostShot(it);
			}
		}
		gm.target=tb;
		bmissile=false;
		setstatelabel("death");
	}
	states{
	death:
		TNT1 A 0{gravity=0;}
		TNT1 AAAAAAAAAAAA 0 A_SpawnItemEx(
			"HugeWallChunk",0,0,0,
			random(-7,7),random(-7,7),random(4,18),
			random(0,360),160
		);
		TNT1 AA 0 A_SpawnItemEx("HDExplosion",
			random(-1,1),random(-1,1),2,
			flags:SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
		);
		TNT1 A 2 A_SpawnItemEx("HDExplosion",zvel:2,
			flags:SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
		);
		TNT1 AAA 0 A_SpawnItemEx("HDSmoke",
			random(-6,6),random(-6,6),1,
			random(-1,4),random(-1,1),0,
			random(-15,15),SXF_NOCHECKPOSITION
		);
		TNT1 A 21{
			A_AlertMonsters();
			DistantNoise.Make(self,"world/rocketfar");
			A_Quake(2,21,0,200,"none");
		}stop;
	}
}

class SquadSummoner:HDPickup{
	default{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Summoning Talisman"
		//$Sprite "PRIFA0"

		+forcexybillboard
		-hdpickup.droptranslation
		inventory.maxamount 7;
		inventory.interhubamount 7;
		inventory.icon "PLHELMA0";
		inventory.pickupsound "misc/p_pkup";
		inventory.pickupmessage "Picked up a summoning talisman.";
		hdpickup.bulk ENC_SQUADSUMMONER;
		tag "summoning talisman";
	}
	states{
	spawn:
		PRIF A -1;
	use:
		TNT1 A 0{
			A_StartSound("misc/p_pkup",CHAN_AUTO,attenuation:ATTN_NONE);
			A_AlertMonsters();
			A_SpawnItemEx("GhostMarine",0,0,0,-8,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER);
			A_SpawnItemEx("GhostMarine",0,0,0,0,5,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER);
			A_SpawnItemEx("GhostMarine",0,0,0,0,-5,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER);
			A_SpawnItemEx("HDSmoke",0,0,0,8,0,0,0,SXF_NOCHECKPOSITION);
			A_SpawnItemEx("HDSmoke",0,0,0,0,5,0,0,SXF_NOCHECKPOSITION);
			A_SpawnItemEx("HDSmoke",0,0,0,0,-5,0,0,SXF_NOCHECKPOSITION);

			string deadawaken;
			int da=random(0,3);
			if(da==0)deadawaken="\cj'They shall stand again and hear there\n\cja horn in the hills ringing.\n\n\cjWhose shall the horn be?'";
			else if(da==1)deadawaken="\cj'For this war will last through years uncounted\n\n\cjand you shall be summoned once again ere the end.'";
			else if(da==2)deadawaken="\cj'Faint cries I heard,and dim horns blowing,\n\n\cjand a murmur as of countless far voices:\n\n\n\cjit was like the echo of some forgotten battle\n\n\cjin the Dark Years long ago.'";
			else if(da==3)deadawaken="\cj'Pale swords were drawn; but I know not\n\n\cjwhether their blades would still bite,\n\n\n\cjfor the Dead needed no longer\n\n\cjany weapon but fear.'";

			A_PrintBold(deadawaken,deadawaken.length()*0.05,"NewSmallFont");
		}stop;
	}
}




// ------------------------------------------------------------
// A replacement.
// ------------------------------------------------------------
class BotBot:HDMarine{
	default{
		+noblockmonst
		+nofear
		species "Player";
		obituary "%o died.";
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(!bfriendly)return super.damagemobj(inflictor,source,damage,mod,flags,angle);

		//abort if zero team damage, otherwise save factor for wounds and burns
		if(
			source
			&&source!=self
			&&(
				isteammate(source)
				||(
					!deathmatch&&
					(source.player||botbot(source))
				)
			)
		){
			if(!teamdamage)return 0;
			else damage=int(damage*teamdamage);
		}

		lastmod=mod;
		return super.damagemobj(
			inflictor,source,damage,mod,flags,angle
		);
	}
	name lastmod;
	override void Die(actor source,actor inflictor,int dmgflags){
		super.Die(source,inflictor,dmgflags);
		if(masterplayer>=0){
			actor rpp=players[masterplayer].mo;
			if(rpp){
				rpp.A_SetShootable();
				rpp.damagemobj(inflictor,source,rpp.health,lastmod,dmgflags|DMG_FORCED);
				rpp.A_UnsetShootable();
			}
		}
	}
	int warptimer;
	int unseen;
	bool seen;
	vector3 oldppos;
	override void tick(){
		super.tick();
		if(
			masterplayer<1
			||health<1
		)return;
		actor rpp=players[masterplayer].mo;
		if(rpp){
			rpp.setorigin((
				pos.xy+angletovector(angle,1),
				pos.z+height-8
			),true);
			rpp.A_SetAngle(angle,SPF_INTERPOLATE);
			rpp.A_SetPitch(pitch,SPF_INTERPOLATE);
		}

		if(!bfriendly||timesdied>0||target){
			unseen=0;
			return;
		}

		warptimer++;
		if(!(warptimer%35)){
			seen=false;
			warptimer=0;
			for(int i=0;i<MAXPLAYERS;i++){
				if(
					playeringame[i]&&!players[i].bot&&players[i].mo
					&&checksight(players[i].mo)
				){
					seen=true;
					unseen=0;
				}
			}
			if(!seen)unseen++;
			if(unseen==HDMBC_WARPLIMIT){
				gunloaded=gunmax;
				glloaded=true;
				pistolloaded=15;
				for(int i=0;i<MAXPLAYERS;i++){
					if(
						playeringame[i]&&!players[i].bot&&players[i].mo
					){
						oldppos=players[i].mo.pos;
						break;
					}
				}
			}else if(unseen>HDMBC_WARPLIMIT){
				vector3 posbak=pos;
				setorigin(oldppos,false);
				for(int i=0;i<MAXPLAYERS;i++){
					if(
						playeringame[i]&&!players[i].bot&&players[i].mo
						&&(absangle(
							players[i].mo.angle,
							players[i].mo.angleto(self)
						)<100)
					){
						seen=true;
						unseen--;
					}
				}
				if(unseen>HDMBC_WARPLIMIT+3){
					unseen=0;
					seen=true;
					warptimer=0;
					A_StartSound(seesound,CHAN_VOICE);
					spawn("HDSmoke",pos,ALLOW_REPLACE);
				}else{
					setorigin(posbak,false);
				}
			}
		}
	}
	override void A_HDMScream(){
		if(master)master.A_PlayerScream();
		master=null;masterplayer=-1;
		if(hd_disintegrator){
			A_SpawnItemEx("Telefog",0,0,0,vel.x,vel.y,vel.z,0,SXF_ABSOLUTEMOMENTUM);
			destroy();
		}
	}
	int masterplayer;
	override void postbeginplay(){
		super.postbeginplay();
		givearmour(1.,0.12,1.);
		if(!master){
			for(int i=0;i<MAXPLAYERS;i++){
				if(playeringame[i]&&players[i].mo){
					master=players[i].mo;
					break;
				}
			}
		}
		masterplayer=master.playernumber();

		int pgend;
		if(playeringame[masterplayer])pgend=players[masterplayer].getgender();
		else pgend=random(0,3);
		if(!pgend){
			painsound="marine/pain";
			deathsound="marine/death";
		}
		else if(pgend==1){
			painsound="marinef/pain";
			deathsound="marinef/death";
		}
		else if(pgend==2){
			painsound="marineb/pain";
			deathsound="marineb/death";
		}

		nickname=players[masterplayer].getusername();
	}
	//nick should be the player's nick
	override string SetNickname(){return gettag();}
	//don't do anything, let the playerpawn do the reporting instead
	override void HDMCheckIn(){}
}




