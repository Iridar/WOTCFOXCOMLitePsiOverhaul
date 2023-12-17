class X2StrategyElement_PsiAmp extends CHItemSlotSet config(PsiOverhaul);

//var localized string strSlotFirstLetter;
var config string strSlotLocName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateSlotTemplate());

	return Templates;
}

static function X2DataTemplate CreateSlotTemplate()
{
	local CHItemSlot Template;

	`CREATE_X2TEMPLATE(class'CHItemSlot', Template, 'IRI_PsiAmpSlot');

	Template.InvSlot = eInvSlot_PsiAmp;
	Template.SlotCatMask = Template.SLOT_WEAPON;

	Template.IsUserEquipSlot = true;

	Template.IsEquippedSlot = true;

	Template.BypassesUniqueRule = false;
	Template.IsMultiItemSlot = false;
	Template.IsSmallSlot = false;
	Template.NeedsPresEquip = true;
	Template.ShowOnCinematicPawns = true;

	Template.CanAddItemToSlotFn = CanAddItemToSlot;

	Template.UnitHasSlotFn = HasSlot;
	Template.GetPriorityFn = SlotGetPriority;
	
	Template.ShowItemInLockerListFn = ShowItemInLockerList;
	Template.ValidateLoadoutFn = SlotValidateLoadout;
	//Template.GetDisplayLetterFn = GetSlotDisplayLetter;
	Template.GetDisplayNameFn = GetDisplayName;

	return Template;
}

static private function bool HasSlot(CHItemSlot Slot, XComGameState_Unit UnitState, out string LockedReason, optional XComGameState CheckGameState)
{ 
	if (class'Help'.static.IsPsiOperative(UnitState))
	{
		// Soldier classes that use Psi Amp as a secondary and don't have access to other secondaries
		// don't get access to Psi Amp slot.
		if (class'Help'.static.PsiAmpIsOnlySecondaryForSoldierClass(UnitState))
		{
			return false;
		}

		return true;
	}
	   
	return false;
}



static private function bool ShowItemInLockerList(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_Item ItemState, X2ItemTemplate ItemTemplate, XComGameState CheckGameState)
{
	return IsTemplateValidForSlot(Slot.InvSlot, ItemTemplate, Unit, CheckGameState);
}

static private function bool CanAddItemToSlot(CHItemSlot Slot, XComGameState_Unit UnitState, X2ItemTemplate ItemTemplate, optional XComGameState CheckGameState, optional int Quantity = 1, optional XComGameState_Item ItemState)
{    
	//	If there is no item in the slot
	if(UnitState.GetItemInSlot(Slot.InvSlot, CheckGameState) == none)
	{
		return IsTemplateValidForSlot(Slot.InvSlot, ItemTemplate, UnitState, CheckGameState);
	}

	//	Slot is already occupied, cannot add any more items to it.
	return false;
}

static private function bool IsTemplateValidForSlot(EInventorySlot InvSlot, X2ItemTemplate ItemTemplate, XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	local X2WeaponTemplate WeaponTemplate;

	WeaponTemplate = X2WeaponTemplate(ItemTemplate);
	if (WeaponTemplate == none)
		return false;

	return WeaponTemplate.InventorySlot == eInvSlot_PsiAmp || WeaponTemplate.WeaponCat == 'psiamp';
}

static private function SlotValidateLoadout(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState)
{
	local XComGameState_Item	ItemState;
	local XComGameState_Unit	NewUnit;
	local string				strDummy;
	local bool					HasSlot;

	ItemState = Unit.GetItemInSlot(Slot.InvSlot, NewGameState);
	HasSlot = Slot.UnitHasSlot(Unit, strDummy, NewGameState);

	//	If there's an item equipped in the slot, but the unit is not supposed to have the slot, or the item is not supposed to be in the slot, then unequip it and put it into HQ Inventory.
	if (ItemState != none && (!HasSlot || !IsTemplateValidForSlot(Slot.InvSlot, ItemState.GetMyTemplate(), Unit, NewGameState)))
	{
		ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemState.ObjectID));
		NewUnit = XComGameState_Unit(GetGameStateForObjectID(NewGameState, class'XComGameState_Unit', Unit.GetReference()));
		if (NewUnit.RemoveItemFromInventory(ItemState, NewGameState))
		{
			XComHQ.PutItemInInventory(NewGameState, ItemState);
			ItemState = none;
		}	
	}

	//	If there's no item in the slot, put a conventional Psi Amp into it
	if (ItemState == none && HasSlot)
	{
		ItemState = FindBestWeapon(Unit, eInvSlot_PsiAmp, XComHQ, NewGameState);
		if (ItemState == none)
		{
			ItemState = XComHQ.GetItemByName('PsiAmp_CV');
			XComHQ.GetItemFromInventory(NewGameState, ItemState.GetReference(), ItemState);
		}
		if (ItemState == none)
			return;

		if (NewUnit == none)
		{
			NewUnit = XComGameState_Unit(GetGameStateForObjectID(NewGameState, class'XComGameState_Unit', Unit.GetReference()));
		}

		if (!NewUnit.AddItemToInventory(ItemState, Slot.InvSlot, NewGameState))
		{
			//	Nuke the item if it was not equipped for some reason.
			NewGameState.PurgeGameStateForObjectID(ItemState.ObjectID);
		}
	}
}

static private function XComGameState_Item FindBestWeapon(const XComGameState_Unit UnitState, EInventorySlot Slot, XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState)
{
	local X2ItemTemplate					ItemTemplate;
	local XComGameStateHistory				History;
	local int								HighestTier;
	local XComGameState_Item				ItemState;
	local XComGameState_Item				BestItemState;
	local StateObjectReference				ItemRef;

	HighestTier = -999;
	History = `XCOMHISTORY;

	//	Cycle through all items in HQ Inventory
	foreach XComHQ.Inventory(ItemRef)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
		if (ItemState != none)
		{
			ItemTemplate = ItemState.GetMyTemplate();
			if (ItemTemplate == none)
				continue;

			if (!IsTemplateValidForSlot(Slot, ItemTemplate, UnitState, NewGameState))
				continue;			

			//	If this is an infinite item, it's tier is higher than the current recorded highest tier,
			//	it is allowed on the soldier by config entries that are relevant to this soldier
			//	and it can be equipped on the soldier
			if (ItemTemplate.bInfiniteItem && ItemTemplate.Tier > HighestTier && 
				UnitState.CanAddItemToInventory(ItemTemplate, Slot, NewGameState, ItemState.Quantity, ItemState))
			{	
				//	then remember this item as the currently best replacement option.
				HighestTier = ItemTemplate.Tier;
				BestItemState = ItemState;
			}
		}
	}

	if (BestItemState != none)
	{
		//	This will set up the Item State for modification automatically, or create a new Item State in the NewGameState if the template is infinite.
		XComHQ.GetItemFromInventory(NewGameState, BestItemState.GetReference(), BestItemState);
	}

	//	If we didn't find any fitting items, then BestItemState will be "none", and we're okay with that.
	return BestItemState;
}

static private function XComGameState_BaseObject GetGameStateForObjectID(XComGameState NewGameState, class ObjClass, const StateObjectReference ObjRef)
{
	local XComGameState_BaseObject BaseObject;

	BaseObject = NewGameState.GetGameStateForObjectID(ObjRef.ObjectID);
	if (BaseObject == none)
	{
		BaseObject = NewGameState.ModifyStateObject(ObjClass, ObjRef.ObjectID);
	}
	return BaseObject;
}
static private function int SlotGetPriority(CHItemSlot Slot, XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	// I.e. put right after secondary weapon
	return eInvSlot_SecondaryWeapon * 10 + 5;
}
/*
static function string GetSlotDisplayLetter(CHItemSlot Slot)
{
	return ""; //default.strSlotFirstLetter;
}*/

static private function string GetDisplayName(CHItemSlot Slot)
{
	return default.strSlotLocName;
}