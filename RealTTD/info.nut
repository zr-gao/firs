

require("version.nut");


class FMainClass extends GSInfo {

	function GetAuthor()		{ return "GZR"; }
	function GetName()			{ return "RealTTD"; }
	function GetDescription() 	{ return "Real life TTD"; }
	function GetVersion()		{ return SELF_VERSION; }
	function GetDate()			{ return "2025-09-16"; }
	function CreateInstance()	{ return "MainClass"; }
	// WARNING: the short name is also declared in version.nut
	function GetShortName()		{ return "RTTD"; }
	function GetAPIVersion()	{ return "1.4"; }
	function GetURL()			{ return ""; }
	function MinVersionToLoad() { return 1; }

	// function GetAuthor()		{ return "GZR"; }
	// function GetName()			{ return "RealTTD"; }
	// function GetDescription() 	{ return "Real life TTD"; }
	// function GetVersion()		{ return SELF_VERSION; }
	// function GetDate()			{ return "2025-09-16"; }
	// function CreateInstance()	{ return "MainClass"; }
	// WARNING: the short name is also declared in version.nut
	// function GetShortName()		{ return "RTTD"; }
	// function GetAPIVersion()	{ return "1.0"; }
	// function GetURL()			{ return ""; }
	// function MinVersionToLoad() { return 1; }

	function GetSettings() {
		AddSetting({name = "payment_per_unit",
				description = "Payment per cargo unit delivered",
				easy_value = 70,
				medium_value = 40,
				hard_value = 25,
				custom_value = 40,
				flags = CONFIG_INGAME,
				min_value = 0,
				max_value = 1000000000,
		});

		AddSetting({name = "income_news",
				description = "Show a news message when your bank balance has been updated",
				easy_value = 0,
				medium_value = 0,
				hard_value = 0,
				custom_value = 0,
				flags = CONFIG_BOOLEAN | CONFIG_INGAME,
		});


		AddSetting({
			name = "log_level",
			description = "Debug: Log level (higher = print more)",
			easy_value = 1,
			medium_value = 1,
			hard_value = 1,
			custom_value = 1,
			flags = CONFIG_INGAME,
			min_value = 1,
			max_value = 3,
		});

		AddSetting({
			name = "industry_signs",
			description = "Display industry signs",
			easy_value = 1, medium_value = 1, hard_value = 1, custom_value = 1,
			flags = CONFIG_INGAME | CONFIG_BOOLEAN
		});

		AddLabels("log_level", {_1 = "1: Info", _2 = "2: Verbose", _3 = "3: Debug" } );
	}
}

RegisterGS(FMainClass());
