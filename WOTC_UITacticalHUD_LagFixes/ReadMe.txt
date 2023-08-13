Various performance fixes in the Tactical HUD:

- Greatly reduce number of ability array refreshes while visualizations are running. Huge cause of frame stutters, especially noticable when also using the 'Cost Based Ability Colors' mod.
- Cache hitchance calculations before sorting them, reducing the number of needed calculations even further.
- Reduce the number of unnecessary refreshes of the 'Objectives list' and 'Turn counter' HUD elements.
- (TODO) Reduce the number of unnecessary refreshes of Unit flags.

=====
STEAM Description: [WOTC] Tactical HUD Lag Fixes

https://steamcommunity.com/sharedfiles/filedetails/?id=3018494559
=====

[h1]Tactical HUD Lag Fixes - for War of the Chosen[/h1]

Various performance fixes in the Tactical HUD:
[list]
[*] Greatly reduce number of ability array refreshes while visualizations are running. Huge cause of frame stutters, especially noticable when also using the 'Cost Based Ability Colors' mod.
[*] Cache hitchance calculations before sorting them, reducing the number of needed calculations even further.
[*] Reduce the number of unnecessary refreshes of the 'Objectives list' and 'Turn counter' HUD elements.
[*] (TODO) Reduce the number of unnecessary refreshes of Unit flags.
[/list]

[h1]Compatibility[/h1]

[b]** Safe to add/remove mid-campaign. Safe to add/remove from a tactical save. **[/b]

This mod has [b]Mod Class Overrides[/b] for the following classes:
[list]
[*] UITacticalHUD_Enemies
[*] UITacticalHUD_AbilityContainer
[*] UITacticalHUD_Countdown
[*] UIObjectiveList
[/list]

All mods that use the same [b]Mod Class Override[/b] are incompatible, except for the ones listed below:

[h2]Using 'WOTC - Extended Information!'? [b]READ THIS:[/b][/h2]

You [b]MUST[/b] disable one of the ModClassOverrides of 'Extended Information!'. This mod automatically detects if you are using 'Extended Information!' and also uses its MCM config settings.
[list]
[*] Find the XComEngine.ini file for 'Extended Information!' (steamapps\workshop\content\268500\1183444470\Config\XComEngine.ini).
[*] Find the line [b]+ModClassOverrides=(BaseGameClass="UITacticalHUD_Enemies", ModClass="UITacticalHUD_Enemies_HitChance")[/b]
[*] Remove it, or comment it (put a [b];[/b] in front of it)
[/list]

[h2]Using '[WOTC] Unlimited Ability Icons'? [b]READ THIS:[/b][/h2]

Since recent updates, this mod [b]already includes[/b] the functionality of Unlimited Ability Icons. You [b]MUST[/b] remove or disable '[WOTC] Unlimited Ability Icons', you don't need it with this mod. It is safe to remove mid-campaign and from tactical saves.

Thanks -bg- for letting me include the functionality of Unlimited Ability Icons into this mod!

[h1]Issues[/h1]

Hopefully, these fixes can be merged into the Community Highlander at some point. Before that, these 'fixes' need more real-world testing.
That's why I pushed out this mod (my first), to gather feedback and fix potential issues before making their way into CHL.

Please report any issues you may find here or on discord (@ExitSign).

[h1]Credits[/h1]

Thanks to all the modders on the XCOM 2 Modding discord for answering my questions.
[list]
[*]Especially @Iridar and the great guides by @robojumper which helped me get started.
[*]-bg- for letting me include the unlimited ability icons functionality.
[/list]