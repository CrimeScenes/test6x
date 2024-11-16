if shared.Forbidden.Memory.Settings.IsActive == true then
    local Memory

    game:GetService("RunService").RenderStepped:Connect(function()
        pcall(function()
            for i, v in pairs(game:GetService("CoreGui").RobloxGui.PerformanceStats:GetChildren()) do
                if v.Name == "PS_Button" then
                    if v.StatsMiniTextPanelClass.TitleLabel.Text == "Mem" then
                        v.StatsMiniTextPanelClass.ValueLabel.Text = tostring(Memory) .. " MB"
                    end
                end
            end
        end)

        pcall(function()
            if game:GetService("CoreGui").RobloxGui.PerformanceStats["PS_Viewer"].Frame.TextLabel.Text == "Memory" then
                for i, v in pairs(game:GetService("CoreGui").RobloxGui.PerformanceStats["PS_Viewer"].Frame:GetChildren()) do
                    if v.Name == "PS_DecoratedValueLabel" and string.find(v.Label.Text, 'Current') then
                        v.Label.Text = "Current: " .. Memory .. " MB"
                    end
                    if v.Name == "PS_DecoratedValueLabel" and string.find(v.Label.Text, 'Average') then
                        v.Label.Text = "Average: " .. Memory .. " MB"
                    end
                end
            end
        end)

        pcall(function()
            game:GetService("CoreGui").DevConsoleMaster.DevConsoleWindow.DevConsoleUI.TopBar.LiveStatsModule["MemoryUsage_MB"].Text = math.round(tonumber(Memory)) .. " MB"
        end)
    end)

    task.spawn(function()
        while task.wait(1) do
            local minMemory = shared.Forbidden.Memory.Configuration.Start
            local maxMemory = shared.Forbidden.Memory.Configuration.End
            Memory = tostring(math.random(minMemory, maxMemory)) .. "." .. tostring(math.random(10, 99))
        end
    end)
end









local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local RunService = game:GetService("RunService")
local Camera = game.Workspace.CurrentCamera

local Circle = Drawing.new("Circle")
Circle.Color = Color3.new(1, 1, 1)
Circle.Thickness = 1
Circle.Filled = false



local function UpdateFOV()
    if not Circle then return end

    local reach = shared.Forbidden.PointAssist.Reach
    local finalReach = 150  

   
    if reach.X == 5 and reach.Y == 5 and reach.Z == 5 then
        finalReach = 150
    else

        finalReach = (reach.X + reach.Y + reach.Z) / 3  
        
    end

    local success, errorMsg = pcall(function()
        if Circle then
            Circle.Visible = shared.Forbidden.PointAssist.Reach_Visibility
            Circle.Radius = finalReach  
            Circle.Position = Vector2.new(Mouse.X, Mouse.Y + game:GetService("GuiService"):GetGuiInset().Y)
        end
    end)

    if not success then
        warn("Error updating FOV: " .. errorMsg)
    end
end




RunService.RenderStepped:Connect(UpdateFOV)

local function ClosestPlrFromMouse()
    local Target, Closest = nil, math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local Position, OnScreen = Camera:WorldToScreenPoint(player.Character.HumanoidRootPart.Position)
            local Distance = (Vector2.new(Position.X, Position.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude

            if Circle.Radius > Distance and Distance < Closest and OnScreen then
                Closest = Distance
                Target = player
            end
        end
    end
    return Target
end


local function GetClosestBodyPart(character)
    local ClosestDistance = math.huge
    local BodyPart = nil

    if character and character:IsDescendantOf(game.Workspace) then
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                local Position, OnScreen = Camera:WorldToScreenPoint(part.Position)
                if OnScreen then
                    local Distance = (Vector2.new(Position.X, Position.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if Circle.Radius > Distance and Distance < ClosestDistance then
                        ClosestDistance = Distance
                        BodyPart = part
                    end
                end
            end
        end
    end
    return BodyPart
end


local function GetTarget()
    
    return TargetPlayer
end


local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera


RunService.Heartbeat:Connect(function()
    pcall(function()
        for i, v in pairs(game.Players:GetChildren()) do
            if v.Name ~= game.Players.LocalPlayer.Name then
                local hrp = v.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                   
                    hrp.Velocity = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z)
                    hrp.AssemblyLinearVelocity = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z)
                end
            end
        end
    end)
end)


Mouse.KeyDown:Connect(function(Key)
    local key = Key:lower()

    if key == shared.Forbidden.ActivationKey:lower() then
        if shared.Forbidden.PointAssist.IsActive then
            if IsTargeting then
                if TargetPlayer and TargetPlayer.Character and TargetPlayer.Character:FindFirstChildOfClass("Humanoid").Health >= 1 then
                    if ClosestPlrFromMouse() == TargetPlayer then
                        IsTargeting = false
                        TargetPlayer = nil
                    else
                        local newTarget = ClosestPlrFromMouse()
                        if newTarget and newTarget.Character and newTarget.Character:FindFirstChildOfClass("Humanoid").Health >= 1 then
                            TargetPlayer = newTarget
                        end
                    end
                end
            else
                local initialTarget = ClosestPlrFromMouse()
                if initialTarget and initialTarget.Character and initialTarget.Character:FindFirstChildOfClass("Humanoid").Health >= 1 then
                    IsTargeting = true
                    TargetPlayer = initialTarget
                end
            end
        end
    end
end)

local function IsAlignedWithCamera(targetPlayer)
    if targetPlayer and targetPlayer.Character then
        local targetPosition = targetPlayer.Character.HumanoidRootPart.Position
        local cameraPosition = Camera.CFrame.Position
        local direction = (targetPosition - cameraPosition).unit
        local targetDirection = (Camera.CFrame.LookVector).unit

        return direction:Dot(targetDirection) > 0.9 
    end
    return false
end

RunService.RenderStepped:Connect(function()
    if IsTargeting and TargetPlayer and TargetPlayer.Character then
        if TargetPlayer.Character:FindFirstChildOfClass("Humanoid").Health < 1 then
            TargetPlayer = nil
            IsTargeting = false
            return
        end

        local BodyPart = GetClosestBodyPart(TargetPlayer.Character)

        if BodyPart then
            local predictedPosition
            if shared.Forbidden.PointAssist.Resolver then
                local humanoid = TargetPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local moveDirection = humanoid.MoveDirection
                    predictedPosition = BodyPart.Position + (moveDirection * Vector3.new(
                        shared.Forbidden.PointAssist.VelocityCompensation.X,
                        shared.Forbidden.PointAssist.VelocityCompensation.Y,
                        shared.Forbidden.PointAssist.VelocityCompensation.Z
                    ))
                end
            else
                local targetVelocity = TargetPlayer.Character.HumanoidRootPart.Velocity
                predictedPosition = BodyPart.Position + (targetVelocity * Vector3.new(
                    shared.Forbidden.PointAssist.VelocityCompensation.X,
                    shared.Forbidden.PointAssist.VelocityCompensation.Y,
                    shared.Forbidden.PointAssist.VelocityCompensation.Z
                ))
            end

            if predictedPosition then
                local DesiredCFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
                Camera.CFrame = Camera.CFrame:Lerp(DesiredCFrame, shared.Forbidden.PointAssist.Stabilization)
            end

            if shared.Forbidden['Silent Precision'].IsActive and IsTargeting and TargetPlayer.Character:FindFirstChild("Humanoid") then
                local closestPoint = BodyPart.Position  
                local velocity = GetVelocity(TargetPlayer, BodyPart.Name)
                Replicated_Storage[RemoteEvent]:FireServer(Argument, closestPoint + velocity * Vector3.new(
                    shared.Forbidden['Silent Precision'].TimeDistortion.X, 
                    shared.Forbidden['Silent Precision'].TimeDistortion.Y, 
                    shared.Forbidden['Silent Precision'].TimeDistortion.Z
                ))
            end
        end
    end
end)








local G                   = game
local Run_Service         = G:GetService("RunService")
local Players             = G:GetService("Players")
local UserInputService    = G:GetService("UserInputService")
local Local_Player        = Players.LocalPlayer
local Mouse               = Local_Player:GetMouse()
local Current_Camera      = G:GetService("Workspace").CurrentCamera
local Replicated_Storage  = G:GetService("ReplicatedStorage")
local StarterGui          = G:GetService("StarterGui")
local Workspace           = G:GetService("Workspace")


local Target = nil
local V2 = Vector2.new
local Fov = Drawing.new("Circle")
local holdingMouseButton = false
local lastToolUse = 0
local FovParts = {}


if not game:IsLoaded() then
    game.Loaded:Wait()
end


local Games = {
    DaHood = {
        ID = 2,
        Details = {
            Name = "Da Hood",
            Argument = "UpdateMousePosI2",
            Remote = "MainEvent",
            BodyEffects = "K.O"
        }
    },
    DaHoodMacro = {
        ID = 16033173781,
        Details = {
            Name = "Da Hood Macro",
            Argument = "UpdateMousePosI2",
            Remote = "MainEvent",
            BodyEffects = "K.O"
        }
    },
    DaHoodVC = {
        ID = 7213786345,
        Details = {
            Name = "Da Hood VC",
            Argument = "UpdateMousePosI",
            Remote = "MainEvent",
            BodyEffects = "K.O"
        }
    },
    HoodCustoms = {
        ID = 9825515356,
        Details = {
            Name = "Hood Customs",
            Argument = "MousePosUpdate",
            Remote = "MainEvent"
        }
    },
    HoodModded = {
        ID = 5602055394,
        Details = {
            Name = "Hood Modded",
            Argument = "MousePos",
            Remote = "Bullets"
        }
    },
    DaDownhillPSXbox = {
        ID = 77369032494150,
        Details = {
            Name = "Da Downhill [PS/Xbox]",
            Argument = "MOUSE",
            Remote = "MAINEVENT"
        }
    },
    DaBank = {
        ID = 132023669786646,
        Details = {
            Name = "Da Bank",
            Argument = "MOUSE",
            Remote = "MAINEVENT"
        }
    },
    DaUphill = {
        ID = 84366677940861,
        Details = {
            Name = "Da Uphill",
            Argument = "MOUSE",
            Remote = "MAINEVENT"
        }
    },
    DaHoodBotAimTrainer = {
        ID = 14487637618,
        Details = {
            Name = "Da Hood Bot Aim Trainer",
            Argument = "MOUSE",
            Remote = "MAINEVENT"
        }
    },
    HoodAimTrainer1v1 = {
        ID = 11143225577,
        Details = {
            Name = "1v1 Hood Aim Trainer",
            Argument = "UpdateMousePos",
            Remote = "MainEvent"
        }
    },
    HoodAim = {
        ID = 14413712255,
        Details = {
            Name = "Hood Aim",
            Argument = "MOUSE",
            Remote = "MAINEVENT"
        }
    },
    MoonHood = {
        ID = 14472848239,
        Details = {
            Name = "Moon Hood",
            Argument = "MoonUpdateMousePos",
            Remote = "MainEvent"
        }
    },
    DaStrike = {
        ID = 15186202290,
        Details = {
            Name = "Da Strike",
            Argument = "MOUSE",
            Remote = "MAINEVENT"
        }
    },
    OGDaHood = {
        ID = 17319408836,
        Details = {
            Name = "OG Da Hood",
            Argument = "UpdateMousePos",
            Remote = "MainEvent",
            BodyEffects = "K.O"
        }
    },
    DahAimTrainner = {
        ID = 16747005904,
        Details = {
            Name = "DahAimTrainner",
            Argument = "UpdateMousePos",
            Remote = "MainEvent",
            BodyEffects = "K.O"
        }
    },
    MekoHood = {
        ID = 17780567699,
        Details = {
            Name = "Meko Hood",
            Argument = "UpdateMousePos",
            Remote = "MainEvent",
            BodyEffects = "K.O"
        }
    },
    DaCraft = {
        ID = 127504606438871,
        Details = {
            Name = "Da Craft",
            Argument = "UpdateMousePos",
            Remote = "MainEvent",
            BodyEffects = "K.O"
        }
    },
    NewHood = {
        ID = 17809101348,
        Details = {
            Name = "New Hood",
            Argument = "UpdateMousePos",
            Remote = "MainEvent",
            BodyEffects = "K.O"
        }
    },
    NewHood2 = {
        ID = 138593053726293,
        Details = {
            Name = "New Hood",
            Argument = "UpdateMousePos",
            Remote = "MainEvent",
            BodyEffects = "K.O"
        }    
    },
    DeeHood = {
        ID = 139379854239480,
        Details = {
            Name = "Dee Hood",
            Argument = "UpdateMousePos",
            Remote = "MainEvent",
            BodyEffects = "K.O"
        }
    },
    DaKitty = {
        ID = 113357850268933,
        Details = {
            Name = "Da kitty",
            Argument = "UpdateMousePos",
            Remote = "MainEvent",
            BodyEffects = "K.O"
        }
    }
}


local gameId = game.PlaceId
local gameSettings


for _, gameData in pairs(Games) do
    if gameData.ID == gameId then
        gameSettings = gameData.Details
        break
    end
end

if not gameSettings then
    Players.LocalPlayer:Kick("Unsupported game")
    return
end

local RemoteEvent = gameSettings.Remote
local Argument = gameSettings.Argument
local BodyEffects = gameSettings.BodyEffects or "K.O"


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MainEvent = ReplicatedStorage:FindFirstChild(RemoteEvent)

if not MainEvent then
    Players.LocalPlayer:Kick("Are you sure this is the correct game?")
    return
end

local function isArgumentValid(argumentName)
    return argumentName == Argument
end

local argumentToCheck = Argument

if isArgumentValid(argumentToCheck) then
    MainEvent:FireServer(argumentToCheck)
else
    Players.LocalPlayer:Kick("Invalid argument")
end


local function clearFovParts()
    for _, part in pairs(FovParts) do
        part:Remove()
    end
    FovParts = {}
end


local function calculateFov(X, Y, Z)
    local baseSize = 3.5  
    local baseFov = 12   


    local sizeProduct = X * Y * Z


    local calculatedFov = baseFov * (sizeProduct / (baseSize * baseSize * baseSize))

    return calculatedFov
end


local function updateFov()
    local settings = shared.Forbidden['Silent Precision'].VoidLimits
    clearFovParts()
 
    local dynamicFovSize = calculateFov(settings.X, settings.Y, settings.Z)

    if IsTargeting then
        if settings.FovShape == "Square" then
            local halfSize = dynamicFovSize / 2
            local corners = {
                V2(Mouse.X - halfSize, Mouse.Y - halfSize),
                V2(Mouse.X + halfSize, Mouse.Y - halfSize),
                V2(Mouse.X + halfSize, Mouse.Y + halfSize),
                V2(Mouse.X - halfSize, Mouse.Y + halfSize)
            }
            for i = 1, 4 do
                local line = Drawing.new("Line")
                line.Visible = settings.FovVisible
                line.From = corners[i]
                line.To = corners[i % 4 + 1]
                line.Color = settings.FovColor
                line.Thickness = settings.FovThickness
                line.Transparency = settings.FovTransparency
                table.insert(FovParts, line)
            end
        elseif settings.FovShape == "Triangle" then
            local points = {
                V2(Mouse.X, Mouse.Y - dynamicFovSize),
                V2(Mouse.X + dynamicFovSize * math.sin(math.rad(60)), Mouse.Y + dynamicFovSize * math.cos(math.rad(60))),
                V2(Mouse.X - dynamicFovSize * math.sin(math.rad(60)), Mouse.Y + dynamicFovSize * math.cos(math.rad(60)))
            }
            for i = 1, 3 do
                local line = Drawing.new("Line")
                line.Visible = settings.FovVisible
                line.From = points[i]
                line.To = points[i % 3 + 1]
                line.Color = settings.FovColor
                line.Thickness = settings.FovThickness
                line.Transparency = settings.FovTransparency
                table.insert(FovParts, line)
            end
        else  -- Default to Circle
            Fov.Visible = settings.FovVisible
            Fov.Radius = dynamicFovSize
            Fov.Position = V2(Mouse.X, Mouse.Y + (G:GetService("GuiService"):GetGuiInset().Y))
            Fov.Color = settings.FovColor
            Fov.Thickness = settings.FovThickness
            Fov.Transparency = settings.FovTransparency
            Fov.Filled = settings.Filled
            if settings.Filled then
                Fov.Transparency = settings.FillTransparency
            end
        end
    else
        Fov.Visible = false  
    end
end


local function sendNotification(title, text, icon)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Icon = icon,
        Duration = 5
    })
end


local function Death(Plr)
    if Plr.Character and Plr.Character:FindFirstChild("BodyEffects") then
        local bodyEffects = Plr.Character.BodyEffects
        local ko = bodyEffects:FindFirstChild(shared.Forbidden.BodyEffects)
        return ko and ko.Value
    end
    return false
end


local function Grabbed(Plr)
    return Plr.Character and Plr.Character:FindFirstChild("GRABBING_CONSTRAINT") ~= nil
end


local function isPartInFovAndVisible(part)
    if not shared.Forbidden.PointAssist.IsActive or not IsTargeting or not TargetPlayer then
        return false
    end

    -- Dynamically calculate the FOV based on X, Y, Z values
    local dynamicFovSize = calculateFov(shared.Forbidden['Silent Precision'].VoidLimits.X, 
                                         shared.Forbidden['Silent Precision'].VoidLimits.Y, 
                                         shared.Forbidden['Silent Precision'].VoidLimits.Z)

    local screenPoint, onScreen = Current_Camera:WorldToScreenPoint(part.Position)
    local distance = (V2(screenPoint.X, screenPoint.Y) - V2(Mouse.X, Mouse.Y)).Magnitude
    return onScreen and distance <= dynamicFovSize
end

-- Modify the isPartVisible function (if necessary)
local function isPartVisible(part)
    if not shared.Forbidden['Silent Precision'].WallCheck then 
        return true
    end
    local origin = Current_Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * (part.Position - origin).Magnitude
    local ray = Ray.new(origin, direction)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {Local_Player.Character, part.Parent})
    return hit == part or not hit
end




local function GetClosestHitPoint(character)
    local closestPart = nil
    local closestPoint = nil
    local shortestDistance = math.huge


    local AllBodyParts = {
        "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftHand", "RightHand", 
        "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm", "LeftFoot", 
        "LeftLowerLeg", "LeftUpperLeg", "RightLowerLeg", "RightUpperLeg", "RightFoot"
    }

  
    for _, bodyPartName in pairs(AllBodyParts) do
        local part = character:FindFirstChild(bodyPartName)
        

        if part and part:IsA("BasePart") and isPartInFovAndVisible(part) and isPartVisible(part) then
  
            local screenPoint, onScreen = Current_Camera:WorldToScreenPoint(part.Position)
            local distance = (V2(screenPoint.X, screenPoint.Y) - V2(Mouse.X, Mouse.Y)).Magnitude

            if distance < shortestDistance then
                closestPart = part
                closestPoint = part.Position  
                shortestDistance = distance
            end
        end
    end

    return closestPart, closestPoint
end



local OldTimeDistortion = shared.Forbidden['Silent Precision'].TimeDistortion  

local function GetVelocity(player, part)
    if player and player.Character then
        local velocity = player.Character[part].Velocity
        
        -- Time distortion factors from Silent Precision
        local distortionX = shared.Forbidden['Silent Precision'].TimeDistortion.X
        local distortionY = shared.Forbidden['Silent Precision'].TimeDistortion.Y
        local distortionZ = shared.Forbidden['Silent Precision'].TimeDistortion.Z
        
        -- Adjust the velocity based on the time distortion factors
        local adjustedVelocity = Vector3.new(
            velocity.X * distortionX,
            velocity.Y * distortionY,
            velocity.Z * distortionZ
        )

        -- If velocity is too low or too high, apply different behaviors based on the resolver setting
        if adjustedVelocity.Y < -30 and shared.Forbidden['Silent Precision'].Resolver then
            shared.Forbidden['Silent Precision'].TimeDistortion = { X = 0, Y = 0, Z = 0 } 
            return adjustedVelocity
        elseif adjustedVelocity.Magnitude > 50 and shared.Forbidden['Silent Precision'].Resolver then
            return player.Character:FindFirstChild("Humanoid").MoveDirection * 16 * distortionX  
        else
            shared.Forbidden['Silent Precision'].TimeDistortion = OldTimeDistortion 
            return adjustedVelocity
        end
    end
    return Vector3.new(0, 0, 0)  
end





local function GetClosestPlr()
    local closestTarget = nil
    local maxDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and player ~= Local_Player and not Death(player) then  
            local closestPart, closestPoint = GetClosestHitPoint(player.Character)
            if closestPart and closestPoint then
                local screenPoint = Current_Camera:WorldToScreenPoint(closestPoint)
                local distance = (V2(screenPoint.X, screenPoint.Y) - V2(Mouse.X, Mouse.Y)).Magnitude
                if distance < maxDistance then
                    maxDistance = distance
                    closestTarget = player
                end
            end
        end
    end


    if closestTarget and Death(closestTarget) then
        return nil
    end

    return closestTarget
end






local function getKeyCodeFromString(key)
    return Enum.KeyCode[key]
end


UserInputService.InputBegan:Connect(function(input, isProcessed)
    if not isProcessed and input.UserInputType == Enum.UserInputType.MouseButton1 then
        holdingMouseButton = true
        local closestPlayer = GetClosestPlr()

        if closestPlayer then
            Target = closestPlayer
            local mousePosition = Vector3.new(Mouse.X, Mouse.Y, 0)

            local remoteEvent = Replicated_Storage:FindFirstChild(RemoteEvent) 
            if remoteEvent then

                if Argument then
                    local success, err = pcall(function()
                        remoteEvent:FireServer(Argument, mousePosition)
                    end)
                    if not success then

                    end
                else
       
                end
            else
          
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, isProcessed)
    if input.KeyCode == Enum.KeyCode[shared.Forbidden.ActivationKey:upper()] and shared.Forbidden.pointassist.Method == "hold" then
        holdingMouseButton = false
    end
end)





local LastTarget = nil  


local function IsVisible(targetPosition)
    local character = game.Players.LocalPlayer.Character
    if not character then return false end

    local origin = character.Head.Position 
    local direction = (targetPosition - origin).Unit * 1000  

    -- Perform the raycast
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {character}  

    local raycastResult = workspace:Raycast(origin, direction, rayParams)
    
  
    return raycastResult and (raycastResult.Position - targetPosition).Magnitude < 5
end


RunService.RenderStepped:Connect(function()
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        local humanoid = character.Humanoid

        if humanoid.Health <= 1 then
            TargetPlayer = nil
            IsTargeting = false
            LastTarget = nil  
            return
        end
    end
    
    if shared.Forbidden['Silent Precision'].IsActive and IsTargeting then  
        UpdateFOV()  
    
        
        if TargetPlayer then
            if TargetPlayer.Character then
                local targetPos = TargetPlayer.Character.Head.Position
                if TargetPlayer.Character.Humanoid.Health < 1 then
                    TargetPlayer = nil
                    IsTargeting = false
                    LastTarget = nil 
                    return
                end
    
                if Death(TargetPlayer) then
                    TargetPlayer = nil
                    IsTargeting = false
                    LastTarget = nil  
                    return
                end
    
                if not IsVisible(targetPos) then
                    IsTargeting = false
                    LastTarget = TargetPlayer 
                    return
                end
    
                local closestPart, closestPoint = GetClosestHitPoint(TargetPlayer.Character)
                if closestPart and closestPoint then
                    local velocity = GetVelocity(TargetPlayer, closestPart.Name)
    
                    local timeDistortionX = shared.Forbidden['Silent Precision'].TimeDistortion.X
                    local timeDistortionY = shared.Forbidden['Silent Precision'].TimeDistortion.Y
                    local timeDistortionZ = shared.Forbidden['Silent Precision'].TimeDistortion.Z
    
                    local adjustedVelocity = velocity * Vector3.new(timeDistortionX, timeDistortionY, timeDistortionZ)
    
                    Replicated_Storage[RemoteEvent]:FireServer(Argument, closestPoint + adjustedVelocity)
                end
            end
        end
    elseif LastTarget and LastTarget.Character then
        local lastTargetPos = LastTarget.Character.Head.Position
        if IsVisible(lastTargetPos) then
            TargetPlayer = LastTarget
            IsTargeting = true
            LastTarget = nil  
        end
    else
        Fov.Visible = false  
    end
    end)
    
    
    
    task.spawn(function()
        while task.wait(0.1) do
            if shared.Forbidden['Silent Precision'].IsActive then
                Fov.Visible = IsTargeting and shared.Forbidden['Silent Precision'].VoidLimits.FovVisible 
            end
        end
    end)
    



    local function HookTool(tool)
        if tool:IsA("Tool") then
            tool.Activated:Connect(function()
                if tick() - lastToolUse > 0.1 then  
                    lastToolUse = tick()
    
                    
                    local target = TargetPlayer  
                    
                    if target and target.Character then
                        local closestPart, closestPoint = GetClosestHitPoint(target.Character) 
                        if closestPart and closestPoint then
                            local velocity = GetVelocity(target, closestPart.Name)
                        
                            local timeDistortionX = shared.Forbidden['Silent Precision'].TimeDistortion.X
                            local timeDistortionY = shared.Forbidden['Silent Precision'].TimeDistortion.Y
                            local timeDistortionZ = shared.Forbidden['Silent Precision'].TimeDistortion.Z
                            
                            local adjustedVelocity = velocity * Vector3.new(timeDistortionX, timeDistortionY, timeDistortionZ)
                            
                       
                            Replicated_Storage[RemoteEvent]:FireServer(Argument, closestPoint + adjustedVelocity)
                        end
                    end
                end
            end)
        end
    end
    
    local function onCharacterAdded(character)
        character.ChildAdded:Connect(HookTool)
        for _, tool in pairs(character:GetChildren()) do
            HookTool(tool)
        end
    end
    
    Local_Player.CharacterAdded:Connect(onCharacterAdded)
    if Local_Player.Character then
        onCharacterAdded(Local_Player.Character)
    end
    

if shared.Forbidden.TargetControl.BlockGroundHits == true then
    local function CheckNoGroundShots(Plr)
        if shared.Forbidden.TargetControl.BlockGroundHits and Plr.Character:FindFirstChild("Humanoid") and Plr.Character.Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            pcall(function()
                local TargetVelv5 = Plr.Character:FindFirstChild(shared.Forbidden.Silent and shared.Forbidden.Silent)
                if TargetVelv5 then
                    TargetVelv5.Velocity = Vector3.new(TargetVelv5.Velocity.X, (TargetVelv5.Velocity.Y * 0.2), TargetVelv5.Velocity.Z)
                    TargetVelv5.AssemblyLinearVelocity = Vector3.new(TargetVelv5.Velocity.X, (TargetVelv5.Velocity.Y * 0.2), TargetVelv5.Velocity.Z)
                end
            end)
        end
    end
end
