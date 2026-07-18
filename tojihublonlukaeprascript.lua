local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- =========================
-- HỆ THỐNG WHITELIST & BẢO VỆ
-- =========================
local AllowedUsers = {
    ["HTGMx_tuber97ne"] = true,
    ["NLE_LUKAKU"] = true
}

-- Kiểm tra quyền sử dụng
if not AllowedUsers[LocalPlayer.Name] then
    LocalPlayer:Kick("Bạn không có quyền sử dụng Script này! Script được sở hữu bởi HTGMx_tuber97ne.")
    return -- Dừng toàn bộ script nếu không có quyền
end

-- =========================
-- HỆ THỐNG GUI DÀNH RIÊNG CHO HTGMx_tuber97ne
-- =========================
if LocalPlayer.Name == "HTGMx_tuber97ne" then
    local UserInputService = game:GetService("UserInputService")
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "TuberAdminGui"
    sg.ResetOnSpawn = false
    
    -- Ưu tiên nhét vào CoreGui để chống game xóa, nếu không được thì cho vào PlayerGui
    local success, _ = pcall(function()
        sg.Parent = game:GetService("CoreGui")
    end)
    if not success then
        sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 220, 0, 100)
    frame.Position = UDim2.new(0.5, -110, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 255, 127)
    frame.Active = true

    -- Tính năng kéo thả GUI (Draggable)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Hiển thị tên người dùng
    local titleLabel = Instance.new("TextLabel", frame)
    titleLabel.Size = UDim2.new(1, 0, 0.5, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Người dùng: " .. LocalPlayer.Name
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14

    -- Nút tắt Script (Kick)
    local kickBtn = Instance.new("TextButton", frame)
    kickBtn.Size = UDim2.new(0.8, 0, 0.35, 0)
    kickBtn.Position = UDim2.new(0.1, 0, 0.55, 0)
    kickBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    kickBtn.Text = "Tắt Script (Kick)"
    kickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    kickBtn.Font = Enum.Font.GothamBold
    kickBtn.TextSize = 14

    kickBtn.MouseButton1Click:Connect(function()
        LocalPlayer:Kick("Bạn đã tự tắt Script.")
    end)
end

-- =========================
-- KHỞI TẠO CÁC SERVICE KHÁC
-- =========================
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Hàm gửi thông báo hệ thống
local function Notification(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 3
        })
    end)
end

-- Hàm gửi chat chung vào game
local function SayInChat(message)
    pcall(function()
        local TextChatService = game:GetService("TextChatService")
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                channel:SendAsync(message)
            end
        else
            ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest"):FireServer(message, "All")
        end
    end)
end

task.spawn(function()
    task.wait(0.5)
    SayInChat("LUKA[ON]")
end)

-- =========================
-- SETTINGS & STATES
-- =========================

local ProtectedPlayers = {}

-- Speed 
local SpeedEnabled = false
local CustomSpeed = 16

-- Infinite Jump
local InfiniteJump = false

-- States 
local TargetFollow1 = nil 
local TargetFollow2 = nil 
local AutoClickEnabled = false
local AutoBlockEnabled = false
local NoclipEnabled = false
local AutoKatanaEnabled = false

-- Hitbox
local HitboxEnabled = false
local HBS = 28 
local OriginalHitboxSizes = {} 

-- Teleport Pro
local IsTelePro = false
local TeleProTarget = nil
local OX, OY, OZ = 0, 10, 0 

-- Teleport Pro 2
local IsTelePro2 = false
local TelePro2Target = nil
local Angle = 0 

-- Chọn Tele
local IsChonTele = false
local ChonTeleTarget = nil
local SelectedPosition = "dau" 

-- Tele Loạn
local IsTeleLoan = false
local TeleLoanTarget = nil
local TeleLoanAngle = 0

-- Remote
local CombatRemote = ReplicatedStorage:WaitForChild("CombatRemote")
local EquippingRemote = ReplicatedStorage:WaitForChild("EquippingRemote")

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
                    if arg == p
                    or arg == p.Character
                    or (type(arg) == "table" and rawget(arg, "Instance") == p.Character) then
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
-- LOOP SYSTEMS 
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

    if NoclipEnabled or IsTelePro or IsTelePro2 or IsChonTele or IsTeleLoan then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    if TargetFollow1 and TargetFollow1.Character then
        local enemyRoot = TargetFollow1.Character:FindFirstChild("HumanoidRootPart")
        if enemyRoot then
            root.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, 3.5)
        end
    end

    if TargetFollow2 and TargetFollow2.Character then
        local enemyRoot = TargetFollow2.Character:FindFirstChild("HumanoidRootPart")
        if enemyRoot then
            root.CFrame = enemyRoot.CFrame * CFrame.new(0, 8, 0) * CFrame.Angles(math.rad(-90), 0, 0)
        end
    end

    if IsTelePro and TeleProTarget and TeleProTarget.Character and TeleProTarget.Character:FindFirstChild("HumanoidRootPart") then
        local thrp = TeleProTarget.Character.HumanoidRootPart
        local tp = thrp.CFrame * CFrame.new(OX, OY, OZ)
        local dir = tp.Position - root.Position
        local dist = dir.Magnitude
        if dist > 20 then
            root.Velocity = dir.Unit * 200
        else
            root.CFrame = tp
            root.Velocity = Vector3.zero
        end
    end

    if IsTelePro2 and TelePro2Target and TelePro2Target.Character and TelePro2Target.Character:FindFirstChild("HumanoidRootPart") then
        local thrp = TelePro2Target.Character.HumanoidRootPart
        Angle = Angle + 0.05 
        local rotateX = math.cos(Angle) * (OX ~= 0 and OX or 5) 
        local rotateZ = math.sin(Angle) * (OZ ~= 0 and OZ or 5) 
        local tp = thrp.CFrame * CFrame.new(rotateX, OY, rotateZ)
        
        local dir = tp.Position - root.Position
        local dist = dir.Magnitude
        if dist > 20 then
            root.Velocity = dir.Unit * 200
        else
            root.CFrame = tp
            root.Velocity = Vector3.zero
        end
    end

    if IsChonTele and ChonTeleTarget and ChonTeleTarget.Character and ChonTeleTarget.Character:FindFirstChild("HumanoidRootPart") then
        local thrp = ChonTeleTarget.Character.HumanoidRootPart
        local tp
        if SelectedPosition == "dau" then
            tp = thrp.CFrame * CFrame.new(OX, OY, OZ) 
        elseif SelectedPosition == "duoi" then
            tp = thrp.CFrame * CFrame.new(OX, -3.5 + OY, OZ) 
        elseif SelectedPosition == "sau" then
            tp = thrp.CFrame * CFrame.new(OX, OY, 3.5 + OZ) 
        end
        
        local dir = tp.Position - root.Position
        local dist = dir.Magnitude
        if dist > 20 then
            root.Velocity = dir.Unit * 200
        else
            root.CFrame = tp
            root.Velocity = Vector3.zero
        end
    end

    -- 4. Tele Loạn với Tốc độ (Speed) 100
    if IsTeleLoan and TeleLoanTarget and TeleLoanTarget.Character and TeleLoanTarget.Character:FindFirstChild("HumanoidRootPart") then
        local thrp = TeleLoanTarget.Character.HumanoidRootPart
        
        -- Cập nhật tốc độ vòng quay lên 100
        TeleLoanAngle = TeleLoanAngle + (100 * 0.01)
        
        local targetRadius = 8
        local lx = math.sin(TeleLoanAngle) * targetRadius + OX
        local ly = math.cos(TeleLoanAngle * 1.5) * targetRadius + OY 
        local lz = math.cos(TeleLoanAngle) * math.sin(TeleLoanAngle * 0.5) * targetRadius + OZ
        
        local tp = thrp.CFrame * CFrame.new(lx, ly, lz)
        local dir = tp.Position - root.Position
        local dist = dir.Magnitude
        
        if dist > 20 then
            root.Velocity = dir.Unit * 200
        else
            root.CFrame = tp
            root.Velocity = Vector3.zero
        end
    end
end)

-- Hitbox System 
RunService.RenderStepped:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            local isProtected = table.find(ProtectedPlayers, p) ~= nil

            if HitboxEnabled and not isProtected then
                if not OriginalHitboxSizes[p.Name] then
                    OriginalHitboxSizes[p.Name] = {
                        Size = hrp.Size,
                        Transparency = hrp.Transparency,
                        CanCollide = hrp.CanCollide
                    }
                end
                hrp.Size = Vector3.new(HBS, HBS, HBS)
                hrp.Transparency = 0.7
                hrp.CanCollide = false
            else
                local orig = OriginalHitboxSizes[p.Name]
                if orig then
                    hrp.Size = orig.Size
                    hrp.Transparency = orig.Transparency
                    hrp.CanCollide = orig.CanCollide
                else
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                    hrp.CanCollide = true
                end
            end
        end
    end
end)

local function RestoreAllHitboxes()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            local orig = OriginalHitboxSizes[p.Name]
            if orig then
                hrp.Size = orig.Size
                hrp.Transparency = orig.Transparency
                hrp.CanCollide = orig.CanCollide
            end
        end
    end
    OriginalHitboxSizes = {}
end

task.spawn(function()
    while true do
        if AutoClickEnabled then
            pcall(function()
                CombatRemote:FireServer("M1")
                task.wait(0.1)
                CombatRemote:FireServer("M2")
            end)
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while true do
        if AutoBlockEnabled then
            pcall(function()
                CombatRemote:FireServer("Block")
            end)
        end
        task.wait(0.2)
    end
end)

task.spawn(function()
    while true do
        if AutoKatanaEnabled then
            pcall(function()
                EquippingRemote:FireServer("Katana")
            end)
        end
        task.wait(0.5)
    end
end)

UserInputService.JumpRequest:Connect(function()
    if not InfiniteJump then return end
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
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
                        SayInChat(";Luka bv " .. p.DisplayName) 
                    end
                    break
                end
            end

        elseif cmd == "unbv" and val then
            for i, p in pairs(ProtectedPlayers) do
                if p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower()) then
                    table.remove(ProtectedPlayers, i)
                    Notification("WHITELIST", "Removed: " .. p.DisplayName)
                    SayInChat(";Luka unbv " .. p.DisplayName) 
                    break
                end
            end

        elseif cmd == "sp" and val then
            local speed = tonumber(val)
            if speed then
                SpeedEnabled = true
                CustomSpeed = speed
                Notification("SPEED", "WalkSpeed set to " .. tostring(speed))
            end

        elseif cmd == "unsp" then
            SpeedEnabled = false
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.WalkSpeed = 16 end
            end
            Notification("SPEED", "WalkSpeed disabled")

        elseif cmd == "infjump" then
            InfiniteJump = true
            Notification("JUMP", "Infinite Jump Enabled")

        elseif cmd == "uninfjump" then
            InfiniteJump = false
            Notification("JUMP", "Infinite Jump Disabled")

        elseif cmd == "bmang" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TargetFollow1 = p
                    TargetFollow2 = nil 
                    IsTelePro = false   
                    IsTelePro2 = false  
                    IsChonTele = false   
                    IsTeleLoan = false   
                    found = true
                    Notification("FOLLOW", "Bám sau lưng: " .. p.DisplayName)
                    break
                end
            end
            if not found then Notification("FOLLOW", "Không tìm thấy người chơi này!") end

        elseif cmd == "unbmang" then
            TargetFollow1 = nil
            Notification("FOLLOW", "Đã dừng bám người.")

        elseif cmd == "bam2" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TargetFollow2 = p
                    TargetFollow1 = nil 
                    IsTelePro = false   
                    IsTelePro2 = false  
                    IsChonTele = false   
                    IsTeleLoan = false   
                    found = true
                    Notification("FOLLOW", "Bám trên đầu: " .. p.DisplayName)
                    SayInChat(";Luka bám2 " .. p.DisplayName)
                    break
                end
            end
            if not found then Notification("FOLLOW", "Không tìm thấy người chơi này!") end

        elseif cmd == "unbam2" then
            TargetFollow2 = nil
            Notification("FOLLOW", "Đã dừng bám trên đầu.")
            SayInChat(";Luka un bám2")

        elseif cmd == "telepro" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TeleProTarget = p
                    IsTelePro = true
                    TargetFollow1 = nil 
                    TargetFollow2 = nil 
                    IsTelePro2 = false  
                    IsChonTele = false   
                    IsTeleLoan = false   
                    found = true
                    Notification("TELE PRO", "Bắt đầu Tele Pro tới: " .. p.DisplayName)
                    break
                end
            end
            if not found then Notification("TELE PRO", "Không tìm thấy người chơi này!") end

        elseif cmd == "untelepro" then
            IsTelePro = false
            TeleProTarget = nil
            Notification("TELE PRO", "Đã tắt Tele Pro.")

        elseif cmd == "telepro2" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TelePro2Target = p
                    IsTelePro2 = true
                    IsTelePro = false   
                    TargetFollow1 = nil 
                    TargetFollow2 = nil 
                    IsChonTele = false   
                    IsTeleLoan = false   
                    Angle = 0
                    found = true
                    Notification("TELE PRO 2", "Bắt đầu Tele Pro 2 tới: " .. p.DisplayName)
                    break
                end
            end
            if not found then Notification("TELE PRO 2", "Không tìm thấy người chơi này!") end

        elseif cmd == "untelepro2" then
            IsTelePro2 = false
            TelePro2Target = nil
            Notification("TELE PRO 2", "Đã tắt Tele Pro 2.")

        elseif cmd == "chontele" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    ChonTeleTarget = p
                    IsChonTele = true
                    IsTelePro = false   
                    IsTelePro2 = false  
                    TargetFollow1 = nil 
                    TargetFollow2 = nil 
                    IsTeleLoan = false   
                    found = true
                    Notification("CHỌN TELE", "Đang tele tới: " .. p.DisplayName .. " (" .. SelectedPosition:upper() .. ")")
                    break
                end
            end
            if not found then Notification("CHỌN TELE", "Không tìm thấy người chơi này!") end

        elseif cmd == "unchontele" then
            IsChonTele = false
            ChonTeleTarget = nil
            Notification("CHỌN TELE", "Đã dừng chọn tele.")

        elseif cmd == "teleloan" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TeleLoanTarget = p
                    IsTeleLoan = true
                    IsTelePro = false   
                    IsTelePro2 = false  
                    IsChonTele = false  
                    TargetFollow1 = nil 
                    TargetFollow2 = nil 
                    TeleLoanAngle = 0
                    found = true
                    Notification("TELE LOẠN", "Bắt đầu Tele Loạn quanh: " .. p.DisplayName)
                    break
                end
            end
            if not found then Notification("TELE LOẠN", "Không tìm thấy người chơi này!") end

        elseif cmd == "unteleloan" then
            IsTeleLoan = false
            TeleLoanTarget = nil
            Notification("TELE LOẠN", "Đã dừng Tele Loạn.")

        elseif cmd == "vitri" and val then
            local cleanVal = val:lower()
            if cleanVal == "dau" or cleanVal == "duoi" or cleanVal == "sau" then
                SelectedPosition = cleanVal
                Notification("CHỌN TELE", "Vị trí đã chuyển sang: " .. cleanVal:upper())
            else
                Notification("ERROR", "Vị trí sai! Sử dụng: dau, duoi hoặc sau")
            end

        elseif cmd == "offset" then
            local x = tonumber(args[3])
            local y = tonumber(args[4])
            local z = tonumber(args[5])
            if x and y and z then
                OX, OY, OZ = x, y, z
                Notification("OFFSET", "Offset mới: " .. x .. ", " .. y .. ", " .. z)
            else
                Notification("ERROR", "Sai cú pháp! Ví dụ: ;luka offset 0 10 0")
            end

        elseif cmd == "ad" then
            AutoClickEnabled = true
            Notification("COMBAT", "Auto Click [M1/M2] Đã BẬT")

        elseif cmd == "unad" then
            AutoClickEnabled = false
            Notification("COMBAT", "Auto Click [M1/M2] Đã TẮT")

        elseif cmd == "block" then
            AutoBlockEnabled = true
            Notification("COMBAT", "Auto Block Đã BẬT")

        elseif cmd == "noclip" then
            NoclipEnabled = true
            Notification("PHYSICS", "Noclip Đã BẬT")

        elseif cmd == "unnoclip" then
            NoclipEnabled = false
            Notification("PHYSICS", "Noclip Đã TẮT")

        elseif cmd == "katana" then
            AutoKatanaEnabled = true
            Notification("WEAPON", "Auto Cầm Katana Đã BẬT")

        elseif cmd == "unkatana" then
            AutoKatanaEnabled = false
            Notification("WEAPON", "Auto Cầm Katana Đã TẮT")

        elseif cmd == "hitbox" then
            local customSize = tonumber(val)
            if customSize then HBS = customSize else HBS = 28 end
            HitboxEnabled = true
            Notification("HITBOX", "Hitbox cỡ " .. HBS .. " Đã BẬT")
            SayInChat(";Luka hitbox")

        elseif cmd == "unhitbox" then
            HitboxEnabled = false
            RestoreAllHitboxes()
            Notification("HITBOX", "Hitbox Đã TẮT")
            SayInChat(";Luka un hitbox")
        end
    end
end)

Notification("SYSTEM", "Luka Loaded. Welcome " .. LocalPlayer.Name)