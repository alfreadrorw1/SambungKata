local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

-- ==========================================
-- 1. CONFIG & DATABASE
-- ==========================================
local CLOUD_CSV_URL = "https://raw.githubusercontent.com/alfreadrorw1/SambungKata/main/kbbi.csv"
local KBBI_DATA, UsedWords, CurrentWordList = {}, {}, {}
local BotSpeed, LastTarget, AutoAnswer, ActiveMode, LengthFilter = 10, "", false, "Normal", 0
local IsTyping = false
local TypoMode = false
local AutoRetryIndex = 1 -- Index untuk retry auto jawab

local KeyNeighbors = {
    A="S", B="V", C="X", D="F", E="R", F="G", G="H", H="J", I="O", J="K", K="L", L="P",
    M="N", N="B", O="P", P="O", Q="W", R="T", S="D", T="Y", U="I", V="C", W="E", X="Z", Y="U", Z="X"
}

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
local BillboardRemote = Remotes:WaitForChild("BillboardUpdate")
local SubmitRemote = Remotes:WaitForChild("SubmitWord")

-- ==========================================
-- 2. SMART SUBMIT DENGAN RETRY LOGIC
-- ==========================================
local function SmartSubmit(word, onDone)
    if not word or word == "" or IsTyping then
        if onDone then onDone(false) end
        return
    end
    IsTyping = true

    local target = word:upper()
    local charDelay = (1 / math.max(1, BotSpeed)) * 2.7

    task.wait(math.random(5, 10) / 10)

    local currentText = LastTarget:upper()
    local prefixLen = #currentText

    local maxTypos = (#target > 6) and math.random(1, 3) or math.random(1, 2)
    local typoIndices = {}
    if TypoMode then
        for _ = 1, maxTypos do
            table.insert(typoIndices, math.random(prefixLen + 1, #target))
        end
    end

    for i = prefixLen + 1, #target do
        if not IsTyping then break end

        local isTypoTime = false
        for _, idx in pairs(typoIndices) do if idx == i then isTypoTime = true end end

        if TypoMode and isTypoTime then
            local realChar = target:sub(i, i)
            local fakeChar = KeyNeighbors[realChar] or "A"
            currentText = currentText .. fakeChar
            BillboardRemote:FireServer(currentText)
            task.wait(charDelay * 1.5)
            currentText = currentText:sub(1, #currentText - 1)
            BillboardRemote:FireServer(currentText)
            task.wait(charDelay * 0.8)
        end

        currentText = currentText .. target:sub(i, i)
        BillboardRemote:FireServer(currentText)
        task.wait(charDelay)
    end

    task.wait(math.random(2, 4) / 10)
    SubmitRemote:FireServer(target:lower())
    UsedWords[target] = true

    task.wait(0.6)
    IsTyping = false

    if onDone then onDone(true) end
end

-- Auto Jawab dengan Retry otomatis ke kata berikutnya
local function AutoAnswerLoop()
    AutoRetryIndex = 1
    local function tryNext()
        if not AutoAnswer then return end
        if AutoRetryIndex > #CurrentWordList then return end
        
        local wd = CurrentWordList[AutoRetryIndex]
        if not wd then return end

        -- Cek apakah kata sudah dipakai atau invalid
        if UsedWords[wd.w] then
            AutoRetryIndex = AutoRetryIndex + 1
            task.spawn(tryNext)
            return
        end

        SmartSubmit(wd.w, function(success)
            if not success then
                -- Gagal submit (IsTyping conflict), tunggu sebentar dan retry index yang sama
                task.wait(0.5)
                task.spawn(tryNext)
            end
            -- Kalau berhasil, tunggu response game — detect loop akan trigger UpdateWords
            -- yang akan reset AutoRetryIndex via UpdateWords
        end)
    end
    task.spawn(tryNext)
end

-- ==========================================
-- 3. UI SETUP — Compact & Modern
-- ==========================================
if Player.PlayerGui:FindFirstChild("Alfread_V78") then
    Player.PlayerGui.Alfread_V78:Destroy()
end

local SG = Instance.new("ScreenGui", Player.PlayerGui)
SG.Name = "Alfread_V78"
SG.DisplayOrder = 2147483647
SG.ResetOnSpawn = false
SG.IgnoreGuiInset = true

-- Main Panel
local Main = Instance.new("Frame", SG)
Main.Name = "Main"
Main.Size = UDim2.new(0, 220, 0, 480)
Main.Position = UDim2.new(0, 8, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(10, 8, 20)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Visible = true
Main.Active = true
Main.Draggable = true

local MainCorner = Instance.new("UICorner", Main)
MainCorner.CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(200, 30, 80)
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.3

-- Gradient background
local BG = Instance.new("UIGradient", Main)
BG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 12, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 6, 18))
})
BG.Rotation = 135

-- Header Bar
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, 36)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundColor3 = Color3.fromRGB(200, 30, 80)
Header.BorderSizePixel = 0

local HeaderGrad = Instance.new("UIGradient", Header)
HeaderGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 40, 100)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 20, 60))
})
HeaderGrad.Rotation = 90

local HeaderCorner = Instance.new("UICorner", Header)
HeaderCorner.CornerRadius = UDim.new(0, 14)

-- Fix bottom corner of header
local HeaderFix = Instance.new("Frame", Header)
HeaderFix.Size = UDim2.new(1, 0, 0.5, 0)
HeaderFix.Position = UDim2.new(0, 0, 0.5, 0)
HeaderFix.BackgroundColor3 = Color3.fromRGB(255, 40, 100)
HeaderFix.BorderSizePixel = 0

local HeaderLabel = Instance.new("TextLabel", Header)
HeaderLabel.Size = UDim2.new(1, -60, 1, 0)
HeaderLabel.Position = UDim2.new(0, 10, 0, 0)
HeaderLabel.Text = "⚡ ALFREAD V78"
HeaderLabel.TextColor3 = Color3.new(1, 1, 1)
HeaderLabel.Font = Enum.Font.GothamBlack
HeaderLabel.TextSize = 13
HeaderLabel.BackgroundTransparency = 1
HeaderLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize Button
local MinBtn = Instance.new("TextButton", Header)
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -32, 0.5, -14)
MinBtn.Text = "−"
MinBtn.Font = Enum.Font.GothamBlack
MinBtn.TextSize = 18
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextColor3 = Color3.fromRGB(200, 30, 80)
MinBtn.BorderSizePixel = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(1, 0)

local isMinimized = false
local fullHeight = 480
local miniHeight = 36

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    MinBtn.Text = isMinimized and "+" or "−"
    local targetSize = isMinimized and UDim2.new(0, 220, 0, miniHeight) or UDim2.new(0, 220, 0, fullHeight)
    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = targetSize}):Play()
end)

-- Content container
local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, 0, 1, -36)
Content.Position = UDim2.new(0, 0, 0, 36)
Content.BackgroundTransparency = 1

-- Target label
local TBox = Instance.new("TextLabel", Content)
TBox.Size = UDim2.new(1, -16, 0, 28)
TBox.Position = UDim2.new(0, 8, 0, 6)
TBox.Text = "TARGET: ??"
TBox.BackgroundColor3 = Color3.fromRGB(25, 18, 45)
TBox.TextColor3 = Color3.fromRGB(255, 200, 50)
TBox.Font = Enum.Font.GothamBold
TBox.TextSize = 13
TBox.BorderSizePixel = 0
Instance.new("UICorner", TBox).CornerRadius = UDim.new(0, 8)

-- Status label (untuk auto retry info)
local StatusLabel = Instance.new("TextLabel", Content)
StatusLabel.Size = UDim2.new(1, -16, 0, 18)
StatusLabel.Position = UDim2.new(0, 8, 0, 38)
StatusLabel.Text = "● READY"
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(0, 220, 120)
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local function SetStatus(txt, color)
    StatusLabel.Text = txt
    StatusLabel.TextColor3 = color or Color3.fromRGB(0, 220, 120)
end

-- Helper: create small button
local function MakeBtn(parent, txt, x, y, w, h)
    local b = Instance.new("TextButton", parent)
    b.Text = txt
    b.Size = UDim2.new(0, w, 0, h)
    b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(35, 25, 55)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    local stroke = Instance.new("UIStroke", b)
    stroke.Color = Color3.fromRGB(80, 60, 120)
    stroke.Thickness = 1
    return b
end

-- Mode Row (Mudah / Sulit)
local modeLabel = Instance.new("TextLabel", Content)
modeLabel.Size = UDim2.new(1, -16, 0, 16)
modeLabel.Position = UDim2.new(0, 8, 0, 62)
modeLabel.Text = "MODE KATA"
modeLabel.BackgroundTransparency = 1
modeLabel.TextColor3 = Color3.fromRGB(140, 110, 200)
modeLabel.Font = Enum.Font.GothamBold
modeLabel.TextSize = 10
modeLabel.TextXAlignment = Enum.TextXAlignment.Left

local MudahBtn = MakeBtn(Content, "MUDAH", 8, 80, 96, 26)
local SulitBtn = MakeBtn(Content, "SULIT", 112, 80, 96, 26)

local function UpdateModeVisual()
    MudahBtn.BackgroundColor3 = (ActiveMode == "Mudah") and Color3.fromRGB(255, 40, 100) or Color3.fromRGB(35, 25, 55)
    SulitBtn.BackgroundColor3 = (ActiveMode == "Sulit") and Color3.fromRGB(255, 40, 100) or Color3.fromRGB(35, 25, 55)
end

MudahBtn.MouseButton1Click:Connect(function()
    ActiveMode = (ActiveMode == "Mudah" and "Normal" or "Mudah")
    UpdateModeVisual()
    _G.UpdateWords(LastTarget)
end)
SulitBtn.MouseButton1Click:Connect(function()
    ActiveMode = (ActiveMode == "Sulit" and "Normal" or "Sulit")
    UpdateModeVisual()
    _G.UpdateWords(LastTarget)
end)

-- Length Filter Row
local lenLabel = Instance.new("TextLabel", Content)
lenLabel.Size = UDim2.new(1, -16, 0, 16)
lenLabel.Position = UDim2.new(0, 8, 0, 112)
lenLabel.Text = "FILTER PANJANG"
lenLabel.BackgroundTransparency = 1
lenLabel.TextColor3 = Color3.fromRGB(140, 110, 200)
lenLabel.Font = Enum.Font.GothamBold
lenLabel.TextSize = 10
lenLabel.TextXAlignment = Enum.TextXAlignment.Left

local LenBtns = {}
for i, h in ipairs({5, 6, 7}) do
    local b = MakeBtn(Content, h.."H", 8 + (i-1)*68, 130, 60, 26)
    LenBtns[h] = b
    b.MouseButton1Click:Connect(function()
        LengthFilter = (LengthFilter == h and 0 or h)
        for k, btn in pairs(LenBtns) do
            btn.BackgroundColor3 = (LengthFilter == k) and Color3.fromRGB(255, 40, 100) or Color3.fromRGB(35, 25, 55)
        end
        _G.UpdateWords(LastTarget)
    end)
end

-- Auto Jawab Button
local AtBtn = MakeBtn(Content, "AUTO JAWAB: OFF", 8, 162, 204, 30)
AtBtn.TextSize = 13
AtBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 55)

AtBtn.MouseButton1Click:Connect(function()
    AutoAnswer = not AutoAnswer
    AtBtn.Text = "AUTO JAWAB: " .. (AutoAnswer and "ON ✓" or "OFF")
    AtBtn.BackgroundColor3 = AutoAnswer and Color3.fromRGB(255, 40, 100) or Color3.fromRGB(35, 25, 55)
    if AutoAnswer and #CurrentWordList > 0 and not IsTyping then
        AutoAnswerLoop()
    end
end)

-- Typo Mode Button
local TypoBtn = MakeBtn(Content, "TYPO MODE: OFF", 8, 197, 204, 30)
TypoBtn.TextSize = 13

TypoBtn.MouseButton1Click:Connect(function()
    TypoMode = not TypoMode
    TypoBtn.Text = "TYPO MODE: " .. (TypoMode and "ON ✓" or "OFF")
    TypoBtn.BackgroundColor3 = TypoMode and Color3.fromRGB(220, 140, 0) or Color3.fromRGB(35, 25, 55)
end)

-- Speed Row
local SpeedLabel = Instance.new("TextLabel", Content)
SpeedLabel.Size = UDim2.new(1, -16, 0, 16)
SpeedLabel.Position = UDim2.new(0, 8, 0, 233)
SpeedLabel.Text = "SPEED: " .. BotSpeed
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.TextColor3 = Color3.fromRGB(140, 110, 200)
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextSize = 10
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left

local SpeedBar = Instance.new("Frame", Content)
SpeedBar.Size = UDim2.new(1, -16, 0, 6)
SpeedBar.Position = UDim2.new(0, 8, 0, 252)
SpeedBar.BackgroundColor3 = Color3.fromRGB(35, 25, 55)
SpeedBar.BorderSizePixel = 0
Instance.new("UICorner", SpeedBar).CornerRadius = UDim.new(1, 0)

local SpeedFill = Instance.new("Frame", SpeedBar)
SpeedFill.Size = UDim2.new(BotSpeed / 100, 0, 1, 0)
SpeedFill.BackgroundColor3 = Color3.fromRGB(255, 40, 100)
SpeedFill.BorderSizePixel = 0
Instance.new("UICorner", SpeedFill).CornerRadius = UDim.new(1, 0)

local SpeedMinus = MakeBtn(Content, "◀", 8, 262, 40, 24)
local SpeedPlus = MakeBtn(Content, "▶", 168, 262, 40, 24)

local function UpdateSpeed()
    SpeedLabel.Text = "SPEED: " .. BotSpeed
    TweenService:Create(SpeedFill, TweenInfo.new(0.2), {Size = UDim2.new(BotSpeed / 100, 0, 1, 0)}):Play()
end

SpeedMinus.MouseButton1Click:Connect(function()
    BotSpeed = math.max(1, BotSpeed - 1)
    UpdateSpeed()
end)
SpeedPlus.MouseButton1Click:Connect(function()
    BotSpeed = math.min(100, BotSpeed + 1)
    UpdateSpeed()
end)

-- Word Count label
local WordCount = Instance.new("TextLabel", Content)
WordCount.Size = UDim2.new(1, -16, 0, 16)
WordCount.Position = UDim2.new(0, 8, 0, 292)
WordCount.Text = "KATA DITEMUKAN: 0"
WordCount.BackgroundTransparency = 1
WordCount.TextColor3 = Color3.fromRGB(140, 110, 200)
WordCount.Font = Enum.Font.GothamBold
WordCount.TextSize = 10
WordCount.TextXAlignment = Enum.TextXAlignment.Left

-- Scroll list
local Scroll = Instance.new("ScrollingFrame", Content)
Scroll.Size = UDim2.new(1, -16, 0, 118)
Scroll.Position = UDim2.new(0, 8, 0, 310)
Scroll.BackgroundColor3 = Color3.fromRGB(15, 10, 28)
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(200, 30, 80)
Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 8)

local ScrollLayout = Instance.new("UIListLayout", Scroll)
ScrollLayout.Padding = UDim.new(0, 3)

local ScrollPad = Instance.new("UIPadding", Scroll)
ScrollPad.PaddingLeft = UDim.new(0, 4)
ScrollPad.PaddingRight = UDim.new(0, 4)
ScrollPad.PaddingTop = UDim.new(0, 4)

-- ==========================================
-- 4. LOGIC UPDATER
-- ==========================================
_G.UpdateWords = function(target)
    if not target or target == "" then return end
    LastTarget = target:upper()
    TBox.Text = "TARGET: " .. LastTarget
    AutoRetryIndex = 1  -- ← RESET retry index setiap target baru

    for _, v in pairs(Scroll:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end

    CurrentWordList = {}
    local suffixes = {"ex", "ia", "rba", "ly", "ks", "if"}

    for _, w in ipairs(KBBI_DATA) do
        local lowerW = w:lower()
        local foundSuffix = ""
        for _, sfx in pairs(suffixes) do
            if lowerW:match(sfx .. "$") then foundSuffix = sfx:upper() break end
        end
        local isLastRare = w:sub(-1):match("[FXZQJV]")
        if isLastRare and foundSuffix == "" then foundSuffix = w:sub(-1) end
        local isHard = (foundSuffix ~= "")

        if (w:sub(1, #target) == target:upper() and not UsedWords[w]) and
           (LengthFilter == 0 or #w == LengthFilter) then
            if (ActiveMode == "Normal") or
               (ActiveMode == "Mudah" and not isHard) or
               (ActiveMode == "Sulit" and isHard) then
                table.insert(CurrentWordList, {
                    w = w,
                    sfx = foundSuffix,
                    s = (100 - #w) + (isHard and 500 or 0)
                })
            end
        end
    end

    table.sort(CurrentWordList, function(a, b) return a.s > b.s end)

    WordCount.Text = "KATA DITEMUKAN: " .. #CurrentWordList
    Scroll.CanvasSize = UDim2.new(0, 0, 0, #CurrentWordList * 30 + 8)

    for i = 1, math.min(60, #CurrentWordList) do
        local wd = CurrentWordList[i]
        local B = Instance.new("TextButton", Scroll)
        B.Size = UDim2.new(1, 0, 0, 26)
        B.BackgroundColor3 = Color3.fromRGB(22, 15, 40)
        B.TextColor3 = Color3.new(1, 1, 1)
        B.Font = Enum.Font.GothamBold
        B.TextSize = 12
        B.TextXAlignment = Enum.TextXAlignment.Left
        B.BorderSizePixel = 0
        Instance.new("UICorner", B).CornerRadius = UDim.new(0, 6)

        if wd.sfx ~= "" then
            B.Text = "  🔴 [" .. wd.sfx .. "] " .. wd.w
            B.TextColor3 = Color3.fromRGB(255, 100, 100)
        else
            B.Text = "  ✦ " .. wd.w
            B.TextColor3 = Color3.fromRGB(0, 230, 140)
        end

        B.MouseButton1Click:Connect(function()
            SetStatus("⏳ MENGETIK: " .. wd.w, Color3.fromRGB(255, 200, 50))
            SmartSubmit(wd.w, function()
                SetStatus("● READY", Color3.fromRGB(0, 220, 120))
            end)
        end)
    end

    -- Auto jawab: mulai loop dari awal
    if AutoAnswer and #CurrentWordList > 0 and not IsTyping then
        AutoAnswerLoop()
    end
end

-- ==========================================
-- 5. AUTO RETRY — Deteksi kata ditolak/salah
-- ==========================================
-- Detect jika submit gagal (kata tidak valid) → lanjut ke kata berikutnya
local function WatchForReject()
    -- Monitor: jika IsTyping sudah false tapi AutoAnswer masih on
    -- dan ada sisa kata, lanjut otomatis
    task.spawn(function()
        while true do
            task.wait(1.2)
            if AutoAnswer and not IsTyping and #CurrentWordList > 0 then
                -- Cek apakah kata terakhir yang dicoba sudah masuk UsedWords
                -- Kalau belum ada yang masuk padahal sudah submit, berarti ditolak
                -- → naikkan index dan coba lagi
                if AutoRetryIndex <= #CurrentWordList then
                    local wd = CurrentWordList[AutoRetryIndex]
                    if wd and UsedWords[wd.w] then
                        -- Kata berhasil, tunggu trigger dari game (UpdateWords akan reset)
                    elseif wd and not UsedWords[wd.w] then
                        -- Kata gagal/ditolak, coba berikutnya
                        AutoRetryIndex = AutoRetryIndex + 1
                        if AutoRetryIndex <= #CurrentWordList then
                            local next = CurrentWordList[AutoRetryIndex]
                            if next and not UsedWords[next.w] then
                                SetStatus("🔄 RETRY: " .. next.w, Color3.fromRGB(255, 160, 0))
                                SmartSubmit(next.w, function()
                                    SetStatus("● READY", Color3.fromRGB(0, 220, 120))
                                end)
                            end
                        end
                    end
                end
            end
        end
    end)
end

WatchForReject()

-- ==========================================
-- 6. DETECT LOOP
-- ==========================================
task.spawn(function()
    while true do
        task.wait(0.2)
        for _, v in pairs(Player.PlayerGui:GetDescendants()) do
            if v:IsA("TextLabel") and v.Visible then
                if v.Text:find("Pemenang") or v.Text:find("Eliminasi") or
                   v.Text:find("Match Berakhir") or v.Text:find("Lobby") then
                    if next(UsedWords) ~= nil then
                        UsedWords = {}
                        LastTarget = ""
                        TBox.Text = "TARGET: ??"
                        AutoRetryIndex = 1
                        SetStatus("● READY", Color3.fromRGB(0, 220, 120))
                    end
                end
                if v.Text:find("Hurufnya adalah") then
                    for _, child in pairs(v.Parent:GetChildren()) do
                        if child:IsA("TextLabel") and child ~= v and child.Visible
                           and #child.Text >= 1 and #child.Text <= 4 then
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
