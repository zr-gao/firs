class industriesMgr
{
	signs = {};      // signs
	prices = {};
	make_sign = false ;   // display industry sign

	/**
	 * An industry is deleted
	 */
	function delIndustry(indus)
	{
		if(!industriesMgr.make_sign) return;
		local sign_id = industriesMgr.signs[indus]; // todo use "in"/ rowin() to check if indus index is present
		if (sign_id!=null) GSSign.RemoveSign(sign_id);
		trace(3,"Industry Deletion: "+indus);
		industriesMgr.signs.rawdelete(indus);
		//industriesMgr.signs.remove(indus); //todo, check why it does not work...
	}

	/**
	 * An industry is created
	 */
	function newSign(indus)
	{
		if(industriesMgr.make_sign) {
			if (!industriesMgr.signs.rawin(indus)) {
				local type = GSIndustry.GetIndustryType(indus)
				local name = "("+GSIndustryType.GetName(type)+")"; // build a name
				local tile_index = GSIndustry.GetLocation(indus); // industry location
				local sign_id = GSSign.BuildSign(tile_index, name); // create the sign
				trace(3,"New Industry "+ indus + " type " + type + " sign "+name);
				if (sign_id!=null) {industriesMgr.signs[indus] <- sign_id;}
			}
		}
	}
	function newIndustry(indus)
	{
		// industriesMgr.newSign(indus)
		if (!industriesMgr.prices.rawin(indus)) {
			local cargo_list = 	GSCargoList_IndustryAccepting(indus);
			industriesMgr.prices.rawset(indus,{})
			foreach(cargo_id, _ in cargo_list) {
				industriesMgr.prices[indus].rawset(cargo_id,cargo_prices[cargo_id])
				// trace(3,"Industry "+ indus + " accepts cargo " + cargo_id)
			}
			foreach(cargo_id,price in industriesMgr.prices[indus]) {
				trace(3,"Industry "+ indus + " accepts cargo " + cargo_id + " price "+ price)
			}
		}
	}

	/**
	 * check if we need to create industry sign, and effectively create if settings request it.
	 *
	 * Called at game creation and savegame load.
	 */
	function Init()
	{

		if(industriesMgr.prices.len()>0) {
			trace(3,"Save game already have prices")
			if(industriesMgr.signs.len()>0) {
				trace(3,"Save game already have signs")
				industriesMgr.make_sign <- true;
			} else {
				industriesMgr.make_sign <- false;
			}
			industriesMgr.UpdateSign()
		} else {
			trace(3,"New game")
			industriesMgr.make_sign <- GSController.GetSetting("industry_signs");
			industriesMgr.CollectAllIndustry()
			industriesMgr.SetAllSigns()
			industriesMgr.Update(0)
		}

	}

	/**
	 * Fetch all industries, and threat them as beeing new ones
	 */
	function CollectAllIndustry()
	{
		local inds = GSIndustryList();
		foreach(ind_id, _ in inds)
		{
			industriesMgr.newIndustry(ind_id);
		}
	}

	/**
	 * Check if "industry_sign" settings got changed,
	 * Note : not usefull while setting cannot be updated durring gameplay.
	 */
	function SetAllSigns()
	{
		local inds = GSIndustryList();
		foreach(ind_id, _ in inds)
		{
			industriesMgr.newSign(ind_id);
		}
	}
	function UpdateSign()
	{
		local make_sign = GSController.GetSetting("industry_signs");
		if(make_sign==industriesMgr.make_sign) return; // no changes
		industriesMgr.make_sign <- make_sign;
		if(industriesMgr.make_sign)
		{
			industriesMgr.SetAllSigns();
		}
		else
		{
			industriesMgr.RemoveAllSigns();
		}
	}
	function UpdateText()
	{
		local inds = GSIndustryList();
		foreach(ind_id, ind in inds)
		{
			local indacc = GSCargoList_IndustryAccepting(ind_id);
			local ninput = indacc.Count();
			local lines = {};
			local i = 0;
			foreach(cargo_id,cargo in indacc) {
				lines[i++] <- GSText(GSText.STR_CARGO_PRICE,industriesMgr.prices[ind_id][cargo_id],GSCargo.GetName(cargo_id))
			}
			switch (ninput)
			{
				case 1:
					GSIndustry.SetText(ind_id,GSText(GSText.STR_IND_I1,lines[0]))
					break;
				case 2:
					GSIndustry.SetText(ind_id,GSText(GSText.STR_IND_I2,lines[0],lines[1]));
					break;
				case 3:
					GSIndustry.SetText(ind_id,GSText(GSText.STR_IND_I3,lines[0],lines[1],lines[2]));
					break;
			}
		}

	}
	function UpdateIncome()
	{
		local inds = GSIndustryList();
		local income_total = 0;
		foreach(ind_id, ind in inds)
		{
			local indacc = GSCargoList_IndustryAccepting(ind_id);
			foreach(cargo_id,cargo in indacc) {
				local cargo_amount = GSCargoMonitor.GetIndustryDeliveryAmount(GSCompany.COMPANY_FIRST, cargo_id, ind_id, true);
				local income = industriesMgr.prices[ind_id][cargo_id] * cargo_amount;
				trace(3,"Delivered " + cargo_amount + " " + GSCargo.GetName(cargo_id) + " to " + GSIndustry.GetName(ind_id) + " income "+ income);
				if (income >= 0) {
					income_total += income;
				}
			}
		}
		return income_total;
	}
	function Update(month)
	{
		industriesMgr.UpdateText();
		industriesMgr.UpdateSign();
		return industriesMgr.UpdateIncome();

	}

	/**
	 * Delete all industry signs.
	 * target signs from registrered ones.
	 */
	function RemoveAllSigns()
	{
		trace(3,"Remove all registered industry signs");
		foreach(sign_id in industriesMgr.signs)
		{
			if (sign_id!=null && GSSign.IsValidSign(sign_id))
				GSSign.RemoveSign(sign_id);
		}
		industriesMgr.signs.clear();
		industriesMgr.make_sign<-false;
	}

};

