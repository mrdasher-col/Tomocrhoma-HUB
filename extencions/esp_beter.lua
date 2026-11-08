
--[[

    ▄▄▄  ▄▄▄                                                           ▄▄▄▄▄
   █▀██  ██                     █▄                                █▄  ██▀▀▀██
     ██  ██                    ▄██▄                            ▀▀▄██▄    ▄██▀
     ██████   ▄███▄▀█▄ █▄ ██▀   ██ ▄███▄   ██ ██ ▄██▀█ ▄█▀█▄   ██ ██    ██
     ██  ██   ██ ██ ██▄██▄██    ██ ██ ██   ██ ██ ▀███▄ ██▄█▀   ██ ██
   ▀██▀  ▀██▄▄▀███▀  ▀██▀██▀   ▄██▄▀███▀  ▄▀██▀██▄▄██▀▄▀█▄▄▄  ▄██▄██    ██


               ESP MODULE | DOCUMENTATION

Your script returns a module called ESPModule.
It provides player ESP, role detection, inventory fallback,
Sheriff death detection and round timer monitoring.

------------------------------------------------------------

1. IMPORT

Using a ModuleScript:

local ESPModule = require(path.To.ESPModule)

Or using a hosted Lua source:

local ESPModule = loadstring(
    game:HttpGet("YOUR_RAW_SCRIPT_URL")
)()

------------------------------------------------------------

2. INITIALIZATION

Initialize the module:

ESPModule:Init()

The module automatically starts:

- Player ESP updates.
- Role detection through game events.
- GunDrop tracking.
- Round timer monitoring.
- Inventory role recovery.

------------------------------------------------------------

3. ESP TOGGLE

Enable or disable player ESP:

ESPModule:SetEnabled(true)

ESPModule:SetEnabled(false)

Check current state:

local enabled = ESPModule:IsEnabled()

------------------------------------------------------------

4. INVENTORY FALLBACK TOGGLE

Enable or disable automatic inventory scanning.

ESPModule:SetInventoryFallback(true)

ESPModule:SetInventoryFallback(false)

Check current state:

local enabled = ESPModule:IsInventoryFallbackEnabled()

Inventory detection:

- Gun prefix  -> Sheriff / Hero inference.
- Knife prefix -> Murderer.

Inventory scanning runs every 5 seconds.

------------------------------------------------------------

5. ROLE FUNCTIONS

Get a player's registered role:

local role = ESPModule:GetPlayerRole("PlayerName")

Possible returned roles:

- Innocent
- Sheriff
- Murderer
- Hero

Check whether a player has a gun:

local hasGun = ESPModule:HasGun("PlayerName")

You can also pass a Player instance:

local hasGun = ESPModule:HasGun(
    game.Players.PlayerName
)

------------------------------------------------------------

6. ROUND DETECTION

Check whether the round is active:

local active = ESPModule:IsRoundActive()

The module monitors:

Workspace.RoundTimerPart

It recursively searches for the TextLabel named "Timer".

Every 5 seconds:

- Changed timer text -> Round considered active.
- Unchanged timer text -> Round considered paused.
- Paused round -> Stored roles are cleared.
- New role event -> Roles are registered again.

------------------------------------------------------------

7. SHERIFF / HERO DETECTION

The module monitors the Sheriff's Humanoid.Died event.

When the Sheriff dies:

- Sheriff death state is activated.
- Hero detection becomes available.
- Gun holders can be identified as Hero.

------------------------------------------------------------

8. DESTROY

Completely stop the module:

ESPModule:Destroy()

This disconnects registered connections,
clears tracked ESP objects and resets internal data.

------------------------------------------------------------

9. COMPLETE EXAMPLE (NO UI)

local ESPModule = require(path.To.ESPModule)

ESPModule:Init()

-- Enable ESP
ESPModule:SetEnabled(true)

-- Enable inventory fallback
ESPModule:SetInventoryFallback(true)

-- Check player role
print(ESPModule:GetPlayerRole("PlayerName"))

-- Check gun possession
print(ESPModule:HasGun("PlayerName"))

-- Check round state
print(ESPModule:IsRoundActive())

-- Disable ESP
ESPModule:SetEnabled(false)

-- Stop everything
-- ESPModule:Destroy()

------------------------------------------------------------

10. KEYBIND EXAMPLE

local UserInputService =
    game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.V then

        local newState = not ESPModule:IsEnabled()

        ESPModule:SetEnabled(newState)

        print("ESP Enabled:", newState)

    elseif input.KeyCode == Enum.KeyCode.B then

        local newState =
            not ESPModule:IsInventoryFallbackEnabled()

        ESPModule:SetInventoryFallback(newState)

        print("Inventory Fallback:", newState)
    end
end)


                                                                
    ▄▄▄                    ▄▄▄▄▄▄
   ██▀▀█▄                 █▀██▀▀██              █▄
   ██ ▄█▀                   ██   ██             ██          ▄
   ██▀▀█▄ ██ ██             ██   ██ ▄▀▀█▄ ▄██▀█ ████▄ ▄█▀█▄ ████▄
 ▄ ██  ▄█ ██▄██   ▀▀▀▀    ▄ ██   ██ ▄█▀██ ▀███▄ ██ ██ ██▄█▀ ██
 ▀██████▀▄▄▀██▀           ▀██▀███▀ ▄▀█▄███▄▄██▀▄██ ██▄▀█▄▄▄▄█▀
            ██
          ▀▀▀

                         END OF DOCUMENTATION

]]



--[[
    ESP MODULE | MM2
    Role ESP + Inventory Recovery + Round Detection
]]

local ESPModule = {}

--// SERVICES
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

--// CONFIGURATION
local CONFIG = {
    UpdateInterval = 0.5,
    TimerInterval = 5,

    FillTransparency = 0.85,
    OutlineTransparency = 0,

    HighlightTag = "_WH",
    BillboardTag = "_WBB",

    InventoryFallback = true,
}

--// COLORS
local COLORS = {
    Innocent = Color3.fromRGB(50, 205, 50),
    Sheriff = Color3.fromRGB(40, 120, 255),
    Hero = Color3.fromRGB(255, 255, 0),
    Murderer = Color3.fromRGB(220, 40, 40),
    Ended = Color3.fromRGB(128, 128, 128),
    GunDrop = Color3.fromRGB(255, 255, 0),
}

--// STATE
local playerRoles = {}
local trackedPlayers = {}
local trackedGunDrops = {}

local playerConnections = {}
local globalConnections = {}

local sheriffPlayerName = nil
local sheriffDead = false

local lastTimerText = nil
local timerInitialized = false

local espEnabled = true
local inventoryFallbackEnabled = CONFIG.InventoryFallback
local roundActive = true
local isInitialized = false

local sheriffDeathConnection = nil

--// CONNECTION HELPER
local function disconnect(connection)
    if connection then
        connection:Disconnect()
    end
end

--// FIND BILLBOARD PART
local function getBillboardPart(target)
    if not target then
        return nil
    end

    if target:IsA("BasePart") then
        return target
    end

    if target:IsA("Model") then
        return target.PrimaryPart
            or target:FindFirstChild("HumanoidRootPart")
            or target:FindFirstChild("Head")
            or target:FindFirstChildWhichIsA("BasePart")
    end

    return nil
end

--// CLEAR ESP
local function clearESP(target)
    if not target then
        return
    end

    local function clear(container)
        if not container then
            return
        end

        for _, obj in ipairs(container:GetChildren()) do
            if obj.Name == CONFIG.HighlightTag
                or obj.Name == CONFIG.BillboardTag then
                obj:Destroy()
            end
        end
    end

    clear(target)

    if target:IsA("Model") then
        clear(target:FindFirstChild("Head"))
    end
end

--// HIGHLIGHT
local function applyHighlight(target, color)
    if not target or not target.Parent then
        return
    end

    local highlight = target:FindFirstChild(CONFIG.HighlightTag)

    if highlight and highlight:IsA("Highlight") then
        highlight.Adornee = target
        highlight.FillColor = color
        highlight.OutlineColor = color
        return highlight
    end

    if highlight then
        highlight:Destroy()
    end

    highlight = Instance.new("Highlight")
    highlight.Name = CONFIG.HighlightTag
    highlight.Adornee = target

    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = color
    highlight.OutlineColor = color

    highlight.FillTransparency = CONFIG.FillTransparency
    highlight.OutlineTransparency = CONFIG.OutlineTransparency

    highlight.Parent = target

    return highlight
end

--// BILLBOARD
local function applyBillboard(target, text, color)
    local part = getBillboardPart(target)

    if not part then
        return
    end

    local billboard = part:FindFirstChild(CONFIG.BillboardTag)

    if billboard and billboard:IsA("BillboardGui") then
        local label = billboard:FindFirstChild("NameLabel")

        if label then
            label.Text = text
            label.TextColor3 = color
        end

        return billboard
    end

    if billboard then
        billboard:Destroy()
    end

    billboard = Instance.new("BillboardGui")
    billboard.Name = CONFIG.BillboardTag
    billboard.Adornee = part
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(180, 26)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.Name = "NameLabel"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1

    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = color
    label.TextStrokeTransparency = 1

    label.Parent = billboard

    return billboard
end

--// INVENTORY HELPERS
local function getInventoryItems(player)
    local items = {}

    local character = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")

    if character then
        for _, item in ipairs(character:GetChildren()) do
            table.insert(items, item)
        end
    end

    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            table.insert(items, item)
        end
    end

    return items
end

local function getInventoryRole(player)
    for _, item in ipairs(getInventoryItems(player)) do
        if item:IsA("Tool") then
            local name = item.Name:lower()

            -- Knife detection
            if name:match("^knife") then
                return "Murderer"
            end

            -- Gun detection
            if name:match("^gun") then
                return "Gun"
            end
        end
    end

    return nil
end

local function checkPlayerInventoryForGun(player)
    return getInventoryRole(player) == "Gun"
end

--// SHERIFF DEATH
local function watchSheriffDeath(player)
    disconnect(sheriffDeathConnection)
    sheriffDeathConnection = nil

    if not player then
        return
    end

    local function connectCharacter(character)
        local humanoid = character:WaitForChild("Humanoid", 10)

        if not humanoid then
            return
        end

        disconnect(sheriffDeathConnection)

        sheriffDeathConnection = humanoid.Died:Connect(function()
            if sheriffPlayerName ~= player.Name then
                return
            end

            sheriffDead = true

            print("[ESP] Sheriff died.")

            for _, target in ipairs(Players:GetPlayers()) do
                task.spawn(function()
                    updatePlayer(target)
                end)
            end
        end)
    end

    if player.Character then
        task.spawn(connectCharacter, player.Character)
    end

    local connections = playerConnections[player]

    if connections then
        disconnect(connections.sheriffCharacter)
    end

    connections = connections or {}
    playerConnections[player] = connections

    connections.sheriffCharacter = player.CharacterAdded:Connect(function(character)
        if sheriffPlayerName == player.Name and not sheriffDead then
            task.spawn(connectCharacter, character)
        end
    end)
end

--// ROLE COLOR
local function getRoleColor(player)
    if not roundActive then
        return COLORS.Ended
    end

    local role = playerRoles[player.Name] or "Innocent"

    if role == "Murderer" then
        return COLORS.Murderer
    end

    if role == "Sheriff" then
        return COLORS.Sheriff
    end

    if role == "Hero" then
        return sheriffDead and COLORS.Hero or COLORS.Innocent
    end

    if checkPlayerInventoryForGun(player) and sheriffDead then
        return COLORS.Hero
    end

    return COLORS.Innocent
end

--// ROLE TEXT
local function getRoleText(player)
    if not roundActive then
        return " [Ended]"
    end

    local role = playerRoles[player.Name] or "Innocent"

    if role == "Sheriff" then
        return " [Sheriff]"
    end

    if role == "Murderer" then
        return " [Murderer]"
    end

    if checkPlayerInventoryForGun(player) and sheriffDead then
        return " [Hero]"
    end

    if role == "Hero" and sheriffDead then
        return " [Hero]"
    end

    return " [Innocent]"
end

--// PLAYER UPDATE
function updatePlayer(player)
    if not player or player == LocalPlayer then
        return
    end

    local character = player.Character

    if not character then
        return
    end

    if not espEnabled then
        clearESP(character)
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")

    if not root or not head then
        return
    end

    local color = getRoleColor(player)

    applyHighlight(character, color)

    applyBillboard(
        head,
        player.DisplayName .. getRoleText(player),
        color
    )
end

--// GUNDROP TRACKING
local function checkAndTrackGunDrop(obj)
    if not obj or not obj.Parent then
        return
    end

    if not obj.Name:lower():find("gundrop", 1, true) then
        return
    end

    if trackedGunDrops[obj] then
        return
    end

    trackedGunDrops[obj] = true

    if espEnabled then
        applyHighlight(obj, COLORS.GunDrop)
        applyBillboard(obj, "GunDrop", COLORS.GunDrop)
    end

    local connection

    connection = obj.AncestryChanged:Connect(function(_, parent)
        if not parent then
            trackedGunDrops[obj] = nil
            disconnect(connection)
            clearESP(obj)
        end
    end)

    table.insert(globalConnections, connection)
end

--// PLAYER HOOK
local function hookPlayer(player)
    if player == LocalPlayer or playerConnections[player] then
        return
    end

    local connections = {}
    playerConnections[player] = connections

    connections.characterAdded = player.CharacterAdded:Connect(function(character)
        task.wait(0.2)

        trackedPlayers[player] = {
            character = character
        }

        updatePlayer(player)
    end)

    connections.characterRemoving = player.CharacterRemoving:Connect(function(character)
        clearESP(character)

        if trackedPlayers[player]
            and trackedPlayers[player].character == character then
            trackedPlayers[player] = nil
        end
    end)

    if player.Character then
        trackedPlayers[player] = {
            character = player.Character
        }

        task.spawn(updatePlayer, player)
    end
end

--// ROLE EVENT PARSER
local function parseRoleData(data)
    if type(data) ~= "table" then
        return
    end

    for playerName, playerData in pairs(data) do
        if type(playerData) == "table" and playerData.Role then
            local roleRaw = tostring(playerData.Role)

            local formattedRole =
                roleRaw:sub(1, 1):upper()
                .. roleRaw:sub(2):lower()

            playerRoles[tostring(playerName)] = formattedRole

            if formattedRole == "Sheriff" then
                sheriffPlayerName = tostring(playerName)
                sheriffDead = false

                local sheriff = Players:FindFirstChild(sheriffPlayerName)

                if sheriff then
                    watchSheriffDeath(sheriff)
                end
            end
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        updatePlayer(player)
    end
end

--// INVENTORY FALLBACK
local function recoverUnknownRoles()
    if not roundActive or not inventoryFallbackEnabled then
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not playerRoles[player.Name] then
            local inventoryRole = getInventoryRole(player)

            if inventoryRole == "Murderer" then
                playerRoles[player.Name] = "Murderer"

                print("[ESP] Murderer recovered:", player.Name)

            elseif inventoryRole == "Gun" then
                if sheriffDead then
                    playerRoles[player.Name] = "Hero"

                    print("[ESP] Hero recovered:", player.Name)

                elseif not sheriffPlayerName then
                    playerRoles[player.Name] = "Sheriff"
                    sheriffPlayerName = player.Name

                    watchSheriffDeath(player)

                    print("[ESP] Sheriff recovered:", player.Name)
                end
            end
        end
    end
end

--// TIMER
local function getTimerLabel()
    local timerPart = Workspace:FindFirstChild("RoundTimerPart")

    if not timerPart then
        return nil
    end

    local timer = timerPart:FindFirstChild("Timer", true)

    if timer and timer:IsA("TextLabel") then
        return timer
    end

    return nil
end

local function clearRoundRoles()
    table.clear(playerRoles)

    sheriffPlayerName = nil
    sheriffDead = false

    disconnect(sheriffDeathConnection)
    sheriffDeathConnection = nil

    print("[ESP] Round roles cleared.")
end

local function checkRoundTimer()
    local timerLabel = getTimerLabel()

    if not timerLabel then
        return
    end

    local currentText = timerLabel.Text

    if not timerInitialized then
        lastTimerText = currentText
        timerInitialized = true
        return
    end

    if currentText == lastTimerText then
        if roundActive then
            roundActive = false

            clearRoundRoles()

            print("[ESP] Timer paused.")

            for _, player in ipairs(Players:GetPlayers()) do
                updatePlayer(player)
            end
        end

        return
    end

    lastTimerText = currentText

    if not roundActive then
        print("[ESP] Timer resumed.")
    end

    roundActive = true
end

--// PUBLIC TOGGLES

function ESPModule:SetEnabled(state)
    espEnabled = state == true

    if not espEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                clearESP(player.Character)
            end
        end

        for drop in pairs(trackedGunDrops) do
            clearESP(drop)
        end

    else
        for _, player in ipairs(Players:GetPlayers()) do
            updatePlayer(player)
        end

        for drop in pairs(trackedGunDrops) do
            if drop and drop.Parent then
                applyHighlight(drop, COLORS.GunDrop)
                applyBillboard(drop, "GunDrop", COLORS.GunDrop)
            end
        end
    end
end

function ESPModule:IsEnabled()
    return espEnabled
end

function ESPModule:SetInventoryFallback(state)
    inventoryFallbackEnabled = state == true
end

function ESPModule:IsInventoryFallbackEnabled()
    return inventoryFallbackEnabled
end

function ESPModule:GetPlayerRole(playerOrName)
    local name

    if typeof(playerOrName) == "Instance" then
        name = playerOrName.Name
    else
        name = tostring(playerOrName)
    end

    return playerRoles[name] or "Innocent"
end

function ESPModule:HasGun(player)
    if typeof(player) == "string" then
        player = Players:FindFirstChild(player)
    end

    if not player or not player:IsA("Player") then
        return false
    end

    return checkPlayerInventoryForGun(player)
end

function ESPModule:IsRoundActive()
    return roundActive
end

--// INITIALIZATION
function ESPModule:Init()
    if isInitialized then
        return
    end

    isInitialized = true

    -- Existing GunDrops
    for _, obj in ipairs(Workspace:GetDescendants()) do
        checkAndTrackGunDrop(obj)
    end

    -- New GunDrops
    table.insert(globalConnections,
        Workspace.DescendantAdded:Connect(checkAndTrackGunDrop)
    )

    -- Existing players
    for _, player in ipairs(Players:GetPlayers()) do
        hookPlayer(player)
    end

    -- New players
    table.insert(globalConnections,
        Players.PlayerAdded:Connect(hookPlayer)
    )

    -- Player removal
    table.insert(globalConnections,
        Players.PlayerRemoving:Connect(function(player)
            local connections = playerConnections[player]

            if connections then
                for _, connection in pairs(connections) do
                    disconnect(connection)
                end
            end

            if trackedPlayers[player] then
                clearESP(trackedPlayers[player].character)
            end

            playerConnections[player] = nil
            trackedPlayers[player] = nil
            playerRoles[player.Name] = nil

            if sheriffPlayerName == player.Name then
                sheriffPlayerName = nil
                sheriffDead = false
                disconnect(sheriffDeathConnection)
                sheriffDeathConnection = nil
            end
        end)
    )

    -- Gameplay remotes
    task.spawn(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

        if not remotes then
            warn("[ESP] Remotes not found.")
            return
        end

        local gameplay = remotes:WaitForChild("Gameplay", 10)

        if not gameplay then
            warn("[ESP] Gameplay folder not found.")
            return
        end

        local events = {
            "Fade",
            "RoundStart",
            "RoleSelect",
            "ShowRoleSelect",
            "ShowRoleSelectNew",
            "PlayerDataChanged",
            "GameOver"
        }

        for _, eventName in ipairs(events) do
            local remote = gameplay:FindFirstChild(eventName)

            if remote and remote:IsA("RemoteEvent") then
                local connection = remote.OnClientEvent:Connect(function(...)
                    for _, value in ipairs({...}) do
                        if type(value) == "table" then
                            parseRoleData(value)
                        end
                    end
                end)

                table.insert(globalConnections, connection)
            end
        end
    end)

    -- Main update loop
    task.spawn(function()
        while isInitialized do
            if espEnabled then
                for _, player in ipairs(Players:GetPlayers()) do
                    updatePlayer(player)
                end
            end

            task.wait(CONFIG.UpdateInterval)
        end
    end)

    -- Timer + inventory loop
    task.spawn(function()
        while isInitialized do
            checkRoundTimer()

            if roundActive then
                recoverUnknownRoles()
            end

            task.wait(CONFIG.TimerInterval)
        end
    end)

    print("[ESP] Module initialized.")
end

--// DESTROY
function ESPModule:Destroy()
    if not isInitialized then
        return
    end

    isInitialized = false

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            clearESP(player.Character)
        end
    end

    for drop in pairs(trackedGunDrops) do
        clearESP(drop)
    end

    for _, connections in pairs(playerConnections) do
        for _, connection in pairs(connections) do
            disconnect(connection)
        end
    end

    for _, connection in ipairs(globalConnections) do
        disconnect(connection)
    end

    disconnect(sheriffDeathConnection)

    table.clear(playerConnections)
    table.clear(globalConnections)
    table.clear(trackedPlayers)
    table.clear(trackedGunDrops)
    table.clear(playerRoles)

    sheriffPlayerName = nil
    sheriffDead = false
    timerInitialized = false
    lastTimerText = nil

    print("[ESP] Module destroyed.")
end

return ESPModule
