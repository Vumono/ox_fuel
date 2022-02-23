local inStation = false
local isFueling = false
local inStationInterval


local function findClosestPump(coords)
    local closest = 4
    local pump

    if not pumps[inStation] then return false end

    for i = 1, #pumps[inStation] do
        local distance = #(coords - pumps[inStation][i])
        if distance < closest then
            closest = distance
            pump = pumps[inStation][i]
        end
    end

    if closest < 4 then
        return pump
    end

    return false
end

local function isVehicleCloseEnough(playerCoords, vehicle)
    return #(GetEntityCoords(vehicle) - playerCoords) <= 3 or false
end

local function notify(message)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(0,1)
end

local stations = {}
for i = 1, #Config.stations do
    local station = Config.stations[i]
    stations[i] = BoxZone:Create(station.coords, station.length, station.width, {
        name = ('station-%s'):format(i),
        heading = station.heading,
        minZ = station.minZ,
        maxZ = station.maxZ,
        debugPoly = false
    })
end

for i = 1, #stations do
    stations[i]:onPlayerInOut(function(isInside)
        inStation = isInside and i
        if inStation and Config.usedrawtextui then
            TriggerEvent('cd_drawtextui:ShowUI', 'show', 'Gas Station')
        elseif not inStation and Config.usedrawtextui then
            TriggerEvent('cd_drawtextui:HideUI')
        end
        if not Config.qtargetcar and not Config.qtargetpump and not inStationInterval and isInside then
            inStationInterval = SetInterval(function()
                local ped = PlayerPedId()
                local playerCoords = GetEntityCoords(ped)
                
                if not findClosestPump(playerCoords) then return end

                if IsPedInAnyVehicle(ped) then
                    DisplayHelpTextThisFrame('fuelLeaveVehicleText', false)
                elseif not isFueling then
                    local vehicle = GetPlayersLastVehicle()
                    if not isVehicleCloseEnough(playerCoords, vehicle) and Config.petrolCan.enabled then
                        DisplayHelpTextThisFrame('petrolcanHelpText', false)
                    else
                        DisplayHelpTextThisFrame('fuelHelpText', false)
                    end
                end
            end)
        elseif Config.qtargetcar and not inStationInterval and isInside then
            inStationInterval = SetInterval(function()
                local ped = PlayerPedId()
                local playerCoords = GetEntityCoords(ped)
                
                if not findClosestPump(playerCoords) then return end

                if IsPedInAnyVehicle(ped) then
                    DisplayHelpTextThisFrame('fuelLeaveVehicleText', false)
                elseif not isFueling then
                    local vehicle = GetPlayersLastVehicle()
                    if not isVehicleCloseEnough(playerCoords, vehicle) and Config.petrolCan.enabled then
                        DisplayHelpTextThisFrame('petrolcanHelpText', false)
                    else
                        DisplayHelpTextThisFrame('fuelHelpText', false)
                    end
                end
            end)
                exports.qtarget:AddTargetBone({'wheel_lr','wheel_rr'},{ 
                    options = {
                        {
                            icon = "fas fa-gas-pump",
                            label = "Fuel vehicle",
                            canInteract = function()
                                if isInside then
                                    return true
                                end
                                return false
                            end,
                            action = function(entity)
                                TargetFueling(entity)
                            end
                        },
                    },
                    distance = 1.5
                })
                exports.qtarget:AddTargetModel({-2007231801, 1339433404,1694452750,1933174915,-462817101,-469694731,-164877493}, {
                    options = {
                        {
                            icon = "fas fa-oil-can",
                            label = "Get petrol Can",
                            canInteract = function()
                                if isInside then
                                    return true
                                end
                                return false
                            end,
                            action = function()
                                local playerCoords = GetEntityCoords(PlayerPedId())
                                local pumpCoord = findClosestPump(playerCoords)
                                GetPetrolCan(pumpCoord)
                            end
                        },
                    },
                    distance = 3.5
                })
        elseif Config.qtargetpump and not inStationInterval and isInside then
            exports.qtarget:AddTargetModel({-2007231801, 1339433404,1694452750,1933174915,-462817101,-469694731,-164877493}, {
                options = {
                    {
                        icon = "fas fa-gas-pump",
                        label = "Fuel vehicle",
                        canInteract = function()
                            if isInside then
                                return true
                            end
                            return false
                        end,
                        action = function()
                            TargetFueling()
                        end
                    },
                    {
                        icon = "fas fa-oil-can",
                        label = "Get petrol Can",
                        canInteract = function()
                            if isInside then
                                return true
                            end
                            return false
                        end,
                        action = function()
                            local playerCoords = GetEntityCoords(PlayerPedId())
                            local pumpCoord = findClosestPump(playerCoords)
                            GetPetrolCan(pumpCoord)
                        end
                    },
                },
                distance = 3.5
            })
            
        elseif not isInside and inStationInterval then
            ClearInterval(inStationInterval)
            inStationInterval = nil
        end
    end)

    if Config.showBlips == 2 then
        local coords = stations[i]:getBoundingBoxCenter()
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 415)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.6)
        SetBlipColour(blip, 23)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.blipname)
        EndTextCommandSetBlipName(blip)
    end
end

if Config.showBlips == 1 then
    local currentBlip
    local closestStation
    local currentStation

    SetInterval(function()
        local playerCoords = GetEntityCoords(PlayerPedId())
        local closestDistance

        for i = 1, #stations do
            local station = stations[i]
            local distance = #(playerCoords - station:getBoundingBoxCenter())

            if not closestDistance or distance < closestDistance then
                closestDistance = distance
                closestStation = station
            end
        end

        if not currentStation or closestStation ~= currentStation then
            if DoesBlipExist(currentBlip) then
                RemoveBlip(currentBlip)
            end

            local coords = closestStation:getBoundingBoxCenter()
            currentBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipSprite(currentBlip, 415)
            SetBlipDisplay(currentBlip, 4)
            SetBlipScale(currentBlip, 0.6)
            SetBlipColour(currentBlip, 23)
            SetBlipAsShortRange(currentBlip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(Config.blipname)
            EndTextCommandSetBlipName(currentBlip)
        end

        currentStation = closestStation
    end, 5000)
end

-- Synchronize fuel
SetInterval(function()
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(ped, false)

	if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped or not GetIsVehicleEngineRunning(vehicle) then
        return
    end

    local usage = Config.rpmUsage[math.floor(GetVehicleCurrentRpm(vehicle) * 10) / 10]
    local multiplier = Config.classUsage[GetVehicleClass(vehicle)] or 1.0

    local Vehicle = Entity(vehicle).state
    local fuel = Vehicle.fuel

    local newFuel = fuel and fuel - usage * multiplier or GetVehicleFuelLevel(vehicle)

    if newFuel < 0 or newFuel > 100 then
        newFuel = GetVehicleFuelLevel(vehicle)
    end

    SetVehicleFuelLevel(vehicle, newFuel)
    print(newFuel) -- debug
    Vehicle:set('fuel', newFuel, true)
end, 1000)

local function StartFueling(vehicle, fuelingMode)
    isFueling = true
    local ped = PlayerPedId()
    local Vehicle = Entity(vehicle).state
    local fuel = Vehicle.fuel
    local duration = math.ceil((100 - fuel) / Config.refillValue) * Config.refillTick
    local price, moneyAmount 

    if 100 - fuel < Config.refillValue then
        isFueling = false
        return notify('Tank full')
    end

    if fuelingMode == 'pump' then 
        price = 0
        moneyAmount = exports.ox_inventory:Search(2, 'money')
    end
    
    TaskTurnPedToFaceEntity(ped, vehicle, duration)

    Wait(500)

    exports.ox_inventory:Progress({
        duration = duration,
        label = 'Fueling vehicle',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'timetable@gardener@filling_can',
            clip = 'gar_ig_5_filling_can',
            flags = 49,
        },
    }, function(cancel)
        if cancel then
            isFueling = false
        end
    end)

    while isFueling do

        -- Commented out for debug
        -- if price >= moneyAmount then
        --     exports.ox_inventory:CancelProgress()
        -- end

        fuel += Config.refillValue
        
        if fuelingMode == 'pump' then 
            price += Config.priceTick 
        end

        if fuelingMode == 'can' then 
            -- reduce can durability
        end

        -- if can durability is 0, keep fuel at current level and isFueling false
        -- elseif...
        if(fuel >= 100) then
            isFueling = false
            fuel = 100.0
        end

        Wait(Config.refillTick)
    end

    Vehicle:set('fuel', fuel, true)
    SetVehicleFuelLevel(vehicle, fuel)
    if fuelingMode == 'pump' then TriggerServerEvent('ox_fuel:pay', price) end 
    -- DEBUG
    notify(fuel)
end

function GetPetrolCan(pumpCoord)
    local ped = PlayerPedId()
    local petrolCan = exports.ox_inventory:Search('count', 'WEAPON_PETROLCAN')

    LocalPlayer.state.invBusy = true

    TaskTurnPedToFaceCoord(ped, pumpCoord, Config.petrolCan.duration) 
    -- Linden broke this changing from entity too coord, needs a better solution

    Wait(500)

    exports.ox_inventory:Progress({
        duration = Config.petrolCan.duration,
        label = 'Fueling can',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'timetable@gardener@filling_can',
            clip = 'gar_ig_5_filling_can',
            flags = 49,
        },
    }, function(cancel)
        LocalPlayer.state.invBusy = false
        if not cancel then
            if petrolCan > 0 then
                return TriggerServerEvent('ox_fuel:fuelCan', true, Config.petrolCan.refillPrice)
            else 
                return TriggerServerEvent('ox_fuel:fuelCan', false, Config.petrolCan.price)
            end
        else
            return false
        end
    end)
end

function TargetFueling(entity)

    local ped = PlayerPedId()
    local vehicle = GetPlayersLastVehicle() or entity
    local petrolCan = GetSelectedPedWeapon(ped) == `WEAPON_PETROLCAN` and true or false
    local playerCoords = GetEntityCoords(ped)
    local isNearPump = findClosestPump(playerCoords)
    local moneyAmount = Config.inventory and exports.ox_inventory:Search(2, 'money') or 0

    if not petrolCan then
        --if not inStation or isFueling or IsPedInAnyVehicle(ped) then return print('skipping fuel -- debug')  end
        if not isNearPump then return notify('Move closer to pump') end
    
        if isVehicleCloseEnough(playerCoords, vehicle) then
            if not Config.inventory then return StartFueling(vehicle, 'pump') end
            if moneyAmount >= Config.priceTick then StartFueling(vehicle, 'pump') end
        elseif not isVehicleCloseEnough(playerCoords, vehicle) then
            return notify('Vehicle far from you')
        elseif vehicle ~= Config.electricModels then
            return notify('You cant fuel this vehicle')
        else
            return notify('Vehicle far from pump')
        end
    else
        if not Config.petrolCan.enabled or isFueling or IsPedInAnyVehicle(ped) then return print('skipping fuel with can -- debug') end
        if isNearPump then return notify('Put your can away before fueling with the pump') end

        if isVehicleCloseEnough(playerCoords, vehicle) and not vehicle == Config.electricModels then
            StartFueling(vehicle, 'can')
       
        else
            return notify('Vehicle far from you')
        end
    end
end
Citizen.CreateThread(function()
    if not Config.qtargetpump and not Config.qtargetcar then
        RegisterCommand('startfueling', function()
            local ped = PlayerPedId()
            local vehicle = GetPlayersLastVehicle()
            local petrolCan = GetSelectedPedWeapon(ped) == `WEAPON_PETROLCAN` and true or false
            local playerCoords = GetEntityCoords(ped)
            local isNearPump = findClosestPump(playerCoords)
            local moneyAmount = Config.inventory and exports.ox_inventory:Search(2, 'money') or 0

            if not petrolCan then
                if not inStation or isFueling or IsPedInAnyVehicle(ped) then return print('skipping fuel -- debug')  end
                if not isNearPump then return notify('Move closer to pump') end
            
                if not isVehicleCloseEnough(playerCoords, vehicle) and Config.petrolCan.enabled then
                    if not Config.inventory then return GetPetrolCan(isNearPump) end
                    if moneyAmount >= Config.petrolCan.price then GetPetrolCan(isNearPump) end
                elseif isVehicleCloseEnough(playerCoords, vehicle) then
                    if not Config.inventory then return StartFueling(vehicle, 'pump') end
                    if moneyAmount >= Config.priceTick then StartFueling(vehicle, 'pump') end
                elseif not isVehicleCloseEnough(playerCoords, vehicle) then
                    return notify('Vehicle far from you')
                elseif vehicle ~= Config.electricModels then
                    return notify('You cant fuel this vehicle')
                else
                    return notify('Vehicle far from pump')
                end
                
            else
                if not Config.petrolCan.enabled or isFueling or IsPedInAnyVehicle(ped) then return print('skipping fuel with can -- debug') end
                if isNearPump then return notify('Put your can away before fueling with the pump') end

                if isVehicleCloseEnough(playerCoords, vehicle) then
                    StartFueling(vehicle, 'can')
                else
                    return notify('Vehicle far from you')
                end
            end
        end)

        RegisterKeyMapping('startfueling', 'Fuel vehicle', 'keyboard', 'e')
        TriggerEvent('chat:removeSuggestion', '/startfueling')
        AddTextEntry('fuelHelpText', 'Press ~INPUT_C2939D45~ to fuel')
        AddTextEntry('petrolcanHelpText', 'Press ~INPUT_C2939D45~ to buy or refill a fuel can')
    end
end)
AddTextEntry('fuelLeaveVehicleText', 'Leave the vehicle to be able to start fueling')
