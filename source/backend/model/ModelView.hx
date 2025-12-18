package backend.model;

import openfl.display.Sprite;
import openfl.display.Stage3D;
import openfl.display3D.Context3D;
import openfl.events.Event;
import flixel.FlxG;
import flixel.FlxCamera;

class ModelView extends Sprite
{
    public var context:Context3D;
    public var camera:FlxCamera;

    public function new(cam:FlxCamera)
    {
        super();
        camera = cam;
        FlxG.stage.addChild(this);

        FlxG.stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext);
        FlxG.stage.stage3Ds[0].requestContext3D();
    }

    function onContext(e:Event)
    {
        context = FlxG.stage.stage3Ds[0].context3D;
        context.configureBackBuffer(
            Std.int(FlxG.width),
            Std.int(FlxG.height),
            0,
            true
        );
    }

    public function render()
    {
        if (context == null) return;

        context.clear(0, 0, 0, 0);

        // Draw models here

        context.present();
    }
}
