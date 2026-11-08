--[[
	                                                                             
                                                                             
   ▄▄▄  ▄▄▄                                                           ▄▄▄▄▄  
  █▀██  ██                     █▄                                █▄  ██▀▀▀██ 
    ██  ██                    ▄██▄                            ▀▀▄██▄    ▄██▀ 
    ██████   ▄███▄▀█▄ █▄ ██▀   ██ ▄███▄   ██ ██ ▄██▀█ ▄█▀█▄   ██ ██    ██    
    ██  ██   ██ ██ ██▄██▄██    ██ ██ ██   ██ ██ ▀███▄ ██▄█▀   ██ ██          
  ▀██▀  ▀██▄▄▀███▀  ▀██▀██▀   ▄██▄▀███▀  ▄▀██▀██▄▄██▀▄▀█▄▄▄  ▄██▄██    ██    
                                                                             
                                                                             
Your script returns a module called fling_hub, so you can call its functions after loading it.

1. Load the module
If you saved the code in a ModuleScript, require it from a script running in the appropriate Roblox context:

lua

local fling_hub = loadstring(game:HttpGet("https://pastebin.com/raw/mZqw4NLd"))()


2. Fling a player
Call fling with the player's username NOT THE DISPLAY:

fling_hub.fling("Player_Name")
Example:


fling_hub.fling("anoing_user67")


3. Stop the fling


fling_hub.stop_current_fling()


4. Get the player list

local players = fling_hub.players_refresh_list()

for _, name in ipairs(players) do
    print(name)
end






                                   
   ▄▄     ▄▄▄                      
   ██▄   ██▀      █▄               
   ███▄  ██      ▄██▄              
   ██ ▀█▄██ ▄███▄ ██ ▄█▀█▄ ▄██▀█ ▀ 
   ██   ▀██ ██ ██ ██ ██▄█▀ ▀███▄   
 ▀██▀    ██▄▀███▀▄██▄▀█▄▄▄█▄▄██▀ ▄ 
                                   
                                   
fling matches usernames and display names without case sensitivity.

players_refresh_list() returns usernames of other players in the server.

The module uses physics manipulation and extremely large or invalid velocity values. These can destabilize your character's physics or cause unexpected behavior.

The script relies on client-side behavior that may not work in every Roblox experience.

Note: Your module exports fling, not ExecuteUltraFling. To use the latter name from your original example, you would need to add an alias:


fling_hub.ExecuteUltraFling = fling_hub.fling

This makes fling_hub.ExecuteUltraFling("Player_Name") call the same function.







                                                                 
    ▄▄▄                    ▄▄▄▄▄▄                                
   ██▀▀█▄                 █▀██▀▀██              █▄               
   ██ ▄█▀                   ██   ██             ██          ▄    
   ██▀▀█▄ ██ ██             ██   ██ ▄▀▀█▄ ▄██▀█ ████▄ ▄█▀█▄ ████▄
 ▄ ██  ▄█ ██▄██   ▀▀▀▀    ▄ ██   ██ ▄█▀██ ▀███▄ ██ ██ ██▄█▀ ██   
 ▀██████▀▄▄▀██▀           ▀██▀███▀ ▄▀█▄███▄▄██▀▄██ ██▄▀█▄▄▄▄█▀   
            ██                                                   
          ▀▀▀






--]]




-- Main code YAY!

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Player = Players.LocalPlayer

local fling_hub = {}
local FlingActive = false


local function GetTargetCollidablePart(targetCharacter)
    if not targetCharacter then return nil end
    
    local priorityParts = {
        "HumanoidRootPart", 
        "Torso", 
        "UpperTorso", 
        "LowerTorso", 
        "Head"
    }
    
    for _, partName in ipairs(priorityParts) do
        local part = targetCharacter:FindFirstChild(partName)
        if part and part:IsA("BasePart") and part.CanCollide then
            return part
        end
    end

    for _, child in ipairs(targetCharacter:GetChildren()) do
        if child:IsA("BasePart") and child.CanCollide then
            return child
        end
    end
    
    return targetCharacter:FindFirstChild("HumanoidRootPart") or targetCharacter:FindFirstChildOfClass("BasePart")
end

local function ExecuteUltraFling(TargetPlayer)
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    
    local TCharacter = TargetPlayer.Character
    local TargetPart = GetTargetCollidablePart(TCharacter)
    
    if not Character or not Humanoid or not RootPart or not TargetPart then return end

    workspace.FallenPartsDestroyHeight = 0/0

    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(Player, "SimulationRadius", math.huge)
            sethiddenproperty(RootPart, "PhysicsRepRootPart", TargetPart)
        end
    end)

    local activeBodies = {}
    

    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(9e9, 9e9, 9e9)
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent = RootPart
    table.insert(activeBodies, bv)
    
    local bf = Instance.new("BodyForce")
    bf.Force = Vector3.new(9e9, 9e9, 9e9)
    bf.Parent = RootPart
    table.insert(activeBodies, bf)
    

    local torque = Instance.new("Torque")
    torque.Torque = Vector3.new(9e9, 9e9, 9e9)
    torque.Parent = RootPart
    table.insert(activeBodies, torque)
    

    local nan = 0 / 0
    for i = 1, 10 do
        local nanBv = Instance.new("BodyVelocity")
        nanBv.Velocity = Vector3.new(nan, nan, nan)
        nanBv.MaxForce = Vector3.new(9e30, 9e30, 9e30)
        nanBv.Parent = RootPart
        table.insert(activeBodies, nanBv)
    end
    
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    local function FPos(BasePart, Pos, Ang)
        RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        RootPart.Velocity = Vector3.new(9e9, 9e9, 9e9)
        RootPart.RotVelocity = Vector3.new(9e9, 9e9, 9e9)
        

        pcall(function()
            RootPart.AssemblyLinearVelocity = Vector3.new(nan, nan, nan)
            RootPart.AssemblyAngularVelocity = Vector3.new(nan, nan, nan)
        end)
    end

    local startTime = tick()
    local angle = 0
    
    repeat
        TargetPart = GetTargetCollidablePart(TCharacter)
        if not RootPart or not TargetPart or not TargetPart.Parent then break end
        
        angle = angle + 100
        local ang = CFrame.Angles(math.rad(angle), 0, 0)
        
        FPos(TargetPart, CFrame.new(0, 1.5, 0), ang)
        task.wait()
        FPos(TargetPart, CFrame.new(0, -1.5, 0), ang)
        task.wait()
    until tick() - startTime >= 1.5 or not FlingActive


    for _, body in ipairs(activeBodies) do
        if body and body.Destroy then
            body:Destroy()
        end
    end
end

function fling_hub.stop_current_fling(savedCFrame)
    FlingActive = false
    
    local Character = Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart

    if Character and RootPart and Humanoid then
        for _, v in pairs(Character:GetDescendants()) do
            if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyThrust") or 
               v:IsA("LinearVelocity") or v:IsA("Torque") or v:IsA("AlignPosition") then
                v:Destroy()
            end
        end

        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        Humanoid.PlatformStand = false
        Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

        for _, part in pairs(Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.Velocity = Vector3.zero
                part.RotVelocity = Vector3.zero
            end
        end

        if savedCFrame then
            RootPart.CFrame = savedCFrame
        end
    end
end

function fling_hub.fling(targetIdentifier)
    local targetPlayer = nil
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == tostring(targetIdentifier):lower() or p.DisplayName:lower() == tostring(targetIdentifier):lower() then
            targetPlayer = p
            break
        end
    end

    if not targetPlayer then return end

    local Character = Player.Character
    local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    
    if not RootPart then return end

    local initialCFrame = RootPart.CFrame

    if FlingActive then
        fling_hub.stop_current_fling(initialCFrame)
    end

    FlingActive = true

    task.spawn(function()
        while FlingActive and targetPlayer and targetPlayer.Parent do
            ExecuteUltraFling(targetPlayer)
            task.wait(0.1)
        end
        
        fling_hub.stop_current_fling(initialCFrame)
    end)
end

function fling_hub.players_refresh_list()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then table.insert(list, p.Name) end
    end
    return list
end

print([[
    
 ________ ___       ___  ________   ________            
|\  _____\\  \     |\  \|\   ___  \|\   ____\           
\ \  \__/\ \  \    \ \  \ \  \\ \  \ \  \___|           
 \ \   __\\ \  \    \ \  \ \  \\ \  \ \  \  ___         
  \ \  \_| \ \  \____\ \  \ \  \\ \  \ \  \|\  \        
   \ \__\   \ \_______\ \__\ \__\\ \__\ \_______\       
    \|__|    \|_______|\|__|\|__| \|__|\|_______|       
                                                        
                                                        
                                                        
             ___  ___  ___  ___  ________               
            |\  \|\  \|\  \|\  \|\   __  \              
            \ \  \\\  \ \  \\\  \ \  \|\ /_             
             \ \   __  \ \  \\\  \ \   __  \            
              \ \  \ \  \ \  \\\  \ \  \|\  \           
               \ \__\ \__\ \_______\ \_______\          
                \|__|\|__|\|_______|\|_______|   -By dasher       
]])

local pastebin_version = "1.0"

print("Loaded on version: " .. pastebin_version)
print("This is a module scrip for fling on roblox. Ty for using it")
print("Url: https://pastebin.com/mZqw4NLd")

return fling_hub

--[[
    Yo! This project is open source. 
    If you modify or use this code, credit is appreciated! :3
	Plz dont stole.
]]