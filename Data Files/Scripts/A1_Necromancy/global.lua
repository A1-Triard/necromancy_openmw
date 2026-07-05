local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local async = require('openmw.async')

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
    ['a1_necroaltmerrace'] = 'a1_necroaltmerpaulsk',
    ['a1_necroargrace'] = 'a1_necroargpaulsk',
    ['a1_necrobosmerrace'] = 'a1_necrobosmerpaulsk',
    ['a1_necrobretonrace'] = 'a1_necrobretonpaulsk',
    ['a1_necrodunmerrace'] = 'a1_necrodunmerpaulsk',
    ['a1_necroimprace'] = 'a1_necroimppaulsk',
    ['a1_necrokharace'] = 'a1_necrokhapaulsk',
    ['a1_necronordrace'] = 'a1_necronordpaulsk',
    ['a1_necroorcrace'] = 'a1_necroorcpaulsk',
    ['a1_necrorgrace'] = 'a1_necrorgpaulsk',
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
            local inv = types.Actor.inventory(target)
            for _, item in ipairs(inv:getAll()) do
                item:moveInto(types.Actor.inventory(data.player))
            end
            local record = types.NPC.record(target)
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
            local body = pauls[record.race]
            local bodyObj = world.createObject(body)
            bodyObj:moveInto(types.Actor.inventory(data.player))
            target:remove()
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
            body:remove()
            local head = data.head
            head:remove()
            incSkill(data.player)
        end,
    },
}
