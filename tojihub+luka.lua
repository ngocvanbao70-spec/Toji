local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Hàm gửi thông báo hệ thống (chỉ bạn nhìn thấy)
local function Notification(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 3
        })
    end)
end

-- Hàm gửi chat chung vào game (tự động thông báo tính năng)
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

-- Tự động gửi LUKA[ON] khi chạy script
task.spawn(function()
    task.wait(0.5)
    SayInChat("LUKA[ON]")
end)

-- =========================
-- SETTINGS & STATES
-- =========================

local ProtectedPlayers = {}

-- Speed mặc định KHÔNG bật
local SpeedEnabled = false
local CustomSpeed = 16

-- Infinite Jump
local InfiniteJump = false

-- States (Trạng thái các tính năng)
local TargetFollow1 = nil -- Bám sau lưng (;luka bmang)
local TargetFollow2 = nil -- Bám trên đầu (;luka bam2)
local AutoClickEnabled = false
local AutoBlockEnabled = false
local NoclipEnabled = false
local AutoKatanaEnabled = false

-- Hitbox Settings từ bản Tuber97
local HitboxEnabled = false
local HBS = 28 -- Kích thước mặc định
local OriginalHitboxSizes = {} -- Lưu kích thước gốc

-- Teleport Pro Settings từ bản Tuber97
local IsTelePro = false
local TeleProTarget = nil
local OX, OY, OZ = 0, 10, 0 -- Tọa độ lệch mặc định

-- Teleport Pro 2 (Xoay trên đầu)
local IsTelePro2 = false
local TelePro2Target = nil
local Angle = 0 -- Góc xoay

-- Chọn Tele (Dưới đất, trên đầu, sau lưng)
local IsChonTele = false
local ChonTeleTarget = nil
local SelectedPosition = "dau" -- Mặc định: "dau" | "duoi" | "sau"

-- Tele Loạn (Mới thêm)
local IsTeleLoan = false
local TeleLoanTarget = nil
local TeleLoanAngle = 0

-- Remote References
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
-- LOOP SYSTEMS (Các vòng lặp tính năng)
-- =========================

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end

    -- Speed System
    if SpeedEnabled and humanoid.WalkSpeed ~= CustomSpeed then
        humanoid.WalkSpeed = CustomSpeed
    end

    -- Noclip System (Xuyên tường)
    if NoclipEnabled or IsTelePro or IsTelePro2 or IsChonTele or IsTeleLoan then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    -- Bám 1: Sau lưng 3.5 studs (;luka bmang)
    if TargetFollow1 and TargetFollow1.Character then
        local enemyRoot = TargetFollow1.Character:FindFirstChild("HumanoidRootPart")
        if enemyRoot then
            root.CFrame = enemyRoot.CFrame * CFrame.new(0, 0, 3.5)
        end
    end

    -- Bám 2: Trên đầu 8 studs (;luka bam2)
    if TargetFollow2 and TargetFollow2.Character then
        local enemyRoot = TargetFollow2.Character:FindFirstChild("HumanoidRootPart")
        if enemyRoot then
            root.CFrame = enemyRoot.CFrame * CFrame.new(0, 8, 0) * CFrame.Angles(math.rad(-90), 0, 0)
        end
    end

    -- 1. Dịch chuyển PRO (Tele Pro) lấy từ bản Tuber97
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

    -- 2. Dịch chuyển PRO 2 (Xoay trên đầu địch)
    if IsTelePro2 and TelePro2Target and TelePro2Target.Character and TelePro2Target.Character:FindFirstChild("HumanoidRootPart") then
        local thrp = TelePro2Target.Character.HumanoidRootPart
        Angle = Angle + 0.05 -- Tốc độ xoay chuyển
        
        -- Tính toán tọa độ xoay quanh đầu dựa trên Angle kết hợp Offset (OY là độ cao trên đầu)
        local rotateX = math.cos(Angle) * (OX ~= 0 and OX or 5) -- Nếu offset X = 0 thì mặc định bán kính xoay là 5
        local rotateZ = math.sin(Angle) * (OZ ~= 0 and OZ or 5) -- Nếu offset Z = 0 thì mặc định bán kính xoay là 5
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

    -- 3. Chọn Tele (dau, duoi, sau)
    if IsChonTele and ChonTeleTarget and ChonTeleTarget.Character and ChonTeleTarget.Character:FindFirstChild("HumanoidRootPart") then
        local thrp = ChonTeleTarget.Character.HumanoidRootPart
        local tp
        
        -- Xác định vị trí dựa trên cài đặt SelectedPosition
        if SelectedPosition == "dau" then
            tp = thrp.CFrame * CFrame.new(OX, OY, OZ) -- Sử dụng offset điều chỉnh
        elseif SelectedPosition == "duoi" then
            tp = thrp.CFrame * CFrame.new(OX, -3.5 + OY, OZ) -- Dưới đất (kèm offset)
        elseif SelectedPosition == "sau" then
            tp = thrp.CFrame * CFrame.new(OX, OY, 3.5 + OZ) -- Sau lưng (kèm offset)
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

    -- 4. Tele Loạn (Xoay, Đổi hướng liên tục Trên/Dưới/Trái/Phải/Quanh Địch với Speed tương đương 20, Bán kính 8 studs)
    if IsTeleLoan and TeleLoanTarget and TeleLoanTarget.Character and TeleLoanTarget.Character:FindFirstChild("HumanoidRootPart") then
        local thrp = TeleLoanTarget.Character.HumanoidRootPart
        
        -- Tăng biến góc dựa trên vận tốc yêu cầu (Speed 20 studs, bán kính 8)
        TeleLoanAngle = TeleLoanAngle + (20 * 0.01)
        
        -- Tính toán quỹ đạo toán học hỗn hợp liên tục hoán đổi vị trí Full hướng (X, Y, Z) xung quanh tâm địch
        local targetRadius = 8
        local lx = math.sin(TeleLoanAngle) * targetRadius + OX
        local ly = math.cos(TeleLoanAngle * 1.5) * targetRadius + OY -- Biến đổi chiều cao liên tục từ đầu xuống đất
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

-- Hitbox System (Lấy hoàn toàn từ Tuber97)
RunService.RenderStepped:Connect(function()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            
            -- Nếu trong danh sách bảo vệ (ProtectedPlayers), không phóng to hitbox của họ
            local isProtected = table.find(ProtectedPlayers, p) ~= nil

            if HitboxEnabled and not isProtected then
                -- Sao lưu thông tin gốc trước khi phóng to
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
                -- Trả về bình thường nếu tắt hoặc nằm trong Whitelist
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

-- Khôi phục toàn bộ Hitbox khi tắt script
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

-- Auto Click Loop (M1 & M2)
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

-- Auto Block Loop
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

-- Auto Equip Katana Loop
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

-- =========================
-- INFINITE JUMP
-- =========================

UserInputService.JumpRequest:Connect(function()
    if not InfiniteJump then
        return
    end

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

        -- BV (Chống Target / Thêm vào Whitelist)
        if cmd == "bv" and val then
            for _, p in pairs(Players:GetPlayers()) do
                if p.Name:lower():find(val:lower())
                or p.DisplayName:lower():find(val:lower()) then

                    if not table.find(ProtectedPlayers, p) then
                        table.insert(ProtectedPlayers, p)
                        Notification("WHITELIST", "Added: " .. p.DisplayName)
                        SayInChat(";Luka bv " .. p.DisplayName) -- Chat thông báo
                    end
                    break
                end
            end

        -- UNBV (Hủy Whitelist)
        elseif cmd == "unbv" and val then
            for i, p in pairs(ProtectedPlayers) do
                if p.Name:lower():find(val:lower())
                or p.DisplayName:lower():find(val:lower()) then

                    table.remove(ProtectedPlayers, i)
                    Notification("WHITELIST", "Removed: " .. p.DisplayName)
                    SayInChat(";Luka unbv " .. p.DisplayName) -- Chat thông báo
                    break
                end
            end

        -- SPEED
        elseif cmd == "sp" and val then
            local speed = tonumber(val)
            if speed then
                SpeedEnabled = true
                CustomSpeed = speed
                Notification("SPEED", "WalkSpeed set to " .. tostring(speed))
            end

        -- TẮT SPEED
        elseif cmd == "unsp" then
            SpeedEnabled = false
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.WalkSpeed = 16 end
            end
            Notification("SPEED", "WalkSpeed disabled")

        -- INFINITE JUMP
        elseif cmd == "infjump" then
            InfiniteJump = true
            Notification("JUMP", "Infinite Jump Enabled")

        -- TẮT INFINITE JUMP
        elseif cmd == "uninfjump" then
            InfiniteJump = false
            Notification("JUMP", "Infinite Jump Disabled")

        -- BÁM SAU LƯNG (;luka bmang [tên])
        elseif cmd == "bmang" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TargetFollow1 = p
                    TargetFollow2 = nil -- Tắt bám 2
                    IsTelePro = false   -- Tắt tele pro
                    IsTelePro2 = false  -- Tắt tele pro 2
                    IsChonTele = false   -- Tắt chọn tele
                    IsTeleLoan = false   -- Tắt tele loạn
                    found = true
                    Notification("FOLLOW", "Bám sau lưng: " .. p.DisplayName)
                    break
                end
            end
            if not found then
                Notification("FOLLOW", "Không tìm thấy người chơi này!")
            end

        -- HỦY BÁM SAU LƯNG
        elseif cmd == "unbmang" then
            TargetFollow1 = nil
            Notification("FOLLOW", "Đã dừng bám người.")

        -- BÁM TRÊN ĐẦU 8 STUDS (;luka bam2 [tên])
        elseif cmd == "bam2" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TargetFollow2 = p
                    TargetFollow1 = nil -- Tắt bám 1
                    IsTelePro = false   -- Tắt tele pro
                    IsTelePro2 = false  -- Tắt tele pro 2
                    IsChonTele = false   -- Tắt chọn tele
                    IsTeleLoan = false   -- Tắt tele loạn
                    found = true
                    Notification("FOLLOW", "Bám trên đầu: " .. p.DisplayName)
                    SayInChat(";Luka bám2 " .. p.DisplayName) -- Chat thông báo
                    break
                end
            end
            if not found then
                Notification("FOLLOW", "Không tìm thấy người chơi này!")
            end

        -- HỦY BÁM TRÊN ĐẦU
        elseif cmd == "unbam2" then
            TargetFollow2 = nil
            Notification("FOLLOW", "Đã dừng bám trên đầu.")
            SayInChat(";Luka un bám2") -- Chat thông báo

        -- TELEPORT PRO (;luka telepro [tên])
        elseif cmd == "telepro" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TeleProTarget = p
                    IsTelePro = true
                    TargetFollow1 = nil -- Tắt bám 1
                    TargetFollow2 = nil -- Tắt bám 2
                    IsTelePro2 = false  -- Tắt tele pro 2
                    IsChonTele = false   -- Tắt chọn tele
                    IsTeleLoan = false   -- Tắt tele loạn
                    found = true
                    Notification("TELE PRO", "Bắt đầu Tele Pro tới: " .. p.DisplayName)
                    break
                end
            end
            if not found then
                Notification("TELE PRO", "Không tìm thấy người chơi này!")
            end

        -- TẮT TELEPORT PRO
        elseif cmd == "untelepro" then
            IsTelePro = false
            TeleProTarget = nil
            Notification("TELE PRO", "Đã tắt Tele Pro.")

        -- TELEPORT PRO 2 (;luka telepro2 [tên]) - XOAY QUANH TRÊN ĐẦU ĐỊCH
        elseif cmd == "telepro2" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TelePro2Target = p
                    IsTelePro2 = true
                    IsTelePro = false   -- Tắt tele pro
                    TargetFollow1 = nil -- Tắt bám 1
                    TargetFollow2 = nil -- Tắt bám 2
                    IsChonTele = false   -- Tắt chọn tele
                    IsTeleLoan = false   -- Tắt tele loạn
                    Angle = 0
                    found = true
                    Notification("TELE PRO 2", "Bắt đầu Tele Pro 2 (Xoay đầu) tới: " .. p.DisplayName)
                    break
                end
            end
            if not found then
                Notification("TELE PRO 2", "Không tìm thấy người chơi này!")
            end

        -- TẮT TELEPORT PRO 2
        elseif cmd == "untelepro2" then
            IsTelePro2 = false
            TelePro2Target = nil
            Notification("TELE PRO 2", "Đã tắt Tele Pro 2.")

        -- CHỌN TELE (;luka chontele [tên])
        elseif cmd == "chontele" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    ChonTeleTarget = p
                    IsChonTele = true
                    IsTelePro = false   -- Tắt tele pro
                    IsTelePro2 = false  -- Tắt tele pro 2
                    TargetFollow1 = nil -- Tắt bám 1
                    TargetFollow2 = nil -- Tắt bám 2
                    IsTeleLoan = false   -- Tắt tele loạn
                    found = true
                    Notification("CHỌN TELE", "Đang tele tới: " .. p.DisplayName .. " (" .. SelectedPosition:upper() .. ")")
                    break
                end
            end
            if not found then
                Notification("CHỌN TELE", "Không tìm thấy người chơi này!")
            end

        -- TẮT CHỌN TELE
        elseif cmd == "unchontele" then
            IsChonTele = false
            ChonTeleTarget = nil
            Notification("CHỌN TELE", "Đã dừng chọn tele.")

        -- TELE LOẠN (;luka teleloan [tên]) - MỚI THÊM
        elseif cmd == "teleloan" and val then
            local found = false
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and (p.Name:lower():find(val:lower()) or p.DisplayName:lower():find(val:lower())) then
                    TeleLoanTarget = p
                    IsTeleLoan = true
                    IsTelePro = false   -- Tắt tele pro
                    IsTelePro2 = false  -- Tắt tele pro 2
                    IsChonTele = false  -- Tắt chọn tele
                    TargetFollow1 = nil -- Tắt bám 1
                    TargetFollow2 = nil -- Tắt bám 2
                    TeleLoanAngle = 0
                    found = true
                    Notification("TELE LOẠN", "Bắt đầu Tele Loạn quanh: " .. p.DisplayName)
                    break
                end
            end
            if not found then
                Notification("TELE LOẠN", "Không tìm thấy người chơi này!")
            end

        -- TẮT TELE LOẠN
        elseif cmd == "unteleloan" then
            IsTeleLoan = false
            TeleLoanTarget = nil
            Notification("TELE LOẠN", "Đã dừng Tele Loạn.")

        -- CHỌN VỊ TRÍ CHỌN TELE (;luka vitri [dau / duoi / sau])
        elseif cmd == "vitri" and val then
            local cleanVal = val:lower()
            if cleanVal == "dau" or cleanVal == "duoi" or cleanVal == "sau" then
                SelectedPosition = cleanVal
                Notification("CHỌN TELE", "Vị trí đã chuyển sang: " .. cleanVal:upper())
            else
                Notification("ERROR", "Vị trí sai! Sử dụng: dau, duoi hoặc sau")
            end

        -- CHỈNH TỌA ĐỘ LỆCH (Dùng chung cho Tele Pro, Tele Pro 2, Chọn Tele, Tele Loạn)
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

        -- AUTOCLICK (BẬT)
        elseif cmd == "ad" then
            AutoClickEnabled = true
            Notification("COMBAT", "Auto Click [M1/M2] Đã BẬT")

        -- AUTOCLICK (TẮT)
        elseif cmd == "unad" then
            AutoClickEnabled = false
            Notification("COMBAT", "Auto Click [M1/M2] Đã TẮT")

        -- AUTO BLOCK (BẬT)
        elseif cmd == "block" then
            AutoBlockEnabled = true
            Notification("COMBAT", "Auto Block Đã TẮT")

        -- NOCLIP (BẬT)
        elseif cmd == "noclip" then
            NoclipEnabled = true
            Notification("PHYSICS", "Noclip Đã BẬT")

        -- NOCLIP (TẮT)
        elseif cmd == "unnoclip" then
            NoclipEnabled = false
            Notification("PHYSICS", "Noclip Đã TẮT")

        -- AUTO CẦM KATANA (BẬT)
        elseif cmd == "katana" then
            AutoKatanaEnabled = true
            Notification("WEAPON", "Auto Cầm Katana Đã BẬT")

        -- AUTO CẦM KATANA (TẮT)
        elseif cmd == "unkatana" then
            AutoKatanaEnabled = false
            Notification("WEAPON", "Auto Cầm Katana Đã TẮT")

        -- HITBOX 28 (BẬT)
        elseif cmd == "hitbox" then
            local customSize = tonumber(val)
            if customSize then HBS = customSize else HBS = 28 end
            
            HitboxEnabled = true
            Notification("HITBOX", "Hitbox cỡ " .. HBS .. " Đã BẬT")
            SayInChat(";Luka hitbox")

        -- HITBOX 28 (TẮT)
        elseif cmd == "unhitbox" then
            HitboxEnabled = false
            RestoreAllHitboxes()
            Notification("HITBOX", "Hitbox Đã TẮT")
            SayInChat(";Luka un hitbox")
        end
    end
end)

Notification("SYSTEM", "Luka Loaded.")