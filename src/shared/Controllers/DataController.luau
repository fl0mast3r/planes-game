--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Net = require(ReplicatedStorage.Shared.ClientNet)
local DataConfig = require(ReplicatedStorage.Shared.DataConfig)
local Signal = require(ReplicatedStorage.Packages.LemonSignal)

local DataController = {
    Data = {},
    DataUpdated = Signal.new() :: Signal.Signal<DataConfig.Type>
}

function DataController.Start(self: Controller)
    Net.CatchSwitchingSlot.On(function(Value)  
        self.Data = Value

        self.DataUpdated:Fire(Value)
    end)

    Net.GrabData.Invoke():andThen(function(result)
        self.Data = result

        self.DataUpdated:Fire(result)
    end)

    local moneyGained: number = TeleportService:GetLocalPlayerTeleportData()
    if moneyGained and typeof(moneyGained) == "number" then
        Net.Award.Fire(moneyGained)
    end
end

function DataController.Get(self: Controller)
    return self.Data
end

export type Controller = typeof(DataController)
return DataController