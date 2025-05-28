--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local ProfileService = require(ReplicatedStorage.Packages.ProfileService)
local Observer = require(ReplicatedStorage.Packages.Observers)
local Net = require(ServerScriptService.Server.ServerNet)
local ProfileConfig = require(ReplicatedStorage.Shared.DataConfig)
local StoreData = require(ReplicatedStorage.Shared.StoreData)

local ProfileStore = ProfileService.GetProfileStore("PlayerData4", ProfileConfig)

local DataService = {
    Profiles = {},
}

function DataService.Start(self: Service)
    Observer.observePlayer(function(player: Player): (() -> ())?
        local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
        if profile ~= nil then
            profile:AddUserId(player.UserId)
            profile:Reconcile()
            profile:ListenToRelease(function()
                self.Profiles[player] = nil
                player:Kick()
            end)
            if player:IsDescendantOf(Players) == true then
                self.Profiles[player] = profile

                Net.CatchSwitchingSlot.Fire(player, self.Profiles[player].Data)
            else
                profile:Release()
            end
        else
            player:Kick() 
        end

        return function()
            local profile = self.Profiles[player]
            if profile ~= nil then
                profile:Release()
            end
        end
    end)

    Net.GrabData.On(function(player: Player): any
        if not self.Profiles[player] then
            for i = 1, 1000 do
                task.wait(0.1)

                if self.Profiles[player] then
                    break
                end
            end
        end

        if not self.Profiles[player] then
            return
        end

        return self.Profiles[player].Data
    end)

    Net.Buy.On(function(player: Player, name: string): (boolean)  
        return self:Buy(player, name)
    end)

    Net.Award.On(function(player: Player, moneyGained: number)
        self:Set(player, "Money", self:Get(player, "Money") + moneyGained)
        self:Set(player, "Wins", self:Get(player, "Wins") + 1)
    end)
end

function DataService.Get(self: Service, player: Player, index: string): any
    return self.Profiles[player].Data[index]
end

function DataService.Set(self: Service, player: Player, index: string, value: any)
    self.Profiles[player].Data[index] = value

    Net.CatchSwitchingSlot.Fire(player, self.Profiles[player].Data)
end

function DataService.Buy(self: Service, player: Player, name: string): (boolean)
    if not StoreData[name] then
        return false
    end

    if StoreData[name][2] > self:Get(player, StoreData[name][1]) then
        return false
    end

    local newData: {string} = table.clone(self:Get(player, "Unlocked"))
    if table.find(newData, name) then
        return false
    end
    
    table.insert(newData, name)
    self:Set(player, "Unlocked", newData)
    self:Set(player, StoreData[name][1], self:Get(player, StoreData[name][1]) - StoreData[name][2])

    return true
end

export type Service = typeof(DataService)
return DataService