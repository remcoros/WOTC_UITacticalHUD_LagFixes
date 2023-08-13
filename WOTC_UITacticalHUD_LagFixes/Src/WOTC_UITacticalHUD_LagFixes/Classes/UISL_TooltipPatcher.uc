class UISL_TooltipPatcher extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local UITacticalHUD_AbilityTooltip	AbilityTooltip;
	local UITacticalHUD_Tooltips Tooltips;
	local AbilityTooltipDelegateHook DelegateHook;
	if (UITacticalHUD(Screen) != none)
	{
		Tooltips = UITacticalHUD(Screen).m_kTooltips;
		AbilityTooltip = UITacticalHUD_AbilityTooltip(Tooltips.Movie.Pres.m_kTooltipMgr.GetChildByName('TooltipAbility', false));
		if (AbilityTooltip != none)
		{
			DelegateHook = AbilityTooltipDelegateHook(AbilityTooltip.GetChildByName('TooltipThirtyHook', false));

			if (DelegateHook == none)
			{
				DelegateHook = AbilityTooltip.Spawn(class'AbilityTooltipDelegateHook', AbilityTooltip);
				DelegateHook.InitPanel('TooltipThirtyHook');
				DelegateHook.Hide();
				DelegateHook.del_OnMouseIn = AbilityTooltip.del_OnMouseIn;
				AbilityTooltip.del_OnMouseIn = DelegateHook.OnAbilityTooptipMouseIn;
			}
		}
	}
}
