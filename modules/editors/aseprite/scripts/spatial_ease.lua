local sprite = app.activeSprite
if not sprite then return app.alert("No active sprite open.") end
local frame = app.activeFrame
if not frame then return app.alert("No active frame.") end

local selBounds = sprite.selection.bounds
local originalData = {}
local layerSettings = {}
local layerNames = {}

for _, layer in ipairs(sprite.layers) do
    if not layer.isGroup then
        local cel = layer:cel(frame)
        if cel then
            table.insert(layerNames, layer.name)
            originalData[layer.name] = {
                layer = layer,
                image = cel.image:clone(),
                pos = Point(cel.position.x, cel.position.y),
                opacity = cel.opacity
            }
            layerSettings[layer.name] = {
                px = 100, opS = 100, opE = 100,   
                tgtColor = Color{ r=0, g=0, b=0, a=255 }, 
                blendS = 0, blendE = 0, 
                blur = true, bLen = 100, bStep = 10, bOp = 70 -- New Blur Defaults!
            }
        end
    end
end

if #layerNames == 0 then return app.alert("No drawings found on this frame.") end

local easings = {
    "Linear", "In Sine", "Out Sine", "In-Out Sine",
    "In Quad", "Out Quad", "In-Out Quad",
    "In Cubic", "Out Cubic", "In-Out Cubic"
}

local function ease(t, mode)
    if mode == "Linear" then return t end
    if mode == "In Sine" then return 1 - math.cos((t * math.pi) / 2) end
    if mode == "Out Sine" then return math.sin((t * math.pi) / 2) end
    if mode == "In-Out Sine" then return -(math.cos(math.pi * t) - 1) / 2 end
    if mode == "In Quad" then return t * t end
    if mode == "Out Quad" then local f = 1 - t return 1 - (f * f) end
    if mode == "In-Out Quad" then if t < 0.5 then return 2 * t * t end local f = -2 * t + 2 return 1 - (f * f) / 2 end
    if mode == "In Cubic" then return t * t * t end
    if mode == "Out Cubic" then local f = 1 - t return 1 - (f * f * f) end
    if mode == "In-Out Cubic" then if t < 0.5 then return 4 * t * t * t end local f = -2 * t + 2 return 1 - (f * f * f) / 2 end
    return t
end

-- Core Engine
local function transformImage(srcImg, celPos, dx, dy, wrapMode, tgtColor, blendAmt, doBlur, prevDx, prevDy, bStep, bOp)
    local w, h = sprite.width, sprite.height
    local newImg = Image(w, h, srcImg.colorMode)
    
    local renderImg = srcImg
    if blendAmt > 0 and srcImg.colorMode == ColorMode.RGB then
        renderImg = srcImg:clone()
        local tr, tg, tb = tgtColor.red, tgtColor.green, tgtColor.blue
        for it in renderImg:pixels() do
            local px = it()
            if px ~= renderImg.spec.transparentColor then
                local a = app.pixelColor.rgbaA(px)
                if a > 0 then
                    local r, g, b = app.pixelColor.rgbaR(px), app.pixelColor.rgbaG(px), app.pixelColor.rgbaB(px)
                    r = math.floor(r + (tr - r) * blendAmt)
                    g = math.floor(g + (tg - g) * blendAmt)
                    b = math.floor(b + (tb - b) * blendAmt)
                    renderImg:drawPixel(it.x, it.y, app.pixelColor.rgba(r, g, b, a))
                end
            end
        end
    end

    local function stamp(offsetX, offsetY, opacity)
        if wrapMode == "Selection" and not selBounds.isEmpty then
            for it in renderImg:pixels() do
                local px = it()
                if px ~= renderImg.spec.transparentColor and app.pixelColor.rgbaA(px) > 0 then
                    local absX, absY = celPos.x + it.x + offsetX, celPos.y + it.y + offsetY
                    if absX >= selBounds.x and absX < selBounds.x + selBounds.width and absY >= selBounds.y and absY < selBounds.y + selBounds.height then
                        local relX, relY = absX - selBounds.x, absY - selBounds.y
                        if opacity == 255 then newImg:drawPixel(selBounds.x + (relX % selBounds.width), selBounds.y + (relY % selBounds.height), px) end
                    else
                        if opacity == 255 then newImg:drawPixel(absX, absY, px) end
                    end
                end
            end
        else
            local absX, absY = celPos.x + offsetX, celPos.y + offsetY
            if wrapMode == "Canvas" then
                local wx, wy = absX % w, absY % h
                newImg:drawImage(renderImg, Point(wx, wy), opacity)
                if wx > 0 then newImg:drawImage(renderImg, Point(wx - w, wy), opacity) end
                if wy > 0 then newImg:drawImage(renderImg, Point(wx, wy - h), opacity) end
                if wx > 0 and wy > 0 then newImg:drawImage(renderImg, Point(wx - w, wy - h), opacity) end
            else
                newImg:drawImage(renderImg, Point(absX, absY), opacity)
            end
        end
    end

    -- Draw Highly Customizable Motion Smear
    if doBlur and bStep > 0 and (dx ~= prevDx or dy ~= prevDy) then
        for s = 1, bStep do
            local f = s / (bStep + 1)
            local mx = math.floor(prevDx + (dx - prevDx) * f + 0.5)
            local my = math.floor(prevDy + (dy - prevDy) * f + 0.5)
            
            -- Opacity ramps up linearly towards the main object based on your Max Opacity setting
            local ghostOpacity = math.floor(255 * (bOp / 100) * f)
            stamp(mx, my, ghostOpacity)
        end
    end

    -- Draw 100% Solid Core Object
    stamp(dx, dy, 255)
    return newImg
end

local dlg = Dialog("Spatial Easer Pro")
local isPreviewing = false
local updatePreview
local loadLayerData

local function syncSetting(key, val)
    if dlg.data.linkAll then
        for _, name in ipairs(layerNames) do layerSettings[name][key] = val end
    else
        layerSettings[dlg.data.editLayer][key] = val
    end
    updatePreview()
end

local function resetDefaults()
    local function reset(name)
        layerSettings[name].px = 100; layerSettings[name].opS = 100; layerSettings[name].opE = 100
        layerSettings[name].tgtColor = Color{ r=0, g=0, b=0, a=255 }
        layerSettings[name].blendS = 0; layerSettings[name].blendE = 0; 
        layerSettings[name].blur = true; layerSettings[name].bLen = 100; layerSettings[name].bStep = 10; layerSettings[name].bOp = 70
    end
    if dlg.data.linkAll then for _, name in ipairs(layerNames) do reset(name) end else reset(dlg.data.editLayer) end
    loadLayerData()
    updatePreview()
end

dlg:number{ id="count", label="Frames:", text="12", onchange=function() updatePreview() end }
dlg:number{ id="dx", label="Shift X:", text="0", onchange=function() updatePreview() end }
dlg:number{ id="dy", label="Shift Y:", text="0", onchange=function() updatePreview() end }
dlg:combobox{ id="easing", label="Curve:", options=easings, option="In-Out Sine", onchange=function() updatePreview() end }
dlg:combobox{ id="wrapMode", label="Wrap:", options={"None", "Canvas", "Selection"}, option="Canvas", onchange=function() updatePreview() end }
dlg:check{ id="pingpong", label="Ping-Pong", selected=false, onchange=function() updatePreview() end }
dlg:check{ id="overwrite", label="Overwrite Frames", selected=false }
dlg:separator{ text="Layer Configuration" }

function loadLayerData()
    local lset = layerSettings[dlg.data.editLayer]
    dlg:modify{ id="l_px", value = lset.px }; dlg:modify{ id="l_opS", value = lset.opS }; dlg:modify{ id="l_opE", value = lset.opE }
    dlg:modify{ id="l_tgtColor", color = lset.tgtColor }
    dlg:modify{ id="l_blendS", value = lset.blendS }; dlg:modify{ id="l_blendE", value = lset.blendE }
    dlg:modify{ id="l_blur", selected = lset.blur }; dlg:modify{ id="l_bLen", value = lset.bLen }
    dlg:modify{ id="l_bStep", value = lset.bStep }; dlg:modify{ id="l_bOp", value = lset.bOp }
end

dlg:combobox{ id="editLayer", label="Configure:", options=layerNames, option=layerNames[1], onchange=loadLayerData }
dlg:check{ id="linkAll", text="Link All Layers (Sync Settings)", selected=true }

dlg:slider{ id="l_px", label="Speed % (Parallax):", min=-100, max=200, value=100, onchange=function() syncSetting("px", dlg.data.l_px) end }
dlg:color{ id="l_tgtColor", label="Target Color:", color=Color{r=0, g=0, b=0}, onchange=function() syncSetting("tgtColor", dlg.data.l_tgtColor) end }
dlg:slider{ id="l_blendS", label="Blend Start %:", min=0, max=100, value=0, onchange=function() syncSetting("blendS", dlg.data.l_blendS) end }
dlg:slider{ id="l_blendE", label="Blend End %:", min=0, max=100, value=0, onchange=function() syncSetting("blendE", dlg.data.l_blendE) end }
dlg:slider{ id="l_opS", label="Opacity Start %:", min=0, max=100, value=100, onchange=function() syncSetting("opS", dlg.data.l_opS) end }
dlg:slider{ id="l_opE", label="Opacity End %:", min=0, max=100, value=100, onchange=function() syncSetting("opE", dlg.data.l_opE) end }

-- New Custom Blur Sliders
dlg:check{ id="l_blur", text="Motion Blur Smear", selected=true, onchange=function() syncSetting("blur", dlg.data.l_blur) end }
dlg:slider{ id="l_bLen", label="  - Trail Length %:", min=10, max=300, value=100, onchange=function() syncSetting("bLen", dlg.data.l_bLen) end }
dlg:slider{ id="l_bStep", label="  - Ghost Steps:", min=1, max=30, value=10, onchange=function() syncSetting("bStep", dlg.data.l_bStep) end }
dlg:slider{ id="l_bOp", label="  - Trail Max Opacity %:", min=5, max=100, value=70, onchange=function() syncSetting("bOp", dlg.data.l_bOp) end }

dlg:button{ id="btnReset", text="Reset Defaults", onclick=resetDefaults }
dlg:separator{ text="Target Layers (Uncheck to ignore)" }
for _, name in ipairs(layerNames) do
    dlg:check{ id="chk_"..name, label="", text=name, selected=true, onchange=function() updatePreview() end }
end

dlg:separator{ text="Live Preview" }

local function renderToFrame(targetFrame, rawT, data)
    local t = rawT
    if data.pingpong then t = rawT < 0.5 and (rawT * 2) or (2 - (rawT * 2)) end
    local progress = ease(t, data.easing)

    -- Base gap for 1 frame
    local frameTimeGap = 1 / math.max(1, tonumber(data.count) - 1)

    for name, orig in pairs(originalData) do
        if data["chk_"..name] then
            local lset = layerSettings[name]
            local pRatio = lset.px / 100
            
            local curDx = math.floor((data.dx * progress * pRatio) + 0.5)
            local curDy = math.floor((data.dy * progress * pRatio) + 0.5)
            local curOp = math.floor(255 * (lset.opS + (lset.opE - lset.opS) * t) / 100)
            local curBlend = (lset.blendS + (lset.blendE - lset.blendS) * t) / 100

            local prevDx, prevDy = curDx, curDy
            
            if lset.blur and rawT > 0 then
                -- Dynamically calculate where the trail starts based on the Trail Length multiplier!
                local trailGap = frameTimeGap * (lset.bLen / 100)
                local rawPrevT = math.max(0, rawT - trailGap)
                local prevT = rawPrevT
                if data.pingpong then prevT = rawPrevT < 0.5 and (rawPrevT * 2) or (2 - (rawPrevT * 2)) end
                
                local trailProgress = ease(prevT, data.easing)
                prevDx = math.floor((data.dx * trailProgress * pRatio) + 0.5)
                prevDy = math.floor((data.dy * trailProgress * pRatio) + 0.5)
            end

            local transImg = transformImage(orig.image, orig.pos, curDx, curDy, data.wrapMode, lset.tgtColor, curBlend, lset.blur, prevDx, prevDy, lset.bStep, lset.bOp)
            local finalCel = sprite:newCel(orig.layer, targetFrame, transImg, Point(0, 0))
            finalCel.opacity = curOp
        else
            local finalCel = sprite:newCel(orig.layer, targetFrame, orig.image, orig.pos)
            finalCel.opacity = orig.opacity
        end
    end
end

function updatePreview()
    local data = dlg.data
    if isPreviewing then app.command.Undo() end
    app.transaction("Preview Scrub", function() renderToFrame(frame, data.preview / 100, data) end)
    isPreviewing = true
    app.refresh()
end

dlg:slider{ id="preview", label="Scrub %:", min=0, max=100, value=0, onchange=updatePreview }
dlg:button{ id="ok", text="Generate" }
dlg:button{ id="cancel", text="Cancel" }
dlg:show()

if not dlg.data.ok then
    if isPreviewing then app.command.Undo() end
    app.refresh()
    return
end

if isPreviewing then app.command.Undo() end
local data = dlg.data
local totalFrames = math.max(2, tonumber(data.count) or 12)

app.transaction("Generate Eased Frames", function()
    for i = 1, totalFrames - 1 do
        local targetFrameIndex = frame.frameNumber + i
        local newFrame
        if data.overwrite and targetFrameIndex <= #sprite.frames then
            newFrame = sprite.frames[targetFrameIndex]
        else
            newFrame = sprite:newEmptyFrame()
        end
        renderToFrame(newFrame, i / (totalFrames - 1), data)
    end
end)

app.refresh()