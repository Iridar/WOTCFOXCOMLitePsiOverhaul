class X2DLCInfo_WOTCFOXCOMLitePsiOverhaul extends X2DownloadableContentInfo;

var config(StrategyTuning) array<StrategyCost>	Cost;
var config(StrategyTuning) array<int>			BuildDays;
var config(StrategyTuning) array<int>			Power;
var config(StrategyTuning) array<int>			UpkeepCost;
var config(StrategyTuning) bool					bSkipRemovingPsionicsResearchCost;

static event OnPostTemplatesCreated()
{
	local X2FacilityTemplate				FacilityTemplate;
	local X2StrategyElementTemplateManager	StratMgr;
	local array<X2DataTemplate>				DataTemplates;
	local X2DataTemplate					DataTemplate;
	local int								iDiff;
	local X2TechTemplate					TechTemplate;
	local StrategyCost						EmptyCost;
	local X2StaffSlotTemplate				StaffSlotTemplate;
	local X2ItemTemplateManager				ItemMgr;
	local X2ItemTemplate					ItemTemplate;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	StratMgr.FindDataTemplateAllDifficulties('PsiChamber', DataTemplates);
	foreach DataTemplates(DataTemplate, iDiff)
	{
		if (iDiff > 3)
			break; 

		FacilityTemplate = X2FacilityTemplate(DataTemplate);
		if (FacilityTemplate == none)
			continue;

		FacilityTemplate.Cost = default.Cost[iDiff];
		FacilityTemplate.PointsToComplete = class'X2StrategyElement_DefaultFacilities'.static.GetFacilityBuildDays(default.BuildDays[iDiff]);
		FacilityTemplate.iPower = default.Power[iDiff];
		FacilityTemplate.UpkeepCost = default.UpkeepCost[iDiff];
	}

	if (!default.bSkipRemovingPsionicsResearchCost)
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

	StaffSlotTemplate = X2StaffSlotTemplate(StratMgr.FindStrategyElementTemplate('PsiChamberSoldierStaffSlot'));
	if (StaffSlotTemplate != none)
	{
		`AMLOG("Patching psi lab staff slot");
		StaffSlotTemplate.AssociatedProjectClass = class'XComGameState_HeadquartersProjectPsiTraining_FOXCOM';
		StaffSlotTemplate.FillFn = FillPsiChamberSoldierSlot;
		StaffSlotTemplate.IsUnitValidForSlotFn = IsUnitValidForPsiChamberSoldierSlot;
	}

	class'AbilitySelector'.static.ValidatePsiAbilities();

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplate = ItemMgr.FindItemTemplate('PsiAmp_CV');
	if (ItemTemplate != none)
	{
		class'X2StrategyElement_PsiAmp'.default.strSlotLocName = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(ItemTemplate.GetItemFriendlyNameNoStats());
		//class'X2StrategyElement_PsiAmp'.default.strSlotFirstLetter = "";
	}
}

static private function FillPsiChamberSoldierSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo, optional bool bTemporary = false)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_HeadquartersProjectPsiTraining_FOXCOM ProjectState;
	local StateObjectReference EmptyRef;
	local int SquadIndex;

	class'X2StrategyElement_DefaultStaffSlots'.static.FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	
	if (!class'Help'.static.IsPsiOperative(NewUnitState)) 
	{
		NewUnitState.SetStatus(eStatus_PsiTesting);

		NewXComHQ = class'X2StrategyElement_DefaultStaffSlots'.static.GetNewXComHQState(NewGameState);

		ProjectState = XComGameState_HeadquartersProjectPsiTraining_FOXCOM(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectPsiTraining_FOXCOM'));
		ProjectState.SetProjectFocus(UnitInfo.UnitRef, NewGameState, NewSlotState.Facility);

		NewXComHQ.Projects.AddItem(ProjectState.GetReference());

		// Remove their gear
		NewUnitState.MakeItemsAvailable(NewGameState, false);

		// If the unit undergoing training is in the squad, remove them
		SquadIndex = NewXComHQ.Squad.Find('ObjectID', UnitInfo.UnitRef.ObjectID);
		if (SquadIndex != INDEX_NONE)
		{
			// Remove them from the squad
			NewXComHQ.Squad[SquadIndex] = EmptyRef;
		}
	}
	else // The unit is either starting or resuming an ability training project, so set their status appropriately
	{
		NewUnitState.SetStatus(eStatus_PsiTraining);
	}
}

static private function bool IsUnitValidForPsiChamberSoldierSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit; 
	//local SCATProgression ProgressAbility;
	//local name AbilityName;
	local bool bOverridePsiTrain, bCanTrain; //issue #159 - booleans for mod override
	local XComLWTuple Tuple; //issue #159 - tuple for event
	local bool bUnitInitiallyValid;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	if (Unit == none)
		return false;

	if (class'Help'.static.IsPsiOperative(Unit))
		return false;

	if (Unit.CanBeStaffed()
		&& Unit.IsSoldier()
		&& Unit.IsActive()
		&& SlotState.GetMyTemplate().ExcludeClasses.Find(Unit.GetSoldierClassTemplateName()) == INDEX_NONE)
	{
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

		bUnitInitiallyValid = true;

		//if (Unit.GetRank() == 0 && !Unit.CanRankUpSoldier()) // All rookies who have not yet ranked up can be trained as Psi Ops
		//{
		//	return true;
		//}
		//else if (Unit.GetSoldierClassTemplateName() == 'PsiOperative') // But Psi Ops can only train until they learn all abilities
		//{
		//	foreach Unit.PsiAbilities(ProgressAbility)
		//	{
		//		AbilityName = Unit.GetAbilityName(ProgressAbility.iRank, ProgressAbility.iBranch);
		//		if (AbilityName != '' && !Unit.HasSoldierAbility(AbilityName))
		//		{
		//			return true; // If we find an ability that the soldier hasn't learned yet, they are valid
		//		}
		//	}
		//}
	}

	// TODO: Exclude SPARKs

	return bUnitInitiallyValid && Unit.GetRank() > 0;
}

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