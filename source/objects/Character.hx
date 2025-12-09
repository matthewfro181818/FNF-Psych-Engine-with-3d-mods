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
import flixel.system.FlxAssets.FlxGraphicAsset;
import openfl.display.BitmapData;
import flixel.FlxG;
import openfl.display3D.Context3DTextureFormat;
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

class Character extends FlxNestedSprite
{
	// =====================================================================
	// BASE CONFIG
	// =====================================================================

	public static final DEFAULT_CHARACTER:String = "bf";

	public var curCharacter:String = "";
	public var isPlayer:Bool = false;

	// =====================================================================
	// ANIMATION + STATE
	// =====================================================================

	public var animation:PsychAnimationController;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;

	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;

	public var singDuration:Float = 4;
	public var idleSuffix:String = "";
	public var danceIdle:Bool = false;
	public var skipDance:Bool = false;

	public var healthIcon:String = "face";
	public var animationsArray:Array<AnimArray> = [];

	public var canAutoAnim:Bool = true;
	public var canAutoIdle:Bool = true;

	public var animOffsets:Map<String, Array<Float>> = [];
	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var initFacing:Int = FlxObject.RIGHT;

	public var initWidth:Float = -1;
	public var initFrameWidth:Int = -1;
	public var initHeight:Float = -1;

	public var camOffsets:Array<Float> = [0, 0];
	public var posOffsets:Array<Float> = [0, 0];

	// =====================================================================
	// EDITOR DATA
	// =====================================================================

	public var imageFile:String = "";
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;

	// =====================================================================
	// MODEL (3D) SYSTEM
	// =====================================================================

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

	// =====================================================================
	// ATLAS / FLXANIMATE SUPPORT
	// =====================================================================

	public var atlasActive:Bool = false;
	public var atlasContainer:AtlasThing;
	public var animRedirect:Map<String, String> = [];

	#if flxanimate
	public var atlas:FlxAnimate;
	public var isAnimateAtlas:Bool = false;
	#end

	// =====================================================================
	// DANCE + MISC STATE
	// =====================================================================

	public var danced:Bool = false;
	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;

	// Track name of last played animation
	var _lastPlayedAnimation:String = "";

	// =====================================================================
	// CONSTRUCTOR
	// =====================================================================

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false)
	{
		super(x, y);

		this.isPlayer = isPlayer;
		curCharacter = character;

		animation = new PsychAnimationController(this);

		changeCharacter(curCharacter);
	}

	// =====================================================================
	// CHANGE CHARACTER
	// =====================================================================

	public function changeCharacter(character:String):Void
	{
		curCharacter = character;
		animationsArray = [];
		animOffsets = [];

		skipDance = false;
		danceIdle = false;
		specialAnim = false;

		atlasActive = false;
		#if flxanimate
		isAnimateAtlas = false;
		#end

		var characterPath:String = 'characters/$character.json';
		// -----------------------------------------------------------------
		// CONTINUATION OF changeCharacter(character:String)
		// -----------------------------------------------------------------
		switch (curCharacter)
		{
			// -------------------------------------------------------------
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");

			// -------------------------------------------------------------
			case 'pico-blazin' | 'darnell-blazin':
				skipDance = true;

			// -------------------------------------------------------------
			case 'spirit':
				frames = Paths.getSparrowAtlasFunk('characters/spirit');
				animation.addByPrefix('idle', 'idle spirit', 24, false);
				animation.addByPrefix('singUP', 'up', 24, false);
				animation.addByPrefix('singRIGHT', 'right', 24, false);
				animation.addByPrefix('singLEFT', 'left', 24, false);
				animation.addByPrefix('singDOWN', 'spirit down', 24, false);

				addOffset('idle', 0, 0);
				addOffset('singUP', -3, 20);
				addOffset('singRIGHT', -10, 0);
				addOffset('singLEFT', 10, 0);
				addOffset('singDOWN', 0, -10);

				antialiasing = false;

				setGraphicSize(Std.int(width * 6));
				playAnim('idle');
				updateHitbox();

				try {
					#if MODS_ALLOWED
					loadCharacterFile(Json.parse(sys.io.File.getContent(characterPath)));
					#else
					loadCharacterFile(Json.parse(Assets.getText(characterPath)));
					#end
				} catch (e:Dynamic) {
					trace('Error loading character file "$character": $e');
				}

			// -------------------------------------------------------------
			case 'tankman':
				createAtlas();
				setAtlasAnim('idle', "idle");
				setAtlasAnim('singUP', "singUP");
				setAtlasAnim('singUP-alt', "singRIGHT-alt");
				setAtlasAnim('singDOWN', "singDOWN");
				setAtlasAnim('singLEFT', "singLEFT");
				setAtlasAnim('singRIGHT', "singRIGHT");
				setAtlasAnim('singRIGHTmiss', "singRIGHTmiss");
				setAtlasAnim('singLEFTmiss', "singLEFTmiss");
				setAtlasAnim('singUPmiss', "singUPmiss");
				setAtlasAnim('singDOWNmiss', "singDOWNmiss");

				loadAtlas(
					Paths.getImageFunk("characters/tankman/spritemap1"),
					Paths.json("characters/tankman/spritemap1","images"),
					Paths.json("characters/tankman/Animation","images")
				);

				addOffset('idle');
				addOffset("singUP", 17, 58);
				addOffset("singLEFT", 86, -29);
				addOffset("singRIGHT", -21, 4);
				addOffset("singDOWN", 56, -103);
				addOffset("singUPmiss", 17, 56);
				addOffset("singLEFTmiss", 90, -29);
				addOffset("singRIGHTmiss", -21, 5);
				addOffset("singDOWNmiss", 53, -99);

				playAnim('idle');
				initFacing = FlxObject.LEFT;

			// -------------------------------------------------------------
			case 'atlanta':
				frames = Paths.getSparrowAtlasFunk("characters/atlanta");
				animation.addByPrefix('idle','idle',12,false);
				animation.addByPrefix('singDOWN','singDOWN',12,false);
				animation.addByPrefix('singDOWNmiss','missDOWN',12,false);
				animation.addByPrefix('singLEFTmiss','missLEFT',12,false);
				animation.addByPrefix('singRIGHTmiss','missRIGHT',12,false);
				animation.addByPrefix('singUPmiss','missUP',12,false);
				animation.addByPrefix('singLEFT','singLEFT',12,false);
				animation.addByPrefix('singRIGHT','singRIGHT',12,false);
				animation.addByPrefix('singUP','singUP',12,false);

				addOffset('idle');
				addOffset("singDOWN", -4, -135);
				addOffset("singLEFT", -18, -27);
				addOffset("singRIGHT", -2, 2);
				addOffset("singUP", 20, 38);

				playAnim('idle');
				posOffsets = [-180, 0];
				camOffsets = [180, 0];

			// -------------------------------------------------------------
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

				loadAtlas(
					Paths.getImageFunk("characters/lily/spritemap1"),
					Paths.json("characters/lily/spritemap1","images"),
					Paths.json("characters/lily/Animation","images")
				);

				addOffset('idle');
				addOffset("singDOWN", 108, -181);
				addOffset("singUP", 225, 77);
				addOffset("singLEFT", 131, -2);
				addOffset("singRIGHT", -2, -23);

				playAnim('idle');

			// -------------------------------------------------------------
			case 'prisma':
				isModel = true;
				modelName = "prisma";
				modelScale = 50;

				var multiplier = Conductor.bpm / 100;
				animSpeed = [
					"default" => 2.1 * multiplier,
					"idle" => 1.5 * multiplier,
					"singLEFT" => 2.5 * multiplier
				];
				for (thing in ["singUPEnd","singLEFTEnd","singRIGHTEnd","singDOWNEnd"])
					animSpeed[thing] = 1.5;

				noLoopList = [
					"idle","singUP","singDOWN","singLEFT","singRIGHT",
					"singUPEnd","singLEFTEnd","singRIGHTEnd","singDOWNEnd","idleEnd"
				];

				ambient = 1;
				specular = 1;
				diffuse = 1;
				initYaw = -50;
				isGlass = true;

				viewX = 600;
				viewY = 600;

				if (isPlayer) posOffsets = [viewX/2, -550];
				else          posOffsets = [-viewX/2, -550];

				if (isPlayer) camOffsets = [-viewX/2, viewY/2];
				else          camOffsets = [viewX/2, viewY/2];

			// -------------------------------------------------------------
			case 'nogf':
				frames = Paths.getSparrowAtlasFunk("characters/nogf");
				animation.addByPrefix('idle','BUMP',24,false);
				playAnim('idle');

			// -------------------------------------------------------------
			case 'gf' | 'gfSinger':
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

				loadAtlas(
					Paths.getImageFunk("characters/gf/spritemap"),
					Paths.json("characters/gf/spritemap","images"),
					Paths.json("characters/gf/Animation","images")
				);

				var yOff:Float = -150;

				addOffset('cheer', -200, -449);
				addOffset('sad', -2, -18 + yOff);
				addOffset('danceLeft', 0, -4 + yOff);
				addOffset('danceRight', 0, 0 + yOff);
				addOffset("singUP", 0, -11 + yOff);
				addOffset("singRIGHT", 0, -5 + yOff);
				addOffset("singLEFT", 0, -3 + yOff);
				addOffset("singDOWN", 0, -31 + yOff);
				addOffset('scared', -2, -17 + yOff);

				playAnim('danceRight');

			// -------------------------------------------------------------
			case 'dad':
				createAtlas();
				setAtlasAnim('idle','Dad idle danceF');
				setAtlasAnim('singUP','Dad Sing Note UPF');
				setAtlasAnim('singRIGHT','Dad Sing Note RIGHTF');
				setAtlasAnim('singDOWN','Dad Sing Note DOWNF');
				setAtlasAnim('singLEFT','Dad Sing Note LEFTF');
				setAtlasAnim('singUPmiss','Dad Sing Note UPmissF');
				setAtlasAnim('singRIGHTmiss','Dad Sing Note RIGHTmissF');
				setAtlasAnim('singDOWNmiss','Dad Sing Note DOWNmissF');
				setAtlasAnim('singLEFTmiss','Dad Sing Note LEFTmissF');

				loadAtlas(
					Paths.getImageFunk("characters/dad/spritemap"),
					Paths.json("characters/dad/spritemap","images"),
					Paths.json("characters/dad/Animation","images")
				);

				addOffset('idle');
				addOffset("singUP", -1, 61);
				addOffset("singRIGHT", -4, 26);
				addOffset("singLEFT", 38, 7);
				addOffset("singDOWN", 2, -8);

				playAnim('idle');
				initFacing = FlxObject.LEFT;

			// -------------------------------------------------------------
			case 'spooky':
				frames = Paths.getSparrowAtlasFunk("characters/spooky_kids_assets");
				animation.addByPrefix('singUP','spooky UP NOTE',24,false);
				animation.addByPrefix('singDOWN','spooky DOWN note',24,false);
				animation.addByPrefix('singLEFT','note sing left',24,false);
				animation.addByPrefix('singRIGHT','spooky sing right',24,false);
				animation.addByIndices('danceLeft','spooky dance idle',[0,2,6],"",12,false);
				animation.addByIndices('danceRight','spooky dance idle',[8,10,12,14],"",12,false);

				addOffset('danceLeft');
				addOffset('danceRight');
				addOffset("singUP", -18, 25);
				addOffset("singRIGHT", -130, -14);
				addOffset("singLEFT", 124, -13);
				addOffset("singDOWN", -46, -144);

				playAnim('danceRight');

			// -------------------------------------------------------------
			case 'mom':
				createAtlas();
				setAtlasAnim('idle','Mom IdleF');
				setAtlasAnim('singUP','Mom Up PoseF');
				setAtlasAnim('singDOWN','MOM DOWN POSEF');
				setAtlasAnim('singLEFT','Mom Left PoseF');
				setAtlasAnim('singRIGHT','Mom Pose LeftF');

				loadAtlas(
					Paths.getImageFunk("characters/mom/spritemap"),
					Paths.json("characters/mom/spritemap","images"),
					Paths.json("characters/mom/Animation","images")
				);

				addOffset('idle', 0, -25);
				addOffset("singUP", 77, 46);
				addOffset("singRIGHT", -19, -79);
				addOffset("singLEFT", 280, -23);
				addOffset("singDOWN", 30, -232);

				playAnim('idle');

			// -------------------------------------------------------------
			case 'pico':
				createAtlas();
				setAtlasAnim('idle','Pico Idle DanceF');
				setAtlasAnim('singUP','pico Up noteF');
				setAtlasAnim('singDOWN','Pico Down NoteF');
				setAtlasAnim('singLEFT','Pico NOTE LEFTF');
				setAtlasAnim('singRIGHT','Pico Note RightF');
				setAtlasAnim('singRIGHTmiss','Pico Note Right MissF');
				setAtlasAnim('singLEFTmiss','Pico NOTE LEFT missF');
				setAtlasAnim('singUPmiss','pico Up note missF');
				setAtlasAnim('singDOWNmiss','Pico Down Note MISSF');
				setAtlasAnim('attack','pico shootF');

				loadAtlas(
					Paths.getImageFunk("characters/pico/spritemap"),
					Paths.json("characters/pico/spritemap","images"),
					Paths.json("characters/pico/Animation","images")
				);

				addOffset('idle');
				addOffset("singUP", 38, 65);
				addOffset("singLEFT", 100, -7);
				addOffset("singRIGHT", -50, 13);
				addOffset("singDOWN", 80, -74);

				playAnim('idle');
				initFacing = FlxObject.LEFT;

			// -------------------------------------------------------------
			case 'bf':
				createAtlas();
				setAtlasAnim('idle','BF idle danceF');
				setAtlasAnim('singUP','BF NOTE UPF');
				setAtlasAnim('singLEFT','BF NOTE LEFTF');
				setAtlasAnim('singRIGHT','BF NOTE RIGHTF');
				setAtlasAnim('singDOWN','BF NOTE DOWNF');
				setAtlasAnim('singUPmiss','BF NOTE UP MISSF');
				setAtlasAnim('singLEFTmiss','BF NOTE LEFT MISSF');
				setAtlasAnim('singRIGHTmiss','BF NOTE RIGHT MISSF');
				setAtlasAnim('singDOWNmiss','BF NOTE DOWN MISSF');
				setAtlasAnim('hey','BF HEY!!F');
				setAtlasAnim('hit','BF hit copyF');
				setAtlasAnim('dodge','boyfriend dodgeF');
				setAtlasAnim('scared','BF idle shakingF',true);

				loadAtlas(
					Paths.getImageFunk("characters/bf/spritemap"),
					Paths.json("characters/bf/spritemap","images"),
					Paths.json("characters/bf/Animation","images")
				);

				addOffset('idle', -5);
				addOffset("singUP", -21, 66);
				addOffset("singRIGHT", -51, 9);
				addOffset("singLEFT", -7, 3);
				addOffset("singDOWN", -26, -41);

				playAnim('idle');
				initFacing = FlxObject.LEFT;

			// -------------------------------------------------------------
			case 'senpai':
				antialiasing = false;
				frames = Paths.getSparrowAtlasFunk("characters/senpai");

				animation.addByPrefix('danceLeft','Senpai IdleA',24,false);
				animation.addByPrefix('danceRight','Senpai IdleB',24,false);
				animation.addByPrefix('singUP','SENPAI UP NOTE',24,false);
				animation.addByPrefix('singLEFT','SENPAI LEFT NOTE',24,false);
				animation.addByPrefix('singRIGHT','SENPAI RIGHT NOTE',24,false);
				animation.addByPrefix('singDOWN','SENPAI DOWN NOTE',24,false);
				animation.addByPrefix('singUPmiss','Angry Senpai UP NOTE',24,false);

				camOffsets = [0, 15];
				posOffsets = [0, 15];

				addOffset('danceLeft');
				addOffset('danceRight');
				addOffset("singUP", 1, 6);
				addOffset("singRIGHT", 1);
				addOffset("singLEFT", 5);
				addOffset("singDOWN", 2);

				playAnim('danceRight');

			// -------------------------------------------------------------
			case 'nothing':
				antialiasing = false;
				loadGraphic(FlxGraphic.fromRectangle(1,1,FlxColor.TRANSPARENT));
		}

		// -------------------------------------------------------------
		// POST-PROCESSING
		// -------------------------------------------------------------
		initWidth = width;
		initFrameWidth = frameWidth;
		initHeight = height;

		setFacingFlip(
			(initFacing == FlxObject.LEFT ? FlxObject.RIGHT : FlxObject.LEFT),
			true, false
		);

		dance();
	}



	// =====================================================================
	// LOAD CHARACTER FILE
	// =====================================================================

	public function loadCharacterFile(json:Dynamic):Void
	{
		#if flxanimate
		isAnimateAtlas = false;
		#end

		imageFile = json.image;
		jsonScale = json.scale != null ? json.scale : 1;
		singDuration = json.sing_duration;
		healthIcon = json.healthicon;
		flipX = (json.flip_x != isPlayer);
		noAntialiasing = json.no_antialiasing;
		healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2)
			? json.healthbar_colors : [161,161,161];
		editorIsPlayer = json._editor_isPlayer;
		originalFlipX = json.flip_x;

		scale.set(1,1);
		antialiasing = !noAntialiasing;

		#if flxanimate
		var animJsonPath = Paths.getPath('images/' + imageFile + '/Animation.json', TEXT);
		if ((#if MODS_ALLOWED sys.FileSystem.exists(animJsonPath) #else Assets.exists(animJsonPath) #end))
			isAnimateAtlas = true;
		#end

		//---------------------------------------------------------
		// Non-flxAnimate: load sparrow/multiatlas
		//---------------------------------------------------------
		if (!isAnimateAtlas)
		{
			frames = Paths.getMultiAtlas(imageFile.split(","));
			updateHitbox();

			// MODEL loading
			if (isModel)
			{
				modelView = new ModelView(viewX, viewY, ambient, specular, diffuse);
				loadGraphicFromSprite(modelView.sprite);
				antialiasing = true;
			}
			// AtlasThing (custom atlas system)
			else if (atlasActive)
			{
				if (facing != initFacing)
				{
					if (atlasContainer.animList.contains(animRedirect['singRIGHT']))
					{
						swapAnimOffsets('singRIGHT','singLEFT');
						swapRedirect('singRIGHT','singLEFT');
					}
					if (atlasContainer.animList.contains(animRedirect['singRIGHTmiss']))
					{
						swapAnimOffsets('singRIGHTmiss','singLEFTmiss');
						swapRedirect('singRIGHTmiss','singLEFTmiss');
					}
					if (atlasContainer.animList.contains(animRedirect['singRIGHT-alt']))
					{
						swapAnimOffsets('singRIGHT-alt','singLEFT-alt');
						swapRedirect('singRIGHT-alt','singLEFT-alt');
					}
				}

				atlasContainer.finishCallback = animationEnd;
			}

			// Normal animation swapping if facing reversed
			if (!isAnimateAtlas && !atlasActive)
			{
				if (facing != initFacing)
				{
					swapAnimFrames("singRIGHT","singLEFT");
					swapAnimFrames("singRIGHTmiss","singLEFTmiss");
					swapAnimFrames("singRIGHT-alt","singLEFT-alt");
				}
			}
		}

		//---------------------------------------------------------
		// flxAnimate atlas loading
		//---------------------------------------------------------
		#if flxanimate
		if (isAnimateAtlas)
		{
			atlas = new FlxAnimate();
			atlas.showPivot = false;

			try { Paths.loadAnimateAtlas(atlas, imageFile); }
			catch(e:Dynamic)
			{
				FlxG.log.warn("Could not load Animate atlas for " + imageFile + ": " + e);
			}

			copyAtlasValues();
		}
		#end

		//---------------------------------------------------------
		// Load animations from JSON
		//---------------------------------------------------------
		if (json.animations != null)
		{
			for (anim in json.animations)
			{
				animationsArray.push(anim);

				var animName = anim.anim;
				var prefix = anim.name;
				var fps = anim.fps;
				var loop = anim.loop;

				var offs = anim.offsets;

				// AtlasThing
				if (atlasActive)
				{
					animRedirect[animName] = prefix;
					atlasContainer.onlyTheseAnims.push(prefix);
					atlasContainer.setLooping(prefix, loop);

					if (offs != null && offs.length > 1)
						addOffset(animName, offs[0], offs[1]);
					else
						addOffset(animName, 0, 0);
				}
				else
				{
					// Normal sparrow/multiatlas
					if (anim.indices != null && anim.indices.length > 0)
						animation.addByIndices(animName, prefix, anim.indices, "", fps, loop);
					else
						animation.addByPrefix(animName, prefix, fps, loop);

					if (offs != null && offs.length > 1)
						addOffset(animName, offs[0], offs[1]);
					else
						addOffset(animName, 0, 0);
				}
			}
		}

		animation.finishCallback = animationEnd;
		updateHitbox();
	}


	// =====================================================================
	// SWAP HELPERS
	// =====================================================================

	private inline function swapAnimOffsets(a:String, b:String):Void
	{
		if (!animOffsets.exists(a) || !animOffsets.exists(b)) return;
		var oa = animOffsets[a];
		animOffsets[a] = animOffsets[b];
		animOffsets[b] = oa;
	}

	private inline function swapRedirect(a:String, b:String):Void
	{
		var oa = animRedirect[a];
		animRedirect[a] = animRedirect[b];
		animRedirect[b] = oa;
	}

	private inline function swapAnimFrames(a:String, b:String):Void
	{
		if (animation.getByName(a) != null && animation.getByName(b) != null)
		{
			var fa = animation.getByName(a).frames;
			var fb = animation.getByName(b).frames;
			var oa = animOffsets[a];
			var ob = animOffsets[b];

			animation.getByName(a).frames = fb;
			animation.getByName(b).frames = fa;

			animOffsets[a] = ob;
			animOffsets[b] = oa;
		}
	}

	// =====================================================================
	// UPDATE LOOP
	// =====================================================================

	override function update(elapsed:Float):Void
	{
		#if flxanimate
		if (isAnimateAtlas && atlas != null)
			atlas.update(elapsed);
		#end

		tryLoadModel();

		// HEY TIMER
		if (heyTimer > 0)
		{
			var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			heyTimer -= elapsed * rate;

			if (heyTimer <= 0)
			{
				if (specialAnim)
				{
					var nm = getAnimationName();
					if (nm == "hey" || nm == "cheer")
					{
						specialAnim = false;
						dance();
					}
				}
				heyTimer = 0;
			}
		}

		// HOLD TIMER LOGIC (sing poses)
		if (!isPlayer && !specialAnim)
		{
			if (getAnimationName().startsWith("sing"))
			{
				holdTimer += elapsed;

				var limit:Float = Conductor.stepCrochet * 0.0011 * singDuration;
				#if FLX_PITCH
				if (FlxG.sound.music != null)
					limit /= FlxG.sound.music.pitch;
				#end

				if (holdTimer >= limit)
				{
					holdTimer = 0;
					dance();
				}
			}
		}

		super.update(elapsed);
	}


	// =====================================================================
	// PLAY ANIMATION (FULL MERGED VERSION)
	// =====================================================================

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (curCharacter == "nothing") return;

		_lastPlayedAnimation = AnimName;

		//---------------------------------------------------------
		// flxAnimate system
		//---------------------------------------------------------
		#if flxanimate
		if (isAnimateAtlas && atlas != null)
		{
			atlas.anim.play(AnimName, Force, Reversed, Frame);
			atlas.update(0);

			if (animOffsets.exists(AnimName))
			{
				var o = animOffsets[AnimName];
				offset.set(o[0], o[1]);
			}
			return;
		}
		#end

		//---------------------------------------------------------
		// AtlasThing system
		//---------------------------------------------------------
		if (atlasActive)
		{
			var real = animRedirect.exists(AnimName) ? animRedirect[AnimName] : AnimName;
			if (atlasContainer.animList.contains(real))
			{
				atlasContainer.play(real, Force, Reversed, Frame);

				if (animOffsets.exists(AnimName))
				{
					var o = animOffsets[AnimName];
					offset.set(o[0], o[1]);
				}

				return;
			}
		}

		//---------------------------------------------------------
		// Normal animations
		//---------------------------------------------------------
		if (animation.getByName(AnimName) != null)
		{
			animation.play(AnimName, Force, Reversed, Frame);

			if (animOffsets.exists(AnimName))
			{
				var o = animOffsets[AnimName];
				offset.set(o[0], o[1]);
			}
		}


		//---------------------------------------------------------
		// Post-play Behavior
		//---------------------------------------------------------

		// GF dance logic
		if (curCharacter == "gf" || curCharacter == "gfSinger")
		{
			if (AnimName == "singLEFT")
				danced = true;
			if (AnimName == "singUP" || AnimName == "singDOWN")
				danced = !danced;
		}

		// Dad/Mom trim
		if ((curCharacter == "dad" || curCharacter == "mom")
			&& !AnimName.contains("miss"))
		{
			var fc = getFrameCount(AnimName);
			if (fc > 4)
				finishAnimation();
		}

		// BF trim miss
		if ((curCharacter == "bf" || curCharacter == "bf-christmas")
			&& AnimName.contains("miss"))
		{
			var fc2 = getFrameCount(AnimName);
			if (fc2 > 4)
				finishAnimation();
		}

		// Monster special trim
		if (curCharacter == "monster" || curCharacter == "monster-christmas")
		{
			switch(AnimName)
			{
				case "idle":     if (getFrameCount(AnimName) > 10) finishAnimation();
				case "singUP":   if (getFrameCount(AnimName) > 8)  finishAnimation();
				case "singDOWN": if (getFrameCount(AnimName) > 7)  finishAnimation();
				case "singLEFT": if (getFrameCount(AnimName) > 5)  finishAnimation();
				case "singRIGHT":if (getFrameCount(AnimName) > 6)  finishAnimation();
			}
		}
	}


	// =====================================================================
	// DANCE LOGIC
	// =====================================================================

	public function dance(?ignoreDebug:Bool = false):Void
	{
		if (skipDance || specialAnim) return;

		if (danceIdle)
		{
			danced = !danced;
			playAnim(danced ? "danceRight" : "danceLeft");
		}
		else
			playAnim("idle");
	}


	// =====================================================================
	// IDLE END BEHAVIOR
	// =====================================================================

	public function idleEnd(?ignoreDebug:Bool = false):Void
	{
		if (curCharacter == "nothing") return;

		if (!isModel && !atlasActive)
		{
			if (curCharacter.startsWith("gf") || curCharacter == "spooky" || curCharacter == "senpai")
			{
				var fr = animation.getByName("danceRight");
				if (fr != null)
					playAnim("danceRight", true, false, fr.numFrames - 1);
			}
			else
			{
				var fr = animation.getByName("idle");
				if (fr != null)
					playAnim("idle", true, false, fr.numFrames - 1);
			}
		}
		else if (atlasActive)
		{
			var realIdle = animRedirect.exists("idle") ? animRedirect["idle"] : "idle";
			var maxFrame = atlasContainer.maxIndex[realIdle];
			playAnim("idle", true, false, maxFrame);
		}
		else if (isModel)
		{
			if (animExists(getAnimationName() + "End"))
				playAnim(getAnimationName() + "End", true, false);
			else
				playAnim("idleEnd", true, false);
		}

		canAutoIdle = true;
	}


	// =====================================================================
	// ANIMATION END CALLBACK
	// =====================================================================

	public function animationEnd(name:String):Void
	{
		if (name.endsWith("miss") || specialAnim)
			return;

		if (name.startsWith("sing"))
		{
			holdTimer = 0;
			dance();
		}
	}


	// =====================================================================
	// ANIMATION HELPERS
	// =====================================================================

	public inline function getAnimationName():String
	{
		return _lastPlayedAnimation;
	}

	public inline function isAnimationNull():Bool
	{
		#if flxanimate
		if (isAnimateAtlas)
			return (atlas == null || atlas.anim.curInstance == null);
		#end

		if (atlasActive)
			return atlasContainer.curAnim == null;

		return (animation.curAnim == null);
	}

	public function isAnimationFinished():Bool
	{
		if (isAnimationNull()) return false;

		#if flxanimate
		if (isAnimateAtlas)
			return atlas.anim.finished;
		#end

		if (atlasActive)
			return atlasContainer.curAnimFinished;

		return animation.curAnim.finished;
	}

	public function finishAnimation():Void
	{
		if (isAnimationNull()) return;

		#if flxanimate
		if (isAnimateAtlas)
		{
			atlas.anim.curFrame = atlas.anim.length - 1;
			return;
		}
		#end

		if (atlasActive)
		{
			atlasContainer.forceLastFrame();
			return;
		}

		if (animation.curAnim != null)
			animation.curAnim.finish();
	}

	public function animExists(anim:String):Bool
	{
		if (isModel)
		{
			if (model != null && model.fullyLoaded)
				return model.animationSet.hasAnimation(anim);
			return false;
		}

		if (atlasActive)
			return atlasContainer.animList.contains(animRedirect.exists(anim) ? animRedirect[anim] : anim);

		if (animation.getByName(anim) != null)
			return true;

		#if flxanimate
		if (isAnimateAtlas)
			return atlas.anim.hasAnimation(anim);
		#end

		return false;
	}


	public function getFrameCount(name:String):Int
	{
		if (atlasActive)
		{
			var real = animRedirect.exists(name) ? animRedirect[name] : name;
			return atlasContainer.maxIndex[real] + 1;
		}
		else if (!isModel && animation.getByName(name) != null)
		{
			return animation.getByName(name).numFrames;
		}
		return 1;
	}


	// =====================================================================
	// RECALCULATE DANCE IDLE
	// =====================================================================

	public function recalculateDanceIdle():Void
	{
		var last = danceIdle;
		danceIdle = (hasAnimation("danceLeft" + idleSuffix) && hasAnimation("danceRight" + idleSuffix));

		if (settingCharacterUp)
		{
			var calc:Float = danceEveryNumBeats;

			if (danceIdle) calc /= 2;
			else calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc,1));
			settingCharacterUp = false;
		}
	}


	// =====================================================================
	// MODEL LOADER
	// =====================================================================

	public function tryLoadModel():Void
	{
		if (!isModel) return;
		if (beganLoading) return;

		beganLoading = true;
		modelMutex = true;
		model = new ModelThing(this);
		modelMutexThing = model;
	}


	// =====================================================================
	// ATLAS HELPERS
	// =====================================================================

	public function createAtlas():Void
	{
		atlasActive = true;
		atlasContainer = new AtlasThing();
	}

	public function setAtlasAnim(name:String, animName:String, looping:Bool = false):Void
	{
		animRedirect[name] = animName;
		atlasContainer.setLooping(animName, looping);
		atlasContainer.onlyTheseAnims.push(animName);
	}

	public function copyAtlasValues():Void
	{
		#if flxanimate
		if (!isAnimateAtlas || atlas == null) return;

		atlas.scale.set(scale.x, scale.y);
		atlas.x = x + offset.x;
		atlas.y = y + offset.y;

		if (flipX) atlas.flipX = true;
		#end
	}


	// =====================================================================
	// DESTROY
	// =====================================================================

	override public function destroy():Void
	{
		#if flxanimate
		atlas = FlxDestroyUtil.destroy(atlas);
		#end

		if (model != null) model.destroy();
		model = null;

		if (modelView != null) modelView.destroy();
		modelView = null;

		if (animSpeed != null) animSpeed.clear();
		if (animRedirect != null) animRedirect.clear();

		super.destroy();
	}
}
