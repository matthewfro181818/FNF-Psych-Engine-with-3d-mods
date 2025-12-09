package objects;

import sys.FileSystem;
import flixel.util.FlxDestroyUtil;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import openfl.utils.Assets as OpenFlAssets;
import backend.Paths;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;

	public var defaultIconScale:Float = 1.0;
	public var iconScale:Float = 1.0;
	public var iconSize:Float = 128;

	var char:String = "face";
	public var status:String = "normal";

	private var tween:FlxTween;

	private var iconOffsets:Array<Float> = [0, 0];

	// Pixel characters use no antialiasing
	private static final pixelIcons:Array<String> =
		["bf-pixel", "senpai", "senpai-angry", "spirit"];

	public function new(char:String = "face", isPlayer:Bool = false, ?_id:Int = -1)
	{
		super();
		flipX = isPlayer;

		changeChar(char);
		loadStatus("normal");

		antialiasing = !pixelIcons.contains(this.char);
		scrollFactor.set();

		tween = FlxTween.tween(this, {}, 0);
	}


	// --------------------------------------------------------------
	// CHAR SELECTION + MOD-FOLDER COMPATIBILITY
	// --------------------------------------------------------------

	public function changeChar(char:String)
	{
		// Character icons live in mods/<mod>/images/healthicons/<char>/
		var folder = "images/healthicons/" + char;

		var modPath = Paths.mods(folder + "/normal.png");
		var sharedPath = Paths.getSharedPath(folder + "/normal.png");

		if (FileSystem.exists(modPath) || OpenFlAssets.exists(sharedPath))
			this.char = char;
		else
			this.char = "face";
	}


	public function changeIcon(char:String, ?allowGPU:Bool = true) {
		// Character icons live in mods/<mod>/images/healthicons/<char>/
		var folder = "images/healthicons/" + char;

		var modPath = Paths.mods(folder + "/normal.png");
		var sharedPath = Paths.getSharedPath(folder + "/normal.png");

		if (FileSystem.exists(modPath) || OpenFlAssets.exists(sharedPath))
			this.char = char;
		else
			this.char = "face";
	}

	// --------------------------------------------------------------
	// ICON STATES
	// --------------------------------------------------------------

	public function loadStatus(state:String)
	{
		var path = "healthicons/" + char + "/" + state;
		loadGraphic(Paths.image(path));
		status = state;
	}

	public function normal()
		loadStatus("normal");

	public function win()
		loadStatus("win");

	public function lose()
		loadStatus("lose");


	// --------------------------------------------------------------
	// UPDATE + SCALING
	// --------------------------------------------------------------

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		setGraphicSize(Std.int(iconSize * iconScale));
		updateHitbox();
	}

	public function tweenToDefaultScale(time:Float, ease:Null<flixel.tweens.EaseFunction>)
	{
		tween.cancel();
		tween = FlxTween.tween(this, {iconScale: this.defaultIconScale}, time, {ease: ease});
	}


	// --------------------------------------------------------------
	// CLEANUP
	// --------------------------------------------------------------

	override public function destroy()
	{
		tween = FlxDestroyUtil.destroy(tween);
		super.destroy();
	}

	public var autoAdjustOffset:Bool = true;
	override function updateHitbox()
	{
		super.updateHitbox();
		if(autoAdjustOffset)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
	}

	public function getCharacter():String {
		return char;
	}
}
