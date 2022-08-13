--[[

Custom record for site
Custom record for bomb

OnObjectActivate for plant
    Position bomb based on site location
    start bomb timer
    play plate voiceline to everyone

plant Timer
    Message box/other voicelines?
    spawn sub timers
    brown team wins
    Push players away
    Apply damage

OnObjectActivate for defuse
    disable player controls while defuse?
    timer for defuse

defuse timer
    cancel plant timer
    blue team wins

]]

local plateWars = {}

local logPrefix = "Plate Wars: "

platewarsMaps = require("custom/plateWars/platewarsMaps")

matchID = nil
roundID = nil
roundcounter = 0
-- used to track the score for each team
teamScores = nil
-- used to track the number of players on each team
teamCounters = nil
-- used to hold data about the next match
nextMatch = nil
-- unique identifier for match
matchId = nil
-- holds the list of all match-specific variables
matchSettings = nil
teamIndex = nil
currentMatch = platewarsMaps.balmora


plateWars.config = {}
plateWars.config.roundsPerMatch = 5
plateWars.config.freezeTime = 5

plateWars.teams = {}
plateWars.teams.baseData = {}
plateWars.teams.bluePlatesPids = {}
plateWars.teams.brownPlatesPids = {}

plateWars.teams.uniforms = {{"expensive_shirt_02", "expensive_pants_02", "expensive_shoes_02"}, {"expensive_shirt_01", "expensive_pants_01", "expensive_shoes_01"}}

plateWars.teams.baseData = {
    maxPlayersPerTeam = 3,
    bluePlatesSpawnPoint = {-22598, -15301, 505},
    brownPlatesSpawnPoint = {-23598, -16301, 505}
}

plateWars.bomb = {}
plateWars.bomb.baseData = {}
plateWars.bomb.commands = {}
plateWars.bomb.config = {}
plateWars.bomb.records = {}
plateWars.bomb.refIds = {}

plateWars.bomb.refIds = {
    explosionSpell = "de_bomb_explosion",
    inventoryItem = "de_bomb_item_01",
    worldObject = "de_bomb_01"
}

plateWars.bomb.baseData = {
    plantTime = 3,
    defuseTime = 8,
    tickTime = 45,
    tickTimeIncrement = 5,
    tickTimer = nil,
    plantTimer = nil,
    defuseTimer = nil,
    plantingPid = -1,
    defusingPid = -1,
    carrierPid = -1
}

plateWars.bomb.commands = {
    explode = "ExplodeSpell " .. plateWars.bomb.refIds.explosionSpell
}

plateWars.bomb.config = {}

plateWars.bomb.config.explosionSpell = {
    impactArea = 50, -- determines size of area that will be affected by the explosion, in feet, where 1 feet = about 21 units
    impactMinDamage = 100, -- determines how much damage should be dealt to players at MIN
    impactMaxDamage = 100, -- determines how much damage should be dealth to players at MAX
    affiliatedDuration = 5, -- how long will the damage over time last
    affiliatedMinDamage = 10, -- how much damage will be dealt per tick at MIN
    affiliatedMaxDamage = 10, -- how much damage will be dealt per tick at MAX
}

plateWars.bomb.records = {}

plateWars.bomb.records[plateWars.bomb.refIds.explosionSpell] = {
    type = "spell",
    data = {
        name = "Bomb Explosion",
        subytpe = 0,
        cost = 0,
        flags = 65536, -- shouldn't be reflectable
        effects = {
            {
                attribute = -1, -- idk what this does
                area = plateWars.bomb.config.explosionSpell.impactArea, -- measured in feet, 1 feet = about 21 units
                duration = 0, -- one time effect
                id = 14, -- Fire Damage
                rangeType = 0, -- On self/touch/target
                skill = -1, -- idk what this does
                magnitudeMin = plateWars.bomb.config.explosionSpell.impactMinDamage, -- amount of minimum damage
                magnitudeMax = plateWars.bomb.config.explosionSpell.impactMaxDamage -- amount of maximum damage
            },
            {
                attribute = -1,
                area = 0,
                duration = plateWars.bomb.config.explosionSpell.affiliatedDuration, -- in seconds
                id = 23, -- Damage Health
                rangeType = 0,
                skill = -1,
                magnitudeMin = plateWars.bomb.config.explosionSpell.affiliatedMinDamage,
                magnitudeMax = plateWars.bomb.config.explosionSpell.affiliatedMaxDamage
            }
        }
    }
}

plateWars.bomb.records[plateWars.bomb.refIds.inventoryItem] = {
    type = "miscellaneous",
    data = {
        model = "m\\dwemer_satchel00.nif",
        icon = "m\\misc_dwe_satchel00.dds",
        name = "Plate Buster"
    }
}

plateWars.bomb.records[plateWars.bomb.refIds.worldObject] = {
    type = "activator",
    data = {
        model = "m\\dwemer_satchel00.nif",
        name = "Plate Buster"
    }
}

plateWars.bombSites = {}
plateWars.bombSites.baseData = {}
plateWars.bombSites.records = {}
plateWars.bombSites.refIds = {}

plateWars.bombSites.refIds = {
    site01 = "de_site_01",
    site02 = "de_site_02"
}

plateWars.bombSites.baseData[plateWars.bombSites.refIds.site01] = {
    bombPositionOffset = {
        posX = 0,
        posY = 0,
        posZ = 34.666,
        rotX = 0,
        rotY = 0,
        rotZ = 0
    }
}

plateWars.bombSites.baseData[plateWars.bombSites.refIds.site02] = {
    bombPositionOffset = {
        posX = 0,
        posY = 0,
        posZ = 34.666,
        rotX = 0,
        rotY = 0,
        rotZ = 0
    }
}

plateWars.bombSites.records = {}

plateWars.bombSites.records[plateWars.bombSites.refIds.site01] = {
    type = "activator",
    data = {
        model = "o\\contain_crate_01.nif",
        name = "Blue Plate Stash A"
    }
}

plateWars.bombSites.records[plateWars.bombSites.refIds.site02] = {
    type = "activator",
    data = {
        model = "o\\contain_crate_01.nif",
        name = "Blue Plate Stash B"
    }
}

plateWars.sounds = {}
plateWars.sounds.baseData = {}
plateWars.sounds.commands = {}
plateWars.sounds.refIds = {}
plateWars.sounds.records = {}

plateWars.sounds.refIds = {
    bluePlatesWin = "de_s_bm_hello_17",
    brownPlatesWin = "de_s_bm_idle_2",
    bombPlanted = "de_s_bm_idle_6",
    bombTenSecondsLeft = "de_s_bm_attack_7",
    bombNoDefuseTime = "de_s_bm_attack_15",
    bombTick = "de_s_bomb_tick",
    bombDefuseStart = "de_s_bomb_defuse_start"
}

plateWars.sounds.baseData = {
    defaultLocalVolume = 100,
    defaultLocalPitch = 1,
    defaultLocalForEveryone = true,
    defaultGlobalVolume = 100,
    defaultGlobalPitch = 1,
    defaultGlobalForEveryone = true
}

plateWars.sounds.commands = {
    playLocal = "PlaySound3DVP ",
    playGlobal = "PlaySoundVP "
}

plateWars.sounds.records[plateWars.sounds.refIds.bluePlatesWin] = {
    type = "sound",
    data = {
        sound = "Vo\\b\\m\\Hlo_BM017.mp3" --What a revolting display
    }
}

plateWars.sounds.records[plateWars.sounds.refIds.brownPlatesWin] = {
    type = "sound",
    data = {
        sound = "Vo\\b\\m\\Idl_BM002.mp3" --The blue plates are nice but the brown ones seem to last longer
    }
}

plateWars.sounds.records[plateWars.sounds.refIds.bombPlanted] = {
    type = "sound",
    data = {
        sound = "Vo\\b\\m\\Idl_BM006.mp3" --*Whistles*
    }
}

plateWars.sounds.records[plateWars.sounds.refIds.bombDefuseStart] = {
    type = "sound",
    data = {
        sound = "Fx\\item\\spear.wav" --Bomb is being defused
    }
}

plateWars.sounds.records[plateWars.sounds.refIds.bombTick] = {
    type = "sound",
    data = {
        sound = "Fx\\item\\ring.wav" --Bomb tick sound
    }
}

plateWars.sounds.records[plateWars.sounds.refIds.bombTenSecondsLeft] = {
    type = "sound",
    data = {
        sound = "Vo\\b\\m\\Atk_BM007.mp3" --Not Long Now
    }
}

plateWars.sounds.records[plateWars.sounds.refIds.bombNoDefuseTime] = {
    type = "sound",
    data = {
        sound = "Vo\\b\\m\\Atk_BM015.mp3" --Run while you can
    }
}

function plateWars.startMatch()
    tes3mp.LogMessage(enumerations.log.INFO, logPrefix .. "Match started")
    matchID = "m" .. tostring(os.time())
    plateWars.sortPlayersIntoTeams()
    plateWars.startRound()
end

function plateWars.endMatch()
    tes3mp.LogMessage(enumerations.log.INFO, logPrefix .. "Match " .. matchID .. " has ended")
    matchID = nil
    roundcounter = 0
end

function plateWars.startRound()
    roundID = "r" .. tostring(os.time())
    roundcounter = roundcounter + 1
    plateWars.spawnTeams()
    plateWars.startFreezeTime()
    plateWars.teamAddBombRandom()
end

function plateWars.endRound()
  --roundID = nil
  if roundcounter < plateWars.config.roundsPerMatch then
    plateWars.startRound()
  else
    plateWars.endMatch()
  end
end


function plateWars.sortPlayersIntoTeams()
    -- add player to brown team only when blue team has more players
    for pid, player in pairs(Players) do
        if #plateWars.teams.bluePlatesPids > #plateWars.teams.brownPlatesPids then
            plateWars.teamJoinBrownPlates(pid)
        else
            plateWars.teamJoinBluePlates(pid)
            tes3mp.LogMessage(enumerations.log.INFO, logPrefix .. "Adding player to brown team")
        end
    end
end

function plateWars.spawnTeams()
    tes3mp.LogMessage(enumerations.log.INFO, logPrefix .. "Spawning players")
    for pid, player in pairs(Players) do
        if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
            plateWars.spawnPlayer(pid)
        end
    end
end

function plateWars.spawnPlayer(pid)
    plateWars.teamIsBluePlate(pid)
    plateWars.teamIsBrownPlate(pid)
    math.random(1, 7) -- Improves RNG? LUA's random isn't great
    math.random(1, 7)
    local randomLocationIndex = math.random(1, 7)
    local possibleSpawnLocations = {}
    possibleSpawnLocations = currentMatch.teamSpawnLocations[teamIndex]
    tes3mp.LogMessage(2, "++++ Spawning player at team ".. teamIndex .. " spawnpoint #" .. randomLocationIndex .. " ++++")
    -- if plateWars.teamIsBluePlate(pid) then
    --     plateWars.equipUniforms(pid)
    --     tes3mp.SetPos(pid, plateWars.teams.baseData.bluePlatesSpawnPoint[1], plateWars.teams.baseData.bluePlatesSpawnPoint[2], plateWars.teams.baseData.bluePlatesSpawnPoint[3])
    -- else
    --     plateWars.equipUniforms(pid)
    --     tes3mp.SetPos(pid, plateWars.teams.baseData.brownPlatesSpawnPoint[2], plateWars.teams.baseData.brownPlatesSpawnPoint[2], plateWars.teams.baseData.brownPlatesSpawnPoint[3])
    -- end
    plateWars.equipUniforms(pid)
    tes3mp.SetCell(pid, possibleSpawnLocations[randomLocationIndex][1])
  	tes3mp.SendCell(pid)
  	tes3mp.SetPos(pid, possibleSpawnLocations[randomLocationIndex][2], possibleSpawnLocations[randomLocationIndex][3], possibleSpawnLocations[randomLocationIndex][4])
  	tes3mp.SetRot(pid, 0, possibleSpawnLocations[randomLocationIndex][5])
  	tes3mp.SendPos(pid)
    -- tes3mp.SendCell(pid)
    -- tes3mp.SendPos(pid)
    -- plateWars.LoadPlayerItems(pid)
end

function plateWars.equipUniforms(pid)
    local race = string.lower(Players[pid].data.character.race)
    if race ~= "argonian" and race ~= "khajiit" then
        Players[pid].data.equipment[7] = { refId = plateWars.teams.uniforms[teamIndex][3], count = 1, charge = -1 }
    end
      -- give shirt
    Players[pid].data.equipment[8] = { refId = plateWars.teams.uniforms[teamIndex][1], count = 1, charge = -1 }
      --give pants
    Players[pid].data.equipment[9] = { refId = plateWars.teams.uniforms[teamIndex][2], count = 1, charge = -1 }
end

function plateWars.LoadPlayerItems(pid)
    Players[pid]:Save()
	  Players[pid]:LoadInventory()
	  Players[pid]:LoadEquipment()
end

function plateWars.startFreezeTime()
    freezeTimer = tes3mp.CreateTimerEx("endFreezeTime", time.seconds(plateWars.config.freezeTime), "i", 1)
    tes3mp.StartTimer(freezeTimer)
    for pid, player in pairs(Players) do
        if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
            plateWars.disablePlayerControls(pid)
        end
    end
end

function endFreezeTime()
    for pid, player in pairs(Players) do
        if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
            plateWars.enablePlayerControls(pid)
        end
    end
end

--TODO add message informing player of failed/successful join
function plateWars.teamJoin(pid, teamPidsTable)
    if not tableHelper.containsValue(plateWars.teams.bluePlatesPids, pid) and not tableHelper.containsValue(plateWars.teams.brownPlatesPids, pid) then
        if #teamPidsTable < plateWars.teams.baseData.maxPlayersPerTeam then
            table.insert(teamPidsTable, pid)
        end
    end
end

function plateWars.teamJoinBluePlates(pid)
    plateWars.teamJoin(pid, plateWars.teams.bluePlatesPids)
end

function plateWars.teamJoinBrownPlates(pid)
    plateWars.teamJoin(pid, plateWars.teams.brownPlatesPids)
end

function plateWars.teamLeave(pid)
    if plateWars.teamIsBluePlate(pid) then
        tableHelper.removeValue(plateWars.teams.bluePlatesPids, pid)
    elseif plateWars.teamIsBrownPlate(pid) then
        tableHelper.removeValue(plateWars.teams.brownPlatesPids, pid)
    end
end

function plateWars.teamIsBluePlate(pid)
    teamIndex = 1
    return tableHelper.containsValue(plateWars.teams.bluePlatesPids, pid)
end

function plateWars.teamIsBrownPlate(pid)
    teamIndex = 2
    return tableHelper.containsValue(plateWars.teams.brownPlatesPids, pid)
end

function plateWars.teamAddBomb(pid)
    inventoryHelper.addItem(Players[pid].data.inventory, plateWars.bomb.refIds.inventoryItem, 1, -1, -1, "")
    Players[pid]:LoadItemChanges({{refId = plateWars.bomb.refIds.inventoryItem, count = 1, charge = -1, enchantmentCharge = -1, soul = ""}}, enumerations.inventory.ADD)
    plateWars.bomb.baseData.carrierPid = pid
end

function plateWars.teamAddBombRandom()
    math.randomseed(os.time())
    local randomIndex = math.random(#plateWars.teams.brownPlatesPids)
    plateWars.teamAddBomb(plateWars.teams.brownPlatesPids[randomIndex])
end

function plateWars.bombPlayTickSound(cellDescription, bombIndex)
    plateWars.playSoundLocal(tableHelper.getAnyValue(Players).pid, cellDescription, {bombIndex}, plateWars.sounds.refIds.bombTick)
end

function plateWars.bombPlayDefuseStartSound(cellDescription, bombIndex)
    plateWars.playSoundLocal(tableHelper.getAnyValue(Players).pid, cellDescription, {bombIndex}, plateWars.sounds.refIds.bombDefuseStart)
end

function plateWars.bombExplode(cellDescription, bombIndex)
    logicHandler.RunConsoleCommandOnObjects(tableHelper.getAnyValue(Players).pid, plateWars.bomb.commands.explode, cellDescription, {bombIndex}, true)
end

function plateWars.onBombDefused(cellDescription, bombIndex)
    plateWars.bomb.baseData.defusingPid = -1
    if plateWars.bomb.baseData.tickTimer ~= nil then
        tes3mp.StopTimer(plateWars.bomb.baseData.tickTimer)
    end
    plateWars.announcement(color.Blue .. "What a revolting display", plateWars.sounds.refIds.bluePlatesWin)
    logicHandler.DeleteObjectForEveryone(cellDescription, bombIndex)
    tes3mp.LogMessage(enumerations.log.INFO, logPrefix .. "Bomb defused, blue team wins")
    --TODO: Handle round win for blue
end

function plateWars.playSoundLocal(pid, cellDescription, objectIndexes, sound, volume, pitch, forEveryone) -- Play sound from object, the closer the player is the louder the sound and vice versa
    local soundVolume = tonumber(volume) or plateWars.sounds.baseData.defaultLocalVolume
    local soundPitch = tonumber(pitch) or plateWars.sounds.baseData.defaultLocalPitch
    local soundForEveryone = forEveryone or plateWars.sounds.baseData.defaultLocalForEveryone
    logicHandler.RunConsoleCommandOnObjects(pid, plateWars.sounds.commands.playLocal .. sound .. " " .. tostring(soundVolume) .. " " .. tostring(soundPitch), cellDescription, objectIndexes, soundForEveryone)
end

function plateWars.playSoundGlobal(pid, sound, volume, pitch, forEveryone) -- Play sound directly for player or players
    local soundVolume = tonumber(volume) or plateWars.sounds.baseData.defaultGlobalVolume
    local soundPitch = tonumber(pitch) or plateWars.sounds.baseData.defaultGlobalPitch
    local soundForEveryone = forEveryone or plateWars.sounds.baseData.defaultGlobalForEveryone
    logicHandler.RunConsoleCommandOnPlayer(pid, plateWars.sounds.commands.playGlobal .. sound .. " " .. tostring(soundVolume) .. " " .. tostring(soundPitch), soundForEveryone)
end

function plateWars.announcement(message, sound)
    --Just making the assumption that all players are in the game, can replace with teams if needed
    if sound ~= nil then
        plateWars.playSoundGlobal(tableHelper.getAnyValue(Players).pid, sound)
    end

    for pid, player in pairs(Players) do
        if message ~= nil then
            tes3mp.MessageBox(pid, -1, message)
        end
    end
end

function plateWars.onBombExplode(cellDescription, bombIndex)
    if plateWars.bomb.baseData.defuseTimer ~= nil then
        tes3mp.StopTimer(plateWars.bomb.baseData.defuseTimer)
        plateWars.enablePlayerControls(plateWars.bomb.baseData.defusingPid)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix .. logicHandler.GetChatName(plateWars.bomb.baseData.defusingPid) .. " stopped defusing because there was no time left")
        plateWars.bomb.baseData.defusingPid = -1
    end

    plateWars.bombExplode(cellDescription, bombIndex)
    logicHandler.DeleteObjectForEveryone(cellDescription, bombIndex)
    tes3mp.LogMessage(enumerations.log.INFO, logPrefix .. "Bomb exploded, brown team wins")
    plateWars.announcement(color.Brown .. "The blue plates are nice but the brown ones seem to last longer", plateWars.sounds.refIds.brownPlatesWin)
    --TODO: Handle round win for brown
    plateWars.endRound()
end

function plateWars.getBombPos(sitePos, offset)
    local bombPos = {}
    for key,value in pairs(offset) do
        bombPos[key] = sitePos[key] + value
    end
    return bombPos
end

function plateWarsBombTimer(timeLeft, cellDescription, bombIndex)
    if timeLeft > 0 then
        --Just making the assumption that all players are in the game, can replace with teams if needed
        plateWars.announcement(color.Brown .. timeLeft .. " seconds till plate destruction")
        plateWars.bombPlayTickSound(cellDescription, bombIndex)

        if timeLeft > 10 then
            plateWars.bomb.baseData.tickTimer = tes3mp.CreateTimerEx("plateWarsBombTimer", 1000*plateWars.bomb.baseData.tickTimeIncrement, "iss", timeLeft-plateWars.bomb.baseData.tickTimeIncrement, cellDescription, bombIndex)
            tes3mp.StartTimer(plateWars.bomb.baseData.tickTimer)
        else
            if timeLeft == 10 then
                plateWars.announcement(color.Brown .. "Not Long Now", plateWars.sounds.refIds.bombTenSecondsLeft)
            elseif timeLeft == plateWars.bomb.baseData.defuseTime-1 then
                plateWars.announcement(color.Brown .. "Run while you can", plateWars.sounds.refIds.bombNoDefuseTime)
            end

            plateWars.bomb.baseData.tickTimer = tes3mp.CreateTimerEx("plateWarsBombTimer", 1000*1, "iss", timeLeft-1, cellDescription, bombIndex)
            tes3mp.StartTimer(plateWars.bomb.baseData.tickTimer)
        end
    else
        plateWars.onBombExplode(cellDescription, bombIndex)
    end
end

function plateWarsPlantedTimer(pid, cellDescription, uniqueIndex, refId)
    local bombPosOffset = plateWars.bombSites.baseData[refId].bombPositionOffset
    local sitePos = {}
    local bombPos = {}

    if LoadedCells[cellDescription].data.objectData[uniqueIndex].location ~= nil then
        sitePos = LoadedCells[cellDescription].data.objectData[uniqueIndex].location
    else
        return
    end

    bombPos = plateWars.getBombPos(sitePos, bombPosOffset)
    local bombIndex = logicHandler.CreateObjectAtLocation(cellDescription, bombPos, {refId = plateWars.bomb.refIds.worldObject, count = 1,charge = -1, enchantmentCharge = -1, soul = ""}, "place")
    plateWars.removeBomb(pid)
    plateWars.enablePlayerControls(pid)
    plateWars.bomb.baseData.plantingPid = -1
    tes3mp.LogMessage(enumerations.log.INFO, logPrefix .. logicHandler.GetChatName(pid) .. " finished planting the bomb at " .. refId.. "(" ..uniqueIndex .. ") in cell " .. cellDescription)
    tes3mp.MessageBox(pid, -1, color.Green .. "You finished planting the Plate Buster")
    plateWars.announcement(color.Brown .. "*Whistles*", plateWars.sounds.refIds.bombPlanted)

    plateWars.bomb.baseData.tickTimer = tes3mp.CreateTimerEx("plateWarsBombTimer",1000*plateWars.bomb.baseData.tickTimeIncrement, "iss", plateWars.bomb.baseData.tickTime-plateWars.bomb.baseData.tickTimeIncrement, cellDescription, bombIndex)
    tes3mp.StartTimer(plateWars.bomb.baseData.tickTimer)
    --TODO: Play abnoxious voice line?
end

function plateWarsDefusedTimer(pid, cellDescription, uniqueIndex)
    plateWars.enablePlayerControls(pid)
    plateWars.onBombDefused(cellDescription, uniqueIndex)
end

function plateWars.hasBomb(pid)
    return  plateWars.bomb.baseData.carrierPid == pid
end

function plateWars.removeBomb(pid)
    inventoryHelper.removeItem(Players[pid].data.inventory, plateWars.bomb.refIds.inventoryItem, 1, -1, -1, "")
    Players[pid]:LoadItemChanges({{refId = plateWars.bomb.refIds.inventoryItem, count = 1, charge = -1, enchantmentCharge = -1, soul = ""}},enumerations.inventory.REMOVE)
    plateWars.bomb.baseData.carrierPid = -1
end

function plateWars.dropBomb(pid)
    local cell = tes3mp.GetCell(pid)
    local location = {
        posX = tes3mp.GetPosX(pid), posY = tes3mp.GetPosY(pid), posZ = tes3mp.GetPosZ(pid),
        rotX = tes3mp.GetRotX(pid), rotY = 0, rotZ = tes3mp.GetRotZ(pid)
    }
    --drop bomb above player's corpse
    location.posZ = location.posZ + 15

    plateWars.removeBomb(pid)
    logicHandler.CreateObjectAtLocation(cell, location, {refId = plateWars.bomb.refIds.inventoryItem, count = 1, charge = -1, enchantmentCharge = -1, soul = ""}, "place")
end

function plateWars.disablePlayerControls(pid)
    logicHandler.RunConsoleCommandOnPlayer(pid,"DisablePlayerControls")
end

function plateWars.enablePlayerControls(pid)
    logicHandler.RunConsoleCommandOnPlayer(pid,"EnablePlayerControls")
end

function plateWars.handleDefuse(pid, cellDescription, object)
    -- Only blue plates can defuse
    if not plateWars.teamIsBluePlate(pid) then
        return
    end

    if plateWars.bomb.baseData.defusingPid ~= -1 then
        tes3mp.MessageBox(pid, -1, color.Red .. "Someone else is already defusing")
    else
        --Begin Defuse
        plateWars.disablePlayerControls(pid)
        plateWars.bomb.baseData.defusingPid = pid
        plateWars.bombPlayDefuseStartSound(cellDescription, object.uniqueIndex)
        plateWars.bomb.baseData.defuseTimer = tes3mp.CreateTimerEx("plateWarsDefusedTimer",1000 * plateWars.bomb.baseData.defuseTime, "iss", pid, cellDescription, object.uniqueIndex)
        tes3mp.StartTimer(plateWars.bomb.baseData.defuseTimer)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." started defusing the bomb: "..object.uniqueIndex.." in cell "..cellDescription)
        tes3mp.MessageBox(pid, -1, color.Green.."You have begun defusing the Plate Buster")
    end
end

function plateWars.handlePlant(pid, cellDescription, object)
    --TODO: Add check if player is on the brown team
    -- This check shouldn't be neccessary as only brown team can be assigned bomb
    if plateWars.hasBomb(pid) then
        --Begin planting
        plateWars.disablePlayerControls(pid)
        plateWars.bomb.baseData.plantingPid = pid
        plateWars.bomb.baseData.plantTimer = tes3mp.CreateTimerEx("plateWarsPlantedTimer",1000 * plateWars.bomb.baseData.plantTime, "isss", pid, cellDescription, object.uniqueIndex, object.refId)
        tes3mp.StartTimer(plateWars.bomb.baseData.plantTimer)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." started planting the bomb at "..object.refId.."("..object.uniqueIndex..") in cell "..cellDescription)
        tes3mp.MessageBox(pid, -1, color.Green.."You have begun planting the Plate Buster")
    else
        tes3mp.MessageBox(pid, -1, color.Red.."You do not have the Plate Buster")
    end
end

-- Prevent inventory bomb from being dropped into the world regularly
function plateWars.OnObjectPlaceValidator(eventStatus, pid, cellDescription, objects, targetPlayers)
    for _, object in pairs(objects) do
        if object.refId == plateWars.bomb.refIds.inventoryItem then
            return customEventHooks.makeEventStatus(false, false)
        end
    end
end

-- Prevent inventory bomb from being removed regularly, ie. by dragging and dropping it into the world
function plateWars.OnPlayerInventoryValidator(eventStatus, pid, playerPacket)
    if playerPacket.action == enumerations.inventory.REMOVE then
        for _, item in ipairs(playerPacket.inventory) do
            -- Allow the inventory bomb to be removed from planting, dead or disconnecting pid's inventory
            if pid ~= plateWars.bomb.baseData.plantingPid and Players[pid].forceRemoveBomb == nil and item.refId == plateWars.bomb.refIds.inventoryItem then
                Players[pid]:LoadItemChanges({{refId = plateWars.bomb.refIds.inventoryItem, count = 1, charge = -1, enchantmentCharge = -1, soul = ""}},enumerations.inventory.ADD)
                return customEventHooks.makeEventStatus(false, false)
            end
        end
    end
end

function plateWars.OnObjectActivateHandler(eventStatus, pid, cellDescription, objects, targetPlayers)
    if eventStatus.validCustomHandlers ~= false and eventStatus.validDefaultHandler ~= false then
        for _,object in pairs(objects) do
            if plateWars.bombSites.baseData[object.refId] ~= nil then
                --The player activated one of the sites
                plateWars.handlePlant(pid, cellDescription, object)
            end
            if object.refId == plateWars.bomb.refIds.worldObject then
                --The Player activated an armed bomb
                plateWars.handleDefuse(pid, cellDescription, object)
            end
        end
    end
end

function plateWars.OnServerPostInitHandler()
    for _, refId in pairs(plateWars.bomb.refIds) do
        local record = plateWars.bomb.records[refId]
        RecordStores[record.type].data.permanentRecords[refId] = tableHelper.deepCopy(record.data)
    end

    for _, refId in pairs(plateWars.bombSites.refIds) do
        local record = plateWars.bombSites.records[refId]
        RecordStores[record.type].data.permanentRecords[refId] = tableHelper.deepCopy(record.data)
    end

    for _, refId in pairs(plateWars.sounds.refIds) do
        local record = plateWars.sounds.records[refId]
        RecordStores[record.type].data.permanentRecords[refId] = tableHelper.deepCopy(record.data)
    end
    tes3mp.LogMessage(enumerations.log.INFO, logPrefix .. "Script running")
end

function plateWars.OnDeathTimeExpirationHandler(eventStatus, pid)
    tes3mp.LogAppend(enumerations.log.INFO, "------------------------- " .. "top of OnDeathTimeExpiration")
    tes3mp.LogAppend(enumerations.log.INFO, "------------------------- " .. "OnDeathTimeExpiration pid: " .. pid)
    -- figure out why this isn't true
    if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
        tes3mp.LogAppend(enumerations.log.INFO, "------------------------- " .. "in the if")
		    tes3mp.LogMessage(2, "++++ Respawning pid: ", pid)
		    tes3mp.Resurrect(pid, 0)
        -- plateWars.startMatch()
    end
    tes3mp.LogAppend(enumerations.log.INFO, "------------------------- " .. "bottom of OnDeathTimeExpiration")
end

function plateWars.OnPlayerDeathHandler(eventStatus, pid)
    tes3mp.LogAppend(enumerations.log.INFO, "------------------------- " .. "onplayerdeath pid: " .. pid)
    -- Players[pid].data.mwTDM.status = 0	-- Player is dead and not safe for teleporting
    -- Players[pid].data.mwTDM.deaths = Players[pid].data.mwTDM.deaths + 1
    -- Players[pid].data.mwTDM.totalDeaths = Players[pid].data.mwTDM.totalDeaths + 1
    -- Players[pid].data.mwTDM.spree = 0

    if config.bountyResetOnDeath then
        tes3mp.SetBounty(pid, 0)
        tes3mp.SendBounty(pid)
        Players[pid]:SaveBounty()
    end

    local deathReason = tes3mp.GetDeathReason(pid)
    if tes3mp.DoesPlayerHavePlayerKiller(pid) then
        local killerpid = tes3mp.GetPlayerKillerPid(pid)
        tes3mp.LogAppend(enumerations.log.INFO, "------------------------- " .. "inside OnPlayerDeathHandler: " .. tostring(killerpid))
        tes3mp.SetBounty(killerpid, 0)
        tes3mp.SendBounty(killerpid)
        Players[killerpid]:SaveBounty()
        inventoryHelper.addItem(Players[killerpid].data.inventory, "Gold_001", 1, -1, -1, "")
        Players[killerpid]:LoadItemChanges({{refId = "Gold_001", count = 1, charge = -1, enchantmentCharge = -1, soul = ""}}, enumerations.inventory.ADD)
        -- playerPacket = packetReader.GetPlayerPacketTables(killerpid, "PlayerInventory")
        -- Players[killerpid]:SaveInventory(playerPacket)

    end

    if pid == plateWars.bomb.baseData.plantingPid then
        tes3mp.StopTimer(plateWars.bomb.baseData.plantTimer)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." stopped planting because they died")
        plateWars.bomb.baseData.plantingPid = -1
        plateWars.enablePlayerControls(pid)
    elseif pid == plateWars.bomb.baseData.defusingPid then
        tes3mp.StopTimer(plateWars.bomb.baseData.defuseTimer)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." stopped defusing because they died")
        plateWars.bomb.baseData.defusingPid = -1
        plateWars.enablePlayerControls(pid)
    end

    if plateWars.hasBomb(pid) then
        Players[pid].forceRemoveBomb = true
        plateWars.dropBomb(pid)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." dropped the bomb because they died")
        Players[pid].forceRemoveBomb = nil
    end

    tes3mp.SendMessage(pid, color.Yellow .. "Respawning in " .. "5" .. " seconds...\n", false)
  	timer = tes3mp.CreateTimerEx("OnDeathTimeExpiration", time.seconds(5), "is", pid, tes3mp.GetName(pid))
  	tes3mp.LogAppend(enumerations.log.INFO, "------------------------- " .. "timer was created...")

  	tes3mp.StartTimer(timer)
  	tes3mp.LogAppend(enumerations.log.INFO, "------------------------- " .. "timer was started...")
end

function plateWars.OnPlayerDisconnectValidator(eventStatus, pid)
    if pid == plateWars.bomb.baseData.plantingPid then
        tes3mp.StopTimer(plateWars.bomb.baseData.plantTimer)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." stopped planting because they disconnected")
        plateWars.bomb.baseData.plantingPid = -1
    elseif pid == plateWars.bomb.baseData.defusingPid then
        tes3mp.StopTimer(plateWars.bomb.baseData.defuseTimer)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." stopped defusing because they disconnected")
        plateWars.bomb.baseData.defusingPid = -1
    end

    -- Leave team on disconnect (if member of any)
    plateWars.teamLeave(pid)

    if plateWars.hasBomb(pid) then
        Players[pid].forceRemoveBomb = true
        plateWars.dropBomb(pid)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." dropped the bomb because they disconnected")
        Players[pid].forceRemoveBomb = nil
    end

    -- Players[pid]:QuicksaveToDrive()
end

customEventHooks.registerHandler("OnServerPostInit",plateWars.OnServerPostInitHandler)
customEventHooks.registerHandler("OnObjectActivate",plateWars.OnObjectActivateHandler)
customEventHooks.registerHandler("OnDeathTimeExpiration", plateWars.OnDeathTimeExpirationHandler)
customEventHooks.registerHandler("OnPlayerDeath", plateWars.OnPlayerDeathHandler)

customEventHooks.registerValidator("OnPlayerInventory",plateWars.OnPlayerInventoryValidator)
customEventHooks.registerValidator("OnObjectPlace",plateWars.OnObjectPlaceValidator)
customEventHooks.registerValidator("OnPlayerDeath", function(eventStatus, pid)
	-- this makes it so that default resurrect for player does not happen but custom handler for player death does get executed
	return customEventHooks.makeEventStatus(false,true)
end)
customEventHooks.registerValidator("OnDeathTimeExpiration", function(eventStatus, pid)
	 return customEventHooks.makeEventStatus(false,true)
end)
customEventHooks.registerValidator("OnPlayerDisconnect",plateWars.OnPlayerDisconnectValidator)

--- TEST ---

function plateWars.onTeamJoinBluePlates(pid, cmd)
    plateWars.teamJoinBluePlates(pid)
end

function plateWars.onTeamJoinBrownPlates(pid, cmd)
    plateWars.teamJoinBrownPlates(pid)
    -- It's just a test this doesn't cover cases where player drops the bomb and the carrierPid is reset
    if plateWars.bomb.baseData.carrierPid == -1 then
        plateWars.teamAddBombRandom()
    end
end

function plateWars.testStartMatch(pid, cmd)
    plateWars.teamJoinBluePlates(pid)
    plateWars.bomb.baseData.carrierPid = pid
end

function plateWars.forceCarrierPid(pid, cmd)
  plateWars.bomb.baseData.carrierPid = pid
end

customCommandHooks.registerCommand("joinBlue", plateWars.onTeamJoinBluePlates)
customCommandHooks.registerCommand("joinBrown", plateWars.onTeamJoinBrownPlates)
customCommandHooks.registerCommand("startmatch", plateWars.startMatch)
customCommandHooks.registerCommand("forcecarrierpid", plateWars.forceCarrierPid)


--- TEST ---

return plateWars
