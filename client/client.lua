function TranslateCap(str)
    return Locales[Config.Locale] and Locales[Config.Locale][str] or str
end

local armWrestleModelHashes = {}
Citizen.CreateThread(function()
    Wait(1000)
    for _, modelName in ipairs(Config.ArmWrestleModels) do
        table.insert(armWrestleModelHashes, GetHashKey(modelName))
    end
end)

local function GetClosestArmWrestleTable(playerCoords, maxDistance)
    local closestTable = nil
    local closestDistance = maxDistance or 2.0
    local searchRadius = maxDistance or 2.0
    
    for _, modelHash in ipairs(armWrestleModelHashes) do
        local table = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, searchRadius, modelHash, false, false, false)
        
        if DoesEntityExist(table) then
            local tableCoords = GetEntityCoords(table)
            local distance = #(playerCoords - tableCoords)
            
            if distance < closestDistance then
                closestDistance = distance
                closestTable = table
                break
            end
        end
    end
    
    return closestTable, closestDistance
end

local place = 0
local started = false
local grade = 0.5
local disabledControl = 0
local isNearTable = false
local currentInteractionId = nil
local createdProps = {}

Citizen.CreateThread(function()
	while true do
    if place ~= 0 or started then
      Wait(10000)
    elseif #Config.Props > 0 then
      local playerCoords = GetEntityCoords(PlayerPedId())
      local minDistance = 999.0
      
      for i, modelConfig in pairs(Config.Props) do
        local distance = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, modelConfig.x, modelConfig.y, modelConfig.z)
        if distance < minDistance then
          minDistance = distance
          if minDistance < 50 then
            break
          end
        end
      end
      
      if minDistance < 50 then
        for i, modelConfig in pairs(Config.Props) do
          local distance = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, modelConfig.x, modelConfig.y, modelConfig.z)
          if distance < 50 then
            local modelHash = GetHashKey(modelConfig.model)
            local thisTable = GetClosestObjectOfType(modelConfig.x, modelConfig.y, modelConfig.z, 1.5, modelHash, false, false, false)
            if DoesEntityExist(thisTable) then
              SetEntityHeading(thisTable)
              PlaceObjectOnGroundProperly(thisTable)
            else
              thisTable = CreateObject(modelHash, modelConfig.x, modelConfig.y, modelConfig.z, false, false, false)
              SetEntityHeading(thisTable)
              PlaceObjectOnGroundProperly(thisTable)
              if DoesEntityExist(thisTable) then
                table.insert(createdProps, thisTable)
              end
            end
          elseif distance >= 50 then
            local modelHash = GetHashKey(modelConfig.model)
            local thisTable = GetClosestObjectOfType(modelConfig.x, modelConfig.y, modelConfig.z, 1.5, modelHash, false, false, false)
            if DoesEntityExist(thisTable) then
              DeleteEntity(thisTable)
            end
          end
        end
        Wait(5000)
      else
        Wait(30000)
      end
    else
      Wait(10000)
    end		
	end
end)


Citizen.CreateThread(function()
  while true do
    if place ~= 0 or started then
      Wait(30000)
      isNearTable = false
    else
      local playerPos = GetEntityCoords(PlayerPedId())
      local nearestDistance = 999.0
      
      local closestTable, tableDistance = GetClosestArmWrestleTable(playerPos, 50.0)
      if closestTable and tableDistance < nearestDistance then
        nearestDistance = tableDistance
      end
      
      if #Config.Props > 0 then
        for i, modelConfig in pairs(Config.Props) do
          local distance = Vdist(playerPos.x, playerPos.y, playerPos.z, modelConfig.x, modelConfig.y, modelConfig.z)
          if distance < nearestDistance then
            nearestDistance = distance
            if nearestDistance <= 3.0 then
              break
            end
          end
        end
      end
      
      if nearestDistance > 50.0 then
        Wait(10000)
        isNearTable = false
      else
        local waitTime = 2000
        if nearestDistance <= 20.0 then
          if nearestDistance <= 10.0 then
            if nearestDistance <= 5.0 then
              if nearestDistance <= 3.0 then
                waitTime = 50
              else
                waitTime = 200
              end
            else
              waitTime = 500
            end
          else
            waitTime = 1000
          end
        end
        
        Wait(waitTime)

        if place == 0 and not IsPedInAnyVehicle(PlayerPedId(), false) and nearestDistance <= 3.0 then
          local closestTable, distance = GetClosestArmWrestleTable(playerPos, 2.0)
          
          if closestTable and distance < 2.0 then
            isNearTable = true
            
            if Config.useLfInteract and GetResourceState('LfInteract') == 'started' then
              if not currentInteractionId then
                local tableCoords = GetEntityCoords(closestTable)
                if exports['LfInteract'] and exports['LfInteract'].AddInteraction then
                  currentInteractionId = exports['LfInteract']:AddInteraction({
                    id = 'lfarmwrestling:join',
                    coords = vector3(tableCoords.x, tableCoords.y, tableCoords.z + 0.3),
                    distance = Config.lfInteract.distance,
                    interactDst = Config.lfInteract.interactDst,
                    options = {
                      {
                        label = TranslateCap('join_interact'),
                        action = function()
                          if place == 0 and not IsPedInAnyVehicle(PlayerPedId(), false) then
                            checkFunction()
                          end
                        end
                      }
                    }
                  })
                end
              end
            else
              alert(TranslateCap('join'))
            end
          else
            isNearTable = false
            if Config.useLfInteract and currentInteractionId then
              if exports['LfInteract'] and exports['LfInteract'].RemoveInteraction then
                exports['LfInteract']:RemoveInteraction(currentInteractionId)
              end
              currentInteractionId = nil
            end
          end
        else
          isNearTable = false
          if Config.useLfInteract and currentInteractionId then
            if exports['LfInteract'] and exports['LfInteract'].RemoveInteraction then
              exports['LfInteract']:RemoveInteraction(currentInteractionId)
            end
            currentInteractionId = nil
          end
        end
      end
    end
  end
end)

Citizen.CreateThread(function()
  while true do
    if isNearTable then
      Wait(1)
      if IsControlJustPressed(0, 38) and place == 0 and not IsPedInAnyVehicle(PlayerPedId(), false) then
        checkFunction()
      end
    else
      Wait(1000)
    end
  end
end)

Citizen.CreateThread(function()
  while true do
    Wait(0)
    
    if disabledControl == 1 then
      DisableControlAction(2, 71, true)
      DisableControlAction(2, 72, true)
      DisableControlAction(2, 63, true)
      DisableControlAction(2, 64, true)
      DisableControlAction(2, 75, true)
      DisableControlAction(2, 32, true)
      DisableControlAction(2, 33, true)
      DisableControlAction(2, 34, true)
      DisableControlAction(2, 35, true)
      DisableControlAction(2, 37, true)
      DisableControlAction(2, 23, true)
      DisableControlAction(2, 246, true)
    elseif disabledControl == 2 then
      DisableControlAction(2, 71, true)
      DisableControlAction(2, 72, true)
      DisableControlAction(2, 63, true)
      DisableControlAction(2, 64, true)
      DisableControlAction(2, 75, true)
      DisableControlAction(2, 73, true)
      DisableControlAction(2, 32, true)
      DisableControlAction(2, 33, true)
      DisableControlAction(2, 34, true)
      DisableControlAction(2, 35, true)
      DisableControlAction(2, 37, true)
      DisableControlAction(2, 23, true)
      DisableControlAction(2, 38, true)
      DisableControlAction(2, 246, true)
    else
      Wait(100)
    end
  end
end)


function timer()


    PlaySoundFrontend(-1, "Out_Of_Area", "DLC_Lowrider_Relay_Race_Sounds", 0)
    local T = GetGameTimer()
    while GetGameTimer() - T < 1000 do
      Wait(0)
      Draw2DText(0.5, 0.4, ("~s~3"), 3.0)
    end
    PlaySoundFrontend(-1, "Out_Of_Area", "DLC_Lowrider_Relay_Race_Sounds", 0)
    local T = GetGameTimer()
    while GetGameTimer() - T < 1000 do
      Wait(0)
      Draw2DText(0.5, 0.4, ("~s~2"), 3.0)
    end
    PlaySoundFrontend(-1, "Out_Of_Area", "DLC_Lowrider_Relay_Race_Sounds", 0)
    local T = GetGameTimer()
    while GetGameTimer() - T < 1000 do
      Wait(0)
      Draw2DText(0.5, 0.4, ("~s~1"), 3.0)
    end
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 0)
  
    local T = GetGameTimer()
    while GetGameTimer() - T < 1000 do
      Wait(0)
      Draw2DText(0.4, 0.4, ("~s~GO ~w~!"), 3.0)
    end
    

end


local isChecking = false

function checkFunction()
  if isChecking or place ~= 0 or started then
    return
  end
  
  isChecking = true
  local playerCoords = GetEntityCoords(PlayerPedId())
  local closestTable, distance = GetClosestArmWrestleTable(playerCoords, 1.5)
  
  if closestTable and DoesEntityExist(closestTable) then
    local position = GetEntityCoords(PlayerPedId())
    local tableCoords = GetEntityCoords(closestTable)
    TriggerServerEvent('evy_arm:check_sv', {position.x, position.y, position.z}, {x = tableCoords.x, y = tableCoords.y, z = tableCoords.z})
  else
    isChecking = false
  end
end

RegisterNetEvent('evy_arm:updategrade_cl')
AddEventHandler('evy_arm:updategrade_cl', function(gradeUpValue)

  grade = gradeUpValue

end)

RegisterNetEvent('evy_arm:start_cl')
AddEventHandler('evy_arm:start_cl', function()
  started = true
  if place == 1 then

    disabledControl = 2
    timer()

    PlayAnim(PlayerPedId(), "mini@arm_wrestling", "sweep_a", 1)
    SetEntityAnimSpeed(PlayerPedId(), "mini@arm_wrestling", "sweep_a", 0.0)
    SetEntityAnimCurrentTime(PlayerPedId(), "mini@arm_wrestling", "sweep_a", grade)
    PlayFacialAnim(PlayerPedId(), "electrocuted_1", "facials@gen_male@base")
    disabledControl = 1

    while grade >= 0.10 and grade <= 0.90 do
      Wait(1)
      PlayFacialAnim(PlayerPedId(), "electrocuted_1", "facials@gen_male@base")
      alert(TranslateCap('tuto') .. "~INPUT_PICKUP~")
      SetEntityAnimSpeed(PlayerPedId(), "mini@arm_wrestling", "sweep_a", 0.0)
      SetEntityAnimCurrentTime(PlayerPedId(), "mini@arm_wrestling", "sweep_a", grade)
      if IsControlPressed(0, 38) then
        TriggerServerEvent('evy_arm:updategrade_sv', 0.015) 
        SetEntityAnimCurrentTime(PlayerPedId(), "mini@arm_wrestling", "sweep_a", grade)
        while IsControlPressed(0, 38) do
          Wait(1)
          alert(TranslateCap('tuto') .. "~INPUT_PICKUP~")
          SetEntityAnimCurrentTime(PlayerPedId(), "mini@arm_wrestling", "sweep_a", grade)
        end
      end
    end

    if grade >= 0.90 then
      PlayAnim(PlayerPedId(), "mini@arm_wrestling", "win_a_ped_a", 2)
      ESX.ShowNotification(TranslateCap('win'))
    elseif grade <= 0.10 then
      PlayAnim(PlayerPedId(), "mini@arm_wrestling", "win_a_ped_b", 2)
      ESX.ShowNotification(TranslateCap('lose'))
    end
    Wait(4000)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestTable, _ = GetClosestArmWrestleTable(playerCoords, 1.5)
    local tableCoords = nil
    if closestTable and DoesEntityExist(closestTable) then
      tableCoords = GetEntityCoords(closestTable)
    end
    TriggerServerEvent('evy_arm:disband_sv', {playerCoords.x, playerCoords.y, playerCoords.z}, tableCoords and {x = tableCoords.x, y = tableCoords.y, z = tableCoords.z} or nil)
    return

  elseif place == 2 then

    disabledControl = 2
    timer()

    PlayAnim(PlayerPedId(), "mini@arm_wrestling", "sweep_b", 1)
    SetEntityAnimSpeed(PlayerPedId(), "mini@arm_wrestling", "sweep_b", 0.0)
    SetEntityAnimCurrentTime(PlayerPedId(), "mini@arm_wrestling", "sweep_b", grade)
    PlayFacialAnim(PlayerPedId(), "electrocuted_1", "facials@gen_male@base")
    disabledControl = 1

    while grade >= 0.10 and grade <= 0.90 do
      Wait(1)
      PlayFacialAnim(PlayerPedId(), "electrocuted_1", "facials@gen_male@base")
      alert(TranslateCap('tuto') .. "~INPUT_PICKUP~")
      SetEntityAnimSpeed(PlayerPedId(), "mini@arm_wrestling", "sweep_b", 0.0)
      SetEntityAnimCurrentTime(PlayerPedId(), "mini@arm_wrestling", "sweep_b", grade)
      if IsControlPressed(0, 38) then
        TriggerServerEvent('evy_arm:updategrade_sv', -0.015) 
        SetEntityAnimCurrentTime(PlayerPedId(), "mini@arm_wrestling", "sweep_b", grade)
        while IsControlPressed(0, 38) do
          Wait(1)
          alert(TranslateCap('tuto') .. "~INPUT_PICKUP~")
          SetEntityAnimCurrentTime(PlayerPedId(), "mini@arm_wrestling", "sweep_b", grade)
        end
      end
    end

    if grade <= 0.10 then
      PlayAnim(PlayerPedId(), "mini@arm_wrestling", "win_a_ped_a", 2)
      ESX.ShowNotification(TranslateCap('win'))
    elseif grade >= 0.90 then
      PlayAnim(PlayerPedId(), "mini@arm_wrestling", "win_a_ped_b", 2)
      ESX.ShowNotification(TranslateCap('lose'))
    end
    Wait(4000)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestTable, _ = GetClosestArmWrestleTable(playerCoords, 1.5)
    local tableCoords = nil
    if closestTable and DoesEntityExist(closestTable) then
      tableCoords = GetEntityCoords(closestTable)
    end
    TriggerServerEvent('evy_arm:disband_sv', {playerCoords.x, playerCoords.y, playerCoords.z}, tableCoords and {x = tableCoords.x, y = tableCoords.y, z = tableCoords.z} or nil)
    return

  end
end)

RegisterNetEvent('evy_arm:check_cl')
AddEventHandler('evy_arm:check_cl', function(args)
  isChecking = false
  
  if Config.useLfInteract and currentInteractionId then
    if exports['LfInteract'] and exports['LfInteract'].RemoveInteraction then
      exports['LfInteract']:RemoveInteraction(currentInteractionId)
    end
    currentInteractionId = nil
  end
  
  local table = 0
  if args == 'place1' then
    place = 1

    local playerCoords = GetEntityCoords(PlayerPedId())
    table, _ = GetClosestArmWrestleTable(playerCoords, 1.5)
    
    if not table or not DoesEntityExist(table) then
      return
    end
    disabledControl = 2

    SetEntityNoCollisionEntity(PlayerPedId(), table, false)
    SetEntityHeading(PlayerPedId(), GetEntityHeading(table))
    Wait(100)
    SetEntityCoords(PlayerPedId(), GetOffsetFromEntityInWorldCoords(table, -0.20, 0.0, 0.0).x, GetOffsetFromEntityInWorldCoords(table, 0.0, -0.65, 0.0).y, GetEntityCoords(PlayerPedId()).z-1)
    FreezeEntityPosition(PlayerPedId(), true)
    PlayAnim(PlayerPedId(), "mini@arm_wrestling","aw_ig_intro_alt1_a", 2)
    while ( GetEntityAnimCurrentTime(PlayerPedId(), "mini@arm_wrestling", "aw_ig_intro_alt1_a") < 0.95 ) do
      Wait(0)
    end
    PlayAnim(PlayerPedId(), "mini@arm_wrestling", "nuetral_idle_a", 1)
    disabledControl = 1

    while not started do

      Wait(0)
      
      alert(TranslateCap('wait') .. "~n~~r~" .. TranslateCap('leave'))
      
      if IsControlPressed(2, 73) or IsPedRagdoll(PlayerPedId()) or IsControlPressed(2, 200) or IsControlPressed(2, 214) then
        SetEntityNoCollisionEntity(PlayerPedId(), table, true)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local tableCoords = GetEntityCoords(table)
        TriggerServerEvent('evy_arm:disband_sv', {playerCoords.x, playerCoords.y, playerCoords.z}, {x = tableCoords.x, y = tableCoords.y, z = tableCoords.z})
        return
      end

    end
  elseif args == 'place2' then

    place = 2
    local playerCoords = GetEntityCoords(PlayerPedId())
    table, _ = GetClosestArmWrestleTable(playerCoords, 1.5)
    
    if not table or not DoesEntityExist(table) then
      return
    end
    disabledControl = 2

    SetEntityNoCollisionEntity(PlayerPedId(), table, false)
    SetEntityHeading(PlayerPedId(), GetEntityHeading(table)-180)
    Wait(100)
    SetEntityCoords(PlayerPedId(), GetOffsetFromEntityInWorldCoords(table, 0.0, 0.0, 0.0).x, GetOffsetFromEntityInWorldCoords(table, 0.0, 0.50, 0.0).y, GetEntityCoords(PlayerPedId()).z-1)
    
    FreezeEntityPosition(PlayerPedId(), true)
    PlayAnim(PlayerPedId(), "mini@arm_wrestling","aw_ig_intro_alt1_b", 2)
    while ( GetEntityAnimCurrentTime(PlayerPedId(), "mini@arm_wrestling", "aw_ig_intro_alt1_b") < 0.95 ) do
      Wait(0)
    end
    PlayAnim(PlayerPedId(), "mini@arm_wrestling", "nuetral_idle_b", 1)
    disabledControl = 1
    
    while not started do
      
      Wait(0)
      alert(TranslateCap('wait') .. "~n~~r~" .. TranslateCap('leave'))
          
      if IsControlPressed(2, 73) or IsPedRagdoll(PlayerPedId()) or IsControlPressed(2, 200) or IsControlPressed(2, 214) then
        SetEntityNoCollisionEntity(PlayerPedId(), table, true)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local tableCoords = GetEntityCoords(table)
        TriggerServerEvent('evy_arm:disband_sv', {playerCoords.x, playerCoords.y, playerCoords.z}, {x = tableCoords.x, y = tableCoords.y, z = tableCoords.z})
        return
      end

    end

  elseif args == 'noplace' then
    isChecking = false
    ESX.ShowNotification(TranslateCap('full'))
  end

end)

RegisterNetEvent('evy_arm:reset_cl')
AddEventHandler('evy_arm:reset_cl', function()
  local playerCoords = GetEntityCoords(PlayerPedId())
  local tableId, _ = GetClosestArmWrestleTable(playerCoords, 1.5)
  
  if tableId and DoesEntityExist(tableId) then
    SetEntityNoCollisionEntity(PlayerPedId(), tableId, true)
  end
  
  if Config.useLfInteract and currentInteractionId then
    if exports['LfInteract'] and exports['LfInteract'].RemoveInteraction then
      exports['LfInteract']:RemoveInteraction(currentInteractionId)
    end
    currentInteractionId = nil
  end
  
  ClearPedTasks(PlayerPedId())
  place = 0
  started = false
  grade = 0.5
  disabledControl = 0
  isNearTable = false
  FreezeEntityPosition(PlayerPedId(), false)
  
end)

function PlayAnim(ped, dict, name, flag)
  RequestAnimDict(dict)
  while not HasAnimDictLoaded(dict) do
    Citizen.Wait(0)
  end
  TaskPlayAnim(ped, dict, name, 1.5, 1.5, -1, flag, 0.0, false, false, false)
end

function alert(msg)
  SetTextComponentFormat("STRING")
  AddTextComponentString(msg)
  DisplayHelpTextFromStringLabel(0,0,1,-1)
end	

function Draw2DText(x, y, text, scale)
  SetTextFont(4)
  SetTextProportional(7)
  SetTextScale(scale, scale)
  SetTextColour( 198, 25, 66, 255)
  SetTextDropShadow(0, 0, 0, 0,255)
  SetTextDropShadow()
  SetTextEdge(4, 0, 0, 0, 255)
  SetTextOutline()
  SetTextEntry("STRING")
  AddTextComponentString(text)
  DrawText(x, y)
end

function DrawAdvancedNativeText(x,y,w,h,sc, text, r,g,b,a,font,jus)
  SetTextFont(font)
  SetTextScale(sc, sc)
N_0x4e096588b13ffeca(jus)
  SetTextColour(254, 254, 254, 255)
  SetTextEntry("STRING")
  AddTextComponentString(text)
DrawText(x - 0.1+w, y - 0.02+h)
end

AddEventHandler('onResourceStop', function(resourceName)
  if GetCurrentResourceName() == resourceName then
    for _, prop in ipairs(createdProps) do
      if DoesEntityExist(prop) then
        DeleteEntity(prop)
      end
    end
    
    if #Config.Props > 0 then
      for _, modelConfig in pairs(Config.Props) do
        local modelHash = GetHashKey(modelConfig.model)
        local prop = GetClosestObjectOfType(modelConfig.x, modelConfig.y, modelConfig.z, 1.5, modelHash, false, false, false)
        if DoesEntityExist(prop) then
          DeleteEntity(prop)
        end
      end
    end
    
    if Config.useLfInteract and currentInteractionId then
      if exports['LfInteract'] and exports['LfInteract'].RemoveInteraction then
        exports['LfInteract']:RemoveInteraction(currentInteractionId)
      end
    end
  end
end)
