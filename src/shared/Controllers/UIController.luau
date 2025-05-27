--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local ButtonClass = require(ReplicatedStorage.Shared.Classes.ButtonClass)
local ParameterClass = require(ReplicatedStorage.Shared.Classes.ParameterClass)

local UIController = {
    _player = Players.LocalPlayer :: Player,
    _playerUI = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("UI") :: PlayerGui?,

    _mainFrame = nil :: Frame?,
    _moneyFrame = nil :: Frame?,
    _winsFrame = nil :: Frame?,
    _launchFrame = nil :: Frame?,

    _buttons = {} :: {[TextButton | ImageButton]: ButtonClass.ClassType},
    _parameters = {} :: {[Frame]: ParameterClass.ClassType}
}

function UIController.Start(self: Controller)
    if not self._playerUI then
        return
    end

    self._mainFrame = self._playerUI:WaitForChild("Main") :: Frame
    if not self._mainFrame then
        return
    end

    self._moneyFrame = self._mainFrame:WaitForChild("Money") :: Frame
    self._winsFrame = self._mainFrame:WaitForChild("Wins") :: Frame
    self._launchFrame = self._mainFrame:WaitForChild("Launch") :: Frame

    self:_buildUI()
end

function UIController._buildUI(self: Controller)
    self:_animateButtons()
    self:_animateSwitchButtons()
    self:_connectParameters()
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
    local shopButton = self._launchFrame:WaitForChild("Shop") :: TextButton

    Fusion.Hydrate(lobbyButton:WaitForChild("Main")){
        BackgroundColor3 = Fusion.Computed(function()  
            return if self._buttons[lobbyButton].Activated:get() then Color3.fromRGB(143, 143, 143) else Color3.fromRGB(172, 172, 172)
        end, Fusion.cleanup),
    }

    Fusion.Hydrate(shopButton:WaitForChild("Main")){
        BackgroundColor3 = Fusion.Computed(function()  
            return if self._buttons[shopButton].Activated:get() then Color3.fromRGB(143, 143, 143) else Color3.fromRGB(172, 172, 172)
        end, Fusion.cleanup),
    }


    lobbyButton.MouseButton1Click:Connect(function(...: any)  
        if self._buttons[lobbyButton].Activated:get() then
            return
        end

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