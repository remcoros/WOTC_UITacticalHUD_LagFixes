class UIUnitFlagManager_Ex extends UIUnitFlagManager;

var array<ObjectHistoryIndex> m_arrUnitHistory;

simulated function OnInit()
{
    super.OnInit();

    m_arrUnitHistory.Length = 0;
}

simulated function RespondToNewGameState(XGUnit Unit, XComGameState NewGameState, bool bForceUpdate = false)
{
	local int i, ObjectHistoryIdx, HistoryIndex;
    local ObjectHistoryIndex ObjectHistory;

	for( i = 0; i < m_arrUnitHistory.Length; ++i )
	{
		if( m_arrUnitHistory[i].ObjectID == Unit.ObjectID )
		{
			ObjectHistory = m_arrUnitHistory[i];
            break;
		}
	}

    // ObjectHistoryIdx = m_arrUnitHistory.Find('ObjectID', Unit.ObjectID);
    // if (ObjectHistoryIdx >= 0)
    // {
    //     ObjectHistory = m_arrUnitHistory[ObjectHistoryIdx];
    // }

    if (NewGameState == none)
    {
        HistoryIndex = `XCOMHISTORY.GetCurrentHistoryIndex();
    }
    else
    {
        HistoryIndex = NewGameState.HistoryIndex;
    }
    
    if (bForceUpdate == false && ObjectHistory != none && HistoryIndex <= ObjectHistory.HistoryIndex)
    {
        return;
    }

    if (ObjectHistory == none)
    {
        ObjectHistory = new class'ObjectHistoryIndex';
        ObjectHistory.ObjectID = Unit.ObjectID;
    }

    ObjectHistory.HistoryIndex = HistoryIndex;

	for( i = 0; i < m_arrFlags.Length; i++ )
	{
		if( m_arrFlags[i].StoredObjectID == Unit.ObjectID )
		{
			m_arrFlags[i].RespondToNewGameState(NewGameState, bForceUpdate);
			return;
		}
	}

	for( i = 0; i < m_arrSimpleFlags.Length; i++ )
	{
		if( m_arrSimpleFlags[i].StoredObjectID == Unit.ObjectID )
		{
			m_arrSimpleFlags[i].RespondToNewGameState(NewGameState, bForceUpdate);
			return;
		}
	}
}