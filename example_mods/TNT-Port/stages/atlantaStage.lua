-- Auto-converted TNT stage → Psych Engine 1.0.4
function onCreate()
    curStage = 'atlantaStage'
    defaultCamZoom = 0.7

    local bg = makeLuaSprite('bg', 'ghoti/bg', -625, -200)
    bg.scrollFactor = {x = 1, y = 1}
    bg.antialiasing = true
    addLuaSprite(bg, false)
end
