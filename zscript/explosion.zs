// ------------------------------------------------------------
// Radius damage effect combos!
// ------------------------------------------------------------

//need to do a new explosion to immolate things properly
//...can we do a combo exploder (blast, frags and immolate)?
extend class HDActor{
	void A_HDBlast(
		double blastradius=0,int blastdamage=0,double fullblastradius=0,name blastdamagetype="None",
		double pushradius=0,double pushamount=0,double fullpushradius=0,bool pushmass=true,
		double fragradius=0,class<HDBulletActor> fragtype="HDB_frag",double fragvariance=0.05,double fragspeedfactor=1.,
		double immolateradius=0,int immolateamount=1,int immolatechance=100,
		double gibradius=0,int gibamount=1,
		bool hurtspecies=true,
		actor source=null,
		bool passwalls=false
	){
		hdactor.HDBlast(self,
			blastradius,blastdamage,fullblastradius,blastdamagetype,
			pushradius,pushamount,fullpushradius,pushmass,
			fragradius,fragtype,fragvariance,fragspeedfactor,
			immolateradius,immolateamount,immolatechance,
			gibradius,gibamount,
			hurtspecies,
			source,
			passwalls
		);
	}
	enum UpperMidLower{
		FTIER_TOP=1,
		FTIER_MID=2,
		FTIER_MIDL=4, //left and right relative to the grenade, facing the victim
		FTIER_MIDR=8,
		FTIER_BOTTOM=16
	}
	static void HDBlast(actor caller,
		double blastradius=0,int blastdamage=0,double fullblastradius=0,name blastdamagetype="None",
		double pushradius=0,double pushamount=0,double fullpushradius=0,bool pushmass=true,
		double fragradius=0,class<HDBulletActor> fragtype="HDB_frag",double fragvariance=0.05,double fragspeedfactor=1.,
		double immolateradius=0,int immolateamount=1,int immolatechance=100,
		double gibradius=0,int gibamount=1,
		bool hurtspecies=true,
		actor source=null,
		bool passwalls=false
	){
		//get the biggest radius
		int bigradius=max(
			blastradius,
			fragradius,
			immolateradius,
			gibradius
		);

		//initialize things to be used in the iterator
		if(!source){
			if(caller.target)source=caller.target;
			else if(caller.master)source=caller.master;
			else source=caller;
		}
		actor target=caller.target;

		//do all this from the centre
		double callerhalfheight=caller.height*0.5;
		caller.addz(callerhalfheight);

		blockthingsiterator itt=blockthingsiterator.create(caller,bigradius);
		while(itt.Next()){
			actor it=itt.thing;
			double losmul=0;

			if(	//abort all checks if no hurt species
				!it
				||it==caller
				||(
					!hurtspecies
					&&it.species==source.species
					&&!it.ishostile(source)
				)
			)continue;

			double ithalfheight=it.height*0.5;
			it.addz(ithalfheight); //get the middle not the bottom
			double dist=caller.distance3d(it);
			double dist2=caller.distance2d(it);
			it.addz(-ithalfheight); //reset "it"'s position

			bool ontop=
				(!dist || dist<min(it.radius,ithalfheight))?true
				:false;
			double divdist=ontop?1:clamp(1./dist,0.,1.);

			int playerattack=0;//source&&source.player?DMG_PLAYERATTACK:0;

			//some variables that will be reused
			double biggerradius=bigradius+it.radius;
			double smallerradius=it.radius-1;
			double difz=it.pos.z-caller.pos.z;
			double pitchtotop=-atan2(difz+it.height,dist2);
			double pitchtomid=-atan2(difz+ithalfheight,dist2);
			double pitchtobottom=-atan2(difz,dist2);
			double angletomid=caller.angleto(it);
			double edgeshot=atan2(smallerradius,dist);


			//check how much of the actor is exposed
			int tiershit=0;
			if(passwalls){
				losmul=1.;
				tiershit=FTIER_TOP|FTIER_MIDL|FTIER_MIDR|FTIER_BOTTOM;
			}else{
				//shoot lines to the top, middle, bottom and sides
				//if some of these fail, target is partially covered
				//assumes legs that have smaller profile than upper body
				flinetracedata blt;

				caller.linetrace(angletomid,biggerradius,pitchtotop,0,
					0, //caller is already raised by half its height for other things
					data:blt
				);
				if(blt.hitactor==it){
					tiershit|=FTIER_TOP;
					losmul+=0.25;
				}

				blt.hitactor=null; //reset before each call just in case
				caller.linetrace(angletomid,biggerradius,pitchtomid,0,
					0, //caller is already raised by half its height for other things
					data:blt
				);
				if(blt.hitactor==it){
					tiershit|=FTIER_MID;
					losmul+=0.25;
				}

				blt.hitactor=null;
				caller.linetrace(angletomid+edgeshot,biggerradius,pitchtomid,0,
					0, //caller is already raised by half its height for other things
					data:blt
				);
				if(blt.hitactor==it){
					tiershit|=FTIER_MIDL;
					losmul+=0.17;
				}

				blt.hitactor=null;
				caller.linetrace(angletomid-edgeshot,biggerradius,pitchtomid,0,
					0, //caller is already raised by half its height for other things
					data:blt
				);
				if(blt.hitactor==it){
					tiershit|=FTIER_MIDR;
					losmul+=0.17;
				}

				blt.hitactor=null;
				caller.linetrace(angletomid,biggerradius,pitchtobottom,0,
					0, //caller is already raised by half its height for other things
					data:blt
				);
				if(blt.hitactor==it){
					tiershit|=FTIER_BOTTOM;
					losmul+=0.16;
				}

				//the final multiplier should not exceed 1
				if(losmul>1.)losmul=1.;
			}
//				if(losmul){caller.A_Log(string.format("%s  %f",it.getclassname(),losmul));}

			if(!tiershit)continue;
			double divmass=1.;if(it.mass>0)divmass=1./it.mass;

			//immolate before all damage, to avoid bypassing player death transfer
			if(!it)continue;if(dist<=immolateradius){
				if(immolateamount<0){
					HDF.Give(it,"Heat",-immolateamount+random(-immolatechance,immolatechance));
				}else if(!it.countinv("ImmunityToFire")&&immolatechance>=random(1,100)*losmul){
					if(hdactor(caller))hdactor(caller).A_Immolate(it,target,immolateamount);
					else HDF.Give(it,"Heat",immolateamount*2);
				}
			}
			//gibbing
			if(!it)continue;if(dist<=gibradius && it.bcorpse && it.bshootable){
				hdf.give(it,"sawgib",gibamount-dist/3);
				actor bld;bool gbg;
				double minbloodheight=min(4.,it.height*0.2);
				for(int i=0;i<gibamount;i+=3){
					[gbg,bld]=it.A_SpawnItemEx(it.bloodtype,
						it.radius*frandom(0.6,1),
						frandom(-it.radius,it.radius)*0.5,
						frandom(minbloodheight,it.height),
						frandom(-1,4),
						frandom(-4,4),
						frandom(1,7),
						it.angleto(caller),
						SXF_ABSOLUTEANGLE|SXF_NOCHECKPOSITION|SXF_USEBLOODCOLOR
					);
					bld.vel+=it.vel;
				}
				if(!it.bdontthrust)it.vel+=(it.pos-caller.pos)*divdist*divmass*10;
			}
			//push
			if(!it)continue;if(dist<=pushradius && it.bshootable && !it.bdontthrust){
				if(it.radiusdamagefactor)pushamount*=it.radiusdamagefactor;
				vector3 push=(it.pos-caller.pos)*divdist
					*clamp(pushamount-clamp(dist-fullpushradius,0,dist),0,pushamount);
				if(pushmass){
					if(pushamount<=it.mass)push=(0,0,0);
					else{
						push*=divmass;
						if(push.z>0)push-=(0,0,caller.mass*it.gravity);
					}
				}
				it.vel+=push;
			}
			//blast damage
			if(!it)continue;if(dist<=blastradius && (it.bshootable||it.bvulnerable)){
				if(it.radiusdamagefactor)blastdamage*=it.radiusdamagefactor;
				int dmg=(dist>fullblastradius)?
					blastdamage-clamp(dist-fullblastradius,0,dist)
					:blastdamage;
				it.DamageMobj(caller,source,dmg*losmul,blastdamagetype,DMG_THRUSTLESS|playerattack);
			}
			//frag damage
			if(!it)continue;if(
				dist<=fragradius
				&&(it.bsolid || it.bshootable || it.bvulnerable)
			){
				caller.A_Face(it);
				if(
					(
						it.bvulnerable||(
							it.bshootable
							&&it.radius
							&&it.height
						)
					)
				){
					int fragshit=1400; //
					if(dist>0){
						//determine size of arc exposed to frags
						//https://en.wikipedia.org/wiki/Spherical_sector
						double angcover=(abs(pitchtotop-pitchtobottom)+edgeshot*2)*0.5;
//console.printf(string.format("%s  %f",it.getclassname(),angcover));
						double domearea=HDCONST_TAU*angcover; //*dist
						double blastarea=(HDCONST_TAU*2)*dist; //*dist
						double proportionfragged=domearea/blastarea;

						//NOW incorporate the cover
						proportionfragged*=losmul;

						fragshit*=proportionfragged;
					}

//console.printf(string.format("%s  %i",it.getclassname(),fragshit));

					//randomize count and abort if none end up hitting
					fragshit*=frandom(0.9,1.1);
					if(fragshit<1)continue;
					if(hd_debug){
						string nm;if(it.player)nm=it.player.getusername();else nm=it.getclassname();
						console.printf(nm.." fragged "..fragshit.." times");
					}

					//resolve the impacts using a single bullet
					let bbb=hdbulletactor(spawn(fragtype,caller.pos));
					if(!bbb)continue;
					bbb.target=target;
					bbb.vel+=caller.vel;
					bbb.traceactors.push(caller); //does this even work?

					//set the base properties of the frag bullet
					//TODO: replace with frag type parameter in this function
					double fragpushfactor=bbb.pushfactor;
					double fragmass=bbb.mass;
					double fragspeed=bbb.speed*fragspeedfactor;
					double fragaccuracy=bbb.accuracy;
					double fragstamina=bbb.stamina;

					//limit number of frags and increase size to compensate
					if(fragshit>20){
						fragstamina+=((fragshit-20)<<4);
						fragshit=20;
					}

					double fragangle=caller.angleto(it);
					vector3 vu=(cos(bbb.pitch)*(cos(fragangle),sin(fragangle)),sin(bbb.pitch));
					fragradius-=it.stamina; //to be used to place the bullet, not inside target

					//resolve the impacts using the same bullet, resetting each time
					for(int i=0;i<fragshit;i++){
						bbb.mass=fragmass*(1.+frandom(-fragvariance,fragvariance));
						bbb.pushfactor=fragpushfactor*(1.+frandom(-fragvariance,fragvariance));
						bbb.stamina=fragstamina*(1.+frandom(-fragvariance,fragvariance));
						bbb.accuracy=fragaccuracy*(1.+frandom(-fragvariance,fragvariance));
						bbb.speed=fragspeed*(1.+frandom(-fragvariance,fragvariance));

						if(i>10)bbb.bbloodlessimpact=true;

						double fragtop=it.height;
						double fragbottom=0;
						if(!(tiershit&FTIER_BOTTOM))fragbottom=fragtop*0.3;
						if(!(tiershit&FTIER_TOP))fragtop*=0.7;

						bbb.setxyz((
							rotatevector((0,fragradius),fragangle),
							it.pos.z+frandom(fragbottom,fragtop)
						));
						bbb.onhitactor(it,bbb.pos,vu);
					}
					bbb.setorigin(caller.pos,false);
					bbb.bulletdie();

					//don't forget to spawn the moving frags!
				}
			}
		}
		//reset position
		if(caller)caller.addz(-callerhalfheight);
	}
}
