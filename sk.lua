local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local CLOUD_CSV_URL = "https://raw.githubusercontent.com/Hidayathamir/kata-kbbi-github/main/kbbi.csv"
local KBBI_DATA, UsedWords, CurrentWordList = {}, {}, {}
local BotSpeed, LastTarget, AutoAnswer, HumanMode, ActiveMode, LengthFilter, IsTyping = 10, "", false, false, "Normal", 0, false

task.spawn(function()
    local success, result = pcall(function() return game:HttpGet(CLOUD_CSV_URL) end)
    if success then 
        for line in result:gmatch("[^\r\n]+") do 
            local word = line:gsub('"', ''):gsub('%s+', ''):upper() 
            if #word >= 4 then table.insert(KBBI_DATA, word) end 
        end 
    end
end)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BillboardRemote, SubmitRemote = Remotes:WaitForChild("BillboardUpdate"), Remotes:WaitForChild("SubmitWord")

local function GetDelay() return math.clamp((105 - BotSpeed) * 0.005, 0.01, 0.6) end

local function SmartSubmit(word)
    if not word or word == "" or IsTyping then return end
    IsTyping = true
    local target, prefix = word:upper(), LastTarget:upper()
    task.wait(math.random(0.5, 1.0) + (GetDelay() * 2))
    local currentTyped = prefix
    for i = #prefix + 1, #target do
        if not IsTyping then break end
        if HumanMode and math.random(1, 20) == 5 and i > #prefix + 1 then
            BillboardRemote:FireServer(currentTyped .. string.char(math.random(65, 90)))
            task.wait(GetDelay() * 2)
            BillboardRemote:FireServer(currentTyped)
            task.wait(GetDelay() * 1.5)
        end
        currentTyped = target:sub(1, i)
        BillboardRemote:FireServer(currentTyped)
        task.wait(GetDelay())
    end
    task.wait(0.3)
    if IsTyping then SubmitRemote:FireServer(target:lower()) UsedWords[target] = true end
    IsTyping = false
end

_G.UpdateWords = function(target)
    if target == "" then return end
    LastTarget = target:upper()
    if Player.PlayerGui.Alfread_V77:FindFirstChild("Main") then 
        Player.PlayerGui.Alfread_V77.Main.TBox.Text = "TARGET: "..LastTarget 
    end
    local Scroll = Player.PlayerGui.Alfread_V77.Main.Scroll
    for _, v in pairs(Scroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    CurrentWordList = {}
    for _, w in ipairs(KBBI_DATA) do
        local isHard = w:sub(-1):match("[FXZQJV]")
        if (w:sub(1, #target) == target:upper() and not UsedWords[w]) and (LengthFilter == 0 or #w == LengthFilter) and (ActiveMode == "Normal" or (ActiveMode == "Mudah" and not isHard) or (ActiveMode == "Sulit" and isHard)) then
            table.insert(CurrentWordList, {w = w, s = (100 - #w) + (isHard and 500 or 0)})
        end
    end
    table.sort(CurrentWordList, function(a, b) return a.s > b.s end)
    
    -- Limit List ke 500 Kata
    local displayLimit = math.min(500, #CurrentWordList)
    Scroll.CanvasSize = UDim2.new(0, 0, 0, displayLimit * 32)
    
    for i=1, displayLimit do
        local wd = CurrentWordList[i]
        local B = Instance.new("TextButton", Scroll); B.Size = UDim2.new(1, -5, 0, 30); B.Text = "  "..wd.w; 
        B.BackgroundColor3 = Color3.fromRGB(35, 25, 55); 
        B.TextColor3 = Color3.fromRGB(0, 255, 128); -- WARNA HIJU LIST
        B.Font = "GothamSemibold"; B.TextXAlignment = "Left"; 
        B.ZIndex = 10;
        local BCorn = Instance.new("UICorner", B); BCorn.CornerRadius = UDim.new(0, 6)
        local BStroke = Instance.new("UIStroke", B); BStroke.Color = Color3.fromRGB(80, 50, 120); BStroke.Thickness = 1
        
        if wd.w:sub(-1):match("[FXZQJV]") then 
            local Ex = Instance.new("TextLabel", B); Ex.Size = UDim2.new(0, 20, 0, 20); Ex.Position = UDim2.new(1, -25, 0.5, -10); Ex.Text = "★"; Ex.TextColor3 = Color3.fromRGB(255, 100, 150); Ex.BackgroundTransparency = 1; Ex.Font = "GothamBold" 
        end
        B.MouseButton1Click:Connect(function() SmartSubmit(wd.w) end)
    end
    if AutoAnswer and #CurrentWordList > 0 and not IsTyping then 
        task.spawn(function() task.wait(0.5) if not IsTyping then local w = CurrentWordList[1].w table.remove(CurrentWordList, 1) SmartSubmit(w) end end) 
    end
end

if Player.PlayerGui:FindFirstChild("Alfread_V77") then Player.PlayerGui.Alfread_V77:Destroy() end
local SG = Instance.new("ScreenGui", Player.PlayerGui); SG.Name = "Alfread_V77"
SG.DisplayOrder = 999999999 -- INDEX TERTINGGI AGAR DI ATAS KEYBOARD

local Toggle = Instance.new("TextButton", SG); Toggle.Size = UDim2.new(0, 50, 0, 50); Toggle.Position = UDim2.new(0.9, 0, 0.2, 0); Toggle.Text = "⚡"; Toggle.Font = "GothamBold"; Toggle.TextSize = 24; Toggle.Draggable = true; 
Toggle.BackgroundColor3 = Color3.fromRGB(30, 20, 50); Toggle.TextColor3 = Color3.fromRGB(200, 150, 255);
Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1,0)
local TglStroke = Instance.new("UIStroke", Toggle); TglStroke.Color = Color3.fromRGB(130, 60, 255); TglStroke.Thickness = 2

local Main = Instance.new("Frame", SG); Main.Name = "Main"; Main.Size = UDim2.new(0, 240, 0, 480); Main.Position = UDim2.new(1, 20, 0.1, 0); 
Main.BackgroundColor3 = Color3.fromRGB(20, 15, 30); Main.Draggable = true; 
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", Main); MainStroke.Color = Color3.fromRGB(100, 50, 180); MainStroke.Thickness = 2

local Title = Instance.new("TextLabel", Main); Title.Size = UDim2.new(1, 0, 0, 40); Title.Text = "ALFREAD V77.1"; Title.Font = "GothamBlack"; Title.TextColor3 = Color3.fromRGB(220, 180, 255); Title.TextSize = 16; Title.BackgroundTransparency = 1

local TBox = Instance.new("TextLabel", Main); TBox.Name = "TBox"; TBox.Size = UDim2.new(1, -20, 0, 35); TBox.Position = UDim2.new(0, 10, 0, 40); 
TBox.BackgroundColor3 = Color3.fromRGB(30, 20, 50); TBox.Text = "TARGET: ??"; TBox.TextColor3 = Color3.fromRGB(150, 255, 200); TBox.Font = "GothamBold"; 
TBox.TextXAlignment = "Center"; -- TARGET DI TENGAH
Instance.new("UICorner", TBox).CornerRadius = UDim.new(0, 6)
local TBoxStroke = Instance.new("UIStroke", TBox); TBoxStroke.Color = Color3.fromRGB(80, 50, 120); TBoxStroke.Thickness = 1

local function CreateBtn(name, pos, size, parent, func)
    local b = Instance.new("TextButton", parent); b.Text = name; b.Size = size; b.Position = pos; 
    b.BackgroundColor3 = Color3.fromRGB(40, 30, 60); b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamBold"; 
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", b); stroke.Color = Color3.fromRGB(90, 60, 140); stroke.Thickness = 1
    b.MouseButton1Click:Connect(function() func(b) end); return b
end

local FR1 = Instance.new("Frame", Main); FR1.Size = UDim2.new(1, -20, 0, 30); FR1.Position = UDim2.new(0, 10, 0, 85); FR1.BackgroundTransparency = 1; Instance.new("UIListLayout", FR1).FillDirection = "Horizontal"; FR1.UIListLayout.Padding = UDim.new(0, 5)
CreateBtn("Mudah", UDim2.new(0,0,0,0), UDim2.new(0.48,0,1,0), FR1, function(b) ActiveMode = (ActiveMode == "Mudah" and "Normal" or "Mudah") for _, v in pairs(FR1:GetChildren()) do if v:IsA("TextButton") then v.BackgroundColor3 = Color3.fromRGB(40, 30, 60) end end if ActiveMode == "Mudah" then b.BackgroundColor3 = Color3.fromRGB(130, 60, 255) end _G.UpdateWords(LastTarget) end)
CreateBtn("Sulit", UDim2.new(0,0,0,0), UDim2.new(0.48,0,1,0), FR1, function(b) ActiveMode = (ActiveMode == "Sulit" and "Normal" or "Sulit") for _, v in pairs(FR1:GetChildren()) do if v:IsA("TextButton") then v.BackgroundColor3 = Color3.fromRGB(40, 30, 60) end end if ActiveMode == "Sulit" then b.BackgroundColor3 = Color3.fromRGB(130, 60, 255) end _G.UpdateWords(LastTarget) end)

local FR2 = Instance.new("Frame", Main); FR2.Size = UDim2.new(1, -20, 0, 30); FR2.Position = UDim2.new(0, 10, 0, 120); FR2.BackgroundTransparency = 1; Instance.new("UIListLayout", FR2).FillDirection = "Horizontal"; FR2.UIListLayout.Padding = UDim.new(0, 5)
for _, h in pairs({5,6,7}) do CreateBtn(h.."H", UDim2.new(0,0,0,0), UDim2.new(0.31,0,1,0), FR2, function(b) LengthFilter = (LengthFilter == h and 0 or h) for _, v in pairs(FR2:GetChildren()) do if v:IsA("TextButton") then v.BackgroundColor3 = Color3.fromRGB(40, 30, 60) end end if LengthFilter == h then b.BackgroundColor3 = Color3.fromRGB(130, 60, 255) end _G.UpdateWords(LastTarget) end) end

local AtBtn = CreateBtn("AUTO JAWAB: OFF", UDim2.new(0,10,0,160), UDim2.new(1,-20,0,35), Main, function(b) AutoAnswer = not AutoAnswer b.Text = "AUTO JAWAB: "..(AutoAnswer and "ON" or "OFF") b.BackgroundColor3 = AutoAnswer and Color3.fromRGB(130, 60, 255) or Color3.fromRGB(40, 30, 60) end)
local HmBtn = CreateBtn("HUMAN MODE: OFF", UDim2.new(0,10,0,200), UDim2.new(1,-20,0,35), Main, function(b) HumanMode = not HumanMode b.Text = "HUMAN MODE: "..(HumanMode and "ON" or "OFF") b.BackgroundColor3 = HumanMode and Color3.fromRGB(160, 80, 255) or Color3.fromRGB(40, 30, 60) end)

local SL = Instance.new("TextLabel", Main); SL.Size = UDim2.new(1,0,0,20); SL.Position = UDim2.new(0,0,0,245); SL.Text = "SPEED: "..BotSpeed; SL.TextColor3 = Color3.fromRGB(220, 180, 255); SL.Font = "GothamBold"; SL.BackgroundTransparency = 1
CreateBtn("-", UDim2.new(0.2,0,0,265), UDim2.new(0,40,0,25), Main, function() BotSpeed = math.max(1, BotSpeed - 5) SL.Text = "SPEED: "..BotSpeed end)
CreateBtn("+", UDim2.new(0.6,0,0,265), UDim2.new(0,40,0,25), Main, function() BotSpeed = math.min(100, BotSpeed + 5) SL.Text = "SPEED: "..BotSpeed end)

local Scroll = Instance.new("ScrollingFrame", Main); Scroll.Name = "Scroll"; Scroll.Size = UDim2.new(1, -20, 1, -305); Scroll.Position = UDim2.new(0, 10, 0, 295); Scroll.BackgroundTransparency = 1; Scroll.ScrollBarThickness = 3; Scroll.ScrollBarImageColor3 = Color3.fromRGB(130, 60, 255); Instance.new("UIListLayout", Scroll).Padding = UDim.new(0, 5)
Toggle.MouseButton1Click:Connect(function() Main:TweenPosition(Main.Position.X.Offset > 0 and UDim2.new(0.5, -120, 0.1, 0) or UDim2.new(1, 20, 0.1, 0), "Out", "Quart", 0.3, true) end)

task.spawn(function()
    while true do task.wait(0.2)
        for _, v in pairs(Player.PlayerGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Visible and v.Text:find("Hurufnya adalah") then
                for _, child in pairs(v.Parent:GetChildren()) do
                    if child:IsA("TextLabel") and child ~= v and child.Visible and #child.Text >= 1 and #child.Text <= 4 then
                        local t = child.Text:gsub("%s+", ""):upper()
                        if t:match("^[A-Z]+$") and t ~= LastTarget then IsTyping = false task.wait(0.1) _G.UpdateWords(t) end
                    end
                end
            elseif v:IsA("TextLabel") and (v.Text:find("Pemenang") or v.Text:find("Eliminasi")) then UsedWords = {} end
        end
        if AutoAnswer and not IsTyping then
            pcall(function()
                for _, v in pairs(Player.PlayerGui:GetDescendants()) do
                    if v:IsA("TextBox") and v.Visible and v.Parent.Name ~= "ChatBar" and #v.Text > #LastTarget then
                        task.wait(1.5)
                        if v.Visible and #v.Text > #LastTarget then
                            IsTyping = true
                            local ct = v.Text
                            for i = #ct, #LastTarget, -1 do BillboardRemote:FireServer(ct:sub(1, i)) task.wait(GetDelay() * 0.6) end
                            IsTyping = false
                            if #CurrentWordList > 0 then local nw = CurrentWordList[1].w table.remove(CurrentWordList, 1) SmartSubmit(nw) end
                        end
                        break
                    end
                end
            end)
        end
    end
end)
