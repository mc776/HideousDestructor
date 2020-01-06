// ------------------------------------------------------------
// Vulcanette Guy
// ------------------------------------------------------------
class HDChainReplacer:RandomSpawner replaces ChaingunGuy{
	default{
		dropitem "VulcanetteGuy",256,6;
		dropitem "UndeadRifleman",256,2;
		dropitem "EnemyHERP",256,1;
		dropitem "EnemyDERP",256,1;
	}
}class VulcanetteGuy:HDMobMan{
	default{
		radius 14;
		height 54;
		painchance 170;
		monster;
		+floorclip
		seesound "chainguy/sight";
		painsound "chainguy/pain";
		deathsound "chainguy/death";
		activesound "chainguy/active";
		tag "$cc_heavy";

		health 120;
		speed 9;
		mass 200;
		maxtargetrange 6000;
		obituary "%o met the budda-budda-budda on the street, and it killed %h.";
		hitobituary "%o took the wrong pill.";
		hdmobbase.downedframe 11;
	}
	bool turnleft;
	bool superauto;
	int thismag;
	int mags;
	int chambers;
	int burstcount;
	vector2 coverdir;
	override void postbeginplay(){
		super.postbeginplay();
		hdmobster.spawnmobster(self);
		chambers=5;
		burstcount=random(4,20);
		superauto=randompick(0,0,0,1);
		mags=4;
		thismag=50;
		bhashelmet=!bplayingid;
		bnoincap=bplayingid;

		if(bplayingid)givearmour(1.,0.06,-0.4);
		else givearmour(1.,0.2,-0.4);
	}
	void A_ScanForTargets(){
		if(noammo()){
			setstatelabel("reload");
			return;
		}

		int c=-2;
		double oldangle=angle;
		double oldpitch=pitch;
		while(
			c<=1
		){
			c++;
			//shoot a line out
			flinetracedata hlt;
			int ccc=0;
			double aimangle=oldangle+frandom(-4,4);
			double aimpitch=oldpitch+c*2+frandom(-4,4);
			do{
				ccc++;
				linetrace(
					aimangle+frandom(-2,2),16384,aimpitch+frandom(-2,2),
					flags:TRF_NOSKY,
					offsetz:40,
					data:hlt
				);
			}while(!hlt.hitactor&&ccc<4);

			//if the line hits a valid target, go into shooting state
			actor hitactor=hlt.hitactor;
			if(hitactor&&(
				hitactor==target
				||(
					isHostile(hitactor)
					&&hitactor.bshootable
					&&!hitactor.bnotarget
					&&!hitactor.bnevertarget
					&&(hitactor.bismonster||hitactor.player)
					&&(!hitactor.player||!(hitactor.player.cheats&CF_NOTARGET))
					&&hitactor.health>random(-4,5)
				)
			)){
				if(!target||target.health<1)target=hitactor;
				angle=aimangle+frandom(-1,1);
				pitch=aimpitch+frandom(-1,1);
				burstcount=random(3,max(8,hitactor.health/10));
				setstatelabel("scanshoot");
				return;
			}
		}
		if(turnleft)angle+=frandom(3,4);
		else angle-=frandom(3,4);
	}
	bool noammo(){
		return chambers<1&&thismag<1&&mags<1;
	}
	void A_VulcGuyShot(){
		//abort if burst is over
		if(
			burstcount<1
			||noammo()
		){
			burstcount=random(3,5);
			setstatelabel("postshot");
			return;
		}

		//check for ammo
		if(
			thismag<1
			&&mags>0
		){
			setstatelabel("shuntmag");
			return;
		}
		if(chambers<1)setstatelabel("chamber");

		//shoot the bullet
		A_StartSound("weapons/vulcanette",CHAN_WEAPON,CHANF_OVERLAP);
		HDBulletActor.FireBullet(self,"HDB_426",spread:2,distantsounder:"DistantVulc");
		pitch+=frandom(-0.4,0.3);angle+=frandom(-0.3,0.3);
		burstcount--;
		chambers--;

		//cycle the next round
		if(chambers<5 && thismag){
			thismag--;
			chambers++;
			A_StartSound("weapons/rifleclick2",8);
		}
	}
	void A_TurnTowardsTarget(
		statelabel shootstate="shoot",
		double maxturn=13,
		double maxvariance=10
	){
		A_FaceTarget(maxturn,maxturn);
		if(
			!target
			||maxvariance>absangle(angle,angleto(target))
			||!checksight(target)
		)setstatelabel(shootstate);
		if(bfloat||floorz>=pos.z)A_ChangeVelocity(0,frandom(-0.1,0.1)*speed,0,CVF_RELATIVE);
	}
	override void deathdrop(){
		if(!bhasdropped){
			bhasdropped=true;
			A_DropItem("HDBattery",0,16);
			A_DropItem("HDHandgunRandomDrop");
			vulcanette vvv=vulcanette(spawn("vulcanette",pos+(0,0,32),ALLOW_REPLACE));
			if(!vvv)return;
			vvv.vel=vel;vvv.angle=angle;
			vvv.A_ChangeVelocity(1,0,2,CVF_RELATIVE);
			for(int i=0;i<5;i++){
				if(!i){
					vvv.setmagcount(i,thismag);
				}else if(mags>0){
					vvv.setmagcount(i,VULC_MAG_FULLSEALED);
					mags--;
				}else vvv.setmagcount(i,0);
				vvv.weaponstatus[0]|=VULCF_CHAMBER1;
				vvv.weaponstatus[0]|=VULCF_CHAMBER2;
				vvv.weaponstatus[0]|=VULCF_CHAMBER3;
				vvv.weaponstatus[0]|=VULCF_CHAMBER4;
				vvv.weaponstatus[0]|=VULCF_CHAMBER5;
				if(!random(0,3))vvv.weaponstatus[0]&=VULCF_BROKEN1;
				if(!random(0,3))vvv.weaponstatus[0]&=VULCF_BROKEN2;
				if(!random(0,3))vvv.weaponstatus[0]&=VULCF_BROKEN3;
				if(!random(0,3))vvv.weaponstatus[0]&=VULCF_BROKEN4;
				if(!random(0,3))vvv.weaponstatus[0]&=VULCF_BROKEN5;
			}
			if(superauto)vvv.weaponstatus[0]|=VULCF_FAST;
			vvv.weaponstatus[VULCS_BATTERY]=random(1,20);
			vvv.weaponstatus[VULCS_BREAKCHANCE]=random(0,random(1,500));
			vvv.weaponstatus[VULCS_ZOOM]=random(16,70);
		}else if(!bfriendly){
			A_DropItem("HD4mMag",0,96);
			A_DropItem("HD4mMag",0,96);
			A_DropItem("HDBattery",0,8);
		}
	}
	states{
	spawn:
		CPOS B 1 nodelay{
			A_Look();
			A_Recoil(random(-1,1)*0.1);
			A_SetTics(random(10,40));
		}
		CPOS BB 1{
			A_Look();
			A_SetTics(random(10,40));
		}
		CPOS A 8{
			if(bambush)setstatelabel("spawnhold");
			else if(!random(0,1))setstatelabel("spawnstill");
			else A_Recoil(random(-1,1)*0.2);
		}loop;
	spawnhold:
		CPOS G 1{
			A_Look();
			if(!random(0,8))A_Recoil(random(-1,1)*0.4);
			A_SetTics(random(10,30));
			if(!random(0,8))A_StartSound(activesound,CHAN_VOICE);
		}wait;
	spawnstill:
		CPOS C 0 A_Jump(128,"scan","scan","spawnwander");
		CPOS C 0{
			A_Look();
			A_Recoil(random(-1,1)*0.4);
		}
		CPOS CD 5{angle+=random(-4,4);}
		CPOS AB 5{
			A_Look();
			if(!random(0,15))A_StartSound(activesound,CHAN_VOICE);
			angle+=random(-4,4);
		}
		CPOS B 1 A_SetTics(random(10,40));
		---- A 0 setstatelabel("spawn");
	spawnwander:
		CPOS A 0 A_Look();
		CPOS CD 5 A_Wander();
		CPOS AB 5{
			A_Look();
			if(!random(0,15))A_StartSound(activesound,CHAN_VOICE);
			A_Wander();
		}
		CPOS A 0 A_Jump(196,"spawn");
		loop;
	see2:
		CPOS A 0{
			if(!mags&&thismag<1)setstatelabel("reload");
			else bfrightened=0;
		}
		CPOS AABBCCDD 3 {hdmobai.chase(self,flags:CHF_NOPOSTATTACKTURN);}
		CPOS A 0 A_Jump(196,"see2");
		---- A 0 setstatelabel("scan");
	missile:
		CPOS ABCD 3 A_TurnTowardsTarget("aim");
		loop;
	aim:
		CPOS E 4{
			if(target){
				coverdir=(angleto(target),atan2(pos.z-target.pos.z,distance2d(target)));
				if(target.spawnhealth()>random(50,1000))superauto=true;
			}
		}
		CPOS E 0 A_TurnTowardsTarget("scanshoot",5,5);
		loop;
	see:
	scan:
		CPOS E 2{
			turnleft=randompick(0,0,0,1);
			if(turnleft)angle-=frandom(18,24);
			else angle+=frandom(18,24);
		}
	scanturn:
		CPOS EEEEEE 3 A_ScanForTargets();
		CPOS E 0 A_Jump(32,"scanturn","scanturn","scan");
		---- A 0 setstatelabel("see2");
	scanshoot:
		CPOS E 1{
			angle+=frandom(-2,2);
			pitch+=frandom(-2,2);
		}
		//fallthrough to shoot
	shoot:
		CPOS F 1 bright light("SHOT") A_VulcGuyShot();
		CPOS E 2 A_JumpIf(superauto,"shoot");
		loop;
	postshot:
		CPOS E 1{
			turnleft=randompick(0,0,0,1);
			if(turnleft)angle-=frandom(3,6);
			else angle+=frandom(3,6);
		}
	considercover:
		CPOS E 0 A_JumpIf(thismag<1&&mags<1,"reload");
		CPOS E 0 A_JumpIf(target&&target.health>0&&!checksight(target),"cover");
		CPOS E 3 A_ScanForTargets();
		---- A 0 setstatelabel("scan");
	cover:
		CPOS E 0 A_JumpIf(
			!target
			||target.health<1
			||hdmobai.tryshoot(self,pradius:6,pheight:6),
			"see"
		);
		CPOS E 0{
			superauto=randompick(0,0,0,0,0,0,1);
			angle+=clamp(coverdir.x-angle,-20,20);
			pitch=clamp(coverdir.y-angle,-20,20);
			if(!random(0,99))setstatelabel("see");
		}
		CPOS EEEEEEEEEEEE 1 A_JumpIf(
			!target
			||checksight(target)
			||!random(0,20)
		,"scanshoot");
		loop;
	shuntmag:
		CPOS E 1;
		CPOS E 3{
			A_StartSound("weapons/vulcshunt",8);
			if(thismag>=0){
				actor mmm=HDMagAmmo.SpawnMag(self,"HD4mMag",0);
				mmm.A_ChangeVelocity(3,frandom(-3,2),frandom(0,-2),CVF_RELATIVE|CVF_REPLACE);
			}
			thismag=-1;
			if(mags>0){
				mags--;
				thismag=50;
			}
		}
		---- A 0 setstatelabel("shoot");
	chamber:
		CPOS E 3{
			if(chambers<5&&thismag>0){
				thismag--;
				chambers++;
				A_StartSound("weapons/rifleclick2",8,CHANF_OVERLAP);
			}
		}
		---- A 0 setstatelabel("shoot");

	reload:
		CPOS A 0{
			if(!target||!checksight(target))setstatelabel("loadamag");
			bfrightened=true;
		}
		CPOS AABBCCDD 3 A_Chase(null,null);
	loadamag:
		CPOS E 9 A_StartSound("weapons/pocket",9);
		CPOS E 7 A_StartSound("weapons/rifleload",8);
		CPOS E 10{
			if(thismag<0)thismag=50;
			else if(mags<4)mags++;
			else{
				setstatelabel("see2");
				return;
			}A_StartSound("weapons/rifleclick2",8);
		}loop;

	melee:
		CPOS DAB 2 A_FaceTarget(10,10);
		CPOS C 6 A_FaceTarget();
		CPOS D 2;
		CPOS E 3 A_CustomMeleeAttack(
			random(9,99),"weapons/smack","","none",randompick(0,0,0,1)
		);
		CPOS E 2 A_JumpIfTargetInsideMeleeRange(2);
		---- A 0 setstatelabel("considercover");
		CPOS E 0 A_JumpIf(target.health<random(-3,1),"see");
		CPOS EC 2;
		---- A 0 setstatelabel("melee");

	pain:
		CPOS G 3;
		CPOS G 3 A_Pain();
		CPOS G 0 A_Jump(196,"see","scan");
		---- A 0 setstatelabel("missile");


	death:
		CPOS H 5;
		CPOS I 5{
			A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
			A_Scream();
		}
		CPOS J 5 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		CPOS KL 5;
		CPOS M 5;
	dead:
		CPOS M 3;
		CPOS N 5 canraise{
			if(abs(vel.z)>1)setstatelabel("dead");
		}wait;
	xxxdeath:
		CPOS LKO 3;
		CPOS P 3{
			A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
			A_XScream();
		}
		CPOS R 2;
		CPOS QRS 5;
		---- A 0 setstatelabel("xdead");

	xdeath:
		CPOS O 5;
		CPOS P 3{
			A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
			A_XScream();
		}
		CPOS R 2 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		CPOS Q 5;
		CPOS Q 0 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		CPOS RS 5 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
	xdead:
		CPOS S 3;
		CPOS T 5 canraise{
			if(abs(vel.z)>1)setstatelabel("dead");    
		}wait;
	raise:
		CPOS N 2 A_SpawnItemEx("MegaBloodSplatter",0,0,4,0,0,3,0,SXF_NOCHECKPOSITION);
		CPOS NML 6;
		CPOS KJIH 4;
		---- A 0 setstatelabel("checkraise");
	ungib:
		CPOS T 6 A_SpawnItemEx("MegaBloodSplatter",0,0,4,0,0,3,0,SXF_NOCHECKPOSITION);
		CPOS TS 12 A_SpawnItemEx("MegaBloodSplatter",0,0,4,0,0,3,0,SXF_NOCHECKPOSITION);
		CPOS RQ 7;
		CPOS POH 5;
		---- A 0 setstatelabel("checkraise");
	}
}
