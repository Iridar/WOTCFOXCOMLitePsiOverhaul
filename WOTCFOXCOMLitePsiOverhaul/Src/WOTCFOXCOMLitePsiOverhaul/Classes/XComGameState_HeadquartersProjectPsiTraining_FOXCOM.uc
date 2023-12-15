class XComGameState_HeadquartersProjectPsiTraining_FOXCOM extends XComGameState_HeadquartersProjectPsiTraining config(PsiOverhaul);

var private config int	InitialPsiOffenseBonus;
var private config bool	bSkipAppearanceChanges;
var private config int	iHairColor;
var private config int	iEyeColor;

function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_GameTime TimeState;

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

	XComHQ = `XCOMHQ;

	return XComHQ.GetPsiTrainingDays() * XComHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour * 24 / 10; // TODO: DEBUG ONLY
}

function OnProjectCompleted()
{
	local HeadquartersOrderInputContext		OrderInput;
	local XComGameState_Unit				UnitState;
	local X2AbilityTemplate					AbilityTemplate;
	local name								AbilityName;
	local XComGameState						NewGameState;
	local int								CurrentPsiOffense;

	OrderInput.OrderType = eHeadquartersOrderType_PsiTrainingCompleted;
	OrderInput.AcquireObjectReference = self.GetReference();

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectFocus.ObjectID));
	if (UnitState == none)
		return;
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Complete psionic Training");
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));

	// TODO: Roll for Gift here

	CurrentPsiOffense = UnitState.GetMaxStat(eStat_PsiOffense);
	UnitState.SetBaseMaxStat(eStat_PsiOffense, CurrentPsiOffense + InitialPsiOffenseBonus);

	if (!bSkipAppearanceChanges)
	{
		UnitState.kAppearance.iHairColor = default.iHairColor;
		UnitState.kAppearance.iEyeColor = default.iEyeColor;
	}
	
	InjectPsiPerks(UnitState, NewGameState);	
	`GAMERULES.SubmitGameState(NewGameState);

	AbilityName = UnitState.GetAbilityName(0 /*iAbilityRank*/, 1 /*iAbilityBranch*/); 
	AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);

	`HQPRES.UIPsiTrainingComplete(ProjectFocus, AbilityTemplate);
	
	// Start Issue #534
	TriggerPsiProjectCompleted(UnitState, AbilityName);
	// End Issue #534
}


private function InjectPsiPerks(out XComGameState_Unit UnitState, out XComGameState NewGameState)
{
	local SoldierRankAbilities		InsertAbilities;
	local AbilitySelector			Selector;
	local int iFinalRow;
	local int i;	

	if (UnitState.GetSoldierClassTemplate() == none)
		return;

	// Calculate the index of the last ability row for this soldier.
	// Cycle through the entire ability tree so that if there's even one perk on the final row, all psionic rows will go below it.
	for (i = 0; i < UnitState.AbilityTree.Length; i++)
	{
		iFinalRow = Max(iFinalRow, UnitState.AbilityTree[i].Abilities.Length);
	}

	Selector = new class'AbilitySelector';
	Selector.BuildPsiAbilities(InsertAbilities, UnitState.GetSoldierClassTemplate().GetMaxConfiguredRank());

	UnitState.AbilityTree[i] = InsertAbilities;

	// Instantly learn squaddie ability
	UnitState.BuySoldierProgressionAbility(NewGameState, 0, iFinalRow);

	// Mark soldier so they can't undergo psionic training again. Unit value will store the index of the row where psionic abilities start.
	// For a soldier class that normally has 3 perk rows + XCOM row, the Unit Value is recorded as "4". So perks go:
	// 0: Class
	// 1: Class
	// 2: Class
	// 3: XCOM
	// 4: psionic 1 - iFinalRow
	// 5: psionic 2
	UnitState.SetUnitFloatValue('IRI_IsPsiOperative', iFinalRow, eCleanup_Never);
}


