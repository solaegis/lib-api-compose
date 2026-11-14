[B][COLOR=da8a00]LibApiCompose[/COLOR][/B]

solaegis ESO library: SafeCall / SafeCallMulti, index walkers, and compose helpers for bag slots, gear facts, collectibles, quickslots, item OnUse previews, and companions.

[B]For addon authors[/B]
[LIST]
[*] Install this library once under AddOns/LibApiCompose
[*] Add to your manifest: [COLOR=2ea5f1]## DependsOn: LibApiCompose>=10000[/COLOR] (AddOnVersion for v1.0.0)
[*] Global: LibApiCompose (alias LAC)
[*] Read-only: no UseItem / write wrappers - products own secure calls
[/LIST]

[B]Versioning[/B]
[LIST]
[*] ## Version: semver (e.g. 1.0.0)
[*] ## AddOnVersion: encoded integer (1.0.0 -> 10000)
[/LIST]

[B]AI assistance[/B]
Development used AI assistance for scaffolding and documentation; all library code is reviewed and maintained by solaegis.

[B]Credits[/B]
Author: solaegis. Optional: LibDebugLogger.
