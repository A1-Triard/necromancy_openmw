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
    },
    eventHandlers = {
        A1NecroPrepare = function(data)
            local target = data.target
            local inv = types.Actor.inventory(target)
            for _, item in ipairs(inv:getAll()) do
                item:moveInto(types.Actor.inventory(data.player))
            end
            local record = types.NPC.record(target)
            local hair = world.createObject('A1_NecroH' .. idHash(record.hair))
            hair:moveInto(types.Actor.inventory(data.player))
            local head = world.createObject('A1_NecroH' .. idHash(record.head))
            head:moveInto(types.Actor.inventory(data.player))
            heads[head.id] = record.id
            local race = record.race
            local body
            if race == 'high elf' then
                body = 'A1_NecroAltmerPaul'
            elseif race == 'argonian' then
                body = 'A1_NecroArgPaul'
            elseif race == 'wood elf' then
                body = 'A1_NecroBosmerPaul'
            elseif race == 'breton' then
                body = 'A1_NecroBretonPaul'
            elseif race == 'dark elf' then
                body = 'A1_NecroDunmerPaul'
            elseif race == 'imperial' then
                body = 'A1_NecroImpPaul'
            elseif race == 'khajiit' then
                body = 'A1_NecroKhaPaul'
            elseif race == 'nord' then
                body = 'A1_NecroNordPaul'
            elseif race == 'orc' then
                body = 'A1_NecroOrcPaul'
            else
                body = 'A1_NecroRgPaul'
            end
            local bodyObj = world.createObject(body, 1)
            bodyObj:moveInto(types.Actor.inventory(data.player))
            target:remove()
        end,
    },
}
