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
var private bool		bSecondaryPsiAmp;	// In case the soldier class under the Psionic Evaluation already uses Psi Amp as their secondary weapon.
											// Then the Psi Abilities will be assigned to eInvSlot_SecondaryWeapon instead of eInvSlot_PsiAmp.

var private int NumAbilitiesToSelect;
var private int OverflowCounter;

`include(WOTCFOXCOMLitePsiOverhaul\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

// Main function to interface with the class.

final function BuildPsiAbilities(out SoldierRankAbilities InsertAbilities, const int NumSlots)
{
	local SoldierClassAbilityType_FMPO	AbilitySlot;
	local float							AverageTier;

	NumAbilitiesToSelect = NumSlots;
	bSecondaryPsiAmp = class'Help'.static.PsiAmpIsOnlySecondaryForSoldierClass(UnitState);

	GetAbilityTemplates();
	
	`AMLOG("Going to select:" @ NumSlots @ "abilities out of:" @ AbilitySlots.Length);
	PrintAbilitySlots();

	ShuffleAbilitySlots();
	RemoveMutuallyExclusiveAbilities();

	RemoveAbilitiesPresentInSoldierAbilityTree();

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

	PrintAbilitySlots("Before sorting by Tier");

	AbilitySlots.Sort(SortByTier);

	PrintAbilitySlots("Before ordering");

	OrderAbilitySlots();

	PrintAbilitySlots("After ordering");

	foreach AbilitySlots(AbilitySlot)
	{
		InsertAbilities.Abilities.AddItem(AddAbility(AbilitySlot));
	}
}

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
	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

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



private function OrderAbilitySlots()
{
	local SoldierClassAbilityType_FMPO			AbilitySlot;
	local array<SoldierClassAbilityType_FMPO>	SortedAbilitySlots;
	local array<SoldierClassAbilityType_FMPO>	AbilitiesWithReqs;
	local name									RequiredAbility;
	local int MaxIndex;
	local int Index;

	foreach AbilitySlots(AbilitySlot)
	{
		if (DoesAbilityRequireAnotherAbility(AbilitySlot))
		{
			AbilitiesWithReqs.AddItem(AbilitySlot);
		}
		else
		{
			SortedAbilitySlots.AddItem(AbilitySlot);
		}
	}

	if (`GETMCMVAR(RANDOMIZE_FREE_ABILITY))
	{
		Index = `SYNC_RAND(SortedAbilitySlots.Length);
		AbilitySlot = SortedAbilitySlots[Index];

		SortedAbilitySlots.RemoveItem(AbilitySlot);
		SortedAbilitySlots.InsertItem(0, AbilitySlot);
	}

	foreach AbilitiesWithReqs(AbilitySlot)
	{
		MaxIndex = 0;
		foreach AbilitySlot.Template.PrerequisiteAbilities(RequiredAbility)
		{
			if (Left(string(RequiredAbility), 4) == "NOT_")
				continue;

			for (Index = 0; Index < SortedAbilitySlots.Length; Index++)
			{
				if (SortedAbilitySlots[Index].AbilityName == RequiredAbility && MaxIndex < Index)
				{
					MaxIndex = Index;
					break;
				}
			}
			SortedAbilitySlots.InsertItem(MaxIndex + 1, AbilitySlot);
		}
	}

	AbilitySlots = SortedAbilitySlots;
}

private function PrintAbilitySlots(optional string StepMessage)
{
	local SoldierClassAbilityType_FMPO AbilitySlot;

	`AMLOG("===== BEGIN PRINT ======" @ StepMessage);
	foreach AbilitySlots(AbilitySlot)
	{
		`AMLOG(AbilitySlot.AbilityName @ AbilitySlot.Tier);
	}
	`AMLOG("===== END PRINT ======");
}

private function ShuffleAbilitySlots()
{	
	local SoldierClassAbilityType_FMPO			AbilitySlot;
	local array<SoldierClassAbilityType_FMPO>	ShuffledAbilitySlots;
	local int									Index;

	AbilitySlots.RandomizeOrder();

	// Reshuffle manually just in case

	while (AbilitySlots.Length > 0)
	{
		Index = `SYNC_RAND(AbilitySlots.Length);
		AbilitySlot = AbilitySlots[Index];

		AbilitySlots.RemoveItem(AbilitySlot);
		ShuffledAbilitySlots.AddItem(AbilitySlot);
	}

	AbilitySlots = ShuffledAbilitySlots;
}

private function RemoveAbilitiesPresentInSoldierAbilityTree()
{
	local int i;

	for (i = 0; i < AbilitySlots.Length; i++)
	{
		if (IsAbilityPresentInSoldierAbilityTree(AbilitySlots[i].AbilityName))
		{
			`AMLOG(AbilitySlots[i].AbilityName @ "- removing ability, because it's already present in soldier's ability tree");
			AbilitySlots.Remove(i, 1);
		}
	}
}

private function bool IsAbilityPresentInSoldierAbilityTree(const name AbilityName)
{
	local SoldierRankAbilities RankAbilities;
	local SoldierClassAbilityType AbilityType;

	foreach UnitState.AbilityTree(RankAbilities)
	{
		foreach RankAbilities.Abilities(AbilityType)
		{
			if (AbilityType.AbilityName == AbilityName)
			{
				return true;
			}
		}
	}
	return false;
}

private function RemoveMutuallyExclusiveAbilities()
{
	local name RequiredAbility;
	local name MutuallyExclusiveAbilityName;
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
				if (AbilitySlots[j].AbilityName == MutuallyExclusiveAbilityName)
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

	// RemoveAbility() will remove the ability and any abilities that require this ability. Usually that would be two abilities.
	// So when we need to remove only one ability, don't remove the randomly selected ability if happens to be required by
	// another ability.
	if (NumAbilitiesToSelect - AbilitySlots.Length == 1 && IsAbilityRequiredByAnotherAbility(AbilitySlot.AbilityName) && OverflowCounter < 100)
	{
		`AMLOG("Selected random ability:" @ AbilitySlot.AbilityName @ "but it's required by another ability, not removing it at this time:" @ OverflowCounter);
		
		// Use Overflow Counter to guard against an unlikely sitation if all perks in the selection are required by some other perk.
		// If that were to happen, the main while() loop would get stuck in an endless cycle and crash the game.
		OverflowCounter++;
		return;
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

	if (NumAbilitiesToSelect - AbilitySlots.Length == 1 && IsAbilityRequiredByAnotherAbility(AbilitySlot.AbilityName) && OverflowCounter < 100)
	{
		`AMLOG("Selected random ability:" @ AbilitySlot.AbilityName @ "but it's required by another ability, not removing it at this time:" @ OverflowCounter);
		OverflowCounter++;
		return;
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

private function bool DoesAbilityRequireAnotherAbility(const out SoldierClassAbilityType_FMPO AbilitySlot)
{
	local name RequiredAbility;

	foreach AbilitySlot.Template.PrerequisiteAbilities(RequiredAbility)
	{
		if (Left(string(RequiredAbility), 4) != "NOT_")
		{
			return true;
		}
	}
	return false;
}
private function bool IsAbilityRequiredByAnotherAbility(const name AbilityName)
{
	local SoldierClassAbilityType_FMPO AbilitySlot;
	local name RequiredAbility;

	foreach AbilitySlots(AbilitySlot)
	{
		foreach AbilitySlot.Template.PrerequisiteAbilities(RequiredAbility)
		{
			if (RequiredAbility == AbilityName)
			{
				return true;
			}
		}
	}
	return false;
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

	RemoveDuplicateAbilities();
}

static private function RemoveDuplicateAbilities()
{
	local int i;
	local int j;

	for (i = 0; i < default.AbilitySlots.Length; i++)
	{
		for (j = default.AbilitySlots.Length - 1; j >= 0; j--)
		{
			if (default.AbilitySlots[i].AbilityName == default.AbilitySlots[j].AbilityName && i != j)
			{
				default.AbilitySlots.Remove(j, 1);
				break;
			}
		}
	}
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
