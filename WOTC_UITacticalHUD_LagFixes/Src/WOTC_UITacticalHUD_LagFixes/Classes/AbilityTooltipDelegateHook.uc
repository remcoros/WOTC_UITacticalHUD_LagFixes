class AbilityTooltipDelegateHook extends UIPanel;

delegate del_OnMouseIn( UIToolTip refToThisTooltip );

function OnAbilityTooptipMouseIn( UIToolTip Tooltip )
{
	local int					iTargetIndex; 
	local array<string>			Path; 
	local int					MovePathIndex, MovieNum;
	MovePathIndex = InStr(Tooltip.currentPath, 'AbilityContainerMC');
	MovieNum = int(Mid(Tooltip.currentPath, MovePathIndex + 18, 1));
	if (MovieNum > 1)
	{
		Path = SplitString( Tooltip.currentPath, "." );	
		iTargetIndex = int(GetRightMost(Path[5])) + (30 * (MovieNum - 1));
		Path[5] = "AbilityItem_" $ iTargetIndex;
		JoinArray(Path, Tooltip.currentPath, ".");
	}

	if (del_OnMouseIn != none)
		del_OnMouseIn(Tooltip);
}