class UIAlertPanel_ShowEnemies extends UIAlertShadowChamberPanel;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);

	DisableNavigation();

	return self;
}

defaultproperties
{
	LibID = "Alert_ShadowChamber";
}