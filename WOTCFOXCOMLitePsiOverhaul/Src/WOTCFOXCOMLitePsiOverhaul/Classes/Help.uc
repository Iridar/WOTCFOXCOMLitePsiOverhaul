//  FILE:    Help.uc
//  AUTHOR:  Iridar  --  20/04/2022
//  PURPOSE: Helper class for static functions and script snippet repository.     
//---------------------------------------------------------------------------------------

class Help extends Object abstract;

var private name PsiOperativeValue;

static final function bool IsPsiOperative(const XComGameState_Unit UnitState)
{
	local UnitValue UV;

	return UnitState.GetUnitValue(default.PsiOperativeValue, UV);
}

static final function MarkPsiOperative(out XComGameState_Unit UnitState, const int iFinalRow)
{
	UnitState.SetUnitFloatValue(default.PsiOperativeValue, iFinalRow, eCleanup_Never);
}

defaultproperties
{
	PsiOperativeValue = "IRI_IsPsiOperative"
}

