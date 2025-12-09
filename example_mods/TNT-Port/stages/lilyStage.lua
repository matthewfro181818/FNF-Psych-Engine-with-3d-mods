-- Auto-converted TNT stage → Psych Engine 1.0.4
function onCreate()
    curStage = 'lilyStage'
    defaultCamZoom = 0.8

    local bg = makeLuaSprite('bg', 'lily/stuff', -600, -300)
    bg.scrollFactor = {x = 0.7, y = 0.7}
    bg.antialiasing = true
    addLuaSprite(bg, false)

    local roadinner = makeLuaSprite('roadinner', 'lily/morestuff', -600, 274)
    roadinner.scrollFactor = {x = 0.8, y = 0.8}
    roadinner.antialiasing = true
    addLuaSprite(roadinner, false)

    local light = makeLuaSprite('light', 'lily/morestuff', 80, 0)
    light.scrollFactor = {x = 0.9, y = 0.9}
    light.antialiasing = true
    addLuaSprite(light, false)
end
