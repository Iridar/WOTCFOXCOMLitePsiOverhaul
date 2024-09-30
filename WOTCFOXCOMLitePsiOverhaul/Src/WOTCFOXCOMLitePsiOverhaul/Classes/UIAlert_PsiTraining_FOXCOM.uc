class UIAlert_PsiTraining_FOXCOM extends UIAlert;

// This class is bloody ugly cargo culted mess, no idea how much of this is actually required,
// but it works, so w/e.

var localized string strNewAbilitiesAdded;

var private localized string strTitleInfusionFinished;
var private localized string strTitleEvaluationGifted;
var private localized string strTitleEvaluationNotGifted;

enum eAlert_IRIFMPSI
{
	eAlert_IRIFMPSI_Infusion_Finished,
	eAlert_IRIFMPSI_Evaluation_Gifted,
	eAlert_IRIFMPSI_Evaluation_Giftless
};

simulated function BuildAlert()
{
	BindLibraryItem();

	switch ( eAlertName )
	{
	case 'eAlert_IRIFMPSI_Infusion_Finished':
		BuildAlert_Infusion();
		break;

	case 'eAlert_IRIFMPSI_Evaluation_Gifted':
		BuildAlert_Evaluation_Gifted();
		break;	

	case 'eAlert_IRIFMPSI_Evaluation_Giftless':
		BuildAlert_Evaluation_NotGifted();
		break;

	default:
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
	case 'eAlert_IRIFMPSI_Infusion_Finished':
	case 'eAlert_IRIFMPSI_Evaluation_Gifted':
		return 'Alert_TrainingComplete';

	case 'eAlert_IRIFMPSI_Evaluation_Giftless':
		return 'Alert_NegativeSoldierEvent';

	default:
		return '';
	}
}

private function BuildAlert_Evaluation_NotGifted()
{
	local XComGameState_Unit UnitState;
	local XGBaseCrewMgr CrewMgr;
	local XComGameState_HeadquartersRoom RoomState;
	local Vector ForceLocation;
	local Rotator ForceRotation;
	local XComUnitPawn UnitPawn;
	local string ClassIcon, ClassName, RankName;
	local X2AbilityTemplate AbilityTemplate;
	
	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	
	if (UnitState.GetRank() > 0)
	{
		// Start Issue #106
		ClassName = `CAPS(UnitState.GetSoldierClassDisplayName());
		// End Issue #106
	}
	else
	{
		ClassName = "";
	}

	// Start Issue #106
	ClassIcon = UnitState.GetSoldierClassIcon();
	// End Issue #106
	RankName = Caps(UnitState.GetSoldierRankName()); // Issue #408

	// Move the camera
	CrewMgr = `GAME.GetGeoscape().m_kBase.m_kCrewMgr;
	RoomState = CrewMgr.GetRoomFromUnit(UnitState.GetReference());
	UnitPawn = CrewMgr.GetPawnForUnit(UnitState.GetReference());

	if(RoomState != none && UnitPawn != none)
	{
		ForceLocation = UnitPawn.GetHeadLocation();
		ForceLocation.X += 50;
		ForceLocation.Y -= 300;
		ForceRotation.Yaw = 16384;
		`HQPRES.CAMLookAtRoom(RoomState, `HQINTERPTIME, ForceLocation, ForceRotation);
	}

	AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('IRI_NoPsionicGift');

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(strTitleEvaluationNotGifted);
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(ClassIcon);
	LibraryPanel.MC.QueueString(RankName);
	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
	LibraryPanel.MC.QueueString(ClassName);
	LibraryPanel.MC.QueueString(AbilityTemplate.IconImage); 
	LibraryPanel.MC.QueueString(`CAPS(class'XGTacticalScreenMgr'.default.m_arrCategoryNames[eCat_MissionResult])); // "Result"
	LibraryPanel.MC.QueueString(AbilityTemplate.LocFriendlyName);	// "Not Gifted"
	LibraryPanel.MC.QueueString(AbilityTemplate.LocHelpText);		// "This soldier has no Psionic Gift"
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(m_strOk);
	LibraryPanel.MC.EndOp();

	GetOrStartWaitingForStaffImage();
	// Always hide the "Continue" button, since this is just an informational popup
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon()); //bsg-hlee (05.09.17): Changing the icon to A.
	Button1.Hide(); 
	Button1.DisableNavigation();
}

simulated function BuildAlert_Evaluation_Gifted()
{
	local XComGameState_Unit UnitState;
	local X2SoldierClassTemplate ClassTemplate;
	local XGParamTag kTag;
	local string AbilityIcon, AbilityName, AbilityDescription, ClassIcon, ClassName, RankName;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager TemplateManager;
	local name AbilityTemplateName;

	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));

	AbilityTemplateName = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'AbilityTemplate');
	if (AbilityTemplateName != '')
	{
		TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
		AbilityTemplate = TemplateManager.FindAbilityTemplate(AbilityTemplateName);
		AbilityName = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for ability '" $ AbilityTemplate.DataName $ "'");
		AbilityDescription = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, UnitState) : ("Missing 'LocLongDescription' for ability " $ AbilityTemplate.DataName $ "'");
		AbilityIcon = AbilityTemplate.IconImage;
	}
	
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	ClassName = Caps(ClassTemplate.DisplayName);
	ClassIcon = ClassTemplate.IconImage;
	RankName = Caps(class'X2ExperienceConfig'.static.GetRankName(UnitState.GetRank(), ClassTemplate.DataName));

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = "";

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(strTitleEvaluationGifted);
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

simulated function BuildAlert_Infusion()
{
	local XComGameState_Unit UnitState;
	local X2SoldierClassTemplate ClassTemplate;
	local XGParamTag kTag;
	local string AbilityIcon, AbilityName, AbilityDescription, ClassIcon, ClassName, RankName;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager TemplateManager;
	local name AbilityTemplateName;

	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));

	AbilityTemplateName = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'AbilityTemplate');
	if (AbilityTemplateName != '')
	{
		TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
		AbilityTemplate = TemplateManager.FindAbilityTemplate(AbilityTemplateName);
		AbilityName = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for ability '" $ AbilityTemplate.DataName $ "'");
		AbilityDescription = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, UnitState) : ("Missing 'LocLongDescription' for ability " $ AbilityTemplate.DataName $ "'");
		AbilityIcon = AbilityTemplate.IconImage;
	}
	else
	{
		AbilityName = strNewAbilitiesAdded;
	}
	
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	ClassName = Caps(ClassTemplate.DisplayName);
	ClassIcon = ClassTemplate.IconImage;
	RankName = Caps(class'X2ExperienceConfig'.static.GetRankName(UnitState.GetRank(), ClassTemplate.DataName));

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = "";

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(strTitleInfusionFinished);
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(ClassIcon);
	LibraryPanel.MC.QueueString(RankName);
	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
	LibraryPanel.MC.QueueString(ClassName);
	LibraryPanel.MC.QueueString(AbilityIcon);

	if (AbilityTemplateName != '')
	{
		LibraryPanel.MC.QueueString(m_strNewAbilityLabel);
	}
	else
	{
		LibraryPanel.MC.QueueString("");
	}
	LibraryPanel.MC.QueueString(AbilityName);
	LibraryPanel.MC.QueueString(AbilityDescription);
	LibraryPanel.MC.QueueString(m_strViewSoldier);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();

	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
}

/*
simulated function OnConfirmClicked(UIButton button)
{
	local delegate<X2StrategyGameRulesetDataStructures.AlertCallback> LocalCallbackFunction;

	`AMLOG("Running" @ string(DisplayPropertySet.CallbackFunction));
	// This just runs XComGameState_HeadquartersProjectPsiTraining_FOXCOM_12.TrainingCompleteCB

	if( DisplayPropertySet.CallbackFunction != none )
	{
		LocalCallbackFunction = DisplayPropertySet.CallbackFunction;
		LocalCallbackFunction('eUIAction_Accept', DisplayPropertySet, false);
	}
	
	// The callbacks could potentially remove this screen, so make sure we haven't been removed already
	if( !bIsRemoved )
		CloseScreen();
}
*/