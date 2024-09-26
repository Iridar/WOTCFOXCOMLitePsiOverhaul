class UIFacility_PsiLabSlot_Evaluation extends UIFacility_PsiLabSlot;

// Don't need to make any changes, just need this class for localization.

// TODO: Disable Confirm Dialogue for Psi Evaluation MCM options

simulated function PsiPromoteDialog(XComGameState_Unit Unit)
{
	local XGParamTag LocTag;
	local TDialogueBoxData DialogData;
	local XComGameState_HeadquartersXCom XComHQ;
	local int TrainingRateModifier;
	local UICallbackData_StateObjectReference CallbackData;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	TrainingRateModifier = XComHQ.PsiTrainingRate / XComHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour;

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = Unit.GetName(eNameType_RankFull);
	LocTag.IntValue0 = (`ScaleStrategyArrayInt(class'XComGameState_HeadquartersProjectPsiTraining_FOXCOM'.default.PsiEvaluationDays) / TrainingRateModifier);

	//`AMLOG("Displaying Psi Evaluation days:" @ LocTag.IntValue0 @ `ScaleStrategyArrayInt(class'XComGameState_HeadquartersProjectPsiTraining_FOXCOM'.default.PsiEvaluationDays) @ TrainingRateModifier);

	CallbackData = new class'UICallbackData_StateObjectReference';
	CallbackData.ObjectRef = Unit.GetReference();
	DialogData.xUserData = CallbackData;
	DialogData.fnCallbackEx = PsiPromoteDialogCallback;

	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = m_strPsiTrainingDialogTitle;
	DialogData.strText = `XEXPAND.ExpandString(m_strPsiTrainingDialogText);
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(DialogData);
}
