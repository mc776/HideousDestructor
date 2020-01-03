// ------------------------------------------------------------
// Basic functional stuff
// ------------------------------------------------------------

//event handler
class HDHandlers:EventHandler{
	array<double> invposx;
	array<double> invposy;
	array<double> invposz;

	override void RenderOverlay(renderevent e){
		hdlivescounter.RenderEndgameText(e.camera);
	}
	override void WorldLoaded(WorldEvent e){
		//seed a few more spawnpoints
		for (int i=0;i<5;i++){
			vector3 ip=level.PickDeathmatchStart();
			invposx.push(ip.x);
			invposy.push(ip.y);
			invposz.push(ip.z);
		}

		if(hd_flagpole)spawnflagpole();

		//reset some player stuff
		for(int i=0;i<MAXPLAYERS;i++){
			flagcaps[i]=0;
		}

		//misc. map hacks
		textureid dirtyglass=texman.checkfortexture("WALL47_2",texman.type_any);
		int itmax=level.lines.size();
		for(int i=0;i<itmax;i++){
			line lll=level.lines[i];

			//no more killer elevators
			if(lll.special){
				switch(lll.special){

				//cap platform speeds
				case Plat_DownByValue:
				case Plat_DownWaitUpStayLip:
				case Plat_DownWaitUpStay:
				case Generic_Lift:
				case Plat_PerpetualRaiseLip:
				case Plat_PerpetualRaise:
				case Plat_RaiseAndStayTx0:
				case Plat_UpByValue:
				case Plat_UpByValueStayTx:
				case Plat_UpNearestWaitDownStay:
				case Plat_UpWaitDownStay:
					if(!hd_safelifts||abs(lll.args[1])>64)break;
					lll.args[1]=clamp(lll.args[1],-24,24);
					break;

				//prevent lights from going below 1
				case Light_ChangeToValue:
				case Light_Fade:
				case Light_LowerByValue:
					lll.args[1]=max(lll.args[1],1);break;
				case Light_Flicker:
				case Light_Glow:
				case Light_Strobe:
					lll.args[2]=max(lll.args[2],1);break;
				case Light_StrobeDoom:
					lll.args[2]=min(lll.args[2],1);break;
				case Light_RaiseByValue:
					if(lll.args[1]>=0)break;
				case Light_LowerByValue:
					sectortagiterator sss=level.createsectortagiterator(lll.args[0]);
					int ssss=sss.next();
					int lowestlight=255;
					while(ssss>-1){
						lowestlight=min(lowestlight,level.sectors[ssss].lightlevel);
						ssss=sss.next();
					}
					lll.args[1]=min(lll.args[1],lowestlight-1);

				default: break;
				}
			}
			//if block-all and no midtexture, force add a mostly transparent midtexture
			if(
				hd_dirtywindows
				&&lll.sidedef[1]
				&&(
					lll.flags&line.ML_BLOCKEVERYTHING
					||lll.flags&line.ML_BLOCKPROJECTILE
					||lll.flags&line.ML_BLOCKHITSCAN
//					||lll.flags&line.ML_BLOCKING	//still undecided so just comment not delete
				)
				&&!lll.sidedef[0].gettexture(side.mid)
				&&!lll.sidedef[1].gettexture(side.mid)
			){
				lll.flags|=line.ML_WRAP_MIDTEX;
				lll.sidedef[0].settexture(side.mid,dirtyglass);
				lll.sidedef[1].settexture(side.mid,dirtyglass);
				lll.alpha=0.2;
			}
		}
	}
}

//because "extend class Actor" doesn't work
class HDActor:Actor{
	default{
		+noblockmonst
		renderstyle "translucent";
	}

	//"After that many drinks anyone would be blowing chunks all night!"
	//"Chunks is the name of my dog."
	//for frags: A_SpawnChunks("HDB_frag",42,100,700);
	void A_SpawnChunks(
		class<actor> chunk,
		int number=12,
		double minvel=10,
		double maxvel=20
	){
		double burstz=pos.z+height*0.5;
		double minpch=burstz-floorz<56?9:90;
		double maxpch=ceilingz-burstz<56?-9:-90;
		burstz-=pos.z;
		bool gbg;actor frg;
		for(int i=0;i<number;i++){
			double pch=frandom(minpch,maxpch);
			double vl=frandom(minvel,maxvel);
			[gbg,frg]=A_SpawnItemEx(
				chunk,
				0,0,burstz,
				vl*cos(pch),0,vl*sin(-pch),
				frandom(0,360),
				SXF_NOCHECKPOSITION|SXF_TRANSFERPITCH|SXF_TRANSFERPOINTERS
			);
			if(gbg){
				frg.vel+=vel;
				if(HDBulletActor(frg))frg.bincombat=true; //work around hack that normally lets HDBulletActor out
			}
		}
	}
	//roughly equivalent to CacoZapper
	static void ArcZap(actor caller){
		caller.A_CustomRailgun((random(4,8)),frandom(-12,12),"","azure",
			RGF_SILENT|RGF_FULLBRIGHT,
			1,4000,"HDArcPuff",180,180,frandom(32,128),4,0.4,0.6
		);
	}
}
class HDArcPuff:HDActor{
	default{
		+nogravity
		+puffgetsowner
		+puffonactors
		+forcepain
		+noblood
		scale 0.4;
		damagetype "Electro";
		radius 0.1;
		height 0.1;
	}
	states{
	spawn:
		TNT1 A 5 A_PlaySound("misc/arczap",0,0.1,0,0.4);
		stop;
	}
}

class InventoryFlag:Inventory{
	default{
		+inventory.untossable;+nointeraction;+noblockmap;
		inventory.maxamount 1;inventory.amount 1;
	}
	states{
	spawn:
		TNT1 A 0;
		stop;
	}
}
class ActionItem:CustomInventory{
	default{
		+inventory.untossable -inventory.invbar +noblockmap
	}
	//wrapper for HDWeapon and ActionItem
	//remember: LEFT and DOWN
	//would use vector2s but lol bracketing errors I don't need that kind of negativity in my life
	action void A_MuzzleClimb(
		double mc10=0,double mc11=0,
		double mc20=0,double mc21=0,
		double mc30=0,double mc31=0,
		double mc40=0,double mc41=0
	){
		let hdp=HDPlayerPawn(self);
		if(hdp){
			hdp.A_MuzzleClimb((mc10,mc11),(mc20,mc21),(mc30,mc31),(mc40,mc41));
		}else{ //I don't even know why
			vector2 mc0=(mc10,mc11)+(mc20,mc21)+(mc30,mc31)+(mc40,mc41);
			A_SetPitch(pitch+mc0.y,SPF_INTERPOLATE);
			A_SetAngle(angle+mc0.x,SPF_INTERPOLATE);
		}
	}
	states{
	nope:
		TNT1 A 0;fail;
	spawn:
		TNT1 A 0;stop;
	}
}
class IdleDummy:HDActor{
	default{
		+noclip +nointeraction +noblockmap
		height 0;radius 0;
	}
	states{
	spawn:
		TNT1 A -1 nodelay{
			if(stamina>0)A_SetTics(stamina);  
		}stop;
	}
}
class CheckPuff:IdleDummy{
	default{
		+bloodlessimpact +hittracer +puffonactors +alwayspuff +puffgetsowner
		stamina 1;
	}
}


// Blocker to prevent shotguns from overpenetrating multiple targets
// tempshield.spawnshield(self);
class tempshield:HDActor{
	default{
		-solid +shootable +nodamage
		radius 16;height 50;
		stamina 16;
	}
	static actor spawnshield(
		actor caller,class<actor> type="tempshield",
		bool deathheight=false,int shieldlength=16
	){
		actor sss=caller.spawn(type,caller.pos,ALLOW_REPLACE);
		if(!sss)return null;
		sss.master=caller;
		sss.A_SetSize(
			caller.radius,
			deathheight?getdefaultbytype(caller.getclass()).deathheight
			:getdefaultbytype(caller.getclass()).height
		);
		sss.bnoblood=caller.bnoblood;
		sss.stamina=shieldlength;
		return sss;
	}
	override void Tick(){
		if(!master||stamina<1){destroy();return;}
		setorigin(master.pos,false);
		stamina--;
	}
	states{
	spawn:
		TNT1 A -1;
		stop;
	}
}


//collection of generic math functions
struct HDMath{
	//deprecated function, DO NOT USE
	//kept here to keep too much stuff from breaking the moment 4.2.4a comes out)
	static int MaxInv(actor holder,class<inventory> inv){
		console.printf("HDMath.MaxInv() is now deprecated as of HD 4.2.4a. Its contents have been stripped to return only the item's maxamount. Please use HDPickup.MaxGive() instead, which returns actual space left in pockets rather than a theoretical maximum.");
		if(holder.findinventory(inv))return holder.findinventory(inv).maxamount;
		return getdefaultbytype(inv).maxamount;
	}


	//return true if lump exists
	//mostly for seeing if we're playing D1 or D2
	//HDMath.CheckLump("SHT2A0")
	static bool CheckLump(string lumpname){
		return Wads.CheckNumForName(lumpname,wads.ns_sprites,-1,false)>=0;
	}
	//checks encumbrance multiplier
	//hdmath.getencumbrancemult()
	static double GetEncumbranceMult(){
		return clamp(skill?hd_encumbrance:hd_encumbrance*0.5,0.,2.);
	}
	//get the opposite sector of a line
	static sector OppositeSector(line hitline,sector hitsector){
		if(!hitline||!hitline.backsector)return null;
		if(hitline.backsector==hitsector)return hitline.frontsector;
		return hitline.backsector;
	}
	//calculate whether 2 actors are approaching each other
	static double IsApproaching(actor a1,actor a2){
		vector3 veldif=a1.vel-a2.vel;
		vector3 posdif=a1.pos-a2.pos;
		return (veldif dot posdif)<0;
	}
	//calculate the speed at which 2 actors are moving towards each other
	static double TowardsEachOther(actor a1, actor a2){
		vector3 oldpos1=a1.pos;
		vector3 oldpos2=a2.pos;
		vector3 newpos1=oldpos1+a1.vel;
		vector3 newpos2=oldpos2+a2.vel;
		double l1=(oldpos1-oldpos2).length();
		double l2=(newpos1-newpos2).length();
		return l1-l2;
	}
	//angle between any two vec2s
	static double angleto(vector2 v1,vector2 v2,bool absolute=false){
		let diff=absolute?v2-v1:level.Vec2Diff(v1,v2);
		return atan2(diff.y,diff.x);
	}
	//kind of like angleto
	static double pitchto(vector3 this,vector3 that){
		return atan2(this.z-that.z,(this.xy-that.xy).length());
	}
	//return a string indicating a rough cardinal direction
	static string CardinalDirection(int angle){
		angle%=360;
		if(angle<0)angle+=360;
		if(angle>=22&&angle<=66)return("northeast");
		else if(angle>=67&&angle<=113)return("north");
		else if(angle>=114&&angle<=158)return("northwest");
		else if(angle>=159&&angle<=203)return("west");
		else if(angle>=204&&angle<=248)return("southwest");
		else if(angle>=249&&angle<=292)return("south");
		else if(angle>=293&&angle<=338)return("southeast");
		return("east");
	}
	//return a loadout and its name, icon and description, e.g. "Robber: pis, bak~Just grab and run."
	static string,string,string,string GetLoadoutStrings(string input,bool keepspaces=false){
		int pnd=input.indexof("#");
		int col=input.indexof(":");
		int sls=input.indexof("/");

		//"STFEVL0#Voorhees:saw/Chainsaw: Your #1 communicator!"
		if(sls>0){
			if(sls<pnd)pnd=-1;
			if(sls<col)col=-1;
		}

		string pic=input.left(pnd);
		string nam=input.left(col);
		string lod=input;
		string desc="";

		if(sls>-1) {
			desc=input.mid(sls+1);
			lod.remove(sls,int.Max);
		}

		if(col>-1){
			if(pnd>-1)nam.remove(0,pnd+1);
			lod.remove(0,col+1);
		}

		if(!keepspaces)lod.replace(" ","");
		lod=lod.makelower();

		if(hd_debug>1)console.printf(
			pic.."   "..
			nam.."   "..
			lod.."   "..
			desc
		);
		return lod,nam,pic,desc;
	}
	//basically storing a 5-bit int array in a single 32-bit int.
	//every 32 is a 1 in the second entry, every 32*32 a 1 in the third, etc.
	static int GetFromBase32FakeArray(int input,int slot){
		input=(input>>(5*slot));
		return input&(1|2|4|8|16);
	}
	//get a nice name for any actor
	//mostly for exceptions for players and monsters
	static string GetName(actor named){
		if(named.player)return named.player.getusername();
		string tagname=named.gettag();
		if(tagname!="")return tagname;
		return named.getclassname();
	}
}
struct HDF play{
	//because this is 10 times faster than A_GiveInventory
	static void Give(actor whom,class<inventory> what,int howmany=1){
		whom.A_SetInventory(what,whom.countinv(what)+howmany);
	}
	//transfer fire. returns # of fire actors affected.
	static int TransferFire(actor ror,actor ree,int maxfires=-1){
		actoriterator it=level.createactoriterator(-7677,"HDFire");
		actor fff;int counter;
		bool eee;if(ree)eee=true;
		while(maxfires && (fff=it.next())){
			maxfires--;
			if(fff.target==ror){
				counter+=fff.stamina;
				if(eee)fff.target=ree;
				else fff.destroy();
			}
		}
		return counter;
	}
	//figure out if something hit some map geometry that isn't (i.e., "sky").
	//why is GetTexture play!?
	static bool linetracehitsky(flinetracedata llt){
		if(
			(
				llt.hittype==Trace_HitCeiling
				&&llt.hitsector.gettexture(1)==skyflatnum
			)||(
				llt.hittype==Trace_HitFloor
				&&llt.hitsector.gettexture(0)==skyflatnum
			)||(
				!!llt.hitline
				&&llt.hitline.special==Line_Horizon
			)
		)return true;
		let othersector=hdmath.oppositesector(llt.hitline,llt.hitsector);
		if(!othersector)return false;
		return(
			llt.hittype==Trace_HitWall
			&&(
				(
					othersector.gettexture(othersector.ceiling)==skyflatnum
					&&othersector.ceilingplane.zatpoint(llt.hitdir.xy)<llt.hitlocation.z
				)||(
					othersector.gettexture(othersector.floor)==skyflatnum
					&&othersector.floorplane.zatpoint(llt.hitdir.xy)>llt.hitlocation.z
				)
			)
		);
	}
}






//debug thingy
class HDCheatWep:HDWeapon{
	default{
		+inventory.undroppable
		-weapon.no_auto_switch
		+weapon.cheatnotweapon
		+hdweapon.debugonly
		+nointeraction
	}
}
class HDRaiseWep:HDCheatWep{
	default{
		weapon.slotnumber 0;
		hdweapon.refid "rvv";
		tag "monster reviver (cheat!)";
	}
	states{
	ready:
		TNT1 A 1 A_WeaponReady();
		goto readyend;
	fire:
		TNT1 A 0{
			flinetracedata rlt;
			LineTrace(
				angle,128,pitch,
				TRF_ALLACTORS,
				offsetz:height-6,
				data:rlt
			);
			if(rlt.hitactor){
				a_weaponmessage(rlt.hitactor.getclassname().." raised!",30);
				RaiseActor(rlt.hitactor,RF_NOCHECKPOSITION);
			}else a_weaponmessage("click on something\nto raise it.",25);
		}goto nope;
	}
}


