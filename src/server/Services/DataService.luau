--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileService = require(ReplicatedStorage.Packages.ProfileService)
local Observer = require(ReplicatedStorage.Packages.Observers)

local DataService = {
    
}

function DataService.Start(self: Service)
    
end

export type Service = typeof(DataService)
return DataService