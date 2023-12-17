class XComGameState_HeadquartersProjectPsiTraining_FOXCOM extends XComGameState_HeadquartersProjectPsiTraining config(PsiOverhaul);

var private config int	InitialPsiOffenseBonus;
var bool bPsiOperativeTraining;

`include(WOTCFOXCOMLitePsiOverhaul\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

var config array<name> GiftedCharacters;
var config array<name> GiftedClasses;
var config bool ClassUsesShardGauntletsGifted;
var config bool ClassUsesPsiAmpGifted;

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

	return XComHQ.GetPsiTrainingDays() * XComHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour * 24;
}

function OnProjectCompleted()
{
	local XComGameState_Unit				UnitState;
	//local X2AbilityTemplate					AbilityTemplate;
	local name								AbilityName;
	local XComGameState						NewGameState;
	local int								CurrentPsiOffense;
	local int								iFinalRow;
	local bool								bHasGift;
	local bool								bAuroraShard;
	local XComGameState_HeadquartersXCom	XComHQ;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectFocus.ObjectID));
	if (UnitState == none)
		return;

	if (class'Help'.static.IsGiftless(UnitState))
	{	
		bAuroraShard = true;
		bHasGift = true;
	}
	else
	{
		bHasGift = RollUnitHasGift(UnitState);
	}

	if (bPsiOperativeTraining)
	{
		if (bHasGift)
		{
			super.OnProjectCompleted();

			if (bAuroraShard)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Complete psionic Training");
				XComHQ = class'Help'.static.GetAndPrepXComHQ(NewGameState);
				XComHQ.AddResource(NewGameState, 'IRI_AuroraShard', -1);

				UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
				class'Help'.static.UnmarkGiftless(UnitState);

				`GAMERULES.SubmitGameState(NewGameState);

				ShowShardConsumedPopup();
			}
		}
		else
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Complete psionic Training");
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
			class'Help'.static.MarkGiftless(UnitState);

			CompletePsiTraining(NewGameState, GetReference(), UnitState);

			`GAMERULES.SubmitGameState(NewGameState);

			ShowTrainingCompletedPopUp(ProjectFocus, '', true);

			// Start Issue #534
			TriggerPsiProjectCompleted(UnitState, '');
			// End Issue #534
		}
		return;
	}

	// ----------------------------------------------------------------

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Complete psionic Training");
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));

	CompletePsiTraining(NewGameState, GetReference(), UnitState);

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

		if (bAuroraShard)
		{
			XComHQ = class'Help'.static.GetAndPrepXComHQ(NewGameState);
			XComHQ.AddResource(NewGameState, 'IRI_AuroraShard', -1);

			class'Help'.static.UnmarkGiftless(UnitState);
		}
	}
	else
	{
		class'Help'.static.MarkGiftless(UnitState);
	}

	`GAMERULES.SubmitGameState(NewGameState);

	if (bHasGift)
	{
		if (IsUnitAlwaysGifted(UnitState))
		{
			// Show popup here without an ability
			ShowTrainingCompletedPopUp(ProjectFocus);
		}
		else
		{
			AbilityName = UnitState.GetAbilityName(0, iFinalRow); 
			ShowTrainingCompletedPopUp(ProjectFocus, AbilityName);
		}
	}
	else
	{
		ShowTrainingCompletedPopUp(ProjectFocus,, true);
	}

	if (bAuroraShard)
	{
		ShowShardConsumedPopup();
	}

	// Start Issue #534
	TriggerPsiProjectCompleted(UnitState, AbilityName);
	// End Issue #534
}

private function ShowShardConsumedPopup()
{
	local DynamicPropertySet PropertySet;

	class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIAlert_PsiTraining_FOXCOM', 'eAlert_PsiTraining_ShardConsumed', none, true, true, true, false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'EventToTrigger', '');
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'SoundToPlay', "Geoscape_CrewMemberLevelledUp");
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', 0);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'AbilityTemplate', '');
	`HQPRES.QueueDynamicPopup(PropertySet);
}

static private function CompletePsiTraining(XComGameState AddToGameState, StateObjectReference ProjectRef, XComGameState_Unit UnitState)
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

		// Rank up the solder. Will also apply class if they were a Rookie.
		//UnitState.RankUpSoldier(AddToGameState, 'PsiOperative');
		//
		//// Teach the soldier the ability which was associated with the project
		//UnitState.BuySoldierProgressionAbility(AddToGameState, ProjectState.iAbilityRank, ProjectState.iAbilityBranch);

		//if (UnitState.GetRank() == 1) // They were just promoted to Initiate
		//{
		//	UnitState.ApplyBestGearLoadout(AddToGameState); // Make sure the squaddie has the best gear available
		//}

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

private function ShowTrainingCompletedPopUp(StateObjectReference UnitRef, optional name AbilityName = '', optional bool bGiftless = false)
{
	local DynamicPropertySet PropertySet;
	local name AlertName;

	if (bGiftless)
	{
		AlertName = 'eAlert_PsiTraining_FOXCOMTrainingFailed';
	}
	else if (AbilityName != '')
	{
		AlertName = 'eAlert_PsiTraining_FOXCOMTrainingCompleteNoAbility';
	}
	else
	{
		AlertName = 'eAlert_PsiTraining_FOXCOMTrainingComplete';
	}
	if (bGiftless)
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

				class'X2StrategyGameRulesetDataStructures'.static.ShowClassMovie('PsiOperative', UnitState.GetReference());
				
				`HQPRES.ShowPromotionUI(UnitState.GetReference());
			}
		}
	}
}

private function int InjectPsiPerks(out XComGameState_Unit UnitState, out XComGameState NewGameState)
{
	local bool						bAlwaysGifted;
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
	StartingRank = 0;

	if (IsUnitAlwaysGifted(UnitState))
	{
		bAlwaysGifted = true;
		iNumPerks--; // For balancing reasons, always gifted units, like Templars, don't get a free perk.
		StartingRank = 1;
	}

	Selector = new class'AbilitySelector';
	Selector.UnitState = UnitState;
	Selector.BuildPsiAbilities(InsertAbilities, iNumPerks);

	for (iRank = StartingRank; iRank < InsertAbilities.Abilities.Length; iRank++)
	{
		UnitState.AbilityTree[iRank].Abilities[iFinalRow] = InsertAbilities.Abilities[iRank];
	}

	// Instantly learn squaddie ability
	if (!bAlwaysGifted)
	{
		UnitState.BuySoldierProgressionAbility(NewGameState, 0, iFinalRow);
	}

	return iFinalRow;
}

private function bool RollUnitHasGift(const XComGameState_Unit UnitState)
{
	local CharacterPoolManager		CharPool;
	local XComGameState_Unit		CPUnitState;
	
	if (IsUnitAlwaysGifted(UnitState))
		return true;

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

private function bool IsUnitAlwaysGifted(const XComGameState_Unit UnitState)
{
	local X2SoldierClassTemplate	ClassTemplate;
	local SoldierClassWeaponType	AllowedWeapon;

	if (GiftedCharacters.Find(UnitState.GetMyTemplateName()) != INDEX_NONE)
		return true;

	ClassTemplate = UnitState.GetSoldierClassTemplate();
	if (ClassTemplate != none)
	{
		if (GiftedClasses.Find(ClassTemplate.DataName) != INDEX_NONE)
			return true;

		foreach ClassTemplate.AllowedWeapons(AllowedWeapon)
		{
			if (AllowedWeapon.WeaponType == 'psiamp' && ClassUsesPsiAmpGifted)
			{
				return true;
			}
			if (AllowedWeapon.WeaponType == 'gauntlet' && ClassUsesShardGauntletsGifted)
			{
				return true;
			}
		}
	}
}