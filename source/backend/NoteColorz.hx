package backend;

import flixel.util.FlxColor;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
 * Universal TNT-style note palette loader
 * Used by Note, StrumNote, Splashes
 */
class NoteColorz
{
    public static var shaders:Array<ColorzShader> = [];
    public static var flatColors:Array<FlxColor> = [];

    public static function load(?p1:String, ?p2:String)
    {
        clear();
        if (p1 == null) p1 = "default";
        if (p2 == null) p2 = p1;

        for (pal in [p1, p2])
        {
            var file = Paths.json('_notecolors/' + pal.toLowerCase());
            var raw:String;

            if (FileSystem.exists(file))
                raw = File.getContent(file).trim();
            else
                raw = File.getContent(Paths.json('_notecolors/default')).trim();

            var json:ColorzJSON = Json.parse(raw);

            pushPalette(json.left);
            pushPalette(json.down);
            pushPalette(json.up);
            pushPalette(json.right);
        }
    }

    private static function pushPalette(p:ColorzPalette)
    {
        shaders.push(new ColorzShader(
            Std.parseInt("0x" + p.inner),
            Std.parseInt("0x" + p.outer),
            Std.parseInt("0x" + p.base)
        ));

        flatColors.push(Std.parseInt("0x" + p.inner));
    }

    public static function clear()
    {
        shaders.resize(0);
        flatColors.resize(0);
    }
}

/** JSON Types */
typedef ColorzJSON = {
    var left:ColorzPalette;
    var down:ColorzPalette;
    var up:ColorzPalette;
    var right:ColorzPalette;
}
typedef ColorzPalette = {
    var inner:String;
    var outer:String;
    var base:String;
}

/** Wrapper shader */
class ColorzShader extends flixel.system.FlxAssets.FlxShader
{
    public var inner:FlxColor;
    public var outer:FlxColor;
    public var base:FlxColor;

    public function new(i:Int, o:Int, b:Int)
    {
        super();

        inner = i;
        outer = o;
        base  = b;

        // Not all builds have full shader support
        try {
            data.innerColor.value = [i];
            data.outerColor.value = [o];
            data.baseColor.value  = [b];
        }
        catch (_){ }
    }
}
