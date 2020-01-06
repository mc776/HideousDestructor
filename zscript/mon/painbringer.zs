// ------------------------------------------------------------
// Pain Bringer
// ------------------------------------------------------------
class PainBringer:PainMonster replaces HellKnight{
	default{
		height 60;
		radius 14;
		mass 1000;
		painchance 50;
		health 500;
		seesound "knight/sight";
		activesound "knight/active";
		painsound "knight/pain";
		deathsound "knight/death";
		obituary "$ob_knight";
		hitobituary "$ob_knighthit";
		tag "$cc_hell";

		damagefactor "Balefire",0.3;
		damagefactor "Thermal",0.8;
		hdmobbase.shields 500;
		scale 0.9;
		speed 12;
		meleedamage 10;
		meleerange 56;
		minmissilechance 42;

		stamina 0;
	}

	override double bulletshell(vector3 hitpos,double hitangle){
		return frandom(3,7);
	}
	override double bulletresistance(double hitangle){
		return max(0,frandom(0.8,1.)-hitangle*0.008);
	}

	override void postbeginplay(){
		super.postbeginplay();
		hdmobai.resize(self,0.9,1.1);
	}
	double targetingangle;double targetingpitch;
	double targetdistance;
	states{
	spwander:
		BOS2 ABCDABCD 7 {hdmobai.wander(self);}
		BOS2 A 0{
			if(!random(0,1))setstatelabel("spwander");
			else A_Recoil(-0.4);
		}//fallthrough to spawn
	spawn:
		BOS2 AAABBCCCDD 8 A_Look();
		BOS2 A 0{
			if(bambush)setstatelabel("spawn");
			else{
				A_SetTics(random(1,3));
				if(!random(0,5))A_StartSound("knight/active",CHAN_VOICE);
				if(!random(0,5))setstatelabel("spwander");
			}
		}loop;
	see:
		BOS2 A 0{
			if(!random(0,127)){
				A_StartSound(seesound,CHAN_VOICE);
				A_AlertMonsters();
			}
		}
		BOS2 AABBCCDD 3{hdmobai.chase(self);}
		loop;
	pain:
		BOS2 H 2;
		BOS2 H 2 A_Pain;
		---- A 0 setstatelabel("see");
	pain.balefire:
		BOS2 H 3{
			A_Recoil(0.4);
			GiveBody(20);
			if(!random(0,3))A_KillChildren();
		}
		goto pain;
	missile:
		BOS2 ABCD 3{
			A_FaceTarget(30);
			if(A_JumpIfTargetInLOS("null",10))setstatelabel("shoot");
		}
		BOS2 E 0 A_JumpIfTargetInLOS("shoot",10);
		BOS2 E 0 A_JumpIfTargetInLOS("missile");
		---- A 0 setstatelabel("see");
	shoot:
		BOS2 E 0{
			if(target)targetdistance=distance3d(target);else targetdistance=0;
			if(
				stamina<1
				&&targetdistance>1024
				&&!random(0,4)
			){
				setstatelabel("putto");
			}
		}goto fireball;
	putto:
		BOS2 E 6 A_StartSound("knight/sight",CHAN_VOICE);
		BOS2 E 4 A_FaceTarget(10,10);
		BOS2 E 2;
		BOS2 F 5;
		BOS2 E 3;
		BOS2 H 12{
			actor p=spawn("Putto",pos+(angletovector(angle,32),32),ALLOW_REPLACE);
			p.master=self;p.angle=angle;p.pitch=pitch;
			p.A_ChangeVelocity(cos(pitch)*5,0,-sin(pitch)*5,CVF_RELATIVE);
			p.bfriendly=bfriendly;p.target=target;
			stamina++;
		}
		---- A 0 setstatelabel("see");
	fireball:
		BOS2 FE 3 A_FaceTarget(60,60);
		BOS2 E 2{
			A_FaceTarget(6,6);
			targetingangle=angle;targetingpitch=pitch;
		}
		BOS2 E 3{
			A_FaceTarget(6,6);

			if(target&&targetdistance<(25*35*7)){
				double adj=targetdistance*frandom(0.008,0.032);
				angle+=deltaangle(targetingangle,angle)*adj;
				if(target.bfloat)pitch+=deltaangle(targetingpitch,pitch)*adj;
				else pitch+=clamp(deltaangle(targetingpitch,pitch)*adj,-10,10);
			}else{
				angle+=frandom(-4.,4.);
				pitch+=frandom(-0.1,0.1);
			}
		}
		BOS2 F 1;
		BOS2 G 4{
			actor aaa;int bbb;
			[bbb,aaa]=A_SpawnItemEx("BaleBall",
				0,0,32,
				cos(pitch)*25,0,-sin(pitch)*25
			);
			aaa.vel+=vel;aaa.tracer=target;
		}
		BOS2 GF 5;
		BOS2 A 0 A_Jump(128,"missile");
		---- A 0 setstatelabel("see");
	melee:
		BOS2 E 6 A_FaceTarget();
		BOS2 F 2;
		BOS2 G 6{
			A_CustomMeleeAttack(random(20,100),"baron/melee","","claws",true);
			if(!random(0,3))return;
			actor aaa;int bbb;
			[bbb,aaa]=A_SpawnItemEx("BaleBall",
				0,0,48,
				8,0,-12
			);
			aaa.vel+=vel;
		}
		BOS2 F 5;
		---- A 0 setstatelabel("see");
	death:
		BOS2 I 8;
		BOS2 J 8 A_Scream();
		BOS2 K 8;
		BOS2 L 8 A_NoBlocking();
		BOS2 M 8;
		BOS2 N 8;
		BOS2 O -1 A_BossDeath();
		stop;
	death.maxhpdrain:
		BOS2 H 5 A_StartSound("misc/gibbed",CHAN_BODY);
		BOS2 HIJK 5;
		BOS2 L 5 A_NoBlocking();
		BOS2 MN 5;
		BOS2 O -1;
		stop;
	raise:
		BOS2 ONMLKJI 5;
		BOS2 H 8 A_StartSound("knight/sight",CHAN_VOICE);
		BOS2 AAABB 3 A_Chase();
		goto checkraise;
	}
}


class zbbt:hdfireballtail{
	default{
		translation 2;
		renderstyle "subtract";
		deathheight 0.9;
		gravity 0;
		scale 0.6;
	}
	override void tick(){
		super.tick();
		if(alpha==height)addz(6);
	}
	states{
	spawn:
		BAL7 CDE 2{
			roll+=10;
			scale.x*=randompick(-1,1);
		}loop;
	}
}
class BaleBall:hdfireball{
	default{
		missiletype "zbbt";
		damagetype "balefire";
		activesound "baron/ballhum";
		decal "gooscorch";
		gravity 0;
		speed 25;
	}
	actor lingerburner;
	override void ondestroy(){
		if(lingerburner)lingerburner.destroy();
		super.ondestroy();
	}
	states{
	spawn:
		BAL7 A 0 nodelay{
			actor bbl=spawn("BaronBallLight",pos,ALLOW_REPLACE);bbl.target=self;
		}
		BAL7 ABAB 3 A_FBTail();
	spawn2:
		BAL7 AB 3 {
			if(!A_FBSeek())A_FBFloat();
		}loop;
	death:
		BAL7 A 0{
			vel.z+=0.5;
			if(!blockingmobj){
				tracer=null;
				setstatelabel("burn");

				lingerburner=spawn("BaleBallBurner",pos,ALLOW_REPLACE);
				lingerburner.target=target;lingerburner.master=self;
				return;
			}else if(target&&
				blockingmobj.health>0&&target.health>0&&
				blockingmobj.getspecies()==target.getspecies()&&
				!(blockingmobj.ishostile(target))
			)return;
			else if(tracer&&blockingmobj==tracer){
				vel.z=2;
				tracer.damagemobj(self,target,random(16,32),"balefire");
				alpha=1;scale*=1.2;
				setstatelabel("burn");
			}
		}
	splat:
		BAL7 CDE 4;
		stop;
	burn:
		BAL7 CDE 3{
			A_FadeOut(0.05);
			frame=random(2,4);roll=random(0,360);
			if(!tracer){
				addz(0.1);
				return;
			}

			if(tracer is "HDPlayerPawn"&&tracer.health<1&&HDPlayerPawn(tracer).playercorpse){
				tracer=HDPlayerPawn(tracer).playercorpse;
			}

			double trad=tracer.radius;double tht=tracer.height;
			setxyz(tracer.pos+(frandom(-trad,trad),frandom(-trad,trad),frandom(tht*0.5,tht)));

			if(alpha>0.3){
				tracer.damagemobj(self,target,random(1,3),"balefire");
			}else{
				A_Immolate(tracer,target,random(10,20));
				destroy();
			}
		}wait;
	}
}
class BaleBallBurner:PersistentDamager{
	default{
		height 12;radius 20;stamina 1;
		damagetype "balefire";
	}
}


class BaronBallLight:PointLight{
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=64;
		args[1]=196;
		args[2]=48;
		args[3]=0;
		args[4]=0;
	}
	override void tick(){
		if(!target){
			args[3]+=random(-10,1);
			if(args[3]<1)destroy();
		}else{
			setorigin(target.pos,true);
			if(target.bmissile)args[3]=random(32,40);
			else args[3]=random(48,64);
		}
	}
}






