//-----------------------------------------------------------
//	Class:	WOTCFOXCOMLitePsiOverhaul_MCMScreenListener
//	Author: Iridar
//	
//-----------------------------------------------------------

class WOTCFOXCOMLitePsiOverhaul_MCMScreenListener extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local WOTCFOXCOMLitePsiOverhaul_MCMScreen MCMScreen;

	if (ScreenClass==none)
	{
		if (MCM_API(Screen) != none)
			ScreenClass=Screen.Class;
		else return;
	}

	MCMScreen = new class'WOTCFOXCOMLitePsiOverhaul_MCMScreen';
	MCMScreen.OnInit(Screen);
}

defaultproperties
{
    ScreenClass = none;
}
