local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- =========================
-- HỆ THỐNG WHITELIST & BẢO VỆ
-- =========================
local AllowedUsers = {
    ["HTGMx_tuber97ne"] = true,
    ["NLE_LUKAKU"] = true
}

if not AllowedUsers[LocalPlayer.Name] then
    LocalPlayer:Kick("Bạn không có quyền sử dụng Script này! Script được sở hữu bởi HTGMx_tuber97ne.")
    return 
end

-- =========================
-- SETTINGS & STATES
-- =========================
local ProtectedPlayers = {}
local SpeedEnabled = false
local CustomSpeed = 16
local InfiniteJump = false
local TargetFollow1 = nil 
local TargetFollow2 = nil 
local AutoClickEnabled = false
local AutoBlockEnabled = false
local NoclipEnabled = false
local AutoKatanaEnabled = false
local HitboxEnabled = false
local HBS = 28 
local OriginalHitboxSizes = {} 

local IsTelePro = false
local TeleProTarget = nil
local OX, OY, OZ = 0, 10, 0 

local IsTelePro2 = false
local TelePro2Target = nil
local Angle2 = 0 

local IsTelePro3 = false
local TelePro3Target = nil
local Angle3 = 0

local IsChonTele = false
local ChonTeleTarget = nil
local SelectedPosition = "dau" 

local IsTeleLoan = false
local TeleLoanTarget = nil
local TeleLoanAngle = 0

local AdminUnlocked = false

local CombatRemote = ReplicatedStorage:WaitForChild("CombatRemote")
local EquippingRemote = ReplicatedStorage:WaitForChild("EquippingRemote")

local function SayInChat(message)
    pcall(function()
        local TextChatService = game:GetService("TextChatService")
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then channel:SendAsync(message) end
        else
            ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest"):FireServer(message, "All")
        end
    end)
end

-- Khởi động chat
task.spawn(function()
    task.wait(0.5)
    SayInChat("luka hub!!")
end)

local function Notification(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 3 })
    end)
end

local function RestoreAllHitboxes()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            local orig = OriginalHitboxSizes[p.Name]
            if orig then
                hrp.Size = orig.Size; hrp.Transparency = orig.Transparency; hrp.CanCollide = orig.CanCollide
            end
        end
    end
    OriginalHitboxSizes = {}
end

-- =========================
-- HỆ THỐNG GUI (ĐẸP HƠN & TABS)
-- =========================
local sg = Instance.new("ScreenGui")
sg.Name = "LukaHubGui"
sg.ResetOnSpawn = false

local success, _ = pcall(function() sg.Parent = game:GetService("CoreGui") end)
if not success then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- NÚT TRÒN MỞ/ĐÓNG GUI
local toggleBtn = Instance.new("TextButton", sg)
toggleBtn.Size = UDim2.new(0, 50, 0, 50)
toggleBtn.Position = UDim2.new(0, 15, 0.5, -25)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
toggleBtn.Text = "LUKA"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
toggleBtn.TextSize = 14
local toggleCorner = Instance.new("UICorner", toggleBtn)
toggleCorner.CornerRadius = UDim.new(1, 0) -- Làm tròn hoàn toàn

-- KHUNG CHÍNH
local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, 480, 0, 270)
frame.Position = UDim2.new(0.5, -240, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Visible = false -- Mặc định ẩn
local frameCorner = Instance.new("UICorner", frame)
frameCorner.CornerRadius = UDim.new(0, 10)

toggleBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

-- Header kéo thả
local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1, 0, 0, 35)
header.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
header.BorderSizePixel = 0

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "LUKA HUB PREMIUM"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16

local dragging, dragInput, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = frame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Thanh Menu chuyển Tab
local menuBar = Instance.new("Frame", frame)
menuBar.Size = UDim2.new(1, 0, 0, 30)
menuBar.Position = UDim2.new(0, 0, 0, 35)
menuBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
menuBar.BorderSizePixel = 0

local btnHome = Instance.new("TextButton", menuBar)
btnHome.Size = UDim2.new(0.33, 0, 1, 0); btnHome.Position = UDim2.new(0, 0, 0, 0)
btnHome.Text = "Lệnh Chat"; btnHome.BackgroundTransparency = 1; btnHome.TextColor3 = Color3.fromRGB(255,255,255); btnHome.Font = Enum.Font.GothamBold

local btnTheme = Instance.new("TextButton", menuBar)
btnTheme.Size = UDim2.new(0.33, 0, 1, 0); btnTheme.Position = UDim2.new(0.33, 0, 0, 0)
btnTheme.Text = "Đổi Màu"; btnTheme.BackgroundTransparency = 1; btnTheme.TextColor3 = Color3.fromRGB(150,150,150); btnTheme.Font = Enum.Font.GothamBold

local btnAdmin = Instance.new("TextButton", menuBar)
btnAdmin.Size = UDim2.new(0.34, 0, 1, 0); btnAdmin.Position = UDim2.new(0.66, 0, 0, 0)
btnAdmin.Text = "Admin Code"; btnAdmin.BackgroundTransparency = 1; btnAdmin.TextColor3 = Color3.fromRGB(150,150,150); btnAdmin.Font = Enum.Font.GothamBold

-- Các Container Tabs
local tabHome = Instance.new("Frame", frame)
tabHome.Size = UDim2.new(1, 0, 1, -65); tabHome.Position = UDim2.new(0, 0, 0, 65)
tabHome.BackgroundTransparency = 1; tabHome.Visible = true

local tabTheme = Instance.new("Frame", frame)
tabTheme.Size = UDim2.new(1, 0, 1, -65); tabTheme.Position = UDim2.new(0, 0, 0, 65)
tabTheme.BackgroundTransparency = 1; tabTheme.Visible = false

local tabAdmin = Instance.new("Frame", frame)
tabAdmin.Size = UDim2.new(1, 0, 1, -65); tabAdmin.Position = UDim2.new(0, 0, 0, 65)
tabAdmin.BackgroundTransparency = 1; tabAdmin.Visible = false

-- Chuyển Tab Logic
local function SwitchTab(tab)
    tabHome.Visible = (tab == "Home")
    tabTheme.Visible = (tab == "Theme")
    tabAdmin.Visible = (tab == "Admin")
    btnHome.TextColor3 = (tab == "Home") and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,150)
    btnTheme.TextColor3 = (tab == "Theme") and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,150)
    btnAdmin.TextColor3 = (tab == "Admin") and Color3.fromRGB(255,255,255) or Color3.fromRGB(150,150,150)
end
btnHome.MouseButton1Click:Connect(function() SwitchTab("Home") end)
btnTheme.MouseButton1Click:Connect(function() SwitchTab("Theme") end)
btnAdmin.MouseButton1Click:Connect(function() SwitchTab("Admin") end)

-- === NỘI DUNG TAB HOME ===
local avatarImg = Instance.new("ImageLabel", tabHome)
avatarImg.Size = UDim2.new(0, 70, 0, 70); avatarImg.Position = UDim2.new(0.03, 0, 0.05, 0)
avatarImg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
local avtCorner = Instance.new("UICorner", avatarImg); avtCorner.CornerRadius = UDim.new(1,0)
task.spawn(function()
    local content, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    if isReady then avatarImg.Image = content end
end)

local nameLabel = Instance.new("TextLabel", tabHome)
nameLabel.Size = UDim2.new(0, 120, 0, 20); nameLabel.Position = UDim2.new(0.01, 0, 0.45, 0)
nameLabel.BackgroundTransparency = 1; nameLabel.Text = LocalPlayer.DisplayName
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255); nameLabel.Font = Enum.Font.GothamBold

local btnOffHack = Instance.new("TextButton", tabHome)
btnOffHack.Size = UDim2.new(0.2, 0, 0.2, 0); btnOffHack.Position = UDim2.new(0.03, 0, 0.65, 0)
btnOffHack.BackgroundColor3 = Color3.fromRGB(200, 50, 50); btnOffHack.Text = "TẮT HACK"
btnOffHack.TextColor3 = Color3.fromRGB(255, 255, 255); btnOffHack.Font = Enum.Font.GothamBold
local offCorner = Instance.new("UICorner", btnOffHack); offCorner.CornerRadius = UDim.new(0, 5)

-- Nút Tắt Hack (Không Kick)
btnOffHack.MouseButton1Click:Connect(function()
    SpeedEnabled = false
    InfiniteJump = false
    TargetFollow1 = nil 
    TargetFollow2 = nil 
    AutoClickEnabled = false
    AutoBlockEnabled = false
    NoclipEnabled = false
    AutoKatanaEnabled = false
    HitboxEnabled = false
    RestoreAllHitboxes()
    IsTelePro = false; IsTelePro2 = false; IsTelePro3 = false; IsChonTele = false; IsTeleLoan = false
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
    sg:Destroy()
    Notification("LUKA HUB", "Đã tắt toàn bộ chức năng!")
end)

local scrollFrame = Instance.new("ScrollingFrame", tabHome)
scrollFrame.Size = UDim2.new(0.7, 0, 0.9, 0); scrollFrame.Position = UDim2.new(0.28, 0, 0.05, 0)
scrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30); scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4; scrollFrame.CanvasSize = UDim2.new(0, 0, 1.8, 0)
local scrollCorner = Instance.new("UICorner", scrollFrame); scrollCorner.CornerRadius = UDim.new(0, 5)

local cmdList = Instance.new("TextLabel", scrollFrame)
cmdList.Size = UDim2.new(1, -10, 1, 0); cmdList.Position = UDim2.new(0, 5, 0, 0)
cmdList.BackgroundTransparency = 1; cmdList.TextXAlignment = Enum.TextXAlignment.Left; cmdList.TextYAlignment = Enum.TextYAlignment.Top
cmdList.TextColor3 = Color3.fromRGB(200, 200, 200); cmdList.Font = Enum.Font.Code; cmdList.TextSize = 13
cmdList.Text = [[
DANH SÁCH LỆNH (;luka ...)
[Thêm 'un' trước lệnh để TẮT]

1. DỊCH CHUYỂN BÁM (TELEPORT):
- telepro3 [tên]: Tele xoay 4 hướng Đông Tây Nam Bắc quanh địch (Mới)
- teleloan [tên]: Tele loạn quanh địch (Speed 100)
- telepro2 [tên]: Tele xoay tròn đều TRÊN ĐẦU
- chontele [tên]: Tele ghim theo góc cố định
- vitri [dau/duoi/sau]: Đổi góc chontele
- telepro [tên]: Tele ghim lệch tọa độ
- offset [x] [y] [z]: Chỉnh tọa độ lệch
- bmang [tên]: Bám lưng
- bam2 [tên]: Bám thẳng trên đầu 8 studs

2. CHIẾN ĐẤU (COMBAT):
- hitbox [cỡ]: Phóng to hitbox (Mặc định 28)
- ad: Bật Auto Click M1/M2
- block: Auto Đỡ đòn
- katana: Auto rút kiếm

3. TIỆN ÍCH & BẢO VỆ:
- bv [tên]: Đưa vào Whitelist
- sp [số]: Chỉnh tốc độ chạy
- infjump: Nhảy vô hạn
- noclip: Xuyên tường
]]

-- === NỘI DUNG TAB THEME (ĐỔI MÀU) ===
local function CreateColorButton(color, pos, name)
    local btn = Instance.new("TextButton", tabTheme)
    btn.Size = UDim2.new(0.25, 0, 0.25, 0); btn.Position = pos
    btn.BackgroundColor3 = color; btn.Text = name; btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.fromRGB(255,255,255)
    local corner = Instance.new("UICorner", btn); corner.CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(function()
        header.BackgroundColor3 = color
        toggleBtn.BackgroundColor3 = color
    end)
end
CreateColorButton(Color3.fromRGB(200, 50, 50), UDim2.new(0.1, 0, 0.1, 0), "Đỏ")
CreateColorButton(Color3.fromRGB(220, 180, 40), UDim2.new(0.4, 0, 0.1, 0), "Vàng")
CreateColorButton(Color3.fromRGB(0, 200, 100), UDim2.new(0.7, 0, 0.1, 0), "Xanh Lá")
CreateColorButton(Color3.fromRGB(50, 100, 220), UDim2.new(0.25, 0, 0.45, 0), "Xanh Dương")
CreateColorButton(Color3.fromRGB(150, 50, 200), UDim2.new(0.55, 0, 0.45, 0), "Tím")

-- === NỘI DUNG TAB ADMIN ===
local adminTitle = Instance.new("TextLabel", tabAdmin)
adminTitle.Size = UDim2.new(1, 0, 0.2, 0); adminTitle.Position = UDim2.new(0, 0, 0.1, 0)
adminTitle.BackgroundTransparency = 1; adminTitle.Text = "NHẬP CODE ADMIN ĐỂ KÍCH HOẠT"
adminTitle.TextColor3 = Color3.fromRGB(255,255,255); adminTitle.Font = Enum.Font.GothamBold; adminTitle.TextSize = 16

local codeInput = Instance.new("TextBox", tabAdmin)
codeInput.Size = UDim2.new(0.6, 0, 0.25, 0); codeInput.Position = UDim2.new(0.2, 0, 0.4, 0)
codeInput.BackgroundColor3 = Color3.fromRGB(40,40,45); codeInput.TextColor3 = Color3.fromRGB(255,255,255)
codeInput.PlaceholderText = "Nhập code tại đây..."
codeInput.Font = Enum.Font.Gotham; codeInput.TextSize = 14
local inputCorner = Instance.new("UICorner", codeInput); inputCorner.CornerRadius = UDim.new(0, 5)

local btnSubmitCode = Instance.new("TextButton", tabAdmin)
btnSubmitCode.Size = UDim2.new(0.3, 0, 0.2, 0); btnSubmitCode.Position = UDim2.new(0.35, 0, 0.75, 0)
btnSubmitCode.BackgroundColor3 = Color3.fromRGB(0, 150, 255); btnSubmitCode.Text = "XÁC NHẬN"
btnSubmitCode.TextColor3 = Color3.fromRGB(255,255,255); btnSubmitCode.Font = Enum.Font.GothamBold
local submitCorner = Instance.new("UICorner", btnSubmitCode); submitCorner.CornerRadius = UDim.new(0, 5)

btnSubmitCode.MouseButton1Click:Connect(function()
    if codeInput.Text == "Luka+Toji" then
        AdminUnlocked = true
        Notification("ADMIN", "Mở khóa thành công!")
        SayInChat("Luka bypass!!")
    else
        Notification("LỖI", "Code không hợp lệ!")
    end
end)

-- =========================
-- BV SYSTEM (Chống Target)
-- =========================
local gmt = getrawmetatable(game)
setreadonly(gmt, false)
local oldNamecall = gmt.__namecall

gmt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if method == "FireServer" or method == "InvokeServer" then
        for _, p in pairs(ProtectedPlayers) do
            if p and p.Character then
                for _, arg in pairs(args) do
                    if arg == p or arg == p.Character or (type(arg) == "table" and rawget(arg, "Instance") == p.Character) then
                        return nil
                    end
                end
            end
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(gmt, true)

-- =========================
-- VÒNG LẶP DI CHUYỂN VÀ VẬT LÝ
-- =========================
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end

    if SpeedEnabled and humanoid.WalkSpeed ~= CustomSpeed then
        humanoid.WalkSpeed = CustomSpeed
    end

    if NoclipEnabled or IsTelePro or IsTelePro2 or IsTelePro3 or IsChonTele or IsTeleLoan then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    if TargetFollow1 and TargetFollow1.Character then
        local enemyRoot = TargetFollow1.Character:FindFirstChild("HumanoidRootPart")
        if enemyRoot then root.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, 3.5) end
    end

    if TargetFollow2 and TargetFollow2.Character then
        local enemyRoot = TargetFollow2.Character:FindFirstChild("HumanoidRootPart")
        if enemyRoot then root.CFrame = enemyRoot.CFrame * CFrame.new(0, 8, 0) * CFrame.Angles(math.rad(-90), 0, 0) end
    end

    -- TELE PRO
    if IsTelePro and TeleProTarget and TeleProTarget.Character and TeleProTarget.Character:FindFirstChild("HumanoidRootPart") then
        local thrp = TeleProTarget.Character.HumanoidRootPart
        local tp = thrp.CFrame * CFrame.new(OX, OY, OZ)
        local dir = tp.Position - root.Position; local dist = dir.Magnitude
        if dist > 20 then root.Velocity = dir.Unit * 200 else root.CFrame = tp; root.Velocity = Vector3.zero end
    end

    -- TELE PRO 2 (Tròn Trên Đầu)
    if IsTelePro2 and TelePro2Target and TelePro2Target.Character and TelePro2Target.Character:FindFirstChild("HumanoidRootPart") then
        local thrp = TelePro2Target.Character.HumanoidRootPart
        Angle2 = Angle2 + 0.05 
        local rotateX = math.cos(Angle2) * (OX ~= 0 and OX or 5) 
        local rotateZ = math.sin(Angle2) * (OZ ~= 0 and OZ or 5) 
        local tp = thrp.CFrame * CFrame.new(rotateX, OY, rotateZ)
        local dir = tp.Position - root.Position; local dist = dir.Magnitude
        if dist > 20 then root.Velocity = dir.Unit * 200 else root.CFrame = tp; root.Velocity = Vector3.zero end
    end

    -- TELE PRO 3 (4 Hướng Quanh Người - Đông Tây Nam Bắc)
    if IsTelePro3 and TelePro3Target and TelePro3Target.Character and TelePro3Target.Character:FindFirstChild("HumanoidRootPart") then
        local thrp = TelePro3Target.Character.HumanoidRootPart
        Angle3 = Angle3 + 0.05 
        local radius = (OX ~= 0 and OX or 6)
        -- Sử dụng độ cao 0 hoặc lệch nhẹ, không ở trên đầu
        local targetY = (OY == 10 and 0 or OY) 
        local rotateX = math.cos(Angle3) * radius
        local rotateZ = math.sin(Angle3) * radius
        
        local tp = thrp.CFrame * CFrame.new(rotateX, targetY, rotateZ)
        local dir = tp.Position - root.Position; local dist = dir.Magnitude
        if dist > 20 then root.Velocity = dir.Unit * 200 else root.CFrame = tp; root.Velocity = Vector3.zero end
    end

    -- CHỌN TELE
    if IsChonTele and ChonTeleTarget and ChonTeleTarget.Character and ChonTeleTarget.Character:FindFirstChild("HumanoidRootPart") then
        local thrp = ChonTeleTarget.Character.HumanoidRootPart
        local tp
        if SelectedPosition == "dau" then tp = thrp.CFrame * CFrame.new(OX, OY, OZ) 
        elseif SelectedPosition == "duoi" then tp = thrp.CFrame * CFrame.new(OX, -3.5 + OY, OZ) 
        elseif SelectedPosition == "sau" then tp = thrp.CFrame * CFrame.new(OX, OY, 3.5 + OZ) end
        
        local dir = tp.Position - root.Position; local dist = dir.Magnitude
        if dist > 20 then root.Velocity = dir.Unit * 200 else root.CFrame = tp; root.Velocity = Vector3.zero end
    end

    -- TELE LOẠN
    if IsTeleLoan and TeleLoanTarget and TeleLoanTarget.Character and TeleLoanTarget.Character:FindFirstChild("HumanoidRootPart") then
        local thrp = TeleLoanTarget.Character.HumanoidRootPart
        TeleLoanAngle = TeleLoanAngle + (100 * 0.01)
        local targetRadius = 8
        local lx = math.sin(TeleLoanAngle) * targetRadius + OX
        local ly = math.cos(TeleLoanAngle * 1.5) * targetRadius + OY 
        local lz = math.cos(TeleLoanAngle) * math.sin(TeleLoanAngle * 0.5) * targetRadius + OZ
        
        local tp = thrp.CFrame * CFrame.new(lx, ly, lz)
        local dir = tp.Position - root.Position; local dist = dir.Magnitude
        if dist > 20 then root.Velocity = dir.Unit * 200 else root.CFrame = tp; root.Velocity = Vector3.zero end
    end
end)

-- =========================
-- HITBOX VÀ AUTO
-- =========================
RunService.RenderStepped:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            local isProtected = table.find(ProtectedPlayers, p) ~= nil

            if HitboxEnabled and not isProtected then
                if not OriginalHitboxSizes[p.Name] then
                    OriginalHitboxSizes[p.Name] = { Size = hrp.Size, Transparency = hrp.Transparency, CanCollide = hrp.CanCollide }
                end
                hrp.Size = Vector3.new(HBS, HBS, HBS); hrp.Transparency = 0.7; hrp.CanCollide = false
            else
                local orig = OriginalHitboxSizes[p.Name]
                if orig then
                    hrp.Size = orig.Size; hrp.Transparency = orig.Transparency; hrp.CanCollide = orig.CanCollide
                else
                    hrp.Size = Vector3.new(2, 2, 1); hrp.Transparency = 1; hrp.CanCollide = true
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        if AutoClickEnabled then pcall(function() CombatRemote:FireServer("M1"); task.wait(0.1); CombatRemote:FireServer("M2") end) end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if AutoBlockEnabled then pcall(function() CombatRemote:FireServer("Block") end) end
        task.wait(0.2)
    end
end)

task.spawn(function()
    while true do
        if AutoKatanaEnabled then pcall(function() EquippingRemote:FireServer("Katana") end) end
        task.wait(0.5)
    end
end)

UserInputService.JumpRequest:Connect(function()
    if not InfiniteJump then return end
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- =========================
-- CHAT COMMANDS
-- =========================
LocalPlayer.Chatted:Connect(function(msg)
    local args = msg:split(" ")

    if args[1]:lower() == ";luka" then
        local cmd = args[2] and args[2]:lower()
        local val = args[3]

        if cmd == "bv" and val then
            for _, p in pairs(Players:GetPlayers()) do
                if p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower()) then
                    if not table.find(ProtectedPlayers, p) then
                        table.insert(ProtectedPlayers, p)
                        Notification("WHITELIST", "Added: " .. p.DisplayName)
                    end
                    break
                end
            end
        elseif cmd == "unbv" and val then
            for i, p in pairs(ProtectedPlayers) do
                if p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower()) then
                    table.remove(ProtectedPlayers, i); Notification("WHITELIST", "Removed: " .. p.DisplayName)
                    break
                end
            end
        elseif cmd == "sp" and val then
            local speed = tonumber(val); if speed then SpeedEnabled = true; CustomSpeed = speed; Notification("SPEED", "WalkSpeed = " .. speed) end
        elseif cmd == "unsp" then
            SpeedEnabled = false
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 end
            Notification("SPEED", "WalkSpeed disabled")
        elseif cmd == "infjump" then InfiniteJump = true; Notification("JUMP", "Infinite Jump Enabled")
        elseif cmd == "uninfjump" then InfiniteJump = false
        elseif cmd == "bmang" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TargetFollow1 = p; TargetFollow2 = nil; IsTelePro = false; IsTelePro2 = false; IsTelePro3 = false; IsChonTele = false; IsTeleLoan = false; found = true
                    Notification("FOLLOW", "Bám sau lưng: " .. p.DisplayName)
                    break
                end
            end
        elseif cmd == "unbmang" then TargetFollow1 = nil
        elseif cmd == "bam2" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TargetFollow2 = p; TargetFollow1 = nil; IsTelePro = false; IsTelePro2 = false; IsTelePro3 = false; IsChonTele = false; IsTeleLoan = false; found = true
                    Notification("FOLLOW", "Bám trên đầu: " .. p.DisplayName)
                    break
                end
            end
        elseif cmd == "unbam2" then TargetFollow2 = nil
        elseif cmd == "telepro" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TeleProTarget = p; IsTelePro = true; TargetFollow1 = nil; TargetFollow2 = nil; IsTelePro2 = false; IsTelePro3 = false; IsChonTele = false; IsTeleLoan = false; found = true
                    Notification("TELE PRO", "Bắt đầu Tele Pro tới: " .. p.DisplayName)
                    break
                end
            end
        elseif cmd == "untelepro" then IsTelePro = false; TeleProTarget = nil
        elseif cmd == "telepro2" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TelePro2Target = p; IsTelePro2 = true; IsTelePro = false; IsTelePro3 = false; TargetFollow1 = nil; TargetFollow2 = nil; IsChonTele = false; IsTeleLoan = false; Angle2 = 0; found = true
                    Notification("TELE PRO 2", "Xoay trên đầu: " .. p.DisplayName)
                    break
                end
            end
        elseif cmd == "untelepro2" then IsTelePro2 = false; TelePro2Target = nil
        elseif cmd == "telepro3" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TelePro3Target = p; IsTelePro3 = true; IsTelePro2 = false; IsTelePro = false; TargetFollow1 = nil; TargetFollow2 = nil; IsChonTele = false; IsTeleLoan = false; Angle3 = 0; found = true
                    Notification("TELE PRO 3", "Xoay quanh người: " .. p.DisplayName)
                    break
                end
            end
        elseif cmd == "untelepro3" then IsTelePro3 = false; TelePro3Target = nil
        elseif cmd == "chontele" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    ChonTeleTarget = p; IsChonTele = true; IsTelePro = false; IsTelePro2 = false; IsTelePro3 = false; TargetFollow1 = nil; TargetFollow2 = nil; IsTeleLoan = false; found = true
                    Notification("CHỌN TELE", "Đang tele tới: " .. p.DisplayName .. " (" .. SelectedPosition:upper() .. ")")
                    break
                end
            end
        elseif cmd == "unchontele" then IsChonTele = false; ChonTeleTarget = nil
        elseif cmd == "teleloan" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TeleLoanTarget = p; IsTeleLoan = true; IsTelePro = false; IsTelePro2 = false; IsTelePro3 = false; IsChonTele = false; TargetFollow1 = nil; TargetFollow2 = nil; TeleLoanAngle = 0; found = true
                    Notification("TELE LOẠN", "Bắt đầu Tele Loạn quanh: " .. p.DisplayName)
                    break
                end
            end
        elseif cmd == "unteleloan" then IsTeleLoan = false; TeleLoanTarget = nil
        elseif cmd == "vitri" and val then
            local cleanVal = val:lower()
            if cleanVal == "dau" or cleanVal == "duoi" or cleanVal == "sau" then SelectedPosition = cleanVal; Notification("CHỌN TELE", "Vị trí đã chuyển sang: " .. cleanVal:upper()) end
        elseif cmd == "offset" then
            local x, y, z = tonumber(args[3]), tonumber(args[4]), tonumber(args[5])
            if x and y and z then OX, OY, OZ = x, y, z; Notification("OFFSET", "Offset mới: " .. x .. ", " .. y .. ", " .. z) end
        elseif cmd == "ad" then AutoClickEnabled = true; Notification("COMBAT", "Auto Click Đã BẬT")
        elseif cmd == "unad" then AutoClickEnabled = false
        elseif cmd == "block" then AutoBlockEnabled = true; Notification("COMBAT", "Auto Block Đã BẬT")
        elseif cmd == "unblock" then AutoBlockEnabled = false
        elseif cmd == "noclip" then NoclipEnabled = true; Notification("PHYSICS", "Noclip Đã BẬT")
        elseif cmd == "unnoclip" then NoclipEnabled = false
        elseif cmd == "katana" then AutoKatanaEnabled = true; Notification("WEAPON", "Auto Cầm Katana Đã BẬT")
        elseif cmd == "unkatana" then AutoKatanaEnabled = false
        elseif cmd == "hitbox" then
            local customSize = tonumber(val); if customSize then HBS = customSize else HBS = 28 end
            HitboxEnabled = true; Notification("HITBOX", "Hitbox cỡ " .. HBS .. " Đã BẬT")
        elseif cmd == "unhitbox" then HitboxEnabled = false; RestoreAllHitboxes()
        end
    end
end)