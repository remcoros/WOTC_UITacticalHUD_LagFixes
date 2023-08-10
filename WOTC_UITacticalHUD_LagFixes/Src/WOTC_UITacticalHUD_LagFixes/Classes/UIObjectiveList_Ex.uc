class UIObjectiveList_Ex extends UIObjectiveList;

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	local XComGameState_ObjectivesList ObjectiveList;
	local XComGameState_AIReinforcementSpawner AISpawnerState; 
	local XComGameStateHistory History;
	local int spawningStates;
	local bool ForceShowReinforcementsAlert;
	
    `log("UIObjectiveList_Ex > OnVisualizationBlockComplete " $ AssociatedGameState.HistoryIndex);

	//Exit early if the state being passed in is older than our latest sync'd state
	if (AssociatedGameState.HistoryIndex <= SyncedToState || !AssociatedGameState.GetContext().bLastEventInChain)
	{
		return;
	}

	// See if any states we are interested in are in the associated state
	foreach AssociatedGameState.IterateByClassType(class'XComGameState_ObjectivesList', ObjectiveList)
	{
		break;
	}

	foreach AssociatedGameState.IterateByClassType(class'XComGameState_AIReinforcementSpawner', AISpawnerState)
	{
		break;
	}

	// Start Issue #449
	ForceShowReinforcementsAlert = IsReinforcementsAlertForced(AssociatedGameState);

	// if this state has nothing for us to update, then just return
	if (ObjectiveList == none && AISpawnerState == none && !ForceShowReinforcementsAlert)
	{
		return;
	}
	// End Issue #449

	// if we update either, we need to grab the correct version of both or our SyncedToState might prevent us from updating correctly
	History = `XCOMHISTORY;
	
	foreach History.IterateByClassType(class'XComGameState_ObjectivesList', ObjectiveList)
	{
		ObjectiveList = XComGameState_ObjectivesList(History.GetGameStateForObjectID(ObjectiveList.ObjectID,, AssociatedGameState.HistoryIndex));
		RefreshObjectivesDisplay(ObjectiveList);
		break;
	}

	// Start Issue #449
	//
	// Reposition the objective list if the reinforcements alert is being forced
	// to show.
	if (ForceShowReinforcementsAlert)
	{
		SetPosition(ReinforcementsPos.X, ReinforcementsPos.Y);
	}
	else
	{
		spawningStates = 0;
		foreach History.IterateByClassType(class'XComGameState_AIReinforcementSpawner', AISpawnerState)
		{
			spawningStates++;
			AISpawnerState = XComGameState_AIReinforcementSpawner(History.GetGameStateForObjectID(AISpawnerState.ObjectID,, AssociatedGameState.HistoryIndex));
			RefreshPositionBasedOnCounter(AISpawnerState);
			break;
		}

		if (spawningStates == 0)
		{
			//objectives list needs to return to valid position after reinforcements
			RefreshPositionBasedOnCounter(none);
		}
	}
	// End Issue #449

	SyncedToState = AssociatedGameState.HistoryIndex;
}
