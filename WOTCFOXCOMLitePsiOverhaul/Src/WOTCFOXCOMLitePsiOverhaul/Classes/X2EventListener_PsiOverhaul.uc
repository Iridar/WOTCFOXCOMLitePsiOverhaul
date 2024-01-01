class X2EventListener_PsiOverhaul extends X2EventListener config(PsiOverhaul);

var config string PsionicTreeName;

var private config int ListenerPriority;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Create_ListenerTemplate());

	return Templates;
}

static function CHEventListenerTemplate Create_ListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'IRI_X2EventListener_PsiOverhaul_FOXCOM');

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;

	Template.AddCHEvent('OverrideLocalizedAbilityTreeTitle', OnOverrideLocalizedAbilityTreeTitle, ELD_Immediate, default.ListenerPriority);

	Template.AddCHEvent('CPS_OverrideCanPurchaseAbilityProperties', OnOverrideCanPurchaseAbilityProperties, ELD_Immediate, default.ListenerPriority);
	Template.AddCHEvent('CPS_OverrideGetAbilityPointCostProperties', OnOverrideCanPurchaseAbilityProperties, ELD_Immediate, default.ListenerPriority);

	Template.AddCHEvent('CPS_OverrideAbilityPointCost', OnOverrideAbilityPointCost, ELD_Immediate, default.ListenerPriority);
	Template.AddCHEvent('CPS_AbilityPurchased', OnAbilityPurchased, ELD_Immediate, default.ListenerPriority);
	Template.AddCHEvent('CPS_OverrideAbilityDescription', OnOverrideAbilityDescription, ELD_Immediate, default.ListenerPriority);

	Template.AddCHEvent('UpdateResources', OnUpdateResources, ELD_Immediate, default.ListenerPriority);
	
	return Template;
}


static private function EventListenerReturn OnUpdateResources(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local X2ItemTemplate	ItemTemplate;
	local UIAvengerHUD		HUD;

	if (UIFacility_PsiLab(`SCREENSTACK.GetCurrentScreen()) == none)
		return ELR_NoInterrupt;

	ItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate('IRI_AuroraShard');
	if (ItemTemplate == none)
		return ELR_NoInterrupt;

	HUD = `HQPRES.m_kAvengerHUD;
	HUD.AddResource(`CAPS(ItemTemplate.FriendlyNamePlural), string(`XCOMHQ.GetResourceAmount('IRI_AuroraShard')));
	HUD.ShowResources();

	return ELR_NoInterrupt;
}

static private function EventListenerReturn OnOverrideAbilityDescription(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple			Tuple;
	local XComGameState_Unit	UnitState;
	local int					Index;
	local name					AbilityName;
	local int					StatIncrease;
	local string				StatString;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		return ELR_NoInterrupt;

	Index = class'Help'.static.GetPsiOperativeRow(UnitState);
	if (Index == INDEX_NONE)
		return ELR_NoInterrupt;

	Tuple = XComLWTuple(EventData);
	if (Tuple == none)
		return ELR_NoInterrupt;

	if (Tuple.Data[2].i != Index)
		return ELR_NoInterrupt;

	// Squaddie abilities don't provide Psi Offense
	//if (Tuple.Data[1].i == 0)
	//	return ELR_NoInterrupt;
	
	AbilityName = Tuple.Data[0].n;
	StatIncrease = class'AbilitySelector'.static.GetAbilityStatIncrease(AbilityName);
	if (StatIncrease == 0)
		return ELR_NoInterrupt;

	StatString @= class'X2TacticalGameRulesetDataStructures'.default.m_aCharStatLabels[eStat_PsiOffense];
	StatString $= ": ";
	if (StatIncrease > 0)
	{
		StatString $= "+";
	}
	StatString $= string(StatIncrease);
	StatString = class'UIUtilities_Text'.static.GetColoredText(StatString, eUIState_Warning);

	Tuple.Data[12].s $= StatString;
	
	return ELR_NoInterrupt;
}

static private function EventListenerReturn OnAbilityPurchased(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple			Tuple;
	local XComGameState_Unit	UnitState;
	local int					Index;
	local name					AbilityName;
	local int					StatIncrease;
	local int					CurrentPsiOffense;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		return ELR_NoInterrupt;

	Index = class'Help'.static.GetPsiOperativeRow(UnitState);
	if (Index == INDEX_NONE)
		return ELR_NoInterrupt;

	Tuple = XComLWTuple(EventData);
	if (Tuple == none)
		return ELR_NoInterrupt;

	if (Tuple.Data[1].i == Index)
	{
		UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(UnitState.ObjectID));
		if (UnitState == none)
			return ELR_NoInterrupt;

		AbilityName = UnitState.GetAbilityName(Tuple.Data[0].i, Tuple.Data[1].i);
		StatIncrease = class'AbilitySelector'.static.GetAbilityStatIncrease(AbilityName);
		`AMLOG(UnitState.GetFullName() @ "unlocked psi ability:" @ AbilityName @ "increasing Psi Offense by:" @ StatIncrease);
		if (StatIncrease == 0)
			return ELR_NoInterrupt;

		CurrentPsiOffense = UnitState.GetMaxStat(eStat_PsiOffense);
		UnitState.SetBaseMaxStat(eStat_PsiOffense, CurrentPsiOffense + StatIncrease);
	}
	return ELR_NoInterrupt;
}

static private function EventListenerReturn OnOverrideLocalizedAbilityTreeTitle(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple			Tuple;
	local XComGameState_Unit	UnitState;
	local int					Index;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		return ELR_NoInterrupt;

	Index = class'Help'.static.GetPsiOperativeRow(UnitState);
	if (Index == INDEX_NONE)
		return ELR_NoInterrupt;

	Tuple = XComLWTuple(EventData);
	if (Tuple == none)
		return ELR_NoInterrupt;

	if (Tuple.Data[0].i == Index)
	{
		Tuple.Data[1].s = default.PsionicTreeName;
	}
	return ELR_NoInterrupt;
}

static private function EventListenerReturn OnOverrideCanPurchaseAbilityProperties(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple			Tuple;
	local XComGameState_Unit	UnitState;
	local int					Index;
	local name					AbilityName;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		return ELR_NoInterrupt;

	Index = class'Help'.static.GetPsiOperativeRow(UnitState);
	if (Index == INDEX_NONE)
		return ELR_NoInterrupt;

	Tuple = XComLWTuple(EventData);
	if (Tuple == none)
		return ELR_NoInterrupt;

	if (Tuple.Data[2].i == Index)
	{
		Tuple.Data[5].b = true; // bClassAbility - counts as a normal soldier class ability, e.g. can be unlocked for free with promotion
		Tuple.Data[9].b = true; // bUnitCanSpendAP - e.g. Training Center isn't required to unlock this ability with AP.
	}
	else
	{
		AbilityName = UnitState.GetAbilityName(Tuple.Data[1].i, Index); // Rank
		if (UnitState.HasSoldierAbility(AbilityName))
		{
			Tuple.Data[7].b = true; // bUnitHasPurchasedClassPerkAtRank
		}
	}
	return ELR_NoInterrupt;
}

static private function EventListenerReturn OnOverrideAbilityPointCost(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComLWTuple			Tuple;
	local XComGameState_Unit	UnitState;
	local int					Index;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState == none)
		return ELR_NoInterrupt;

	Index = class'Help'.static.GetPsiOperativeRow(UnitState);
	if (Index == INDEX_NONE)
		return ELR_NoInterrupt;

	Tuple = XComLWTuple(EventData);
	if (Tuple == none)
		return ELR_NoInterrupt;

	if (Tuple.Data[2].i == Index)
	{
		if (Tuple.Data[7].b) // bUnitHasPurchasedClassPerkAtRank
		{
			Tuple.Data[12].i = class'AbilitySelector'.static.GetAbilityUnlockCost(Tuple.Data[0].n);
		}
		// else it will be zero.
	}
	return ELR_NoInterrupt;
}

