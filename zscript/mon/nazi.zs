// ------------------------------------------------------------
// born to forever sucker fruit hawaiian in the motherfuckin
// ------------------------------------------------------------
class HoopBubble:HDMobMan replaces WolfensteinSS{
	default{
		seesound "wolfss/sight";
		painsound "wolfss/pain";
		deathsound "wolfss/death";
		activesound "wolfss/active";
		tag "$cc_wolfss";

		painchance 170;

		obituary "%o invoked Godwin's Law.";
		translation "192:207=103:111","240:247=5:8";
	}
	override void postbeginplay(){
		super.postbeginplay();
		hdmobster.spawnmobster(self);
		gunloaded=31;
		if(!bplayingid){
			scale=(0.81,0.81);
		}
		givearmour(1.);
	}
	double spread;
	double turnamount;
	int gunloaded;
	override void deathdrop(){
		hdweapon wp=null;
		if(!bhasdropped){
			A_DropItem("HDHandgunRandomDrop");
			bhasdropped=true;
			if(wp=hdweapon(spawn("HDSMG",pos,ALLOW_REPLACE))){
				wp.weaponstatus[SMGS_AUTO]=2;
				wp.weaponstatus[SMGS_MAG]=random(0,30);
				wp.weaponstatus[SMGS_CHAMBER]=2;
			}
			A_DropItem("HD9mMag30");
		}else if(!bfriendly){
			A_DropItem("HD9mMag30",0,240);
			A_DropItem("HD9mMag30",0,128);
		}
	}
	states{
	spawn:
		SSWV EE 1{
			A_Look();
			A_Recoil(frandom(-0.1,0.1));
			A_SetTics(random(10,40));
		}
		SSWV B 0 A_Jump(16,"spawnstretch");
		SSWV B 0 A_Jump(116,"spawnwander");
		SSWV B 8 A_Recoil(frandom(-0.2,0.2));
		loop;
	spawnstretch:
		SSWV H 1{
			A_Recoil(frandom(-0.4,0.4));
			A_SetTics(random(30,80));
			if(!random(0,3))A_StartSound("grunt/active",CHAN_VOICE);
		}
		---- A 0 setstatelabel("spawn");
	spawnstill:
		SSWV A 0 A_Look();
		SSWV A 0 A_Recoil(frandom(-0.4,0.4));
		SSWV CD 5 A_SetAngle(angle+frandom(-4.,4.));
		SSWV A 0 A_Look();
		SSWV A 0 A_Jump(192,2);
		SSWV A 0 A_StartSound("grunt/active",CHAN_VOICE);
		SSWV AB 5 A_SetAngle(angle+frandom(-4.,4.));
		SSWV A 0 A_Look();
		SSWV B 1 A_SetTics(random(10,40));
		---- A 0 setstatelabel("spawn");
	spawnwander:
		SSWV CDAB 5{
			hdmobai.wander(self);
			if(!random(0,72))A_StartSound("grunt/active",CHAN_VOICE);
		}
		---- A 0 setstatelabel("spawn");
	see:
		SSWV A 0 A_JumpIf(gunloaded<2,"reload");
		SSWV ABCD 4{hdmobai.chase(self);}
		SSWV A 0 A_JumpIfTargetInLOS("see");
		---- A 0 setstatelabel("roam");
	roam:
		#### E 3 A_Jump(60,"roam2");
		#### E 0{spread=1;}
		#### EEEE 1 A_Chase("melee","turnaround",CHF_DONTMOVE);
		#### E 0{spread=0;}
		#### EEEEEEEEEEEEE 1 A_Chase("melee","turnaround",CHF_DONTMOVE);
		#### A 0 A_Jump(60,"roam");
	roam2:
		#### A 0 A_Jump(8,"see");
		#### A 5{hdmobai.chase(self);}
		#### BC 5{hdmobai.wander(self,true);}
		#### D 5{hdmobai.chase(self);}
		#### A 0 A_Jump(140,"Roam");
		#### A 0 A_AlertMonsters();
		#### A 0 A_JumpIfTargetInLOS("see");
		loop;
	turnaround:
		#### A 0 A_FaceTarget(15,0);
		#### E 2 A_JumpIfTargetInLOS("missile2",40);
		#### E 0{spread=3;}
		#### A 0 A_FaceTarget(15,0);
		#### E 0{spread=6;}
		#### E 2 A_JumpIfTargetInLOS("missile2",40);
		#### E 0{spread=4;}
		#### ABCD 3{hdmobai.chase(self);}
		---- A 0 setstatelabel("see");
	pain:
		SSWV H 3;
		SSWV H 3 A_Pain();
		SSWV A 0 A_Jump(192,"see");
		SSWV A 0 A_AlertMonsters();
		---- A 0 setstatelabel("see");
	missile:
		#### A 0 A_JumpIf(gunloaded<1,"reload");
		#### A 0 A_JumpIfTargetInLOS(3,120);
		#### CDE 1 A_FaceTarget(90);
		#### F 1 A_SetTics(random(4,10)); //when they just start to aim,not for followup shots!
		#### A 0 A_JumpIfTargetInLOS("missile2");
		#### A 0 A_CheckLOF("see",
			CLOFF_JUMPNONHOSTILE|CLOFF_SKIPTARGET|
			CLOFF_JUMPOBJECT|CLOFF_MUSTBESOLID|
			CLOFF_SKIPENEMY,
			0,0,0,0,44,0
		);
	missile2:
		#### A 0{
			if(!target){
				setstatelabel("spawn");
				return;
			}
			double enemydist=distance3d(target);
			if(enemydist<200)turnamount=50;
			else if(enemydist<600)turnamount=30;
			else turnamount=10;
		}goto turntoaim;
	turntoaim:
		#### E 2 A_FaceTarget(turnamount,turnamount);
		#### A 0 A_JumpIfTargetInLOS(2);
		---- A 0 setstatelabel("see");
		#### A 0 A_JumpIfTargetInLOS(1,10);
		loop;
		#### E 1{
			A_FaceTarget(turnamount,turnamount);
			A_SetTics(random(1,int(100/clamp(turnamount,1,turnamount+1)+4)));
			spread=frandom(0.06,0.27)*turnamount;
		}
		#### A 0 A_Jump(256,"shoot");
	shoot:
		SSWV G 1 bright light("SHOT"){
			if(gunloaded<1){
				setstatelabel("ohforfuckssake");
				return;
			}
			pitch+=frandom(0,spread)-frandom(0,spread);
			angle+=frandom(0,spread)-frandom(0,spread);
			A_StartSound("weapons/pistol",CHAN_WEAPON);
			HDBulletActor.FireBullet(self,"HDB_9",speedfactor:1.1);
			A_SpawnItemEx("HDSpent9mm",
				cos(pitch)*10,0,height-8-sin(pitch)*10,
				vel.x,vel.y,vel.z,
				0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH
			);
			gunloaded--;
		}
		SSWV F 2 A_SpawnProjectile("HDSpent9mm",40);
		SSWV F 0 A_Jump(128,"shoot");
	shootend:
		SSWV F 1 A_FaceTarget(0,0);
		SSWV F 4 A_Jump(132,"see");
		SSWV F 6 A_CPosRefire();
		loop;
	ohforfuckssake:
		SSWV F 8;
	reload:
		SSWV A 3{hdmobai.chase(self,"melee",null,true);}
		SSWV B 4{
			A_StartSound("weapons/rifleclick2",8);
			if(gunloaded>=0)A_SpawnProjectile("HDSMGEmptyMag",38,0,random(90,120));
			gunloaded=-1;
		}
		SSWV CD 3{hdmobai.chase(self,"melee",null,true);}
		SSWV E 4{
			A_StartSound("weapons/rifleload",8);
			hdmobai.wander(self,true);
		}
		SSWV F 3{
			A_StartSound("weapons/rifleclick2",8);
			gunloaded+=30;
			hdmobai.wander(self,true);
		}
		---- A 0 setstatelabel("see");
	melee:
		#### D 8 A_FaceTarget();
		#### E 4;
		#### F 4{
			A_CustomMeleeAttack(
				random(3,20),"weapons/smack","","none",randompick(0,0,0,1)
			);
		}
		#### F 3 A_JumpIfCloser(64,2);
		#### E 4 A_FaceTarget();
		goto missile2;
		#### D 4;
		---- A 0 setstatelabel("see");
	death:
		SSWV I 5;
		SSWV J 5 A_Scream();
		SSWV KL 5;
	dead:
		SSWV L 3 canraise A_JumpIf(abs(vel.z)<2,1);
		loop;
		SSWV M 5 A_JumpIf(abs(vel.z)>=2,"dead");
		loop;
	xxxdeath:
		SSWV N 5;
		SSWV O 5 A_XScream();
		SSWV PQRSTU 5;
		---- A 0 setstatelabel("xdead");
	xdeath:
		SSWV N 5 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		SSWV O 0 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		SSWV O 5 A_XScream();
		SSWV P 5 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		SSWV Q 0 A_SpawnItemEx("MegaBloodSplatter",0,0,34,0,0,0,0,160);
		SSWV QRSTU 5;
	xdead:
		SSWV U 3 canraise A_JumpIf(abs(vel.z)<2,1);
		wait;
		SSWV V 5 canraise A_JumpIf(abs(vel.z)>=2,"xdead");
		wait;
	raise:
		SSWV M 4;
		SSWV MLK 6;
		SSWV JIH 4;
		---- A 0 setstatelabel("checkraise");
	ungib:
		SSWV V 4;
		SSWV VUT 8;
		SSWV SRQ 6;
		SSWV PON 4;
		---- A 0 setstatelabel("checkraise");
	}
}
