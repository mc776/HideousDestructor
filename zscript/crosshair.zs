// ------------------------------------------------------------
// Sight picture crosshairs
// ------------------------------------------------------------
extend class HDStatusBar{
	virtual void DrawGrenadeLadder(int airburst,vector2 bob){
		drawimage(
			"XH27",(0,1.8)+bob,DI_SCREEN_CENTER|DI_ITEM_HCENTER|DI_ITEM_TOP,
			scale:(1.6,1.6)
		);
		if(airburst)drawnum(airburst,
			12+bob.x,42+bob.y,DI_SCREEN_CENTER,Font.CR_BLACK
		);
	}
	virtual void DrawHDXHair(hdplayerpawn hpl){
		int nscp=hd_noscope.getint();
		if(
			!(cplayer.cmd.buttons&(BT_USE|BT_ZOOM))
			&&(
				nscp>1
				||hd_hudusedelay.getint()<-1
			)
		)return;

		let wp=hdweapon(cplayer.readyweapon);
		bool sightbob=hd_sightbob.getbool();
		vector2 bob=hpl.hudbob;
		double fov=cplayer.fov;

		//have no crosshair at all
		if(
			!wp
			||hpl.barehanded
			||hpl.nocrosshair>0
			||(!sightbob&&hpl.countinv("IsMoving"))
			||abs(bob.x)>50
			||fov<13
		)return;


		//multiple weapons use this
		string whichdot="redpxl";
		int whichdotthough=hd_crosshair.getint();
		switch(whichdotthough){
			case 1:case 2:case 3:case 4:case 5:
			whichdot=string.format("riflsit%i",whichdotthough);
			default:break;
		}


		//all weapon sights go here
		double scl=fov/(90.*clamp(hd_xhscale.getfloat(),0.1,3.0)); //broken as of 4.0.0
		SetSize(0,400*scl,250*scl);
		BeginHUD(forcescaled:true);

		actor hpc=hpl.scopecamera;
		int cpbt=cplayer.cmd.buttons;

		bool scopeview=!!hpc&&(
			!nscp
			||cpbt&BT_ZOOM
			||hudlevel==2
		);
//if(hpl.findinventory("PortableLiteAmp")&&PortableLiteAmp(hpl.findinventory("PortableLiteAmp")).worn)scopeview=false;

		wp.DrawSightPicture(self,wp,hpl,sightbob,bob,fov,scopeview,hpc,whichdot);
	}
}
