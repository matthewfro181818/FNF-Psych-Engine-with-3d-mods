-- Auto-converted TNT stage → Psych Engine 1.0.4
function onCreate()
    curStage = 'bfStage'
    defaultCamZoom = 0.75

    local bg = makeLuaSprite('bg', 'bfStage/bg2', -500, -200)
    bg.scrollFactor = {x = 0.3, y = 0.3}
    bg.antialiasing = true
    addLuaSprite(bg, false)

    local fg = makeLuaSprite('fg', 'bfStage/fg', -500, -200)
    fg.scrollFactor = {x = 0.3, y = 0.3}
    fg.antialiasing = true
    addLuaSprite(fg, false)
end
