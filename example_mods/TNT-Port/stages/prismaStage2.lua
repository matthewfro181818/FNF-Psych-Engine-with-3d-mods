-- Auto-converted TNT stage → Psych Engine 1.0.4
function onCreate()
    curStage = 'prismaStage2'
    defaultCamZoom = 0.8

    -- Background
    local bg = makeLuaSprite('bg', 'prismaStage/space', 0, 0)
    bg.scrollFactor = {x = 1, y = 1}
    bg.antialiasing = true
    addLuaSprite(bg, false)

    -- Moon
    local sun = makeLuaSprite('moon', 'prismaStage/moon', FlxG.width/2 - 175, -175)
    sun.scrollFactor = {x = 0.2, y = 0.2}
    sun.antialiasing = true
    addLuaSprite(sun, false)

    -- City / mountains
    local mtn = makeLuaSprite('city', 'prismaStage/city', FlxG.width/2 - 100, -100)
    mtn.scrollFactor = {x = 0.33, y = 0.33}
    mtn.antialiasing = true
    addLuaSprite(mtn, false)

    -- Tile / foreground grid
    skewScale = -0.07
    local skewGrid = makeLuaSprite('skewGrid', 'prismaStage/tile2', FlxG.width/2 - 200, 600)
    skewGrid.antialiasing = true
    addLuaSprite(skewGrid, false)
end
