class X2DownloadableContentInfo_WOTC_UITacticalHUD_LagFixes extends X2DownloadableContentInfo;

static event OnLoadedSavedGame(){}

static event InstallNewCampaign(XComGameState StartState){}

// Make this function empty since we don't need it
static function UpdateHumanPawnMeshComponent(XComGameState_Unit UnitState, XComHumanPawn Pawn, MeshComponent MeshComp){}
