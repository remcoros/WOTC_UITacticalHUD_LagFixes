class X2DownloadableContentInfo_WOTC_UITacticalHUD_LagFixes extends X2DownloadableContentInfo;

static function UpdateHumanPawnMeshComponent(XComGameState_Unit UnitState, XComHumanPawn Pawn, MeshComponent MeshComp)
{
    // This function gets called a lot, but we don't use it in this mod, so make it empty to get some free performance.
    // (hopefully will be fixed in CHL at some point)
}

// Let's not mess with users ini config
// static function OnPreCreateTemplates()
// {
// 	local Engine Engine;
// 	local int i;

// 	Engine = class'Engine'.static.GetEngine();

// 	for (i = Engine.ModClassOverrides.Length - 1; i >= 0; --i)
// 	{
// 		if (Engine.ModClassOverrides[i].BaseGameClass == 'UITacticalHUD_Enemies' && Engine.ModClassOverrides[i].ModClass == 'UITacticalHUD_Enemies_HitChance')
// 		{
//             `log("WOTC_UITacticalHUD_LagFixes > OnPreCreateTemplates > removed UITacticalHUD_Enemies_HitChance MCO");
//             Engine.ModClassOverrides.Remove(i, 1);
// 		}
// 	}

//     for (i = 0; i < Engine.ModClassOverrides.Length; ++i)
// 	{
//         `log("WOTC_UITacticalHUD_LagFixes | Base="$Engine.ModClassOverrides[i].BaseGameClass$" ModClass="$Engine.ModClassOverrides[i].ModClass);
// 	}
// }