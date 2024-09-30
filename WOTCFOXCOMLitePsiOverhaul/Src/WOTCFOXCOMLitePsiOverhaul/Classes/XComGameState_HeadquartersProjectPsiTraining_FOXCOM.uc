class XComGameState_HeadquartersProjectPsiTraining_FOXCOM extends XComGameState_HeadquartersProjectPsiTraining config(StrategyTuning);

var private bool bPsiInfusion;
var private bool bPsiOperativeTraining;
var private bool bAlwaysGifted;
var private bool bHasGift;

var private config(PsiOverhaul) int	InitialPsiOffenseBonus;

var config array<int> PsiEvaluationDays;
var config array<int> PsiInfusionDays;

var private config(PsiOverhaul) bool bEnablePsiAbilityTaxForAlwaysGiftedUnits;

`include(WOTCFOXCOMLitePsiOverhaul\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

// ---------------------------------- OVERRIDDEN METHODS ----------------------------------

function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory				History;
	local XComGameState_Unit				UnitState;
	local XComGameState_GameTime			TimeState;
	local XComGameState_HeadquartersXCom	XComHQ;

	// -------------------------------------------------
	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(FocusRef.ObjectID));
	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(FocusRef.ObjectID));
		if (UnitState != none)
		{
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		}
	}
	if (UnitState == none)
	{
		`AMLOG("ERROR :: Failed to acquire Unit State!" @ FocusRef.ObjectID @ History.GetGameStateForObjectID(FocusRef.ObjectID).Class);
		return;
	}

	// -------------------------------------------------

	// Vanilla Psi Operative support
	if (UnitState.GetSoldierClassTemplateName() == 'PsiOperative')
	{
		bPsiOperativeTraining = true;
		super.SetProjectFocus(FocusRef, NewGameState, AuxRef);
		return;
	}

	bAlwaysGifted = class'Help'.static.IsUnitAlwaysGifted(UnitState);
	
	if (class'Help'.static.IsGiftless(UnitState) || bAlwaysGifted)
	{
		bPsiInfusion = true;

		XComHQ = class'Help'.static.GetAndPrepXComHQ(NewGameState);
		PayInfusionCost(XComHQ, NewGameState);
	}
	
	ProjectFocus = FocusRef;	// Unit
	AuxilaryReference = AuxRef;	// Facility

	`AMLOG("Starting project for:" @ UnitState.GetFullName() @ "is doing Infusion:" @ bPsiInfusion);

	ProjectPointsRemaining = CalculatePointsToTrain();
	InitialProjectPoints = ProjectPointsRemaining;
	UpdateWorkPerHour(NewGameState); 

	`AMLOG(`ShowVar(ProjectPointsRemaining) @ `ShowVar(InitialProjectPoints) @ "Work Per Hour:" @ GetCurrentWorkPerHour());

	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	StartDateTime = TimeState.CurrentTime;

	if (`STRATEGYRULES != none)
	{
		if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(TimeState.CurrentTime, `STRATEGYRULES.GameTime))
		{
			StartDateTime = `STRATEGYRULES.GameTime;
		}
	}

	if (MakingProgress())
	{
		SetProjectedCompletionDateTime(StartDateTime);
	}
	else
	{
		// Set completion time to unreachable future
		CompletionDateTime.m_iYear = 9999;
	}
}

function int CalculatePointsToTrain(optional bool bClassTraining = false)
{
	if (bPsiOperativeTraining)
	{
		return super.CalculatePointsToTrain(bClassTraining);
	}
	if (bPsiInfusion)
	{
		return `ScaleStrategyArrayInt(default.PsiInfusionDays) * `XCOMHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour * 24;
	}
	
	`AMLOG("Days:" @ `ScaleStrategyArrayInt(default.PsiEvaluationDays) @ "Work Per Hour:" @ `XCOMHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour);
	return `ScaleStrategyArrayInt(default.PsiEvaluationDays) * `XCOMHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour * 24;
}

function OnProjectCompleted()
{
	local XComGameState_Unit				UnitState;
	//local X2AbilityTemplate					AbilityTemplate;
	local name								AbilityName;
	local XComGameState						NewGameState;
	local int								CurrentPsiOffense;
	local int								iFinalRow;
	local bool								bOneFewerPsiAbility;

	if (bPsiOperativeTraining)
	{
		super.OnProjectCompleted();
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectFocus.ObjectID));
	if (UnitState == none)
		return;

	// Roll for The Gift, if needed.
	if (!bPsiInfusion && !bAlwaysGifted)
	{
		bHasGift = RollUnitHasGift(UnitState);
		if (!bHasGift)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Complete FOXCOM Psi Training");
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
			class'Help'.static.MarkGiftless(UnitState);
			CompleteProject(NewGameState, GetReference(), UnitState);
			`GAMERULES.SubmitGameState(NewGameState);

			ShowTrainingCompletedPopUp(ProjectFocus, 'eAlert_IRIFMPSI_Evaluation_Giftless');

			return;
		}
	}

	// If it's a gifted rookie, make them a Psi Operative.
	if (UnitState.GetRank() == 0 && bHasGift)
	{
		super.OnProjectCompleted();
		return;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Complete FOXCOM Psi Training");
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
	CompleteProject(NewGameState, GetReference(), UnitState);

	// Give psi perks.
	if (bPsiInfusion || bHasGift || bAlwaysGifted)
	{
		// Always Gifted units don't get a free Psi Perk.
		if (default.bEnablePsiAbilityTaxForAlwaysGiftedUnits)
		{
			bOneFewerPsiAbility = bAlwaysGifted;
		}
		iFinalRow = InjectPsiPerks(UnitState, NewGameState, bOneFewerPsiAbility); 
		
		// Mark soldier so they can't undergo psionic training again. Unit value will store the index of the row where psionic abilities start.
		class'Help'.static.MarkGifted(UnitState, iFinalRow);

		// This will equip a Psi Amp into the freshly unlocked slot
		UnitState.ValidateLoadout(NewGameState);

		// Boost Psi Offense
		CurrentPsiOffense = UnitState.GetMaxStat(eStat_PsiOffense);
		UnitState.SetBaseMaxStat(eStat_PsiOffense, CurrentPsiOffense + InitialPsiOffenseBonus);

		if (`GETMCMVAR(CHANGE_APPEARANCE))
		{
			UnitState.kAppearance.iHairColor = `GETMCMVAR(HAIR_COLOR);
			UnitState.kAppearance.iEyeColor = `GETMCMVAR(EYE_COLOR);
		}

		`GAMERULES.SubmitGameState(NewGameState);

		// NOTE: Important to show pop-ups AFTER the game state was submitted,
		// because showing a pop-up will toggle Avenger scanning, which in itself requires a game state submission

		// Pop Up Msg
		//if (bAlwaysGifted)
		//{
		//	ShowTrainingCompletedPopUp(ProjectFocus, 'eAlert_IRIFMPSI_Evaluation_Gifted');
		//}
		//else 
		if (bPsiInfusion)
		{
			AbilityName = UnitState.GetAbilityName(0, iFinalRow); 
			ShowTrainingCompletedPopUp(ProjectFocus, 'eAlert_IRIFMPSI_Infusion_Finished', AbilityName);
		}
		else if (bHasGift)
		{
			AbilityName = UnitState.GetAbilityName(0, iFinalRow); 
			ShowTrainingCompletedPopUp(ProjectFocus, 'eAlert_IRIFMPSI_Evaluation_Gifted', AbilityName);
		}
	}
}

// ---------------------------------- NEW INTERNAL METHODS ----------------------------------

private function CompleteProject(XComGameState AddToGameState, StateObjectReference ProjectRef, XComGameState_Unit UnitState)
{
	local XComGameState_HeadquartersProjectPsiTraining ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectPsiTraining(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}

		UnitState.SetStatus(eStatus_Active);

		// Remove the soldier from the staff slot
		StaffSlotState = UnitState.GetStaffSlot();
		if (StaffSlotState != none)
		{
			StaffSlotState.EmptySlot(AddToGameState);
		}
			
		`XEVENTMGR.TriggerEvent('PsiTrainingCompleted', UnitState, UnitState, AddToGameState);
		
	}
}

private function ShowTrainingCompletedPopUp(StateObjectReference UnitRef, const name AlertName, optional name AbilityName = '')
{
	local DynamicPropertySet PropertySet;

	if (AlertName == 'eAlert_IRIFMPSI_Evaluation_Giftless')
	{
		class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIAlert_PsiTraining_FOXCOM', AlertName, none, true, true, true, false);
	}
	else
	{
		class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIAlert_PsiTraining_FOXCOM', AlertName, TrainingCompleteCB, true, true, true, false);
	}
	
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'EventToTrigger', '');
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'SoundToPlay', "Geoscape_CrewMemberLevelledUp");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'AbilityTemplate', AbilityName);
	`HQPRES.QueueDynamicPopup(PropertySet);
}

simulated function TrainingCompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool LocbInstant = false)
{
	local XComGameState_Unit UnitState;

	if (eAction == 'eUIAction_Accept' || eAction == 'eUIAction_Cancel')
	{
		if (!`HQPRES.m_kAvengerHUD.Movie.Stack.HasInstanceOf(class'UIArmory_Promotion')) // If we are already in the promotion screen, just close this popup
		{
			if (eAction == 'eUIAction_Accept')
			{
				UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'UnitRef')));
				if (UnitState == none)
					return;

				// This was super annoying to debug, but it actually works fine, it just doesn't trigger on any Debug start, including non-cheat,
				// cuz that records for some reason that has already played.
				// ... or maybe MeetAllFactions does...

				class'X2StrategyGameRulesetDataStructures'.static.ShowClassMovie('PsiOperative', UnitState.GetReference(), false);
				
				`HQPRES.ShowPromotionUI(UnitState.GetReference());
			}
		}
	}
}

private function int InjectPsiPerks(out XComGameState_Unit UnitState, out XComGameState NewGameState, bool bOneFewerPsiAbility)
{
	local int						iNumPerks;
	local SoldierRankAbilities		InsertAbilities;
	local AbilitySelector			Selector;
	local int						StartingRank;
	local int iFinalRow;
	local int iRank;
	local int i;	

	if (UnitState.GetSoldierClassTemplate() == none)
		return INDEX_NONE;

	// Calculate the index of the last ability row for this soldier.
	// Cycle through the entire ability tree so that if there's even one perk on the final row, all psionic rows will go below it.
	for (i = 0; i < UnitState.AbilityTree.Length; i++)
	{
		iFinalRow = Max(iFinalRow, UnitState.AbilityTree[i].Abilities.Length);
	}

	iNumPerks = UnitState.GetSoldierClassTemplate().GetMaxConfiguredRank();

	if (bOneFewerPsiAbility)
	{
		StartingRank = 1;

		iNumPerks--; // For balancing reasons, always gifted units, like Templars, don't get a free perk.
	}
	else
	{
		StartingRank = 0;
	}

	Selector = new class'AbilitySelector';
	Selector.UnitState = UnitState;
	Selector.BuildPsiAbilities(InsertAbilities, iNumPerks);

	if (bOneFewerPsiAbility)
	{	
		InsertAbilities.Abilities.InsertItem(0, InsertAbilities.Abilities[0]); // Add a dummy copy of the first perk in the tree so that array index can work
	}

	for (iRank = StartingRank; iRank < InsertAbilities.Abilities.Length; iRank++)
	{
		UnitState.AbilityTree[iRank].Abilities[iFinalRow] = InsertAbilities.Abilities[iRank];
	}

	// Instantly learn squaddie ability
	if (!bOneFewerPsiAbility)
	{
		UnitState.BuySoldierProgressionAbility(NewGameState, 0, iFinalRow);
	}

	return iFinalRow;
}

private function bool RollUnitHasGift(const XComGameState_Unit UnitState)
{
	local CharacterPoolManager		CharPool;
	local XComGameState_Unit		CPUnitState;
	
	//if (IsUnitAlwaysGifted(UnitState))
	//	return true;

	if (`GETMCMVAR(GIFT_PSIOP_GUARANTEED))
	{
		CharPool = `CHARACTERPOOLMGR;
	
		foreach CharPool.CharacterPool(CPUnitState)
		{
			if (CPUnitState.GetFullName() == UnitState.GetFullName() &&
				CPUnitState.GetSoldierClassTemplateName() == 'PsiOperative')
			{
				return true;
			}
		}
	}

	return `SYNC_RAND(100) < `GETMCMVAR(GIFT_CHANCE);
}

private function PayInfusionCost(XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState)
{
	local StrategyCost				InfusionCost;
	local array<StrategyCostScalar> CostScalars;

	InfusionCost = class'X2DLCInfo_WOTCFOXCOMLitePsiOverhaul'.static.GetInfusionCost();

	CostScalars.Length = 0; // Settle down, compiler
	XComHQ.PayStrategyCost(NewGameState, InfusionCost, CostScalars);
}
