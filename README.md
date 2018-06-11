gs_skilllevel
===============

This script adds support for skill level-specific .cfg files, which in turn can be used to implement HL:S skill level configs. Since "exec" is a blacklisted concommand, the script also includes a .cfg file reader to manually execute each command.

skill_manifest.cfg is still executed on change and maintains full compatibility.

#### Features
* [Fixed game.SetSkillLevel reverting to the "skill" convar's value](https://github.com/Facepunch/garrysmod-issues/issues/3491).
* [Added GM:OnSkillLevelChanged(number NewSkillLevel)](https://github.com/Facepunch/garrysmod-requests/issues/1149).
* Added cvars.ExecConfig(string File) - executes a file relative to ~/garrysmod/cfg/*.
* [Added Half-Life: Source skill files](https://github.com/Facepunch/garrysmod/pull/1497).
* [skill#.cfg is now run on skill level change](https://github.com/Facepunch/garrysmod-requests/issues/1148).

#### Developer Notes
* A "Think" hook with ID "game.SetSkillLevel" is used by this addon.
* Changes to the skill convar will not update game.GetSkillLevel or call the configs until the next tick due to [a bug with convar callbacks](https://github.com/Facepunch/garrysmod-issues/issues/3503).

Facepunch: https://gmod.facepunch.com/f/gmodaddon/bsyyr/Half-Life-Source-Skill-Levels-and-cfg-File-Reader/1/

GitHub: https://github.com/Kefta/gs_skilllevel
