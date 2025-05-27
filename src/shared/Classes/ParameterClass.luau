--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Enums = require(ReplicatedStorage.Packages.Enums)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local ParameterClass = {}
ParameterClass.__index = ParameterClass

type Properties = {
    _frame: Frame,
    _main: Frame,
    _state: Fusion.Value<number>,
}
export type ClassType = typeof(setmetatable({} :: Properties, ParameterClass))

function ParameterClass.new(frame: Frame)
    local self: Properties = {
        _frame = frame,
        _main = frame:WaitForChild("Main") :: Frame,
        _state = Fusion.Value(Enums.States.States.Easy),
    }
    setmetatable(self, ParameterClass)

    self:_bindConnections()

    return self
end

function ParameterClass.GetState(self: ClassType): (number)
    return self._state:get()
end

function ParameterClass._bindConnections(self: ClassType): ()
    for name: string, stateIndex: number in next, Enums.States.States do
        local button: TextButton = self._main:WaitForChild(name) :: TextButton

        Fusion.Hydrate(button){
            BackgroundColor3 = Fusion.Computed(function()  
                return if self._state:get() == stateIndex then Color3.fromRGB(34, 207, 63) else Color3.fromRGB(91, 91, 91)
            end, Fusion.cleanup)
        }

        Fusion.Hydrate(button:WaitForChild("Main")){
            BackgroundColor3 = Fusion.Computed(function()  
                return if self._state:get() == stateIndex then Color3.fromRGB(57, 255, 17) else Color3.fromRGB(125, 125, 125)
            end, Fusion.cleanup)
        }

        Fusion.Hydrate(button:WaitForChild("Main"):WaitForChild("Title"):WaitForChild("UIStroke")){
            Color = Fusion.Computed(function()  
                return if self._state:get() == stateIndex then Color3.fromRGB(6, 83, 2) else Color3.fromRGB(51, 51, 51)
            end, Fusion.cleanup)
        }

        Fusion.Hydrate(button:WaitForChild("UIStroke")){
            Color = Fusion.Computed(function()  
                return if self._state:get() == stateIndex then Color3.fromRGB(6, 83, 2) else Color3.fromRGB(51, 51, 51)
            end, Fusion.cleanup)
        }
        
        button.MouseButton1Click:Connect(function(...: any)  
            self._state:set(stateIndex)
        end)
    end
end

function ParameterClass.Destroy(self: ClassType): ()
    
end

return ParameterClass
