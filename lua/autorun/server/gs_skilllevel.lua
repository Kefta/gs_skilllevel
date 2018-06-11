local function ExecConfig(sFile)
	local File = file.Open(string.format("cfg/%s", sFile), "rb", "GAME")

	if (File ~= nil) then
		local iSize = File:Size()

		-- File:EndOfFile() replacement
		while (File:Tell() < iSize) do
			local sLine = string.match(File:ReadLine(), "^%s*(.*)%s*$")
			local iComment = string.find(sLine, "//", 1, true)
			local iLen

			if (iComment == nil) then
				iLen = #sLine
			else
				iLen = iComment - 1
			end

			if (iLen == 0) then
				continue
			end

			local tArgs = {}
			local iArgs = 0
			local iCurPos = 1

			-- FIXME: This doesn't exactly replicate cfg quote/tab behaviour
			::Arg::
				local iStartArg, iEndArg

				if (string.sub(sLine, iCurPos, iCurPos) == '"') then
					iStartArg = iCurPos + 1
					iEndArg = string.find(sLine, '"', iStartArg, true)

					if (iEndArg == nil) then
						iCurPos = iLen
						iEndArg = iLen
					else
						iCurPos = iEndArg + 1
						iEndArg = iEndArg - 1
					end
				else
					iStartArg = iCurPos
					iEndArg = string.find(sLine, "[%s\"]", iCurPos)

					if (iEndArg == nil) then
						iCurPos = iLen
						iEndArg = iLen
					else
						iCurPos = iEndArg
						iEndArg = iEndArg - 1
					end
				end

				local sArg = string.sub(sLine, iStartArg, iEndArg)
				iArgs = iArgs + 1
				tArgs[iArgs] = sArg

				iCurPos = string.find(sLine, "[^%s]", iCurPos)

				if (iCurPos ~= nil) then
					goto Arg
				end

			-- Recursive exec calls
			if (string.match(tArgs[1], "^%s*(.*)%s*$") == "exec") then
				local sFile = tArgs[2]

				if (sFile ~= nil) then
					ExecConfig(sFile)
				end
			else
				RunConsoleCommand(unpack(tArgs, 1, iArgs))
			end
		end

		File:Close()
	end
end

local function CheckType(Val, iArg, nType, iLevel --[[= 2]])
	if (TypeID(Val) ~= nType) then
		if (iLevel == nil) then
			iLevel = 2
		end

		local sError = "bad argument #" .. iArg
		local tDebug = debug.getinfo(2, "n")

		if (tDebug ~= nil) then
			local sName = tDebug.name

			if (sName ~= nil) then
				sError = string.format("%s to '%s'", sError, sName)
			end
		end

		error(string.format("%s (number expected, got %s)", sError, type(iSkill)), 3)
	end
end

function cvars.ExecConfig(sFile)
	-- number->string coercion
	if (TypeID(sFile) == TYPE_NUMBER) then
		sFile = tostring(sFile)
	else
		CheckType(sFile, 1, TYPE_STRING)
	end

	ExecConfig(sFile)
end

local function CallSkillConfigs(iSkill)
	cvars.ExecConfig("skill_manifest.cfg")

	-- Use %d for int casting
	cvars.ExecConfig(string.format("skill%d.cfg", iSkill))

	-- https://github.com/Facepunch/garrysmod-requests/issues/1149
	hook.Run("OnSkillLevelChanged", iSkill)
end

local fSetSkillLevel = game._SetSkillLevel

-- Auto-refresh
if (fSetSkillLevel == nil) then
	fSetSkillLevel = game.SetSkillLevel
	game._SetSkillLevel = fSetSkillLevel
end

local iPrevSkillLevel
local skill = GetConVar("skill")

function game.SetSkillLevel(iSkill)
	-- Maintain string->number coercion
	if (TypeID(iSkill) == TYPE_STRING) then
		local num = tonumber(iSkill)

		if (num == nil) then
			CheckType(iSkill, 1, TYPE_NUMBER)
		else
			iSkill = num
		end
	else
		CheckType(iSkill, 1, TYPE_NUMBER)
	end

	-- Fix the skill level being reset by the skill convar
	RunConsoleCommand("skill", iSkill)

	-- FIXME: Have to do all this in SetSkillLevel
	-- since the skill convar doesn't get callbacks

	-- Get clamped skill int
	iSkill = skill:GetInt()
	iPrevSkillLevel = iSkill
	local iOldSkillLevel = game.GetSkillLevel()

	-- Call the old function regardless of changes
	fSetSkillLevel(iSkill)

	if (iSkill ~= iOldSkillLevel) then
		CallSkillConfigs(iSkill)
	end
end

-- FIXME: Check for changes to the skill convar manually since no callbacks
hook.Add("Think", "game.SetSkillLevel", function()
	local iSkill = skill:GetInt()

	if (iSkill ~= iPrevSkillLevel) then
		iPrevSkillLevel = iSkill
		fSetSkillLevel(iSkill)
		CallSkillConfigs(iSkill)
	end
end)

-- https://github.com/Facepunch/garrysmod-issues/issues/3503
--[[cvars.AddChangeCallback("skill", function(_, _, sSkill)
	local iSkill = tonumber(sSkill)

	if (iSkill ~= nil) then
		local iOldSkill = game.GetSkillLevel()

		-- Set the new skill level before calling configs
		-- in-case any of the convars being changed have
		-- callbacks that rely on skill level checks
		fSetSkillLevel(iSkill)

		-- Only call configs if the skill level is different
		if (iSkill ~= iOldSkill) then
			cvars.ExecConfig("skill_manifest.cfg")
			cvars.ExecConfig(string.format("skill%d.cfg", iSkill))
		end
	end
end, "game.SetSkillLevel")]]
