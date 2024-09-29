class UIFacility_PsiLabSlot_Evaluation extends UIFacility_PsiLabSlot;

`include(WOTCFOXCOMLitePsiOverhaul\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

simulated function OnPersonnelSelected(StaffUnitInfo UnitInfo)
{
	local UICallbackData_StateObjectReference CallbackData;
	local XComGameState_Unit Unit;
	
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	if (Unit == none)
		return;
	
	if (Unit.GetSoldierClassTemplateName() == 'PsiOperative')
	{
		`HQPRES.UIChoosePsiAbility(UnitInfo.UnitRef, StaffSlotRef);
	}
	else
	{
		if (`GETMCMVAR(DISABLE_CONFIRM_EVALUATION_POPUP))
		{
			CallbackData = new class'UICallbackData_StateObjectReference';
			CallbackData.ObjectRef = Unit.GetReference();
			PsiPromoteDialogCallback('eUIAction_Accept', CallbackData);
		}
		else
		{
			ConfirmPsiEvaluationDialog(Unit);
		}
	}
}

private function ConfirmPsiEvaluationDialog(XComGameState_Unit Unit)
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
