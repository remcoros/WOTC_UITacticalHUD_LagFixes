class UITacticalHUD_AbilityContainer_Ex extends UITacticalHUD_AbilityContainer;

// The last History Index that was realized
var int LastRealizedIndex;
var bool m_arrAbilitiesChanged;
var array<UITacticalHUD_NestedAbilities> AdditionalPanel;

simulated function int GetNumberOfAbilityItems()
{
	return MAX_NUM_ABILITIES * (AdditionalPanel.Length + 1);
}

simulated private function SpawnNestedContainer()
{
	local int i, index;
	local UITacticalHUD_Ability kItem;

	index = AdditionalPanel.Length;
	AdditionalPanel.AddItem(ParentPanel.Spawn(class'UItacticalHUD_NestedAbilities', ParentPanel));

	AdditionalPanel[index].ParentPane = self;
	AdditionalPanel[index].ShiftIndex = MAX_NUM_ABILITIES * (index + 1);
	AdditionalPanel[index].MCName = name("AbilityContainerMC" $ (index + 2));
	AdditionalPanel[index].InitPanel();

	for(i = 0; i < MAX_NUM_ABILITIES; ++i)
	{	
		kItem = AdditionalPanel[index].Spawn(class'UITacticalHUD_Ability', AdditionalPanel[index]);
		kItem.InitAbilityItem(name("AbilityItem_" $ i));
		m_arrUIAbilities.AddItem(kItem);
	}

	AdditionalPanel[index].Hide();
}

simulated function UITacticalHUD_AbilityContainer InitAbilityContainer()
{
	super.InitAbilityContainer();

	SpawnNestedContainer();

	return self;
}

simulated function CycleAbilitySelectionRow(int step)
{
	local int index;
	local int totalStep;

	// Ignore if index was never set (e.g. nothing was populated.)
	if (m_iCurrentIndex == -1)
		return;

	totalStep = step;
	do
	{
		index = m_iCurrentIndex;
		index = (ActiveAbilities + (index + (totalStep * MAX_NUM_ABILITIES_PER_ROW_BAR))) % ActiveAbilities;

		if (index >= ActiveAbilities)
		{
			index = ActiveAbilities - 1;
		}

		while (IsCommmanderAbility(index) && index >= 0)
		{
			index--;
		}

		totalStep += step;
	}
	until(index >= 0 && index < ActiveAbilities);

	if(index != m_iCurrentIndex && index >= 0 && index < ActiveAbilities )
	{
		ResetMouse();
		SelectAbility( index );
	}
}

simulated function RefreshTutorialShine(optional bool bIgnoreMenuStatus = false)
{	
	local int i;
	
	if( !`REPLAY.bInTutorial ) return; 

	for( i = 0; i < m_arrUIAbilities.Length; ++i )
	{
		m_arrUIAbilities[i].RefreshShine(bIgnoreMenuStatus);
	}
}

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

    UpdateAbilitiesArrayImproved();
}

function UpdateAbilitiesArrayImproved()
{
	local int i;
	local int len;
	local X2GameRuleset Ruleset;
	local GameRulesCache_Unit UnitInfoCache;
	local array<AvailableAction> arrCommandAbilities;
	local int bCommanderAbility;
	local AvailableAction AbilityAvailableInfo; //Represents an action that a unit can perform. Usually tied to an ability.
	
	//Hide any AOE indicators from old abilities
	for (i = 0; i < m_arrAbilities.Length; i++)
	{
		HideAOE(i);
	}

	//Clear out the array 
	m_arrAbilities.Length = 0;

	// Loop through all abilities.
	Ruleset = `XCOMGAME.GameRuleset;
	Ruleset.GetGameRulesCache_Unit(XComTacticalController(PC).GetActiveUnitStateRef(), UnitInfoCache);

	len = UnitInfoCache.AvailableActions.Length;
	for(i = 0; i < len; i++)
	{	
		// Obtain unit's ability.
		AbilityAvailableInfo = UnitInfoCache.AvailableActions[i];

		if(ShouldShowAbilityIcon(AbilityAvailableInfo, bCommanderAbility))
		{
			//Separate out the command abilities to send to the CommandHUD, and do not want to show them in the regular list. 
			// Commented out in case we bring CommanderHUD back.
			if( bCommanderAbility == 1 )
			{
				arrCommandAbilities.AddItem(AbilityAvailableInfo);
			}

			//Add to our list of abilities 
			m_arrAbilities.AddItem(AbilityAvailableInfo);
		}
	}

	arrCommandAbilities.Sort(SortAbilities);
	m_arrAbilities.Sort(SortAbilities);
	
	m_arrAbilitiesChanged = true;

	PopulateFlash();

	if (m_iCurrentIndex < 0)
	{
		mc.FunctionNum("animateIn", m_arrAbilities.Length - arrCommandAbilities.Length);
	}
	UITacticalHUD(screen).m_kShotInfoWings.Show();
	
	if (`ISCONTROLLERACTIVE)
	{
		UITacticalHUD(screen).UpdateSkyrangerButton();
	}
	else
	{
		UITacticalHUD(screen).m_kMouseControls.SetCommandAbilities(arrCommandAbilities);
		UITacticalHUD(screen).m_kMouseControls.UpdateControls();
	}

	//  jbouscher: I am 99% certain this call is entirely redundant, so commenting it out
	//kUnit.UpdateUnitBuffs();

	// If we're in shot mode, then set the current ability index based on what (if anything) was populated.
	if( UITacticalHUD(screen).IsMenuRaised() && m_arrAbilities.Length > 0 )
	{
		if( m_iMouseTargetedAbilityIndex == -1 )
		{
			// MHU - We reset the ability selection if it's not initialized.
			//       We also define the initial shot determined in XGAction_Fire.
			//       Otherwise, retain the last selection.
			if (m_iCurrentIndex < 0)
				SetAbilityByIndex( 0 );
			else
				SetAbilityByIndex( m_iCurrentIndex );
		}
	}

	// Do this after assigning the CurrentIndex
	UpdateWatchVariables();
	CheckForHelpMessages();
	DoTutorialChecks();

	if (`ISCONTROLLERACTIVE)
	{
		//INS:
		if (m_iCurrentIndex >= 0 && m_arrAbilities[m_iCurrentIndex].AvailableTargets.Length > 1)
			m_arrAbilities[m_iCurrentIndex].AvailableTargets = SortTargets(m_arrAbilities[m_iCurrentIndex].AvailableTargets);
		else if (m_iPreviousIndexForSecondaryMovement >= 0 && m_arrAbilities[m_iPreviousIndexForSecondaryMovement].AvailableTargets.Length > 1)
			m_arrAbilities[m_iPreviousIndexForSecondaryMovement].AvailableTargets = SortTargets(m_arrAbilities[m_iPreviousIndexForSecondaryMovement].AvailableTargets);
	}
}

simulated function PopulateFlash()
{
	local bool isVisible;
	
	// Only populate flash when the abilities are changed, or when the UI was not visible
	isVisible = UITacticalHUD(Screen).bIsVisible && self.bIsVisible;

	if (!m_arrAbilitiesChanged && self.bIsVisible) return;

	m_arrAbilitiesChanged = false;
	PopulateFlashImproved();
}

simulated function PopulateFlashImproved()
{
	local int i, len, lastX;
	local AvailableAction AvailableActionInfo; //Represents an action that a unit can perform. Usually tied to an ability.
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;
	local UITacticalHUD_AbilityTooltip TooltipAbility;

	if (!bAbilitiesInited)
	{
		bAbilitiesInited = true;
		for (i = 0; i < m_arrUIAbilities.Length; i++)
		{
			if (!m_arrUIAbilities[i].bIsInited)
			{
				bAbilitiesInited = false;
				return;
			}
		}
	}

	if (!bIsInited)
	{
		return;
	}

	if (m_arrAbilities.Length < 0)
	{
		return;
	}

	//Process the number of abilities, verify that it does not violate UI assumptions
	len = m_arrAbilities.Length;

	while (len > GetNumberOfAbilityItems())
	{
		SpawnNestedContainer();
		//`log("NOT ENOUGH ABILITIES, SPAWNING MORE... NEW:" @ GetNumberOfAbilityItems(),, 'Ability30');
	}

	ActiveAbilities = 0;
	for( i = 0; i < len; i++ )
	{
		if (i >= m_arrAbilities.Length)
		{
			m_arrUIAbilities[i].ClearData();
			continue;
		}
		AvailableActionInfo = m_arrAbilities[i];

		AbilityState = XComGameState_Ability( `XCOMHISTORY.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
		AbilityTemplate = AbilityState.GetMyTemplate();
		
		if (AbilityTemplate.bCommanderAbility)
		{
			m_arrUIAbilities[i].ClearData();

			continue;
		}
		if(!AbilityTemplate.bCommanderAbility)
		{
			m_arrUIAbilities[ActiveAbilities].UpdateData(ActiveAbilities, AvailableActionInfo);
			ActiveAbilities++;
		}
	}

	mc.FunctionNum("SetNumActiveAbilities", min(ActiveAbilities, MAX_NUM_ABILITIES));
	if (ActiveAbilities > MAX_NUM_ABILITIES)
	{
		if (ActiveAbilities % MAX_NUM_ABILITIES >= MAX_NUM_ABILITIES_PER_ROW || ActiveAbilities % MAX_NUM_ABILITIES == 0)
		{
			// move the icon full width
			lastX = 640;
		}
		else
		{
			// move the icon based on remainder
			lastX = 940 - ((ActiveAbilities % MAX_NUM_ABILITIES_PER_ROW) * 20);
		}

		lastX -= (300 * ((ActiveAbilities - 1) / MAX_NUM_ABILITIES));

		SetPosition(lastX, 1010);
		RealizeLocation();

		for ( i = 0; i < AdditionalPanel.Length; i++ )
		{
			if (ActiveAbilities - (MAX_NUM_ABILITIES * (i + 1)) > 0)
			{
				AdditionalPanel[i].mc.FunctionNum("SetNumActiveAbilities", min(ActiveAbilities - (MAX_NUM_ABILITIES * (i + 1)), MAX_NUM_ABILITIES));
				lastX = lastX + 660;
				AdditionalPanel[i].SetPosition(lastX, 1010);
				AdditionalPanel[i].RealizeLocation();
				AdditionalPanel[i].Show();
			}
			else
			{
				AdditionalPanel[i].mc.FunctionNum("SetNumActiveAbilities", 0);
				AdditionalPanel[i].Hide();
			}
		}
	}
	else
	{
		for ( i = 0; i < AdditionalPanel.Length; i++ )
		{
			AdditionalPanel[i].mc.FunctionNum("SetNumActiveAbilities", 0);
			AdditionalPanel[i].Hide();
		}
	}
	
	if (ActiveAbilities > MAX_NUM_ABILITIES_PER_ROW)
	{
		UITacticalHUD(Owner).m_kShotHUD.MC.FunctionVoid("AbilityOverrideAnimateIn");
		UITacticalHUD(Owner).m_kEnemyTargets.MC.FunctionBool("SetMultirowAbilities", true);
		UITacticalHUD(Owner).m_kEnemyPreview.MC.FunctionBool("SetMultirowAbilities", true);
	}
	else
	{
		UITacticalHUD(Owner).m_kShotHUD.MC.FunctionVoid("AbilityOverrideAnimateOut");
		UITacticalHUD(Owner).m_kEnemyTargets.MC.FunctionBool("SetMultirowAbilities", false);
		UITacticalHUD(Owner).m_kEnemyPreview.MC.FunctionBool("SetMultirowAbilities", false);
	}

	//bsg-jneal (3.2.17): set the gamepadIcon where we populate flash
	if(`ISCONTROLLERACTIVE)
	{
		mc.FunctionString("SetHelp", class'UIUtilities_Input'.const.ICON_RT_R2);
	}

	Show();
	
	// Refresh the ability tooltip if it's open
	TooltipAbility = UITacticalHUD_AbilityTooltip(Movie.Pres.m_kTooltipMgr.GetChildByName('TooltipAbility'));
	if(TooltipAbility != none && TooltipAbility.bIsVisible)
		TooltipAbility.RefreshData();
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

defaultproperties
{
	bAnimateOnInit = false;
}
