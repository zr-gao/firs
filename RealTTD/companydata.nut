
//------------------------------------------------------------//
//                                                            //
//   Class for storage of company specific data               //
//                                                            //
//------------------------------------------------------------//

class CompanyData
{
	_company_id = null; // company id

	/*
	 * Amount of money to give to company in next DoBankTransfer().
	 * Updated by IncomeUpdate()
	 * Key = cargo id or "vehicle_income" for reversing vehicle income
	 */
	_next_bank_transfer = null;

	// year * 4 + quarter
	_last_handled_quarter = null;

	constructor(company_id)
	{
		this._company_id = company_id;
		this._next_bank_transfer = {};
		foreach (cargo_id, _ in GSCargoList()) {
			this._next_bank_transfer.rawset(cargo_id, 0);
		}
		this._next_bank_transfer.rawset("vehicle_income", 0);

		this._last_handled_quarter = 0;
	}

	// Get company id
	function GetId();

	// Send information about goal to AI or Human players
	// function InformAboutRules();

	// Check income and cargo transported since last call.
	// Does not make any bank balance adjustments. Instead call
	// DoBankTransfer() to actually commit the change.
	function IncomeUpdate();

	// Commit the bank transfer decided by IncomeUpdate.
	function DoBankTransfer();

	// Called at end of year
	function EndOfYear(year);

	// For save/load
	function SaveToTable();
	static function CreateFromTable(table, version, goal_ptr);
}

function CompanyData::GetId()
{
	return this._company_id;
}

// function CompanyData::InformAboutRules()
// {
// 	//g_scp_manager.SendCurrentGoal(this._company_id, this._company_id);

// 	// AIs can't read news, but humans can be on the same company as AIs,
// 	// so always send news even if the company has registered with the
// 	// SCP protocol.
// 	this.AddInfoStoryPages();
// }

// function CompanyData::AddInfoStoryPages(auto_show = true)
// {
// 	local text = GSText(GSText.STR_INTRO_PAGE);
// 	if (auto_show) {
// 		Story.ShowMessage(this._company_id, text, GSText(GSText.STR_INTRO_TITLE));
// 	} else {
// 		// When auto_show is false, don't show any message, just silently create the story page
// 		Story.NewStoryPage(this._company_id, GSText(GSText.STR_INTRO_TITLE), [
// 				[GSStoryPage.SPET_TEXT, 0, text]
// 		]);
// 	}
// }

function GetPayment(cargo_id, delivery_amount) {
	return GSController.GetSetting("payment_per_unit") * delivery_amount;
}

function CompanyData::IncomeUpdate()
{

	foreach (cargo_id, _ in GSCargoList())
	{
		local transported = 0;
		local t = 0;
		local i_list = GSIndustryList();

		foreach (i, _ in i_list)
		{
			t = GSCargoMonitor.GetIndustryDeliveryAmount(this._company_id, cargo_id, i, true);
			if (t > 0) {
				trace(2,"transported: " + t + " (" + GSCargo.GetCargoLabel(cargo_id) + ") to (" + GSIndustry.GetName(i) + ")");
				transported += t;
			}
		}
		local town_list = GSTownList();

	// foreach (cargo_id, _ in GSCargoList())
	// {
		local transported = 0;
		local t = 0;

		foreach (town_id, _ in town_list)
		{
			t = GSCargoMonitor.GetTownDeliveryAmount(this._company_id, cargo_id, town_id, true);
			if (t > 0) {
				trace(2,"transported: " + t + " (" + GSCargo.GetCargoLabel(cargo_id) + ") to (" + GSTown.GetName(town_id) + ")");
				transported += t;
			}
		}

		// trace(2,"transported: " + transported + " (" + GSCargo.GetCargoLabel(cargo_id) + ")");

		local old_amount = this._next_bank_transfer.rawget(cargo_id);
		this._next_bank_transfer.rawset(cargo_id, old_amount + this.GetPayment(cargo_id, transported));
	}

	// Doing the following logic within the same quarter is important
	GSController.Sleep(1);

	// Collect vehicle income from past completed quarters that has not yet
	// have been collected by this code before.
	local tot_veh_income = 0;
	local now = GSDate.GetCurrentDate();
	local curr_quarter = GSDate.GetYear(now) * 4 + GSDate.GetMonth(now) / 3;
	local last_completed_quarter = curr_quarter - 1;
	if (this._last_handled_quarter < last_completed_quarter) {
		local n_quarters_back = last_completed_quarter - this._last_handled_quarter;

		// In OpenTTD CURRENT_QUARTER is defined as 0 and EARLIEST_QUARTER as some max value back in time.
		// This code below only works when CURRENT_QUARTER < EARLIEST_QUARTER.
		assert(GSCompany.CURRENT_QUARTER < GSCompany.EARLIEST_QUARTER);

		for (local i = GSCompany.CURRENT_QUARTER + 1; i < GSCompany.CURRENT_QUARTER + 1 + n_quarters_back; i++)
		{
			tot_veh_income += GSCompany.GetQuarterlyIncome(this._company_id, i);
			if (i >= GSCompany.EARLIEST_QUARTER) break;
		}
		trace(2,"Veh income: " + tot_veh_income);
	}
	this._last_handled_quarter = last_completed_quarter;

	local old_amount = this._next_bank_transfer.rawget("vehicle_income");
	this._next_bank_transfer.rawset("vehicle_income", old_amount - tot_veh_income);

}

function CompanyData::DoBankTransfer()
{
	// Collect cargo delivery payment
	local tot_deliver_payment = 0;
	foreach (cargo_id, _ in GSCargoList())
	{
		local amount = this._next_bank_transfer.rawget(cargo_id);
		tot_deliver_payment += amount;
		this._next_bank_transfer.rawset(cargo_id, 0);
	}
	// Reversing vehicle income
	local vehicle_reverse_income = this._next_bank_transfer.rawget("vehicle_income");
	this._next_bank_transfer.rawset("vehicle_income", 0);

	// Do bank balance change
	GSCompany.ChangeBankBalance(this._company_id, tot_deliver_payment + vehicle_reverse_income, GSCompany.EXPENSES_OTHER);

	// Show news
	if (GSController.GetSetting("income_news") == 1) {
		local news_text = GSText(GSText.STR_BANK_TRANSFER_NEWS,
				tot_deliver_payment + vehicle_reverse_income,
				tot_deliver_payment,
				vehicle_reverse_income);
		GSNews.Create(GSNews.NT_GENERAL, news_text, this._company_id);
	}
}

function CompanyData::EndOfYear(year)
{
}

function CompanyData::SaveToTable()
{
	return {
		company_id = this._company_id,
		next_bank_transfer = this._next_bank_transfer,
		last_handled_quarter = this._last_handled_quarter,
	};
}

/* static */ function CompanyData::CreateFromTable(table, version)
{
	local result = CompanyData(table.company_id);
	result._next_bank_transfer = table.next_bank_transfer;
	result._last_handled_quarter = table.last_handled_quarter;

	return result;
}
