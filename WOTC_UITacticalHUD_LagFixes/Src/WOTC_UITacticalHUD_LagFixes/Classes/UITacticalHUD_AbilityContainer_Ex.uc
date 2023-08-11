class UITacticalHUD_AbilityContainer_Ex extends UITacticalHUD_AbilityContainer;

// The last History Index that was realized
var int LastRealizedIndex;
var int LastVizHistoryIndex;
var StateObjectReference LastSelectedUnitRef;
var bool m_bPopulatingFlash;

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

simulated function PopulateFlash()
{
    if (m_bPopulatingFlash) return;
    m_bPopulatingFlash = true;
    ClearTimer(nameof(PopulateFlashDelayed));
    SetTimer(0.01f, false, nameof(PopulateFlashDelayed));
}

private function PopulateFlashDelayed()
{
    super.PopulateFlash();
    m_bPopulatingFlash = false;
}