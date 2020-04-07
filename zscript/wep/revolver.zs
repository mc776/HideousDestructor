// ------------------------------------------------------------
// Revolver
// ------------------------------------------------------------
class HDRevolver:HDHandgun{
	bool cylinderopen; //don't use weaponstatus since it shouldn't be saved anyway
	default{
		+hdweapon.fitsinbackpack
		+hdweapon.reverseguninertia
		scale 0.5;
		weapon.selectionorder 49;
		weapon.slotnumber 2;
		weapon.slotpriority 3;
		weapon.kickback 30;
		weapon.bobrangex 0.1;
		weapon.bobrangey 0.6;
		weapon.bobspeed 2.5;
		weapon.bobstyle "normal";
		obituary "%o got capped by %k's six-pea shooter.";
		inventory.pickupmessage "You got the revolver!";
		tag "revolver";
		hdweapon.refid HDLD_REVOLVER;
		hdweapon.barrelsize 6,0.3,0.5; //physically longer than auto but can shoot at contact
	}
	override double gunmass(){
		return 9;
	}
	override double weaponbulk(){
		double blk=0;
		for(int i=BUGS_CYL1;i<=BUGS_CYL6;i++){
			int wi=weaponstatus[i];
			if(wi==BUGS_MASTERBALL)blk+=ENC_355_LOADED;
			else if(wi==BUGS_NINEMIL)blk+=ENC_9_LOADED;
		}
		return blk+32;
	}
	override string,double getpickupsprite(){
		return "REVLA0",1.;
	}

	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		if(sb.hudlevel==1){
			sb.drawimage("PRNDA0",(-47,-10),sb.DI_SCREEN_CENTER_BOTTOM,scale:(2.1,2.55));
			sb.drawnum(hpl.countinv("HDRevolverAmmo"),-44,-8,sb.DI_SCREEN_CENTER_BOTTOM);
			int ninemil=hpl.countinv("HDPistolAmmo");
			if(ninemil>0){
				sb.drawimage("PRNDA0",(-64,-10),sb.DI_SCREEN_CENTER_BOTTOM,scale:(2.1,2.1));
				sb.drawnum(ninemil,-60,-8,sb.DI_SCREEN_CENTER_BOTTOM);
			}
		}
		int plf=hpl.player.getpsprite(PSP_WEAPON).frame;
		for(int i=BUGS_CYL1;i<=BUGS_CYL6;i++){
			double drawangle=i*(360./6.)-150;
			vector2 cylpos;
			if(plf==4){
				drawangle-=45.;
				cylpos=(-28,-14);
			}else if(cylinderopen){
				drawangle-=90;
				cylpos=(-32,-12);
			}else{
				cylpos=(-20,-20);
			}
			vector2 drawpos=cylpos+(cos(drawangle),sin(drawangle))*5;
			sb.fill(
				hdw.weaponstatus[i]>0?
				color(255,240,230,40)
				:color(200,30,26,24),
				drawpos.x,
				drawpos.y,
				3,3,
				sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT
			);
		}
	}
	override string gethelptext(){
		if(cylinderopen)return
		WEPHELP_FIRE.." Close cylinder\n"
		..WEPHELP_ALTFIRE.." Cycle cylinder \(Hold "..WEPHELP_ZOOM.." to reverse\)\n"
		..WEPHELP_UNLOAD.." Hit extractor \(double-tap to dump live rounds\)\n"
		..WEPHELP_RELOAD.." Load round \(Hold "..WEPHELP_FIREMODE.." to force using 9mm\)\n"
		;
		return
		WEPHELP_FIRESHOOT
		..WEPHELP_ALTFIRE.." Pull back hammer\n"
		..WEPHELP_ALTRELOAD.."/"..WEPHELP_FIREMODE.."  Quick-Swap (if available)\n"
		..WEPHELP_UNLOAD.."/"..WEPHELP_RELOAD.." Open cylinder\n"
		;
	}
	override void DrawSightPicture(
		HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl,
		bool sightbob,vector2 bob,double fov,bool scopeview,actor hpc,string whichdot
	){
		int cx,cy,cw,ch;
		[cx,cy,cw,ch]=screen.GetClipRect();
		vector2 scc;
		vector2 bobb=bob*1.6;

		sb.SetClipRect(
			-8+bob.x,-4+bob.y,16,10,
			sb.DI_SCREEN_CENTER
		);
		scc=(0.9,0.9);
		bobb.y=clamp(bobb.y,-8,8);

		sb.drawimage(
			"revfst",(0,0)+bobb,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			alpha:0.9,scale:scc
		);
		sb.SetClipRect(cx,cy,cw,ch);
		sb.drawimage(
			"revbkst",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
			scale:scc
		);
	}
	override void DropOneAmmo(int amt){
		if(owner){
			amt=clamp(amt,18,60);
			if(owner.countinv("HDRevolverAmmo"))owner.A_DropInventory("HDRevolverAmmo",amt);
			else owner.A_DropInventory("HDPistolAmmo",amt);
		}
	}
	override void ForceBasicAmmo(){
		owner.A_SetInventory("HDRevolverAmmo",6);
	}
	override void initializewepstats(bool idfa){
		weaponstatus[BUGS_CYL1]=BUGS_MASTERBALL;
		weaponstatus[BUGS_CYL2]=BUGS_MASTERBALL;
		weaponstatus[BUGS_CYL3]=BUGS_MASTERBALL;
		weaponstatus[BUGS_CYL4]=BUGS_MASTERBALL;
		weaponstatus[BUGS_CYL5]=BUGS_MASTERBALL;
		weaponstatus[BUGS_CYL6]=BUGS_MASTERBALL;
	}

	action bool HoldingRightHanded(){
		bool righthanded=invoker.wronghand;
		righthanded=
		(
			righthanded
			&&Wads.CheckNumForName("id",0)!=-1
		)||(
			!righthanded
			&&Wads.CheckNumForName("id",0)==-1
		);
		return righthanded;
	}
	action void A_CheckRevolverHand(){
		bool righthanded=HoldingRightHanded();
		if(righthanded)player.getpsprite(PSP_WEAPON).sprite=getspriteindex("RRVGA0");
		else player.getpsprite(PSP_WEAPON).sprite=getspriteindex("REVGA0");
	}
	action void A_RotateCylinder(bool clockwise=true){
		invoker.RotateCylinder(clockwise);
		A_StartSound("weapons/deinocyl",8);
	}
	void RotateCylinder(bool clockwise=true){
		if(clockwise){
			int cylbak=weaponstatus[BUGS_CYL1];
			weaponstatus[BUGS_CYL1]=weaponstatus[BUGS_CYL6];
			weaponstatus[BUGS_CYL6]=weaponstatus[BUGS_CYL5];
			weaponstatus[BUGS_CYL5]=weaponstatus[BUGS_CYL4];
			weaponstatus[BUGS_CYL4]=weaponstatus[BUGS_CYL3];
			weaponstatus[BUGS_CYL3]=weaponstatus[BUGS_CYL2];
			weaponstatus[BUGS_CYL2]=cylbak;
		}else{
			int cylbak=weaponstatus[BUGS_CYL1];
			weaponstatus[BUGS_CYL1]=weaponstatus[BUGS_CYL2];
			weaponstatus[BUGS_CYL2]=weaponstatus[BUGS_CYL3];
			weaponstatus[BUGS_CYL3]=weaponstatus[BUGS_CYL4];
			weaponstatus[BUGS_CYL4]=weaponstatus[BUGS_CYL5];
			weaponstatus[BUGS_CYL5]=weaponstatus[BUGS_CYL6];
			weaponstatus[BUGS_CYL6]=cylbak;
		}
	}
	action void A_LoadRound(){
		if(invoker.weaponstatus[BUGS_CYL1]>0)return;
		bool useninemil=(
			player.cmd.buttons&BT_FIREMODE
			||!countinv("HDRevolverAmmo")
		);
		if(useninemil&&!countinv("HDPistolAmmo"))return;
		class<inventory>ammotype=useninemil?"HDPistolAmmo":"HDRevolverAmmo";
		A_TakeInventory(ammotype,1,TIF_NOTAKEINFINITE);
		invoker.weaponstatus[BUGS_CYL1]=useninemil?BUGS_NINEMIL:BUGS_MASTERBALL;
		A_StartSound("weapons/deinoload",8,CHANF_OVERLAP);
	}
	action void A_OpenCylinder(){
		A_StartSound("weapons/deinoopen",8);
		invoker.weaponstatus[0]&=~BUGF_COCKED;
		invoker.cylinderopen=true;
		A_SetHelpText();
	}
	action void A_CloseCylinder(){
		A_StartSound("weapons/deinoclose",8);
		invoker.cylinderopen=false;
		A_SetHelpText();
	}
	action void A_HitExtractor(){
		double cosp=cos(pitch);
		for(int i=BUGS_CYL1;i<=BUGS_CYL6;i++){
			int thischamber=invoker.weaponstatus[i];
			if(thischamber<1)continue;
			if(
				thischamber==BUGS_NINEMILSPENT
				||thischamber==BUGS_NINEMIL
				||thischamber==BUGS_MASTERBALLSPENT
			){
				actor aaa=spawn(
					thischamber==BUGS_NINEMIL?"HDLoose9mm"
						:thischamber==BUGS_MASTERBALLSPENT?"HDSpent355"
						:"HDSpent9mm",
					(pos.xy,pos.z+height-10)
					+(cosp*cos(angle),cosp*sin(angle),sin(pitch))*7,
					ALLOW_REPLACE
				);
				aaa.vel=vel+(frandom(-1,1),frandom(-1,1),-1);
				invoker.weaponstatus[i]=0;
			}
		}
		A_StartSound("weapons/deinoeject",8,CHANF_OVERLAP);
	}
	action void A_ExtractAll(){
		double cosp=cos(pitch);
		bool gotany=false;
		for(int i=BUGS_CYL1;i<=BUGS_CYL6;i++){
			int thischamber=invoker.weaponstatus[i];
			if(thischamber<1)continue;
			if(
				thischamber==BUGS_NINEMILSPENT
				||thischamber==BUGS_MASTERBALLSPENT
			){
				actor aaa=spawn("HDSpent9mm",
					(pos.xy,pos.z+height-14)
					+(cosp*cos(angle),cosp*sin(angle),sin(pitch)-2)*3,
					ALLOW_REPLACE
				);
				aaa.vel=vel+(frandom(-0.3,0.3),frandom(-0.3,0.3),-1);
				if(thischamber==BUGS_MASTERBALLSPENT)aaa.scale.y=0.85;
				invoker.weaponstatus[i]=0;
			}else{
				//give or spawn either 9mm or 355
				class<inventory>ammotype=
					thischamber==BUGS_MASTERBALL?
					"HDRevolverAmmo":"HDPistolAmmo";
				if(A_JumpIfInventory(ammotype,0,"null")){
					actor aaa=spawn(ammotype,
						(pos.xy,pos.z+height-14)
						+(cosp*cos(angle),cosp*sin(angle),sin(pitch)-2)*3,
						ALLOW_REPLACE
					);
					aaa.vel=vel+(frandom(-1,1),frandom(-1,1),-1);
				}else{
					A_GiveInventory(ammotype,1);
					gotany=true;
				}
				invoker.weaponstatus[i]=0;
			}
		}
		if(gotany)A_StartSound("weapons/pocket",9);
	}
	action void A_FireRevolver(){
		invoker.weaponstatus[0]&=~BUGF_COCKED;
		int cyl=invoker.weaponstatus[BUGS_CYL1];
		if(
			cyl!=BUGS_MASTERBALL
			&&cyl!=BUGS_NINEMIL
		){
			A_StartSound("weapons/deinoclick",8,CHANF_OVERLAP);
			return;
		}
		invoker.weaponstatus[BUGS_CYL1]--;
		bool masterball=cyl==BUGS_MASTERBALL;

		let bbb=HDBulletActor.FireBullet(self,masterball?"HDB_355":"HDB_9",spread:1.,speedfactor:frandom(0.99,1.01));
		if(
			frandom(0,ceilingz-floorz)<bbb.speed*(masterball?0.4:0.3)
		)A_AlertMonsters(masterball?512:256);

		A_GunFlash();
		A_Light1();
		A_ZoomRecoil(0.995);
		HDFlashAlpha(masterball?72:64);
		A_StartSound("weapons/deinoblast1",CHAN_WEAPON,CHANF_OVERLAP);
		if(masterball){
			A_MuzzleClimb(-frandom(0.8,1.6),-frandom(1.6,2.));
			A_StartSound("weapons/deinoblast1",CHAN_WEAPON,CHANF_OVERLAP,0.5);
			A_StartSound("weapons/deinoblast2",CHAN_WEAPON,CHANF_OVERLAP,0.4);
		}else{
			A_MuzzleClimb(-frandom(0.6,1.2),-frandom(0.8,1.8));
			A_StartSound("weapons/deinoblast2",CHAN_WEAPON,CHANF_OVERLAP,0.3);
		}
	}
	int cooldown;
	action void A_ReadyOpen(){
		A_WeaponReady(WRF_NOFIRE|WRF_ALLOWUSER3);
		if(justpressed(BT_ALTATTACK))setweaponstate("open_rotatecylinder");
		else if(justpressed(BT_RELOAD)){
			if(
				(
					invoker.weaponstatus[BUGS_CYL1]>0
					&&invoker.weaponstatus[BUGS_CYL2]>0
					&&invoker.weaponstatus[BUGS_CYL3]>0
					&&invoker.weaponstatus[BUGS_CYL4]>0
					&&invoker.weaponstatus[BUGS_CYL5]>0
					&&invoker.weaponstatus[BUGS_CYL6]>0
				)||(
					!countinv("HDPistolAmmo")
					&&!countinv("HDRevolverAmmo")
				)
			)setweaponstate("open_closecylinder");
			else setweaponstate("open_loadround");
		}else if(justpressed(BT_ATTACK))setweaponstate("open_closecylinder");
		else if(justpressed(BT_UNLOAD)){
			if(!invoker.cooldown){
				setweaponstate("open_dumpcylinder");
				invoker.cooldown=6;
			}else{
				setweaponstate("open_dumpcylinder_all");
			}
		}
		if(invoker.cooldown>0)invoker.cooldown--;
	}
	action void A_RoundReady(int rndnm){
		int gunframe=-1;
		if(invoker.weaponstatus[rndnm]>0)gunframe=player.getpsprite(PSP_WEAPON).frame;
		let thissprite=player.getpsprite(BUGS_OVRCYL+rndnm);
		switch(gunframe){
		case 4: //E
			thissprite.frame=0;
			break;
		case 5: //F
			thissprite.frame=1;
			break;
		case 6: //G
			thissprite.frame=pressingzoom()?4:2;
			break;
		default:
			thissprite.sprite=getspriteindex("TNT1A0");
			thissprite.frame=0;
			return;break;
		}
	}
	action void A_CockHammer(bool yes=true){
		if(yes)invoker.weaponstatus[0]|=BUGF_COCKED;
		else invoker.weaponstatus[0]&=~BUGF_COCKED;
	}


/*
	A normal ready
	B ready cylinder midframe
	C hammer fully cocked (maybe renumber these lol)
	D recoil frame
	E cylinder swinging out - left hand passing to right
	F cylinder swung out - held in right hand, working chamber in middle
	G cylinder swung out midframe
*/
	states{
	spawn:
		REVL A -1;
		stop;
	round1:RVR1 A 1 A_RoundReady(BUGS_CYL1);wait;
	round2:RVR2 A 1 A_RoundReady(BUGS_CYL2);wait;
	round3:RVR3 A 1 A_RoundReady(BUGS_CYL3);wait;
	round4:RVR4 A 1 A_RoundReady(BUGS_CYL4);wait;
	round5:RVR5 A 1 A_RoundReady(BUGS_CYL5);wait;
	round6:RVR6 A 1 A_RoundReady(BUGS_CYL6);wait;
	select0:
		REVG A 0{
			if(!countinv("NulledWeapon"))invoker.wronghand=false;
			A_TakeInventory("NulledWeapon");
			A_CheckRevolverHand();
			invoker.cylinderopen=false;
			invoker.weaponstatus[0]&=~BUGF_COCKED;

			//uncock all spare revolvers
			if(findinventory("SpareWeapons")){
				let spw=SpareWeapons(findinventory("SpareWeapons"));
				for(int i=0;i<spw.weapontype.size();i++){
					if(spw.weapontype[i]==invoker.getclassname()){
						string spw2=spw.weaponstatus[i];
						string spw1=spw2.left(spw2.indexof(","));
						spw2=spw2.mid(spw2.indexof(","));
						int stat0=spw1.toint();
						stat0&=~BUGF_COCKED;
						spw.weaponstatus[i]=stat0..spw2;
					}
				}
			}

			A_Overlay(BUGS_OVRCYL+BUGS_CYL1,"round1");
			A_Overlay(BUGS_OVRCYL+BUGS_CYL2,"round2");
			A_Overlay(BUGS_OVRCYL+BUGS_CYL3,"round3");
			A_Overlay(BUGS_OVRCYL+BUGS_CYL4,"round4");
			A_Overlay(BUGS_OVRCYL+BUGS_CYL5,"round5");
			A_Overlay(BUGS_OVRCYL+BUGS_CYL6,"round6");
		}
		---- A 1 A_Raise();
		---- A 1 A_Raise(40);
		---- A 1 A_Raise(40);
		---- A 1 A_Raise(25);
		---- A 1 A_Raise(20);
		wait;
	deselect0:
		REVG A 0 A_CheckRevolverHand();
		#### D 0 A_JumpIf(!invoker.cylinderopen,"deselect0a");
		REVG E 2;
		REVG A 0 A_CloseCylinder();
		REVG A 0 A_CheckRevolverHand();
		goto deselect0a;
	deselect0a:
		#### AD 1 A_Lower();
		---- A 1 A_Lower(20);
		---- A 1 A_Lower(34);
		---- A 1 A_Lower(50);
		wait;
	ready:
		REVG A 0 A_CheckRevolverHand();
		---- A 0 A_JumpIf(invoker.cylinderopen,"readyopen");
		#### C 0 A_JumpIf(invoker.weaponstatus[0]&BUGF_COCKED,2);
		#### A 0;
		---- A 1 A_WeaponReady(WRF_ALLOWRELOAD|WRF_ALLOWUSER1|WRF_ALLOWUSER2|WRF_ALLOWUSER3|WRF_ALLOWUSER4);
		goto readyend;
	fire:
		#### A 0 A_JumpIf(invoker.weaponstatus[0]&BUGF_COCKED,"hammertime");
		#### B 1 offset(0,34);
		#### C 2 offset(0,36) A_RotateCylinder();
		#### A 0 offset(0,32);
	hammertime:
		#### A 0 A_ClearRefire();
		#### A 1 A_FireRevolver();
		goto nope;
	firerecoil:
		#### D 2;
		#### A 0;
		goto nope;
	flash:
		REVF A 1 bright;
		---- A 0 A_Light0();
		---- A 0 setweaponstate("firerecoil");
		stop;
		RRVG ABCD 0;
		stop;
	altfire:
		---- A 0 A_JumpIf(invoker.weaponstatus[0]&BUGF_COCKED,"uncock");
		#### B 1 offset(0,34) A_ClearRefire();
		#### B 2 offset(0,36) A_RotateCylinder();
	cocked:
		#### C 0 A_CockHammer();
		---- A 0 A_JumpIf(pressingaltfire(),"nope");
		goto readyend;
	uncock:
		#### C 1 offset(0,38);
		#### B 1 offset(0,34);
		#### A 2 offset(0,36) A_StartSound("weapons/deinocyl",8,CHANF_OVERLAP);
		#### A 0 A_CockHammer(false);
		goto nope;
	reload:
	unload:
		#### C 0 A_JumpIf(!(invoker.weaponstatus[0]&BUGF_COCKED),3);
		#### B 2 offset(0,35)A_CockHammer(false);
		#### A 2 offset(0,33);
		#### A 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite!=getspriteindex("RRVGA0"),"openslow");
		REVG E 3 A_OpenCylinder();
		goto readyopen;
	openslow:
		REVG A 1 offset(2,39);
		REVG A 1 offset(4,50);
		REVG A 1 offset(8,64);
		REVG A 1 offset(10,86);
		REVG A 1 offset(12,96);
		REVG E 1 offset(-7,66);
		REVG E 1 offset(-6,56);
		REVG E 1 offset(-2,40);
		REVG E 1 offset(0,32);
		REVG E 1 A_OpenCylinder();
		goto readyopen;
	readyopen:
		REVG F 1 A_ReadyOpen();
		goto readyend;
	open_rotatecylinder:
		REVG G 2 A_RotateCylinder(pressingzoom());
		REVG F 2 A_JumpIf(!pressingaltfire(),"readyopen");
		loop;
	open_loadround:
		REVG F 2;
		REVG F 1 A_LoadRound();
		goto open_rotatecylinder;
	open_closecylinder:
		REVG E 2 A_JumpIf(pressingfire(),"open_fastclose");
		REVG E 0 A_CloseCylinder();
		REVG A 0 A_CheckRevolverHand();
		#### A 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("RRVGA0"),"nope");
		REVG E 1 offset(0,32);
		REVG E 1 offset(-2,40);
		REVG E 1 offset(-6,56);
		REVG E 1 offset(-7,66);
		REVG A 1 offset(12,96);
		REVG A 1 offset(10,86);
		REVG A 1 offset(8,64);
		REVG A 1 offset(4,50);
		REVG A 1 offset(2,39);
		goto nope;
	open_fastclose:
		REVG E 2;
		REVG A 0{
			A_CloseCylinder();
			invoker.wronghand=(Wads.CheckNumForName("id",0)!=-1);
			A_CheckRevolverHand();
		}goto nope;
	open_dumpcylinder:
		REVG F 3 A_HitExtractor();
		goto readyopen;
	open_dumpcylinder_all:
		REVG F 1 offset(0,34);
		REVG F 1 offset(0,42);
		REVG F 1 offset(0,54);
		REVG F 1 offset(0,68);
		TNT1 A 6 A_ExtractAll();
		REVG F 1 offset(0,68);
		REVG F 1 offset(0,54);
		REVG F 1 offset(0,42);
		REVG F 1 offset(0,34);
		goto readyopen;

	user1:
	user2:
	swappistols:
		---- A 0 A_SwapHandguns();
		#### D 0 A_JumpIf(player.getpsprite(PSP_WEAPON).sprite==getspriteindex("RRVGA0"),"swappistols2");
	swappistols1:
		TNT1 A 0 A_Overlay(1025,"raiseright");
		TNT1 A 0 A_Overlay(1026,"lowerleft");
		TNT1 A 5;
		RRVG C 0 A_JumpIf(invoker.weaponstatus[0]&BUGF_COCKED,"nope");
		RRVG A 0;
		goto nope;
	swappistols2:
		TNT1 A 0 A_Overlay(1025,"raiseleft");
		TNT1 A 0 A_Overlay(1026,"lowerright");
		TNT1 A 5;
		REVG C 0 A_JumpIf(invoker.weaponstatus[0]&BUGF_COCKED,"nope");
		REVG A 0;
		goto nope;
	lowerleft:
		REVG C 0 A_JumpIf(invoker.weaponstatus[0]&BUGF_COCKED,2);
		REVG A 0;
		---- A 1 offset(-6,38);
		---- A 1 offset(-12,48);
		REVG D 1 offset(-20,60);
		REVG D 1 offset(-34,76);
		REVG D 1 offset(-50,86);
		stop;
	lowerright:
		RRVG C 0 A_JumpIf(invoker.weaponstatus[0]&BUGF_COCKED,2);
		RRVG A 0;
		---- A 1 offset(6,38);
		---- A 1 offset(12,48);
		RRVG D 1 offset(20,60);
		RRVG D 1 offset(34,76);
		RRVG D 1 offset(50,86);
		stop;
	raiseleft:
		REVG D 1 offset(-50,86);
		REVG D 1 offset(-34,76);
		REVG C 0 A_JumpIf(invoker.weaponstatus[0]&BUGF_COCKED,2);
		REVG A 0;
		---- A 1 offset(-20,60);
		---- A 1 offset(-12,48);
		---- A 1 offset(-6,38);
		stop;
	raiseright:
		RRVG D 1 offset(50,86);
		RRVG D 1 offset(34,76);
		RRVG C 0 A_JumpIf(invoker.weaponstatus[0]&BUGF_COCKED,2);
		RRVG A 0;
		---- A 1 offset(20,60);
		---- A 1 offset(12,48);
		---- A 1 offset(6,38);
		stop;
	whyareyousmiling:
		#### D 1 offset(0,38);
		#### D 1 offset(0,48);
		#### D 1 offset(0,60);
		TNT1 A 7;
		REVG A 0{
			invoker.wronghand=!invoker.wronghand;
			A_CheckRevolverHand();
		}
		#### D 1 offset(0,60);
		#### D 1 offset(0,48);
		#### D 1 offset(0,38);
		goto nope;
	}
}
enum DeinovolverStats{
	//chamber 1 is the shooty one
	BUGS_CYL1=1,
	BUGS_CYL2=2,
	BUGS_CYL3=3,
	BUGS_CYL4=4,
	BUGS_CYL5=5,
	BUGS_CYL6=6,
	BUGS_OVRCYL=355,

	//odd means spent
	BUGS_NINEMILSPENT=1,
	BUGS_NINEMIL=2,
	BUGS_MASTERBALLSPENT=3,
	BUGS_MASTERBALL=4,

	BUGF_RIGHTHANDED=1,
	BUGF_COCKED=2,
}
class HDSpent355:HDSpent9mm{default{yscale 0.85;}}
class HDRevolverAmmo:HDPistolAmmo{
	default{
		xscale 0.7;
		yscale 0.85;
		inventory.pickupmessage "Picked up a .355 round.";
		hdpickup.refid HDLD_355;
		tag ".355 round";
		hdpickup.bulk ENC_355;
	}
	override void GetItemsThatUseThis(){
		itemsthatusethis.push("HDRevolver");
	}
	override void SplitPickup(){
		SplitPickupBoxableRound(10,72,"HD355BoxPickup","TEN9A0","PRNDA0");
	}
}
class HD355BoxPickup:HDUPK{
	default{
		//$Category "Ammo/Hideous Destructor/"
		//$Title "Box of .355"
		//$Sprite "3BOXA0"
		scale 0.4;
		hdupk.amount 72;
		hdupk.pickupsound "weapons/pocket";
		hdupk.pickupmessage "Picked up some .355 ammo.";
		hdupk.pickuptype "HDRevolverAmmo";
	}
	states{
	spawn:
		3BOX A -1;
	}
}
class DeinoSpawn:HD355BoxPickup{
	override void postbeginplay(){
		super.postbeginplay();
		spawn("HDRevolver",pos,ALLOW_REPLACE);
	}
}


