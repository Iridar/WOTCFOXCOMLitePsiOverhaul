class WOTCFOXCOMLitePsiOverhaul_MCMScreen extends Object config(WOTCFOXCOMLitePsiOverhaul);

var config int VERSION_CFG;

var localized string ModName;
var localized string PageTitle;
var localized array<string> GroupHeaders;

var localized string LabelEnd;
var localized string LabelEndTooltip;

`include(WOTCFOXCOMLitePsiOverhaul\Src\ModConfigMenuAPI\MCM_API_Includes.uci)

`MCM_API_AutoSliderVars(GIFT_CHANCE);
`MCM_API_AutoCheckBoxVars(GIFT_PSIOP_GUARANTEED);
`MCM_API_AutoCheckBoxVars(RANDOMIZE_FREE_ABILITY);
`MCM_API_AutoCheckBoxVars(DEBUG_LOGGING);
`MCM_API_AutoCheckBoxVars(CHANGE_APPEARANCE);
`MCM_API_AutoSliderVars(HAIR_COLOR);
`MCM_API_AutoSliderVars(EYE_COLOR);

`include(WOTCFOXCOMLitePsiOverhaul\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

`MCM_API_AutoSliderFns(GIFT_CHANCE,, 1);
`MCM_API_AutoCheckBoxFns(GIFT_PSIOP_GUARANTEED, 1);
`MCM_API_AutoCheckBoxFns(RANDOMIZE_FREE_ABILITY, 1);
`MCM_API_AutoCheckBoxFns(DEBUG_LOGGING, 1);
`MCM_API_AutoCheckBoxFns(CHANGE_APPEARANCE, 1);
`MCM_API_AutoSliderFns(HAIR_COLOR,, 1);
`MCM_API_AutoSliderFns(EYE_COLOR,, 1);

event OnInit(UIScreen Screen)
{
	`MCM_API_Register(Screen, ClientModCallback);
}

//Simple one group framework code
simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
	local MCM_API_SettingsPage		Page;
	local MCM_API_SettingsGroup		Group;
	local XComLinearColorPalette	Palette;

	LoadSavedSettings();
	Page = ConfigAPI.NewSettingsPage(ModName);
	Page.SetPageTitle(PageTitle);
	Page.SetSaveHandler(SaveButtonClicked);
	Page.EnableResetButton(ResetButtonClicked);

	Group = Page.AddGroup('Group', GroupHeaders[0]); // "Strategic Changes"

	

	Group = Page.AddGroup('Group', GroupHeaders[1]); // "Psionic Abilities"
	`MCM_API_AutoAddCheckBox(Group, RANDOMIZE_FREE_ABILITY);
	
	Group = Page.AddGroup('Group', GroupHeaders[2]); // "Psionic Training"
	`MCM_API_AutoAddCheckBox(Group, CHANGE_APPEARANCE);

	Palette = `CONTENT.GetColorPalette(ePalette_HairColor);
	`MCM_API_AutoAddSLider(Group, HAIR_COLOR, 0, Palette.Entries.Length - 1, 1);

	Palette = `CONTENT.GetColorPalette(ePalette_EyeColor);
	`MCM_API_AutoAddSLider(Group, EYE_COLOR, 0, Palette.Entries.Length - 1, 1);

	Group = Page.AddGroup('Group', GroupHeaders[3]); // "The Gift"

	`MCM_API_AutoAddSLider(Group, GIFT_CHANCE, 0, 100, 1);
	`MCM_API_AutoAddCheckBox(Group, GIFT_PSIOP_GUARANTEED);

	Group = Page.AddGroup('Group', GroupHeaders[4]); // Misc

	`MCM_API_AutoAddCheckBox(Group, DEBUG_LOGGING);
	Group.AddLabel('Label_End', LabelEnd, LabelEndTooltip);

	Page.ShowSettings();
}

simulated function LoadSavedSettings()
{
	GIFT_CHANCE = `GETMCMVAR(GIFT_CHANCE);
	DEBUG_LOGGING = `GETMCMVAR(DEBUG_LOGGING);
	GIFT_PSIOP_GUARANTEED = `GETMCMVAR(GIFT_PSIOP_GUARANTEED);
	RANDOMIZE_FREE_ABILITY = `GETMCMVAR(RANDOMIZE_FREE_ABILITY);
	CHANGE_APPEARANCE = `GETMCMVAR(CHANGE_APPEARANCE);

	HAIR_COLOR = `GETMCMVAR(HAIR_COLOR);
	EYE_COLOR = `GETMCMVAR(EYE_COLOR);
}

simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	`MCM_API_AutoReset(HAIR_COLOR);
	`MCM_API_AutoReset(EYE_COLOR);

	`MCM_API_AutoReset(GIFT_CHANCE);
	`MCM_API_AutoReset(DEBUG_LOGGING);
	`MCM_API_AutoReset(RANDOMIZE_FREE_ABILITY);
	`MCM_API_AutoReset(CHANGE_APPEARANCE);
	`MCM_API_AutoReset(GIFT_PSIOP_GUARANTEED);
}


simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	VERSION_CFG = `MCM_CH_GetCompositeVersion();
	SaveConfig();
}


