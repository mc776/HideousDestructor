// ------------------------------------------------------------
// Yokai
// ------------------------------------------------------------
class Yokai:HDMobBase{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Yokai"
		//$Sprite "PINSA0"

		monster;
		+nodamagethrust +noblooddecals +nogravity +floatbob -solid
		+forcexybillboard
		+notrigger
		+hdmobbase.noshootablecorpse
		height 42;radius 10;
		renderstyle "Add";
		tag "yokai";
		maxtargetrange 666;health 66;
		bloodtype "IdleDummy";
		obituary "%o watched a yokai.";
		translation "176:191=29:47","192:207=160:167","240:247=188:191";
		speed 4;
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_GiveInventory("ImmunityToFire");
	}
	override void tick(){
		super.tick();
		if(alpha<0.4&&!random(0,3)){
			a_setrenderstyle(alpha,STYLE_Fuzzy);
		}else{
			a_setrenderstyle(alpha,STYLE_Add);
		}
	}
	states{
	spawn:
		PINS ABCD 6 A_Look();
		loop;
	see:
		#### AABBCCDD 2{
			vel.z+=frandom(-0.1,0.1);
			alpha=clamp(alpha+frandom(-0.1,0.06),0.1,0.6);
			scale.x=frandom(0.660,0.672);
			scale.y=scale.x;
			hdmobai.chase(self);
		}loop;
	melee:
	missile:
		#### AB 3{
			alpha+=0.1;
			scale*=frandom(0.9,1.15);
		}
		#### CDA 2{
			alpha+=0.1;
			scale*=frandom(0.95,1.08);
		}
	missile2:
		#### B 1 bright A_JumpIfInTargetLOS("hurt");
		goto posthurt;
	hurt:
		#### A 2{
			bfrightened=false;
			A_SetShootable();
			alpha=frandom(0.8,0.9);
			if(target is ("GhostMarine")){
				A_Die();
				return;
			}

			A_StartSound("putto/sight",CHAN_AUTO,0,1.,0.9);
			A_SetScale(0.666);
			GiveBody(4);
			if(!target)return;
			A_GiveToTarget("IsMoving",2);
			target.damagemobj(
				self,self,
				1,!random(0,63)?"balefire":"internal",
				DMG_NO_ARMOR
			);
			if(target.health>0&&!random(0,3))target.givebody(1);
		}
		#### B 1 bright{
			A_SetScale(0.680);
		}
	posthurt:
		#### C 0 A_JumpIfCloser(random(600,666),1);
		---- A 0 setstatelabel("see");
		#### C 0 A_MonsterRefire(0,"see");
		#### C 0 A_JumpIfInTargetLOS("hurt",40);
		#### C 0 A_SetScale(0.666);
		#### CDA 1 bright;
		#### C 0 A_JumpIfInTargetLOS("missile2",80);
		---- A 0 setstatelabel("see");
	pain:
		---- A 1;
		---- A 0{
			bfrightened=true;
			A_StartSound("putto/sight");
			A_SetTranslucent(1,1);
			A_UnsetShootable();
		}
		#### DABCD 1{alpha-=0.18;}
		TNT1 A 1{
			bfrightened=false;
			A_Chase(null,null,CHF_NOPLAYACTIVE);
			if(!random(0,99))setstatelabel("unspook");
		}
		wait;
	unspook:
		PINS A 0{
			bfrightened=false;
			A_SetShootable();
		}
		PINS DABCD 1{alpha+=0.18;}
		---- A 0 setstatelabel("see");
	death:
		#### DABCD 1{alpha-=0.18;}
		stop;
	}
}
class YokaiSpawner:HDActor{
	default{
		+ismonster -countkill +noblockmap +frightened
		+nogravity +float +lookallaround -telestomp
		speed 32;health 1;
		radius 18;height 24;
		translation "176:191=29:47","192:207=160:167","240:247=188:191";
		scale 0.666;
	}
	states{
	spawn:
		TNT1 A 0 nodelay A_JumpIf(!sv_nomonsters,"spawn2");
		stop;
	spawn2:
		TNT1 A 10 A_Look();
		loop;
	see:
		TNT1 A 1{
			A_Chase(null,null);
			setz(frandom((ceilingz+floorz)*0.5,ceilingz-height));

			if(!target)setstatelabel("spawn2");
			else if(!checksight(target)||distance3d(target)>512)setstatelabel("drop");  
		}loop;
	drop:
		TNT1 A 1 A_SetTics(random(210,700));
		TNT1 A 0{
			A_FaceTarget();
			vel=(0,0,0);
			A_SetTranslucent(0.1,1);
		}
		PINS ABCD 1 bright A_FadeIn(0.1);
		TNT1 A 1 A_SpawnItemEx("Yokai",zvel:-4,
			flags:SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS
		);
		stop;
	}
}

