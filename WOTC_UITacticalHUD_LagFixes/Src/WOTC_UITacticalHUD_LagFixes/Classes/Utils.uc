class Utils extends Object abstract config(WOTC_TacticalHUD_LagFixes_Settings);

struct DLCInfo
{
    var string Name;
    var bool Installed;
};

var config array<DLCInfo> _dlcInfos;
var config array<DLCInfo> _modInfos;

public static final function bool IsDLCInstalled(coerce string dlcIdentifier)
{
	local array<string> DLCs;
    local DLCInfo dlc;
    local int dlcInfoIdx;

    dlcInfoIdx = default._dlcInfos.Find('Name', dlcIdentifier);
    if (dlcInfoIdx != INDEX_NONE)
    {
        return default._dlcInfos[dlcInfoIdx].Installed;
    }

	DLCs = class'Helpers'.static.GetInstalledDLCNames();

    dlc.Name = dlcIdentifier;
    dlc.Installed = DLCs.Find(dlcIdentifier) != INDEX_NONE;
    default._dlcInfos.AddItem(dlc);

	return dlc.Installed;
}

public static final function bool IsModInstalled(coerce string modName)
{
	local array<string> MODs;
    local DLCInfo mod;
    local int modInfoIdx;

    modInfoIdx = default._modInfos.Find('Name', modName);
    if (modInfoIdx != INDEX_NONE)
    {
        return default._modInfos[modInfoIdx].Installed;
    }

	MODs = class'Helpers'.static.GetInstalledModNames();

    mod.Name = modName;
    mod.Installed = MODs.Find(modName) != INDEX_NONE;
    default._modInfos.AddItem(mod);

	return mod.Installed;
}