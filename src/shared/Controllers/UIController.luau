--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Promise = require(ReplicatedStorage.Packages.TypedPromise)
local ButtonClass = require(ReplicatedStorage.Shared.Classes.ButtonClass)
local ParameterClass = require(ReplicatedStorage.Shared.Classes.ParameterClass)
local StoreClass = require(ReplicatedStorage.Shared.Classes.StoreClass)
local DataConfig = require(ReplicatedStorage.Shared.DataConfig)
local Controllers = require(ReplicatedStorage.Shared.Controllers)

local UIController = {
    DataController = nil :: any,

    _player = Players.LocalPlayer :: Player,
    _playerUI = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI") :: PlayerGui?,

    _mainFrame = nil :: Frame?,
    _moneyFrame = nil :: Frame?,
    _winsFrame = nil :: Frame?,
    _launchFrame = nil :: Frame?,
    _shopFrame = nil :: Frame?,

    _buttons = {} :: {[TextButton | ImageButton]: ButtonClass.ClassType},
    _parameters = {} :: {[Frame]: ParameterClass.ClassType},
    _shopButtons = {} :: {[Frame]: StoreClass.ClassType},
}

function UIController.Start(self: Controller)
    self.DataController = Controllers:Get("DataController")

    if not self._playerUI then
        return
    end

    self._mainFrame = self._playerUI:WaitForChild("Main") :: Frame
    if not self._mainFrame then
        return
    end

    self._shopFrame = self._mainFrame:WaitForChild("Launch"):WaitForChild("Shop") :: Frame

    self._moneyFrame = self._mainFrame:WaitForChild("Money") :: Frame
    self._winsFrame = self._mainFrame:WaitForChild("Wins") :: Frame
    self._launchFrame = self._mainFrame:WaitForChild("Launch") :: Frame

    self:_buildUI()

    self.DataController.DataUpdated:Connect(function(newData: DataConfig.Type)
        self:_updateCurrency(newData)
    end)
end

function UIController.DeactivateShopButtons(self: Controller)
    for frame: Frame, object: StoreClass.ClassType in next, self._shopButtons do
        object:ForceDeactivate()
    end
end

function UIController._buildUI(self: Controller)
    self:_animateButtons()
    self:_animateSwitchButtons()
    self:_connectParameters()
    self:_connectPlayButton()
    self:_bindShopButtons()
end

function UIController._bindShopButtons(self: Controller)
    if not self._shopFrame then
        return
    end

    for _, buttonFrame: Instance in next, self._shopFrame:WaitForChild("List"):GetChildren() do
        if not buttonFrame:IsA("Frame") then
            continue    
        end

        self._shopButtons[buttonFrame] = StoreClass.new(buttonFrame)
    end

    local basicFrame: Frame = self._shopFrame:WaitForChild("List"):WaitForChild("Basic") :: Frame
    self._shopButtons[basicFrame]:Unlock()
    self._shopButtons[basicFrame]:Equip()

    Promise.try(function(...)
        local data: DataConfig.Type = {}

        repeat
            task.wait()
            data = self.DataController:Get()
        until data.Unlocked

        for frame: Frame, object: StoreClass.ClassType in next, self._shopButtons do
            if not table.find(data.Unlocked, frame.Name) then
                object:Lock()

                continue
            end

            object:Unlock()
        end
    end)
end

function UIController._connectPlayButton(self: Controller)
    if not self._launchFrame then
        return
    end

    local playButton = self._launchFrame:WaitForChild("Launch"):WaitForChild("Play") :: TextButton
    playButton.MouseButton1Click:Connect(function()  
        local teleportData: {[string]: number} = {}

        for frame: Frame, object: ParameterClass.ClassType in next, self._parameters do
            teleportData[frame.Name] = object:GetState()
        end

        TeleportService:Teleport(0, self._player, teleportData)
    end)
end

function UIController._updateCurrency(self: Controller, newData)
    if not self._moneyFrame then
        return
    end

    local amountMoney = self._moneyFrame:WaitForChild("Main"):WaitForChild("Amount") :: TextLabel
    amountMoney.Text = newData.Money

    if not self._winsFrame then
        return
    end

    local amountWins = self._winsFrame:WaitForChild("Main"):WaitForChild("Amount") :: TextLabel
    amountWins.Text = newData.Wins
end

function UIController._connectParameters(self: Controller)
    if not self._launchFrame then
        return
    end

    for _, frame: Instance in next, self._launchFrame:WaitForChild("Launch"):WaitForChild("List"):GetChildren() do
        if not frame:IsA("Frame") then
            continue
        end

        self._parameters[frame] = ParameterClass.new(frame)
    end
end

function UIController._animateButtons(self: Controller)
    if not self._mainFrame then
        return
    end

    for _, button: Instance in next, self._mainFrame:GetDescendants() do
        if (not button:IsA("TextButton")) and (not button:IsA("ImageButton")) then
            continue
        end

        self._buttons[button] = ButtonClass.new(button)
    end
end

function UIController._animateSwitchButtons(self: Controller)
    if not self._launchFrame then
        return
    end

    local lobbyButton = self._launchFrame:WaitForChild("Lobby") :: TextButton
    local shopButton = self._launchFrame:WaitForChild("ShopButton") :: TextButton
    local launchFrame = self._launchFrame:WaitForChild("Launch") :: Frame
    local shopFrame = self._launchFrame:WaitForChild("Shop") :: Frame

    Fusion.Hydrate(lobbyButton:WaitForChild("Main")){
        BackgroundColor3 = Fusion.Computed(function()  
            return if self._buttons[lobbyButton].Activated:get() then Color3.fromRGB(208, 208, 208) else Color3.fromRGB(255, 255, 255)
        end, Fusion.cleanup),
    }

    Fusion.Hydrate(shopButton:WaitForChild("Main")){
        BackgroundColor3 = Fusion.Computed(function()  
            return if self._buttons[shopButton].Activated:get() then Color3.fromRGB(208, 208, 208) else Color3.fromRGB(255, 255, 255)
        end, Fusion.cleanup),
    }

    lobbyButton.MouseButton1Click:Connect(function(...: any)
        if self._buttons[lobbyButton].Activated:get() then
            return
        end

        shopFrame.Visible = false
        launchFrame.Visible = true

        self._buttons[lobbyButton].Activated:set(true)
        self._buttons[lobbyButton].OriginalSize = UDim2.fromScale(self._buttons[lobbyButton].OriginalSize.X.Scale / 1.1, self._buttons[lobbyButton].OriginalSize.Y.Scale / 1.1)
        
        if self._buttons[shopButton].Activated:get() then
            self._buttons[shopButton].Activated:set(false)

            self._buttons[shopButton].OriginalSize = UDim2.fromScale(self._buttons[shopButton].OriginalSize.X.Scale * 1.1, self._buttons[shopButton].OriginalSize.Y.Scale * 1.1)    
            self._buttons[shopButton]:RenderChanges()
        end
    end)

    shopButton.MouseButton1Click:Connect(function(...: any)  
        if self._buttons[shopButton].Activated:get() then
            return
        end

        shopFrame.Visible = true
        launchFrame.Visible = false

        self._buttons[shopButton].Activated:set(true)
        self._buttons[shopButton].OriginalSize = UDim2.fromScale(self._buttons[shopButton].OriginalSize.X.Scale / 1.1, self._buttons[shopButton].OriginalSize.Y.Scale / 1.1)
        
        if self._buttons[lobbyButton].Activated:get() then
            self._buttons[lobbyButton].Activated:set(false)

            self._buttons[lobbyButton].OriginalSize = UDim2.fromScale(self._buttons[lobbyButton].OriginalSize.X.Scale * 1.1, self._buttons[lobbyButton].OriginalSize.Y.Scale * 1.1)    
            self._buttons[lobbyButton]:RenderChanges()
        end
    end)

    self._buttons[lobbyButton].Activated:set(true)
    self._buttons[lobbyButton].OriginalSize = UDim2.fromScale(self._buttons[lobbyButton].OriginalSize.X.Scale / 1.1, self._buttons[lobbyButton].OriginalSize.Y.Scale / 1.1)
    self._buttons[lobbyButton]:RenderChanges()
end

export type Controller = typeof(UIController)
return UIController