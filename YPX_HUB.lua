-- ===================================================
-- Project: ypx Multi-Game Master Hub
-- Version: v3.1 (ypx FloatBall + Toast Welcome)
-- Developer: ypx
-- Architecture: Luxury Multi-Adapter Engine (Multi-Game Support)
-- ===================================================

-- 第0步：兼容层（与扫描器完全一致）
local _spawn = spawn or function(f) coroutine.wrap(f)() end
local _wait  = wait or function(t) local R = game:GetService("RunService"); if R and R.Heartbeat then for _ = 1, math.floor((t or 0.1)*60) do R.Heartbeat:Wait() end end end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local VirtualUser = nil
pcall(function() VirtualUser = game:GetService("VirtualUser") end)
local HttpService = nil
pcall(function() HttpService = game:GetService("HttpService") end)

-- 第一步：确保 LocalPlayer 就绪（与扫描器完全一致）
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    pcall(function()
        LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    end)
end
if not LocalPlayer then
    repeat _wait(0.5); LocalPlayer = Players.LocalPlayer until LocalPlayer
end

local set_clipboard = setclipboard or set_copy or (syn and syn.write_clipboard) or function() end
local open_url = openurl or opentarget or (syn and syn.open_url) or function(url) end

-- 文件操作兼容层（统一带下划线和不带下划线两种命名）
local write_file = writefile or (syn and syn.writefile)
local read_file  = readfile  or (syn and syn.readfile)
local is_file    = isfile    or (syn and syn.isfile)
-- 建立全局别名，确保所有代码路径都能找到
writefile = write_file
readfile  = read_file
isfile    = is_file

-- 自定义资源加载兼容
local get_custom_asset = getcustomasset or (syn and syn.getcustomasset) or function(path)
    -- 备选：尝试直接用 rbxasset 路径
    if is_file and is_file(path) then
        return "rbxasset://" .. path
    end
    return nil
end
getcustomasset = get_custom_asset

-- 兼容 os.time 缺失
local os_time = os and os.time or function() return tick() end

-- 保留 task_spawn/task_wait 别名，兼容内部代码
local task_spawn = _spawn
local task_wait = _wait

local Config = {
    HubVersion = "2.7",
    KeySystemEnabled = true,
    UserKey = "ypx-vip-2026",
    ValidDurationHours = 24,
    KeyLink = "https://lootdest.org/s?kjLRWzSa",
    DiscordLink = "https://discord.gg/szQ573FFQ",
    SaveFileName = "YPX_Hub_KeyData.json"
}

-- ===================================================
-- 内嵌悬浮球图片 (Base64 自动解码写入)
-- 运行时自动解码并写入 workspace，无需手动放置图片
-- ===================================================
local function _b64_decode_char(c)
    if c >= 65 and c <= 90 then return c - 65 end
    if c >= 97 and c <= 122 then return c - 71 end
    if c >= 48 and c <= 57 then return c + 4 end
    if c == 43 then return 62 end
    if c == 47 then return 63 end
    return -1
end

local function _b64_decode(data)
    local out = {}
    local i, j = 1, 0
    local buf = 0
    for p = 1, #data do
        local c = data:byte(p)
        local v = _b64_decode_char(c)
        if v >= 0 then
            buf = buf * 64 + v
            j = j + 6
            if j >= 8 then
                j = j - 8
                out[i] = string.char(math.floor(buf / (2 ^ j)) % 256)
                i = i + 1
            end
        end
    end
    return table.concat(out)
end

local function _autoSetupFloatBallImage()
    local imgPath = "floatball_icon.jpg"
    if isfile and isfile(imgPath) then return true end
    if writefile then
        local b64data = table.concat({
            "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIy",
            "MjIyMjIyMjL/wAARCACAAIADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVW",
            "V1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAEC",
            "AxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq",
            "8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD36iiigAooyM4zzTJZVhheWQ4RFLMfQCgBtxcxWsYeVsAkKo6liegA7muX1jxHJG8kUTSAoSGjtwGcf7z/AHVPsMmsk3F5qOoy6neSvDGQVggBwY0PqexI645qvMWuVESKyWw42R8FvqR0FUo9wKUGvJcXu2SLVCSeRFCZD+mS",
            "a17m8a7j+zR2+sWsA6m4t1Ib6gnP6Vn/ANqxaSoKyQwpCN5ihAzgdcn09+axr/xpLrEgGi2cvnMT5kjgbAfbPNaW7CSI7yO5064Z7N4yx+95I2kj0aM9RVn+1JDozL5iJKfuI0mMH1BPIHtUdnc3d5D5U+vNJNuw/kQoViP93nv74FWU8OzxOGiv2kcngSxKVb8hkUX7",
            "jLcfivVY0SGxS4KhRyuwgtj5jyOhOTW/YeJddgEbahZLNE3JKqUdfx+6f0qppzReVJaz2ix3ERAlRucDsyn0PrV1l8hTs3Be6gnj6VDsI6y0vYL2ESQtkdweCPrViuDN3c2Z+02xeQL95VOG/HsR9a1tJ8aafqEiwSCSK4zgqU71LQzpqKajls/IyjtnvTqQBRRRQBXu",
            "LK3usGWIFh0YEhh+I5rh9du4zO1pZXtwVjJDvI/mKT6AHritfxnr76ZaR2Fkd2oXgIQA42IPvOT2HbNcVo52TmUzRuluMvIw+QEDk49BVRWlwJo11GAMdQuY0VWC4iiALE9AO5PtUN+b1QIrW3kurmT7kJf5EHqxqfR70+JNQm1d4itpETDZR5wGb+KQ/wCeBmt62snh",
            "klkaVXEjfJt7iqvYRzGmeFFWyk/tYrdXU775tpO04+6vuB6cDP0FW4ohpNzHawtGTKCMIgG0gE4+mBXS+QcbRx2JrLngVvFOl2sagLDbz3Dj64QZ/M0uYDH1C1W3iXWrWBfOtyGuEUf6yE/e+uOo7jFdZEnlABAOQGB9j0pY9MRHIxlGUqQfQ9aksbRo7WNGzlEC5Ptm",
            "k2Blaq0sCrfEBjb8vgctEfvD8Ov1FaUUls6RKZAzyJxzwatz6d59pNE4IWRDHn6jH9a4zwpFPPpsBnyWgl+zn3ZWwf5U0rgbksTW829DweoqWIxWV9DqVtEm8jbImByO+D2NXPJRL1vtLLkqMKT3JPHvwK5bUb1re8RYn/drKQQO9NK4HptvcRXUCzQsGRhkGpa4y0vJ",
            "LUMYpmjGM4AyD+FaOjX19qt05eQi2hI3MABubso/mfwqLDOirNvb69gDiLT3kx0YMGB/Ac1pVBeXMdlZzXMp/dxIXb8KQHjXiqfVbnVmjltprV5xl5pVwxQcYX0H+fenXVnjTLfRYVKxy4e6YHkp/d/4EcD86fDcTeIPFE99c8W8J3vnoTj5VHsBz/8ArrTmkihhE8vE",
            "txJuweu0DP6D+dbATaVaiLwxZwhOkK8erNyavxXBtYY0UMxyVUDrjuR+NQWs6zJZRRZ8tUMjfQcAfnVq2QM6ysOFzg/hUeojSS6CeWssonHIOcev/66o6C8Oo+IdX1IsPJ3LYWp67hHy5H1Zv0rN17UZBZGG2GJ5j5cXqT6n2HWpdGha3tY7OzJRIU8vzSOnqfdiSSf",
            "rRbS4krHXRJGzs3mqygcAGoX1C2t4dqkNMeOOxNYZu/It5RCMceVHj09aggheTaWJ2jIOfXvQl3GbkOtJdzGDyivAIbdkHkVgW7tDYqlqNryXE1wSO2WIH9atXEv2ZYY1wGOSSB+VJaw+XCRjBwFwewFO6WqF0KkXmG/tnZiRnjJzwKp39sJQjKOWkLfzrQ3bmjdRjCE",
            "L+JwKqahIlvEoZ9i7Su70zxn9ad7saViS1sb7U9WS2i8xbYKru4IChe4z1z7CvQ7eCK2gSGFFSNRgBRivN0uHQI8cmGUfK8b4/I1uaNrtxLMsd5qIUZwsZh3yP8AiB/jUyi9xnYMyqMswA9ziszUbWPVIxHcHFhGd8gzjzcdv9319a0yoPUA/WsHxdfrZ6I8O7D3R8oc",
            "9B/Efy/nUdQODuLxEaSUYU3c7MBj+H/ADFcpq/iAXb3k8R/d20It4B3Z3PzH8BSald3Wo6t9ntIm3SqbezBGAxz8zZ9sc1t3WmpFplloFpGr/Z3WSeTs0vpn6kk/THY1q3ZpFKN1c0dDmuIdJt2kBxJIFYn+Hj+X9a37e5hktyoPyKOorD8S3UGhaXY2ZLGSQ5CjlmCj",
            "+pajRL1Utg1xgeZyx7KO+PX0qYvmVwnFRdkTG2uLprnUHUrhNkI+pwFH1JGT+ArfigWytEhB+WNcE+vHJpYJY76WCGAARqfMOf8AZ5H64pt5MrSCIH5erY/ujr+fA/GjVkFJkaTULaIDgHzX9sdB+daGxUTLnAX5jUOmTLLZSX7Y5Uc1mf2oLiK/AP8AqmiGfdv/ANdF",
            "rgaflb9QWSTqOEHoT3qykS77lT/C3ze3eoic63aQKCSRvOB2Vc/zIqpLfktqoU7V8xl3e+Qg/kaLDKq3SGWNU5z8q+nHU/m2KzvEr5smkHQMAPcDr+v8qx5NVEd9pXlNiOW1lVPqJBWpqFzBO72Dyor4AVWOC3HUetaRWqAXw/ZzavKsMEZIGC5Bwqj1J/pXp2naXbab",
            "CFhjUPj5nxya5nRdRtrPTrHTLK2WzKlTcSNwmAfmOTyxb+tdRFqdvcT+Vblpj/EyL8q/U9Kio5N+Qi2zKilmIVQMkk4AFee+IZ5dWv4pHt5zZZ2xlVI2x5G+QnoPau/lgjnXbKgdf7rcg/Ud6yfENus1oieayAMCVDlVwPoDjtzUJ2YzyhLZ08VPMg22umWuIFXJCyuA",
            "vT+8QC1dL4dgR0i1CTHlFdyg/wAI9T7nGa5bQ9VktZL+1FqZ52uHkTnLMSpXvycDn8an8L3t5dWd1oigQ3dvcCCTzTnamSdxHfHTHfFTO+pvTskibWYLbVfE1xf3khkWBFWKLOFhTrlvVmOTjsMVf0KzvPMl1S/t/Is4oy8UcnBVQPvMO3HQVkaaEstUhtIpPtPmXcry",
            "SycljhipPvx+lbXii+Mmqw+HXunjSe184kcbn3Dap/2cKeO+aqV9IRFHS82WdOu0jjncfL+4LfiWANZeo6y0em394CAoXy0PqTwo/mayf7QuLVJILm3kSVY2Qsp3BsHOfYVzkmv2VxDZWs3nSIAJniUY3tjgZJ4FatqKuZxXM7Hfpf8Ak+HbS0jfJljXP0x1rntP1Bzd",
            "yxOG8u+1GHZxjciEhiPyqkdVjd8y3MdvHtCoSwBCjqR756VrWpsLufS5bRJMQOwiLAgbduO/uRUudmoopU3yuTO9kvhZXl7qpYRwRW6qqj/ZBZifyUVwy65dS2dhbTSHMxEpT0yS2PzJ/Kn+J9WE9t/ZcDHNwwjPsmcsT9cGsSxgfUtTZg+xIo8hv7oAwP5saaaim2KM",
            "GyB5Lb+zIY45le402UurtxvRzlseuDkH86uXVxb3jwXMo3wyYSTHJUjoao6tJZW3hVzIELEmG1+X7yn7zY64GNwPqaxfDOsReH/FNv8A2pbC5sAMvBgMGBHDAHg84NKlN8t2OtFRlZHvHgux019OGF+0Srz5kjbgQemB0GOldgiJGoVFCqOwGBXn+l+NdBnvoLi0tpbJ",
            "TlZk8tdrAjg/KeoOO1d9DNHcQpNC6vG4yrKcgipk7u5kiSsrWNPuL/ykt3WI8hpic7B6hejN6Z4HX2rVoqRnh3jfRbnw/NEliN8sbCdZQ3zuM8sw+vU/41ljfbatJfwFh9pijgmYf7RGG+tev6/4W/tWWTUPNJv44fLthnaijduIPru6HNcLBohmN3YbNjhgyK/DLjna",
            "fcfL+HNVdcprB8zMDQ2eO9knmUjF7mPjqoTyz+RP61J8Qp3i8X2F/ESY5YUjUr6AsG/EEiupi01p9Pe2mswwglaaOVG5V+roy9cEdx7VFfWUVxqemwKplSzRpgW5I3E7cn8z+ArOVT3uY1jTvHlOfuJ0ubX7baqsrKD50S9XXuV/wrPs9D0+90+OK2jV4h90gc49/X0I",
            "ron8LLea4k9pcfZhKGM6R4K7h0bGflJ/WtKw8HQaa8guYRLG77/tELMrKfcA5x7inOpGUfMUIunPyMLS/CMQ3M8aD5uCqDNaF/YDTrmzaKN9ojkztHIAwS34Cu3gsoLeMKpLAd2bcT+NMuIIHaJ3GHibejenGD+BB5FYxm1K5pO0o8qOHtNFhk0u1nlXMrO0k0hPJ6qB",
            "+VRRDS4m1GW5z5AVImjhIHTO0HHIBPFXb+4TS9NuS37uFZHdF/upngf/AFveuIk0+eO0TUnD/aLmdWSLP3iTnkd+lNu7KirROf8AE8s02tXPnmNfKGY1ibcojwCCp7jBz+fpWCmssmLW6tYbhYz+7csVZQfQjtXqtxpWm3ehC7aILGg3KejK3oD2Oe3SvLbvRI7S7aVp",
            "w0I+YIBgj0HpXRConojlqU5LVu50Ok6zhAwOOcYz0r374baidR8IRE9YZpIvwzkf+hV8r2U5iZgT35r6L+C1yj+E51LAM144UE8n5VPFEjM9MoooqRBXCeN7jTLDULW4+2LBqLsF2qMnHZmx0HbnqDW34k19tLt2jtgGnI5Y9EH+NeJeILhrmWWaRy8jnLMTyTVxhdXY",
            "07O563ZsZdt0IwjuNk8Y6Bh3/wA9qqatoUd9YPEFxLHloJASpHfGR29qy/h5rp1bSPs87ZuYD5bk9Wx0P4j+VdlLhV9q5ZaM60+qOG8LzSRLJs02HCsY5JfMAlVh1VgRz7HPNdV9tG3IGWxwuRk1wfiDVBoniqG7tcFZspdRA4DoMYb6jPBrqYJY7q3jljkEsbDhx3H+",
            "NSy3ruVpNf1O11JIbrSZjaSHH2i3JkWP03cDH4ZFW9U1SCygeaeVY0UcsxrM1fXrXRkIdy8xHyxKck/4VgpFc6uyXF+qna2+OMDhOOPqf8aAUSp9pk8UayluEZbKM7yG6uQeMj0749q6qbSY5tQgZvu2ilgO24jGfwFU/C9jDZLfahMyqgdmLscAKCa5nxF4xkk86CzY",
            "qJD857ke/oParSu7IJStuVvFmswxs1pbMPKDFsDozdz9K4CeRrqfDE7V+Zqkup2kdmJJY9zUH3IQo++5reMbHLUm5FCTCRsw6sc/4V2Wn6neWngqNIpWiK3P2lGjYqytnbkEcjiuLu3A+6OAePoK7qTTWt/C0UXUiJS31JB/rVaNkJH1LWdrOpjTLEygAyMdsYPTNaNc",
            "h8Q3MGiW9wP4JwD9Cp/wqYq7SZJzV7fecXMzb2flie9cXqGnwXUkyLLLGd2EdTkDHXI78/yqfUNVW3iMzv8AKFyPcnoPzplnIJbYMee2a2m+hSRP4GCeHdVmN/OqiZl2z87MDPBPY5J68e9epahK0tjm3IbePlYHIOfevLfNMYJA68UtteS2rZtbyW0PUiNsIfqvSued",
            "K7ujaM7aFS8sZtQ1u9aSXeUOwHtwO3tk1dt4pbOJo7a6uYEb70cUpAzjr7H6VlJa39vqsl9FdxzGVizAHBOe208Guhga01G2KTOYpTwSjdPoahq25rCaZzVpbyJqzyTOZrSOYeZLIclM9C3rz3rrdQvxp+ns+VJIxHjuT/Osaa0TQYrz7TKJba5iMYYAe/Uf5FcXqmvG",
            "4jEEZKQINqDJGF9vr60lHmHKagtTX1vxRLPZpp1u5jtY8bsH77DufU5/AfWuZE2/g9apmUuen0FSxKS4z1rojFJHJKbk7sbIO56VTa4yTKRhSdiHPT3qa8YzSi2iOB/Gw7Co47b7ZOIgdsCdMDnA6Um+VXEk3oEFktxfWlu7AyTyAbQegJH/ANevSNSLTKLOAZdvvY/h",
            "FcJpMc516GK2iQXERznHHT75/OvSLeBLSDJJZ+rOerGlDVXLP//Z"
        }, "")
        local rawData = _b64_decode(b64data)
        if rawData and #rawData > 0 then
            writefile(imgPath, rawData)
            return true
        end
    end
    return false
end

_autoSetupFloatBallImage()

-- 第二步：找到父容器（与扫描器完全一致）
local function FindParent()
    local ok, r
    ok, r = pcall(function() if gethui then return gethui() end end)
    if ok and r then return r end
    ok, r = pcall(function() return game:GetService("CoreGui") end)
    if ok and r then return r end
    ok, r = pcall(function() return LocalPlayer:WaitForChild("PlayerGui") end)
    if ok and r then return r end
    ok, r = pcall(function() return LocalPlayer.PlayerGui end)
    if ok and r then return r end
    return nil
end

local Parent = FindParent()
if not Parent then
    if not LocalPlayer.Character then
        pcall(function() LocalPlayer.CharacterAdded:Wait() end)
    end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then repeat _wait(0.5); pg = LocalPlayer:FindFirstChild("PlayerGui") until pg end
    Parent = pg
end

-- 第三步：创建 ScreenGui（直接用 Parent）
if _G.YpxHubActiveInstance then
    pcall(function() _G.YpxHubActiveInstance:Destroy() end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YPX_LuxuryMasterHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = Parent
_G.YpxHubActiveInstance = ScreenGui

local function EnableSmoothDrag(guiObject)
    local dragging, dragInput, dragStart, startPos
    
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            RunService.Heartbeat:Wait()
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function CheckIsKeyValid()
    if not Config.KeySystemEnabled then return true end
    local isValid = false
    pcall(function()
        if is_file and read_file and is_file(Config.SaveFileName) then
            local rawData = read_file(Config.SaveFileName)
            if rawData and #rawData > 0 then
                local data = HttpService:JSONDecode(rawData)
                if data and data.Key == Config.UserKey and data.ExpireTime then
                    if os_time() < data.ExpireTime then
                        isValid = true
                    end
                end
            end
        end
    end)
    return isValid
end

local function SaveKeyData()
    if write_file then
        pcall(function()
            local expireTime = os_time() + (Config.ValidDurationHours * 3600)
            local data = { Key = Config.UserKey, ExpireTime = expireTime }
            write_file(Config.SaveFileName, HttpService:JSONEncode(data))
        end)
    end
end

local StartCoreEngine
local ShowKeyVerificationWindow
local FloatBall, MainFrame

local function ShowSplashLoadingScreen()
    local SplashFrame = Instance.new("Frame")
    SplashFrame.Name = "YpxSplashLoading"
    SplashFrame.Size = UDim2.new(0, 310, 0, 160)
    SplashFrame.Position = UDim2.new(0.5, -155, 0.4, -80)
    SplashFrame.BackgroundColor3 = Color3.fromRGB(10, 11, 16)
    SplashFrame.BorderSizePixel = 0
    SplashFrame.Parent = ScreenGui

    local SplashCorner = Instance.new("UICorner")
    SplashCorner.CornerRadius = UDim.new(0, 16)
    SplashCorner.Parent = SplashFrame

    local SplashStroke = Instance.new("UIStroke")
    SplashStroke.Color = Color3.fromRGB(0, 240, 255)
    SplashStroke.Thickness = 2
    SplashStroke.Parent = SplashFrame

    EnableSmoothDrag(SplashFrame)

    local SplashTitle = Instance.new("TextLabel")
    SplashTitle.Size = UDim2.new(1, 0, 0, 35)
    SplashTitle.Position = UDim2.new(0, 0, 0, 18)
    SplashTitle.Text = "⚡ YPX LUXURY HUB v" .. Config.HubVersion
    SplashTitle.TextColor3 = Color3.fromRGB(0, 240, 255)
    SplashTitle.TextSize = 15
    SplashTitle.Font = Enum.Font.GothamBold
    SplashTitle.BackgroundTransparency = 1
    SplashTitle.Parent = SplashFrame

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -30, 0, 25)
    StatusLabel.Position = UDim2.new(0, 15, 0, 60)
    StatusLabel.Text = "正在初始化安全引擎 ( Initializing Engine ... )"
    StatusLabel.TextColor3 = Color3.fromRGB(200, 210, 230)
    StatusLabel.TextSize = 10
    StatusLabel.Font = Enum.Font.GothamMedium
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Parent = SplashFrame

    local CountdownLabel = Instance.new("TextLabel")
    CountdownLabel.Size = UDim2.new(1, 0, 0, 30)
    CountdownLabel.Position = UDim2.new(0, 0, 0, 100)
    CountdownLabel.Text = "2 秒后启动核心框架..."
    CountdownLabel.TextColor3 = Color3.fromRGB(150, 160, 180)
    CountdownLabel.TextSize = 10
    CountdownLabel.Font = Enum.Font.GothamBold
    CountdownLabel.BackgroundTransparency = 1
    CountdownLabel.Parent = SplashFrame

    task_spawn(function()
        for i = 2, 1, -1 do
            CountdownLabel.Text = i .. " 秒后启动核心框架..."
            task_wait(1)
        end
        
        pcall(function() SplashFrame:Destroy() end)

        if CheckIsKeyValid() then
            StartCoreEngine()
        else
            ShowKeyVerificationWindow()
        end
    end)
end

ShowKeyVerificationWindow = function()
    local KeyFrame = Instance.new("Frame")
    KeyFrame.Name = "LuxuryLoginFrame"
    KeyFrame.Size = UDim2.new(0, 320, 0, 320)
    KeyFrame.Position = UDim2.new(0.5, -160, 0.3, 0)
    KeyFrame.BackgroundColor3 = Color3.fromRGB(10, 11, 16)
    KeyFrame.BorderSizePixel = 0
    KeyFrame.Parent = ScreenGui

    local KeyCorner = Instance.new("UICorner")
    KeyCorner.CornerRadius = UDim.new(0, 16)
    KeyCorner.Parent = KeyFrame

    local KeyStroke = Instance.new("UIStroke")
    KeyStroke.Color = Color3.fromRGB(0, 240, 255)
    KeyStroke.Thickness = 2
    KeyStroke.Parent = KeyFrame

    EnableSmoothDrag(KeyFrame)

    local HeaderGlow = Instance.new("Frame")
    HeaderGlow.Size = UDim2.new(1, 0, 0, 48)
    HeaderGlow.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
    HeaderGlow.Parent = KeyFrame

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 16)
    HeaderCorner.Parent = HeaderGlow

    local KeyTitleText = Instance.new("TextLabel")
    KeyTitleText.Size = UDim2.new(1, -20, 1, 0)
    KeyTitleText.Position = UDim2.new(0, 14, 0, 0)
    KeyTitleText.Text = "⚡ YPX HUB v" .. Config.HubVersion .. " ( 高级授权系统 )"
    KeyTitleText.TextColor3 = Color3.fromRGB(0, 240, 255)
    KeyTitleText.TextSize = 12
    KeyTitleText.Font = Enum.Font.GothamBold
    KeyTitleText.BackgroundTransparency = 1
    KeyTitleText.TextXAlignment = Enum.TextXAlignment.Left
    KeyTitleText.Parent = HeaderGlow

    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(1, -28, 0, 42)
    GetKeyBtn.Position = UDim2.new(0, 14, 0, 62)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    GetKeyBtn.Text = "🔑 获取卡密 ( Get Key )"
    GetKeyBtn.TextColor3 = Color3.fromRGB(10, 10, 15)
    GetKeyBtn.TextSize = 11
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.Parent = KeyFrame

    local GetKeyCorner = Instance.new("UICorner")
    GetKeyCorner.CornerRadius = UDim.new(0, 8)
    GetKeyCorner.Parent = GetKeyBtn

    GetKeyBtn.MouseButton1Click:Connect(function()
        set_clipboard(Config.KeyLink)
        open_url(Config.KeyLink)
        GetKeyBtn.Text = "✓ 链接已复制 ( Copied )"
        task_wait(2)
        GetKeyBtn.Text = "🔑 获取卡密 ( Get Key )"
    end)

    local KeyInput = Instance.new("TextBox")
    KeyInput.Size = UDim2.new(1, -28, 0, 42)
    KeyInput.Position = UDim2.new(0, 14, 0, 114)
    KeyInput.BackgroundColor3 = Color3.fromRGB(20, 23, 33)
    KeyInput.Text = ""
    KeyInput.PlaceholderText = "在此粘贴获取到的卡密..."
    KeyInput.PlaceholderColor3 = Color3.fromRGB(120, 130, 150)
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.TextSize = 11
    KeyInput.Font = Enum.Font.GothamMedium
    KeyInput.Parent = KeyFrame

    local KeyInputCorner = Instance.new("UICorner")
    KeyInputCorner.CornerRadius = UDim.new(0, 8)
    KeyInputCorner.Parent = KeyInput

    local VerifyBtn = Instance.new("TextButton")
    VerifyBtn.Size = UDim2.new(1, -28, 0, 42)
    VerifyBtn.Position = UDim2.new(0, 14, 0, 166)
    VerifyBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 120)
    VerifyBtn.Text = "🚀 验证并启动 ( Verify & Launch )"
    VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    VerifyBtn.TextSize = 11
    VerifyBtn.Font = Enum.Font.GothamBold
    VerifyBtn.Parent = KeyFrame

    local VerifyCorner = Instance.new("UICorner")
    VerifyCorner.CornerRadius = UDim.new(0, 8)
    VerifyCorner.Parent = VerifyBtn

    local StatusText = Instance.new("TextLabel")
    StatusText.Size = UDim2.new(1, -28, 0, 25)
    StatusText.Position = UDim2.new(0, 14, 0, 218)
    StatusText.Text = "提示：验证成功后 24 小时内免验证"
    StatusText.TextColor3 = Color3.fromRGB(150, 160, 180)
    StatusText.TextSize = 9
    StatusText.Font = Enum.Font.GothamMedium
    StatusText.BackgroundTransparency = 1
    StatusText.Parent = KeyFrame

    local DiscordBtn = Instance.new("TextButton")
    DiscordBtn.Size = UDim2.new(1, -28, 0, 34)
    DiscordBtn.Position = UDim2.new(0, 14, 0, 252)
    DiscordBtn.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
    DiscordBtn.Text = "💬 加入 Discord 交流群"
    DiscordBtn.TextColor3 = Color3.fromRGB(100, 180, 255)
    DiscordBtn.TextSize = 10
    DiscordBtn.Font = Enum.Font.GothamMedium
    DiscordBtn.Parent = KeyFrame

    local DiscordCorner = Instance.new("UICorner")
    DiscordCorner.CornerRadius = UDim.new(0, 6)
    DiscordCorner.Parent = DiscordBtn

    DiscordBtn.MouseButton1Click:Connect(function()
        set_clipboard(Config.DiscordLink)
        open_url(Config.DiscordLink)
    end)

    VerifyBtn.MouseButton1Click:Connect(function()
        if KeyInput.Text == Config.UserKey then
            StatusText.Text = "✓ 验证成功！正在载入界面..."
            StatusText.TextColor3 = Color3.fromRGB(0, 240, 255)
            SaveKeyData()
            task_wait(0.5)
            KeyFrame:Destroy()
            StartCoreEngine()
        else
            StatusText.Text = "❌ 卡密错误，请重新获取"
            StatusText.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end)
end

local function BuildMainHubUI()
    FloatBall = Instance.new("ImageButton")
    FloatBall.Name = "LuxuryFloatBall"
    FloatBall.Size = UDim2.new(0, 56, 0, 56)
    FloatBall.Position = UDim2.new(0.04, 0, 0.22, 0)
    FloatBall.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    FloatBall.BorderSizePixel = 0
    FloatBall.AutoButtonColor = false
    FloatBall.Active = true
    FloatBall.ZIndex = 10
    FloatBall.Parent = ScreenGui

    -- 尝试加载图片，失败则用 YPX / HUB 两行文字
    local imageLoaded = false
    pcall(function()
        if getcustomasset then
            local imgId = getcustomasset("floatball_icon.jpg")
            if imgId then
                FloatBall.Image = imgId
                imageLoaded = true
            end
        end
    end)
    if not imageLoaded then
        pcall(function()
            if is_file and is_file("floatball_icon.jpg") then
                FloatBall.Image = "rbxasset://floatball_icon.jpg"
                imageLoaded = true
            end
        end)
    end

    if imageLoaded then
        FloatBall.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    else
        -- 无图片：亮色 YPX / HUB 两行文字悬浮球
        FloatBall.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
        FloatBall.Image = ""
        -- 第一行：YPX
        local BallText1 = Instance.new("TextLabel")
        BallText1.Size = UDim2.new(1, 0, 0.5, 0)
        BallText1.Position = UDim2.new(0, 0, 0, 2)
        BallText1.BackgroundTransparency = 1
        BallText1.Text = "YPX"
        BallText1.TextColor3 = Color3.fromRGB(255, 255, 255)
        BallText1.TextSize = 12
        BallText1.Font = Enum.Font.GothamBold
        BallText1.ZIndex = 11
        BallText1.Parent = FloatBall
        -- 第二行：HUB
        local BallText2 = Instance.new("TextLabel")
        BallText2.Size = UDim2.new(1, 0, 0.5, 0)
        BallText2.Position = UDim2.new(0, 0, 0.5, -2)
        BallText2.BackgroundTransparency = 1
        BallText2.Text = "HUB"
        BallText2.TextColor3 = Color3.fromRGB(255, 255, 255)
        BallText2.TextSize = 12
        BallText2.Font = Enum.Font.GothamBold
        BallText2.ZIndex = 11
        BallText2.Parent = FloatBall
    end

    -- 圆角 + 青色描边（始终应用）
    pcall(function()
        local BallCorner = Instance.new("UICorner")
        BallCorner.CornerRadius = UDim.new(1, 0)
        BallCorner.Parent = FloatBall
    end)
    pcall(function()
        local BallStroke = Instance.new("UIStroke")
        BallStroke.Color = Color3.fromRGB(0, 255, 255)
        BallStroke.Thickness = 2.5
        BallStroke.Parent = FloatBall
    end)

    -- 统一拖拽 + 点击处理
    local floatDragging = false
    local floatDragStart, floatStartPos
    local floatMoved = false

    FloatBall.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            floatDragging = true
            floatMoved = false
            floatDragStart = input.Position
            floatStartPos = FloatBall.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    floatDragging = false
                    if not floatMoved then
                        MainFrame.Visible = not MainFrame.Visible
                    end
                end
            end)
        end
    end)

    FloatBall.InputChanged:Connect(function(input)
        if floatDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - floatDragStart
            if math.abs(delta.X) > 2 or math.abs(delta.Y) > 2 then
                floatMoved = true
            end
            FloatBall.Position = UDim2.new(
                floatStartPos.X.Scale,
                floatStartPos.X.Offset + delta.X,
                floatStartPos.Y.Scale,
                floatStartPos.Y.Offset + delta.Y
            )
        end
    end)

    FloatBall.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    MainFrame = Instance.new("Frame")
    MainFrame.Name = "LuxuryMainFrame"
    MainFrame.Size = UDim2.new(0, 360, 0, 380)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(10, 11, 16)
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = true
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 16)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(0, 240, 255)
    MainStroke.Thickness = 1.8
    MainStroke.Parent = MainFrame

    EnableSmoothDrag(MainFrame)

    -- ====== 可拖拽边缘缩放功能 ======
    local function createResizeHandle(name, position, size, cursor)
        local handle = Instance.new("Frame")
        handle.Name = name
        handle.Size = size
        handle.Position = position
        handle.BackgroundTransparency = 1
        handle.BorderSizePixel = 0
        handle.Active = true
        handle.ZIndex = 100
        handle.Parent = MainFrame

        local resizeDrag = false
        local resizeStartPos = nil
        local resizeStartSize = nil

        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                resizeDrag = true
                resizeStartPos = input.Position
                resizeStartSize = MainFrame.AbsoluteSize
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        resizeDrag = false
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if not resizeDrag then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - resizeStartPos
                local newW = math.clamp(resizeStartSize.X + delta.X, 280, 600)
                local newH = math.clamp(resizeStartSize.Y + delta.Y, 280, 700)
                MainFrame.Size = UDim2.new(0, newW, 0, newH)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                resizeDrag = false
            end
        end)
    end

    -- 底部边缘拖拽（调高度）
    createResizeHandle("ResizeBottom", UDim2.new(0, 0, 1, -6), UDim2.new(1, -6, 0, 6), "rbxasset://SystemCursors.ResizeUpDown")
    -- 右侧边缘拖拽（调宽度）
    createResizeHandle("ResizeRight", UDim2.new(1, -6, 0, 0), UDim2.new(0, 6, 1, -6), "rbxasset://SystemCursors.ResizeLeftRight")
    -- 右下角拖拽（同时调宽高）
    createResizeHandle("ResizeCorner", UDim2.new(1, -6, 1, -6), UDim2.new(0, 6, 0, 6), "rbxasset://SystemCursors.ResizeSouthEast")
end

local TitleText
local CreateStandardTab, AddToggle, AddSlider, AddButton, AddCategoryLabel

local function InitUIFactory()
    BuildMainHubUI()

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 46)
    TitleBar.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
    TitleBar.Parent = MainFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 16)
    TitleCorner.Parent = TitleBar

    TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(0.60, 0, 1, 0)
    TitleText.Position = UDim2.new(0.04, 0, 0, 0)
    TitleText.Text = "YPX HUB v" .. Config.HubVersion .. " ( 主面板 )"
    TitleText.TextColor3 = Color3.fromRGB(0, 240, 255)
    TitleText.TextSize = 11
    TitleText.Font = Enum.Font.GothamBold
    TitleText.BackgroundTransparency = 1
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar

    local AuthorText = Instance.new("TextLabel")
    AuthorText.Size = UDim2.new(0.32, 0, 1, 0)
    AuthorText.Position = UDim2.new(0.64, 0, 0, 0)
    AuthorText.Text = "Dev by ypx"
    AuthorText.TextColor3 = Color3.fromRGB(180, 100, 255)
    AuthorText.TextSize = 10
    AuthorText.Font = Enum.Font.GothamMedium
    AuthorText.BackgroundTransparency = 1
    AuthorText.TextXAlignment = Enum.TextXAlignment.Right
    AuthorText.Parent = TitleBar

    -- TabBar 可滚动容器（所有接口分类都能左右滑动查看）
    local TabBarScroller = Instance.new("ScrollingFrame")
    TabBarScroller.Name = "TabBarScroller"
    TabBarScroller.Size = UDim2.new(1, -16, 0, 36)
    TabBarScroller.Position = UDim2.new(0, 8, 0, 52)
    TabBarScroller.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
    TabBarScroller.BorderSizePixel = 0
    TabBarScroller.ScrollBarThickness = 0
    TabBarScroller.ScrollingDirection = Enum.ScrollingDirection.X
    TabBarScroller.ScrollingEnabled = true
    TabBarScroller.CanvasSize = UDim2.new(0, 0, 0, 36)
    TabBarScroller.ClipsDescendants = true
    TabBarScroller.ElasticBehavior = Enum.ElasticBehavior.Never
    TabBarScroller.VerticalScrollBarInset = Enum.ScrollBarInset.None
    TabBarScroller.Selectable = false
    TabBarScroller.Active = true
    -- 自动计算 CanvasSize（核心修复）
    pcall(function()
        TabBarScroller.AutomaticCanvasSize = Enum.AutomaticSize.X
    end)
    TabBarScroller.Parent = MainFrame

    local TabScrollerCorner = Instance.new("UICorner")
    TabScrollerCorner.CornerRadius = UDim.new(0, 8)
    TabScrollerCorner.Parent = TabBarScroller

    -- 内部 TabBar（内容容器，宽度自动增长）
    local TabBar = Instance.new("Frame")
    TabBar.Name = "TabBarInner"
    TabBar.Size = UDim2.new(0, 0, 1, 0)
    TabBar.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = TabBarScroller
    -- 自动扩展宽度以容纳所有标签
    pcall(function()
        TabBar.AutomaticSize = Enum.AutomaticSize.X
    end)

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.Padding = UDim.new(0, 4)
    TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TabLayout.Parent = TabBar

    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingLeft = UDim.new(0, 4)
    TabPadding.PaddingRight = UDim.new(0, 4)
    TabPadding.Parent = TabBar

    -- 自动更新 CanvasSize 以支持滑动（三保险：AutomaticCanvasSize + 事件 + 定时器）
    pcall(function()
        TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            local w = TabLayout.AbsoluteContentSize.X + 8
            if w > 0 then
                TabBarScroller.CanvasSize = UDim2.new(0, w, 0, 36)
                TabBar.Size = UDim2.new(0, w, 1, 0)
            end
        end)
    end)
    -- 定时器兜底：每 0.3 秒检查一次 CanvasSize
    task_spawn(function()
        while true do
            task_wait(0.3)
            pcall(function()
                local w = TabLayout.AbsoluteContentSize.X + 8
                if w > 0 and TabBarScroller.CanvasSize.X.Offset ~= w then
                    TabBarScroller.CanvasSize = UDim2.new(0, w, 0, 36)
                    TabBar.Size = UDim2.new(0, w, 1, 0)
                end
            end)
        end
    end)

    -- 手动刷新 CanvasSize 的公开函数（接口加载完成后调用）
    _G.RefreshTabBarScroll = function()
        pcall(function()
            local w = TabLayout.AbsoluteContentSize.X + 8
            if w > 0 then
                TabBarScroller.CanvasSize = UDim2.new(0, w, 0, 36)
                TabBar.Size = UDim2.new(0, w, 1, 0)
            end
        end)
    end

    local PagesContainer = Instance.new("Frame")
    PagesContainer.Size = UDim2.new(1, -16, 1, -98)
    PagesContainer.Position = UDim2.new(0, 8, 0, 92)
    PagesContainer.BackgroundTransparency = 1
    PagesContainer.Parent = MainFrame

    local tabs = {}
    CreateStandardTab = function(name)
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        pcall(function() page.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Color3.fromRGB(0, 240, 255)
        page.Visible = false
        page.Parent = PagesContainer

        local list = Instance.new("UIListLayout")
        list.Padding = UDim.new(0, 6)
        list.HorizontalAlignment = Enum.HorizontalAlignment.Center
        list.Parent = page

        pcall(function()
            list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 12)
            end)
        end)

        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0, 60, 0.82, 0)
        tabBtn.BackgroundColor3 = Color3.fromRGB(22, 25, 36)
        tabBtn.Text = name
        tabBtn.TextColor3 = Color3.fromRGB(140, 150, 170)
        tabBtn.TextSize = 8.5
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = TabBar

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = tabBtn

        tabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(tabs) do
                t.Page.Visible = false
                t.Button.BackgroundColor3 = Color3.fromRGB(22, 25, 36)
                t.Button.TextColor3 = Color3.fromRGB(140, 150, 170)
            end
            page.Visible = true
            tabBtn.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
            tabBtn.TextColor3 = Color3.fromRGB(10, 10, 15)
        end)

        table.insert(tabs, {Page = page, Button = tabBtn})
        if #tabs == 1 then
            page.Visible = true
            tabBtn.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
            tabBtn.TextColor3 = Color3.fromRGB(10, 10, 15)
        end
        return page
    end

    AddCategoryLabel = function(parent, text)
        local catFrame = Instance.new("Frame")
        catFrame.Size = UDim2.new(1, -6, 0, 28)
        catFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
        catFrame.Parent = parent

        local catCorner = Instance.new("UICorner")
        catCorner.CornerRadius = UDim.new(0, 6)
        catCorner.Parent = catFrame

        local catStroke = Instance.new("UIStroke")
        catStroke.Color = Color3.fromRGB(0, 240, 255)
        catStroke.Transparency = 0.5
        catStroke.Thickness = 1
        catStroke.Parent = catFrame

        local catText = Instance.new("TextLabel")
        catText.Size = UDim2.new(1, -12, 1, 0)
        catText.Position = UDim2.new(0, 6, 0, 0)
        catText.Text = "📌 " .. text
        catText.TextColor3 = Color3.fromRGB(0, 240, 255)
        catText.TextSize = 10
        catText.Font = Enum.Font.GothamBold
        catText.BackgroundTransparency = 1
        catText.TextXAlignment = Enum.TextXAlignment.Left
        catText.Parent = catFrame
    end

    AddToggle = function(parent, text, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -6, 0, 44)
        frame.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
        frame.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.72, 0, 1, 0)
        label.Position = UDim2.new(0.04, 0, 0, 0)
        label.Text = text
        label.TextColor3 = Color3.fromRGB(230, 235, 245)
        label.TextSize = 9.5
        label.Font = Enum.Font.GothamMedium
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 40, 0, 20)
        btn.Position = UDim2.new(1, -46, 0.5, -10)
        btn.Text = ""
        btn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
        btn.Parent = frame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(1, 0)
        btnCorner.Parent = btn

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 14, 0, 14)
        dot.Position = UDim2.new(0, 3, 0.5, -7)
        dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        dot.Parent = btn

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot

        local state = false
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(35, 40, 55)
            dot.Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            task_spawn(function()
                pcall(callback, state)
            end)
        end)
    end

    AddSlider = function(parent, text, minVal, maxVal, defaultVal, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -6, 0, 50)
        frame.BackgroundColor3 = Color3.fromRGB(16, 19, 28)
        frame.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -16, 0, 20)
        label.Position = UDim2.new(0, 8, 0, 4)
        label.Text = text .. " : " .. tostring(defaultVal)
        label.TextColor3 = Color3.fromRGB(230, 235, 245)
        label.TextSize = 10
        label.Font = Enum.Font.GothamMedium
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local bar = Instance.new("TextButton")
        bar.Size = UDim2.new(1, -16, 0, 8)
        bar.Position = UDim2.new(0, 8, 0, 30)
        bar.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
        bar.Text = ""
        bar.AutoButtonColor = false
        bar.Parent = frame

        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(1, 0)
        barCorner.Parent = bar

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
        fill.Parent = bar

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill

        local sliding = false
        local function Update(input)
            local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(minVal + (maxVal - minVal) * pos)
            fill.Size = UDim2.new(pos, 0, 1, 0)
            label.Text = text .. " : " .. tostring(val)
            task_spawn(function()
                pcall(callback, val)
            end)
        end

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                Update(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                Update(input)
            end
        end)
    end

    AddButton = function(parent, text, bgColor, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -6, 0, 38)
        btn.BackgroundColor3 = bgColor or Color3.fromRGB(30, 35, 50)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 10
        btn.Font = Enum.Font.GothamBold
        btn.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            task_spawn(function()
                pcall(callback)
            end)
        end)
        return btn
    end
end

-- ===================================================
-- 【接口 1】：通用功能模块 (Universal Mods)
-- ===================================================
local function LoadUniversalInterface()
    ShowToast("UNIVERSAL MODS ( 通用功能 )")
    TitleText.Text = "UNIVERSAL MODS ( 通用功能 )"
    
    local PagePlayer = CreateStandardTab("👤 角色")
    local PageMovement = CreateStandardTab("🏃 移动")
    local PageVisual = CreateStandardTab("👁️ 视觉")

    AddSlider(PagePlayer, "WalkSpeed ( 移动速度 )", 16, 300, 16, function(val)
        local char = LocalPlayer and LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = val
        end
    end)

    AddSlider(PagePlayer, "JumpPower ( 跳跃高度 )", 50, 300, 50, function(val)
        local char = LocalPlayer and LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = val
            char.Humanoid.UseJumpPower = true
        end
    end)

    AddToggle(PagePlayer, "Infinite Jump ( 无限连跳 )", function(val)
        _G.InfJumpYpx = val
        if not _G.InfJumpConn then
            _G.InfJumpConn = UserInputService.JumpRequest:Connect(function()
                if _G.InfJumpYpx then
                    local char = LocalPlayer and LocalPlayer.Character
                    if char and char:FindFirstChild("Humanoid") then
                        char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        end
    end)

    AddToggle(PagePlayer, "Anti-AFK ( 防挂机踢出 )", function(val)
        _G.AntiAfkYpx = val
        task_spawn(function()
            while _G.AntiAfkYpx do
                if VirtualUser then
                    pcall(function() VirtualUser:CaptureController() end)
                    pcall(function() VirtualUser:ClickButton2(Vector2.new()) end)
                end
                task_wait(30)
            end
        end)
    end)

    AddToggle(PageMovement, "Noclip ( 角色穿墙 )", function(val)
        _G.NoclipYpx = val
        task_spawn(function()
            while _G.NoclipYpx do
                local char = LocalPlayer and LocalPlayer.Character
                if char then
                    for _, part in pairs(char:GetChildren()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
                task_wait(0.1)
            end
        end)
    end)

    AddToggle(PageMovement, "Touch Fly ( 手机端触控飞行 )", function(val)
        _G.FlyingYpx = val
        local char = LocalPlayer and LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        if _G.FlyingYpx then
            local bv = Instance.new("BodyVelocity")
            bv.Name = "YpxFlyBV"
            bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = hrp
            
            task_spawn(function()
                while _G.FlyingYpx and hrp:FindFirstChild("YpxFlyBV") do
                    local cam = Workspace.CurrentCamera
                    hrp.YpxFlyBV.Velocity = cam.CFrame.LookVector * 50
                    task_wait(0.02)
                end
                if hrp:FindFirstChild("YpxFlyBV") then hrp.YpxFlyBV:Destroy() end
            end)
        else
            if hrp:FindFirstChild("YpxFlyBV") then hrp.YpxFlyBV:Destroy() end
        end
    end)

    AddSlider(PageVisual, "Field of View ( 广角视野 )", 70, 120, 70, function(val)
        Workspace.CurrentCamera.FieldOfView = val
    end)

    -- 刷新 TabBar 滚动（确保所有分类可左右滑动）
    pcall(function() _G.RefreshTabBarScroll() end)
end

-- ===================================================
-- Toast 通知系统（右下角弹出）
-- 每次启动接口时显示：欢迎使用 YPX HUB → 接口名称卡片
-- ===================================================
local function ShowToast(interfaceName)
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(0, 220, 0, 50)
    toast.Position = UDim2.new(1, -230, 1, -80)
    toast.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
    toast.BorderSizePixel = 0
    toast.BackgroundTransparency = 1
    toast.ZIndex = 999
    toast.Parent = ScreenGui

    pcall(function()
        local tc = Instance.new("UICorner")
        tc.CornerRadius = UDim.new(0, 10)
        tc.Parent = toast
    end)
    pcall(function()
        local ts = Instance.new("UIStroke")
        ts.Color = Color3.fromRGB(0, 240, 255)
        ts.Thickness = 1.5
        ts.Parent = toast
    end)

    local toastLabel = Instance.new("TextLabel")
    toastLabel.Size = UDim2.new(1, 0, 1, 0)
    toastLabel.BackgroundTransparency = 1
    toastLabel.Text = "欢迎使用 YPX HUB"
    toastLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    toastLabel.TextSize = 14
    toastLabel.Font = Enum.Font.GothamBold
    toastLabel.ZIndex = 1000
    toastLabel.Parent = toast

    -- 渐入动画
    toast.BackgroundTransparency = 1
    toastLabel.TextTransparency = 1
    local tweenSvc = nil
    pcall(function() tweenSvc = game:GetService("TweenService") end)

    if tweenSvc then
        local fadeIn = tweenSvc:Create(toast, TweenInfo.new(0.4), {BackgroundTransparency = 0.15})
        local textIn = tweenSvc:Create(toastLabel, TweenInfo.new(0.4), {TextTransparency = 0})
        fadeIn:Play()
        textIn:Play()
    else
        toast.BackgroundTransparency = 0.15
        toastLabel.TextTransparency = 0
    end

    -- 2.5 秒后切换为接口名称
    task_spawn(function()
        task_wait(2.5)
        pcall(function()
            toastLabel.Text = interfaceName or "YPX HUB"
            toastLabel.TextColor3 = Color3.fromRGB(0, 240, 255)
            toastLabel.TextSize = 12
        end)
        -- 再过 2 秒消失
        task_wait(2)
        pcall(function()
            if tweenSvc then
                local fadeOut = tweenSvc:Create(toast, TweenInfo.new(0.5), {BackgroundTransparency = 1})
                local textOut = tweenSvc:Create(toastLabel, TweenInfo.new(0.5), {TextTransparency = 1})
                fadeOut:Play()
                fadeOut.Completed:Connect(function()
                    pcall(function() toast:Destroy() end)
                end)
            else
                toast:Destroy()
            end
        end)
    end)
end

-- ===================================================
-- 【接口 2】：Anime Incremental 专用接口 (原封不动隔离)
-- ===================================================
local function LoadAnimeIncrementalInterface()
    ShowToast("ANIME INCREMENTAL ( 动漫增量 )")
    TitleText.Text = "ANIME INCREMENTAL ( 动漫增量 )"

    local function GetRemotesFolder()
        local packages = ReplicatedStorage:FindFirstChild("Packages")
        if packages and packages:FindFirstChild("_Index") then
            for _, child in pairs(packages._Index:GetChildren()) do
                if string.find(child.Name, "networker") and child:FindFirstChild("networker") then
                    local remotes = child.networker:FindFirstChild("_remotes")
                    if remotes then return remotes end
                end
            end
        end
        return nil
    end

    local RemotesPath = GetRemotesFolder()

    local function GetRemote(sName, isFunc)
        if not RemotesPath then RemotesPath = GetRemotesFolder() end
        if RemotesPath then
            local s = RemotesPath:FindFirstChild(sName)
            if s then return isFunc and s:FindFirstChild("RemoteFunction") or s:FindFirstChild("RemoteEvent") end
        end
        return nil
    end

    local PageMain = CreateStandardTab("⚡ 挂机")
    local PagePotions = CreateStandardTab("🧪 药水")
    local PageUpgrades = CreateStandardTab("📈 属性")
    local PagePuppets = CreateStandardTab("🎭 傀儡")
    local PageClones = CreateStandardTab("👥 分身")
    local PageCards = CreateStandardTab("🎴 卡包")
    local PageNinja = CreateStandardTab("👁️ 血统")
    local PageTeleport = CreateStandardTab("📍 传送")

    AddToggle(PageMain, "ClickerService ( 自动点击器 )", function(val)
        local r = GetRemote("ClickerService", false)
        if r then r:FireServer("SetAutoClickEnabled", val) end
    end)

    AddToggle(PageMain, "ConvertMax ( 自动最大化转换能量 )", function(val)
        _G.AutoConvertMaxypx = val
        task_spawn(function()
            while _G.AutoConvertMaxypx do
                local r = GetRemote("CondensedEnergyService", false)
                if r then pcall(function() r:FireServer("ConvertMax") end) end
                task_wait(0.1)
            end
        end)
    end)

    AddToggle(PageMain, "PickupAura & Orb ( 自动收集光环 )", function(val)
        _G.AutoOrbAuraypx = val
        task_spawn(function()
            while _G.AutoOrbAuraypx do
                local orb = GetRemote("OrbService", false)
                local aura = GetRemote("PickupAuraService", false)
                if orb then pcall(function() orb:FireServer() end) end
                if aura then pcall(function() aura:FireServer() end) end
                task_wait(0.05)
            end
        end)
    end)

    -- 区域能量收集：开局指定区域循环收集能量/星星等散落物
    AddToggle(PageMain, "Area Energy Collect ( 区域能量收集 )", function(val)
        _G.AreaEnergyCollect = val
        if not val then return end
        task_spawn(function()
            local areaCenter = nil
            local areaRadius = 60
            local collectedSet = {}
            local roundCount = 0

            -- 噪声名字过滤
            local noiseNames = {
                ["Terrain"]=true,["Baseplate"]=true,["Floor"]=true,["Wall"]=true,
                ["Ground"]=true,["Handle"]=true,["Part"]=true,["MeshPart"]=true,
                ["HumanoidRootPart"]=true,["Head"]=true,["Torso"]=true,
                ["SpawnLocation"]=true,["Spawn"]=true,["Platform"]=true,
            }

            while _G.AreaEnergyCollect do
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then
                    task_wait(0.5)
                else

                -- 首次确定区域中心
                if not areaCenter then
                    areaCenter = char.HumanoidRootPart.Position
                end

                -- 扫描区域内小物件
                local items = {}
                pcall(function()
                    for _, obj in pairs(Workspace:GetDescendants()) do
                        if obj:IsA("BasePart") then
                            local name = obj.Name
                            if not noiseNames[name] then
                                local sz = obj.Size
                                if not (sz.X > 10 or sz.Y > 10 or sz.Z > 10) then
                                    if not (sz.X < 0.1 and sz.Y < 0.1 and sz.Z < 0.1) then
                                        local dist = (obj.Position - areaCenter).Magnitude
                                        if not (dist > areaRadius) then
                                            -- 排除玩家角色
                                            if not (obj.Parent and obj.Parent:IsA("Model") and obj.Parent:FindFirstChild("Humanoid")) then
                                                if not (obj.Anchored and sz.X > 5) then
                                                    table.insert(items, {Name = name, Position = obj.Position})
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)

                -- 过滤已收集
                local newItems = {}
                for _, item in ipairs(items) do
                    local key = item.Name .. "_" .. string.format("%.1f,%.1f,%.1f", item.Position.X, item.Position.Y, item.Position.Z)
                    if not collectedSet[key] then
                        table.insert(newItems, item)
                    end
                end

                if #newItems == 0 then
                    roundCount = roundCount + 1
                    if roundCount >= 8 then
                        roundCount = 0
                        collectedSet = {}
                    end
                    task_wait(2)
                else
                    roundCount = 0
                    for _, item in ipairs(newItems) do
                        if not _G.AreaEnergyCollect then break end
                        pcall(function()
                            local c = LocalPlayer.Character
                            if c and c:FindFirstChild("HumanoidRootPart") then
                                c.HumanoidRootPart.CFrame = CFrame.new(item.Position) + Vector3.new(0, 3, 0)
                            end
                        end)
                        task_wait(0.08)
                        local key = item.Name .. "_" .. string.format("%.1f,%.1f,%.1f", item.Position.X, item.Position.Y, item.Position.Z)
                        collectedSet[key] = true
                    end
                    task_wait(0.3)
                end
                end
            end
        end)
    end)

    AddToggle(PageMain, "AntiAfkService ( 防挂机踢出 )", function(val)
        _G.AntiAfkypx = val
        task_spawn(function()
            while _G.AntiAfkypx do
                local r = GetRemote("AntiAfkService", false)
                if r then pcall(function() r:FireServer() end) end
                if VirtualUser then
                    pcall(function() VirtualUser:CaptureController() end)
                    pcall(function() VirtualUser:ClickButton2(Vector2.new()) end)
                end
                task_wait(30)
            end
        end)
    end)

    local potionList = {
        {"CardLuckPotion", "🍀 Card Luck Potion ( 抽卡幸运 )"},
        {"CardBulkPotion", "📦 Card Bulk Potion ( 抽卡数量 )"},
        {"CardSpeedPotion", "⚡ Card Speed Potion ( 抽卡速度 )"},
        {"WalkspeedPotion", "🏃 Walkspeed Potion ( 角色移速 )"}
    }

    AddToggle(PagePotions, "🔥 Use All Potions ( 全药水自动连用 )", function(val)
        _G.AutoUseAllPotionsypx = val
        task_spawn(function()
            while _G.AutoUseAllPotionsypx do
                local inventoryFunc = GetRemote("InventoryService", true)
                if inventoryFunc then
                    for _, p in ipairs(potionList) do pcall(function() inventoryFunc:InvokeServer("UseItem", p[1], 1) end) end
                end
                task_wait(1)
            end
        end)
    end)

    for _, p in ipairs(potionList) do
        local id, name = p[1], p[2]
        AddToggle(PagePotions, "Auto Potion : " .. name, function(val)
            _G["AutoPot_" .. id] = val
            task_spawn(function()
                while _G["AutoPot_" .. id] do
                    local inventoryFunc = GetRemote("InventoryService", true)
                    if inventoryFunc then pcall(function() inventoryFunc:InvokeServer("UseItem", id, 1) end) end
                    task_wait(1)
                end
            end)
        end)
    end

    local upgradeList = {
        {"NatureMultiplier", "Nature Multiplier ( 自然能量倍率 )"},
        {"NatureChakraMultiplier", "Chakra Multiplier ( 自然查克拉倍率 )"},
        {"NatureExperienceMultiplier", "Nature Exp Multiplier ( 自然经验倍率 )"},
        {"ClickerMultiplier", "Clicker Multiplier ( 基础点击倍率 )"},
        {"DailyClickerMultiplier", "Daily Clicker Multiplier ( 每日点击倍率 )"},
        {"DailyMeditationMultiplier", "Daily Meditation Multiplier ( 每日冥想倍率 )"},
        {"CondensedExperienceMultiplier", "Condensed Exp Multiplier ( 凝聚经验倍率 )"},
        {"CondensedNatureMultiplier", "Condensed Nature Multiplier ( 凝聚自然倍率 )"},
        {"MeditationGain", "Meditation Gain ( 冥想收益增幅 )"},
        {"MeditationExperienceInsight", "Meditation Exp Insight ( 冥想经验洞察 )"},
        {"MeditationAdventureDamage", "Meditation Adventure Damage ( 冥想冒险伤害 )"},
        {"LevelAdventureDamage", "Level Adventure Damage ( 等级冒险伤害 )"},
        {"BaseAdventureDamage", "Adventure Damage ( 基础冒险伤害 )"},
        {"AdventureDamage", "Adventure Damage Alt ( 冒险伤害备用 )"},
        {"SkillMeditationFocus", "Skill Meditation Focus ( 技能冥想专注 )"},
        {"LevelClickerPower", "Level Clicker Power ( 等级点击力量 )"},
        {"LevelEyeSpeed", "Level Eye Speed ( 等级瞳术速度 )"},
        {"LevelEyeLuck", "Level Eye Luck ( 等级瞳术幸运 )"}
    }

    AddToggle(PageUpgrades, "🔥 Max All Upgrades ( 一键极速属性拉满 )", function(val)
        _G.AutoUpgradeAllypx = val
        task_spawn(function()
            while _G.AutoUpgradeAllypx do
                local upgradeRemote = GetRemote("UpgradeService", true)
                if upgradeRemote then
                    for _, item in ipairs(upgradeList) do
                        pcall(function()
                            upgradeRemote:InvokeServer("AttemptUpgrade", item[1], 4)
                        end)
                    end
                end
                task_wait(0.02)
            end
        end)
    end)

    AddToggle(PageUpgrades, "LevelUp Service ( 自动提升角色等级 )", function(val)
        _G.AutoLevelUpypx = val
        task_spawn(function()
            while _G.AutoLevelUpypx do
                local levelRemote = GetRemote("LevelService", true) or GetRemote("LevelService", false)
                if levelRemote then
                    pcall(function()
                        if levelRemote:IsA("RemoteFunction") then levelRemote:InvokeServer("LevelUp")
                        else levelRemote:FireServer("LevelUp") end
                    end)
                end
                task_wait(0.1)
            end
        end)
    end)

    AddButton(PageUpgrades, "⚠️ Reset Hourglass Upgrades ( 重置沙漏升级 )", Color3.fromRGB(180, 50, 50), function()
        local upgradeRemote = GetRemote("UpgradeService", true)
        if upgradeRemote then upgradeRemote:InvokeServer("ResetHourglassUpgrades") end
    end)

    for _, item in ipairs(upgradeList) do
        local key, name = item[1], item[2]
        AddToggle(PageUpgrades, "Auto Upgrade : " .. name, function(val)
            _G["AutoUp_" .. key] = val
            task_spawn(function()
                while _G["AutoUp_" .. key] do
                    local upgradeRemote = GetRemote("UpgradeService", true)
                    if upgradeRemote then pcall(function() upgradeRemote:InvokeServer("AttemptUpgrade", key, 4) end) end
                    task_wait(0.02)
                end
            end)
        end)
    end

    AddToggle(PagePuppets, "PuppetShop ( 自动购买/升级傀儡 )", function(val)
        _G.AutoPuppetypx = val
        task_spawn(function()
            while _G.AutoPuppetypx do
                local puppetFunc = GetRemote("PuppetShopService", true) or GetRemote("BijuuPuppetService", true)
                if puppetFunc then
                    pcall(function() puppetFunc:InvokeServer("BuyBestPuppet") end)
                end
                task_wait(0.2)
            end
        end)
    end)

    AddToggle(PageClones, "ShadowClone ( 自动召唤影分身 )", function(val)
        _G.AutoCloneypx = val
        task_spawn(function()
            while _G.AutoCloneypx do
                local cloneRemote = GetRemote("ShadowCloneService", false) or GetRemote("ShadowCloneService", true)
                if cloneRemote then
                    pcall(function() 
                        if cloneRemote:IsA("RemoteFunction") then cloneRemote:InvokeServer("SpawnClone") 
                        else cloneRemote:FireServer("SpawnClone") end 
                    end)
                end
                task_wait(0.5)
            end
        end)
    end)

    AddToggle(PageCards, "CardPackService ( 全卡包后台自动抽卡 )", function(val)
        _G.AutoCardPackypx = val
        task_spawn(function()
            local packNames = {"Shinobi Starter Pack", "Rogue Shadows Pack", "Starter", "Basic", "Advanced", "World2"}
            while _G.AutoCardPackypx do
                local cardRemote = GetRemote("CardPackService", false)
                local cardFunc = GetRemote("CardPackService", true)
                pcall(function()
                    for _, p in ipairs(packNames) do
                        if cardRemote then cardRemote:FireServer("Buy", p, 18); cardRemote:FireServer("Open", p, 18) end
                        if cardFunc then cardFunc:InvokeServer("Buy", p, 18) end
                    end
                end)
                task_wait(0.05)
            end
        end)
    end)

    AddToggle(PageNinja, "BloodlineService ( 自动重抽血统 )", function(val)
        _G.AutoBloodlineypx = val
        task_spawn(function()
            while _G.AutoBloodlineypx do
                local r = GetRemote("BloodlineService", true) or GetRemote("BloodlineService", false)
                if r then pcall(function() if r:IsA("RemoteFunction") then r:InvokeServer("RequestRerollBloodline") else r:FireServer("RequestRerollBloodline") end end) end
                task_wait(0.1)
            end
        end)
    end)

    AddToggle(PageNinja, "EyeService ( 自动重抽瞳术 )", function(val)
        _G.AutoEyeypx = val
        task_spawn(function()
            while _G.AutoEyeypx do
                local r = GetRemote("EyeService", true) or GetRemote("EyeService", false)
                if r then pcall(function() if r:IsA("RemoteFunction") then r:InvokeServer("RequestRerollEye") else r:FireServer("RequestRerollEye") end end) end
                task_wait(0.1)
            end
        end)
    end)

    AddButton(PageTeleport, "🔄 Scan Map & Stations ( 智能扫描地图传送点 )", Color3.fromRGB(0, 150, 200), function()
        for _, child in pairs(PageTeleport:GetChildren()) do 
            if child:IsA("Frame") and child.Name == "PackItem" then 
                child:Destroy() 
            end 
        end

        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (string.find(obj.Name, "Pack") or string.find(obj.Name, "Platform") or string.find(obj.Name, "Starter") or string.find(obj.Name, "Stage") or string.find(obj.Name, "Adventure")) then
                local packFrame = Instance.new("Frame")
                packFrame.Name = "PackItem"
                packFrame.Size = UDim2.new(1, -6, 0, 40)
                packFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
                packFrame.Parent = PageTeleport
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 8)
                corner.Parent = packFrame
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.60, 0, 1, 0)
                label.Position = UDim2.new(0.04, 0, 0, 0)
                label.Text = "📍 " .. obj.Name
                label.TextColor3 = Color3.fromRGB(230, 235, 245)
                label.TextSize = 10
                label.Font = Enum.Font.GothamMedium
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.BackgroundTransparency = 1
                label.Parent = packFrame
                
                local tpBtn = Instance.new("TextButton")
                tpBtn.Size = UDim2.new(0.32, 0, 0.75, 0)
                tpBtn.Position = UDim2.new(0.64, 0, 0.125, 0)
                tpBtn.BackgroundColor3 = Color3.fromRGB(0, 240, 255)
                tpBtn.Text = "Teleport ( 传送 )"
                tpBtn.TextColor3 = Color3.fromRGB(10, 10, 15)
                tpBtn.TextSize = 9
                tpBtn.Font = Enum.Font.GothamBold
                tpBtn.Parent = packFrame
                
                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 6)
                bCorner.Parent = tpBtn
                
                tpBtn.MouseButton1Click:Connect(function()
                    local char = LocalPlayer and LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        char.HumanoidRootPart.CFrame = obj.CFrame + Vector3.new(0, 3, 0)
                    end
                end)
            end
        end
    end)

    -- 刷新 TabBar 滚动（确保所有分类可左右滑动）
    pcall(function() _G.RefreshTabBarScroll() end)
end

-- ===================================================
-- 【接口 3】：Resource Incremental 专用接口
-- ===================================================
local function LoadResourceIncrementalInterface()
    ShowToast("RESOURCE INCREMENTAL ( 资源增量 )")
    TitleText.Text = "RESOURCE INCREMENTAL ( 资源增量 )"

    local PageFarm = CreateStandardTab("⚙️ 挂机")
    local PageUpgrades = CreateStandardTab("📈 升级")
    local PageSummer = CreateStandardTab("☀️ 夏日")
    local PageTeleport = CreateStandardTab("📍 传送")

    -- ==================== 挂机页 ====================
    -- 1. 自动化采集与散落物收集（指定区域循环收集）
    AddCategoryLabel(PageFarm, "自动化采集与散落物收集")

    -- 游戏实际散落物名字（截图确认：Pine / Screw / Gear / Pipe）
    local SCRAP_ITEM_NAMES = {"Pine", "Screw", "Gear", "Pipe", "Nut"}
    local SCRAP_AREA_RADIUS = 80  -- 收集区域半径

    -- 区域扫描：只扫描玩家周围指定区域内的散落物
    local function scanAreaScrapItems(center, radius)
        local items = {}
        pcall(function()
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local name = obj.Name
                    -- 精确匹配散落物名字
                    local isScrap = false
                    for _, sn in ipairs(SCRAP_ITEM_NAMES) do
                        if name == sn then isScrap = true; break end
                    end
                    -- 检查父级名字
                    if not isScrap and obj.Parent then
                        local pname = obj.Parent.Name
                        for _, sn in ipairs(SCRAP_ITEM_NAMES) do
                            if pname == sn then isScrap = true; break end
                        end
                    end
                    if isScrap then
                        -- 距离过滤：只在指定区域内收集
                        local dist = (obj.Position - center).Magnitude
                        if dist <= radius then
                            -- 尺寸过滤
                            local sz = obj.Size
                            if not (sz.X > 15 or sz.Y > 15 or sz.Z > 15) then
                                if not (sz.X < 0.05 and sz.Y < 0.05 and sz.Z < 0.05) then
                                    table.insert(items, {Name = name, Position = obj.Position})
                                end
                            end
                        end
                    end
                end
            end
        end)
        return items
    end

    -- 自动收集散落物（指定区域循环：扫描 → 传送触碰 → 循环）
    AddToggle(PageFarm, "Auto Collect Scrap ( 自动扫描收集散落物 )", function(val)
        _G.AutoCollectScrapx = val
        if not val then return end
        task_spawn(function()
            local collectedSet = {}
            local roundCount = 0
            local areaCenter = nil  -- 首次运行时确定区域中心

            while _G.AutoCollectScrapx do
                -- 确定区域中心：以玩家当前位置为基准
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    if not areaCenter then
                        areaCenter = char.HumanoidRootPart.Position
                    end
                    local items = scanAreaScrapItems(areaCenter, SCRAP_AREA_RADIUS)
                    local newItems = {}
                    for _, item in ipairs(items) do
                        local key = item.Name .. "_" .. string.format("%.1f,%.1f,%.1f", item.Position.X, item.Position.Y, item.Position.Z)
                        if not collectedSet[key] then
                            table.insert(newItems, item)
                        end
                    end

                    if #newItems == 0 then
                        roundCount = roundCount + 1
                        if roundCount >= 5 then
                            roundCount = 0
                            collectedSet = {}  -- 快速重置记录，散落物已刷新
                        end
                        task_wait(0.3)
                    else
                        roundCount = 0
                        for _, item in ipairs(newItems) do
                            if not _G.AutoCollectScrapx then break end
                            pcall(function()
                                local c = LocalPlayer.Character
                                if c and c:FindFirstChild("HumanoidRootPart") then
                                    c.HumanoidRootPart.CFrame = CFrame.new(item.Position) + Vector3.new(0, 3, 0)
                                end
                            end)
                            task_wait(0.02)
                            local key = item.Name .. "_" .. string.format("%.1f,%.1f,%.1f", item.Position.X, item.Position.Y, item.Position.Z)
                            collectedSet[key] = true
                        end
                        task_wait(0.05)
                    end
                else
                    task_wait(0.5)
                end
            end
        end)
    end)

    AddToggle(PageFarm, "Auto Convert Cash ( 自动现金转换 )", function(val)
        _G.AutoConvertCashx = val
        if not val then return end
        task_spawn(function()
            while _G.AutoConvertCashx do
                pcall(function()
                    local ev = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Features") and ReplicatedStorage.Remotes.Features:FindFirstChild("ConvertCash")
                    if ev then ev:FireServer() end
                end)
                task_wait(0.5)
            end
        end)
    end)

    -- 传送 Obby 循环
    AddToggle(PageFarm, "Auto Teleport Obby ( 自动传送 Obby )", function(val)
        _G.AutoTeleportObby = val
        if not val then return end
        task_spawn(function()
            while _G.AutoTeleportObby do
                pcall(function()
                    local ev = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Others") and ReplicatedStorage.Remotes.Others:FindFirstChild("Teleport")
                    if ev then ev:FireServer("Obby") end
                end)
                task_wait(0.5)
            end
        end)
    end)

    -- 群组与互动按钮
    AddCategoryLabel(PageFarm, "互动与社群")

    AddButton(PageFarm, "🔗 Copy Group Link ( 复制群组链接 )", Color3.fromRGB(60, 140, 200), function()
        if set_clipboard then
            set_clipboard("https://www.roblox.com/communities/381196760")
        end
    end)

    -- ==================== 升级页 ====================
    AddCategoryLabel(PageUpgrades, "Shells / 现金 / 钻石 / 升级树")

    AddToggle(PageUpgrades, "Auto Shells Upgrade ( 自动贝壳升级循环 )", function(val)
        _G.AutoShellsUpgrade = val
        if not val then return end
        task_spawn(function()
            while _G.AutoShellsUpgrade do
                pcall(function()
                    local upg = ReplicatedStorage.Remotes.Others.Upgrades
                    for i = 1, 4 do upg:FireServer("ShellsUpgrade" .. i, "Max") end
                end)
                task_wait(0.05)
            end
        end)
    end)

    AddToggle(PageUpgrades, "Auto Cash Upgrade ( 自动现金升级循环 )", function(val)
        _G.AutoCashUpgrade = val
        if not val then return end
        task_spawn(function()
            while _G.AutoCashUpgrade do
                pcall(function()
                    local upg = ReplicatedStorage.Remotes.Others.Upgrades
                    for i = 1, 3 do upg:FireServer("CashUpgrade" .. i, "Max") end
                end)
                task_wait(0.05)
            end
        end)
    end)

    AddToggle(PageUpgrades, "Auto Rebirth Upgrade ( 自动转生升级循环 )", function(val)
        _G.AutoRebirthUpgrade = val
        if not val then return end
        task_spawn(function()
            while _G.AutoRebirthUpgrade do
                pcall(function()
                    local upg = ReplicatedStorage.Remotes.Others.Upgrades
                    for i = 1, 3 do upg:FireServer("RebirthUpgrade" .. i, "Max") end
                end)
                task_wait(0.05)
            end
        end)
    end)

    AddToggle(PageUpgrades, "Auto Diamond Upgrade 1 ( 自动钻石升级1循环 )", function(val)
        _G.AutoDiamondUpgrade = val
        if not val then return end
        task_spawn(function()
            while _G.AutoDiamondUpgrade do
                pcall(function() ReplicatedStorage.Remotes.Others.Upgrades:FireServer("DiamondUpgrade1", "Max") end)
                task_wait(0.05)
            end
        end)
    end)

    AddToggle(PageUpgrades, "Auto Diamond Upgrade 2 ( 自动钻石升级2循环 )", function(val)
        _G.AutoDiamondUpgrade2 = val
        if not val then return end
        task_spawn(function()
            while _G.AutoDiamondUpgrade2 do
                pcall(function() ReplicatedStorage.Remotes.Others.Upgrades:FireServer("DiamondUpgrade2", "Max") end)
                task_wait(0.05)
            end
        end)
    end)

    AddToggle(PageUpgrades, "Auto UpgradeTree Upg1 ( 自动升级树 Upg1 )", function(val)
        _G.AutoUpgradeTree = val
        if not val then return end
        task_spawn(function()
            while _G.AutoUpgradeTree do
                pcall(function()
                    local ev = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Features") and ReplicatedStorage.Remotes.Features:FindFirstChild("UpgradeTree")
                    if ev then ev:FireServer("Upg1") end
                end)
                task_wait(0.05)
            end
        end)
    end)

    AddButton(PageUpgrades, "✨ Trigger Rebirth Reset ( 一键触发转生 )", Color3.fromRGB(200, 40, 40), function()
        pcall(function() ReplicatedStorage.Remotes.Others.ResetLayers:FireServer("Rebirth") end)
    end)

    -- ==================== 夏日活动页 ====================
    AddCategoryLabel(PageSummer, "夏日活动功能 ( 待添加 )")

    -- ==================== 传送页 ====================
    AddCategoryLabel(PageTeleport, "💪 力量训练 (Strength Bench)")

    local StrengthBenches = {
        {name = "Bench #1", pos = Vector3.new(-194.37643432617, 3.7239301204681, 25.601934432983)},
        {name = "Bench #2", pos = Vector3.new(-194.37643432617, 3.7239301204681, 35.59407043457)},
        {name = "Bench #3", pos = Vector3.new(-194.37643432617, 3.7239301204681, 45.62659072876)},
        {name = "Bench #4", pos = Vector3.new(-194.37643432617, 3.7239301204681, 55.659671783447)},
        {name = "Bench #5", pos = Vector3.new(-194.37643432617, 3.7239301204681, 65.652656555176)},
        {name = "Bench #6", pos = Vector3.new(-194.37643432617, 3.7239301204681, 75.705230712891)},
    }

    local SpeedTreadmills = {
        {name = "Treadmill #1", pos = Vector3.new(-194.8187713623, 1.4777241945267, 86.50944519043)},
        {name = "Treadmill #2", pos = Vector3.new(-194.8187713623, 1.4777241945267, 95.50944519043)},
        {name = "Treadmill #3", pos = Vector3.new(-194.8187713623, 1.4777241945267, 104.50944519043)},
        {name = "Treadmill #4", pos = Vector3.new(-194.8187713623, 1.4777241945267, 113.50944519043)},
        {name = "Treadmill #5", pos = Vector3.new(-194.8187713623, 1.4777241945267, 122.50944519043)},
        {name = "Treadmill #6", pos = Vector3.new(-194.8187713623, 1.4777241945267, 131.50944519043)},
    }

    local BrainMeditations = {
        {name = "Meditation #1", pos = Vector3.new(-246.2063293457, 1.0764456987381, 127.2932434082)},
        {name = "Meditation #2", pos = Vector3.new(-254.20634460449, 1.0765010118484, 127.29277038574)},
        {name = "Meditation #3", pos = Vector3.new(-263.20635986328, 1.0764456987381, 127.2932434082)},
        {name = "Meditation #4", pos = Vector3.new(-272.20635986328, 1.0764456987381, 127.2932434082)},
        {name = "Meditation #5", pos = Vector3.new(-281.20635986328, 1.0764456987381, 127.2932434082)},
    }

    for _, bench in ipairs(StrengthBenches) do
        AddToggle(PageTeleport, "🏋️ " .. bench.name, function(val)
            _G["TeleportStrength" .. bench.name] = val
            if not val then return end
            task_spawn(function()
                while _G["TeleportStrength" .. bench.name] do
                    pcall(function()
                        local char = LocalPlayer and LocalPlayer.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = CFrame.new(bench.pos) + Vector3.new(0, 3, 0)
                        end
                    end)
                    task_wait(0.5)
                end
            end)
        end)
    end

    AddCategoryLabel(PageTeleport, "🏃 速度训练 (Speed Treadmill)")
    for _, mill in ipairs(SpeedTreadmills) do
        AddToggle(PageTeleport, "🏃 " .. mill.name, function(val)
            _G["TeleportSpeed" .. mill.name] = val
            if not val then return end
            task_spawn(function()
                while _G["TeleportSpeed" .. mill.name] do
                    pcall(function()
                        local char = LocalPlayer and LocalPlayer.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = CFrame.new(mill.pos) + Vector3.new(0, 3, 0)
                        end
                    end)
                    task_wait(0.5)
                end
            end)
        end)
    end

    AddCategoryLabel(PageTeleport, "🧠 冥想训练 (Brain Meditation)")
    for _, med in ipairs(BrainMeditations) do
        AddToggle(PageTeleport, "🧘 " .. med.name, function(val)
            _G["TeleportMeditation" .. med.name] = val
            if not val then return end
            task_spawn(function()
                while _G["TeleportMeditation" .. med.name] do
                    pcall(function()
                        local char = LocalPlayer and LocalPlayer.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = CFrame.new(med.pos) + Vector3.new(0, 3, 0)
                        end
                    end)
                    task_wait(0.5)
                end
            end)
        end)
    end

    -- 刷新 TabBar 滚动（确保所有分类可左右滑动）
    pcall(function() _G.RefreshTabBarScroll() end)
end

-- ===================================================
-- 核心分发路由引擎 (Multi-Game Router)
-- 多策略检测，避免单一匹配失败
-- ===================================================
StartCoreEngine = function()
    InitUIFactory()

    local loadedGameAdapter = false

    -- 策略 1: 精确 PlaceId 匹配（字符串比较避免大数精度问题）
    local placeIdStr = nil
    pcall(function() placeIdStr = tostring(game.PlaceId) end)
    if placeIdStr then
        local SupportedGames = {
            ["79708985160875"] = {name = "Anime Incremental", loader = LoadAnimeIncrementalInterface},
            ["84156601481934"] = {name = "Resource Incremental", loader = LoadResourceIncrementalInterface},
        }
        if SupportedGames[placeIdStr] then
            local ok, err = pcall(SupportedGames[placeIdStr].loader)
            if ok then
                loadedGameAdapter = true
            end
        end
    end

    -- 策略 2: 游戏名称检测
    if not loadedGameAdapter then
        local gameName = ""
        pcall(function() if game.Name then gameName = game.Name:lower() end end)
        if gameName == "" then
            pcall(function()
                local mps = game:GetService("MarketplaceService")
                if mps then
                    local info = mps:GetProductInfo(game.PlaceId)
                    if info and info.Name then gameName = info.Name:lower() end
                end
            end)
        end
        if gameName:find("anime") and gameName:find("incremental") then
            pcall(LoadAnimeIncrementalInterface)
            loadedGameAdapter = true
        end
    end

    -- 策略 3: 游戏特征检测（检测 Anime Incremental 特有的 networker 架构）
    if not loadedGameAdapter then
        pcall(function()
            local packages = ReplicatedStorage:FindFirstChild("Packages")
            if packages and packages:FindFirstChild("_Index") then
                for _, child in pairs(packages._Index:GetChildren()) do
                    if string.find(child.Name, "networker") and child:FindFirstChild("networker") then
                        -- 确认是 Anime Incremental 的特征
                        LoadAnimeIncrementalInterface()
                        loadedGameAdapter = true
                        break
                    end
                end
            end
        end)
    end

    -- 策略 4: 检测 Resource Incremental 特征
    if not loadedGameAdapter then
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("Others") then
                LoadResourceIncrementalInterface()
                loadedGameAdapter = true
            end
        end)
    end

    -- 兜底: 通用接口
    if not loadedGameAdapter then
        pcall(LoadUniversalInterface)
    end

    -- 最终刷新 TabBar 滚动（确保所有接口分类都能左右滑动）
    task_spawn(function()
        task_wait(0.2)
        pcall(function() _G.RefreshTabBarScroll() end)
        task_wait(0.5)
        pcall(function() _G.RefreshTabBarScroll() end)
    end)
end

ShowSplashLoadingScreen()
