package objects;

import backend.animation.PsychAnimationController;
import flixel.util.FlxSort;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.addons.display.FlxNestedSprite;
import flixel.util.FlxDestroyUtil;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;
import haxe.macro.Type.AnonStatus;
import flixel.system.FlxAssets.FlxGraphicAsset;
import openfl.display.BitmapData;
import flixel.FlxG;
import openfl.display3D.Context3DTextureFormat;
import openfl.Assets;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import backend.Song;
import states.stages.objects.TankmenBG;

using StringTools;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;
	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var vocals_file:String;
	@:optional var _editor_isPlayer:Null<Bool>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxNestedSkewSprite {
	/**
	 * In case a character is missing, it will use this on its place
	**/
	public static final DEFAULT_CHARACTER:String = 'bf';

	public var animOffsets:Map<String, Array<Dynamic>>;

	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var canAutoAnim:Bool = true;
	public var canAutoIdle:Bool = true;

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var initFacing:Int = FlxObject.RIGHT;

	public var initWidth:Float = -1;
	public var initFrameWidth:Int = -1;
	public var initHeight:Float;

	public var camOffsets:Array<Float> = [0, 0];
	public var posOffsets:Array<Float> = [0, 0];

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;

	// 3D
	public var isModel:Bool = false;
	public var modelView:ModelView;
	public var beganLoading:Bool = false;
	public var modelName:String = "";
	public var modelScale:Float = 1;
	public var model:ModelThing;
	public var modelType:String = "md2";
	public var initYaw:Float = 0;
	public var initPitch:Float = 0;
	public var initRoll:Float = 0;
	public var xOffset:Float = 0;
	public var yOffset:Float = 0;
	public var zOffset:Float = 0;
	public var viewX:Float = 750;
	public var viewY:Float = 750;
	public var ambient:Float = 1;
	public var specular:Float = 1;
	public var diffuse:Float = 1;
	public var animSpeed:Map<String, Float> = new Map<String, Float>();
	public var noLoopList:Array<String> = [];
	public var isGlass:Bool = false;

	public static var modelMutex:Bool = false;

	public static var modelMutexThing:ModelThing;

	// Atlas
	var animRedirect:Map<String, String> = [];

	public var atlasContainer:AtlasThing;
	public var atlasActive:Bool = false;

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false) {
		super(x, y);

		animation = new PsychAnimationController(this);

		animOffsets = new Map<String, Array<Dynamic>>();

		curCharacter = character;
		this.isPlayer = isPlayer;
		changeCharacter(character);

		switch (curCharacter) {
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
			case 'pico-blazin', 'darnell-blazin':
				skipDance = true;
		}
		// var tex:FlxAtlasFrames;
		antialiasing = true;
	}

	public function changeCharacter(character:String) {
		animationsArray = [];
		animOffsets = [];
		curCharacter = character;
		var characterPath:String = 'characters/$character.json';

		switch (curCharacter) {
			case 'spirit':
				frames = Paths.getSparrowAtlasFunk('characters/spirit');
				animation.addByPrefix('idle', "idle spirit", 24, false);
				animation.addByPrefix('singUP', "up", 24, false);
				animation.addByPrefix('singRIGHT', "right", 24, false);
				animation.addByPrefix('singLEFT', "left", 24, false);
				animation.addByPrefix('singDOWN', "spirit down", 24, false);

				addOffset('idle', 0, 0);
				addOffset('singUP', -3, 20);
				addOffset("singRIGHT", -10, 0);
				addOffset("singLEFT", 10, 0);
				addOffset("singDOWN", 0, -10);

				antialiasing = false;

				setGraphicSize(Std.int(width * 6));
				playAnim('idle');
				updateHitbox();

				try {
					#if MODS_ALLOWED
					loadCharacterFile(Json.parse(File.getContent(path)));
					#else
					loadCharacterFile(Json.parse(Assets.getText(path)));
					#end
				} catch (e:Dynamic) {
					trace('Error loading character file of "$character": $e');
				}

			case 'tankman':
				createAtlas();
				setAtlasAnim('idle', "idle");
				setAtlasAnim('singUP', 'singUP');
				setAtlasAnim('singUP-alt', 'singRIGHT-alt');
				setAtlasAnim('singDOWN', 'singDOWN');
				setAtlasAnim('singLEFT', 'singLEFT');
				setAtlasAnim('singRIGHT', 'singRIGHT');
				setAtlasAnim('singRIGHTmiss', 'singRIGHTmiss');
				setAtlasAnim('singLEFTmiss', 'singLEFTmiss');
				setAtlasAnim('singUPmiss', 'singUPmiss');
				setAtlasAnim('singDOWNmiss', 'singDOWNmiss');
				loadAtlas(Paths.getImageFunk("characters/tankman/spritemap1"), Paths.json("characters/tankman/spritemap1", "images"),
					Paths.json("characters/tankman/Animation", "images"));

				skipDance = false;
				hasMissAnimations = hasAnimation('singLEFTmiss') || hasAnimation('singDOWNmiss') || hasAnimation('singUPmiss') || hasAnimation('singRIGHTmiss');
				recalculateDanceIdle();

				addOffset('idle');
				addOffset("singUP", 17, 58);
				addOffset("singLEFT", 86, -29);
				addOffset("singRIGHT", -21, 4);
				addOffset("singUP-alt", -4, -6);
				addOffset("singDOWN", 56, -103);
				addOffset("singUPmiss", 17, 56);
				addOffset("singLEFTmiss", 90, -29);
				addOffset("singRIGHTmiss", -21, 5);
				addOffset("singDOWNmiss", 53, -99);

				playAnim('idle');
				initFacing = FlxObject.LEFT;

			case 'atlanta':
				frames = Paths.getSparrowAtlasFunk("characters/atlanta");
				animation.addByPrefix('idle', 'idle', 12, false);
				animation.addByPrefix('singDOWN', 'singDOWN', 12, false);
				animation.addByPrefix('singDOWNmiss', 'missDOWN', 12, false);
				animation.addByPrefix('singLEFTmiss', 'missLEFT', 12, false);
				animation.addByPrefix('singRIGHTmiss', 'missRIGHT', 12, false);
				animation.addByPrefix('singUPmiss', 'missUP', 12, false);
				animation.addByPrefix('singLEFT', 'singLEFT', 12, false);
				animation.addByPrefix('singRIGHT', 'singRIGHT', 12, false);
				animation.addByPrefix('singUP', 'singUP', 12, false);

				addOffset('idle');
				addOffset("singDOWN", -4, -135);
				addOffset("singDOWNmiss", -4, -135);
				addOffset("singLEFT", -18, -27);
				addOffset("singLEFTmiss", -18, -27);
				addOffset("singRIGHT", -2, 2);
				addOffset("singRIGHTmiss", -2, 2);
				addOffset("singUP", 20, 38);
				addOffset("singUPmiss", 20, 38);

				playAnim('idle');
				posOffsets = [-180, 0];
				camOffsets = [180, 0];

			case 'lily':
				createAtlas();

				setAtlasAnim('idle', 'oIdle');
				setAtlasAnim('singUP', 'oUp');
				setAtlasAnim('singLEFT', 'oLeft');
				setAtlasAnim('singRIGHT', 'oRight');
				setAtlasAnim('singDOWN', 'oDOwn');
				setAtlasAnim('singUPmiss', 'oUpMiss');
				setAtlasAnim('singLEFTmiss', 'oLeftMiss');
				setAtlasAnim('singRIGHTmiss', 'oRightMiss');
				setAtlasAnim('singDOWNmiss', 'oDownMiss');
				setAtlasAnim('hit', 'oHit');
				setAtlasAnim('dodge', 'oDodge');

				loadAtlas(Paths.getImageFunk("characters/lily/spritemap1"), Paths.json("characters/lily/spritemap1", "images"),
					Paths.json("characters/lily/Animation", "images"));

				addOffset('idle');
				addOffset("singDOWN", 108, -181);
				addOffset("singDOWNmiss", 108, -190);
				addOffset("singLEFTmiss", 116, -5);
				addOffset("singRIGHTmiss", 1, -48);
				addOffset("singUPmiss", 225, 77);
				addOffset("singLEFT", 131, -2);
				addOffset("singRIGHT", -2, -23);
				addOffset("singUP", 225, 77);
				addOffset("dodge", 233, 66);
				addOffset("hit", 259, 131);

				playAnim('idle');

			case 'prisma':
				modelName = "prisma";
				modelScale = 50;
				var multiplier = Conductor.bpm / 100;
				animSpeed = [
					"default" => 2.1 * multiplier,
					"idle" => 1.5 * multiplier,
					"singLEFT" => 2.5 * multiplier
				];
				for (thing in ["singUPEnd", "singLEFTEnd", "singRIGHTEnd", "singDOWNEnd"])
					animSpeed[thing] = 1.5;
				isModel = true;
				noLoopList = [
					"idle", "singUP", "singLEFT", "singRIGHT", "singDOWN", "singUPEnd", "singLEFTEnd", "singRIGHTEnd", "singDOWNEnd", "idleEnd"
				];
				ambient = 1;
				specular = 1;
				diffuse = 1;
				initYaw = -50;
				isGlass = true;
				viewX = 600;
				viewY = 600;
				if (isPlayer)
					posOffsets = [viewX / 2, -550];
				else
					posOffsets = [-viewX / 2, -550];
				if (isPlayer)
					camOffsets = [-viewX / 2, viewY / 2];
				else
					camOffsets = [viewX / 2, viewY / 2];

			case 'nogf':
				// frames = Paths.getSparrowAtlas("nogf");
				frames = Paths.getSparrowAtlasFunk("characters/nogf");
				animation.addByPrefix('idle', 'BUMP', 24, false);
				animation.play("idle");

				playAnim('idle');

			case 'gf' | 'gfSinger':
				// GIRLFRIEND CODE
				createAtlas();

				setAtlasAnim('cheer', 'GF CheerF');
				setAtlasAnim('singLEFT', 'GF left noteF');
				setAtlasAnim('singRIGHT', 'GF Right NoteF');
				setAtlasAnim('singUP', 'GF Up NoteF');
				setAtlasAnim('singDOWN', 'GF Down NoteF');
				setAtlasAnim('sad', 'gf sadF');
				setAtlasAnim('danceLeft', 'GF Dancing Beat LEFTF');
				setAtlasAnim('danceRight', 'GF Dancing Beat RIGHTF');
				setAtlasAnim('scared', 'GF FEARF', true);

				loadAtlas(Paths.getImageFunk("characters/gf/spritemap"), Paths.json("characters/gf/spritemap", "images"),
					Paths.json("characters/gf/Animation", "images"));

				var yOffet = -150;

				addOffset('cheer', -200, -449);
				addOffset('sad', -2, -18 + yOffet);
				addOffset('danceLeft', 0, -4 + yOffet);
				addOffset('danceRight', 0, 0 + yOffet);
				addOffset("singUP", 0, -11 + yOffet);
				addOffset("singRIGHT", 0, -5 + yOffet);
				addOffset("singLEFT", 0, -3 + yOffet);
				addOffset("singDOWN", 0, -31 + yOffet);
				addOffset('scared', -2, -17 + yOffet);

				playAnim('danceRight');

			case 'dad':
				// DAD ANIMATION LOADING CODE
				createAtlas();
				setAtlasAnim('idle', 'Dad idle danceF');
				setAtlasAnim('singUP', 'Dad Sing Note UPF');
				setAtlasAnim('singRIGHT', 'Dad Sing Note RIGHTF');
				setAtlasAnim('singDOWN', 'Dad Sing Note DOWNF');
				setAtlasAnim('singLEFT', 'Dad Sing Note LEFTF');
				setAtlasAnim('singUPmiss', 'Dad Sing Note UPmissF');
				setAtlasAnim('singRIGHTmiss', 'Dad Sing Note RIGHTmissF');
				setAtlasAnim('singDOWNmiss', 'Dad Sing Note DOWNmissF');
				setAtlasAnim('singLEFTmiss', 'Dad Sing Note LEFTmissF');
				loadAtlas(Paths.getImageFunk("characters/dad/spritemap"), Paths.json("characters/dad/spritemap", "images"),
					Paths.json("characters/dad/Animation", "images"));

				addOffset('idle');
				addOffset("singUP", -1, 61);
				addOffset("singRIGHT", -4, 26);
				addOffset("singLEFT", 38, 7);
				addOffset("singDOWN", 2, -8);
				addOffset("singUPmiss", -1, 61);
				addOffset("singRIGHTmiss", -4, 26);
				addOffset("singLEFTmiss", 38, 7);
				addOffset("singDOWNmiss", 2, -8);

				playAnim('idle');
			case 'spooky':
				// frames = Paths.getSparrowAtlas("spooky_kids_assets");
				frames = Paths.getSparrowAtlasFunk("characters/spooky_kids_assets");
				animation.addByPrefix('singUP', 'spooky UP NOTE', 24, false);
				animation.addByPrefix('singDOWN', 'spooky DOWN note', 24, false);
				animation.addByPrefix('singLEFT', 'note sing left', 24, false);
				animation.addByPrefix('singRIGHT', 'spooky sing right', 24, false);
				animation.addByIndices('danceLeft', 'spooky dance idle', [0, 2, 6], "", 12, false);
				animation.addByIndices('danceRight', 'spooky dance idle', [8, 10, 12, 14], "", 12, false);

				addOffset('danceLeft');
				addOffset('danceRight');

				addOffset("singUP", -18, 25);
				addOffset("singRIGHT", -130, -14);
				addOffset("singLEFT", 124, -13);
				addOffset("singDOWN", -46, -144);

				playAnim('danceRight');
			case 'mom':
				createAtlas();
				setAtlasAnim('idle', "Mom IdleF");
				setAtlasAnim('singUP', "Mom Up PoseF");
				setAtlasAnim('singDOWN', "MOM DOWN POSEF");
				setAtlasAnim('singLEFT', 'Mom Left PoseF');
				setAtlasAnim('singRIGHT', 'Mom Pose LeftF');
				setAtlasAnim('singUPmiss', "Mom Up PosemissF");
				setAtlasAnim('singDOWNmiss', "MOM DOWN POSEmissF");
				setAtlasAnim('singLEFTmiss', 'Mom Left PosemissF');
				setAtlasAnim('singRIGHTmiss', 'Mom Pose LeftmissF');
				loadAtlas(Paths.getImageFunk("characters/mom/spritemap"), Paths.json("characters/mom/spritemap", "images"),
					Paths.json("characters/mom/Animation", "images"));

				addOffset('idle', 0, -25);
				addOffset("singUP", 77, 46);
				addOffset("singRIGHT", -19, -79);
				addOffset("singLEFT", 280, -23);
				addOffset("singDOWN", 30, -232);
				addOffset("singUPmiss", 77, 46);
				addOffset("singRIGHTmiss", -19, -79);
				addOffset("singLEFTmiss", 280, -23);
				addOffset("singDOWNmiss", 30, -232);

				playAnim('idle');

			case 'pico':
				createAtlas();
				setAtlasAnim('idle', "Pico Idle DanceF");
				setAtlasAnim('singUP', 'pico Up noteF');
				setAtlasAnim('singDOWN', 'Pico Down NoteF');
				setAtlasAnim('singLEFT', 'Pico NOTE LEFTF');
				setAtlasAnim('singRIGHT', 'Pico Note RightF');
				setAtlasAnim('singRIGHTmiss', 'Pico Note Right MissF');
				setAtlasAnim('singLEFTmiss', 'Pico NOTE LEFT missF');
				setAtlasAnim('singUPmiss', 'pico Up note missF');
				setAtlasAnim('singDOWNmiss', 'Pico Down Note MISSF');
				setAtlasAnim('attack', 'pico shootF');
				loadAtlas(Paths.getImageFunk("characters/pico/spritemap"), Paths.json("characters/pico/spritemap", "images"),
					Paths.json("characters/pico/Animation", "images"));

				addOffset('idle');
				addOffset("singUP", 38, 65);
				addOffset("singLEFT", 100, -7);
				addOffset("singRIGHT", -50, 13);
				addOffset("singDOWN", 80, -74);
				addOffset("singUPmiss", 33, 69);
				addOffset("singLEFTmiss", 90, 28);
				addOffset("singRIGHTmiss", -44, 50);
				addOffset("singDOWNmiss", 76, -37);
				addOffset("attack", 321, 6);

				playAnim('idle');
				initFacing = FlxObject.LEFT;

			case 'bf':
				createAtlas();

				setAtlasAnim('idle', 'BF idle danceF');
				setAtlasAnim('singUP', 'BF NOTE UPF');
				setAtlasAnim('singLEFT', 'BF NOTE LEFTF');
				setAtlasAnim('singRIGHT', 'BF NOTE RIGHTF');
				setAtlasAnim('singDOWN', 'BF NOTE DOWNF');
				setAtlasAnim('singUPmiss', 'BF NOTE UP MISSF');
				setAtlasAnim('singLEFTmiss', 'BF NOTE LEFT MISSF');
				setAtlasAnim('singRIGHTmiss', 'BF NOTE RIGHT MISSF');
				setAtlasAnim('singDOWNmiss', 'BF NOTE DOWN MISSF');
				setAtlasAnim('hey', 'BF HEY!!F');
				// setAtlasAnim('attack', 'boyfriend attack');
				setAtlasAnim('hit', 'BF hit copyF');
				setAtlasAnim('dodge', 'boyfriend dodgeF');
				setAtlasAnim('scared', 'BF idle shakingF', true);

				loadAtlas(Paths.getImageFunk("characters/bf/spritemap"), Paths.json("characters/bf/spritemap", "images"),
					Paths.json("characters/bf/Animation", "images"));

				addOffset('idle', -5);
				addOffset("singUP", -21, 66);
				addOffset("singRIGHT", -51, 9);
				addOffset("singLEFT", -7, 3);
				addOffset("singDOWN", -26, -41);
				addOffset("singUPmiss", -21, 65);
				addOffset("singRIGHTmiss", -42, 18);
				addOffset("singLEFTmiss", -9, 14);
				addOffset("singDOWNmiss", -32, -22);
				addOffset("hey", -8, 8);
				addOffset('scared', -17, -5);
				addOffset('dodge', -1, -12);
				addOffset('hit', 17, 41);

				playAnim('idle');

				initFacing = FlxObject.LEFT;

			case 'senpai':
				antialiasing = false;
				frames = Paths.getSparrowAtlasFunk("characters/senpai");
				// animation.addByPrefix('idle', 'Senpai Idle', 24, false);
				animation.addByPrefix('danceLeft', 'Senpai IdleA', 24, false);
				animation.addByPrefix('danceRight', 'Senpai IdleB', 24, false);
				animation.addByPrefix('singUP', 'SENPAI UP NOTE', 24, false);
				animation.addByPrefix('singLEFT', 'SENPAI LEFT NOTE', 24, false);
				animation.addByPrefix('singRIGHT', 'SENPAI RIGHT NOTE', 24, false);
				animation.addByPrefix('singDOWN', 'SENPAI DOWN NOTE', 24, false);
				animation.addByPrefix('singUPmiss', 'Angry Senpai UP NOTE', 24, false);
				animation.addByPrefix('singLEFTmiss', 'Angry Senpai LEFT NOTE', 24, false);
				animation.addByPrefix('singRIGHTmiss', 'Angry Senpai RIGHT NOTE', 24, false);
				animation.addByPrefix('singDOWNmiss', 'Angry Senpai DOWN NOTE', 24, false);

				camOffsets = [0, 15];
				posOffsets = [0, 15];

				// addOffset('idle');
				addOffset('danceLeft');
				addOffset('danceRight');
				addOffset("singUP", 1, 6);
				addOffset("singRIGHT", 1);
				addOffset("singLEFT", 5);
				addOffset("singDOWN", 2);
				addOffset("singUPmiss", 1, 6);
				addOffset("singRIGHTmiss");
				addOffset("singLEFTmiss", 4, 1);
				addOffset("singDOWNmiss", 1, 1);

				// playAnim('idle');
				playAnim('danceRight');

				setGraphicSize(Std.int(width * 6));
				updateHitbox();

			case 'nothing':
				antialiasing = false;
				loadGraphic(FlxGraphic.fromRectangle(1, 1, FlxColor.TRANSPARENT));
		}

		initWidth = width;
		initFrameWidth = frameWidth;
		initHeight = height;
		setFacingFlip((initFacing == FlxObject.LEFT ? FlxObject.RIGHT : FlxObject.LEFT), true, false);
		// if (atlasContainer != null)
		// 	atlasContainer.setFacingFlip((initFacing == FlxObject.LEFT ? FlxObject.RIGHT : FlxObject.LEFT), true, false);

		dance();
	}

	public function loadCharacterFile(json:Dynamic) {
		isAnimateAtlas = false;

		facing = (isPlayer ? FlxObject.LEFT : FlxObject.RIGHT);

		#if flxanimate
		var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);
		if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
			isAnimateAtlas = true;
		#end

		scale.set(1, 1);
		updateHitbox();

		if (!isAnimateAtlas) {
			frames = Paths.getMultiAtlas(json.image.split(','));

			if (isModel) {
				modelView = new ModelView(viewX, viewY, ambient, specular, diffuse);
				loadGraphicFromSprite(modelView.sprite);
				antialiasing = true;
			}
			#if flxanimate
			else if (atlasActive) {
				if (facing != initFacing) {
					if (atlasContainer.animList.contains(animRedirect['singRIGHT'])) {
						var oldOffset = animOffsets['singRIGHT'];
						animOffsets['singRIGHT'] = animOffsets['singLEFT'];
						animOffsets['singLEFT'] = oldOffset;
						var oldRIGHT = animRedirect['singRIGHT'];
						animRedirect['singRIGHT'] = animRedirect['singLEFT'];
						animRedirect['singLEFT'] = oldRIGHT;
					}

					// IF THEY HAVE MISS ANIMATIONS??
					if (atlasContainer.animList.contains(animRedirect['singRIGHTmiss'])) {
						var oldOffset = animOffsets['singRIGHTmiss'];
						animOffsets['singRIGHTmiss'] = animOffsets['singLEFTmiss'];
						animOffsets['singLEFTmiss'] = oldOffset;
						var oldRIGHT = animRedirect['singRIGHTmiss'];
						animRedirect['singRIGHTmiss'] = animRedirect['singLEFTmiss'];
						animRedirect['singLEFTmiss'] = oldRIGHT;
					}

					if (atlasContainer.animList.contains(animRedirect['singRIGHT-alt'])) {
						var oldOffset = animOffsets['singRIGHT-alt'];
						animOffsets['singRIGHT-alt'] = animOffsets['singLEFT-alt'];
						animOffsets['singLEFT-alt'] = oldOffset;
						var oldRIGHT = animRedirect['singRIGHT-alt'];
						animRedirect['singRIGHT-alt'] = animRedirect['singLEFT-alt'];
						animRedirect['singLEFT-alt'] = oldRIGHT;
					}
					atlasContainer.finishCallback = animationEnd;
				} else {
					atlas = new FlxAnimate();
					atlas.showPivot = false;
					try
						if (facing != initFacing) {
							Paths.loadAnimateAtlas(atlas, json.image);
						} catch (e:haxe.Exception) {
						FlxG.log.warn('Could not load atlas ${json.image}: $e');
						trace(e.stack);
					}
			#end

					if (animation.getByName('singRIGHT') != null) {
						var oldRight = animation.getByName('singRIGHT').frames;
						var oldOffset = animOffsets['singRIGHT'];
						animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
						animOffsets['singRIGHT'] = animOffsets['singLEFT'];
						animation.getByName('singLEFT').frames = oldRight;
						animOffsets['singLEFT'] = oldOffset;
					}

					// IF THEY HAVE MISS ANIMATIONS??
					if (animation.getByName('singRIGHTmiss') != null) {
						var oldMiss = animation.getByName('singRIGHTmiss').frames;
						var oldOffset = animOffsets['singRIGHTmiss'];
						animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
						animOffsets['singRIGHTmiss'] = animOffsets['singLEFTmiss'];
						animation.getByName('singLEFTmiss').frames = oldMiss;
						animOffsets['singLEFTmiss'] = oldOffset;
					}

					if (animation.getByName('singRIGHT-alt') != null) {
						var oldRight = animation.getByName('singRIGHT-alt').frames;
						var oldOffset = animOffsets['singRIGHT-alt'];
						animation.getByName('singRIGHT-alt').frames = animation.getByName('singLEFT-alt').frames;
						animOffsets['singRIGHT-alt'] = animOffsets['singLEFT-alt'];
						animation.getByName('singLEFT-alt').frames = oldRight;
						animOffsets['singLEFT-alt'] = oldOffset;
					}

					// data
					healthIcon = json.healthicon;
					singDuration = json.sing_duration;
					flipX = (json.flip_x != isPlayer);
					healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
					vocalsFile = json.vocals_file != null ? json.vocals_file : '';
					originalFlipX = (json.flip_x == true);
					editorIsPlayer = json._editor_isPlayer;

					animation.finishCallback = animationEnd;
				}

				function createAtlas() {
					atlasActive = true;
					atlasContainer = new AtlasThing();
				}

				// animations
				animationsArray = json.animations;
				if (animationsArray != null && animationsArray.length > 0) {
					for (anim in animationsArray) {
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; // Bruh
						var animIndices:Array<Int> = anim.indices;

						if (!isAnimateAtlas) {
							if (animIndices != null && animIndices.length > 0)
								animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
							else
								animation.addByPrefix(animAnim, animName, animFps, animLoop);
						}
						#if flxanimate
						else {
							if (animIndices != null && animIndices.length > 0)
								atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
							else
								atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
						}
						#end
						if (anim.offsets != null && anim.offsets.length > 1)
							addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
						else
							addOffset(anim.anim, 0, 0);
					}
					#if flxanimate
					if (isAnimateAtlas)
						copyAtlasValues();
					#end
					// trace('Loaded file to character ' + curCharacter);

					function loadAtlas(spritemap:FlxGraphicAsset, spritemapJson:String, animationJson:String) {
						// atlasActive = true;
						// atlasContainer = new AtlasThing();
						atlasContainer.loadAtlas(spritemap, spritemapJson, animationJson);
						loadGraphic(FlxGraphic.fromRectangle(1, 1, FlxColor.TRANSPARENT));
						add(atlasContainer);
					}

					override function update(elapsed:Float) {
						if (isAnimateAtlas)
							atlas.update(elapsed);

						tryLoadModel();

						if (debugMode
							|| (!isAnimateAtlas && animation.curAnim == null)
							|| (isAnimateAtlas && (atlas.anim.curInstance == null || atlas.anim.curSymbol == null)))
							if (isModel && model != null && model.fullyLoaded && modelView != null) {
								super.update(elapsed);
								return;

								modelView.update();
								model.update();
							}

						if (heyTimer > 0)
							if (!isPlayer || PlayState.autoPlay) {
								var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
								heyTimer -= elapsed * rate;
								if (heyTimer <= 0)
									if (getCurAnim().startsWith('sing')) {
										var anim:String = getAnimationName();
										if (specialAnim && (anim == 'hey' || anim == 'cheer')) {
											specialAnim = false;
											dance();
										}
										heyTimer = 0;

										holdTimer += elapsed;
									} else if (specialAnim && isAnimationFinished()) {
										specialAnim = false;
										dance();
									} else if (getAnimationName().endsWith('miss') && isAnimationFinished()) {
										dance();
										finishAnimation();

										var dadVar:Float = 4;

										if (curCharacter == 'dad')
											dadVar = 6.1;
										if (holdTimer >= Conductor.stepCrochet * dadVar * 0.001) {
											idleEnd();
											holdTimer = 0;
										}

										switch (curCharacter) switch (curCharacter) {
											case 'pico-speaker':
												if (animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0]) {
													var noteData:Int = 1;
													if (animationNotes[0][1] > 2)
														noteData = 3;

													noteData += FlxG.random.int(0, 1);
													playAnim('shoot' + noteData, true);
													animationNotes.shift();
												}
												if (isAnimationFinished())
													playAnim(getAnimationName(), false, false, animation.curAnim.frames.length - 3);
										}

										if (getAnimationName().startsWith('sing'))
											holdTimer += elapsed;
										else if (isPlayer)
											holdTimer = 0;

										if (!isPlayer
											&& holdTimer >= Conductor.stepCrochet * (0.0011 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end) * singDuration) {
											dance();
											holdTimer = 0;
										}

										var name:String = getAnimationName();
										if (isAnimationFinished() && hasAnimation('$name-loop'))
											playAnim('$name-loop');

										case 'gf':
											if (getCurAnim() == 'hairFall' && getCurAnimFinished())
												playAnim('danceRight');
									}

								super.update(elapsed);
							}
						inline public function isAnimationNull():Bool {
							return !isAnimateAtlas ? (animation.curAnim == null) : (atlas.anim.curInstance == null || atlas.anim.curSymbol == null);
						}

						var _lastPlayedAnimation:String;

						inline public function getAnimationName():String {
							return _lastPlayedAnimation;
						}

						public function isAnimationFinished():Bool {
							if (isAnimationNull())
								return false;
							return !isAnimateAtlas ? animation.curAnim.finished : atlas.anim.finished;
						}

						public function finishAnimation():Void {
							if (isAnimationNull())
								return;

							if (!isAnimateAtlas)
								animation.curAnim.finish();
							else
								atlas.anim.curFrame = atlas.anim.length - 1;
						}

						public function hasAnimation(anim:String):Bool {
							return animOffsets.exists(anim);
						}

						public var animPaused(get, set):Bool;

						private function get_animPaused():Bool {
							if (isAnimationNull())
								return false;
							return !isAnimateAtlas ? animation.curAnim.paused : atlas.anim.isPlaying;
						}

						private function set_animPaused(value:Bool):Bool {
							if (isAnimationNull())
								return value;
							if (!isAnimateAtlas)
								animation.curAnim.paused = value;
							else {
								if (value)
									atlas.pauseAnimation();
								else
									atlas.resumeAnimation();
							}

							return value;
						}

						public var danced:Bool = false;
						private var danced:Bool = false;

						/**
				 * FOR GF DANCING SHIT
				 */
						public function dance(?ignoreDebug:Bool = false) {
							// cleaned TNT + Psych merged version
							if (!specialAnim && !skipDance)
								playAnim('idle', true);
						}

						case 'senpai':
							danced = !danced;

							if (danced)
								playAnim('danceRight', true);
							else
								playAnim('danceLeft', true);

						case 'spooky':
							danced = !danced;

							if (danced)
								playAnim('danceRight', true);
							else
								playAnim('danceLeft', true);
						default:
							if (holdTimer == 0)
								playAnim('idle', true);
					}
				else if (holdTimer == 0) {
					if (isModel && model == null) {
						trace("NO DANCE - NO MODEL");
						return;
					}
					if (isModel && !model.fullyLoaded) {
						trace("NO DANCE - NO FULLY LOAD");
						return;
					}
					if (isModel && !noLoopList.contains('idle'))
						return;
					playAnim('idle', true);
				}

					public function idleEnd(?ignoreDebug:Bool = false) {
						if (curCharacter == 'nothing')
							return;

						if (!isModel && (!debugMode || ignoreDebug) && !atlasActive) {
							switch (curCharacter) {
								case 'gf' | 'gf-car' | 'gf-christmas' | 'gf-pixel' | "spooky" | "senpai" | "gfSinger":
									playAnim('danceRight', true, false, animation.getByName('danceRight').numFrames - 1);
								default:
									playAnim('idle', true, false, animation.getByName('idle').numFrames - 1);
							}
						else if (!isModel && (!debugMode || ignoreDebug)) {
							switch (curCharacter) {
								case 'gf' | 'gf-car' | 'gf-christmas' | 'gf-pixel' | "spooky" | "senpai" | "gfSinger":
									playAnim('danceRight', true, false, atlasContainer.maxIndex[animRedirect['danceRight']]);
								default:
									playAnim('idle', true, false, atlasContainer.maxIndex[animRedirect['idle']]);
							}
						else if (isModel && (!debugMode || ignoreDebug)) {
							if (animExists(getCurAnim() + "End"))
								playAnim(getCurAnim() + "End", true, false);
							else
								playAnim('idleEnd', true, false);
						}

							var curAtlasAnim:String;

							canAutoIdle = true;
						}

							public function addOffset(name:String, x:Float = 0, y:Float = 0) {
								animOffsets[name] = [x, y];
							}

							function animationEnd(name:String) {
								if (isModel) {} else {
									atlas.anim.play(AnimName, Force, Reversed, Frame);
									atlas.update(0);
								}
								_lastPlayedAnimation = AnimName;

								if (hasAnimation(AnimName)) {
									var daOffset = animOffsets.get(AnimName);
									offset.set(daOffset[0], daOffset[1]);
								}
								// else offset.set(0, 0);

								var theAnim = (atlasActive ? getCurAnim() : name);
								switch (curCharacter) {
									case "dad" | "mom" | "mom-car" | "bf-car":
										if (!theAnim.contains('miss')) {
											playAnim(theAnim, true, false, getFrameCount(theAnim) - 4);
										}

										if (curCharacter.startsWith('gf-') || curCharacter == 'gf') {
											if (AnimName == 'singLEFT')
												danced = true;

											case "bf" | "bf-christmas":
												if (theAnim.contains("miss")) {
													playAnim(theAnim, true, false, getFrameCount(theAnim) - 4);
												} else if (AnimName == 'singRIGHT')
													danced = false;

												if (AnimName == 'singUP' || AnimName == 'singDOWN') danced = !danced;
										}

										function loadMappedAnims():Void {
											try {
												var songData:SwagSong = Song.getChart('picospeaker', Paths.formatToSongPath(Song.loadedSongName));
												if (songData != null)
													for (section in songData.notes)
														for (songNotes in section.sectionNotes)
															animationNotes.push(songNotes);

												TankmenBG.animationNotes = animationNotes;
												animationNotes.sort(sortAnims);

												case "monster-christmas" | "monster":
													switch (theAnim) {
														case "idle":
															playAnim(theAnim, false, false, 10);
														case "singUP":
															playAnim(theAnim, false, false, 8);
														case "singDOWN":
															playAnim(theAnim, false, false, 7);
														case "singLEFT":
															playAnim(theAnim, false, false, 5);
														case "singRIGHT":
															playAnim(theAnim, false, false, 6);
													}
											} catch (e:Dynamic) {}

											function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int {
												return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
											}

											var theAnim = (atlasActive ? getCurAnim() : name);
											if (theAnim == 'dodge' || theAnim == 'hit' || theAnim == 'attack') {
												canAutoIdle = true;
												idleEnd();
											}
											public var danceEveryNumBeats:Int = 2;
											private var settingCharacterUp:Bool = true;

											public function recalculateDanceIdle() {
												var lastDanceIdle:Bool = danceIdle;
												danceIdle = (hasAnimation('danceLeft' + idleSuffix) && hasAnimation('danceRight' + idleSuffix));

												public function getCurAnim() {
													if (curCharacter == 'nothing')
														return "";

													if (settingCharacterUp)
														if (isModel) {
															danceEveryNumBeats = (danceIdle ? 1 : 2);
														} else if (lastDanceIdle != danceIdle) {
															var calc:Float = danceEveryNumBeats;
															if (danceIdle)
																calc /= 2;

															if (model != null && model.fullyLoaded)
																return model.currentAnim;
															else
																calc *= 2;

															danceEveryNumBeats = Math.round(Math.max(calc, 1));

															return "";
														}
													settingCharacterUp = false;
												}

												public function addOffset(name:String, x:Float = 0, y:Float = 0) {
													animOffsets[name] = [x, y];
												}

												public function quickAnimAdd(name:String, anim:String) {
													animation.addByPrefix(name, anim, 24, false);

												else if (atlasActive) {
													return curAtlasAnim;
												} else
													return animation.curAnim.name;
												}

												// Atlas support
												// special thanks ne_eo for the references, you're the goat!!
												@:allow(states.editors.CharacterEditorState)
												public var isAnimateAtlas(default, null):Bool = false;
												#if flxanimate
												public var atlas:FlxAnimate;
												public override function draw() {
													var lastAlpha:Float = alpha;
													var lastColor:FlxColor = color;
													if (missingCharacter) {
														alpha *= 0.6;
														color = FlxColor.BLACK;
													}

													public function getFrameCount(name:String) {
														if (atlasActive) {
															return atlasContainer.maxIndex[animRedirect[name]] + 1;
														} else if (!isModel) {
															return animation.getByName(name).numFrames;
														}
														return -1;
													}

													if (isAnimateAtlas) {
														if (atlas.anim.curInstance != null) {
															copyAtlasValues();
															atlas.draw();
															alpha = lastAlpha;
															color = lastColor;
															if (missingCharacter && visible) {
																missingText.x = getMidpoint().x - 150;
																missingText.y = getMidpoint().y - 10;
																missingText.draw();
															}

															public function getCurAnimFinished() {
																if (atlasActive)
																	return atlasContainer.curAnimFinished;
																else
																	return animation.curAnim.finished;
															}

															public function animExists(anim:String) {
																if (isModel) {
																	if (model != null && model.fullyLoaded)
																		return model.animationSet.hasAnimation(anim);
																	else
																		return false;
																} else if (atlasActive) {
																	return atlasContainer.animList.contains(animRedirect[anim]);
																} else
																	return animation.getByName(anim) != null;
															}

															override public function updateHitbox():Void {
																width = Math.abs(scale.x) * frameWidth;
																height = Math.abs(scale.y) * frameHeight;
																if (!atlasActive) {
																	offset.set(-0.5 * (width - frameWidth), -0.5 * (height - frameHeight));
																	centerOrigin();
																}

																function setAtlasAnim(name:String, animName:String, looping:Bool = false) {
																	animRedirect[name] = animName;
																	atlasContainer.setLooping(animName, looping);
																	atlasContainer.onlyTheseAnims.push(animName);
																}

																public function tryLoadModel() {
																	if (!isModel)
																		return;
																}
																super.draw();
																if (missingCharacter && visible)
																	if (modelMutex)
																		return;
																if (isModel && beganLoading)
																	return;
																if (isModel && !beganLoading) {
																	alpha = lastAlpha;
																	color = lastColor;
																	missingText.x = getMidpoint().x - 150;
																	missingText.y = getMidpoint().y - 10;
																	missingText.draw();

																	beganLoading = true;
																	modelMutex = true;
																	model = new ModelThing(this);
																	modelMutexThing = model;
																}

																public function copyAtlasValues()

																	override public function destroy() {
																		@:privateAccess
																		if (isModel) {
																			atlas.cameras = cameras;
																			atlas.scrollFactor = scrollFactor;
																			atlas.scale = scale;
																			atlas.offset = offset;
																			atlas.origin = origin;
																			atlas.x = x;
																			atlas.y = y;
																			atlas.angle = angle;
																			atlas.alpha = alpha;
																			atlas.visible = visible;
																			atlas.flipX = flipX;
																			atlas.flipY = flipY;
																			atlas.shader = shader;
																			atlas.antialiasing = antialiasing;
																			atlas.colorTransform = colorTransform;
																			atlas.color = color;
																		}

																		public override function destroy() {
																			atlas = FlxDestroyUtil.destroy(atlas);

																			if (modelMutexThing == model) {
																				modelMutexThing = null;
																				modelMutex = false;
																			}
																			if (model != null)
																				model.destroy();
																			model = null;
																			if (modelView != null)
																				modelView.destroy();
																			modelView = null;
																			if (animSpeed != null) {
																				animSpeed.clear();
																				animSpeed = null;
																			}
																			if (animRedirect != null) {
																				animRedirect.clear();
																				animRedirect = null;
																			}
																			if (animRedirect != null) {
																				animRedirect.clear();
																				animRedirect = null;
																			}
																			// atlasContainer = FlxDestroyUtil.destroy(atlasContainer);
																			super.destroy();
																		}
												#end
																}
															}
													}
												}
											}
										}
									}
								}
							}
}}}}}}}
