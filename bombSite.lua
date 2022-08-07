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

local bombSite = {}

local logPrefix = "Plate Wars: "

local plantTime = 3
local defuseTime = 8
local bombTime = 45
local bombTimeIncrement = 5

local bombTimer
local plantTimer
local defuseTimer

local plantingPid = -1
local defusingPid = -1
-- I suggest setting this flag for player that was given the bomb based on random pick
-- We then don't have to check for each of the players inventory and only return this in the hasBomb check
local bombCarrierPid = -1

local bombExplodeId = "de_bomb_explosion"

local bombExplodeCfg = {
    impactArea = 50, -- determines size of area that will be affected by the explosion, in feet, where 1 feet = about 21 units
    impactMinDamage = 100, -- determines how much damage should be dealt to players at MIN
    impactMaxDamage = 100, -- determines how much damage should be dealth to players at MAX
    affiliatedDuration = 5, -- how long will the damage over time last
    affiliatedMinDamage = 10, -- how much damage will be dealt per tick at MIN
    affiliatedMaxDamage = 10, -- how much damage will be dealt per tick at MAX
    consoleCommand = "ExplodeSpell " .. bombExplodeId
}

local bombSiteRefIds = {
    de_site_01 = {
        bombPositionOffset = {
            posX = 0,
            posY = 0,
            posZ = 60,
            rotX = 0,
            rotY = 0,
            rotZ = 0
        }
    },
    de_site_02 = {
        bombPositionOffset = {
            posX = 0,
            posY = 0,
            posZ = 60,
            rotX = 0,
            rotY = 0,
            rotZ = 0
        }
    }
}
local bombRefIds = { world = "de_bomb_01", inv = "de_bomb_item_01"}

local bombSiteRecords = {
    {
        id = "de_site_01",
        recordType = "activator",
        recordData = {
            model = "o\\contain_crate_01.nif",
            name = "Blue Plate Stash A"
        }
    },
    {
        id = "de_site_02",
        recordType = "activator",
        recordData = {
            model = "o\\contain_crate_01.nif",
            name = "Blue Plate Stash B"
        }
    },
    {
        id = "de_bomb_01",
        recordType = "activator",
        recordData = {
            model = "m\\dwemer_satchel00.nif",
            name = "Plate Buster"
        }
    },
    {
        id = "de_bomb_item_01",
        recordType = "miscellaneous",
        recordData = {
            model = "m\\dwemer_satchel00.nif",
            icon = "m\\misc_dwe_satchel00.dds",
            name = "Plate Buster"
        }
    },
    {
        id = "de_bomb_explosion",
        recordType = "spell",
        recordData = {
            name = "Bomb Explosion",
            subytpe = 0,
            cost = 0,
            flags = 65536, -- shouldn't be reflectable
            effects = {
                {
                    attribute = -1, -- idk what this does
                    area = bombExplodeCfg.impactArea, -- measured in feet, 1 feet = about 21 units
                    duration = 0, -- one time effect
                    id = 14, -- Fire Damage
                    rangeType = 0, -- On self/touch/target
                    skill = -1, -- idk what this does
                    magnitudeMin = bombExplodeCfg.impactMinDamage, -- amount of minimum damage
                    magnitudeMax = bombExplodeCfg.impactMaxDamage -- amount of maximum damage
                },
                {
                    attribute = -1,
                    area = 0,
                    duration = bombExplodeCfg.affiliatedDuration, -- in seconds
                    id = 23, -- Damage Health
                    rangeType = 0,
                    skill = -1,
                    magnitudeMin = bombExplodeCfg.affiliatedMinDamage,
                    magnitudeMax = bombExplodeCfg.affiliatedMaxDamage
                }
            }
        }
    }
}

function bombSite.bombDefused(cellDescription, bombIndex)
    defusingPid = -1
    if bombTimer ~= nil then
        tes3mp.StopTimer(bombTimer)
    end
    for pid, player in pairs(Players) do
        tes3mp.MessageBox(pid,-1,color.Blue.."The Blue plates have outlasted the Brown")
    end
    logicHandler.DeleteObjectForEveryone(cellDescription, bombIndex)
    tes3mp.LogMessage(enumerations.log.INFO, logPrefix.."Bomb defused, blue team wins")
    --TODO: Handle round win for blue
end

function bombSite.bombDetonate(cellDescription, bombIndex)
    if defuseTimer ~= nil then
        bombSite.enablePlayerControls(defusingPid)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(defusingPid).." stopped defusing because there was no time left")
        defusingPid = -1
        tes3mp.StopTimer(defuseTimer)
    end
    for pid, player in pairs(Players) do
        tes3mp.MessageBox(pid,-1,color.Brown.."Boom!")
    end
    logicHandler.RunConsoleCommandOnObjects(tableHelper.getAnyValue(Players).pid, bombExplodeCfg.consoleCommand, cellDescription, {bombIndex}, true)
    logicHandler.DeleteObjectForEveryone(cellDescription, bombIndex)
    tes3mp.LogMessage(enumerations.log.INFO, logPrefix.."Bomb detonated, brown team wins")
    --TODO: Handle round win for brown
end

function bombSite.getBombPos(sitePos, offset)
    local bombPos = {}
    for key,value in pairs(offset) do
        bombPos[key] = sitePos[key] + value
    end
    return bombPos
end

function bombSiteBombTimer(timeLeft, cellDescription, bombIndex)
    if timeLeft > 0 then
        --Just making the assumption that all players are in the game, can replace with teams if needed
        for pid, player in pairs(Players) do
            tes3mp.MessageBox(pid,-1,color.Brown..timeLeft.." seconds till plate destruction")
        end
        if timeLeft > 10 then
            bombTimer = tes3mp.CreateTimerEx("bombSiteBombTimer",1000*bombTimeIncrement, "iss", timeLeft-bombTimeIncrement, cellDescription, bombIndex)
            tes3mp.StartTimer(bombTimer)
        else
            bombTimer = tes3mp.CreateTimerEx("bombSiteBombTimer",1000*1, "iss", timeLeft-1, cellDescription, bombIndex)
            tes3mp.StartTimer(bombTimer)
        end
    else
        bombSite.bombDetonate(cellDescription, bombIndex)
    end
end

function bombSitePlantedTimer(pid, cellDescription, uniqueIndex, refId)
    local bombPosOffset = bombSiteRefIds[refId].bombPositionOffset
    local sitePos = {}
    local bombPos = {}

    if LoadedCells[cellDescription].data.objectData[uniqueIndex].location ~= nil then
        sitePos = LoadedCells[cellDescription].data.objectData[uniqueIndex].location
    else
        return
    end

    bombPos = bombSite.getBombPos(sitePos, bombPosOffset)
    local bombIndex = logicHandler.CreateObjectAtLocation(cellDescription, bombPos, {refId = bombRefIds.world, count = 1,charge = -1, enchantmentCharge = -1, soul = ""}, "place")
    bombSite.removeBomb(pid)
    bombSite.enablePlayerControls(pid)
    plantingPid = -1
    tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." finished planting the bomb at "..refId.."("..uniqueIndex..") in cell "..cellDescription)
    tes3mp.MessageBox(pid, -1, color.Green.."You finished planting the Plate Buster")

    bombTimer = tes3mp.CreateTimerEx("bombSiteBombTimer",1000*bombTimeIncrement, "iss", bombTime-bombTimeIncrement, cellDescription, bombIndex)
    tes3mp.StartTimer(bombTimer)
    --TODO: Play abnoxious voice line?
end

function bombSiteDefusedTimer(pid, cellDescription, uniqueIndex)
    bombSite.enablePlayerControls(pid)
    bombSite.bombDefused(cellDescription, uniqueIndex)
end

function bombSite.hasBomb(pid)
    return bombCarrierPid == pid
end

function bombSite.removeBomb(pid)
    inventoryHelper.removeItem(Players[pid].data.inventory, bombRefIds.inv, 1, -1, -1, "")
    Players[pid]:LoadItemChanges({{refId = bombRefIds.inv, count = 1, charge = -1, enchantmentCharge = -1, soul = ""}},enumerations.inventory.REMOVE)
    bombCarrierPid = -1
end

function bombSite.dropBomb(pid)
    local cell = tes3mp.GetCell(pid)
    local location = {
        posX = tes3mp.GetPosX(pid), posY = tes3mp.GetPosY(pid), posZ = tes3mp.GetPosZ(pid),
        rotX = tes3mp.GetRotX(pid), rotY = 0, rotZ = tes3mp.GetRotZ(pid)
    }
    --drop bomb above player's corpse
    location.posZ = location.posZ + 15
    
    bombSite.removeBomb(pid)
    logicHandler.CreateObjectAtLocation(cell, location, {refId = bombRefIds.inv, count = 1, charge = -1, enchantmentCharge = -1, soul = ""}, "place")
end

function bombSite.disablePlayerControls(pid)
    logicHandler.RunConsoleCommandOnPlayer(pid,"DisablePlayerControls")
end

function bombSite.enablePlayerControls(pid)
    logicHandler.RunConsoleCommandOnPlayer(pid,"EnablePlayerControls")
end

function bombSite.handleDefuse(pid, cellDescription, object)
    --TODO: Add check if player is on the blue team
    if defusingPid ~= -1 then
        tes3mp.MessageBox(pid, -1, color.Red.."Someone else is already defusing")
    else
        --Begin Defuse
        bombSite.disablePlayerControls(pid)
        defusingPid = pid
        defuseTimer = tes3mp.CreateTimerEx("bombSiteDefusedTimer",1000 * defuseTime, "iss", pid, cellDescription, object.uniqueIndex)
        tes3mp.StartTimer(defuseTimer)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." started defusing the bomb: "..object.uniqueIndex.." in cell "..cellDescription)
        tes3mp.MessageBox(pid, -1, color.Green.."You have begun defusing the Plate Buster")
    end
    
end

function bombSite.handlePlant(pid, cellDescription, object)
    --TODO: Add check if player is on the brown team
    if bombSite.hasBomb(pid) then
        --Begin planting
        bombSite.disablePlayerControls(pid)
        plantingPid = pid
        plantTimer = tes3mp.CreateTimerEx("bombSitePlantedTimer",1000 * plantTime, "isss", pid, cellDescription, object.uniqueIndex, object.refId)
        tes3mp.StartTimer(plantTimer)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." started planting the bomb at "..object.refId.."("..object.uniqueIndex..") in cell "..cellDescription)
        tes3mp.MessageBox(pid, -1, color.Green.."You have begun planting the Plate Buster")
    else
        tes3mp.MessageBox(pid, -1, color.Red.."You do not have the Plate Buster")
    end
end

-- Prevent inventory bomb from being dropped into the world regularly
function bombSite.OnObjectPlaceValidator(eventStatus, pid, cellDescription, objects, targetPlayers)
    for _, object in pairs(objects) do
        if object.refId == bomRefIds.inv then
            return customEventHooks.makeEventStatus(false, false)
        end
    end
end

-- Prevent inventory bomb from being removed regularly, ie. by dragging and dropping it into the world
function bombSite.OnPlayerInventoryValidator(eventStatus, pid, playerPacket)
    if playerPacket.action == enumerations.inventory.REMOVE then
        for _, item in ipairs(playerPacket.inventory) do
            -- Allow the inventory bomb to be removed from planting, dead or disconnecting pid's inventory
            if pid ~= plantingPid and Players[pid].forceRemoveBomb == nil and item.refId == bombRefIds.inv then
                return customEventHooks.makeEventStatus(false, false)
            end
        end
    end
end

function bombSite.OnObjectActivateHandler(eventStatus, pid, cellDescription, objects, targetPlayers)
    if eventStatus.validCustomHandlers ~= false and eventStatus.validDefaultHandler ~= false then
        for _,object in pairs(objects) do
            if bombSiteRefIds[object.refId] ~= nil then
                --The player activated one of the sites
                bombSite.handlePlant(pid, cellDescription, object)
            end
            if object.refId == bombRefIds.world then
                --The Player activated an armed bomb
                bombSite.handleDefuse(pid, cellDescription, object)
            end
        end
    end
end

function bombSite.OnServerPostInitHandler()
    for _,record in pairs(bombSiteRecords) do
        RecordStores[record.recordType].data.permanentRecords[record.id] = tableHelper.deepCopy(record.recordData)
    end
end

function bombSite.OnPlayerDeathValidator(eventStatus, pid)
    if pid == plantingPid then
        tes3mp.StopTimer(plantTimer)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." stopped planting because they died")
        plantingPid = -1
        bombSite.enablePlayerControls(pid)
    elseif pid == defusingPid then
        tes3mp.StopTimer(defuseTimer)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." stopped defusing because they died")
        defusingPid = -1
        bombSite.enablePlayerControls(pid)
    end
    
    if bombSite.hasBomb(pid) then
        Players[pid].forceRemoveBomb = true
        bombSite.dropBomb(pid)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." dropped the bomb because they died")
        Players[pid].forceRemoveBomb = nil
    end
end

function bombSite.OnPlayerDisconnectValidator(eventStatus, pid)
    if pid == plantingPid then
        tes3mp.StopTimer(plantTimer)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." stopped planting because they disconnected")
        plantingPid = -1
    elseif pid == defusingPid then
        tes3mp.StopTimer(defuseTimer)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." stopped defusing because they disconnected")
        defusingPid = -1
    end
    
    if bombSite.hasBomb(pid) then
        Players[pid].forceRemoveBomb = true
        bombSite.dropBomb(pid)
        tes3mp.LogMessage(enumerations.log.INFO, logPrefix..logicHandler.GetChatName(pid).." dropped the bomb because they disconnected")
        Players[pid].forceRemoveBomb = nil
    end
end

customEventHooks.registerHandler("OnServerPostInit",bombSite.OnServerPostInitHandler)

customEventHooks.registerHandler("OnObjectActivate",bombSite.OnObjectActivateHandler)

customEventHooks.registerHandler("OnPlayerInventory",bombSite.OnPlayerInventoryValidator)

customEventHooks.registerValidator("OnPlayerDeath",bombSite.OnPlayerDeathValidator)

customEventHooks.registerValidator("OnPlayerDisconnect",bombSite.OnPlayerDisconnectValidator)

return bombSite
