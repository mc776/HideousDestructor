//-------------------------------------------------
// Flick a piece of tiny debris at something to set off a shootable switch.
//-------------------------------------------------
//class FlickChunk:HDBullet{
class FlickChunk:FastProjectile{
	default{
		+rollsprite +rollcenter +bloodlessimpact +nodamage
		speed 64;
		+hittracer height 0.1;radius 0.05;
		woundhealth 0;
		accuracy 0;
		mass 10;
		deathsound "weapons/chunkslap";
		damagetype "debris";
		scale 5;
	}
	//override 
	actor Puff(int sp){
		bmissile=false;
		setstatelabel("death");
		return null;
	}
	override void Tick(){
		super.Tick();
		if(bmissile&&!isfrozen())vel.z--;
	}
	//override void GunSmoke(){}
	states{
	spawn:
		DUST ABCD -1 nodelay{
			A_ChangeVelocity(cos(pitch)*speed,0,-sin(pitch)*speed,CVF_RELATIVE);
			frame=random(0,3);
			roll=frandom(0,360);
			scale=(randompick(-1,1),randompick(-1,1))*frandom(0.05,0.12);
		}
	death:
		---- A 4{
			A_Scream();
		}
		TNT1 A 0{
			if(tracer&&tracer.health>0&&(tracer.player||!random(0,3)))
				tracer.A_StartSound(tracer.painsound,CHAN_VOICE);
		}
		TNT1 A random(4,20);
		TNT1 A 0{
			if(tracer)tracer.lastheard=target;
		}
		stop;
	}
}
class WallChunkAmmo:Ammo{default{inventory.maxamount 5;}states{spawn:TNT1 A 0;stop;}}
extend class HDFist{
	action void A_ChunkFlick(){
		if(
			!countinv("WallChunkAmmo")&&(
				countinv("WornRadsuit")
				||(
					findinventory("PortableLiteAmp")
					&&PortableLiteAmp(findinventory("PortableLiteAmp")).worn
				)
			)
		){
			A_Log("You're wearing something over your face. Take it off first before you do this.",true);
			return;
		}

		bool isrobot=player.getgender()==3;

		actor p=spawn("FlickChunk",pos+(0,0,height-6),ALLOW_REPLACE);
		p.target=self;p.angle=angle;p.pitch=pitch;
		p.vel+=(
			frandom(-1.,1.),frandom(-1.,1.),frandom(-1.,1.)
		);
		p.vel+=self.vel;

		if(!countinv("WallChunkAmmo")){
			p.deathsound="weapons/chunksplat";
			p.A_SetTranslation(isrobot?"allred":"booger");
		}else A_TakeInventory("WallChunkAmmo",1);
		A_StartSound("weapons/chunkflick",CHAN_WEAPON,volume:0.3);
	}
	action void A_ChunkPick(){
		if(countinv("WallChunkAmmo")){
			A_Log("You find some random punched-wall debris in your pockets to flick it at the offending thing.",true);
			return;
		}
		A_SetTics(30);
		A_StartSound("weapons/pocket",9);
		if(player.getgender()==3)
		A_Log("For want of random wall-punched debris or a natural mucus system, you scrape some tainted lubricant off of some of your unseen parts and wad it into a filthy, flickable lump.",true);
		else A_Log("For want of random wall-punched debris in your pockets, you pick your nose to flick it at the offending thing.",true);
	}
	states{
	unload:
		//because some weapons drop on hitting unload under some circumstances
		TNT1 A 0 A_JumpIf(player.oldbuttons&BT_USER4,"nope");
	flick1:
		TNT1 A 10;
		TNT1 A 0 A_ChunkPick();
	flick2:
		TNT1 A 1 A_JumpIf(!pressingunload(),1);
		wait;
		TNT1 A 10 A_ChunkFlick();
		goto nope;
	}
}
