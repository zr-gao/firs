

/*** Libraries ***/

/* Import SuperLib for GameScript */
// import("util.superlib", "SuperLib", 38);
// Result <- SuperLib.Result;
// Log <- SuperLib.Log;
// Helper <- SuperLib.Helper;
// ScoreList <- SuperLib.ScoreList;
// Tile <- SuperLib.Tile;
// Direction <- SuperLib.Direction;
// Town <- SuperLib.Town;
// Industry <- SuperLib.Industry;
// Story <- SuperLib.Story;

/* Import SCP */
// import("Library.SCPLib", "SCPLib", 45);

/*** GS includes ***/
require("version.nut"); // get SELF_VERSION
require("utils.nut");

require("companydata.nut");
// require("scp.nut");


// Use this pointer to access the SCPManager instance that wraps up the SCP library
// with high level communication methods.
// g_scp_manager <- null;


// Industry tags
require("industry.nut");
indus_m <- industriesMgr;
cargo_prices <- [0,144,0,108,105,149,116,122,125,138,183]

function round(num) {
    return (num >= 0) ? floor(num + 0.5) : ceil(num - 0.5);
}

class MainClass extends GSController
{
	_loaded_data = null;
	_loaded_from_version = null;

	_company_tbl = null;

	constructor()
	{
		this._loaded_data = null;
		this._loaded_from_version = null;

		this._company_tbl = {};
	}

	// Return the company data class instance for a company or null if the company doesn't exist
	// in our in-memory list of companies.
	function GetCompanyData(company_id);
}

function MainClass::Start()
{
	// temp
	local str = "["
	local CL = GSCargoList()
	local i = 0
	while(i<CL.Count())
	{
		if (GSCargo.GetName(i)!=null) {
			str += round(GSCargo.GetCargoIncome(i,2000,0)/10.0) + ",";
			trace(3,GSCargo.GetName(i) + " " + round(GSCargo.GetCargoIncome(i,2000,0)/10.0))
		} else {
			str += "0,";
		}
		i++;
	}
	trace(3,str)
	trace(3,GSCompany.COMPANY_SELF)
	trace(3,GSCompany.COMPANY_FIRST)
	//

	this.Init();
	indus_m.Init();

	trace(2,"Setup done");

	// Wait for the game to start
	this.Sleep(1);

	local last_income_check = GSDate.GetCurrentDate();
	local last_loop_year = GSDate.GetYear(GSDate.GetCurrentDate());
	local last_loop_date = GSDate.GetCurrentDate();
	while (true) {
		local loop_start_tick = GSController.GetTick();

		// Handle events
		this.HandleEvents();

		local current_date = GSDate.GetCurrentDate();
		if (last_loop_date != null) {
			local year = GSDate.GetYear(current_date);
			local month = GSDate.GetMonth(current_date);
			if (month != GSDate.GetMonth(last_loop_date)) {
				this.EndOfMonth(month);
			}
			if (year != GSDate.GetYear(last_loop_date)) {
				this.EndOfYear(year);
			}
		}
		last_loop_date = current_date;

		// Check for incoming SCP messages
		// trace(2,"SCP.Check");
		// for(local s=0; s<20 && g_scp_manager.Check(); s++) {};

		// Loop with a frequency of five days
		local ticks_used = GSController.GetTick() - loop_start_tick;
		GSController.Sleep(max(1,5 * 74 - ticks_used));
	}
}

function MainClass::Init()
{
	// Setup SCPManager
	// g_scp_manager = SCPManager(this);


	if (this._loaded_data != null)
	{
		// Copy loaded data from this._loaded_data to this.*
		// or do whatever with the loaded data

		// Load company data from loaded data
		foreach (company_table in this._loaded_data.company_list)
		{
			if (company_table != null)
			{
				trace(2,"Loading data for company " + GSCompany.GetName(company_table.company_id));
				local loaded_company = CompanyData.CreateFromTable(company_table, this._loaded_from_version)
				this._company_tbl.rawset(loaded_company.GetId(), loaded_company);
			}
		}

		if (this._loaded_data.rawin("signs")) {
			indus_m.signs <- this._loaded_data["signs"];
		}

		if (this._loaded_data.rawin("prices")) {
			indus_m.prices <- this._loaded_data["prices"];
		}

		this._loaded_data = null; // don't attempt to load again
	}
	else
	{
		// New game
	}

	// Add possible new companies
	this.UpdateCompanyList();
}

function MainClass::HandleEvents()
{
	if (GSEventController.IsEventWaiting())
	{
		local ev = GSEventController.GetNextEvent();

		if (ev == null)
			return;

		local ev_type = ev.GetEventType();
		if (ev_type == GSEvent.ET_COMPANY_NEW ||
				ev_type == GSEvent.ET_COMPANY_BANKRUPT ||
				ev_type == GSEvent.ET_COMPANY_MERGER)
		{
			trace(2,"A company was created/bankrupt/merged => update company list");

			// Update the goal list when:
			// - a new company has been created
			// - a company has gone bankrupt
			// - a company has been bought by another company
			this.UpdateCompanyList();
		} else if (ev_type == GSEvent.ET_INDUSTRY_OPEN) {
			local gs_event_industry_open = GSEventIndustryOpen.Convert(ev);
			local industry_id = gs_event_industry_open.GetIndustryID();
			indus_m.newIndustry(industry_id);
		} else if (ev_type == GSEvent.ET_INDUSTRY_CLOSE) {
			local gs_event_industry_close = GSEventIndustryClose.Convert(ev);
			local industry_id = gs_event_industry_close.GetIndustryID();
			indus_m.delIndustry(industry_id);
		}
	}
}

function MainClass::UpdateCompanyList()
{
	// Loop over all possible company IDs
	for (local c = GSCompany.COMPANY_FIRST; c <= GSCompany.COMPANY_LAST; c++)
	{
		// Is the company not existing in the game?
		if (GSCompany.ResolveCompanyID(c) == GSCompany.COMPANY_INVALID)
		{
			if (this._company_tbl.rawin(c))
			{
				// Remove data for no longer existing company
				this._company_tbl.rawdelete(c);
			}
			continue;
		}

		// If the company can be resolved and exist (CompanyData has been setup) => don't do anything
		if (this._company_tbl.rawin(c)) continue;

		// Company data has not yet been setup for this company
		local company_data = CompanyData(c)
		// company_data.InformAboutRules();
		// company_data.IncomeUpdate(); // start tracking delivery

		this._company_tbl.rawset(c, company_data);
	}
}

function MainClass::UpdateCompanyBalance()
{
	for (local c = GSCompany.COMPANY_FIRST; c <= GSCompany.COMPANY_LAST; c++)
	{
		if (this._company_tbl.rawin(c)) {
			trace(2,"Update company bank balance for " + GSCompany.GetName(c));
			this._company_tbl.rawget(c).IncomeUpdate();

			// Extra call to handle events to ensure company gone bankrupt is removed and
			// then possible added again if new company was created quickly. This reduce
			// the risk that you get money that are not yours.
			this.HandleEvents();

			if (this._company_tbl.rawin(c)) this._company_tbl.rawget(c).DoBankTransfer();
		}
	}
}

function MainClass::EndOfMonth(month)
{
	local income = indus_m.Update(month);
	trace(3,"Total income "+ income)
	GSCompany.ChangeBankBalance(GSCompany.COMPANY_FIRST, income, GSCompany.EXPENSES_OTHER);

	// trace(3,"Update income START " + month);
	// this.UpdateCompanyBalance();
	// trace(3,"Update income END " + month);

	local i_list = GSIndustryList();
}
// Called at end of year (but not when the game end has been reached)
// @param year The year that just ended
function MainClass::EndOfYear(year)
{
	trace(2,"End Of Year");

	foreach (_, company_data in this._company_tbl)
	{
		company_data.EndOfYear(year);
	}
}

function MainClass::Save()
{
	trace(2,"Saving data to savegame");

	// If Init() has not finished loading data from save,
	// then save the data that was loaded from save.
	if (this._loaded_data != null) return this._loaded_data;

	local company_save_list = [];
	foreach (_, company_data in this._company_tbl)
	{
		company_save_list.append(company_data.SaveToTable());
	}

	return {
		company_list = company_save_list,
		signs = indus_m.signs,
		prices = indus_m.prices
	};
}

function MainClass::Load(version, tbl)
{
	trace(2,"Loading data from savegame made with version " + version + " of the game script");

	if (version > SELF_VERSION)
	{
		trace(1,"Warning: Loading from a newer version of TransportGoals", true);
	}

	// Store a copy of the table from the save game
	// but do not process the loaded data yet. Wait with that to Init
	// so that OpenTTD doesn't kick us for taking too long to load.
	this._loaded_data = {}
   	foreach (key, val in tbl)
	{
		this._loaded_data.rawset(key, val);
	}
	this._loaded_from_version = version;
}

// public function
function MainClass::GetCompanyData(company_id)
{
	return this._company_tbl.rawin(company_id) ? this._company_tbl.rawget(company_id) : null;
}

