class UIObjectiveList_Ex extends UIObjectiveList;

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	// Fixing the off-by-one error of the base function
    // and only update at the last event in a chain.
	if (AssociatedGameState.HistoryIndex <= SyncedToState || !AssociatedGameState.GetContext().bLastEventInChain)
	{
		return;
	}

    super.OnVisualizationBlockComplete(AssociatedGameState);
}
