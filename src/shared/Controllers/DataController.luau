--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.ClientNet)
local DataConfig = require(ReplicatedStorage.Shared.DataConfig)
local Signal = require(ReplicatedStorage.Packages.LemonSignal)

local DataController = {
    Data = {} :: DataConfig.Type,
    DataUpdated = Signal.new() :: Signal.Signal<DataConfig.Type>
}

function DataController.Start(self: Controller)
    Net.CatchSwitchingSlot.On(function(Value)  
        self.Data = Value

        self.DataUpdated:Fire(Value)
    end)

    Net.GrabData.Invoke():andThen(function(result: any)
        self.Data = result

        self.DataUpdated:Fire(result)
    end)
end

export type Controller = typeof(DataController)
return DataController