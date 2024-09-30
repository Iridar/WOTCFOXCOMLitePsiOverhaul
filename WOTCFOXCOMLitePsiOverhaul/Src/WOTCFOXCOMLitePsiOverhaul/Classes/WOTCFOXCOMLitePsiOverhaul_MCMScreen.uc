class WOTCFOXCOMLitePsiOverhaul_MCMScreen extends Object config(WOTCFOXCOMLitePsiOverhaul);

var config int VERSION_CFG;

var localized string ModName;
var localized string PageTitle;
var localized array<string> GroupHeaders;

var localized string LabelEnd;
var localized string LabelEndTooltip;

`include(WOTCFOXCOMLitePsiOverhaul\Src\ModConfigMenuAPI\MCM_API_Includes.uci)

`MCM_API_AutoSliderVars(GIFT_CHANCE);
`MCM_API_AutoCheckBoxVars(DISABLE_CONFIRM_EVALUATION_POPUP);
`MCM_API_AutoCheckBoxVars(GIFT_PSIOP_GUARANTEED);
`MCM_API_AutoCheckBoxVars(RANDOMIZE_FREE_ABILITY);
`MCM_API_AutoCheckBoxVars(DEBUG_LOGGING);
`MCM_API_AutoCheckBoxVars(CHANGE_APPEARANCE);
`MCM_API_AutoSliderVars(HAIR_COLOR);
`MCM_API_AutoSliderVars(EYE_COLOR);
`MCM_API_AutoCheckBoxVars(ALLOW_ROOKIES);
`MCM_API_AutoCheckBoxVars(CHEAPER_PSI_LAB);
`MCM_API_AutoCheckBoxVars(REMOVE_RESEARCH_COST);
`MCM_API_AutoCheckBoxVars(PS_LAB_STAFF_SCIENTIST);
`MCM_API_AutoCheckBoxVars(DISABLE_STAFF_SLOT_FILLED_POPUP);


`include(WOTCFOXCOMLitePsiOverhaul\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

`MCM_API_AutoSliderFns(GIFT_CHANCE,, 1);
`MCM_API_AutoCheckBoxFns(DISABLE_CONFIRM_EVALUATION_POPUP, 2);
`MCM_API_AutoCheckBoxFns(GIFT_PSIOP_GUARANTEED, 1);
`MCM_API_AutoCheckBoxFns(RANDOMIZE_FREE_ABILITY, 1);
`MCM_API_AutoCheckBoxFns(DEBUG_LOGGING, 1)
`MCM_API_AutoCheckBoxFns(ALLOW_ROOKIES, 1);
`MCM_API_AutoCheckBoxFns(CHANGE_APPEARANCE, 1);
`MCM_API_AutoSliderFns(HAIR_COLOR,, 1);
`MCM_API_AutoSliderFns(EYE_COLOR,, 1);
`MCM_API_AutoCheckBoxFns(CHEAPER_PSI_LAB, 1);
`MCM_API_AutoCheckBoxFns(REMOVE_RESEARCH_COST, 1);
`MCM_API_AutoCheckBoxFns(PS_LAB_STAFF_SCIENTIST, 2);
`MCM_API_AutoCheckBoxFns(DISABLE_STAFF_SLOT_FILLED_POPUP, 2);

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

	`MCM_API_AutoAddCheckBox(Group, CHEAPER_PSI_LAB);
	`MCM_API_AutoAddCheckBox(Group, REMOVE_RESEARCH_COST);
	`MCM_API_AutoAddCheckBox(Group, PS_LAB_STAFF_SCIENTIST);
	`MCM_API_AutoAddCheckBox(Group, DISABLE_STAFF_SLOT_FILLED_POPUP);
	
	Group = Page.AddGroup('Group', GroupHeaders[1]); // "Psionic Abilities"
	`MCM_API_AutoAddCheckBox(Group, RANDOMIZE_FREE_ABILITY);
	
	Group = Page.AddGroup('Group', GroupHeaders[2]); // "Psionic Training"

	`MCM_API_AutoAddCheckBox(Group, DISABLE_CONFIRM_EVALUATION_POPUP);
	`MCM_API_AutoAddCheckBox(Group, ALLOW_ROOKIES);
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
	ALLOW_ROOKIES = `GETMCMVAR(ALLOW_ROOKIES);
	HAIR_COLOR = `GETMCMVAR(HAIR_COLOR);
	EYE_COLOR = `GETMCMVAR(EYE_COLOR);
	DISABLE_CONFIRM_EVALUATION_POPUP = `GETMCMVAR(DISABLE_CONFIRM_EVALUATION_POPUP);
	PS_LAB_STAFF_SCIENTIST = `GETMCMVAR(PS_LAB_STAFF_SCIENTIST);
	CHEAPER_PSI_LAB = `GETMCMVAR(CHEAPER_PSI_LAB);
	REMOVE_RESEARCH_COST = `GETMCMVAR(REMOVE_RESEARCH_COST);
	DISABLE_STAFF_SLOT_FILLED_POPUP = `GETMCMVAR(DISABLE_STAFF_SLOT_FILLED_POPUP);
}

simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	`MCM_API_AutoReset(HAIR_COLOR);
	`MCM_API_AutoReset(EYE_COLOR);
	`MCM_API_AutoReset(ALLOW_ROOKIES);
	`MCM_API_AutoReset(GIFT_CHANCE);
	`MCM_API_AutoReset(DEBUG_LOGGING);
	`MCM_API_AutoReset(RANDOMIZE_FREE_ABILITY);
	`MCM_API_AutoReset(CHANGE_APPEARANCE);
	`MCM_API_AutoReset(GIFT_PSIOP_GUARANTEED);
	`MCM_API_AutoReset(CHEAPER_PSI_LAB);
	`MCM_API_AutoReset(REMOVE_RESEARCH_COST);
	`MCM_API_AutoReset(DISABLE_CONFIRM_EVALUATION_POPUP);
	`MCM_API_AutoReset(PS_LAB_STAFF_SCIENTIST);
	`MCM_API_AutoReset(DISABLE_STAFF_SLOT_FILLED_POPUP);
}


simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	VERSION_CFG = `MCM_CH_GetCompositeVersion();
	SaveConfig();
}


