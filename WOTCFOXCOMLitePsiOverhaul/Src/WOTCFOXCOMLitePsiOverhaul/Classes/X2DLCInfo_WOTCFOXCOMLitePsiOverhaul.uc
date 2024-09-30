class X2DLCInfo_WOTCFOXCOMLitePsiOverhaul extends X2DownloadableContentInfo;

var config(StrategyTuning) array<StrategyCost>	PsiLabCost;
var config(StrategyTuning) array<int>			PsiLabBuildDays;
var config(StrategyTuning) array<int>			PsiLabPower;
var config(StrategyTuning) array<int>			PsiLabUpkeepCost;

var config(StrategyTuning) array<StrategyCost>	InfusionChamberCost;
var config(StrategyTuning) array<int>			InfusionChamberPower;
var config(StrategyTuning) array<int>			InfusionChamberUpkeepCost;

var config(StrategyTuning) array<StrategyCost>	InfusionCost;

`include(WOTCFOXCOMLitePsiOverhaul\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

static event OnPostTemplatesCreated()
{
	local X2FacilityTemplate				FacilityTemplate;
	local X2StrategyElementTemplateManager	StratMgr;
	local array<X2DataTemplate>				DataTemplates;
	local X2DataTemplate					DataTemplate;
	local int								iDiff;
	local X2TechTemplate					TechTemplate;
	local StrategyCost						EmptyCost;
	local X2ItemTemplateManager				ItemMgr;
	local X2ItemTemplate					ItemTemplate;
	local X2FacilityUpgradeTemplate			FacilityUpgradeTemplate;
	local StaffSlotDefinition				StaffSlotDef;
	local X2StaffSlotTemplate				StaffSlotTemplateA;
	local X2StaffSlotTemplate				StaffSlotTemplateB;
	local int i;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	StratMgr.FindDataTemplateAllDifficulties('PsiChamber', DataTemplates);

	foreach DataTemplates(DataTemplate, iDiff)
	{
		if (iDiff > 3)
			break; 

		FacilityTemplate = X2FacilityTemplate(DataTemplate);
		if (FacilityTemplate == none)
			continue;

		if (`GETMCMVAR(CHEAPER_PSI_LAB))
		{
			FacilityTemplate.Cost = default.PsiLabCost[iDiff];
			FacilityTemplate.PointsToComplete = class'X2StrategyElement_DefaultFacilities'.static.GetFacilityBuildDays(default.PsiLabBuildDays[iDiff]);
			FacilityTemplate.iPower = default.PsiLabPower[iDiff];
			FacilityTemplate.UpkeepCost = default.PsiLabUpkeepCost[iDiff];
		}

		// Remove vanila staff slots
		for (i = FacilityTemplate.StaffSlotDefs.Length; i >= 0; i--)
		{
			if (FacilityTemplate.StaffSlotDefs[i].StaffSlotTemplateName == 'PsiChamberSoldierStaffSlot')
			{
				FacilityTemplate.StaffSlotDefs.Remove(i, 1);
			}
		}

		// Add new staff slots
		StaffSlotDef.StaffSlotTemplateName = 'IRI_PsiEvaluationStaffSlot';
		StaffSlotDef.bStartsLocked = false; // Have to explicitly set to revert =true from the previous foreach() cycle
		FacilityTemplate.StaffSlotDefs.AddItem(StaffSlotDef);

		StaffSlotDef.StaffSlotTemplateName = 'IRI_PsiInfusionStaffSlot';
		StaffSlotDef.bStartsLocked = true;
		FacilityTemplate.StaffSlotDefs.AddItem(StaffSlotDef);
	}
	
	StratMgr.FindDataTemplateAllDifficulties('PsiChamber_SecondCell', DataTemplates);
	foreach DataTemplates(DataTemplate, iDiff)
	{
		if (iDiff > 3)
			break; 

		// Make the second cell cost same as the lab itself
		FacilityUpgradeTemplate = X2FacilityUpgradeTemplate(DataTemplate);

		FacilityUpgradeTemplate.Cost = default.InfusionChamberCost[iDiff];
		FacilityUpgradeTemplate.iPower = default.InfusionChamberPower[iDiff];
		FacilityUpgradeTemplate.UpkeepCost = default.InfusionChamberUpkeepCost[iDiff];
	}

	if (`GETMCMVAR(REMOVE_RESEARCH_COST))
	{
		StratMgr.FindDataTemplateAllDifficulties('Psionics', DataTemplates);
		foreach DataTemplates(DataTemplate)
		{
			TechTemplate = X2TechTemplate(DataTemplate);
			if (TechTemplate == none)
				continue;

			TechTemplate.Cost = EmptyCost;
		}
	}

	class'AbilitySelector'.static.ValidatePsiAbilities();

	if (`GETMCMVAR(PS_LAB_STAFF_SCIENTIST))
	{
		StaffSlotTemplateA = X2StaffSlotTemplate(StratMgr.FindStrategyElementTemplate('PsiChamberScientistStaffSlot'));
		StaffSlotTemplateB = X2StaffSlotTemplate(StratMgr.FindStrategyElementTemplate('LaboratoryStaffSlot'));

		if (StaffSlotTemplateA != none && StaffSlotTemplateB != none)
		{
			StaffSlotTemplateA.bScientistSlot = true;
			StaffSlotTemplateA.bEngineerSlot = false;
			StaffSlotTemplateA.EmptyText = StaffSlotTemplateB.EmptyText; // Change "open: engineer required" into "open: scientist required"

			if (`GETMCMVAR(DISABLE_STAFF_SLOT_FILLED_POPUP))
			{
				StaffSlotTemplateA.bPreventFilledPopup = true;
			}
		}
	}
	// Some localization helpers to copy existing game localization so we don't have to provide our own.

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplate = ItemMgr.FindItemTemplate('PsiAmp_CV');
	if (ItemTemplate != none)
	{
		class'X2StrategyElement_PsiAmp'.default.strSlotLocName = `CAPS(ItemTemplate.GetItemFriendlyNameNoStats());
		//class'X2StrategyElement_PsiAmp'.default.strSlotFirstLetter = "";
	}

	TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate('Psionics'));
	if (TechTemplate != none)
	{
		class'X2EventListener_PsiOverhaul'.default.PsionicTreeName = `CAPS(TechTemplate.DisplayName);
	}

	StaffSlotTemplateA = X2StaffSlotTemplate(StratMgr.FindStrategyElementTemplate('PsiChamberSoldierStaffSlot'));
	if (StaffSlotTemplateA != none)
	{
		StaffSlotTemplateB = X2StaffSlotTemplate(StratMgr.FindStrategyElementTemplate('IRI_PsiEvaluationStaffSlot'));
		if (StaffSlotTemplateB != none)
		{
			StaffSlotTemplateB.EmptyText = StaffSlotTemplateA.EmptyText;
			StaffSlotTemplateB.LockedText = StaffSlotTemplateA.LockedText;
		}
		StaffSlotTemplateB = X2StaffSlotTemplate(StratMgr.FindStrategyElementTemplate('IRI_PsiInfusionStaffSlot'));
		if (StaffSlotTemplateB != none)
		{
			StaffSlotTemplateB.EmptyText = StaffSlotTemplateA.EmptyText;
			StaffSlotTemplateB.LockedText = StaffSlotTemplateA.LockedText;
		}
	}
}

/*
static private function bool IsUnitValidForPsiChamberSoldierSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit	Unit; 
	local int					SlotIndex;

	// #1. Initial Validation

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	if (Unit == none)
		return false;

	if (!Unit.IsSoldier())
		return TriggerOverridePsiOpTraining(Unit, false);

	// Should exclude SPARKs
	if (Unit.IsRobotic())
		return TriggerOverridePsiOpTraining(Unit, false);

	if (!Unit.CanBeStaffed())
		return false;

	if (!Unit.IsActive())
		return false;

	if (SlotState.GetMyTemplate().ExcludeClasses.Find(Unit.GetSoldierClassTemplateName()) != INDEX_NONE)
		return TriggerOverridePsiOpTraining(Unit, false);

	if (default.ExcludeCharacters.Find(Unit.GetMyTemplateName()) != INDEX_NONE)
		return TriggerOverridePsiOpTraining(Unit, false);

	if (default.ExcludeClasses.Find(Unit.GetSoldierClassTemplateName()) != INDEX_NONE)
		return TriggerOverridePsiOpTraining(Unit, false);

	if (!`GETMCMVAR(ALLOW_ROOKIES) && Unit.GetRank() == 0)
		return TriggerOverridePsiOpTraining(Unit, false);

	// Unit has undergone already Psionic Evaluation or Infusion and was given psi abilities.
	if (class'Help'.static.IsGifted(Unit))
		return false;

	// #2. Different conditions depending on which staff slot we're in.
	SlotIndex = GetStaffSlotIndex(SlotState.GetReference(), SlotState);
	switch (SlotIndex)
	{
	case 1: // This is Psionic Evaluation Chamber. Any unit who hasn't been tested yet is valid.

		if (class'Help'.static.IsGiftless(Unit))
			return false;
			
		return TriggerOverridePsiOpTraining(Unit, true);

	case 2: // This is Psionic Infusion Chamber. Only Giftless units are valid, and player must be able to pay the cost.

		// Not Giftless = not evaluated yet.
		if (!class'Help'.static.IsGiftless(Unit))
			return false;

		// Always Gifted units don't need to be Infused, just Evaluating them is enough.
		if (class'XComGameState_HeadquartersProjectPsiTraining_FOXCOM'.static.IsUnitAlwaysGifted(Unit))
			return TriggerOverridePsiOpTraining(Unit, false);

		return TriggerOverridePsiOpTraining(Unit, true);

	default:
		`AMLOG("ERROR :: Unexpected Staff Slot index in the Psi Lab facility!" @ `ShowVar(SlotIndex) @ SlotState.GetMyTemplateName());
		return false;
	}

	`AMLOG("WARNING :: Unexpected EOC!" @ Unit.GetMyTemplateName() @ Unit.GetFullName() @ SlotState.GetMyTemplateName() @ SlotIndex);
	return TriggerOverridePsiOpTraining(Unit, false);
}*/

static final function StrategyCost GetInfusionCost()
{
	local StrategyCost	InfusionCostDiff;
	local int			Diff;

	Diff = class'XComGameState_CampaignSettings'.static.GetCampaignDifficultyFromSettings();
	if (Diff < default.InfusionCost.Length)
	{
		InfusionCostDiff = default.InfusionCost[Diff];
		return InfusionCostDiff;
	}

	`AMLOG("WARNING :: Unexpected EOC!" @ Diff @ default.InfusionCost.Length);
	return InfusionCostDiff;
}
/*
static private function int GetStaffSlotIndex(StateObjectReference SlotRef, optional XComGameState_StaffSlot ArgSlotState)
{
	local XComGameState_StaffSlot		SlotState;
	local XComGameState_FacilityXCom	PsiLab;
	local int							SlotIndex;

	if (ArgSlotState != none)
	{
		SlotState = ArgSlotState;
	}
	else
	{
		SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(SlotRef.ObjectID));
	}
	if (SlotState == none)
	{
		`AMLOG("WARNING :: Failed to acquire Slot State!" @ SlotRef.ObjectID);
		return INDEX_NONE;
	}

	PsiLab = SlotState.GetFacility();
	if (PsiLab == none)
	{
		`AMLOG("ERROR :: Failed to acquire Psi Lab state object from the staff slot:" @ SlotState.GetMyTemplateName());
		return INDEX_NONE;
	}
	for (SlotIndex = 0; SlotIndex < PsiLab.StaffSlots.Length; SlotIndex++)
	{
		if (PsiLab.StaffSlots[SlotIndex].ObjectID == SlotRef.ObjectID)
		{
			switch (SlotIndex)
			{
				case 1:
				case 2:
					return SlotIndex;
				default:
					`AMLOG("WARNING :: Unexpected staff slot index:" @ SlotIndex @ SlotState.GetMyTemplateName());
					return INDEX_NONE;
			}
			break;
		}
	}

	`AMLOG("WARNING :: Unexpected reach EOC, facility has no Staff Slots:" @ PsiLab.StaffSlots.Length == 0);
	return INDEX_NONE;
}
*/
/*
static private function bool TriggerOverridePsiOpTraining(XComGameState_Unit Unit, bool bCanTrainArg)
{
	local bool			bOverridePsiTrain; //issue #159 - booleans for mod override
	local bool			bCanTrain;
	local XComLWTuple	Tuple; //issue #159 - tuple for event

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'OverridePsiOpTraining';
	Tuple.Data.Add(2);
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = false; //bOverridePsiTrain;
	Tuple.Data[1].kind = XComLWTVBool;
	Tuple.Data[1].b = false; //bCanTrain;
		
	`XEVENTMGR.TriggerEvent('OverridePsiOpTraining', Tuple, Unit);

	bOverridePsiTrain = Tuple.Data[0].b;
	bCanTrain = Tuple.Data[1].b;

	if (bOverridePsiTrain)
	{
		return bCanTrain;
	}
	return bCanTrainArg;
}
*/
static function bool DisplayQueuedDynamicPopup(DynamicPropertySet PropertySet)
{
	local XComHQPresentationLayer Pres;
	local UIAlert_PsiTraining_FOXCOM Alert;

	if (PropertySet.PrimaryRoutingKey == 'UIAlert_PsiTraining_FOXCOM')
	{
		Pres = `HQPRES;

		Alert = Pres.Spawn(class'UIAlert_PsiTraining_FOXCOM', Pres);
		Alert.DisplayPropertySet = PropertySet;
		Alert.eAlertName = PropertySet.SecondaryRoutingKey;

		Pres.ScreenStack.Push(Alert);
		return true;
	}
	return false;
}

static function ModifyEarnedSoldierAbilities(out array<SoldierClassAbilityType> EarnedAbilities, XComGameState_Unit UnitState)
{
	local SoldierClassAbilityType NewAbility;

	if (!class'Help'.static.IsGifted(UnitState) && class'Help'.static.IsGiftless(UnitState))
	{
		NewAbility.AbilityName = 'IRI_NoPsionicGift';
		EarnedAbilities.AddItem(NewAbility);
	}
}

/*
static function bool GetDLCEventInfo(out array<HQEvent> arrEvents)
{
	return false; //returning true will tell the game to add the events have been added to the above array
}*/