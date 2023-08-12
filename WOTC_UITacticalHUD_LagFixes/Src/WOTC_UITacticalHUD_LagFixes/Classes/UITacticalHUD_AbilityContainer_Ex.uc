class UITacticalHUD_AbilityContainer_Ex extends UITacticalHUD_AbilityContainer;

// The last History Index that was realized
var int LastRealizedIndex;

simulated function UpdateAbilitiesArray() 
{
    UpdateAbilitiesArrayFromHistory(`XCOMHISTORY.GetCurrentHistoryIndex());
}

simulated function UpdateAbilitiesArrayFromHistory(optional int HistoryIndex = -1)
{
	if (HistoryIndex == -1) // force an update no matter what (e.g. if we switched units, we could realize the same index)
	{
		LastRealizedIndex = `XCOMHISTORY.GetCurrentHistoryIndex();
	}
	else
	{
		if (HistoryIndex <= LastRealizedIndex)
		{
			return;
		}

		LastRealizedIndex = HistoryIndex;
	}

    super.UpdateAbilitiesArray();
}

function protected LatentSubmitGameStateContextCallback(XComGameState GameState)
{
    super.LatentSubmitGameStateContextCallback(GameState);

    if (LastSelectionPermitsImmediateSelect == false)
    {
        // refresh the list of abilities/targets
		UpdateAbilitiesArrayFromHistory(GameState.HistoryIndex);
    }
}