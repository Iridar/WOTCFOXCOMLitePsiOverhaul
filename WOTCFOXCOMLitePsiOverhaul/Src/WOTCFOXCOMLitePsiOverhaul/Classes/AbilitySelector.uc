class AbilitySelector extends Object config(PsiOverhaul);

struct SoldierClassAbilityType_FMPO
{
	var name			AbilityName;
	var EInventorySlot	ApplyToWeaponSlot;
	var name			UtilityCat;
	var name			RandomDeckName;
	var int				PsiBonus;	// Amount of Psi Offense granted upon unlocking this ability.
	var float			Tier;		// Subjective power rating of a particular ability. More powerful abilities are put later into the tree.
	var int				AP;			// Ability Point cost

	var X2AbilityTemplate Template;

	structdefaultproperties
	{
		ApplyToWeaponSlot = eInvSlot_PsiAmp
	}
};

var private config array<SoldierClassAbilityType_FMPO>	AbilitySlots;
var private config float								fAverageTierPerRank;
var private X2AbilityTemplateManager					AbilityMgr;

var XComGameState_Unit	UnitState;
var private bool		bSecondaryPsiAmp;

`include(WOTCFOXCOMLitePsiOverhaul\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

private function SoldierClassAbilityType AddAbility(const out SoldierClassAbilityType_FMPO AbilitySlot)
{	
	local SoldierClassAbilityType ReturnAbility;

	ReturnAbility.AbilityName = AbilitySlot.AbilityName;
	if (bSecondaryPsiAmp)
	{
		ReturnAbility.ApplyToWeaponSlot = eInvSlot_SecondaryWeapon;
	}
	else
	{
		ReturnAbility.ApplyToWeaponSlot = AbilitySlot.ApplyToWeaponSlot;
	}
	ReturnAbility.UtilityCat = AbilitySlot.UtilityCat;

	return ReturnAbility;
}

private function GetAbilityTemplates()
{
	local XComGameState_HeadquartersXCom	XComHQ;
	local X2AbilityTemplate					AbilityTemplate;
	local int i;

	XComHQ = `XCOMHQ;

	for (i = AbilitySlots.Length - 1; i >= 0; i--)
	{
		AbilityTemplate = AbilityMgr.FindAbilityTemplate(AbilitySlots[i].AbilityName);
		if (AbilityTemplate == none || !XComHQ.MeetsAllStrategyRequirements(AbilityTemplate.Requirements))
		{
			AbilitySlots.Remove(i, 1);
		}
		else
		{
			AbilitySlots[i].Template = AbilityTemplate;
		}
	}
}

final function BuildPsiAbilities(out SoldierRankAbilities InsertAbilities, const int NumSlots)
{
	local SoldierClassAbilityType_FMPO	AbilitySlot;
	local float							AverageTier;
	local SoldierClassAbilityType		InsertAbility;
	local int							Index;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	GetAbilityTemplates();

	bSecondaryPsiAmp = class'Help'.static.PsiAmpIsOnlySecondaryForSoldierClass(UnitState);

	`AMLOG("Going to select:" @ NumSlots @ "abilities out of:" @ AbilitySlots.Length);
	PrintAbilitySlots();

	ShuffleAbilitySlots();
	RemoveMutuallyExclusiveAbilities();

	// TODO: Remove abilities already present in soldier's ability tree

	if (AbilitySlots.Length > NumSlots)
	{
		while (AbilitySlots.Length > NumSlots)
		{
			AverageTier = CalculateAverageTier();

			`AMLOG("Abilities remain:" @ AbilitySlots.Length @ "Average Tier:" @ AverageTier);

			if (AverageTier >= fAverageTierPerRank)
			{
				RemoveRandomHighTierAbility();
			}
			else
			{
				RemoveRandomLowTierAbility();
			}
		}
	}

	AbilitySlots.Sort(SortByTier);
	PrintAbilitySlots();

	// TODO: Put abilities that require other abilities next to each other?

	foreach AbilitySlots(AbilitySlot)
	{
		InsertAbilities.Abilities.AddItem(AddAbility(AbilitySlot));
	}

	if (`GETMCMVAR(RANDOMIZE_FREE_ABILITY))
	{
		Index = `SYNC_RAND(InsertAbilities.Abilities.Length);
		InsertAbility = InsertAbilities.Abilities[Index];
		InsertAbilities.Abilities.RemoveItem(InsertAbility);
		InsertAbilities.Abilities.InsertItem(0, InsertAbility);

		// TODO: Don't select perks that require other perks

		`AMLOG("Selecting random free ability:" @ InsertAbility.AbilityName);
	}
}

private function PrintAbilitySlots()
{
	local SoldierClassAbilityType_FMPO AbilitySlot;

	`AMLOG("===== BEGIN PRINT ======");
	foreach AbilitySlots(AbilitySlot)
	{
		`AMLOG(AbilitySlot.AbilityName @ AbilitySlot.Tier);
	}
	`AMLOG("===== END PRINT ======");
}

private function ShuffleAbilitySlots()
{
	// TODO: Reimplement in script just in case
	AbilitySlots.RandomizeOrder();
}

private function RemoveMutuallyExclusiveAbilities()
{
	local SoldierClassAbilityType_FMPO	AbilitySlot;
	local name							RequiredAbility;
	local name							MutuallyExclusiveAbilityName;
	local int i;
	local int j;

	for (i = 0; i < AbilitySlots.Length; i++)
	{
		foreach AbilitySlots[i].Template.PrerequisiteAbilities(RequiredAbility)
		{
			if (Left(string(RequiredAbility), 4) != "NOT_")
				continue;

			MutuallyExclusiveAbilityName = name(Right(string(RequiredAbility), Len(string(RequiredAbility)) - 4));

			for (j = AbilitySlots.Length - 1; j >= 0; j--)
			{
				if (AbilitySlot.AbilityName == MutuallyExclusiveAbilityName)
				{
					AbilitySlots.Remove(i, 1);
					break;
				}
			}
		}
	}
}

private function RemoveRandomHighTierAbility()
{
	local SoldierClassAbilityType_FMPO			AbilitySlot;
	local array<SoldierClassAbilityType_FMPO>	ValidAbilitySlots;
	local int									Index;

	foreach AbilitySlots(AbilitySlot)
	{
		if (AbilitySlot.Tier >= fAverageTierPerRank)
		{
			ValidAbilitySlots.AddItem(AbilitySlot);
		}
	}

	if (ValidAbilitySlots.Length > 0)
	{
		Index = `SYNC_RAND(ValidAbilitySlots.Length);
		AbilitySlot = ValidAbilitySlots[Index];
		`AMLOG("Removing valid high tier ability:" @ AbilitySlot.AbilityName @ AbilitySlot.Tier);
	}
	else
	{
		Index = `SYNC_RAND(AbilitySlots.Length);
		AbilitySlot = AbilitySlots[Index];
		`AMLOG("Removing random ability:" @ AbilitySlot.AbilityName @ AbilitySlot.Tier);
	}
	RemoveAbility(AbilitySlot);
}

private function RemoveRandomLowTierAbility()
{
	local SoldierClassAbilityType_FMPO			AbilitySlot;
	local array<SoldierClassAbilityType_FMPO>	ValidAbilitySlots;
	local int									Index;

	foreach AbilitySlots(AbilitySlot)
	{
		if (AbilitySlot.Tier <= fAverageTierPerRank)
		{
			ValidAbilitySlots.AddItem(AbilitySlot);
		}
	}

	if (ValidAbilitySlots.Length > 0)
	{
		Index = `SYNC_RAND(ValidAbilitySlots.Length);
		AbilitySlot = ValidAbilitySlots[Index];
		`AMLOG("Removing valid low tier ability:" @ AbilitySlot.AbilityName @ AbilitySlot.Tier);
	}
	else
	{
		Index = `SYNC_RAND(AbilitySlots.Length);
		AbilitySlot = AbilitySlots[Index];
		`AMLOG("Removing random ability:" @ AbilitySlot.AbilityName @ AbilitySlot.Tier);
	}
	RemoveAbility(AbilitySlot);
}

private function RemoveAbility(const out SoldierClassAbilityType_FMPO AbilitySlot)
{
	AbilitySlots.RemoveItem(AbilitySlot);

	RemoveAbilitiesWithMissingRequiredPerks();
}
private function RemoveAbilitiesWithMissingRequiredPerks()
{
	local SoldierClassAbilityType_FMPO AbilitySlot;
	local name RequiredAbility;
	local bool bRequiredAbilityPresent;
	local int i;

	for (i = AbilitySlots.Length - 1; i >= 0; i--)
	{
		foreach AbilitySlots[i].Template.PrerequisiteAbilities(RequiredAbility)
		{
			if (Left(string(RequiredAbility), 4) == "NOT_")
				continue;

			bRequiredAbilityPresent = false;
			foreach AbilitySlots(AbilitySlot)
			{
				if (AbilitySlot.AbilityName == RequiredAbility)
				{
					bRequiredAbilityPresent = true;
					break;
				}
			}
			if (!bRequiredAbilityPresent)
			{
				`AMLOG("Removing ability:" @ AbilitySlots[i].AbilityName @ "because it requires an ability that was removed:" @ RequiredAbility);
				AbilitySlots.Remove(i, 1);
				break;
			} 
		}
	}
}


private function float CalculateAverageTier()
{
	local SoldierClassAbilityType_FMPO	AbilitySlot;
	local float							AverageTier;

	foreach AbilitySlots(AbilitySlot)
	{
		AverageTier += AbilitySlot.Tier;
	}

	return AverageTier / AbilitySlots.Length;
}

private function int SortByTier(SoldierClassAbilityType_FMPO AbilityA, SoldierClassAbilityType_FMPO AbilityB)
{
	if (AbilityA.Tier > AbilityB.Tier)
	{
		return -1;
	}
	if (AbilityA.Tier < AbilityB.Tier)
	{
		return 1;
	}
	return 0;
}

static final function ValidatePsiAbilities()
{
	local X2AbilityTemplateManager LocAbilityMgr;
	local int i;

	LocAbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	for (i = default.AbilitySlots.Length - 1; i >= 0; i--)
	{
		if (LocAbilityMgr.FindAbilityTemplate(default.AbilitySlots[i].AbilityName) == none)
		{
			default.AbilitySlots.Remove(i, 1);
		}
	}

	// TODO: Remove duplicates
}

static final function int GetAbilityUnlockCost(const name AbilityName)
{
	local SoldierClassAbilityType_FMPO AbilitySlot;

	foreach default.AbilitySlots(AbilitySlot)
	{
		if (AbilitySlot.AbilityName == AbilityName)
		{
			return AbilitySlot.AP;
		}
	}
	return 10;
}

static final function int GetAbilityStatIncrease(const name AbilityName)
{
	local SoldierClassAbilityType_FMPO AbilitySlot;

	foreach default.AbilitySlots(AbilitySlot)
	{
		if (AbilitySlot.AbilityName == AbilityName)
		{
			return AbilitySlot.PsiBonus;
		}
	}
	return 0;
}