class X2Ability_NotGifted extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(IRI_NoPsionicGift());

	return Templates;
}

static function X2AbilityTemplate IRI_NoPsionicGift()
{
	local X2AbilityTemplate	Template;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_NoPsionicGift');

	//SetHidden(Template);
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.bIsPassive = true;
	Template.Hostility = eHostility_Neutral;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	Template.IconImage = "img:///UILibrary_XPACK_Common.PerkIcons.weakx_fearofpsionics";
	Template.AbilitySourceName = 'eAbilitySource_Debuff';

	return Template;
}


//	========================================
//				COMMON CODE
//	========================================

static function SetHidden(out X2AbilityTemplate Template)
{
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	
	//TacticalText is for mainly for item-granted abilities (e.g. to hide the ability that gives the armour stats)
	Template.bDisplayInUITacticalText = false;
	
	//	bDisplayInUITooltip isn't actually used in the base game, it should be for whether to show it in the enemy tooltip, 
	//	but showing enemy abilities didn't make it into the final game. Extended Information resurrected the feature  in its enhanced enemy tooltip, 
	//	and uses that flag as part of it's heuristic for what abilities to show, but doesn't rely solely on it since it's not set consistently even on base game abilities. 
	//	Anyway, the most sane setting for it is to match 'bDisplayInUITacticalText'. (c) MrNice
	Template.bDisplayInUITooltip = false;
	
	//Ability Summary is the list in the armoury when you're looking at a soldier.
	Template.bDontDisplayInAbilitySummary = true;
	Template.bHideOnClassUnlock = true;
}

