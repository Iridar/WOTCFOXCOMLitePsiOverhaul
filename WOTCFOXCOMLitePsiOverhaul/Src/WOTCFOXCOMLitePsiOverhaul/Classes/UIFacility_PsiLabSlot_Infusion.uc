class UIFacility_PsiLabSlot_Infusion extends UIFacility_PsiLabSlot;

var private localized string m_strPsiTrainingDialogTextCannotAfford;
var private localized string m_strPsiTrainingDialogTextAlwaysGifted;

simulated function OnPersonnelSelected(StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit;
	
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	if (Unit == none)
		return;

	if (CanAffordInfusionCost())
	{
		RaiseConfirmInfusionDialog(Unit);		
	}
	else
	{
		RaiseConfirmInfusionDialog(Unit, true);
	}
}

private function RaiseConfirmInfusionDialog(XComGameState_Unit Unit, optional bool bCannotAfford)
{
	local XGParamTag LocTag;
	local TDialogueBoxData DialogData;
	local XComGameState_HeadquartersXCom XComHQ;
	local int TrainingRateModifier;
	local UICallbackData_StateObjectReference CallbackData;
	local string strText;
	local string strResourceCost;

	XComHQ = `XCOMHQ;
	TrainingRateModifier = XComHQ.PsiTrainingRate / XComHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour;

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = Unit.GetName(eNameType_RankFull);
	LocTag.IntValue0 = `ScaleStrategyArrayInt(class'XComGameState_HeadquartersProjectPsiTraining_FOXCOM'.default.PsiInfusionDays) / TrainingRateModifier;

	if (bCannotAfford)
	{
		strText = m_strPsiTrainingDialogTextCannotAfford;
		DialogData.eType = eDialog_Warning;
	}
	else
	{
		if (class'Help'.static.IsUnitAlwaysGifted(Unit))
		{
			strText = m_strPsiTrainingDialogTextAlwaysGifted;
		}
		else
		{
			strText = m_strPsiTrainingDialogText;
		}		
		DialogData.eType = eDialog_Normal;
	}

	strResourceCost = GetInfusionCostString();
	strText = Repl(strText, "%ResourceCost%", strResourceCost);

	CallbackData = new class'UICallbackData_StateObjectReference';
	CallbackData.ObjectRef = Unit.GetReference();
	DialogData.xUserData = CallbackData;
	
	DialogData.strTitle = m_strPsiTrainingDialogTitle;
	DialogData.strText = `XEXPAND.ExpandString(strText);

	if (bCannotAfford)
	{
		DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;

		//DialogData.fnCallbackEx = CannotAffordInfusionCostDialogCallback;
	}
	else
	{
		DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
		DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericCancel;

		DialogData.fnCallbackEx = ConfirmInfusionDialogCallback;
	}
	Movie.Pres.UIRaiseDialog(DialogData);
}

private function string GetInfusionCostString()
{
	local StrategyCost				InfusionCost;
	local array<StrategyCostScalar> CostScalars;

	InfusionCost = class'X2DLCInfo_WOTCFOXCOMLitePsiOverhaul'.static.GetInfusionCost();

	CostScalars.Length = 0; // Settle down, compiler

	return class'UIUtilities_Strategy'.static.GetStrategyCostString(InfusionCost, CostScalars);
}

private function CannotAffordInfusionCostDialogCallback(Name eAction, UICallbackData xUserData)
{	
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_FacilityXCom FacilityState;
	local UICallbackData_StateObjectReference CallbackData;
	local StaffUnitInfo UnitInfo;

	CallbackData = UICallbackData_StateObjectReference(xUserData);

	if (eAction == 'eUIAction_Accept')
	{		
		StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));
		
		if (StaffSlot != none)
		{
			UnitInfo.UnitRef = CallbackData.ObjectRef;
			StaffSlot.FillSlot(UnitInfo); // The Training project is started when the staff slot is filled
			
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");
			
			XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
			FacilityState = StaffSlot.GetFacility();
			if (FacilityState.GetNumEmptyStaffSlots() > 0)
			{
				StaffSlot = FacilityState.GetStaffSlot(FacilityState.GetEmptyStaffSlotIndex());

				if ((StaffSlot.IsScientistSlot() && XComHQ.GetNumberOfUnstaffedScientists() > 0) ||
					(StaffSlot.IsEngineerSlot() && XComHQ.GetNumberOfUnstaffedEngineers() > 0))
				{
					`HQPRES.UIStaffSlotOpen(FacilityState.GetReference(), StaffSlot.GetMyTemplate());
				}
			}
		}

		UpdateData();
	}
}

private function ConfirmInfusionDialogCallback(Name eAction, UICallbackData xUserData)
{	
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_FacilityXCom FacilityState;
	local UICallbackData_StateObjectReference CallbackData;
	local StaffUnitInfo UnitInfo;

	CallbackData = UICallbackData_StateObjectReference(xUserData);

	if(eAction == 'eUIAction_Accept')
	{		
		StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));
		
		if (StaffSlot != none)
		{
			UnitInfo.UnitRef = CallbackData.ObjectRef;
			StaffSlot.FillSlot(UnitInfo); // The Training project is started when the staff slot is filled
			
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");
			
			XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
			FacilityState = StaffSlot.GetFacility();
			if (FacilityState.GetNumEmptyStaffSlots() > 0)
			{
				StaffSlot = FacilityState.GetStaffSlot(FacilityState.GetEmptyStaffSlotIndex());

				if ((StaffSlot.IsScientistSlot() && XComHQ.GetNumberOfUnstaffedScientists() > 0) ||
					(StaffSlot.IsEngineerSlot() && XComHQ.GetNumberOfUnstaffedEngineers() > 0))
				{
					`HQPRES.UIStaffSlotOpen(FacilityState.GetReference(), StaffSlot.GetMyTemplate());
				}
			}
		}

		UpdateData();
	}
}

private function bool CanAffordInfusionCost()
{
	local StrategyCost				InfusionCost;
	local array<StrategyCostScalar> CostScalars;

	InfusionCost = class'X2DLCInfo_WOTCFOXCOMLitePsiOverhaul'.static.GetInfusionCost();

	CostScalars.Length = 0; // Settle down, compiler

	return `XCOMHQ.CanAffordAllStrategyCosts(InfusionCost, CostScalars);
}