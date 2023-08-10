class UITacticalHUD_Enemies_Ex extends UITacticalHUD_Enemies;

// Start Issue #1233 wrapper for sort delegate
struct StateObjectReferenceHitChange
{
	var StateObjectReference Object;
	var XComGameState_BaseObject GameState;
	var int HitChance;
};

var array<StateObjectReferenceHitChange> m_arrTargetsUnsorted;
// End Issue #1233

var int LastActiveUnitObjectID;

simulated function OnInit()
{
	local X2EventManager EventManager;
	local Object ThisObj;

	// skip the OnInit of UITacticalHUD_Enemies, we still need to call UIPanel.OnInit
	super(UIPanel).OnInit();

	`XCOMVISUALIZATIONMGR.RegisterObserver(self);

	EventManager = `XEVENTMGR;
	ThisObj = self;
	EventManager.RegisterForEvent(ThisObj, 'ScamperBegin', OnReEvaluationEvent, ELD_OnVisualizationBlockCompleted);
	EventManager.RegisterForEvent(ThisObj, 'UnitDied', OnReEvaluationEvent, ELD_OnVisualizationBlockCompleted);

	// ExitSign: this seems to be only used to redraw the abbility array right after when it is activated, without out, we redraw too late
	// and the bar looks active while the abilities animations are running.
	// But since this is a global event listener, it is called A LOT and we redraw unnecessarily often.
	// Instead, we do not listen for the global event, but instead redraw when the ability was accepted in UITacticalHUD_AbilityArray
	//EventManager.RegisterForEvent(ThisObj, 'AbilityActivated', OnAbilityActivated, ELD_OnVisualizationBlockCompleted);

	InitializeTooltipData();

	if(!Movie.IsMouseActive())
		InitNavHelp();
}

function EventListenerReturn OnReEvaluationEvent(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	RealizeTargets(GameState.HistoryIndex);

	return ELR_NoInterrupt;
}

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	//Track the largest index we have seen so far. This is necessary because the OnVisualizationBlockComplete can complete in an arbitrary order relative to the history
	if (AssociatedGameState.HistoryIndex > LatestVisBlockCompletedIndex)
	{
		//Limit how often this can be called	
		if (AssociatedGameState.GetContext().bLastEventInChain)
		{
			RealizeTargets(AssociatedGameState.HistoryIndex);
		}

		LatestVisBlockCompletedIndex = AssociatedGameState.HistoryIndex;
	}
}

event OnVisualizationIdle();

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit)
{	
	if (LastActiveUnitObjectID != NewActiveUnit.ObjectID)
	{
		RealizeTargets(-1);
		LastActiveUnitObjectID = NewActiveUnit.ObjectID;
	}

	// ExitSign: note we keep this out of the above check, so the sound still plays at the end of a move (like it does now)	
	// play the sighted enemies sound whenever changing the active unit if there are any visible enemies
	if( iNumVisibleEnemies > 0 )
	{
		PlayEnemySightedSound();
	}
}

simulated function RealizeTargets(int HistoryIndex, bool bDontRefreshVisibleEnemies = false)
{
	if (HistoryIndex == -1)		//	force an update no matter what (e.g. if we switched units, we could realize the same index)
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

	//  update the abilities array - otherwise when the enemy heads get sorted by hit chance, the cached abilities those functions use could be out of date
	UITacticalHUD_AbilityContainer_Ex(XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kAbilityHUD).UpdateAbilitiesArrayFromHistory(HistoryIndex);
	XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kEnemyTargets.MC.FunctionVoid("MoveDown");
	XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kEnemyPreview.MC.FunctionVoid("MoveDownPreview");

	ClearSelectedEnemy();
	if( !bDontRefreshVisibleEnemies )
	{
		UpdateVisibleEnemies(HistoryIndex);
	}
}

simulated function UpdateVisibleEnemies(int HistoryIndex)
{
	local XGUnit kActiveUnit;
	local XComGameState_Unit ActiveUnit;
	local XComGameStateHistory History;
	local int i;
	local XComGameState_Ability CurrentAbilityState;
	local X2AbilityTemplate AbilityTemplate;
	local StateObjectReferenceHitChange TargetWrapper;

	m_arrSSEnemies.length = 0;
	m_arrCurrentlyAffectable.length = 0;

	kActiveUnit = XComTacticalController(PC).GetActiveUnit();
	if (kActiveUnit != none)
	{
		// DATA: -----------------------------------------------------------
		History = `XCOMHISTORY;
		ActiveUnit = XComGameState_Unit(History.GetGameStateForObjectID(kActiveUnit.ObjectID, , HistoryIndex));

		CurrentAbilityState = XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kAbilityHUD.GetCurrentSelectedAbility();
		AbilityTemplate = CurrentAbilityState != none ? CurrentAbilityState.GetMyTemplate() : none;

		if (AbilityTemplate != none && AbilityTemplate.AbilityTargetStyle.SuppressShotHudTargetIcons())
		{
			m_arrTargets.Length = 0;
		}
		else
		{
			ActiveUnit.GetUISummary_TargetableUnits(m_arrTargets, m_arrSSEnemies, m_arrCurrentlyAffectable, CurrentAbilityState, HistoryIndex);
		}

		// if the currently selected ability requires the list of ability targets be restricted to only the ones that can be affected by the available action, 
		// use that list of targets instead
		if (AbilityTemplate != none)
		{
			if (AbilityTemplate.bLimitTargetIcons)
			{
				m_arrTargets = m_arrCurrentlyAffectable;
			}
			else
			{
				//  make sure that all possible targets are in the targets list - as they may not be visible enemies
				for (i = 0; i < m_arrCurrentlyAffectable.Length; ++i)
				{
					if (m_arrTargets.Find('ObjectID', m_arrCurrentlyAffectable[i].ObjectID) == INDEX_NONE)
						m_arrTargets.AddItem(m_arrCurrentlyAffectable[i]);
				}
			}
		}
		
		iNumVisibleEnemies = m_arrTargets.Length;

		// Start Issue #1233 cache some expensive calls and use that in our custom sort delegate
		
		//m_arrTargets.Sort(SortEnemies);

		m_arrTargetsUnsorted.Length = 0;
		
		for (i = 0; i < iNumVisibleEnemies; ++i)
		{			
			TargetWrapper.Object = m_arrTargets[i];
			TargetWrapper.HitChance = GetHitChanceForObjectRef(TargetWrapper.Object);
			TargetWrapper.GameState = History.GetGameStateForObjectID(TargetWrapper.Object.ObjectID);

			m_arrTargetsUnsorted.AddItem(TargetWrapper);
		}
	
		// use our improved sort delegate
		m_arrTargetsUnsorted.Sort(SortEnemiesImproved);

		m_arrTargets.Length = 0;
		for (i = 0; i < iNumVisibleEnemies; ++i)
		{
			m_arrTargets.AddItem(m_arrTargetsUnsorted[i].Object);
		}
		
		// End Issue #1233

		UpdateVisuals(HistoryIndex);
	}
}

// Start Issue #1233 hot path, use cached values only
simulated function int SortEnemiesImproved(StateObjectReferenceHitChange ObjectA, StateObjectReferenceHitChange ObjectB)
{
	local XComGameState_Destructible DestructibleTargetA, DestructibleTargetB;

	DestructibleTargetA = XComGameState_Destructible(ObjectA.GameState);
	DestructibleTargetB = XComGameState_Destructible(ObjectB.GameState);

	//Push the destructible enemies to the back of the list.
	if( DestructibleTargetA != none && DestructibleTargetB == none ) 
	{
		return -1;
	}
	if( DestructibleTargetB != none && DestructibleTargetA == none ) 
	{
		return 1;
	}

	// push lower-hit chance targets back
	if( ObjectA.HitChance < ObjectB.HitChance )
	{
		return -1;
	}

	return 1;
}
// End Issue #1233

simulated function int GetHitChanceForObjectRef(StateObjectReference TargetRef)
{
	// TODO: if (bEnableEnemyPreviewExtended)
	return super.GetHitChanceForObjectRef(TargetRef);
}
