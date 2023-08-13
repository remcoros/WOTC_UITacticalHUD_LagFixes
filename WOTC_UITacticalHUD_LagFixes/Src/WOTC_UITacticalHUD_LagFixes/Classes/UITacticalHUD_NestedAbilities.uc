class UITacticalHUD_NestedAbilities extends UITacticalHUD_AbilityContainer;

var UITacticalHUD_AbilityContainer ParentPane;
var int ShiftIndex;

simulated function ShowAOE(int Index)
{
	ParentPane.ShowAOE((index % MAX_NUM_ABILITIES) + ShiftIndex);
}

simulated function HideAOE(int Index)
{
	ParentPane.HideAOE((index % MAX_NUM_ABILITIES) + ShiftIndex);
}

simulated function bool AbilityClicked(int index)
{
	return ParentPane.AbilityClicked((index % MAX_NUM_ABILITIES) + ShiftIndex);
}

simulated function X2TargetingMethod GetTargetingMethod()
{
	return ParentPane.GetTargetingMethod();
}

simulated public function bool OnAccept( optional string strOption = "" )
{
	ParentPane.m_arrUIAbilities[m_iCurrentIndex].OnLoseFocus();
	return ParentPane.OnAccept(strOption);
}

function ResetMouse()
{
	ParentPane.ResetMouse();
}

defaultproperties
{
	LibID = "AbilityContainer";
	MCName = "AbilityContainerMC2";
	ShiftIndex = 30;
	bAnimateOnInit = false;
}