---@diagnostic disable: cast-local-type
local mapData = require('data.mapData')
local debug = require("modules.utils.shared").debug
local interface = require("modules.interface.client")

local PlayerStatusThread = {}
PlayerStatusThread.__index = PlayerStatusThread

PlayerStatusThread.registry = {}

function PlayerStatusThread.new(identifier)
  local self = setmetatable({}, PlayerStatusThread)
  self.identifier = identifier
  self.isVehicleThreadRunning = false

  PlayerStatusThread.registry[identifier] = self

  debug("(PlayerStatusThread:new) Created new instance with identifier: ", identifier)
  return self
end

function PlayerStatusThread:getIsVehicleThreadRunning()
  return self.isVehicleThreadRunning
end

function PlayerStatusThread:setIsVehicleThreadRunning(value)
  debug("(PlayerStatusThread:setIsVehicleThreadRunning) Setting: ", value)
  self.isVehicleThreadRunning = value
end

function PlayerStatusThread:start(vehicleStatusThread)
  CreateThread(function()
    while true do
      local ped = PlayerPedId()
      local coords = GetEntityCoords(ped)
      local currentStreet, currentArea = GetStreetNameAtCoord(coords.x, coords.y, coords.z)

      currentStreet = GetStreetNameFromHashKey(currentStreet)
      currentArea = GetStreetNameFromHashKey(currentArea)

      local zone = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))

      if mapData.streets[currentStreet] then
        currentStreet = mapData.streets[currentStreet]
      end

      if mapData.streets[currentArea] then
        currentArea = mapData.streets[currentArea]
      end

      local heading = GetEntityHeading(ped)
      local compass = " "
      if (heading >= 0 and heading < 45) or (heading >= 315 and heading < 360) then
        compass = "N"
      elseif heading >= 45 and heading < 135 then
        compass = "W"
      elseif heading >= 135 and heading < 225 then
        compass = "S"
      elseif heading >= 225 and heading < 315 then
        compass = "E"
      end

      local pedArmor = GetPedArmour(ped)
      local pedHealth = math.floor(GetEntityHealth(ped) / GetEntityMaxHealth(ped) * 100)
      local isInVehicle = IsPedInAnyVehicle(ped, false)

      if isInVehicle and not self:getIsVehicleThreadRunning() and vehicleStatusThread then
        vehicleStatusThread:start()
        debug("(playerStatus) (vehicleStatusThread) Vehicle status thread started.")
      end

      local data = {
        health = pedHealth,
        armor = pedArmor,
        streetLabel = currentStreet,
        areaLabel = zone,
        heading = compass,
        isInVehicle = isInVehicle,
      }

      interface.message("setPlayerState", data)

      Wait(1000)
    end
  end)
end

function PlayerStatusThread.getInstanceById(identifier)
  return PlayerStatusThread.registry[identifier]
end

return PlayerStatusThread