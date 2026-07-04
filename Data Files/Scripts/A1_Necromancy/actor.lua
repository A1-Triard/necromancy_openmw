local I = require('openmw.interfaces')
local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')

local pauls = {
    'a1_necroaltmerpaul',
    'a1_necroaltmerpaulsk',
    'a1_necroargpaul',
    'a1_necroargpaulsk',
    'a1_necrobosmerpaul',
    'a1_necrobosmerpaulsk',
    'a1_necrobretonpaul',
    'a1_necrobretonpaulsk',
    'a1_necrodunmerpaul',
    'a1_necrodunmerpaulsk',
    'a1_necroimppaul',
    'a1_necroimppaulsk',
    'a1_necrokhapaul',
    'a1_necrokhapaulsk',
    'a1_necronordpaul',
    'a1_necronordpaulsk',
    'a1_necroorcpaul',
    'a1_necroorcpaulsk',
    'a1_necrorgpaul',
    'a1_necrorgpaulsk',
}

local function dragsCorpseForPlayer()
    local player = nil
    if types.Player.objectIsInstance(self.object) then
        player = self.object
    else
        local follow = I.AI.getActiveTarget('Follow')
        if follow and types.Player.objectIsInstance(follow) then
            player = follow
        end
    end
    if not player then
        return
    end
    local inv = types.Actor.inventory(self.object)
    for _, paul in ipairs(pauls) do
        if inv:countOf(paul) ~= 0 then
            return player
        end
    end
    return nil
end

local updateCounter = 0

return {
    engineHandlers = {
        onUpdate = function(dt)
            updateCounter = updateCounter + 1
            if updateCounter == 500 then
                updateCounter = 0
                if core.isWorldPaused() then
                    return
                end
                local player = dragsCorpseForPlayer()
                if player then
                    core.sendGlobalEvent('A1NecroDrag', {
                        player = player,
                    })
                end
            end
        end,
    },
}
