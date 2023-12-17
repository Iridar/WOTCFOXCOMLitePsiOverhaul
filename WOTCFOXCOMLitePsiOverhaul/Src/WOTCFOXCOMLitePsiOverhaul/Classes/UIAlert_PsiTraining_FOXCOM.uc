class UIAlert_PsiTraining_FOXCOM extends UIAlert;

// This class is bloody ugly cargo culted mess, no idea how much of this is actually required,
// but it works, so w/e.

var localized string strNoGift;

enum UIAlert_PsiTraining_FOXCOM
{
	eAlert_PsiTraining_FOXCOMTrainingComplete,
	eAlert_PsiTraining_FOXCOMTrainingFailed,
	eAlert_PsiTraining_FOXCOMTrainingCompleteNoAbility,
};

simulated function BuildAlert()
{
	BindLibraryItem();

	switch ( eAlertName )
	{
	case 'eAlert_PsiTraining_FOXCOMTrainingComplete':
	case 'eAlert_PsiTraining_FOXCOMTrainingCompleteNoAbility':
		BuildPsiTraining_FOXCOMTrainingCompleteAlert(m_strPsiTrainingCompleteLabel); // TODO: Use Psi Testing
		break;	
	case 'eAlert_PsiTraining_FOXCOMTrainingFailed':
		BuildSoldierHasNoGiftAlert();
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
	case 'eAlert_PsiTraining_FOXCOMTrainingFailed':
		return 'Alert_NegativeSoldierEvent';
	default:
		return '';
	}
}

simulated function BuildSoldierHasNoGiftAlert()
{
	local XComGameState_Unit UnitState;
	local XGBaseCrewMgr CrewMgr;
	local XComGameState_HeadquartersRoom RoomState;
	local Vector ForceLocation;
	local Rotator ForceRotation;
	local XComUnitPawn UnitPawn;
	local string ClassIcon, ClassName, RankName;
	local X2ItemTemplate ItemTemplate;
	local string strTitle;
	
	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	
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

	ItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate('PsionicEvaluation');
	if (ItemTemplate != none)
	{
		strTitle = ItemTemplate.FriendlyName;
	}
	else
	{
		strTitle = "Psionic Evaluation";
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(`CAPS(strTitle));
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(ClassIcon);
	LibraryPanel.MC.QueueString(RankName);
	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
	LibraryPanel.MC.QueueString(ClassName);
	LibraryPanel.MC.QueueString("img:///UILibrary_XPACK_Common.PerkIcons.weakx_fearofpsionics"); // Ability Icon
	LibraryPanel.MC.QueueString(class'XGTacticalScreenMgr'.default.m_arrCategoryNames[eCat_MissionResult] /*NegativeTrait.TraitFriendlyName*/); // Ability Label
	LibraryPanel.MC.QueueString(strNoGift /*NegativeTrait.TraitScientificName*/); // Ability Name
	LibraryPanel.MC.QueueString("" /*TraitDesc*/); // Ability Description
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(m_strOk);
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();
	// Always hide the "Continue" button, since this is just an informational popup
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon()); //bsg-hlee (05.09.17): Changing the icon to A.
	Button1.Hide(); 
	Button1.DisableNavigation();
}

simulated function BuildPsiTraining_FOXCOMTrainingCompleteAlert(string TitleLabel)
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

	AbilityTemplateName = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'AbilityTemplate');
	if (AbilityTemplateName != '')
	{
		TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
		AbilityTemplate = TemplateManager.FindAbilityTemplate(AbilityTemplateName);
		AbilityName = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for ability '" $ AbilityTemplate.DataName $ "'");
		AbilityDescription = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, UnitState) : ("Missing 'LocLongDescription' for ability " $ AbilityTemplate.DataName $ "'");
		AbilityIcon = AbilityTemplate.IconImage;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	ClassName = Caps(ClassTemplate.DisplayName);
	ClassIcon = ClassTemplate.IconImage;
	RankName = Caps(class'X2ExperienceConfig'.static.GetRankName(UnitState.GetRank(), ClassTemplate.DataName));

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = "";

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(TitleLabel);
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