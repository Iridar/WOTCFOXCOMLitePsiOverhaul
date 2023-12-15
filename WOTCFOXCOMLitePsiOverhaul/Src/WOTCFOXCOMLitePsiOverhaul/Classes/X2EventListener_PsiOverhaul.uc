class X2EventListener_PsiOverhaul extends X2EventListener config(PsiOverhaul);

var config string PsionicTreeName;

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

	Template.AddCHEvent('OverrideLocalizedAbilityTreeTitle', OnOverrideLocalizedAbilityTreeTitle, ELD_Immediate, 50);

	Template.AddCHEvent('CPS_OverrideCanPurchaseAbilityProperties', OnOverrideCanPurchaseAbilityProperties, ELD_Immediate, 50);
	Template.AddCHEvent('CPS_OverrideGetAbilityPointCostProperties', OnOverrideCanPurchaseAbilityProperties, ELD_Immediate, 50);

	Template.AddCHEvent('CPS_OverrideAbilityPointCost', OnOverrideAbilityPointCost, ELD_Immediate, 50);
	
	return Template;
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
