class X2StrategyElement_PsiStaffSlots extends X2StrategyElement_DefaultStaffSlots config(PsiOverhaul);

var config array<name>				ExcludeCharacters;
var config array<name>				ExcludeClasses;

`include(WOTCFOXCOMLitePsiOverhaul\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> StaffSlots;

	StaffSlots.AddItem(IRI_PsiEvaluationStaffSlot());
	StaffSlots.AddItem(IRI_PsiInfusionStaffSlot());

	return StaffSlots;
}

static private function X2DataTemplate IRI_PsiEvaluationStaffSlot()
{
	local X2StaffSlotTemplate Template;

	Template = CreateStaffSlotTemplate('IRI_PsiEvaluationStaffSlot');

	Template.bSoldierSlot = true;
	Template.bRequireConfirmToEmpty = true;
	Template.bPreventFilledPopup = true;
	Template.MatineeSlotName = "Soldier";
	Template.ExcludeClasses = default.ExcludeClasses;

	Template.UIStaffSlotClass = class'UIFacility_PsiLabSlot_Evaluation';

	Template.AssociatedProjectClass = class'XComGameState_HeadquartersProjectPsiTraining_FOXCOM';

	Template.FillFn = FillPsiLabStaffSlot;
	Template.EmptyFn = EmptyPsiChamberSoldierSlot;
	Template.EmptyStopProjectFn = EmptyStopProjectPsiChamberSoldierSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayPsiEvaluationSoldierToDoWarning;
	Template.GetSkillDisplayStringFn = GetPsiChamberSoldierSkillDisplayString;
	Template.GetBonusDisplayStringFn = GetPsiLabStaffSlotBonusDisplayString;
	Template.IsUnitValidForSlotFn = IsUnitValidForPsiEvaluationStaffSlot;
	

	return Template;
}

static private function bool IsUnitValidForPsiEvaluationStaffSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit; 

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	//`AMLOG("Running for unit:" @ Unit.GetFullName());
	if (Unit == none)
		return false;

	// If the unit is already a Psi Operative, use vanilla checks.
	if (Unit.GetSoldierClassTemplateName() == 'PsiOperative')
		return IsUnitValidForPsiChamberSoldierSlot(SlotState, UnitInfo);

	if (!IsUnitValidForStaffSlot(Unit, SlotState))
	{
		//`AMLOG("-- Unit is not valid for staffing.");
		return false;
	}
	// Unit was already evaluated
	if (class'Help'.static.IsGiftless(Unit))
	{
		//`AMLOG("-- Unit is giftless.");
		return false;
	}

	// Always Gifted units can't be Evaluated, only Infused
	if (class'Help'.static.IsUnitAlwaysGifted(Unit))
		return false;

	return true;
}

static function bool ShouldDisplayPsiEvaluationSoldierToDoWarning(StateObjectReference SlotRef)
{
	local XComGameState_HeadquartersXCom	XComHQ;
	local XComGameState_StaffSlot			SlotState;
	local StaffUnitInfo						UnitInfo;
	local StateObjectReference				UnitRef;
	
	SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(SlotRef.ObjectID));
	if (SlotState == none)
		return false;

	XComHQ = `XCOMHQ;
	foreach XComHQ.Crew(UnitRef)
	{
		UnitInfo.UnitRef = UnitRef;

		if (IsUnitValidForPsiInfusionStaffSlot(SlotState, UnitInfo))
			return true;
	}

	return false;
}



static private function X2DataTemplate IRI_PsiInfusionStaffSlot()
{
	local X2StaffSlotTemplate Template;

	Template = CreateStaffSlotTemplate('IRI_PsiInfusionStaffSlot');

	Template.bSoldierSlot = true;
	Template.bRequireConfirmToEmpty = true;
	Template.bPreventFilledPopup = true;
	Template.MatineeSlotName = "Soldier";
	Template.ExcludeClasses = default.ExcludeClasses;

	Template.UIStaffSlotClass = class'UIFacility_PsiLabSlot_Infusion';

	Template.AssociatedProjectClass = class'XComGameState_HeadquartersProjectPsiTraining_FOXCOM';

	Template.FillFn = FillPsiLabStaffSlot;
	Template.EmptyFn = EmptyPsiChamberSoldierSlot;
	Template.EmptyStopProjectFn = EmptyStopProjectPsiChamberSoldierSlot;
	Template.ShouldDisplayToDoWarningFn = none; // Psi Infusion costs resources, so it doesn't need to nag at the player about the slot being empty.
	Template.GetSkillDisplayStringFn = GetPsiChamberSoldierSkillDisplayString;
	Template.GetBonusDisplayStringFn = GetPsiLabStaffSlotBonusDisplayString;
	Template.IsUnitValidForSlotFn = IsUnitValidForPsiInfusionStaffSlot;
	

	return Template;
}

static private function bool IsUnitValidForPsiInfusionStaffSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit; 

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	//`AMLOG("Running for unit:" @ Unit.GetFullName());
	if (Unit == none)
		return false;

	// Vanilla Psi Operatives use the Evaluation chamber for their vanilla training.
	if (Unit.GetSoldierClassTemplateName() == 'PsiOperative')
		return false;

	if (!IsUnitValidForStaffSlot(Unit, SlotState))
		return false;

	// Only giftless and always-gifted soldiers are allowed to undergo psionic infusion
	return class'Help'.static.IsGiftless(Unit) || class'Help'.static.IsUnitAlwaysGifted(Unit);
}

// ============================== COMMON =============================


static private function bool IsUnitValidForStaffSlot(XComGameState_Unit Unit, XComGameState_StaffSlot SlotState)
{
	if (!Unit.IsSoldier())
		return false;

	// Should exclude SPARKs
	if (Unit.IsRobotic())
		return false;

	if (!Unit.CanBeStaffed())
		return false;

	if (!Unit.IsActive())
		return false;

	if (SlotState.GetMyTemplate().ExcludeClasses.Find(Unit.GetSoldierClassTemplateName()) != INDEX_NONE)
		return false;

	if (default.ExcludeCharacters.Find(Unit.GetMyTemplateName()) != INDEX_NONE)
		return false;

	if (!`GETMCMVAR(ALLOW_ROOKIES) && Unit.GetRank() == 0)
		return false;

	// Unit has undergone already Psionic Evaluation or Infusion and was given psi abilities.
	if (class'Help'.static.IsGifted(Unit))
		return false;

	return true;
}

static private function FillPsiLabStaffSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo, optional bool bTemporary = false)
{
	local XComGameState_Unit									UnitState;
	local XComGameState_Unit									NewUnitState;
	local XComGameState_StaffSlot								NewSlotState;
	local XComGameState_HeadquartersXCom						NewXComHQ;
	local XComGameState_HeadquartersProjectPsiTraining_FOXCOM	ProjectState;
	local StateObjectReference									EmptyRef;
	local int													SquadIndex;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	if (UnitState == none)
		return;

	// Vanilla Psi Operatives get vanilla Psi Operative treatment.
	if (UnitState.GetSoldierClassTemplateName() == 'PsiOperative')
	{
		FillPsiChamberSoldierSlot(NewGameState, SlotRef, UnitInfo, bTemporary);
		return;
	}

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	
	NewUnitState.SetStatus(eStatus_PsiTesting); // Both slots use eStatus_PsiTesting, which cancels any gained progress. eStatus_PsiTraining is used by vanilla Psi Op to "pause" learning new abilities.
	NewUnitState.MakeItemsAvailable(NewGameState, false); // Remove their gear

	ProjectState = XComGameState_HeadquartersProjectPsiTraining_FOXCOM(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectPsiTraining_FOXCOM'));
	ProjectState.SetProjectFocus(UnitInfo.UnitRef, NewGameState, NewSlotState.Facility);

	NewXComHQ = GetNewXComHQState(NewGameState);
	NewXComHQ.Projects.AddItem(ProjectState.GetReference());

	// If the unit undergoing training is in the squad, remove them from the squad
	SquadIndex = NewXComHQ.Squad.Find('ObjectID', UnitInfo.UnitRef.ObjectID);
	if (SquadIndex != INDEX_NONE)
	{
		NewXComHQ.Squad[SquadIndex] = EmptyRef;
	}
}

// This if for a small dynamic piece of text under the slot itself at the top of the facility
// And also for each soldier in the list during soldier selection, then bPreview = true
// For some reason the slot doesn't count as empty during that, though

// Return "Exposes psionic potential." when the slot is empty for the slot at the top, 
// and "PSI EVALUATION" for the soldier list and when the slot is filled.
static private function string GetPsiLabStaffSlotBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local X2StaffSlotTemplate	StaffSlotTemplate;
	local XComGameState_Unit	Unit;

	`AMLOG(`ShowVar(bPreview));

	StaffSlotTemplate = SlotState.GetMyTemplate();
	if (StaffSlotTemplate == none)
		return "";

	if (!SlotState.IsSlotFilled())
		return StaffSlotTemplate.BonusEmptyText; 

	Unit = SlotState.GetAssignedStaff();
	if (Unit == none)
		return StaffSlotTemplate.BonusEmptyText;

	if (Unit.GetSoldierClassTemplateName() == 'PsiOperative')
		return GetPsiOperativeSkillTrainingString(Unit, bPreview); // Vanilla Psi Operatives.

	return StaffSlotTemplate.BonusDefaultText;
}

// Returns either "PSI OPERATIVE TRAINING" or "SKILLNAME TRAINING" for vanilla Psi Ops.
static private function string GetPsiOperativeSkillTrainingString(XComGameState_Unit Unit, optional bool bPreview)
{
	local X2StrategyElementTemplateManager				StratMgr;
	local X2StaffSlotTemplate							StaffSlotTemplate;
	local XComGameState_HeadquartersProjectPsiTraining	TrainProject;
	local X2AbilityTemplate								AbilityTemplate;
	local name											AbilityName;

	`AMLOG("Running");

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	StaffSlotTemplate = X2StaffSlotTemplate(StratMgr.FindStrategyElementTemplate('PsiChamberSoldierStaffSlot'));
	if (StaffSlotTemplate == none)
		return "";

	if (bPreview)
	{
		// Amounts to "PSI OPERATIVE TRAINING"
		return Repl(StaffSlotTemplate.BonusText, "%SKILL", StaffSlotTemplate.BonusDefaultText);
	}

	TrainProject = `XCOMHQ.GetPsiTrainingProject(Unit.GetReference());
	if (TrainProject == none)
		return ""; // All of this shouldn't be possible, so no error handling

	`AMLOG("Unit" @ Unit.GetFullName());

	AbilityName = Unit.GetAbilityName(TrainProject.iAbilityRank, TrainProject.iAbilityBranch);
	AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
	if (AbilityTemplate == none)
		return "";

	`AMLOG(`ShowVar(AbilityName) @ AbilityTemplate != none);

	return Repl(StaffSlotTemplate.BonusText, "%SKILL", Caps(AbilityTemplate.LocFriendlyName));
}
