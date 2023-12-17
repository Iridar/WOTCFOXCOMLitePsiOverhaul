class XComGameState_HeadquartersProjectPsiTraining_FOXCOM extends XComGameState_HeadquartersProjectPsiTraining config(PsiOverhaul);

var private config int	InitialPsiOffenseBonus;
var bool bPsiOperativeTraining;

`include(WOTCFOXCOMLitePsiOverhaul\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_GameTime TimeState;

	if (bPsiOperativeTraining)
	{
		super.SetProjectFocus(FocusRef, NewGameState, AuxRef);
		return;
	}

	History = `XCOMHISTORY;
	ProjectFocus = FocusRef; // Unit
	AuxilaryReference = AuxRef; // Facility

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ProjectFocus.ObjectID));
	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ProjectFocus.ObjectID));
	}

	`AMLOG("Starting project for:" @ UnitState.GetFullName());

	ProjectPointsRemaining = CalculatePointsToTrain();

	InitialProjectPoints = ProjectPointsRemaining;

	UpdateWorkPerHour(NewGameState); 

	`AMLOG("ProjectPointsRemaining:" @ ProjectPointsRemaining @ GetCurrentWorkPerHour());

	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	StartDateTime = TimeState.CurrentTime;

	if (`STRATEGYRULES != none)
	{
		if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(TimeState.CurrentTime, `STRATEGYRULES.GameTime))
		{
			StartDateTime = `STRATEGYRULES.GameTime;
		}
	}

	if(MakingProgress())
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
	local XComGameState_HeadquartersXCom XComHQ;

	if (bPsiOperativeTraining)
	{
		return super.CalculatePointsToTrain(bClassTraining);
	}

	XComHQ = `XCOMHQ;

	return XComHQ.GetPsiTrainingDays() * XComHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour * 24 / 10; // TODO: DEBUG ONLY
}

function OnProjectCompleted()
{
	local HeadquartersOrderInputContext		OrderInput;
	local XComGameState_Unit				UnitState;
	//local X2AbilityTemplate					AbilityTemplate;
	local name								AbilityName;
	local XComGameState						NewGameState;
	local int								CurrentPsiOffense;
	local int								iFinalRow;
	local bool								bHasGift;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectFocus.ObjectID));
	if (UnitState == none)
		return;

	bHasGift = RollUnitHasGift(UnitState);

	if (bPsiOperativeTraining)
	{
		if (bHasGift)
		{
			super.OnProjectCompleted();
		}
		else
		{
			OrderInput.OrderType = eHeadquartersOrderType_PsiTrainingCompleted;
			OrderInput.AcquireObjectReference = self.GetReference();

			class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);

			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Complete psionic Training");
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
			class'Help'.static.MarkGiftless(UnitState);
			`GAMERULES.SubmitGameState(NewGameState);

			ShowTrainingCompletedPopUp(ProjectFocus, '', true);

			// Start Issue #534
			TriggerPsiProjectCompleted(UnitState, AbilityName);
			// End Issue #534
		}
		return;
	}

	// ----------------------------------------------------------------

	OrderInput.OrderType = eHeadquartersOrderType_PsiTrainingCompleted;
	OrderInput.AcquireObjectReference = self.GetReference();

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Complete psionic Training");
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));

	if (bHasGift)
	{
		CurrentPsiOffense = UnitState.GetMaxStat(eStat_PsiOffense);
		UnitState.SetBaseMaxStat(eStat_PsiOffense, CurrentPsiOffense + InitialPsiOffenseBonus);

		if (`GETMCMVAR(CHANGE_APPEARANCE))
		{
			UnitState.kAppearance.iHairColor = `GETMCMVAR(HAIR_COLOR);
			UnitState.kAppearance.iEyeColor = `GETMCMVAR(EYE_COLOR);
		}
	
		iFinalRow = InjectPsiPerks(UnitState, NewGameState);	

		// Mark soldier so they can't undergo psionic training again. Unit value will store the index of the row where psionic abilities start.
		class'Help'.static.MarkPsiOperative(UnitState, iFinalRow);

		// This will equip a Psi Amp into the freshly unlocked slot
		UnitState.ValidateLoadout(NewGameState);
	}
	else
	{
		class'Help'.static.MarkGiftless(UnitState);
	}

	`GAMERULES.SubmitGameState(NewGameState);

	if (bHasGift)
	{
		AbilityName = UnitState.GetAbilityName(0, iFinalRow); 
		ShowTrainingCompletedPopUp(ProjectFocus, AbilityName);
	}
	else
	{
		ShowTrainingCompletedPopUp(ProjectFocus, '', true);
	}

	// Start Issue #534
	TriggerPsiProjectCompleted(UnitState, AbilityName);
	// End Issue #534
}

private function ShowTrainingCompletedPopUp(StateObjectReference UnitRef, const name AbilityName, optional bool bGiftless = false)
{
	local DynamicPropertySet PropertySet;
	local name AlertName;

	if (AbilityName != '' || bGiftless)
	{
		if (bGiftless)
		{
			AlertName = 'eAlert_PsiTraining_FOXCOMTrainingFailed';
		}
		else
		{
			AlertName = 'eAlert_PsiTraining_FOXCOMTrainingComplete';
		}
		class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIAlert_PsiTraining_FOXCOM', AlertName, TrainingCompleteCB, true, true, true, false);
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'EventToTrigger', '');
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'SoundToPlay', "Geoscape_CrewMemberLevelledUp");
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
		class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'AbilityTemplate', AbilityName);
		`HQPRES.QueueDynamicPopup(PropertySet);
	}
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

				if (UnitState != none)
				{
					class'X2StrategyGameRulesetDataStructures'.static.ShowClassMovie('PsiOperative', UnitState.GetReference());
				}
			}
		}
	}
}

private function int InjectPsiPerks(out XComGameState_Unit UnitState, out XComGameState NewGameState)
{
	local SoldierRankAbilities		InsertAbilities;
	local AbilitySelector			Selector;
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

	Selector = new class'AbilitySelector';
	Selector.BuildPsiAbilities(InsertAbilities, UnitState.GetSoldierClassTemplate().GetMaxConfiguredRank());

	for (iRank = 0; iRank < InsertAbilities.Abilities.Length; iRank++)
	{
		UnitState.AbilityTree[iRank].Abilities[iFinalRow] = InsertAbilities.Abilities[iRank];
	}

	// Instantly learn squaddie ability
	UnitState.BuySoldierProgressionAbility(NewGameState, 0, iFinalRow);

	return iFinalRow;
}

private function bool RollUnitHasGift(const XComGameState_Unit UnitState)
{
	local CharacterPoolManager	CharPool;
	local XComGameState_Unit	CPUnitState;

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
