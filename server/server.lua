local sessions = {}
local sessionCounter = 0

function TranslateCap(str)
    return Locales[Config.Locale] and Locales[Config.Locale][str] or str
end

local function GetOrCreateSession(tableCoords)
    for sessionId, session in pairs(sessions) do
        if session.tableCoords then
            local distance = #(vector3(tableCoords.x, tableCoords.y, tableCoords.z) - session.tableCoords)
            if distance < 1.5 then
                return sessionId, session
            end
        end
    end
    
    sessionCounter = sessionCounter + 1
    sessions[sessionCounter] = {
        place1 = 0,
        place2 = 0,
        started = false,
        grade = 0.5,
        tableCoords = tableCoords
    }
    
    return sessionCounter, sessions[sessionCounter]
end

local function IsTableInUse(tableCoords)
    if not tableCoords or not tableCoords.x or not tableCoords.y or not tableCoords.z then
        return false
    end
    
    local targetCoords = vector3(tableCoords.x, tableCoords.y, tableCoords.z)
    
    for sessionId, session in pairs(sessions) do
        if session.tableCoords then
            local distance = #(targetCoords - session.tableCoords)
            if distance < 1.5 then
                if session.place1 ~= 0 or session.place2 ~= 0 or session.started then
                    return true
                end
            end
        end
    end
    
    return false
end

exports('IsTableInUse', IsTableInUse)

local function GetLocaleMessage(key)
    return TranslateCap(key)
end
exports('GetLocaleMessage', GetLocaleMessage)

Citizen.CreateThread(function()
    Wait(1000)
    for i, props in pairs(Config.Props) do
        GetOrCreateSession(vector3(props.x, props.y, props.z))
    end
end)
  

RegisterNetEvent('evy_arm:check_sv')
AddEventHandler('evy_arm:check_sv', function(position, tableCoords)
    local playerCoords = vector3(position[1] or position.x, position[2] or position.y, position[3] or position.z)
    
    local targetTableCoords = tableCoords
    if not targetTableCoords then
        local closestDistance = 999.0
        for _, props in pairs(Config.Props) do
            local propsCoords = vector3(props.x, props.y, props.z)
            local distance = #(playerCoords - propsCoords)
            if distance < 1.5 and distance < closestDistance then
                closestDistance = distance
                targetTableCoords = propsCoords
            end
        end
    end
    
    if not targetTableCoords then
        TriggerClientEvent('evy_arm:check_cl', source, 'noplace')
        return
    end
    
    local sessionId, session = GetOrCreateSession(targetTableCoords)
    
    if session.place1 == 0 and not session.started then
        session.place1 = source
        TriggerClientEvent('evy_arm:check_cl', source, 'place1')
    elseif session.place2 == 0 and session.place1 ~= 0 then
        session.place2 = source
        TriggerClientEvent('evy_arm:check_cl', source, 'place2')
    else
        TriggerClientEvent('evy_arm:check_cl', source, 'noplace')
        return
    end

    if session.place1 ~= 0 and session.place2 ~= 0 and not session.started then
        session.started = true
        TriggerClientEvent('evy_arm:start_cl', session.place1)
        TriggerClientEvent('evy_arm:start_cl', session.place2)
    end
end)


RegisterNetEvent('evy_arm:updategrade_sv')
AddEventHandler('evy_arm:updategrade_sv', function(gradeUpValue)

    for i, props in pairs(sessions) do

        if props.place1 == source or props.place2 == source then
            props.grade = props.grade + gradeUpValue
            if props.grade <= 0.10 then
                props.grade = -999
            elseif props.grade >= 0.90 then
                props.grade = 999
            end
            
            TriggerClientEvent('evy_arm:updategrade_cl', props.place1, props.grade)
            TriggerClientEvent('evy_arm:updategrade_cl', props.place2, props.grade)
            break
        end

    end

end)

RegisterNetEvent('evy_arm:disband_sv')
AddEventHandler('evy_arm:disband_sv', function(position, tableCoords)
    local playerCoords = vector3(position[1] or position.x, position[2] or position.y, position[3] or position.z)
    local _source = source
    
    local targetSessionId = nil
    local targetTableCoords = tableCoords
    
    if not targetTableCoords then
        local closestDistance = 999.0
        for _, props in pairs(Config.Props) do
            local propsCoords = vector3(props.x, props.y, props.z)
            local distance = #(playerCoords - propsCoords)
            if distance < 1.5 and distance < closestDistance then
                closestDistance = distance
                targetTableCoords = propsCoords
            end
        end
    end
    
    if targetTableCoords then
        for sessionId, session in pairs(sessions) do
            if session.tableCoords then
                local distance = #(playerCoords - session.tableCoords)
                if distance < 1.5 and (session.place1 == _source or session.place2 == _source) then
                    targetSessionId = sessionId
                    break
                end
            end
        end
    end
    
    if targetSessionId and sessions[targetSessionId] then
        local session = sessions[targetSessionId]
        if session.place1 ~= 0 then
            TriggerClientEvent('evy_arm:reset_cl', session.place1)
        end
        if session.place2 ~= 0 then
            TriggerClientEvent('evy_arm:reset_cl', session.place2)
        end
        Wait(100)
        session.started = false
        session.place1 = 0
        session.place2 = 0
        session.grade = 0.5
    end
end)

function resetSession(i)
    sessions[i] = {place1 = 0, place2 = 0, started = false, grade = 0.5}
end
