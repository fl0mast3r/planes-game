--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local ProfileService = require(ReplicatedStorage.Packages.ProfileService)
local Observer = require(ReplicatedStorage.Packages.Observers)
local Net = require(ServerScriptService.Server.ServerNet)
local ProfileConfig = require(ReplicatedStorage.Shared.DataConfig)

local ProfileStore = ProfileService.GetProfileStore("PlayerData3", ProfileConfig)

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
end

function DataService.Get(self: Service, player: Player, index: string)
    return self.Profiles[player].Data[index]
end

function DataService.Set(self: Service, player: Player, index: string, value: any)
    self.Profiles[player].Data[index] = value

    Net.CatchSwitchingSlot.Fire(player, self.Profiles[player].Data)
end

export type Service = typeof(DataService)
return DataService