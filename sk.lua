local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Player = Players.LocalPlayer

-- 1. CONFIG & DATABASE
local CLOUD_CSV_URL = "https://raw.githubusercontent.com/Hidayathamir/kata-kbbi-github/main/kbbi.csv"
local KBBI_DATA, UsedWords, CurrentWordList = {}, {}, {}
local BotSpeed, LastTarget, AutoAnswer, ActiveMode, LengthFilter, IsTyping = 10, "", false, "Normal", 0, false
local TypoMode = false -- Fitur baru

-- Database Typo (Huruf yang berdekatan di keyboard)
local KeyNeighbors = {
    A="S", B="V", C="X", D="F", E="R", F="G", G="H", H="J", I="O", J="K", K="L", L="P",
    M="N", N="B", O="P", P="O", Q="W", R="T", S="D", T="Y", U="I", V="C", W="E", X="Z", Y="U", Z="X"
}

-- Load Data KBBI
task.spawn(function()
    local success, result = pcall(function() return game:HttpGet(CLOUD_CSV_URL) end)
    if success then 
        for line in result:gmatch("[^\r\n]+") do 
            local word = line:gsub('"', ''):gsub('%s+', ''):upper() 
            if #word >= 3 then table.insert(KBBI_DATA, word) end 
        end 
    end
end)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BillboardRemote, SubmitRemote = Remotes:WaitForChild("BillboardUpdate"), Remotes:WaitForChild("SubmitWord")

-- ==========================================
-- 2. LOGIKA HUMAN TYPO (BARU)
-- ==========================================
local function SmartSubmit(word)
    if not word or word == "" or IsTyping then return end
    IsTyping = true
    
    local target = word:upper()
    local charDelay = (1 / math.max(1, BotSpeed)) * 2.7
    
    -- JEDA AWAL (0.5 - 1.0 detik)
    task.wait(math.random(5, 10) / 10) 
    
    local currentText = LastTarget:upper()
    local prefixLen = #currentText
    
    -- Tentukan Berapa Kali Typo (Pendek 1-2, Panjang up to 3)
    local maxTypos = (#target > 6) and math.random(1, 3) or math.random(1, 2)
    local typoIndices = {}
    if TypoMode then
        for _=1, maxTypos do
            table.insert(typoIndices, math.random(prefixLen + 1, #target))
        end
    end

    for i = prefixLen + 1, #target do
        if not IsTyping then break end
        
        local isTypoTime = false
        for _, idx in pairs(typoIndices) do if idx == i then isTypoTime = true end end
        
        if TypoMode and isTypoTime then
            -- Lakukan Typo
            local realChar = target:sub(i, i)
            local fakeChar = KeyNeighbors[realChar] or "A"
            currentText = currentText .. fakeChar
            BillboardRemote:FireServer(currentText)
            task.wait(charDelay * 1.5) -- Jeda "mikir" pas typo
            
            -- Hapus Typo (Backspacing)
            currentText = currentText:sub(1, #currentText - 1)
            BillboardRemote:FireServer(currentText)
            task.wait(charDelay * 0.8)
        end
        
        -- Ketik Huruf Benar
        currentText = currentText .. target:sub(i, i)
        BillboardRemote:FireServer(currentText)
        task.wait(charDelay)
    end
    
    -- JEDA SUBMIT (0.2 - 0.4 detik)
    task.wait(math.random(2, 4) / 10) 
    
    SubmitRemote:FireServer(target:lower())
    UsedWords[target] = true
    task.wait(0.5)
    IsTyping = false
end

-- ==========================================
-- 3. UI SETUP
-- ==========================================
if Player.PlayerGui:FindFirstChild("Alfread_V77") then Player.PlayerGui.Alfread_V77:Destroy() end
local SG = Instance.new("ScreenGui", Player.PlayerGui); SG.Name = "Alfread_V77"; SG.DisplayOrder = 2147483647; SG.ResetOnSpawn = false

local Main = Instance.new("Frame", SG); Main.Name = "Main"; Main.Size = UDim2.new(0, 260, 0, 560); Main.Position = UDim2.new(0.5, -130, 0.2, 0); Main.BackgroundColor3 = Color3.fromRGB(15, 10, 25); Main.Visible = true; Main.Draggable = true; Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", Main); MainStroke.Color = Color3.fromRGB(255, 40, 100); MainStroke.Thickness = 2.5

local Toggle = Instance.new("TextButton", SG); Toggle.Size = UDim2.new(0, 50, 0, 50); Toggle.Position = UDim2.new(0.9, -10, 0.4, 0); Toggle.Text = "⚡"; Toggle.Font = "GothamBlack"; Toggle.TextSize = 25; Toggle.BackgroundColor3 = Color3.fromRGB(30, 20, 50); Toggle.TextColor3 = Color3.new(1,1,1); Toggle.Draggable = true; Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1,0)
Toggle.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

local TBox = Instance.new("TextLabel", Main); TBox.Size = UDim2.new(1, -20, 0, 35); TBox.Position = UDim2.new(0, 10, 0, 10); TBox.Text = "TARGET: ??"; TBox.BackgroundColor3 = Color3.fromRGB(30, 20, 50); TBox.TextColor3 = Color3.new(1,1,1); TBox.Font = "GothamBold"; Instance.new("UICorner", TBox)

local function UpdateButtonVisuals(container, currentVal)
    for _, btn in pairs(container:GetChildren()) do if btn:IsA("TextButton") then local isMatch = (btn.Text == currentVal or btn.Text == (currentVal.."H") or (btn.Name == "TypoBtn" and TypoMode)); btn.BackgroundColor3 = isMatch and Color3.fromRGB(255, 40, 100) or Color3.fromRGB(40, 30, 60) end end
end

local function CreateBtn(name, pos, size, parent, func)
    local b = Instance.new("TextButton", parent); b.Text = name; b.Size = size; b.Position = pos; b.BackgroundColor3 = Color3.fromRGB(40, 30, 60); b.TextColor3 = Color3.new(1,1,1); b.Font = "GothamBold"; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6); b.MouseButton1Click:Connect(function() func(b) end); return b
end

-- Filter & Control UI
local FR1 = Instance.new("Frame", Main); FR1.Size = UDim2.new(1, -20, 0, 30); FR1.Position = UDim2.new(0, 10, 0, 55); FR1.BackgroundTransparency = 1; Instance.new("UIListLayout", FR1).FillDirection = "Horizontal"; FR1.UIListLayout.Padding = UDim.new(0, 5)
CreateBtn("Mudah", UDim2.new(0,0,0,0), UDim2.new(0.48,0,1,0), FR1, function() ActiveMode = (ActiveMode == "Mudah" and "Normal" or "Mudah") UpdateButtonVisuals(FR1, ActiveMode) _G.UpdateWords(LastTarget) end)
CreateBtn("Sulit", UDim2.new(0,0,0,0), UDim2.new(0.48,0,1,0), FR1, function() ActiveMode = (ActiveMode == "Sulit" and "Normal" or "Sulit") UpdateButtonVisuals(FR1, ActiveMode) _G.UpdateWords(LastTarget) end)

local FR2 = Instance.new("Frame", Main); FR2.Size = UDim2.new(1, -20, 0, 30); FR2.Position = UDim2.new(0, 10, 0, 90); FR2.BackgroundTransparency = 1; Instance.new("UIListLayout", FR2).FillDirection = "Horizontal"; FR2.UIListLayout.Padding = UDim.new(0, 5)
for _, h in pairs({5,6,7}) do CreateBtn(h.."H", UDim2.new(0,0,0,0), UDim2.new(0.31,0,1,0), FR2, function() LengthFilter = (LengthFilter == h and 0 or h) UpdateButtonVisuals(FR2, tostring(LengthFilter)) _G.UpdateWords(LastTarget) end) end

local AtBtn = CreateBtn("AUTO JAWAB: OFF", UDim2.new(0,10,0,130), UDim2.new(1,-20,0,35), Main, function(b) AutoAnswer = not AutoAnswer; b.Text = "AUTO JAWAB: "..(AutoAnswer and "ON" or "OFF"); b.BackgroundColor3 = AutoAnswer and Color3.fromRGB(255, 40, 100) or Color3.fromRGB(40, 30, 60) end)

-- BUTTON TYPO (BARU)
local TypoBtn = CreateBtn("TYPO MODE: OFF", UDim2.new(0,10,0,170), UDim2.new(1,-20,0,35), Main, function(b) 
    TypoMode = not TypoMode
    b.Text = "TYPO MODE: "..(TypoMode and "ON" or "OFF")
    b.BackgroundColor3 = TypoMode and Color3.fromRGB(255, 150, 0) or Color3.fromRGB(40, 30, 60)
end)
TypoBtn.Name = "TypoBtn"

local SpeedText = Instance.new("TextLabel", Main); SpeedText.Size = UDim2.new(1, 0, 0, 20); SpeedText.Position = UDim2.new(0, 0, 0, 215); SpeedText.Text = "SPEED KETIK: "..BotSpeed; SpeedText.TextColor3 = Color3.new(1,1,1); SpeedText.Font = "GothamBold"; SpeedText.BackgroundTransparency = 1
CreateBtn("-", UDim2.new(0.2, 0, 0, 240), UDim2.new(0, 45, 0, 30), Main, function() BotSpeed = math.max(1, BotSpeed - 1) SpeedText.Text = "SPEED KETIK: "..BotSpeed end)
CreateBtn("+", UDim2.new(0.6, 0, 0, 240), UDim2.new(0, 45, 0, 30), Main, function() BotSpeed = math.min(100, BotSpeed + 1) SpeedText.Text = "SPEED KETIK: "..BotSpeed end)

local Scroll = Instance.new("ScrollingFrame", Main); Scroll.Size = UDim2.new(1, -20, 1, -320); Scroll.Position = UDim2.new(0, 10, 0, 280); Scroll.BackgroundTransparency = 1; Scroll.ScrollBarThickness = 4; Instance.new("UIListLayout", Scroll).Padding = UDim.new(0, 5)

-- ==========================================
-- 4. LOGIC UPDATER
-- ==========================================
_G.UpdateWords = function(target)
    if not target or target == "" then return end
    LastTarget = target:upper(); TBox.Text = "TARGET: "..LastTarget
    for _, v in pairs(Scroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    
    CurrentWordList = {}
    local suffixes = {"ex", "ia", "rba", "ly", "ks", "if"}
    
    for _, w in ipairs(KBBI_DATA) do
        local lowerW = w:lower()
        local foundSuffix = ""
        for _, sfx in pairs(suffixes) do if lowerW:match(sfx.."$") then foundSuffix = sfx:upper() break end end
        local isLastRare = w:sub(-1):match("[FXZQJV]")
        if isLastRare and foundSuffix == "" then foundSuffix = w:sub(-1) end
        local isHard = (foundSuffix ~= "")
        
        if (w:sub(1, #target) == target:upper() and not UsedWords[w]) and (LengthFilter == 0 or #w == LengthFilter) then
            if (ActiveMode == "Normal") or (ActiveMode == "Mudah" and not isHard) or (ActiveMode == "Sulit" and isHard) then
                table.insert(CurrentWordList, {w = w, sfx = foundSuffix, s = (100 - #w) + (isHard and 500 or 0)})
            end
        end
    end
    table.sort(CurrentWordList, function(a, b) return a.s > b.s end)
    
    Scroll.CanvasSize = UDim2.new(0, 0, 0, #CurrentWordList * 35)
    for i=1, math.min(50, #CurrentWordList) do
        local wd = CurrentWordList[i]
        local B = Instance.new("TextButton", Scroll); B.Size = UDim2.new(1, -5, 0, 30); B.BackgroundColor3 = Color3.fromRGB(30, 20, 45); B.TextColor3 = Color3.new(1,1,1); B.Font = "GothamBold"; B.TextSize = 14; B.TextXAlignment = "Left"; Instance.new("UICorner", B)
        if wd.sfx ~= "" then
            B.Text = "  🔴("..wd.sfx..")  " .. wd.w .. "  ❗"
            B.TextColor3 = Color3.fromRGB(255, 80, 80)
        else
            B.Text = "     " .. wd.w
            B.TextColor3 = Color3.fromRGB(0, 255, 150)
        end
        B.MouseButton1Click:Connect(function() SmartSubmit(wd.w) end)
    end
    
    if AutoAnswer and #CurrentWordList > 0 and not IsTyping then 
        task.spawn(function() SmartSubmit(CurrentWordList[1].w) end) 
    end
end

-- ==========================================
-- 5. DETECT LOOP
-- ==========================================
task.spawn(function()
    while true do 
        task.wait(0.2)
        for _, v in pairs(Player.PlayerGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Visible then
                if v.Text:find("Pemenang") or v.Text:find("Eliminasi") or v.Text:find("Match Berakhir") or v.Text:find("Lobby") then
                    if next(UsedWords) ~= nil then UsedWords = {}; LastTarget = ""; TBox.Text = "TARGET: ??" end
                end
                if v.Text:find("Hurufnya adalah") then
                    for _, child in pairs(v.Parent:GetChildren()) do
                        if child:IsA("TextLabel") and child ~= v and child.Visible and #child.Text >= 1 and #child.Text <= 4 then
                            local t = child.Text:gsub("%s+", ""):upper()
                            if t:match("^[A-Z]+$") and t ~= LastTarget then 
                                IsTyping = false 
                                _G.UpdateWords(t)
                            end
                        end
                    end
                end
            end
        end
    end
end)
