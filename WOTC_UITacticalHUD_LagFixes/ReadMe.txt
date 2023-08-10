TODO: ReadMe.txt

Various performance fixes in the Tactical HUD:

- Greatly reduce number of ability array refreshes while visualizations are running. Huge cause of frame stutters, especially noticable when also using the 'Cost Based Ability Colors' mod.
- Cache hitchance calculations before sorting them, reducing the number of needed calls even further.
- Reduce the number of unnecessary refreshes of the 'Objectives list' and 'Turn counter' HUD elements.
- (TODO) Reduce the number of unnecessary refreshes of Unit flags.