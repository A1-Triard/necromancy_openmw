local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')
local camera = require('openmw.camera')
local nearby = require('openmw.nearby')
local util = require('openmw.util') 
local core = require('openmw.core')

local function withCrosshairObject(callback)
    local startPos
    if camera.getMode() == camera.MODE.FirstPerson then
        startPos = camera.getPosition()
    else
        startPos = camera.getTrackedPosition()
    end
    local direction = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
    local endPos = startPos + direction * 200
    nearby.asyncCastRenderingRay(async:callback(function(result)
        if result.hit and result.hitObject then
            callback(result.hitObject)
        else
            callback(nil)
        end
    end), startPos, endPos, { ignore = self.object })
end

local skeletons = {
    ['a1_necroaltmerpaulsk'] = 'h',
    ['a1_necroargpaulsk'] = 'a',
    ['a1_necrobosmerpaulsk'] = 'w',
    ['a1_necrobretonpaulsk'] = 'b',
    ['a1_necrodunmerpaulsk'] = 'd',
    ['a1_necroimppaulsk'] = 'i',
    ['a1_necrokhapaulsk'] = 'k',
    ['a1_necronordpaulsk'] = 'n',
    ['a1_necroorcpaulsk'] = 'o',
    ['a1_necrorgpaulsk'] = 'r',
}

local skulls = {
    ['a1_necroaltmerskull'] = 'h',
    ['a1_necroargskull'] = 'a',
    ['a1_necrobosmerskull'] = 'w',
    ['a1_necrobretonskull'] = 'b',
    ['a1_necrodunmerskull'] = 'd',
    ['a1_necroimpskull'] = 'i',
    ['a1_necrokhaskull'] = 'k',
    ['a1_necronordskull'] = 'n',
    ['a1_necroorcskull'] = 'o',
    ['a1_necrorgskull'] = 'r',
}

local function summon(callback)
    local inv = types.Actor.inventory(self.object)
    if inv:countOf('ingred_scrap_metal_01') == 0 then
        ui.showMessage('Для создания скелета нужны обрезки металла')
        callback(nil)
        return
    end
    if inv:countOf('ingred_bonemeal_01') < 10 then
        ui.showMessage('Для создания скелета нужно 10 единиц костяной муки')
        callback(nil)
        return
    end
    local skel = nil
    local skelType
    for _, i in ipairs(nearby.items) do
        if types.Armor.objectIsInstance(i) then
            local s = skeletons[types.Armor.record(i).id]
            if s then
                local d = self.object.position - i.position
                if d:length() <= 200 then
                    skel = i
                    skelType = s
                    break
                end
            end
        end
    end
    if not skel then
        ui.showMessage('Заклинание не может найти тело')
        callback(nil)
    end
    local platformStartPos = skel.position
    local platformEndPos = platformStartPos + util.vector3(0, 0, -200)
    nearby.asyncCastRenderingRay(async:callback(function(result)
        local platform = nil
        if result.hit and result.hitObject then
            if types.Static.objectIsInstance(result.hitObject) then
                local id = types.Static.record(result.hitObject).id
                if
                       id == 'in_velothi_ashpit_01'
                    or id == 'in_velothi_ashpit_02'
                    or id == 'in_velothi_platform_01'
                then
                    platform = result.hitObject
                end
            end
        end
        if not platform then
            ui.showMessage('Для поднятия нежити нужна платформа')
            callback(nil)
            return
        end
        local skull = nil
        local skullType
        for _, i in ipairs(nearby.items) do
            if types.Miscellaneous.objectIsInstance(i) then
                local s = skulls[types.Miscellaneous.record(i).id]
                if s then
                    local d = platform.position - i.position
                    if d:length() <= 200 then
                        skull = i
                        skullType = s
                        break
                    end
                end
            end
        end
        if not skull or skullType ~= skelType then
            ui.showMessage('Заклинание не может найти голову')
            callback(nil)
            return
        end
        callback({
            platform = platform,
            type = skelType,
            body = skel,
            head = skull,
        })
    end), platformStartPos, platformEndPos, { ignore = skel })
end

local supportedRaces = {
    ['high elf'] = true,
    ['argonian'] = true,
    ['wood elf'] = true,
    ['breton'] = true,
    ['dark elf'] = true,
    ['imperial'] = true,
    ['khajiit'] = true,
    ['nord'] = true,
    ['orc'] = true,
    ['redguard'] = true,
    ['a1_necroaltmerrace'] = true,
    ['a1_necroargrace'] = true,
    ['a1_necrobosmerrace'] = true,
    ['a1_necrobretonrace'] = true,
    ['a1_necrodunmerrace'] = true,
    ['a1_necroimprace'] = true,
    ['a1_necrokharace'] = true,
    ['a1_necronordrace'] = true,
    ['a1_necroorcrace'] = true,
    ['a1_necrorgrace'] = true,
}

I.AnimationController.addTextKeyHandler('spellcast', function(groupname, key)
    if string.sub(key, -7) == 'release' then
        async:newUnsavableSimulationTimer(0, function()
            local spells = types.Actor.activeSpells(self)
            if spells:isSpellActive('a1_necroprepare') then
                withCrosshairObject(function(target)
                    if
                            target
                        and types.NPC.objectIsInstance(target)
                        and types.Actor.isDead(target)
                        and supportedRaces[types.NPC.record(target).race]
                    then
                        core.sendGlobalEvent('A1NecroPrepare', {
                            player = self.object, target = target
                        })
                    else
                        ui.showMessage('Заклинание не нашло цель')
                    end
                end)
            end
            if spells:isSpellActive('a1_necrosummon') then
                summon(function(s)
                    local platform
                    local type
                    local body
                    local head
                    if s then
                        platform = s.platform
                        type = s.type
                        body = s.body
                        head = s.head
                    else
                        platform = nil
                        type = nil
                        body = nil
                        head = nil
                    end
                    core.sendGlobalEvent('A1NecroSummon', {
                        player = self.object,
                        platform = platform,
                        type = type,
                        body = body,
                        head = head,
                    })
                end)
            end
        end)
    end
end)

return {
    eventHandlers = {
        A1NecroDeny = function(data)
            ui.showMessage('Этот скелет слишком ветхий')
        end,
    },
}
