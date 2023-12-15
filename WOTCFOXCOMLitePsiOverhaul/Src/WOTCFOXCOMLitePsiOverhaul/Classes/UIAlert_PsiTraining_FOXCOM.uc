class UIAlert_PsiTraining_FOXCOM extends UIAlert;

// This class is bloody ugly cargo culted mess, no idea how much of this is actually required,
// but it works, so w/e.

enum UIAlert_PsiTraining_FOXCOM
{
	eAlert_PsiTraining_FOXCOMTrainingComplete,
};

simulated function BuildAlert()
{
	BindLibraryItem();

	switch ( eAlertName )
	{
	case 'eAlert_PsiTraining_FOXCOMTrainingComplete':
		BuildPsiTraining_FOXCOMTrainingCompleteAlert(m_strPsiTrainingCompleteLabel);
		break;	
	default:
		AddBG(MakeRect(0, 0, 1000, 500), eUIState_Normal).SetAlpha(0.75f);
		break;
	}

	// Set  up the navigation *after* the alert is built, so that the button visibility can be used. 
	RefreshNavigation();
}

simulated function Name GetLibraryID()
{
	//This gets the Flash library name to load in a panel. No name means no library asset yet. 
	switch ( eAlertName )
	{
	case 'eAlert_PsiTraining_FOXCOMTrainingComplete':
		return 'Alert_TrainingComplete';
	default:
		return '';
	}
}

simulated function BuildPsiTraining_FOXCOMTrainingCompleteAlert(string TitleLabel)
{
	local XComGameState_Unit UnitState;
	local X2SoldierClassTemplate ClassTemplate;
	local XGParamTag kTag;
	local string AbilityIcon, AbilityName, AbilityDescription, ClassIcon, ClassName, RankName;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager TemplateManager;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplate = TemplateManager.FindAbilityTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'AbilityTemplate'));
	
	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	ClassName = Caps(ClassTemplate.DisplayName);
	ClassIcon = ClassTemplate.IconImage;
	RankName = Caps(class'X2ExperienceConfig'.static.GetRankName(UnitState.GetRank(), ClassTemplate.DataName));

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = "";

	// Ability Name
	AbilityName = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for ability '" $ AbilityTemplate.DataName $ "'");

	// Ability Description
	AbilityDescription = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, UnitState) : ("Missing 'LocLongDescription' for ability " $ AbilityTemplate.DataName $ "'");
	AbilityIcon = AbilityTemplate.IconImage;

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(TitleLabel);
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(ClassIcon);
	LibraryPanel.MC.QueueString(RankName);
	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
	LibraryPanel.MC.QueueString(ClassName);
	LibraryPanel.MC.QueueString(AbilityIcon);
	LibraryPanel.MC.QueueString(m_strNewAbilityLabel);
	LibraryPanel.MC.QueueString(AbilityName);
	LibraryPanel.MC.QueueString(AbilityDescription);
	LibraryPanel.MC.QueueString(m_strViewSoldier);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();

	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
}