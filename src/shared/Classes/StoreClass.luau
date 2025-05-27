--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Controllers = require(ReplicatedStorage.Shared.Controllers)
local ClientNet = require(ReplicatedStorage.Shared.ClientNet)

local CancelSFX: Sound = SoundService:WaitForChild("SFX"):WaitForChild("Cancel") :: Sound
local PurchaseSFX: Sound = SoundService:WaitForChild("SFX"):WaitForChild("Purchase") :: Sound

local StoreClass = {}
StoreClass.__index = StoreClass

type Properties = {
    UIController: any,

    _buttonFrame: Frame,
    _button: TextButton,
    _selected: Frame,
    _lock: Frame,

    _isEquipped: Fusion.Value<boolean>,
    _isUnlocked: Fusion.Value<boolean>,
}
export type ClassType = typeof(setmetatable({} :: Properties, StoreClass))

function StoreClass.new(button: Frame)
    local self: Properties = {
        UIController = Controllers:Get("UIController"),

        _buttonFrame = button,
        _button = button:WaitForChild("Null"):WaitForChild("MainButton") :: TextButton,
        _selected = button:WaitForChild("Null"):WaitForChild("MainButton"):WaitForChild("Selected") :: Frame,
        _lock = button:WaitForChild("Null"):WaitForChild("MainButton"):WaitForChild("Lock") :: Frame,

        _isEquipped = Fusion.Value(false),
        _isUnlocked = Fusion.Value(false),
    }
    setmetatable(self, StoreClass)

    self:_connectThings()

    return self
end

function StoreClass.ForceDeactivate(self: ClassType)
    self._isEquipped:set(false)
end

function StoreClass.Lock(self: ClassType)
    self._isUnlocked:set(false)
end

function StoreClass.Unlock(self: ClassType)
    self._isUnlocked:set(true)
end

function StoreClass.Equip(self: ClassType)
    if not self._isUnlocked:get() then
        return
    end

    self.UIController:DeactivateShopButtons()

    self._isEquipped:set(true)
end

function StoreClass._connectThings(self: ClassType)
    Fusion.Hydrate(self._selected){
        Visible = self._isEquipped
    }

    Fusion.Hydrate(self._lock){
        Visible = Fusion.Computed(function()  
            return not self._isUnlocked:get()
        end, Fusion.cleanup)
    }

    self._button.MouseButton1Click:Connect(function(...: any)
        if not self._isUnlocked:get() then
            return ClientNet.Buy.Invoke(self._buttonFrame.Name):andThen(function(result: boolean)
                if not result then
                    local cancelClone = CancelSFX:Clone()
                    cancelClone.Parent = CancelSFX.Parent
                    cancelClone:Destroy()

                    return
                end

                local purchaseClone = PurchaseSFX:Clone()
                purchaseClone.Parent = PurchaseSFX.Parent
                purchaseClone:Destroy()

                self:Unlock()
            end)
        end

        self:Equip()
    end)
end 

function StoreClass.Destroy(self: ClassType)
    
end

return StoreClass
