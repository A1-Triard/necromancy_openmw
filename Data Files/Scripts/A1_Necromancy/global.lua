local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local async = require('openmw.async')

local maxGeneration = 3

local function incSkill(player)
    local bookRecordDraft = types.Book.createRecordDraft({
        enchant = nil,
        enchantCapacity = 0,
        icon = 'icons\\m\\tx_scroll_open_01.tga',
        isScroll = true,
        model = 'meshes\\m\\text_scroll_01.nif',
        mwscript = nil,
        name = 'Навык колдовства вырос',
        skill = 'conjuration',
        text
            =  '<DIV ALIGN="LEFT"><FONT COLOR="000000" SIZE="3" FACE="Magic Cards"><BR>'
            .. 'Ваш навык колдовства вырос.<BR>',
        value = 0,
        weight = 0,
    })
    local bookRecord = world.createRecord(bookRecordDraft)
    local book = world.createObject(bookRecord.id)
    book:moveInto(types.Actor.inventory(player))
    core.sendGlobalEvent('UseItem', { object = book, actor = player, force = true })
    async:newUnsavableSimulationTimer(0, function()
        book:remove()
    end)
end

local function idHash(id)
    local res = 5381
    for i = 1, #id do
        local b = id:byte(i)
        res = (res * 33 + b) % 4294967296
    end
    res = res % 100000000
    return res
end

local pauls = {
    ['high elf'] = { id = 'a1_necroaltmerpaul', isSkel = false },
    ['argonian'] = { id = 'a1_necroargpaul', isSkel = false },
    ['wood elf'] = { id = 'a1_necrobosmerpaul', isSkel = false },
    ['breton'] = { id = 'a1_necrobretonpaul', isSkel = false },
    ['dark elf'] = { id = 'a1_necrodunmerpaul', isSkel = false },
    ['imperial'] = { id = 'a1_necroimppaul', isSkel = false },
    ['khajiit'] = { id = 'a1_necrokhapaul', isSkel = false },
    ['nord'] = { id = 'a1_necronordpaul', isSkel = false },
    ['orc'] = { id = 'a1_necroorcpaul', isSkel = false },
    ['redguard'] = { id = 'a1_necrorgpaul', isSkel = false },
    ['a1_necroaltmerrace'] = { id = 'a1_necroaltmerpaulsk', isSkel = true },
    ['a1_necroargrace'] = { id = 'a1_necroargpaulsk', isSkel = true },
    ['a1_necrobosmerrace'] = { id = 'a1_necrobosmerpaulsk', isSkel = true },
    ['a1_necrobretonrace'] = { id = 'a1_necrobretonpaulsk', isSkel = true },
    ['a1_necrodunmerrace'] = { id = 'a1_necrodunmerpaulsk', isSkel = true },
    ['a1_necroimprace'] = { id = 'a1_necroimppaulsk', isSkel = true },
    ['a1_necrokharace'] = { id = 'a1_necrokhapaulsk', isSkel = true },
    ['a1_necronordrace'] = { id = 'a1_necronordpaulsk', isSkel = true },
    ['a1_necroorcrace'] = { id = 'a1_necroorcpaulsk', isSkel = true },
    ['a1_necrorgrace'] = { id = 'a1_necrorgpaulsk', isSkel = true },
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

local npcs = {
    ['h'] = 'a1_necroaltmernpc',
    ['a'] = 'a1_necroargnpc',
    ['w'] = 'a1_necrobosmernpc',
    ['b'] = 'a1_necrobretonnpc',
    ['d'] = 'a1_necrodunmernpc',
    ['i'] = 'a1_necroimpnpc',
    ['k'] = 'a1_necrokhanpc',
    ['n'] = 'a1_necronordnpc',
    ['o'] = 'a1_necroorcnpc',
    ['r'] = 'a1_necrorgnpc',
}

local skelHeads = {
    ['a1_necroaltmerrace'] = 'a1_necroaltmerskull',
    ['a1_necroargrace'] = 'a1_necroargskull',
    ['a1_necrobosmerrace'] = 'a1_necrobosmerskull',
    ['a1_necrobretonrace'] = 'a1_necrobretonskull',
    ['a1_necrodunmerrace'] = 'a1_necrodunmerskull',
    ['a1_necroimprace'] = 'a1_necroimpskull',
    ['a1_necrokharace'] = 'a1_necrokhaskull',
    ['a1_necronordrace'] = 'a1_necronordskull',
    ['a1_necroorcrace'] = 'a1_necroorcskull',
    ['a1_necrorgrace'] = 'a1_necrorgskull',
}

return {
    engineHandlers = {
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
            local record = types.NPC.record(target)
            local body = pauls[record.race]
            local generation = nil
            if body.isSkel then
                local npcScript = world.mwscript.getLocalScript(target, data.player)
                generation = npcScript.variables['generation'] + 1
                if generation >= maxGeneration then
                    local player = data.player
                    player:sendEvent("A1NecroDeny", nil)
                    return
                end
            end
            local inv = types.Actor.inventory(target)
            for _, item in ipairs(inv:getAll()) do
                item:moveInto(types.Actor.inventory(data.player))
            end
            local headId
            local skelHead = skelHeads[record.race]
            if skelHead then
                headId = skelHead
            else
                local hair = world.createObject('a1_necroh' .. idHash(record.hair))
                hair:moveInto(types.Actor.inventory(data.player))
                headId = 'a1_necroh' .. idHash(record.head)
            end
            head = world.createObject(headId)
            head:moveInto(types.Actor.inventory(data.player))
            local bodyObj = world.createObject(body.id)
            bodyObj:moveInto(types.Actor.inventory(data.player))
            target:remove()
            if generation then
                async:newUnsavableSimulationTimer(0, function()
                    local paulScript = world.mwscript.getLocalScript(bodyObj, data.player)
                    paulScript.variables['generation'] = generation
                end)
            end
        end,
        A1NecroSummon = function(data)
            local effects = types.Actor.activeEffects(data.player)
            effects:remove('boundboots')
            if not data.platform then
                return
            end
            local inv = types.Actor.inventory(data.player)
            local m = inv:find('ingred_scrap_metal_01')
            if not m then
                return
            end
            m:remove(1)
            local b = inv:find('ingred_bonemeal_01')
            if not b or b.count < 10 then
                return
            end
            b:remove(10)
            local npc = world.createObject(npcs[data.type])
            npc:teleport(data.platform.cell, data.platform.position)
            local body = data.body
            local paulScript = world.mwscript.getLocalScript(body, data.player)
            local generation = paulScript.variables['generation']
            local npcScript = world.mwscript.getLocalScript(npc, data.player)
            npcScript.variables['generation'] = generation
            body:remove()
            local head = data.head
            head:remove()
            incSkill(data.player)
        end,
    },
}
