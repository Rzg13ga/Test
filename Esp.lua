--[[
    esp-lib.lua
    A library for creating esp visuals in roblox using drawing.
    Provides functions to add boxes, health bars, names and distances to instances.
    Written by tul (@.lutyeh), modified for stable two-pass box ESP and refined outlines.
]]

-- // table
local esplib = getgenv().esplib
if not esplib then
    esplib = {
        box = {
            enabled = true,
            type = "normal", -- normal, corner
            padding = 1.15,
            fill = Color3.new(1,1,1), -- White for the inline box
            outline = Color3.new(0,0,0), -- Black for the outline border
        },
        healthbar = {
            enabled = true,
            fill = Color3.new(0,1,0),
            outline = Color3.new(0,0,0),
        },
        name = {
            enabled = true,
            fill = Color3.new(1,1,1),
            size = 13,
        },
        distance = {
            enabled = true,
            fill = Color3.new(1,1,1),
            size = 13,
        },
        tracer = {
            enabled = true,
            fill = Color3.new(1,1,1),
            outline = Color3.new(0,0,0),
            from = "bottom", -- mouse, head, top, bottom, center
        },
    }
    getgenv().esplib = esplib
end

local espinstances = {}
local espfunctions = {}

-- // services
local run_service = game:GetService("RunService")
local players = game:GetService("Players")
local user_input_service = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

-- // utility
-- Function to safely get the current mouse position (needed for tracer from "mouse")
local function get_mouse_location()
    local mouse_location = user_input_service:GetMouseLocation()
    return Vector2.new(mouse_location.X, mouse_location.Y)
end

-- // functions
local function get_bounding_box(instance)
    local min, max = Vector2.new(math.huge, math.huge), Vector2.new(-math.huge, -math.huge)
    local onscreen = false

    local parts_to_check = {}

    if instance:IsA("Model") then
        for _, p in ipairs(instance:GetChildren()) do
            if p:IsA("BasePart") then
                table.insert(parts_to_check, p)
            elseif p:IsA("Accessory") then
                local handle = p:FindFirstChild("Handle")
                if handle and handle:IsA("BasePart") then
                    table.insert(parts_to_check, handle)
                end
            end
        end
    elseif instance:IsA("BasePart") then
        table.insert(parts_to_check, instance)
    end

    if #parts_to_check == 0 then
        return min, max, false
    end

    for _, p in ipairs(parts_to_check) do
        local size = (p.Size / 2) * esplib.box.padding
        local cf = p.CFrame
        for _, offset in ipairs({
            Vector3.new( size.X,  size.Y,  size.Z),
            Vector3.new(-size.X,  size.Y,  size.Z),
            Vector3.new( size.X, -size.Y,  size.Z),
            Vector3.new(-size.X, -size.Y, -size.Z),
            Vector3.new( size.X,  size.Y, -size.Z),
            Vector3.new(-size.X,  size.Y, -size.Z),
            Vector3.new( size.X, -size.Y,  size.Z),
            Vector3.new(-size.X, -size.Y,  size.Z),
        }) do
            local pos, visible = camera:WorldToViewportPoint(cf:PointToWorldSpace(offset))
            if visible then
                local v2 = Vector2.new(pos.X, pos.Y)
                min = min:Min(v2)
                max = max:Max(v2)
                if pos.Z > 0 then onscreen = true end -- Ensure object is in front of camera
            end
        end
    end

    return min, max, onscreen
end

function espfunctions.add_box(instance)
    if not instance or espinstances[instance] and espinstances[instance].box then return end

    local box = {}

    -- Two-pass box: thicker black outline (ZIndex 1) and thinner white fill (ZIndex 2)
    local outline = Drawing.new("Square")
    outline.Thickness = 1
    outline.Filled = false
    outline.ZIndex = 1 -- Draw the black border first (lower ZIndex)
    outline.Visible = false

    local fill = Drawing.new("Square")
    fill.Thickness = 1
    fill.Filled = false
    fill.ZIndex = 2 -- Draw the white line second (higher ZIndex)
    fill.Visible = false

    box.outline = outline
    box.fill = fill

    box.corner_fill = {}
    box.corner_outline = {}
    for i = 1, 8 do
        -- Corner outline (black, thicker)
        local outline = Drawing.new("Line")
        outline.Thickness = 3 
        outline.Visible = false
        outline.ZIndex = 1
        table.insert(box.corner_outline, outline)

        -- Corner fill (white, thinner)
        local fill = Drawing.new("Line")
        fill.Thickness = 1
        fill.Visible = false
        fill.ZIndex = 2
        table.insert(box.corner_fill, fill)
    end

    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].box = box
end

function espfunctions.add_healthbar(instance)
    if not instance or espinstances[instance] and espinstances[instance].healthbar then return end
    
    -- Outline for the health bar box (ZIndex 3)
    local outline = Drawing.new("Square")
    outline.Thickness = 1
    outline.Filled = false 
    outline.Transparency = 1
    outline.ZIndex = 3

    -- Fill for the health (ZIndex 4)
    local fill = Drawing.new("Square")
    fill.Filled = true
    fill.Transparency = 1
    fill.ZIndex = 4

    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].healthbar = {
        outline = outline,
        fill = fill,
    }
end

function espfunctions.add_name(instance)
    if not instance or espinstances[instance] and espinstances[instance].name then return end
    local text = Drawing.new("Text")
    text.Center = true
    text.Outline = true -- Uses built-in outline for text
    text.Font = 1
    text.Transparency = 1
    text.ZIndex = 5

    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].name = text
end

function espfunctions.add_distance(instance)
    if not instance or espinstances[instance] and espinstances[instance].distance then return end
    local text = Drawing.new("Text")
    text.Center = true
    text.Outline = true -- Uses built-in outline for text
    text.Font = 1
    text.Transparency = 1
    text.ZIndex = 5

    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].distance = text
end

function espfunctions.add_tracer(instance)
    if not instance or espinstances[instance] and espinstances[instance].tracer then return end
    
    -- Tracer outline (black, thicker, ZIndex 6)
    local outline = Drawing.new("Line")
    outline.Thickness = 3
    outline.Transparency = 1
    outline.ZIndex = 6

    -- Tracer fill (color, thinner, ZIndex 7)
    local fill = Drawing.new("Line")
    fill.Thickness = 1
    fill.Transparency = 1
    fill.ZIndex = 7

    espinstances[instance] = espinstances[instance] or {}
    espinstances[instance].tracer = {
        outline = outline,
        fill = fill,
    }
end

-- Utility function to remove all ESP elements for an instance
function espfunctions.remove_all(instance)
    local data = espinstances[instance]
    if not data then return end
    
    if data.box then
        data.box.outline:Destroy()
        data.box.fill:Destroy()
        for _, line in ipairs(data.box.corner_fill) do line:Destroy() end
        for _, line in ipairs(data.box.corner_outline) do line:Destroy() end
    end
    if data.healthbar then
        data.healthbar.outline:Destroy()
        data.healthbar.fill:Destroy()
    end
    if data.name then
        data.name:Destroy()
    end
    if data.distance then
        data.distance:Destroy()
    end
    if data.tracer then
        data.tracer.outline:Destroy()
        data.tracer.fill:Destroy()
    end
    espinstances[instance] = nil
end

-- // main rendering thread
run_service.RenderStepped:Connect(function()
    for instance, data in pairs(espinstances) do
        if not instance or not instance.Parent then
            espfunctions.remove_all(instance)
            continue
        end

        -- Ensure models have a character or primary part to calculate bounds from
        local is_model_without_parts = instance:IsA("Model") and not instance:FindFirstChildWhichIsA("BasePart", true)

        if is_model_without_parts then
             -- Hide all elements if the model is empty or not loaded
            if data.box then data.box.outline.Visible = false; data.box.fill.Visible = false end
            if data.healthbar then data.healthbar.outline.Visible = false; data.healthbar.fill.Visible = false end
            if data.name then data.name.Visible = false end
            if data.distance then data.distance.Visible = false end
            if data.tracer then data.tracer.outline.Visible = false; data.tracer.fill.Visible = false end
            continue
        end


        local min, max, onscreen = get_bounding_box(instance)

        -- Box Drawing Logic
        if data.box then
            local box = data.box
            
            if esplib.box.enabled and onscreen then
                local x, y = min.X, min.Y
                local w, h = (max - min).X, (max - min).Y
                local len = math.min(w, h) * 0.25

                if esplib.box.type == "normal" then
                    -- Normal Box: Black outline (ZIndex 1) drawn larger, White fill (ZIndex 2) drawn exact size
                    -- 1. Black Outline (Position offset by -1, Size enlarged by +2)
                    box.outline.Position = Vector2.new(min.X - 1, min.Y - 1)
                    box.outline.Size = Vector2.new(w + 2, h + 2)
                    box.outline.Color = esplib.box.outline
                    box.outline.Visible = true

                    -- 2. White Inline (Exact position and size)
                    box.fill.Position = min
                    box.fill.Size = Vector2.new(w, h)
                    box.fill.Color = esplib.box.fill
                    box.fill.Visible = true

                    -- Hide corner lines
                    for _, line in ipairs(box.corner_fill) do line.Visible = false end
                    for _, line in ipairs(box.corner_outline) do line.Visible = false end

                elseif esplib.box.type == "corner" then
                    -- Hide normal box elements
                    box.outline.Visible = false
                    box.fill.Visible = false

                    local fill_lines = box.corner_fill
                    local outline_lines = box.corner_outline
                    local fill_color = esplib.box.fill
                    local outline_color = esplib.box.outline

                    -- Coordinates for 8 lines creating the corners
                    local corners = {
                        -- Top-Left
                        { Vector2.new(x, y), Vector2.new(x + len, y) },
                        { Vector2.new(x, y), Vector2.new(x, y + len) },
                        -- Top-Right
                        { Vector2.new(x + w - len, y), Vector2.new(x + w, y) },
                        { Vector2.new(x + w, y), Vector2.new(x + w, y + len) },
                        -- Bottom-Left
                        { Vector2.new(x, y + h), Vector2.new(x + len, y + h) },
                        { Vector2.new(x, y + h - len), Vector2.new(x, y + h) },
                        -- Bottom-Right
                        { Vector2.new(x + w - len, y + h), Vector2.new(x + w, y + h) },
                        { Vector2.new(x + w, y + h - len), Vector2.new(x + w, y + h) },
                    }

                    for i = 1, 8 do
                        local from, to = corners[i][1], corners[i][2]
                        local dir = (to - from).Unit
                        local oFrom = from - dir * 0.5 -- Adjusted for cleaner overlap
                        local oTo = to + dir * 0.5

                        -- Black Outline (Thick)
                        local o = outline_lines[i]
                        o.From = oFrom
                        o.To = oTo
                        o.Color = outline_color
                        o.Visible = true

                        -- White Fill (Thin)
                        local f = fill_lines[i]
                        f.From = from
                        f.To = to
                        f.Color = fill_color
                        f.Visible = true
                    end
                end
            else
                box.outline.Visible = false
                box.fill.Visible = false
                for _, line in ipairs(box.corner_fill) do line.Visible = false end
                for _, line in ipairs(box.corner_outline) do line.Visible = false end
            end
        end

        -- Health Bar Drawing Logic
        if data.healthbar then
            local outline, fill = data.healthbar.outline, data.healthbar.fill

            if not esplib.healthbar.enabled or not onscreen then
                outline.Visible = false
                fill.Visible = false
            else
                local humanoid = instance:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.MaxHealth > 0 then
                    local height = max.Y - min.Y
                    local padding = 1
                    local bar_width = 3
                    local x = min.X - bar_width - padding - 1 
                    local y = min.Y - padding
                    local health_ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
                    local fillheight = height * health_ratio

                    -- Calculate dynamic health color (Green -> Yellow -> Red)
                    local r = math.min(1, 2 * (1 - health_ratio))
                    local g = math.min(1, 2 * health_ratio)
                    local health_color = Color3.new(r, g, 0)
                    fill.Color = health_color

                    -- Black Outline of the entire health bar (2-pass setup)
                    outline.Color = esplib.healthbar.outline
                    outline.Position = Vector2.new(x, y - 1) -- Offset up by 1 pixel for better coverage
                    outline.Size = Vector2.new(bar_width + 2 * padding, height + 2 * padding + 2) -- Add 2 pixels to height
                    outline.Visible = true

                    -- Health Fill (exact position)
                    fill.Position = Vector2.new(x + padding, y + (height + 2*padding) - fillheight - padding)
                    fill.Size = Vector2.new(bar_width, fillheight)
                    fill.Visible = true
                else
                    outline.Visible = false
                    fill.Visible = false
                end
            end
        end

        -- Name Drawing Logic
        if data.name then
            if esplib.name.enabled and onscreen then
                local text = data.name
                local center_x = (min.X + max.X) / 2
                local y = min.Y - 15

                local name_str = instance.Name
                local humanoid = instance:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local player = players:GetPlayerFromCharacter(instance)
                    if player then
                        name_str = player.Name
                    end
                end

                text.Text = name_str
                text.Size = esplib.name.size
                text.Color = esplib.name.fill
                text.Position = Vector2.new(center_x, y)
                text.Visible = true
            else
                data.name.Visible = false
            end
        end

        -- Distance Drawing Logic
        if data.distance then
            if esplib.distance.enabled and onscreen then
                local text = data.distance
                local center_x = (min.X + max.X) / 2
                local y = max.Y + 5
                local primary_part = instance:IsA("Model") and (instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart", true)) or instance
                local dist = 999

                if primary_part and primary_part:IsA("BasePart") then
                    dist = (camera.CFrame.Position - primary_part.Position).Magnitude
                end

                text.Text = tostring(math.floor(dist)) .. "m"
                text.Size = esplib.distance.size
                text.Color = esplib.distance.fill
                text.Position = Vector2.new(center_x, y)
                text.Visible = true
            else
                data.distance.Visible = false
            end
        end

        -- Tracer Drawing Logic
        if data.tracer then
            if esplib.tracer.enabled and onscreen then
                local outline, fill = data.tracer.outline, data.tracer.fill

                local from_pos = Vector2.new()
                local to_pos = (min + max) / 2

                if esplib.tracer.from == "mouse" then
                    from_pos = get_mouse_location()
                elseif esplib.tracer.from == "head" then
                    local head = instance:FindFirstChild("Head")
                    local pos, visible = head and camera:WorldToViewportPoint(head.Position) or Vector3.new()

                    if head and visible and pos.Z > 0 then
                        from_pos = Vector2.new(pos.X, pos.Y)
                    else
                        from_pos = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
                    end
                elseif esplib.tracer.from == "bottom" then
                    from_pos = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
                elseif esplib.tracer.from == "center" then
                    from_pos = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
                else
                    from_pos = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y) -- Default to bottom
                end

                outline.From = from_pos
                outline.To = to_pos
                outline.Color = esplib.tracer.outline
                outline.Visible = true

                fill.From = from_pos
                fill.To = to_pos
                fill.Color = esplib.tracer.fill
                fill.Visible = true
            else
                data.tracer.outline.Visible = false
                data.tracer.fill.Visible = false
            end
        end
    end
end)

-- // return
for k, v in pairs(espfunctions) do
    esplib[k] = v
end

return esplib
