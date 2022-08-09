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
    carrierPid = {} -- made it table for testing purposes, so keep the name intact
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
    bombTick = "de_bomb_tick"
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

function plateWars.bombPlayTickSound(cellDescription, bombIndex)
    plateWars.playSoundLocal(tableHelper.getAnyValue(Players).pid, cellDescription, {bombIndex}, plateWars.sounds.refIds.bombTick)
end

function plateWars.bombExplode(cellDescription, bombIndex)
    logicHandler.RunConsoleCommandOnObjects(tableHelper.getAnyValue(Players).pid, plateWars.bomb.commands.explode, cellDescription, {bombIndex}, true)
end
---- TEST FUNCTION, DELETE AFTER NO USE
function plateWars.testAddPlayerBomb(pid, cmd)
    inventoryHelper.addItem(Players[pid].data.inventory, plateWars.bomb.refIds.inventoryItem, 1, -1, -1, "")
    Players[pid]:LoadItemChanges({{refId = plateWars.bomb.refIds.inventoryItem, count = 1, charge = -1, enchantmentCharge = -1, soul = ""}}, enumerations.inventory.ADD)
    -- plateWars.bomb.baseData.carrierPid = pid -- uncomment after testing has been done
    tableHelper.insertValueIfMissing(plateWars.bomb.baseData.carrierPid, pid)
end
-------------------------------------------
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
    return tableHelper.containsValue(plateWars.bomb.baseData.carrierPid, pid)
    -- return  plateWars.bomb.baseData.carrierPid == pid -- uncomment after testing, now multiple players can have the bomb in one session
end

function plateWars.removeBomb(pid)
    inventoryHelper.removeItem(Players[pid].data.inventory, plateWars.bomb.refIds.inventoryItem, 1, -1, -1, "")
    Players[pid]:LoadItemChanges({{refId = plateWars.bomb.refIds.inventoryItem, count = 1, charge = -1, enchantmentCharge = -1, soul = ""}},enumerations.inventory.REMOVE)
    -- plateWars.bomb.baseData.carrierPid = -1 -- uncomment after testing
    tableHelper.removeValue(plateWars.bomb.baseData.carrierPid, pid)
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
    --TODO: Add check if player is on the blue team
    if plateWars.bomb.baseData.defusingPid ~= -1 then
        tes3mp.MessageBox(pid, -1, color.Red.."Someone else is already defusing")
    else
        --Begin Defuse
        plateWars.disablePlayerControls(pid)
        plateWars.bomb.baseData.defusingPid = pid
        plateWars.bomb.baseData.defuseTimer = tes3mp.CreateTimerEx("plateWarsDefusedTimer",1000 * plateWars.bomb.baseData.defuseTime, "iss", pid, cellDescription, object.uniqueIndex)
        tes3mp.StartTimer(plateWars.bomb.baseData.defuseTimer)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." started defusing the bomb: "..object.uniqueIndex.." in cell "..cellDescription)
        tes3mp.MessageBox(pid, -1, color.Green.."You have begun defusing the Plate Buster")
    end
    
end

function plateWars.handlePlant(pid, cellDescription, object)
    --TODO: Add check if player is on the brown team
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

customCommandHooks.registerCommand("addBomb", plateWars.testAddPlayerBomb)

return plateWars
