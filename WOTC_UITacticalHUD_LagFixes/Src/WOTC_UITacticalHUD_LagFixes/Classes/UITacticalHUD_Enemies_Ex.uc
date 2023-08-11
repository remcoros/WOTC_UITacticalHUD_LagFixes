class UITacticalHUD_Enemies_Ex extends UITacticalHUD_Enemies config(WOTC_UITacticalHUD_LagFixes_Settings);

// For 'Extended Information!'
`include(WOTC_UITacticalHUD_LagFixes\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

var bool bEnableEnemyPreviewExtended;
var bool TH_AIM_ASSIST;
var bool DISPLAY_MISS_CHANCE;

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
	
	bEnableEnemyPreviewExtended = class'Utils'.static.IsModInstalled("WOTC_DisplayHitChance");
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
	local UITacticalHUD_AbilityContainer AbilityContainer;
	local UITacticalHUD_AbilityContainer_Ex AbilityContainer_Ex;
	
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
	// AbilityContainer = XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kAbilityHUD;
	// AbilityContainer_Ex = UITacticalHUD_AbilityContainer_Ex(AbilityContainer);
	// if (AbilityContainer_Ex != none)
	// {
	// 	`log("UITacticalHUD_Enemies_Ex > RealizeTargets using UITacticalHUD_AbilityContainer_Ex");
	// 	AbilityContainer_Ex.UpdateAbilitiesArrayFromHistory(HistoryIndex);
	// }
	// else
	// {
	// 	`log("UITacticalHUD_Enemies_Ex > RealizeTargets using UITacticalHUD_AbilityContainer");
	// 	AbilityContainer.UpdateAbilitiesArray();
	// }

	UpdateAbilitiesArrayWithoutUI();
	XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kEnemyTargets.MC.FunctionVoid("MoveDown");
	XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kEnemyPreview.MC.FunctionVoid("MoveDownPreview");

	ClearSelectedEnemy();
	if( !bDontRefreshVisibleEnemies )
	{
		UpdateVisibleEnemies(HistoryIndex);
	}
}

// Very ugly hack to update m_arrAbilities of UITacticalHUD_AbilityContainer without all the UI updates,
// we need to do this before 'UpdateVisibleEnemies', because that uses the currently selected ability in its hitchance calculations
private function UpdateAbilitiesArrayWithoutUI() 
{
	local int i, len;
	local X2GameRuleset Ruleset;
	local GameRulesCache_Unit UnitInfoCache;
	local AvailableAction AbilityAvailableInfo;
	local UITacticalHUD_AbilityContainer AbilityContainer;

	AbilityContainer = XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kAbilityHUD;

	//Clear out the array 
	AbilityContainer.m_arrAbilities.Length = 0;

	// Loop through all abilities.
	Ruleset = `XCOMGAME.GameRuleset;
	Ruleset.GetGameRulesCache_Unit(XComTacticalController(PC).GetActiveUnitStateRef(), UnitInfoCache);

	len = UnitInfoCache.AvailableActions.Length;
	for(i = 0; i < len; ++i)
	{	
		// Obtain unit's ability.
		AbilityAvailableInfo = UnitInfoCache.AvailableActions[i];

		if(AbilityContainer.ShouldShowAbilityIcon(AbilityAvailableInfo))
		{
			//Add to our list of abilities 
			AbilityContainer.m_arrAbilities.AddItem(AbilityAvailableInfo);
		}
	}

	AbilityContainer.m_arrAbilities.Sort(AbilityContainer.SortAbilities);
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
	if (bEnableEnemyPreviewExtended)
	{
		return GetHitChanceForObjectRefExtended(TargetRef);
	}

	return super.GetHitChanceForObjectRef(TargetRef);
}

// For 'Extended Information!'
simulated function int GetHitChanceForObjectRefExtended(StateObjectReference TargetRef) {
	local AvailableAction Action;
	local ShotBreakdown Breakdown;
	local X2TargetingMethod TargetingMethod;
	local XComGameState_Ability AbilityState;
	local int AimBonus, HitChance;

	//`log(" UITacticalHUD_Enemies_Ex > GetHitChanceForObjectRefExtended TH_AIM_ASSIST=" $ GetTH_AIM_ASSIST() $ " DISPLAY_MISS_CHANCE=" $ getDISPLAY_MISS_CHANCE());

	//If a targeting action is active and we're hoving over the enemy that matches this action, then use action percentage for the hover  
	TargetingMethod = XComPresentationLayer(screen.Owner).GetTacticalHUD().GetTargetingMethod();

	if(TargetingMethod != none && TargetingMethod.GetTargetedObjectID() == TargetRef.ObjectID)
	{
		AbilityState = TargetingMethod.Ability;
	}
	else
	{			
		AbilityState = XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kAbilityHUD.GetCurrentSelectedAbility();

		if(AbilityState == None) {
			XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kAbilityHUD.GetDefaultTargetingAbility(TargetRef.ObjectID, Action, true);
			AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));
		}
	}

	if(AbilityState != none)
	{
		AbilityState.LookupShotBreakdown(AbilityState.OwnerStateObject, TargetRef, AbilityState.GetReference(), Breakdown);
		
		if(!Breakdown.HideShotBreakdown)
		{
			AimBonus = 0;
			HitChance = Breakdown.bIsMultishot ? Breakdown.MultiShotHitChance : Breakdown.FinalHitChance;
			if (GetTH_AIM_ASSIST()) {
				AimBonus =WOTC_DisplayHitChance_UITacticalHUD_ShotWings(UITacticalHUD(Screen).m_kShotInfoWings).GetModifiedHitChance(AbilityState, HitChance);
			}

			if (getDISPLAY_MISS_CHANCE())
				HitChance = 100 - (AimBonus + HitChance);
			else
				HitChance = AimBonus + HitChance;
				
			return Clamp(HitChance, 0, 100);
	    }
	}

	return -1;
}

`MCM_CH_VersionChecker(class'MCM_Defaults'.default.VERSION, class'WOTC_DisplayHitChance_MCMScreen'.default.CONFIG_VERSION)

function bool GetTH_AIM_ASSIST() {
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.TH_AIM_ASSIST, class'WOTC_DisplayHitChance_MCMScreen'.default.TH_AIM_ASSIST);
}

function bool GetDISPLAY_MISS_CHANCE() {
	return `MCM_CH_GetValue(class'MCM_Defaults'.default.DISPLAY_MISS_CHANCE, class'WOTC_DisplayHitChance_MCMScreen'.default.DISPLAY_MISS_CHANCE);
}
