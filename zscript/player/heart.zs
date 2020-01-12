// ------------------------------------------------------------
// The heart
// ------------------------------------------------------------
const HDCONST_MAXBLOODLOSS=4096;
extend class HDPlayerPawn{
	const HDCONST_MINHEARTTICS=5; //35/5*60=420 beats per minute!
	int beatcount;
	int beatmax;
	int beatcap;
	int beatcounter;

	int bloodpressure;

	int stimcount;
	int regenblues;
	int secondflesh;
	int zerk;
	int haszerked;

	actor lastthingthatwoundedyou;

	int woundcount;
	int burncount;
	int unstablewoundcount;
	int oldwoundcount;
	int aggravateddamage;

	int bloodloss;

	int maxhealth(){
		if(regenblues<0)regenblues=0;
		if(woundcount<0)woundcount=0;
		if(oldwoundcount<0)oldwoundcount=0;
		if(unstablewoundcount<0)unstablewoundcount=0;
		if(burncount<0)burncount=0;
		if(aggravateddamage<0)aggravateddamage=0;
		if(stunned<0)stunned=0;
		if(bloodloss<0)bloodloss=0;
		return max(0,100
			+min(0,
				-aggravateddamage
				-burncount
				-oldwoundcount
				-woundcount
				-unstablewoundcount
				-(bloodloss>>6)
				-(secondflesh>>2)
				+(stimcount>>1)
			)
			+max(fatigue-HDCONST_SPRINTFATIGUE,0)
		);
	}

	void HeartTicker(double fm,double sm,int input){
		//these will be used repeatedly
		int healthcap=maxhealth();
		int ismv=countinv("IsMoving");
		bool iszerk=(zerk>0);


		//zerk!!!!
		if(
			zerk
			&&bloodloss<HDCONST_MAXBLOODLOSS
		){
			if(iszerk){
				zerk=max(zerk-1,0);
				if(zerk>8000){
					damagemobj(self,self,random(1,10),"bashing");
					aggravateddamage+=random(0,5);
				}else if(zerk>5000){
					zerk--;
					stunned=10;
					angle+=random(-2,2);pitch+=random(-2,2);
					vel+=(frandom(-0.5,0.5),frandom(-0.5,0.5),frandom(-0.5,0.5));
					if(!random(0,3)){
						givebody(1);
						A_SetBlend("20 0a 0f",0.4,3);

						if(!random(0,8-zerk*0.0005)){
							woundcount+=random(0,2);
							if(!random(0,4))A_Pain();
							else if(!random(0,3))aggravateddamage++;
						}

						if(!(player.readyweapon is "HDFist")){
							Disarm(self);
							A_SelectWeapon("HDFist");
						}
					}
				}else if(zerk>4000){
					zerk--;
					angle+=random(-1,1);pitch+=random(-1,1);
					vel+=(frandom(-0.5,0.5),frandom(-0.5,0.5),frandom(-0.5,0.5));
					if(!random(0,3)){
						givebody(1);
						if(!(player.readyweapon is "HDFist")){
							Disarm(self);
							A_SelectWeapon("HDFist");
						}
					}
				}else{
					givebody(1);
					if(stunned)stunned*=0.8;
					if(!zerk){
						A_SetBlend("20 0a 0f",0.8,35);
						A_TakeInventory("PowerStrength");
						A_Pain();
						zerk-=700*max(1,haszerked);
						haszerked=0;
						if(!random(0,4))aggravateddamage+=random(1,3);
					}
				}
			}else{
				stunned+=3;
				zerk++;
				beatcap=HDCONST_MINHEARTTICS+random(1,10);
				A_TakeInventory("PowerStrength");
			}
		}


		//on every beat
		if(beatcount>0){
			beatcount--;
			A_SetPitch(pitch-0.0005*bloodpressure,SPF_INTERPOLATE);
		}else{
			if(hd_debug&&bloodloss)console.printf("bled: "..bloodloss);

			A_SetPitch(pitch+0.0005*beatmax*bloodpressure,SPF_INTERPOLATE);
			beatmax=min(beatmax,beatcap);

			//heartbeat sound
			if(bloodpressure>5||health<30||beatmax<20){
				double bp=0.05*bloodpressure;
				if(beatmax<15||health<30)bp*=2;
				A_StartSound("misc/heart",7778,CHANF_LOCAL,0.05*max(bloodpressure,22-beatmax));
			}

			if(woundcount){
				int dm=(random(10,woundcount)-random(0,bloodpressure))*4/10;
				if(dm>0){
					damagemobj(
						self,lastthingthatwoundedyou,dm,"bleedout",
						DMG_THRUSTLESS
						|(bloodloss>HDCONST_MAXBLOODLOSS?DMG_FORCED:0)
					);
				}
			}

			//fatigue eventually overrides zerk
			if(fatigue>HDCONST_DAMAGEFATIGUE*1.4){
				if(zerk)damagemobj(self,self,beatmax+6,"internal");
				else damagemobj(self,self,2,"internal");
				stunned=min(10,stunned);
			}

			//enforce health cap
			if(healthcap<health)damagemobj(self,null,1,"maxhpdrain");

			//limit beatmax subject to zerk
			if(iszerk)beatmax=clamp(beatmax,4,14);
			else beatmax=clamp(beatmax,HDCONST_MINHEARTTICS,35);

			if(fatigue>random(0,(bloodloss>>6)+secondflesh))fatigue--;
			if(
				beatmax<HDCONST_MINHEARTTICS+3
				||fatigue>HDCONST_DAMAGEFATIGUE  
			){
				damagemobj(self,null,1,"internal");
				stunned=min(10,stunned);
			}else{
				if(health<healthcap){
					if(random(1,30)+ismv<beatmax)givebody(1);
					if(random(1,40)<stimcount)givebody(1);
				}
			}

			//reset beatcount
			beatcount=beatmax;
			if(bloodpressure>3)A_SetBlend("20 12 0f",0.003*min(bloodpressure,100),beatcount);
			beatcounter++;

			//sprinting
			if(
				cansprint
				&&runwalksprint>0
				&&(fm||sm)
			){
				fatigue+=2+max(0,(bloodloss>>6))+(
					countinv("WornRadsuit")?randompick(0,1,1):
					(armourlevel==3?randompick(0,1):
					armourlevel==1?randompick(0,0,0,1):0)
				);
				if(!stimcount && !zerk && fatigue>=HDCONST_SPRINTFATIGUE){
					fatigue+=20;
					stunned+=400;
					A_Pain();
				}
				if(!random(0,35))bloodpressure++;
			}

			//blood pressure
			if(
				stimcount>0
				&&bloodpressure<12-(bloodloss>>4)
			)bloodpressure++;
			else if(bloodpressure>0)bloodpressure--;

			//don't go negatives
			if(regenblues<0)regenblues=0;
			if(stunned<0)stunned=0;
			if(aggravateddamage<0)aggravateddamage=0;

			if(woundcount<0)woundcount=0;
			if(oldwoundcount<0)oldwoundcount=0;
			if(unstablewoundcount<0)unstablewoundcount=0;
			if(burncount<0)burncount=0;

			//apply stims
			if(stimcount){
				beatcap=clamp(beatcap,beatcap-1,35-stimcount);
				if(bloodpressure<stimcount)bloodpressure+=4;
				if(zerk && stimcount>18)stunned=10;
				else stunned--;
			}

			//magical healing passively helps heart rate
			if(regenblues){
				if(beatcap<HDCONST_MINHEARTTICS){
					beatcap=max(beatcap,HDCONST_MINHEARTTICS+5);
					if(!random(0,99))regenblues--;
				}
				if(stimcount>4){
					stimcount-=4;
					regenblues--;
				}
				if(bloodloss>0)bloodloss-=12;


				//heal shorter-term damage
				if(
					unstablewoundcount>0
					||woundcount>0
				){
					if(woundcount>0)woundcount--;else unstablewoundcount--;
					regenblues--;
				}


			}

			//every 4 beats
			int minbeatmax=HDCONST_MINHEARTTICS+random(random(-2,5),5);
			if(beatcounter%4==0){ //==0, !() both 3 characters
				//recovering heart rate
				if(fatigue){
					if(beatmax>minbeatmax){
						beatmax=max(minbeatmax,min(beatmax,35-fatigue));
					}
					if(fatigue>20)stunned=clamp(stunned,stunned+10,fatigue*10);
					if(bloodpressure<fatigue)bloodpressure=fatigue;
				}
				if(beatmax<beatcap) beatmax++;
				if(bloodpressure>0)bloodpressure--;
			}

			//every 12 beats
			if(beatcounter%12==0){
				if(stimcount>0)stimcount--;

				//twitchy zerk
				if(
					iszerk
					&&!ismv
				){
					if(floorz>=pos.z)A_ChangeVelocity(frandom(-2,3),frandom(-2,2),1,CVF_RELATIVE);
					if(!(input&BT_ATTACK))muzzledrift+=(random(-14,14),random(-24,14));
					else muzzledrift+=(frandom(-2,2),frandom(-3,2));
					if(!random(0,2)){
						int stupid=random(1,100);
						if(stupid<30)A_StartSound("*grunt",CHAN_VOICE);
						else if(stupid<50)A_StartSound("*pain",CHAN_VOICE);
						else if(stupid<70)A_StartSound("*death",CHAN_VOICE);
						else if(stupid<90)A_StartSound("*xdeath",CHAN_VOICE);
						else if(stupid<100){
							A_StartSound("*taunt",CHAN_VOICE);
							A_AlertMonsters();
						}
					}
				}


				//second flesh heals wonds
				if(secondflesh>0){
					secondflesh--;
					if(oldwoundcount>0&&random(0,2))oldwoundcount--;
					if(!random(0,47))aggravateddamage++;
					damagemobj(self,self,1,"staples");
				}

				//all other magical healing
				if(regenblues>0){

					//heal long-term damage
					if(oldwoundcount>0||burncount>0||aggravateddamage>0){
						oldwoundcount--;burncount--;aggravateddamage--;
						regenblues--;
					}


					if(
						beatcounter%60==0
						&&!random(0,7)
					){
						A_Log("You feel power coming out of you.",true);
						regenblues-=20;
						plantbit.spawnplants(self,33,144);
						switch(random(0,3)){
						case 0:
							blockthingsiterator rezz=
								blockthingsiterator.create(self,512);
							while(rezz.next()){
								actor rezzz=rezz.thing;
								if(
									canresurrect(rezzz,false)
								){
									RaiseActor(rezzz,RF_NOCHECKPOSITION);
									rezzz.bfriendly=true;
									rezzz.master=self;
									plantbit.spawnplants(rezzz,12,33);
									regenblues--;
									if(!random(0,2))break;
								}
							}
							break;
						case 1:
							blockthingsiterator fffren=
								blockthingsiterator.create(self,512);
							while(fffren.next()){
								actor ffffren=fffren.thing;
								if(
									ffffren.bismonster
									&&!ffffren.bfriendly
									&&ffffren.health>0
									&&ffffren.spawnhealth()<400
								){
									ffffren.bfriendly=true;
									ffffren.A_Pain();
									plantbit.spawnplants(ffffren,1,0);
									regenblues-=2;
									if(!random(0,3))break;
								}
							}
							break;
						default:
							aggravateddamage-=20;
							woundcount-=20;

							A_RadiusGive("health",512,
								RGF_GIVESELF|RGF_MONSTERS|RGF_MONSTERS|
								RGF_CUBE|RGF_NOSIGHT,
								1000
							);
							if(!random(0,3))spawn("BFGNecroShard",pos,ALLOW_REPLACE);
							break;
						}
					}
				}
			}

			if(beatcounter%20==0){	//every 20 beats
				beatcap=clamp(beatcap+8,1,35);

				//blood starts growing back
				if(bloodloss>0)bloodloss--;

				//updating beatcap (minimum heart rate)
				if(health<40) beatcap=clamp(beatcap,1,24);
				else if(health<60) beatcap=clamp(beatcap,1,32);

				//bandages come undone
				if(unstablewoundcount && countinv("IsMoving")>random(0,12)){
					unstablewoundcount--;
					if(flip)oldwoundcount++;else woundcount++;
				}
				//wounds start settling
				if(!random(0,unstablewoundcount+woundcount)){
					if(unstablewoundcount>0){
						unstablewoundcount--;
						oldwoundcount++;
					}
				}



			}
			if(beatcounter==120){	//every 120 beats
				beatcounter=0;	//reset
				if(random(1,health)>70){
					oldwoundcount--;
					burncount--;
				}
			}
		}

		//spawn shards
		if(
			hd_shardrate>0
			&&level.time>0
			&&!(level.time%hd_shardrate)
		)spawn("BFGNecroShard",pos);
	}
}



