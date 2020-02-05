// ------------------------------------------------------------
// The cause of - and solution to -
// ------------------------------------------------------------

//Do downtime management between maps
extend class HDPlayerPawn{
	void ConsolidateAmmo(){
		//call all the Consolidates on actors
		//really everything below could be migrated to their own actors eventually
		for(inventory ppp=inv;ppp!=null;ppp=ppp.inv){
			let hdp=hdpickup(ppp);
			if(hdp)hdp.consolidate();
			let hdw=hdweapon(ppp);
			if(hdw)hdw.consolidate();
		}
	}
}

//Specially handled ammo dropping
extend class HDHandlers{
	//goes through all ammo, checks their lists, dumps if not found
	void PurgeUselessAmmo(hdplayerpawn ppp){
		if(!ppp)return;
		array<inventory> items;items.clear();
		for(inventory item=ppp.inv;item!=null;item=!item?null:item.inv){
			let thisitem=hdpickup(item);
			if(thisitem&&!thisitem.isused())items.push(item);
		}
		double aang=ppp.angle;
		double ch=items.size()?20.:0;
		for(int i=0;i<items.size();i++){
			ppp.a_dropinventory(items[i].getclassname(),items[i].amount);
			ppp.angle+=ch;
		}
		ppp.angle=aang;
	}
	//drops one or more units of your selected weapon's ammo
	void DropOne(hdplayerpawn ppp,playerinfo player,int amt){
		if(!ppp||ppp.health<1)return;
		let cw=hdweapon(player.readyweapon);
		if(cw)cw.DropOneAmmo(amt);
		else PurgeUselessAmmo(ppp);
	}
	//strips armour
	void ChangeArmour(hdplayerpawn ppp){
		let inva=ppp.findinventory("HDArmour");
		if(ppp.CheckStrip(ppp,-1)&&inva)ppp.UseInventory(inva);
	}
}

