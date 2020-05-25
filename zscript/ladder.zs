//-------------------------------------------------
// Ladder
//-------------------------------------------------

//show where the ladder is hanging
//no it doesn't swing, math is hard :(
class hdladdersection:IdleDummy{
	int secnum;
	default{
		+wallsprite
	}
	states{
	spawn:
		LADD B 0 nodelay A_JumpIf(master&&target,1);
		stop;
		LADD B 1 setz(max(target.floorz,master.pos.z-LADDER_SECTIONLENGTH*secnum));
		loop;
	}
}
class hdladdertop:hdactor{
	default{
		//$Category "Misc/Hideous Destructor/"
		//$Title "Ladder Top"
		//$Sprite "LADDA0"

		+flatsprite
		+nointeraction
		+notrigger
		+blockasplayer

		height 4;radius 10;
		maxstepheight 64;
		maxdropoffheight 640;
		mass int.MAX;
	}
	states{
	spawn:
		LADD A 1 nodelay setz(getzat()+4);
		wait;
	}
	override void postbeginplay(){
		super.postbeginplay();
		A_SpawnParticle("darkred",0,10);
		pitch=18;
		bmissile=false;master=target;
		setz(floorz);
		fcheckposition tm;
		vector2 mvlast=pos.xy;
		vector2 mv=angletovector(angle,2);
		for(int i=0;i<20;i++){

			if(
				!!master //don't break if placed by mapper
				&&!checkmove(mvlast,PCM_NOACTORS,tm)
			)break;

			A_UnsetSolid();
			mvlast+=mv;

			//found a place for the ladder to hang down
			double htdiff=clamp(floorz-tm.floorz,0,LADDER_MAX);
			if(
				htdiff
			){

				//spawn the ladder end
				target=spawn("hdladderbottom",tm.pos,ALLOW_REPLACE);
				target.target=self;
				target.master=master;
				target.angle=angle;
				target.pitch=-27;

				vector2 mv2=mv*0.02;
				vector3 newpos=tm.pos;

				//spawn the ladder sections
				double sectionlength=min(htdiff,LADDER_MAX)/LADDER_SECTIONS;
				for(int i=1;i<=LADDER_SECTIONS;i++){
					newpos.xy+=mv2;
					let sss=hdladdersection(spawn("hdladdersection",newpos,ALLOW_REPLACE));
					sss.master=self;sss.target=target;sss.angle=angle+frandom(-1.,1.);
					sss.secnum=i;
					target.setorigin(newpos+(0,0,-sectionlength*i),true);
					if(master){
						sss.translation=master.translation;
						target.translation=master.translation;
					}
				}

				//reposition the thing
				setorigin((tm.pos.xy-mv*radius,floorz),true);

				//only complete if start or within throwable range, else abort
				if(!master)return;
				if(pos.z-master.pos.z<108){
					A_StartSound("misc/ladder");
					master.A_Log(string.format("You hang up a ladder.%s",master.getcvar("hd_helptext")?" Use the ladder to climb.":""),true);
					master.A_TakeInventory("PortableLadder",1);
					return;
				}
			}
		}

		//if there's no lower floor to drop the ladder, abort.
		if(master){
			master.A_Log("Can't hang a ladder here.",true);
		}else{
			actor hdl=spawn("PortableLadder",pos,ALLOW_REPLACE);
			hdl.A_StartSound("misc/ladder");
		}
		destroy();
	}
}
const LADDER_SECTIONLENGTH=12.;
const LADDER_MAX=LADDER_SECTIONLENGTH*67.;
const LADDER_SECTIONS=LADDER_MAX/LADDER_SECTIONLENGTH;

class HDLadderProxy:HDActor{
	default{
		+nogravity +invisible
		height 56;radius 10;
		mass int.MAX;
	}
	override bool used(actor user){
		if(master) return master.used(user);
		else destroy();
		return false;
	}
}

class hdladderbottom:hdactor{
	default{
		+nogravity +flatsprite
		height 56;radius 10;
		mass int.MAX;
	}
	actor users[MAXPLAYERS];
	override bool used(actor user){
		double upz=user.pos.z;
		if(
			upz>target.pos.z+24  
			||upz+user.height*1.3<pos.z
		)return false;
		int usernum=user.playernumber();
		if(users[usernum]){
			disengageladder(usernum);
			return false;
		}

		//check if user can reach
		if(distance2d(user)>16)return false;

		users[user.playernumber()]=user;
		user.vel.z+=1;
		user.A_Log(string.format("You climb the ladder.%s",user.getcvar("hd_helptext")?" Use again or jump to disengage; crouch and jump to pull down the ladder with you.":""),true);
		return true;
	}
	void disengageladder(int usernum,bool message=true){
		actor currentuser=users[usernum];
		if(!currentuser)return;
		if(playerpawn(currentuser))playerpawn(currentuser).viewbob=1.;
		if(message)currentuser.A_Log("Ladder disengaged.",true);
		users[usernum]=null;
	}
	override void postbeginplay(){
		if(CurSector.GetPortalType(Sector.Floor)==SectorPortal.TYPE_LINKEDPORTAL){
			SectorPortal portal=Level.SectorPortals[CurSector.Portals[Sector.Floor]];

			vector3 newPos=(pos.xy+portal.mDisplacement, 0);
			newPos.z=portal.mDestination.FloorPlane.ZAtPoint(newPos.xy);

			HDLadderProxy(Spawn("HDLadderProxy",newPos,ALLOW_REPLACE)).master=self;
		}
	}
	override void ondestroy(){
		for(int i=0;i<MAXPLAYERS;i++){
			actor currentuser=users[i];
			if(playerpawn(currentuser))playerpawn(currentuser).viewbob=1.;
		}
		super.ondestroy();
	}
	override void tick(){
		actor currentuser;
		double currentuserz;

		if(!target){destroy();return;}
		setz(
			clamp(floorz,
				max(target.pos.z-LADDER_MAX,floorz),
				target.pos.z+LADDER_MAX
			)
		);

		A_SetSize(-1,min(LADDER_MAX,target.pos.z-pos.z)+32);

		for(int usernum=0; usernum<MAXPLAYERS; usernum++){
			currentuser=users[usernum];

			if(!currentuser||!target)continue;
			if(currentuser.health<1){disengageladder(usernum,false);continue;}


			//check if facing the ladder
			bool facing=abs(
				deltaangle(
					currentuser.angleto(self,true),
					currentuser.angle
				)
			)<90;

			//checks when above ladder
			if(
				currentuser.pos.z>target.pos.z-16
			){
				//throw in some use of controls still
				if(currentuser.player){
					int bt=currentuser.player.cmd.buttons;
					if(
						bt&BT_JUMP
						||bt&BT_SPEED
						||(!facing&&bt&BT_USE)
					){
						if(
							bt&BT_JUMP
							&&currentuser.height<
							getdefaultbytype(currentuser.getclass()).height
						){
							currentuser.A_Log("Ladder taken up.",true);
							actor hdl=spawn("PortableLadder",target.pos,ALLOW_REPLACE);
							hdl.A_StartSound("misc/ladder");
							hdl.translation=translation;
							target.destroy();
							if(self)destroy();
						}else disengageladder(usernum);
						continue;
					}
					if(currentuser.floorz<currentuser.pos.z){
						double fm=currentuser.player.cmd.forwardmove*0.000125;
						double sm=currentuser.player.cmd.sidemove*0.000125;
						if(fm||sm)currentuser.trymove(
							currentuser.pos.xy
							+angletovector(currentuser.angle,fm)
							+angletovector(currentuser.angle-90,sm),
							true
						);
					}
				}
				if(target.distance2d(currentuser)>40){  
					//account for sector portal offset
					vector2 tp=currentuser.pos.xy-vec2to(currentuser);
					currentuser.setorigin((
						clamp(currentuser.pos.x,
							tp.x-40,
							tp.x+40
						),
						clamp(currentuser.pos.y,
							tp.y-40,
							tp.y+40
						),
						min(currentuser.pos.z,target.pos.z+24)
					),true);
				}
				continue;
			}
			if(distance2d(currentuser)<3.)currentuser.A_ChangeVelocity(-1,0,0,CVF_RELATIVE);
			currentuser.vel.xy*=0.7;
			currentuser.vel.z=0;

			//climbing interface
			if(currentuser.player){
				double spm=currentuser.speed;
				double fm=currentuser.player.cmd.forwardmove;
				if(fm>0)fm=spm;else if(fm<0)fm=-spm;else fm=0;
				double sm=currentuser.player.cmd.sidemove;
				if(sm>0)sm=spm;else if(sm<0)sm=-spm;else sm=0;

				int bt=currentuser.player.cmd.buttons;

				//barehanded and descending are faster
				if(facing){
					if(!sm&&fm<0)fm*=1.5;
					weapon wp=currentuser.player.readyweapon;
					if(wp is "HDFist"||wp is "NullWeapon"){
						sm*=2;fm*=2;
					}
				}else fm*=-1;

				if(currentuser.countinv("PowerStrength"))fm*=1.8;
				if(hdplayerpawn(currentuser)&&hdplayerpawn(currentuser).stunned)
					fm*=0.2;

				//apply climbing
				currentuserz=currentuser.pos.z+fm;
				if(sm)currentuser.trymove(
					currentuser.pos.xy+angletovector(currentuser.angle-90,sm),
					true
				);
				if(fm||sm)playerpawn(currentuser).viewbob=1;
					else playerpawn(currentuser).viewbob=0.;

				//jump also disengages
				//crouch+jump to remove the rope
				if(bt){
					if(bt&BT_JUMP){
						vector3 vl=(
							vec2to(currentuser).unit()*3,
							4
						);
						if(currentuser.countinv("PowerStrength"))vl*=2.2;
						currentuser.vel+=vl;

						if(
							currentuser.height<
							getdefaultbytype(currentuser.getclass()).height
						){
							currentuser.A_Log("Ladder taken down.",true);

							actor hdl=spawn("PortableLadder",target.pos,ALLOW_REPLACE);
							hdl.A_StartSound("misc/ladder");
							hdl.vel.xy=vl.xy*2;
							hdl.translation=translation;

							GrabThinker.Grab(currentuser,hdl);

							target.destroy();
							if(self)destroy();
							continue;
						}else disengageladder(usernum);
					}else if(!facing&&bt&BT_USE)disengageladder(usernum);
				}
			}
			if(!currentuser)continue;

			vector2 relativepos=currentuser.pos.xy-vec2to(currentuser);
			currentuserz=max(currentuserz,pos.z-currentuser.height*1.3);
			currentuserz=min(currentuserz,currentuser.ceilingz-currentuser.height);
			currentuser.setorigin((
				clamp(currentuser.pos.x,
					relativepos.x-16,
					relativepos.x+16
				),
				clamp(currentuser.pos.y,
					relativepos.y-16,
					relativepos.y+16
				),
				currentuserz
			),true);
		}
		//nexttic
		if(CheckNoDelay()){
			if(tics>0)tics--;  
			while(!tics){
				if(!SetState(CurState.NextState)){
					return;
				}
			}
		}
	}
	states{
	spawn:
		LADD C -1;wait;
	}
}
class PortableLadder:HDPickup{
	default{
		inventory.icon "LADDD0";
		inventory.pickupmessage "Picked up a ladder.";
		height 20;radius 8;
		hdpickup.bulk ENC_LADDER;
		hdpickup.refid HDLD_LADDER;
		tag "portable ladder";
	}
	states{
	spawn:
		LADD D -1;
		stop;
	use:
		TNT1 A 0{
			actor aaa;int bbb;
			[bbb,aaa]=A_SpawnItemEx(
				"HDLadderTop",18*cos(pitch),0,48-18*sin(pitch),
				flags:SXF_NOCHECKPOSITION|SXF_SETTARGET
			);if(!aaa)return;

			//only face player if above player's stepheight
			if(aaa.floorz>pos.z+maxstepheight){  
				aaa.angle+=180;
			}
		}fail;
	}
}



