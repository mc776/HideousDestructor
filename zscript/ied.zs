//-------------------------------------------------
// Not-Quite-Improvised Explosive Device
//-------------------------------------------------
/*
	SPECIAL NOTE FOR MAPPERS
	Setting user_startmode to -1 will disable targeting.
*/
enum HDIEDConst{
	HDIED_TID=8495,
}
class HDIEDKit:HDPickup{
	int botid;
	default{
		inventory.amount 1;
		inventory.interhubamount 24;
		inventory.icon "IEDI";
		inventory.pickupmessage "Picked up an IED kit.";
		height 4;radius 4;scale 0.5;
		hdpickup.bulk ENC_IEDKIT;
		tag "IED kit";
		hdpickup.refid HDLD_IEDKIT;
		+hdpickup.multipickup
		+forcexybillboard
	}
	override int getsbarnum(int flags){return botid;}
	override void beginplay(){
		super.beginplay();
		botid=1;
	}
	states{
	spawn:
		IEDK A -1;
		stop;
	use:
		TNT1 A 0{
			if(invoker.amount<1)return;
			class<inventory> which="";
			if(countinv("DudRocketAmmo"))which="DudRocketAmmo";
			else if(countinv("HDRocketAmmo"))which="HDRocketAmmo";
			else{
				A_Log("You need at least one live or dud rocket grenade.",true);
				return;
			}

			A_TakeInventory(which,1,TIF_NOTAKEINFINITE);
			actor ied;
			[bripper,ied]=A_SpawnItemEx("HDIED",0,0,height-12,
				vel.x,vel.y,vel.z,0,
				SXF_SETMASTER|SXF_NOCHECKPOSITION|
				SXF_ABSOLUTEMOMENTUM|SXF_TRANSFERPITCH
			);
			HDIED(ied).botid=invoker.botid;
			ied.A_ChangeVelocity(4*cos(pitch),0,4*sin(-pitch),CVF_RELATIVE);

			if(
				!sv_infiniteammo
				||invoker.amount>1
			)invoker.amount--;
		}fail;
	}
}
class HDEnemyIED:HDIED{
	default{
		//$Category "Misc/Hideous Destructor/Traps"
		//$Title "Enemy IED"
		//$Sprite "IEDSC0"
		-friendly
	}
}
class HDIED:DudRocket{
	int botid;
	int user_startmode;
	default{
		//$Category "Misc/Hideous Destructor/Traps"
		//$Title "Friendly IED"
		//$Sprite "IEDSA0"

		//mm: actively scanning
		-missilemore

		-missile +friendly +lookallaround +nosplashalert +ambush
		-pushable +shootable +noblood +nodamage
		+ismonster
		height 7;radius 4;
		painchance 256;maxtargetrange 96;
		obituary "%o was blown up by an anonymous %k.";
	}
	override int damagemobj(
		actor inflictor,actor source,int damage,
		name mod,int flags,double angle
	){
		if(
			!random(0,7)
			||(!random(0,3)&&(
				mod=="SmallArms0"
				||mod=="SmallArms1"
				||mod=="SmallArms2"
				||mod=="SmallArms3"
			))
		){
			setstatelabel("destroy");
		}
		return 0;
	}
	override void postbeginplay(){
		super.postbeginplay();
		if(master){
			ChangeTid(HDIED_TID);
			if(master.player){
				if(cvar.getcvar("hd_autoactivateied",master.player).getbool()){
					master.A_Log(
						string.format(
							"\cd[IED] \cjDeployed with tag ID \cy%i\cj - \cgARMED AND SEEKING!\cj\n\cjUse \cdied 1 \cy%i\cj in the console to \cgde\cjactivate seeking or \cdied 999 \cy%i\cj to detonate immediately.",
							botid,botid,botid
						),true
					);
					bmissilemore=true;
				}else if(cvar.getcvar("hd_helptext",master.player).getbool())master.A_Log(
					string.format(
						"\cd[IED] \cjDeployed with tag ID \cy%i\cj.\n\cjUse \cdied 1 \cy%i\cj in the console to activate seeking or \cdied 999 \cy%i\cj to detonate immediately.",
						botid,botid,botid
					),true
				);
			}
		}else bmissilemore=user_startmode>-1; //map-placed should be seeking
	}
	void A_IEDScan(){
		if(!bmissilemore)return;
		blockthingsiterator itt=blockthingsiterator.create(self,maxtargetrange);
		while(itt.Next()){
			actor hitactor=itt.thing;
			if(
				hitactor
				&&isHostile(hitactor)
				&&hitactor.bshootable
				&&!hitactor.bnotarget
				&&!hitactor.bnevertarget
				&&(hitactor.bismonster||hitactor.player)
				&&(!hitactor.player||!(hitactor.player.cheats&CF_NOTARGET))
				&&(
					!master
					||!checksight(master)
					||distance3d(master)>256
				)
			){
				tracer=hitactor;
				setstatelabel("detonate");
				return;
			}
		}
	}
	states{
	spawn:
		IEDS A 0 nodelay A_JumpIf(!bmissilemore,"idle");
		IEDS C 35 A_StartSound("ied/beep",CHAN_VOICE);
		IEDS CBCBC 4;
		IEDS ABABABABABABAB 2;
		IEDS ABABAB 1;
	idle:
		IEDS A 10 A_IEDScan();
		IEDS C 10 A_JumpIf(!bmissilemore,"idle");
		loop;
	see:
	melee:
		IEDS A 0;
		goto detonate;
	detonate:
		IEDS A 1{
			bshootable=false;
			bfriendly=false;
			bismonster=false;
			target=master;
		}goto explode;
	destroy:
		IEDS A 0{
			if(!random(0,7))setstatelabel("detonate");
			else if(!random(0,3))stamina=666;
		}goto dismantle;
	grab:
	dismantle:
		IEDS A 0{
			A_SpawnItemEx("HDIEDKit",0,0,height-12,
				vel.x,vel.y,vel.z+4,0,
				SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
			);
			A_SpawnItemEx(stamina==666?"DudRocket":"DudRocketAmmo",0,0,height-12,
				vel.x,vel.y,vel.z+2,0,
				SXF_NOCHECKPOSITION|SXF_ABSOLUTEMOMENTUM
			);
		}stop;
	}
}


//spawn actor
class HDIEDKits:IdleDummy{
	states{
	spawn:
		TNT1 A 0 nodelay{
			A_SpawnItemEx("HDIEDKit",-2,0,0);
			A_SpawnItemEx("HDIEDKit",-2,-2,0);
			A_SpawnItemEx("HDIEDKit",-2,-4,0);
			A_SpawnItemEx("HDIEDKit",0,-2,0);
			A_SpawnItemEx("HDIEDKit",0,-4,0);
			A_SpawnItemEx("HDIEDKit",0,0,0);
		}stop;
	}
}


extend class HDHandlers{
	void SetIED(hdplayerpawn ppp,int iedcmd,int botcmdid){
		let iedinv=HDIEDKit(ppp.findinventory("HDIEDKit"));
		int botid=iedinv?iedinv.botid:1;

		//set IED tag number with -#
		//e.g., "ied -123" will set tag to 123
		if(iedcmd<0){
			if(!iedinv)return;
			iedinv.botid=-iedcmd;
			ppp.A_Log(string.format("\cd[IED] \cjNext IED tag set to \cy%i",-iedcmd),true);
			return;
		}

		//give actual commands
		bool badcommand=true;
		actoriterator it=level.createactoriterator(HDIED_TID,"HDIED");
		actor ied;bool anyieds=false;
		int affected=0;

		while(ied=it.Next()){
			anyieds=true;
			if(
				ied.master==ppp
				&&(
					!botcmdid||
					botcmdid==HDIED(ied).botid
				)
			){
				if(iedcmd==999){
					badcommand=false;
					if(
						ied.checksight(ppp)&&
						ied.distance3d(ppp)<512
					){
						ppp.A_Log(string.format("\cd[IED] \crERROR:\cj IED at [%i,%i] in range of user \crNOT\cj detonated.",ied.pos.x,ied.pos.y),true);
					}
					else{
						ied.setstatelabel("detonate");
						affected++;
					}
				}
				else if(iedcmd==1){
					badcommand=false;
					if(
						ied.checksight(ppp)&&
						ied.distance3d(ppp)<256
					){
						ppp.A_Log(string.format("\cd[IED] \crERROR:\cj IED at [%i,%i] in range of user \crNOT\cj activated.",ied.pos.x,ied.pos.y),true);
					}else{
						ied.bmissilemore=true;
						affected++;
					}
				}
				else if(iedcmd==2){
					badcommand=false;
					ied.bmissilemore=false;
					affected++;
				}
				else if(iedcmd==123){
					badcommand=false;
					ppp.A_Log(string.format("\cd[IED] \cu [\cj%i\cu,\cj%i\cu] \cy%i %s",
						ied.pos.x,ied.pos.y,
						HDIED(ied).botid,
						ied.bmissilemore?"\cgACTIVE":"\cupassive"
					),true);
				}
				else{
					badcommand=true;
					break;
				}
			}
		}
		if(
			!badcommand
			&&iedcmd!=123
		){
			string verb="hacked";
			if(iedcmd==999)verb="\crdetonated";
			else if(iedcmd==1)verb="\cxactivated";
			else if(iedcmd==0)verb="\cydeactivated";
			ppp.A_Log(string.format(
				"\cd[IED] \cj%i IED%s %s%s\cj.",affected,affected==1?"":"s",
				botcmdid?string.format("with tag \ca%i\cj ",botcmdid):"",
				verb
			),true);
		}else if(badcommand)ppp.A_Log(string.format("\cd[IED] \cj%sCommand format:\n\cu ied <option> <tag number> \n\cjOptions:\n 1 = ON\n 2 = OFF\n 999 = DETONATE\n 123 = QUERY\n -n = set tag number\n\cj  tag number on next deployment: \cy%i",anyieds?"":"No IEDs currently deployed.\n",botid),true);
	}
}

