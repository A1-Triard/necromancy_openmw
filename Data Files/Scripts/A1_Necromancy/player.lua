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

I.AnimationController.addTextKeyHandler('spellcast', function(groupname, key)
    if string.sub(key, -7) == 'release' then
        async:newUnsavableSimulationTimer(0.5, function()
            local spells = types.Actor.activeSpells(self)
            if spells:isSpellActive('a1_necroprepare') then
                withCrosshairObject(function(target)
                    if target and types.NPC.objectIsInstance(target) and types.Actor.isDead(target) then
                        local head = types.NPC.record(target).head
                        ui.showMessage(head)
                        core.sendGlobalEvent('A1NecroPrepare', {
                            player = self.object, target = target
                        })
                    else
                        ui.showMessage('Заклинание не нашло цель')
                    end
                end)
            end
        end)
    end
end)
