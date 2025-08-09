local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GhostyHelperGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 360, 0, 280)
frame.Position = UDim2.new(0.5, -180, 0.5, -140)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local uicorner = Instance.new("UICorner", frame)
uicorner.CornerRadius = UDim.new(0, 8)

-- Dragging logic
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                             startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleBar.Parent = frame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -10, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 20
titleText.TextColor3 = Color3.fromRGB(220, 220, 220)
titleText.Text = "Ghosty Helper"
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 36, 0, 36)
closeButton.Position = UDim2.new(1, -36, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 20
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.Parent = titleBar
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Tabs
local tabHolder = Instance.new("Frame")
tabHolder.Size = UDim2.new(1, 0, 0, 32)
tabHolder.Position = UDim2.new(0, 0, 0, 36)
tabHolder.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
tabHolder.Parent = frame

local tabNames = {"ESP", "Aimbot", "About"}
local tabs = {}
local pages = {}

local function createTabButton(name, posX)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.Position = UDim2.new(0, posX, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 16
    btn.Text = name
    btn.Parent = tabHolder
    return btn
end

local function createPage()
    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, -20, 1, -70)
    page.Position = UDim2.new(0, 10, 0, 70)
    page.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    page.Visible = false
    page.Parent = frame
    local pageUICorner = Instance.new("UICorner", page)
    pageUICorner.CornerRadius = UDim.new(0, 6)
    return page
end

for i, name in ipairs(tabNames) do
    tabs[i] = createTabButton(name, (i-1)*100)
    pages[i] = createPage()
end

pages[1].Visible = true
tabs[1].BackgroundColor3 = Color3.fromRGB(100, 100, 100)

for i, btn in ipairs(tabs) do
    btn.MouseButton1Click:Connect(function()
        for j, page in ipairs(pages) do
            page.Visible = (i == j)
            tabs[j].BackgroundColor3 = (i == j) and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(60, 60, 60)
        end
    end)
end

-- ESP tab
local espPage = pages[1]

local espToggle = Instance.new("TextButton")
espToggle.Size = UDim2.new(0, 140, 0, 40)
espToggle.Position = UDim2.new(0, 10, 0, 10)
espToggle.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
espToggle.TextColor3 = Color3.new(1,1,1)
espToggle.Font = Enum.Font.Gotham
espToggle.TextSize = 18
espToggle.Text = "Toggle ESP"
espToggle.Parent = espPage

local espOn = false
local highlights = {}

local function updateESP()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if not highlights[plr] then
                local highlight = Instance.new("Highlight")
                highlight.FillColor = Color3.fromRGB(0,255,0)
                highlight.OutlineColor = Color3.fromRGB(0,0,0)
                highlight.Adornee = plr.Character
                highlight.Parent = player.PlayerGui
                highlights[plr] = highlight
            end
        end
    end
end

local function clearESP()
    for plr, highlight in pairs(highlights) do
        highlight:Destroy()
        highlights[plr] = nil
    end
end

espToggle.MouseButton1Click:Connect(function()
    espOn = not espOn
    if espOn then
        espToggle.Text = "ESP: ON"
        updateESP()
    else
        espToggle.Text = "ESP: OFF"
        clearESP()
    end
end)

Players.PlayerAdded:Connect(function(plr)
    if espOn then
        wait(1)
        updateESP()
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    if highlights[plr] then
        highlights[plr]:Destroy()
        highlights[plr] = nil
    end
end)

-- Aimbot tab
local aimbotPage = pages[2]

local aimbotToggle = Instance.new("TextButton")
aimbotToggle.Size = UDim2.new(0, 140, 0, 40)
aimbotToggle.Position = UDim2.new(0, 10, 0, 10)
aimbotToggle.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
aimbotToggle.TextColor3 = Color3.new(1,1,1)
aimbotToggle.Font = Enum.Font.Gotham
aimbotToggle.TextSize = 18
aimbotToggle.Text = "Toggle Aimbot"
aimbotToggle.Parent = aimbotPage

local aimbotOn = false
local aiming = false

local function getNearestPlayer()
    local nearestPlayer = nil
    local nearestDist = math.huge

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local dist = (hrp.Position - camera.CFrame.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearestPlayer = plr
            end
        end
    end
    return nearestPlayer
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = aimbotOn
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    end
end)

RunService.RenderStepped:Connect(function()
    if aiming then
        local target = getNearestPlayer()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = target.Character.HumanoidRootPart.Position
            local camPos = camera.CFrame.Position
            local newCFrame = CFrame.new(camPos, targetPos)
            camera.CFrame = newCFrame
        end
    end
end)

aimbotToggle.MouseButton1Click:Connect(function()
    aimbotOn = not aimbotOn
    aimbotToggle.Text = aimbotOn and "Aimbot: ON" or "Aimbot: OFF"
end)

-- About tab
local aboutPage = pages[3]

local aboutLabel = Instance.new("TextLabel")
aboutLabel.Size = UDim2.new(1, -20, 1, -20)
aboutLabel.Position = UDim2.new(0, 10, 0, 10)
aboutLabel.BackgroundTransparency = 1
aboutLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
aboutLabel.Font = Enum.Font.Gotham
aboutLabel.TextSize = 16
aboutLabel.TextWrapped = true
aboutLabel.Text = [[
Ghosty Helper GUI
Executor Version (no server item spawn)

Features:
- Draggable main window
- Tabbed UI: ESP, Aimbot, About
- Toggleable ESP highlights for other players
- Toggleable "aimbot" camera look at nearest player on right-click
- Clean modern dark theme UI
- Safe for executor injection in any game
]]
aboutLabel.Parent = aboutPage
