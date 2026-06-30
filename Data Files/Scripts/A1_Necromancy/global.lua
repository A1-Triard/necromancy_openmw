local types = require('openmw.types')
local world = require('openmw.world')

local function idHash(id)
    local res = 5381
    for i = 1, #id do
        local b = id:byte(i)
        res = (res * 33 + b) % 4294967296
    end
    res = res % 100000000
    return res
end

local heads = { }

local pauls = {
    ['high elf'] = 'a1_necroaltmerpaul',
    ['argonian'] = 'a1_necroargpaul',
    ['wood elf'] = 'a1_necrobosmerpaul',
    ['breton'] = 'a1_necrobretonpaul',
    ['dark elf'] = 'a1_necrodunmerpaul',
    ['imperial'] = 'a1_necroimppaul',
    ['khajiit'] = 'a1_necrokhapaul',
    ['nord'] = 'a1_necronordpaul',
    ['orc'] = 'a1_necroorcpaul',
    ['redguard'] = 'a1_necrorgpaul',
}

local bodies = {
    ['a1_necroaltmerpaul'] = 'a1_necroaltmerbody',
    ['a1_necroargpaul'] = 'a1_necroargbody',
    ['a1_necrobosmerpaul'] = 'a1_necrobosmerbody',
    ['a1_necrobretonpaul'] = 'a1_necrobretonbody',
    ['a1_necrodunmerpaul'] = 'a1_necrodunmerbody',
    ['a1_necroimppaul'] = 'a1_necroimpbody',
    ['a1_necrokhapaul'] = 'a1_necrokhabody',
    ['a1_necronordpaul'] = 'a1_necronordbody',
    ['a1_necroorcpaul'] = 'a1_necroorcbody',
    ['a1_necrorgpaul'] = 'a1_necrorgbody',
}

local paulsByBodies = {
    ['a1_necroaltmerbody'] = 'a1_necroaltmerpaul',
    ['a1_necroargbody'] = 'a1_necroargpaul',
    ['a1_necrobosmerbody'] = 'a1_necrobosmerpaul',
    ['a1_necrobretonbody'] = 'a1_necrobretonpaul',
    ['a1_necrodunmerbody'] = 'a1_necrodunmerpaul',
    ['a1_necroimpbody'] = 'a1_necroimppaul',
    ['a1_necrokhabody'] = 'a1_necrokhapaul',
    ['a1_necronordbody'] = 'a1_necronordpaul',
    ['a1_necroorcbody'] = 'a1_necroorcpaul',
    ['a1_necrorgbody'] = 'a1_necrorgpaul',
}

return {
    engineHandlers = {
        onSave = function()
            return heads
        end,
        onLoad = function(data)
            if data then
                heads = data
            end
        end,
        onItemActive = function(item)
            if types.Armor.objectIsInstance(item) then
                local id = types.Armor.record(item).id
                local activatorId = bodies[id]
                if activatorId then
                    local activator = world.createObject(activatorId)
                    activator:teleport(item.cell, item.position, item.rotation)
                    item:remove()
                end
            elseif types.Miscellaneous.objectIsInstance(item) then
                local id = types.Miscellaneous.record(item).id
                if string.sub(id, 1, #'a1_necroh') == 'a1_necroh' then
                    local hash = string.sub(id, #'a1_necroh' + 1)
                    local activatorId = 'a1_necrox' .. hash
                    local activator = world.createObject(activatorId)
                    activator:teleport(item.cell, item.position, item.rotation)
                    item:remove()
                end
            end
        end,
        onActivate = function(object, actor)
            if types.Activator.objectIsInstance(object) then
                local id = types.Activator.record(object).id
                if string.sub(id, 1, #'a1_necrox') == 'a1_necrox' then
                    local hash = string.sub(id, #'a1_necrox' + 1)
                    local headId = 'a1_necroh' .. hash
                    local head = world.createObject(headId)
                    head:moveInto(types.Actor.inventory(actor))
                    object:remove()
                else
                    local paulId = paulsByBodies[id]
                    if paulId then
                        local paul = world.createObject(paulId)
                        paul:moveInto(types.Actor.inventory(actor))
                        object:remove()
                    end
                end
            end
        end,
    },
    eventHandlers = {
        A1NecroPrepare = function(data)
            local target = data.target
            local inv = types.Actor.inventory(target)
            for _, item in ipairs(inv:getAll()) do
                item:moveInto(types.Actor.inventory(data.player))
            end
            local record = types.NPC.record(target)
            local hair = world.createObject('a1_necroh' .. idHash(record.hair))
            hair:moveInto(types.Actor.inventory(data.player))
            local head = world.createObject('a1_necroh' .. idHash(record.head))
            head:moveInto(types.Actor.inventory(data.player))
            heads[head.id] = record.id
            local body = pauls[record.race]
            local bodyObj = world.createObject(body)
            bodyObj:moveInto(types.Actor.inventory(data.player))
            target:remove()
        end,
    },
}
