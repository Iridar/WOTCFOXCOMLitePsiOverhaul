class PsionicInfusionCostConfirmer extends Object;

// TODO: Delete
/*
var private XComGameState			NewGameState;
var private StateObjectReference	SlotRef;
var private StaffUnitInfo			UnitInfo;

var private localized string		strConfirmInfusionCostTitle;
var private localized string		strConfirmInfusionCostText;

final function ConfirmCost(XComGameState _NewGameState, StateObjectReference _SlotRef, StaffUnitInfo _UnitInfo)
{
	//local DynamicPropertySet PropertySet;

	local TDialogueBoxData			kDialogData;
	local StrategyCost				InfusionCost;
	local array<StrategyCostScalar> CostScalars;
	local string					strResourcesRequired;

	NewGameState = _NewGameState;
	SlotRef = _SlotRef;
	UnitInfo = _UnitInfo;

	InfusionCost = class'X2DLCInfo_WOTCFOXCOMLitePsiOverhaul'.static.GetInfusionCost();

	CostScalars.Length = 0; // Settle down, compiler.
	strResourcesRequired = class'UIUtilities_Strategy'.static.GetStrategyCostString(InfusionCost, CostScalars);

	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = strConfirmInfusionCostTitle;
	kDialogData.strText = Repl(strConfirmInfusionCostText, "%ResourceCost%", strResourcesRequired);
	kDialogData.strAccept = class'UISimpleScreen'.default.m_strAccept;
	kDialogData.strCancel = class'UISimpleScreen'.default.m_strCancel;
	kDialogData.fnCallback = ConfirmCostCB;
	`PRESBASE.UIRaiseDialog(kDialogData);

	// class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIAlert_PsiTraining_FOXCOM', 'eAlert_IRIFMPSI_Infusion_Cost_Confirmation', ConfirmCostCB, true, true, true, false);
	// class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'EventToTrigger', '');
	// class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'SoundToPlay', "Geoscape_CrewMemberLevelledUp"); // TODO: Some sound here
	// class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
	// `HQPRES.QueueDynamicPopup(PropertySet);
}

private function ConfirmCostCB(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		// TODO: Check CanAfford here
		`AMLOG("NewGameState has been submitted:" @ NewGameState.HistoryIndex);
		class'X2DLCInfo_WOTCFOXCOMLitePsiOverhaul'.static.FillPsiChamberSoldierSlot_Actual(NewGameState, SlotRef, UnitInfo, true);
	}
}
*/
/*
private function ConfirmCostCB(Name eAction, out DynamicPropertySet AlertData, optional bool LocbInstant = false)
{
	if (eAction == 'eUIAction_Accept')
	{
		`AMLOG("NewGameState has been submitted:" @ NewGameState.HistoryIndex);
		class'X2DLCInfo_WOTCFOXCOMLitePsiOverhaul'.static.FillPsiChamberSoldierSlot_Actual(NewGameState, SlotRef, UnitInfo);
	}
}
*/