//  FILE:    Help.uc
//  AUTHOR:  Iridar  --  20/04/2022
//  PURPOSE: Helper class for static functions and script snippet repository.     
//---------------------------------------------------------------------------------------

class Help extends Object abstract;

var private name PsiOperativeValue;
var private name GiftlessValue;

static final function bool IsPsiOperative(const XComGameState_Unit UnitState)
{
	local UnitValue UV;

	return UnitState.GetUnitValue(default.PsiOperativeValue, UV);
}

static final function bool IsGiftless(const XComGameState_Unit UnitState)
{
	local UnitValue UV;

	return UnitState.GetUnitValue(default.GiftlessValue, UV);
}

static final function int GetPsiOperativeRow(const XComGameState_Unit UnitState)
{
	local UnitValue UV;

	if (UnitState.GetUnitValue(default.PsiOperativeValue, UV))
	{
		return UV.fValue;
	}

	return INDEX_NONE;
}

static final function MarkPsiOperative(out XComGameState_Unit UnitState, const int iFinalRow)
{
	UnitState.SetUnitFloatValue(default.PsiOperativeValue, iFinalRow, eCleanup_Never);
}
static final function MarkGiftless(out XComGameState_Unit UnitState)
{
	UnitState.SetUnitFloatValue(default.PsiOperativeValue, 1.0f, eCleanup_Never);
}

static final function bool PsiAmpIsOnlySecondaryForSoldierClass(XComGameState_Unit UnitState)
{
	local X2SoldierClassTemplate ClassTemplate;
	local SoldierClassWeaponType AllowedWeapon;
	local bool					 bPsiAmpSecondary;
	local bool					 bOtherSecondary;

	ClassTemplate = UnitState.GetSoldierClassTemplate();

	foreach ClassTemplate.AllowedWeapons(AllowedWeapon)
	{
		if (AllowedWeapon.SlotType == eInvSlot_SecondaryWeapon)
		{
			if (AllowedWeapon.WeaponType == 'psiamp')
			{
				bPsiAmpSecondary = true;
			}
			else
			{
				bOtherSecondary = true;
			}
		}
	}
		
	if (bPsiAmpSecondary && !bOtherSecondary)
	{
		return true;
	}
	return false;
}

defaultproperties
{
	PsiOperativeValue = "IRI_IsPsiOperative"
	GiftlessValue = "IRI_NoPsionicGift"
}

