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

-- Map should have property isExterior or isInterior because exteriors need to be handled differently than interiors for which we can create instanced cells
plateWars.maps = {}
plateWars.maps["Balmora"] = {
    -- placeholder, change to cellDescription related to the spawn point coordinates
    cellDescription = "-3, -2",
    bluePlatesSpawnPoint = {-22598, -15301, 505},
    brownPlatesSpawnPoint = {-23598, -16301, 505}
}

plateWars.matches = {}
plateWars.matches = {
    currentMatchId = 0,
    instances = {}
}

plateWars.match = {}
plateWars.match.baseConfig = {}
plateWars.match.baseData = {}
plateWars.match.round = {}
plateWars.match.round.baseData = {}

plateWars.match.baseConfig = {
    freezeTime = 5,
    roundsPerMatch = 5
}

plateWars.match.baseData = {
    bomb = {},
    bombSites = {},
    rounds = {},
    teams = {},
    mapName = nil
}

-- THIS IS A ROUND TEMPLATE
-- We can keep statistics per round here, like kills, assists
plateWars.match.round.baseData = {

}

plateWars.teams = {}
plateWars.teams.baseData = {}
plateWars.teams.config = {}

plateWars.teams.baseData = {
    bluePlatesPids = {},
    brownPlatesPids = {}
}

plateWars.teams.config = {
    maxPlayersPerTeam = 3
}

plateWars.bomb = {}
plateWars.bomb.baseConfig = {}
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

plateWars.bomb.baseConfig = {
    defuseTime = 3,
    plantTime = 3,
    tickTime = 45,
    tickTimeIncrement = 5
}

plateWars.bomb.baseData = {
    defuseTimer = nil,
    plantTimer = nil,
    tickTimer = nil,
    carryingPid = -1,
    defusingPid = -1,
    plantingPid = -1,
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

function plateWars.matchesIncrementId()
    plateWars.matches.currentMatchId = plateWars.matches.currentMatchId + 1
end

function plateWars.matchesGetMatch(matchId)
    return plateWars.matches.instances[matchId]
end

function plateWars.matchesCreateMatch(mapName)
    plateWars.matchesIncrementId()

    local matchId = plateWars.matches.currentMatchId
    plateWars.matches.instances[matchId] = {"the_match"}

    local match = plateWars.matchesGetMatch(matchId)

    match.config = tableHelper.deepCopy(plateWars.match.baseConfig)

    match.data = tableHelper.deepCopy(plateWars.match.baseData)

    match.data.bomb = tableHelper.deepCopy(plateWars.bomb.baseData)

    match.data.bombSites = tableHelper.deepCopy(plateWars.bombSites.baseData)

    match.data.teams = tableHelper.deepCopy(plateWars.teams.baseData)

    if mapName == nil then
        -- Implement random map choice
        mapName = "Balmora"
    end

    match.data.mapName = mapName

    return matchId
end

function plateWars.matchesDestroyMatch(matchId)
    plateWars.matches.instances[matchId] = nil
end

function plateWars.matchesStartMatch(matchId)
    local match = plateWars.matchesGetMatch(matchId)
    tes3mp.LogMessage(enumerations.log.INFO, logPrefix .. "Match ID " .. tostring(matchId) .. " has started.")
    plateWars.matchesSortPlayersIntoTeams(match)
    plateWars.matchesStartRound(match)
end

function plateWars.matchesEndMatch(matchId)
    tes3mp.LogMessage(enumerations.log.INFO, logPrefix .. "Match ID " .. tostring(matchID) .. " has ended.")
    -- Do the logic of showing end scoreboard or something like that
    -- Remove players from the map, do other related stuff to match end
    -- Finally destroy the match entry
    plateWars.matchesDestroyMatch(matchId)
end

function plateWars.matchesStartRound(match)
    -- Initiate new round data
    table.insert(match.data.rounds, plateWars.match.round.baseData)

    plateWars.matchesSpawnTeams(plateWars.matches.currentMatchId)
    plateWars.matchesStartFreezeTime()
    plateWars.teamAddBombRandom()
end

function plateWars.matchesEndRound(matchId)
  --roundID = nil
  local match = plateWars.matchesGetMatch(matchId)
  local roundCount = match.rounds
  if roundCount < plateWars.match then
    plateWars.matchesStartRound(match)
  else
    plateWars.endMatch(matchId)
  end
end

function plateWars.matchesSortPlayersIntoTeams(match)
    -- add player to brown team only when blue team has more players
    for pid, player in pairs(Players) do
        if #plateWars.teams.baseData.bluePlatesPids > #plateWars.teams.baseData.brownPlatesPids then
            plateWars.teamJoinBrownPlates(pid)
        else
            plateWars.teamJoinBluePlates(pid)
            tes3mp.LogMessage(enumerations.log.INFO, logPrefix .. "Adding player to brown team")
        end
    end
end

function plateWars.matchesSpawnTeams(matchId)
    tes3mp.LogMessage(enumerations.log.INFO, logPrefix .. "Spawning players")

    local match = plateWars.matchesGetMatch(matchId)

    for _, pid in ipairs(match.data.teams.bluePlatesPids) do
        if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
            plateWars.matchesSpawnBluePlate(match, pid)
        end
    end

    for _, pid in ipairs(match.data.teams.brownPlatesPids) do
        if Players[pid] ~= nil and Players[pid]:IsLoggedIn() then
            plateWars.matchesSpawnBrownPlate(match, pid)
        end
    end

    -- TODO handle players that have disconnected, so that the match can be paused while waiting for the pid to reconnect
end

function plateWars.matchesSpawnBluePlate(match, pid)
    local map = plateWars.maps["Balmora"]

    tes3mp.SetCell(pid, map.cellDescription)
    tes3mp.SetPos(pid, map.bluePlatesSpawnPoint[1], map.bluePlatesSpawnPoint[2], map.bluePlatesSpawnPoint[3])

    tes3mp.SendCell(pid)
    tes3mp.SendPos(pid)
end

function plateWars.matchesSpawnBrownPlate(match, pid)
    local map = plateWars.maps["Balmora"]

    tes3mp.SetCell(pid, map.cellDescription)
    tes3mp.SetPos(pid, map.brownPlatesSpawnPoint[1], map.brownPlatesSpawnPoint[2], map.brownPlatesSpawnPoint[3])

    tes3mp.SendCell(pid)
    tes3mp.SendPos(pid)
end

-- Freeze time should react to player's disconnecting
-- If player disconnects prepare a timeout timer that will be started after the round has ended
-- If player manages to reconnect prior to the round end, destroy the timeout timer
function plateWars.matchesStartFreezeTime()
    freezeTimer = tes3mp.CreateTimerEx("endFreezeTime", time.seconds(plateWars.match.baseConfig.freezeTime), "i", 1)
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
    if not tableHelper.containsValue(plateWars.teams.baseData.bluePlatesPids, pid) and not tableHelper.containsValue(plateWars.teams.baseData.brownPlatesPids, pid) then
        if #teamPidsTable < plateWars.teams.config.maxPlayersPerTeam then
            table.insert(teamPidsTable, pid)
        end
    end
end

function plateWars.teamJoinBluePlates(pid)
    plateWars.teamJoin(pid, plateWars.teams.baseData.bluePlatesPids)
end

function plateWars.teamJoinBrownPlates(pid)
    plateWars.teamJoin(pid, plateWars.teams.baseData.brownPlatesPids)
end

function plateWars.teamLeave(pid)
    if plateWars.teamIsBluePlate(pid) then
        tableHelper.removeValue(plateWars.teams.baseData.bluePlatesPids, pid)
    elseif plateWars.teamIsBrownPlate(pid) then
        tableHelper.removeValue(plateWars.teams.baseData.brownPlatesPids, pid)
    end
end

function plateWars.teamIsBluePlate(pid)
    return tableHelper.containsValue(plateWars.teams.baseData.bluePlatesPids, pid)
end

function plateWars.teamIsBrownPlate(pid)
    return tableHelper.containsValue(plateWars.teams.baseData.brownPlatesPids, pid)
end

function plateWars.teamAddBomb(pid)
    inventoryHelper.addItem(Players[pid].data.inventory, plateWars.bomb.refIds.inventoryItem, 1, -1, -1, "")
    Players[pid]:LoadItemChanges({{refId = plateWars.bomb.refIds.inventoryItem, count = 1, charge = -1, enchantmentCharge = -1, soul = ""}}, enumerations.inventory.ADD)
    plateWars.bomb.baseData.carryingPid = pid
end

function plateWars.teamAddBombRandom()
    math.randomseed(os.time())
    local randomIndex = math.random(#plateWars.teams.baseData.brownPlatesPids)
    plateWars.teamAddBomb(plateWars.teams.baseData.brownPlatesPids[randomIndex])
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
    return  plateWars.bomb.baseData.carryingPid == pid
end

function plateWars.removeBomb(pid)
    inventoryHelper.removeItem(Players[pid].data.inventory, plateWars.bomb.refIds.inventoryItem, 1, -1, -1, "")
    Players[pid]:LoadItemChanges({{refId = plateWars.bomb.refIds.inventoryItem, count = 1, charge = -1, enchantmentCharge = -1, soul = ""}},enumerations.inventory.REMOVE)
    plateWars.bomb.baseData.carryingPid = -1
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

function plateWars.OnPlayerDeathValidator(eventStatus, pid)
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
end

customEventHooks.registerHandler("OnServerPostInit",plateWars.OnServerPostInitHandler)
customEventHooks.registerHandler("OnObjectActivate",plateWars.OnObjectActivateHandler)

customEventHooks.registerValidator("OnPlayerInventory",plateWars.OnPlayerInventoryValidator)
customEventHooks.registerValidator("OnObjectPlace",plateWars.OnObjectPlaceValidator)
customEventHooks.registerValidator("OnPlayerDeath",plateWars.OnPlayerDeathValidator)
customEventHooks.registerValidator("OnPlayerDisconnect",plateWars.OnPlayerDisconnectValidator)

--- TEST ---

function plateWars.onTeamJoinBluePlates(pid, cmd)
    plateWars.teamJoinBluePlates(pid)
end

function plateWars.onTeamJoinBrownPlates(pid, cmd)
    plateWars.teamJoinBrownPlates(pid)
    -- It's just a test this doesn't cover cases where player drops the bomb and the carryingPid is reset
    if plateWars.bomb.baseData.carryingPid == -1 then
        plateWars.teamAddBombRandom()
    end
end

function plateWars.testStartMatch(pid, cmd)
  -- plateWars.teamJoinBluePlates(pid)
  -- plateWars.bomb.baseData.carryingPid = pid
    plateWars.matchesStartMatch(plateWars.matchesCreateMatch("Balmora"))
end

function plateWars.forcecarryingPid(pid, cmd)
  plateWars.bomb.baseData.carryingPid = pid
end

customCommandHooks.registerCommand("joinBlue", plateWars.onTeamJoinBluePlates)
customCommandHooks.registerCommand("joinBrown", plateWars.onTeamJoinBrownPlates)
customCommandHooks.registerCommand("startmatch", plateWars.testStartMatch)
customCommandHooks.registerCommand("forcecarryingpid", plateWars.forcecarryingPid)


--- TEST ---

return plateWars
