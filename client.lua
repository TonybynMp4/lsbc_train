local teleporting = false
local teleportMarker = {
    {
        coords = vec4(-211.68, -1032.81, 30.14, 77.22),
        label = "prendre le train vers Paleto Bay.",
        target = vec4(-283.69, 6026.39, 31.5, 3.3),
        blip = {
            title = "Gare de Los Santos", colour = 29, id = 795
        }
    },
    {
        coords = vec4(-283.69, 6026.39, 31.5, 3.3),
        label = "prendre le train vers Los Santos.",
        target = vec4(-214.16, -1031.82, 30.14, 128.13),
        blip = {
            title = "Gare de Paleto Bay", colour = 29, id = 795
        }
    }
}
-- LES COORDS DE L'ANIMATION SONT HARDCODES, A CHANGER MANUELLEMENT SI VOUS CHANGEZ LES COORDS DU MARKER
-- THE ANIMATION COORDS ARE HARDCODED, CHANGE THEM MANUALLY IF YOU CHANGE THE MARKER COORDS

local cam

local function DisplayHelpText(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

local function loadTrainModels()
    local train = 'metrotrain'

    local modelHashKey = GetHashKey(train)
    RequestModel(modelHashKey)
    while not HasModelLoaded(modelHashKey) do
        Wait(500)
    end
end

local function playCutScene(fromPaleto)
    local ped = PlayerPedId()
    local camcoords = fromPaleto and vec4(-216.24, -1033.28, 32.27, 355.43) or vec4(-208.49, -1027.99, 32.27, 167)
    local traincoords = fromPaleto and vec3(-200.89, -985.79, 28.69) or vec3(-225, -1076, 29)
    local originalpos = fromPaleto and vec4(-200.89, -987.2, 28.69, -110) or vec4(-209.89, -1030.8, 29.14, 255.6)
    local finalpos = fromPaleto and vec4(-213.13, -1029.07, 30.14, 247.44) or vec4(-207, -1031.5, 30.14, 250)
    FreezeEntityPosition(ped, true)
    DoScreenFadeOut(800)
    Wait(800)
    loadTrainModels()

    local metro = CreateMissionTrain(26, traincoords.x, traincoords.y, traincoords.z, true, true, true)
    while not DoesEntityExist(metro) do
        Wait(800)
    end
    FreezeEntityPosition(ped, not fromPaleto)
    SetEntityCoords(ped, originalpos.x, originalpos.y, originalpos.z, false, false, false, false)
    SetEntityHeading(ped, originalpos.w)
    DoScreenFadeIn(800)

    cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", camcoords.x, camcoords.y, camcoords.z, -15.0, 0.0, camcoords.w, 60.00, false, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 1, true, true)

    Wait(3400)
    for i = 10, 0, -1 do
        SetTrainCruiseSpeed(metro, i)
        Wait(300)
    end
    FreezeEntityPosition(ped, false)
    SetVehicleDoorOpen(metro, 2, true, false)
    TaskGoStraightToCoord(ped, finalpos.x, finalpos.y, finalpos.z, 1, 2500, finalpos.w, 0.0)
    Wait(4500)
    SetVehicleDoorShut(metro, 2, true)
    SetTrainCruiseSpeed(metro, 10)
    Wait(3000)
    DeleteMissionTrain(metro)
    DoScreenFadeOut(800)
    Wait(800)
    SetCamActive(cam, false)
    DestroyCam(cam, true)
    RenderScriptCams(false, false, 1, true, true)
end

local function TeleportPlayer(playerPed, coords, coordId)

    playCutScene(coordId == 2)
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(playerPed, coords.h or coords.w)

    Wait(800)
    DoScreenFadeIn(800)
    teleporting = false
end

CreateThread(function()
    while true do
        local sleep = 0
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for k, marker in ipairs(teleportMarker) do
            local distance = #(playerCoords - marker.coords.xyz)

            if math.floor(distance) <= 10.0 then
                sleep = 0
                DrawMarker(25, marker.coords.x, marker.coords.y, marker.coords.z - 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 70, 186, 253, 202, false, false, 2, nil, nil, false, false)

                if distance <= 1.0 then
                    DisplayHelpText("Appuyez sur ~INPUT_PICKUP~ pour ~b~" .. marker.label)
                    if IsControlJustReleased(0, 38) and not teleporting then
                        teleporting = true
                        TeleportPlayer(playerPed, marker.target, k)
                    end
                end
                break
            else
                sleep = 1000
            end
        end
        Wait(sleep)
    end
end)

---------- BLIPS -------------

CreateThread(function()
    local Blips = {}
    for _, info in pairs(teleportMarker) do
        local blip = AddBlipForCoord(info.coords.x, info.coords.y, info.coords.z)
        SetBlipSprite(blip, info.blip.id)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 1.0)
        SetBlipColour(blip, info.blip.colour)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(info.blip.title)
        EndTextCommandSetBlipName(blip)
        Blips[#Blips + 1] = blip
    end
end)
