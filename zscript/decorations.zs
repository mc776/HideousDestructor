// ------------------------------------------------------------
// Props, trees, headsicles, etc.
// ------------------------------------------------------------
class HDFloatingSkull:HDActor replaces FloatingSkull{
	default{
		height 47;radius 16;+nogravity;+noteleport;+solid;
		+shootable;+nodamage;+noblooddecals;
		+pushable;pushfactor 0.3;mass 300;
		bloodtype "HDSmokeChunk";
	}
	states{
	spawn:
		FSKU AB random(2,8) bright light("FSKUL"){
			double ud=frandom(-0.05,0.05);
			if(pos.z-floorz<4){
				ud=0.05;
			}
			else if(pos.z-floorz>28){
				ud=-0.05;
			}
			vel+=(frandom(-0.05,0.05),frandom(-0.05,0.05),ud);
		}loop;
	}
}


class HDTree:HDActor{
	//seeing if you're standing on a hellish texture
	static const string hlf[]={
		"SFLR6_1","SFLR6_4","SFLR7_1","SFLR7_4",
		"BLOOD1","BLOOD2","BLOOD3",
		"LAVA1","LAVA2","LAVA3","LAVA4"
	};
	bool CheckHellFloor(){
		int hlflength=hlf.size();
		for (int i=0;i<hlflength;i++){
			TextureID tx=TexMan.CheckForTexture(hlf[i],TexMan.Type_Flat);
			if (tx==floorpic){
				return true;
			}
		}
		return false;
	}
	default{
		+solid +shootable +nodamage +dontthrust +forceybillboard +rollsprite
		mass int.MAX;painchance 48;
	}
	void A_Resize(double scx,double scy){
		super.postbeginplay();
		double cz=ceilingz-floorz;
		if(cz>0&&cz<height*scy)scy*=height/cz;
		A_SetSize(radius*scx,height*scy);
		scale=(scale.x*scx,scale.y*scy);
		scale.x*=randompick(-1,1);
		roll+=frandom(-5.,5.);
	}
	states{
	quiet:
		---- A -1{
			bnoblood=true;
			bnopain=true;
		}stop;
	spawn2:
		---- A 1 A_CheckFloor(1);
		wait;
		---- A 0{
			if(
				CheckHellFloor()
			)setstatelabel("spawn3");
			angle=frandom(0,360);
		}goto quiet;
	spawn3:
		---- A 1{
			A_SetTics(random(1,20)*10);
			int chn=random(0,12);
			if(random(0,7))A_StartSound("grunt/active",chn,volume:frandom(0.1,0.4),attenuation:1.);
			else A_StartSound("tree/pain",chn,volume:frandom(0.2,1.0),attenuation:1.,pitch:frandom(0.6,1.3));
		}loop;
	pain:
		---- A 1{
			for(int i=0;i<7;i++){
				A_StopSound(i);
			}
			A_StartSound("tree/pain",CHAN_AUTO,attenuation:1.,pitch:frandom(0.9,1.3));
			A_Immolate(self,self,random(1,10)*8);
			bnopain=true;
			A_SetTics(random(1,10)*40);
		}
		---- A 0{bnopain=false;}
		goto spawn2;
	}
}
class HDBigTree:HDTree replaces BigTree{
	default{
		+shootable +nodamage +dontthrust
		+forceybillboard +rollsprite
		+dontthrust
		painchance 48;
		radius 27; height 68;
	}
	states{
	spawn:
		TRE2 A 0 nodelay{
			if(Wads.CheckNumForName("id",0)==-1)A_SetSize(14,64);
			A_Resize(frandom(0.8,1.2),frandom(0.8,1.2));
		}
		goto spawn2;
	}
}
class HDTorchTree:HDTree replaces TorchTree{
	default{
		radius 10; height 50;
	}
	states{
	spawn:
		TRE1 A 0 nodelay A_Resize(frandom(0.9,1.6),frandom(0.6,1.6));
		goto spawn2;
	}
}



class HDElectricLampLight:PointLight{
	override void postbeginplay(){
		super.postbeginplay();
		if(!target){destroy();return;}
		args[0]=140;
		args[1]=164;
		args[2]=196;
		args[3]=32+int(target.height);
		args[4]=0;
	}
	override void Tick(){
		if(!target){destroy();return;}
		setorigin((target.pos.xy,target.pos.z+target.height-7),true);
	}
}
class HDColumn:Column replaces Column{
	default{+dontthrust +shootable +nodamage +noblood +forceybillboard radius 6;
		height 42;
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_SpawnItemEx("HDElectricLampLight",SXF_SETTARGET);
	}
}
class HDTechLamp:TechLamp replaces TechLamp{
	default{+dontthrust +shootable +nodamage +noblood +forceybillboard radius 6;
		height 69;
	}
	states{spawn:TNT1 A 0;goto super::spawn;} //bypass the "has no frames" check
	override void postbeginplay(){
		super.postbeginplay();
		//used in the range, so gotta check
		if(!texman.checkfortexture("TLMPA0",texman.type_sprite).isvalid()){
			spawn("HDColumn",pos,ALLOW_REPLACE);
			destroy();
			return;
		}
		A_SpawnItemEx("HDElectricLampLight",SXF_SETTARGET);
	}
}
class HDTechLamp2:TechLamp2 replaces TechLamp2{
	default{+dontthrust +shootable +nodamage +noblood +forceybillboard radius 6;}
	override void postbeginplay(){
		super.postbeginplay();
		A_SpawnItemEx("HDElectricLampLight",SXF_SETTARGET);
	}
}


class HDTechPillar:TechPillar replaces TechPillar{
	default{+dontthrust +shootable +nodamage +noblood +forceybillboard mass 2000;radius 10;}
}



class HDTorchLight:PointLight{
	default{+dynamiclight.additive}
	override void tick(){
		if(!target){
			destroy();
			return;
		}
		args[3]=random(64,96);
		setorigin((target.pos.xy,target.pos.z+target.missileheight),true);
	}
}
class HDBlueTorch:BlueTorch replaces BlueTorch{
	default{+dontthrust +shootable +nodamage +noblood +forceybillboard
		radius 6;
		missileheight 42; //used for light
	}
	override void postbeginplay(){
		super.postbeginplay();
		scale.x=randompick(-1,1);
		actor lite=spawn("HDTorchLight",pos,ALLOW_REPLACE);
		if(lite){
			lite.target=self;
			SetLights(lite);
		}
	}
	virtual void SetLights(actor lite){
		lite.args[0]=64;
		lite.args[1]=32;
		lite.args[2]=128;
	}
	states{
	spawn:
		TBLU A 0;
		goto spawn2;
	spawn2:
		#### ABCD random(1,2);
		loop;
	}
}
class HDGreenTorch:HDBlueTorch replaces GreenTorch{
	states{spawn:TGRN A 0;goto spawn2;}
	override void SetLights(actor lite){
		lite.args[0]=32;
		lite.args[1]=128;
		lite.args[2]=64;
	}
}
class HDRedTorch:HDBlueTorch replaces RedTorch{
	states{spawn:TRED A 0;goto spawn2;}
	override void SetLights(actor lite){
		lite.args[0]=128;
		lite.args[1]=64;
		lite.args[2]=32;
	}
}
class HDShortBlueTorch:HDBlueTorch replaces ShortBlueTorch{
	default{height 32;}
	states{spawn:SMBT A 0;goto spawn2;}
}
class HDShortGreenTorch:HDGreenTorch replaces ShortGreenTorch{
	default{height 32;}
	states{spawn:SMGT A 0;goto spawn2;}
}
class HDShortRedTorch:HDRedTorch replaces ShortRedTorch{
	default{height 32;}
	states{spawn:SMRT A 0;goto spawn2;}
}





