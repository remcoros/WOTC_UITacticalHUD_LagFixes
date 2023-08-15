class X2DownloadableContentInfo_WOTC_UITacticalHUD_LagFixes extends X2DownloadableContentInfo;

static event OnLoadedSavedGame(){}

static event InstallNewCampaign(XComGameState StartState){}

static function UpdateHumanPawnMeshComponent(XComGameState_Unit UnitState, XComHumanPawn Pawn, MeshComponent MeshComp)
{
    // This function gets called a lot, but we don't use it in this mod, so make it empty to get some free performance.
    // (hopefully will be fixed in CHL at some point)
}

static function OnPreCreateTemplates()
{
	local Engine Engine;
	local int i;

	Engine = class'Engine'.static.GetEngine();

	for (i = Engine.ModClassOverrides.Length - 1; i >= 0; --i)
	{
		if (Engine.ModClassOverrides[i].BaseGameClass == 'UITacticalHUD_Enemies' && Engine.ModClassOverrides[i].ModClass == 'UITacticalHUD_Enemies_HitChance')
		{
            Engine.ModClassOverrides.Remove(i, 1);
		}
	}
}