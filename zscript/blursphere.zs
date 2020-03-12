//-------------------------------------------------
// Blur Sphere
//-------------------------------------------------
class BlurTaint:InventoryFlag{default{+inventory.undroppable}}
class HDBlurSphere:HDPickup{
	//true +invisible can never be used.
	//it will cause the monsters to be caught in a consant 1-tic see loop.
	//no one seems to consider this to be a bug.
	//shadow will at least cause attacks to happen less often.
	default{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Blur Sphere"
		//$Sprite "PINSA0"

		+inventory.alwayspickup
		inventory.maxamount 9;
		inventory.interhubamount 1;
		inventory.pickupmessage "So precious in your sight.";
		inventory.pickupsound "blursphere/pickup";
		inventory.icon "PINSA0";
		scale 0.3;
	}
	int intensity;int xp;int level;bool worn;
	int randticker[4];double randtickerfloat;
	override void ownerdied(){
		buntossable=false;
		owner.DropInventory(self);
	}
	states{
	spawn:
		PINS ABCDCB random(1,6);
		loop;
	use:
		TNT1 A 0{
			A_SetBlend("01 00 00",0.9,48);
			if(!invoker.worn){
				invoker.worn=true;
				HDF.Give(self,"BlurTaint",1);
				A_StartSound("blursphere/use",CHAN_BODY,CHANF_OVERLAP,frandom(0.3,0.5),attenuation:8.);
				invoker.level=min(13,invoker.level+invoker.xp/BLUR_LEVELUP);
				invoker.xp%=BLUR_LEVELUP;
				invoker.stamina=clamp(invoker.level+random(-2,2),0,10);
				if(invoker.level>7)invoker.buntossable=true;  

				int spac=countinv("SpiritualArmour");
				if(spac){
					hdplayerpawn(self).cheatgivestatusailments("fire",spac*3);
					A_TakeInventory("SpiritualArmour");
				}
			}else{
				invoker.worn=false;
				A_StartSound("blursphere/unuse",CHAN_BODY,CHANF_OVERLAP,frandom(0.3,0.5),attenuation:8.);
			}
		}fail;
	}
	enum blurstats{
		BLUR_LEVELUP=3500,
		BLUR_LEVELCAP=13,
	}
	override void tick(){
		super.tick();
		double frnd=frandom[blur](0.93,1.04);
		scale=(0.3,0.3)*frnd;
		alpha=0.9*frnd;
		randticker[0]=random(0,3);
		randticker[1]=random(8,25);
		randticker[2]=random(0,40+level);
		randticker[3]=random(0,BLUR_LEVELUP);
		randtickerfloat=frandom(0.,1.);
	}
	override void DoEffect(){
		if(
			!owner
			||owner.health<1
		){
			return;
		}

		//they eat their own
		if(amount>1){  
			amount=1;
			xp+=100;
		}

		if(!worn){
			intensity=max(0,intensity-1);
			if(level<BLUR_LEVELCAP&&!randticker[0])xp++;
		}else{
			if(intensity<99)intensity=max(intensity+1,-135);
			xp++;

			let ltm=PortableLiteAmp(owner.findinventory("PortableLiteAmp"));
			if(ltm)ltm.worn=false;
		}
		bool invi=true;

		if(intensity<randticker[1]){
			owner.a_setrenderstyle(1.,STYLE_Normal);
			invi=false;
		}else{
			owner.a_setrenderstyle(0.9,STYLE_Fuzzy);
		}

		//apply result
		owner.bshadow=invi;
		owner.bnevertarget=invi;

		if(!owner.countinv("blurtaint"))return;

		//medusa gaze
		if(invi&&!!randticker[0]){
			flinetracedata medusagaze;
			owner.linetrace(
				owner.angle,4096,owner.pitch,
				offsetz:owner.height-6,
				data:medusagaze
			);
			actor aaa=medusagaze.hitactor;
			if(aaa&&aaa.bismonster){
				aaa.A_ClearTarget();
				aaa.A_ClearSoundTarget();
				HDF.Give(aaa,"Heat",random(1,level+3));
				if(!random(0,3))xp++;
			}
			owner.A_ClearSoundTarget();
		}

		let hdp=hdplayerpawn(owner);
		if(hdp){
			if(hdp.regenblues>random(1,777)){
				hdp.aggravateddamage++;
				hdp.regenblues=max(0,hdp.regenblues-15);
				hdp.cheatgivestatusailments("fire",1);
				if(!worn&&!randticker[2]){
					hdp.A_TakeInventory("BlurTaint");
				}
			}
			if(hdp.countinv("SpiritualArmour")){
				hdp.cheatgivestatusailments("fire",countinv("SpiritualArmour")*10);
				hdp.A_TakeInventory("SpiritualArmour");
			}
			if(hdp.woundcount>random(0,level)){
				hdp.woundcount--;
				hdp.unstablewoundcount++;
			}
		}

		if(xp<1)return;

		//power.
		if(!(xp%666)){
			bool nub=!level&&xp<1066;
			if(nub||!random(0,15))owner.A_Log("You feel power growing in you.",true);
			blockthingsiterator it=blockthingsiterator.create(owner,512);
			array<actor>monsters;monsters.clear();
			while(it.next()){
				actor itt=it.thing;
				if(
					itt==owner
					||!itt.bismonster
					||itt.health<1
				)continue;
				monsters.push(itt);
				if(itt.target==owner)itt.A_ClearTarget();
				if(
					nub
					||!random(0,66-level)
				){
					actor fff=itt.spawn("HDFire",itt.pos,ALLOW_REPLACE);
					fff.target=itt;
					fff.stamina=nub?166:13*level;
					fff.master=self;
				}else if(random(0,6-level)<1){
					HDBleedingWound.Inflict(itt,13*level,source:self);
				}
			}
			if(monsters.size()){
				int maxindex=monsters.size()-1;
				for(int i=0;i<maxindex;i++){
					actor mmm1=monsters[random(0,maxindex)];
					actor mmm2=monsters[random(0,maxindex)];
					mmm1.damagemobj(
						self,mmm2,1,"Balefire"
					);
					mmm1.target=mmm2;
				}
			}
		}

		//precious.
		if(randticker[3]<level){
			if(!(xp%3)){
				owner.A_StartSound("blursphere/hallu"..int(clamp(randtickerfloat*7,0,6)),
					CHAN_VOICE,CHANF_OVERLAP|CHANF_LOCAL,randtickerfloat*0.3+0.3
				);
			}
			if(!(xp%5)){
				string msg[15];
				msg[0]=string.format("Out of sync with: %i",randticker[0]+1);
				msg[1]="Error: no such actor \"HDPlayer\" exists. Execution may abort!";
				msg[2]="\cd[DERP] \cjEngaging hostile.";
				msg[3]="Memory allocation error: recovered segfault at address 00x6f24ff.";
				msg[4]="rendering error";
				msg[5]="Noise.";
				msg[6]="hello";
				msg[7]="I hate you.";
				msg[8]="This is worthless.";
				msg[9]="it hurts";
				msg[10]="error";
				msg[11]="Precious.";
				msg[12]="Precious.";
				msg[13]="Precious.";
				msg[14]="Precious.";
				owner.A_Log(msg[int(clamp(randtickerfloat*msg.size(),0,msg.size()-1))],true);
			}
			if(!(xp%7)){
				hdplayerpawn(owner).aggravateddamage++;
				if(!randticker[0])owner.A_Log("Precious.",true);
			}
		}
		if(level>=BLUR_LEVELCAP&&xp>666)xp=0;
	}
	override void DetachFromOwner(){
		owner.bshadow=false;
		owner.a_setrenderstyle(1.,STYLE_Normal);
		if(worn){
			worn=false;
			owner.damagemobj(self,owner,random(1,level),"balefire");
		}
		intensity=0;
		owner.A_StartSound("blursphere/unuse",CHAN_BODY,volume:frandom(0.3,0.5),attenuation:8.);
		super.detachfromowner();
	}
}





//a mortal man doomed to die
class WraithLight:PointLight{
	default{
		+dynamiclight.subtractive
	}
	override void postbeginplay(){
		super.postbeginplay();
		args[0]=66;
		args[1]=17;
		args[2]=13;
		args[3]=0;
		args[4]=0;
	}
	override void tick(){
		if(!target){
			args[3]+=random(-5,2);
			if(args[3]<1)destroy();
		}else{
			setorigin(target.pos,true);
			if(target.bmissile)args[3]=random(32,40);
			else args[3]=random(48,64);
		}
	}
}
//In geometry, a spherical shell is a generalization of an annulus to three dimensions.
class ShellShade:ZombieStormtrooper{
	default{
		//$Category "Monsters/Hideous Destructor"
		//$Title "Shellshade"
		//$Sprite "POSSA1"

		+shadow -solid +noblood
		+hdmobbase.noincap
		hdmobbase.shields 666;
		renderstyle "Fuzzy";
		health 900;
		stencilcolor "04 00 06";
		tag "shell-shade";
	}
	override void postbeginplay(){
		user_weapon=1;
		super.postbeginplay();
		A_SpawnItemEx("WraithLight",flags:SXF_SETTARGET);
	}
	override void tick(){
		super.tick();
		bshootable=randompick(0,1,1,1);
		scale=bshootable?(1.,1.):(0.98,0.98);
		binvisible=bshootable?false:true;
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(
			mod=="holy"
			||(
				mod!="bleedout"
				&&source
				&&source.countinv("SpiritualArmour")
				&&!source.countinv("HDBlurSphere")
			)
		){
			bnoblood=false;
			forcepain(self);
			A_StartSound("marine/death",CHAN_VOICE);
			shields>>=1;
		}
		int dmg=super.damagemobj(
			inflictor,source,damage,mod,flags,angle
		);
		if(bnoblood)stunned=0;
		return dmg;
	}
	override void deathdrop(){
		A_NoBlocking();
		A_DropItem("ZM66Regular");
		bnointeraction=true;
		for(int i=0;i<10;i++){A_SpawnItemEx("HDSmoke",
			frandom(-12,12),frandom(-12,12),frandom(4,36),
			flags:SXF_NOCHECKPOSITION
		);}
		DistantQuaker.Quake(self,
			6,100,16384,10,256,512,128
		);
		vel=(0,0,0);
	}
	states{
	death:
	xdeath:
		POSS G 5;
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAA
			random(1,3) A_StartSound("marine/death",random(8,24),volume:frandom(0.3,1.),attenuation:0.1,pitch:frandom(0.98,1.01));
		TNT1 A 35;
		TNT1 A 0 A_DropItem("HDBlurSphere");
	xxxdeath:
		stop;
	}
}

