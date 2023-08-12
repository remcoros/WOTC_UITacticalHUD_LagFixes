class UITacticalHUD_Countdown_Ex extends UITacticalHUD_Countdown;

// The last History Index that was realized
var int LastRealizedIndex;
var int m_lastSpawnerStateCountdown;
var string m_sLastColor;
var string m_sLastTitle;
var string m_sLastBody;

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	local XComGameState_AIReinforcementSpawner AISpawnerState;
	local string sTitle, sBody, sColor;  // Issue #449

	//Track the largest index we have seen so far. This is necessary because the OnVisualizationBlockComplete can complete in an arbitrary order relative to the history
    if (AssociatedGameState.HistoryIndex <= LastRealizedIndex || !AssociatedGameState.GetContext().bLastEventInChain)
	{
		return;
	}

	LastRealizedIndex = AssociatedGameState.HistoryIndex;

	// Start Issue #449
	//
	// Check whether any listeners want to force the display of the reinforcements
	// alert. If so, display it and update its text and color based on the values
	// provided by the dominant listener.
	if (CheckForReinforcementsOverride(sTitle, sBody, sColor, AssociatedGameState))
	{
		// only call into AS when something changed
		if (m_sLastColor != sColor || m_sLastTitle != sTitle || m_sLastBody != sBody)
		{
			m_sLastColor = sColor;
			m_sLastTitle = sTitle;
			m_sLastBody = sBody;

			AS_SetCounterText(sTitle, sBody);
			AS_SetMCColor( MCPath$".dags", sColor);
		}

		Show();
		return;
	}
	// End Issue #449
	
	foreach AssociatedGameState.IterateByClassType(class'XComGameState_AIReinforcementSpawner', AISpawnerState)
	{
		RefreshCounter(AISpawnerState);
		break;
	}
}

simulated function RefreshCounter(XComGameState_AIReinforcementSpawner AISpawnerState)
{
	if( AISpawnerState.Countdown > 0 && m_lastSpawnerStateCountdown != AISpawnerState.Countdown)
	{
		m_lastSpawnerStateCountdown = AISpawnerState.Countdown;
		AS_SetCounterTimer(AISpawnerState.Countdown);
		Show(); 
	}
	else
	{
		Hide();
	}
}

defaultproperties 
{
    LastRealizedIndex = -1;
}