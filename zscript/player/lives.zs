// ------------------------------------------------------------
// Lives counter
// ------------------------------------------------------------
class HDLivesCounter:Thinker{
	int lastfraglimit;
	bool lastteamplay;
	bool lastlivesmode;
	int endgametriggered;
	int deaths[MAXPLAYERS];

	//for the typeon effect
	int endgametypecounter;
	int endgametypecounterstartsmalltext;
	int endgametypecounterend;
	int endgametypecounternext;
	string endbigstring;
	string endsmallstring;

	override void postbeginplay(){
		super.postbeginplay();
		lastfraglimit=0;
		lastteamplay=false;
		endgametriggered=0;

		endgametypecounter=-36; //1-second lag before it starts = start at -35
		endgametypecounterstartsmalltext=0;
		endgametypecounterend=0;
		endgametypecounternext=0;
		endbigstring="";
		endsmallstring="";
	}
	override void tick(){
		super.tick();

		//reset if lives mode is changed midgame
		bool thislivesmode=livesmode();
		if(lastlivesmode!=thislivesmode){
			lastlivesmode=thislivesmode;
			for(int i=0;i<MAXPLAYERS;i++){
				if(playeringame[i])players[i].fragcount=0;
				deaths[i]=0;
			}
		}

		//update the counters every time the limit is adjusted
		if(
			lastfraglimit!=fraglimit
			||lastteamplay!=teamplay
		){
			lastfraglimit=fraglimit;
			lastteamplay=teamplay;
			updatefragcounts(self);
		}

		//tick the typeon effect
		if(endgametypecounter>-36){
			endgametypecounter++;
			if(
				endgametypecounter>endgametypecounternext
				&&checkendgame(true)
			){
				if(!deathmatch)level.nextmap=level.mapname;
				Exit_Normal(0);
			}
		}
	}
	//obtain the thinker
	static hdlivescounter get(){
		hdlivescounter hdlc=null;
		thinkeriterator hdlcit=thinkeriterator.create("hdlivescounter");
		while(hdlc=hdlivescounter(hdlcit.next())){
			if(hdlc)break;
		}
		if(!hdlc)hdlc=new("hdlivescounter");
		return hdlc;
	}
	//because it's not just "!fraglimit"!
	//fraglimit is nonzero and either coop or FL>=100
	static bool livesmode(){
		return(
			fraglimit
			&&(
				!deathmatch
				||fraglimit>=100
			)
		);
	}
	//update all the fragcounts
	static void updatefragcounts(hdlivescounter hdlc){
		if(!hdlivescounter.livesmode())return;
		for(int i=0;i<MAXPLAYERS;i++){
			if(playeringame[i])players[i].fragcount=(fraglimit%100)-hdlivescounter.owndeaths(i);
		}
	}
	//get total death count
	static int alldeaths(hdlivescounter hdlc){
		int dths=0;
		for(int i=0;i<MAXPLAYERs;i++){
			dths+=hdlc.deaths[i];
		}
		return dths;
	}
	//get total death count for this player
	static int owndeaths(int playernum){
		let hdlc=hdlivescounter.get();
		if(!playeringame[playernum])return 0;

		//coop, count everyone's deaths
		if(!deathmatch)return hdlivescounter.alldeaths(hdlc);

		//ffa, just count own deaths
		if(!teamplay)return hdlc.deaths[playernum];

		//teamplay, add up deaths for all players on this team
		//if you switch teams, you bring your shame with you
		int dths=0;
		int pteam=players[playernum].getteam();
		for(int i=0;i<MAXPLAYERS;i++){
			if(playeringame[i]&&pteam==players[i].getteam())dths+=hdlc.deaths[i];
		}
		return dths;
	}
	//check if player has been wiped
	static bool wiped(int playernum,bool checkspawned=false){
		return(
			(
				hd_pof
				&&(
					!hdplayerpawn(players[playernum].mo)
					||players[playernum].mo.health<1
				)
			)||(
				hdlivescounter.livesmode()
				&&hdlivescounter.owndeaths(playernum)>fraglimit%100
				&&(
					!checkspawned
					||(
						!hdplayerpawn(players[playernum].mo)
						||players[playernum].mo.health<1
					)
				)
			)
		);
	}
	//check remaining number of teams
	static int,int teamsleft(){
		array<int> countedteams;countedteams.clear();
		for(int i=0;i<MAXPLAYERS;i++){
			if(!playeringame[i]||hdlivescounter.wiped(i,true))continue;
			int thisteam=players[i].getteam();
			bool alreadylisted=false;
			for(int j=0;j<countedteams.size();j++){
				if(countedteams[j]==thisteam){
					alreadylisted=true;
					break;
				}
			}
			if(!alreadylisted)countedteams.push(thisteam);
		}
		int whichfirst=countedteams.size()?countedteams[0]:-1;
		return countedteams.size(),whichfirst;
	}
	//check endgame
	static int checkendgame(bool checkonly=false){
		if(!hdlivescounter.livesmode())return false;
		let hdlc=hdlivescounter.get();
		int endgametype=0;
		int survivorindex=-1;
		string endtext="";

		//sudden death cyber-cyberdemons
		bool wipedout=true;
		for(int i=0;i<MAXPLAYERS;i++){
			if(playeringame[i]&&!hdlivescounter.wiped(i,true)){
				wipedout=false;
				break;
			}
		}
		if(wipedout){
			endgametype=hdlivescounter.HDEND_WIPE;

			if(!deathmatch)endtext="Team eliminated.";
			else if(teamplay)endtext="All teams eliminated.";
			else endtext="All players eliminated.";
		}

		//all other checks are conditional on non-wipeout
		if(endgametype!=hdlivescounter.HDEND_WIPE){
			if(!deathmatch){
				//coop: count deaths
				if(fraglimit<=hdlivescounter.alldeaths(hdlc)){
					endtext="Casualty budget exceeded.";
					endgametype=hdlivescounter.HDEND_COOPFAIL;
				}
			}
			else if(!teamplay){
				//ffa: check if at least 2 survivors
				int survivors=0;
				int survivingplayer=-1;
				for(int i=0;i<MAXPLAYERS;i++){
					if(playeringame[i]&&!hdlivescounter.wiped(i,true)){
						survivors++;
						if(survivingplayer<0)survivingplayer=i;
					}
				}
				bool ending=(survivors<2);
				if(ending){

					if(!survivors){
						endtext="All players eliminated.";
						endgametype=hdlivescounter.HDEND_WIPE;
					}else{
						endtext=players[survivingplayer].getusername().." alone remains.";
						survivorindex=survivingplayer;
						endgametype=hdlivescounter.HDEND_LMSWIN;
					}
				}
			}
			else{
				//teams: check if at least 2 surviving teams
				int teamsleft,lastteam;
				[teamsleft,lastteam]=hdlivescounter.teamsleft();
				bool ending=(teamsleft<2);
				if(ending){
					if(teamsleft<1){
						endtext="All teams eliminated.";
						endgametype=hdlivescounter.HDEND_WIPE;
					}else{
						endtext=teams[lastteam].mname.." Team alone remains.";
						survivorindex=lastteam;
						endgametype=hdlivescounter.HDEND_TEAMWIN;
					}
				}
			}
		}

		if(!checkonly||hd_debug)console.printf(endtext);
		if(endgametype&&endgametype!=hdlc.endgametriggered){
			hdlc.startendgameticker(endgametype,survivorindex);
		}else if(!endgametype){
			hdlc.endgametypecounter=-36;
		}

		if(!endgametype&&hdlc.endgametriggered)console.printf("Then again...");
		hdlc.endgametriggered=endgametype;
		return endgametype;
	}
	//start the endgame sequence
	void startendgameticker(int endtype,int winner=-1){
		endgametriggered=endtype;
		endgametypecounter=-35;
		static const string smtx[]={
			"Good game!",
			"Well played, everyone!",
			"Everyone else, better luck next time!",
			"Shit your pants before their awesome!",
			"Congratulations on being sufficiently hideous!",
			"And now to survive the sudden death cyber-cyberdemons..."
		};
		switch(endtype){
		case HDEND_LMSWIN:
			endbigstring=players[winner].getusername().." has won the match!";
			endsmallstring=smtx[random(0,smtx.size()-1)];
			break;
		case HDEND_TEAMWIN:
			endbigstring=teams[winner].mname.." Team has won the match!";
			endsmallstring=smtx[random(0,smtx.size()-1)];
			break;
		case HDEND_COOPFAIL:
			endbigstring="W E   A R E   L E A V I N G !";
			endsmallstring="Too many casualties, HQ has ordered a retreat!";
			break;
		case HDEND_WIPE:
			endbigstring="W I P E D   O U T !";
			endsmallstring="T r y   a g a i n.";
			break;
		default:
			endgametypecounter=-36;
			return;
			break;
		}
		endgametypecounterstartsmalltext=endbigstring.length()+35;
		endgametypecounterend=endgametypecounterstartsmalltext+endsmallstring.length()+70;
		endgametypecounternext=endgametypecounterend+35;

		//additional changes
		for(int i=0;i<MAXPLAYERS;i++){
			if(
				playeringame[i]
				&&players[i].mo
				&&hdweapon(players[i].mo.player.readyweapon)
			){
				hdweapon(players[i].mo.player.readyweapon).wepmsg="";
			}
		}
	}
	static void playerdied(int playernum){
		if(!playeringame[playernum])return;
		let hdlc=hdlivescounter.get();

		hdlc.deaths[playernum]++;
		hdlivescounter.updatefragcounts(hdlc);

		playerinfo player=players[playernum];
		if(hdlivescounter.wiped(playernum,true)){
			console.printf("\ci-- "..player.getusername().." is OUT!");
			if(deathmatch&&teamplay){
				bool teamwiped=true;
				int ownteam=players[playernum].getteam();
				for(int i=0;i<MAXPLAYERS;i++){
					if(
						playeringame[i]
						&&players[i].getteam()==ownteam
						&&hdplayerpawn(players[i].mo)
						&&players[i].mo.health>0
					){
						teamwiped=false;
						break;
					}
				}
				if(teamwiped)console.printf("\cg*** "..teams[player.getteam()].mname.." Team has been ELIMINATED!");
			}
		}

		hdlivescounter.checkendgame();
	}
	static ui void RenderEndgameText(actor camera){
		hdlivescounter hdlc=null;
		thinkeriterator hdlcit=thinkeriterator.create("hdlivescounter");
		while(hdlc=hdlivescounter(hdlcit.next())){
			if(hdlc)break;
		}
		if(!hdlc)return;
		int counter=hdlc.endgametypecounter;
		if(counter>0){
			double calpha=1.;
			if(counter>hdlc.endgametypecounterend){
				double totaltics=max(1.,hdlc.endgametypecounternext-hdlc.endgametypecounterend);
				calpha-=double(counter-hdlc.endgametypecounterend)/totaltics;
			}
			string bigmsg=hdlc.endbigstring;
			screen.DrawText(BigFont,OptionMenuSettings.mFontColorHighlight,
				(screen.GetWidth() - BigFont.StringWidth(bigmsg) * CleanXfac_1) / 2,
				SmallFont.GetHeight()*CleanYFac_1*11,
				bigmsg.left(counter),DTA_CleanNoMove_1,true,
				DTA_Alpha,calpha
			);
			counter-=hdlc.endgametypecounterstartsmalltext;
			if(counter>0){
				string smallmsg=hdlc.endsmallstring;
				screen.DrawText(smallfont,OptionMenuSettings.mFontColorValue,
					(screen.GetWidth() - smallfont.StringWidth(smallmsg) * CleanXfac_1) / 2,
					SmallFont.GetHeight()*CleanYFac_1*12+BigFont.GetHeight()*CleanYFac_1,
					smallmsg.left(counter),DTA_CleanNoMove_1,true,
					DTA_Alpha,calpha
				);
			}
		}else if(
			counter<35
			&&hdspectator(camera)
		){
			let spec=hdspectator(camera);
			double calpha=spec.textalpha;
			string msg=spec.spectitle;
			screen.DrawText(BigFont,OptionMenuSettings.mTitleColor,
				(screen.GetWidth() - BigFont.StringWidth(msg) * CleanXfac_1) / 2,
				SmallFont.GetHeight()*CleanYFac_1*2,
				msg,DTA_CleanNoMove_1,true,
				DTA_Alpha,calpha
			);
			msg="Hit fire/altfire to jump to the remaining players.";
			screen.DrawText(smallfont,OptionMenuSettings.mFontColorValue,
				(screen.GetWidth() - smallfont.StringWidth(msg) * CleanXfac_1) / 2,
				(SmallFont.GetHeight()+3)*CleanYFac_1*2+BigFont.GetHeight()*CleanYFac_1,
				msg.left(counter),DTA_CleanNoMove_1,true,
				DTA_Alpha,calpha
			);
		}
	}
	enum EndgameType{
		HDEND_WIPE=1,
		HDEND_COOPFAIL=2,
		HDEND_LMSWIN=3,
		HDEND_TEAMWIN=4,
	}
}

