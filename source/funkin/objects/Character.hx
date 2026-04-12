package funkin.objects;

import funkin.data.CharacterData.CharacterParser;
import funkin.data.CharacterData.AnimationInfo;
import funkin.data.CharacterData.CharacterInfo;

import animate.FlxAnimate;

// taking some things from base game
// add back miss anim stuff

/**
 * Bopper with extended features to be animated to the strums
 */
// NOT DONE NOT DONE NOT DONE
class Character extends Bopper
{
	public static final DEFAULT_CHARACTER:String = 'bf';
	
	/**
	 * how much the camera moves with the characters sings animations
	 */
	public var camDisplacement:Float = 20;
	
	/**
	 * is the player character
	 * 
	 * changes some things like flipping them
	 */
	public var isPlayer:Bool = false;
	
	/**
	 * Character's json name
	 */
	public var curCharacter:String = DEFAULT_CHARACTER;
	
	public var pastCharacter:String = DEFAULT_CHARACTER;
	
	public var charName:String = DEFAULT_CHARACTER;
	public var isSpeakerChar:Bool = false;
	public var flipMode:Bool = false;
	
	public var daZoom(default, set):Float = 1;
	
	function set_daZoom(value:Float):Float
	{
		daZoom = value;
		var daValue:Float = value * jsonScale;
		this.scale.set(daValue, daValue);
		
		// trace("fucked with");
		
		return value;
	}
	
	public var holdTimer:Float = 0;
	
	public var animTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var stunned:Bool = false;
	
	/**
	 * Multiplier of how long a character holds the sing pose
	 */
	public var singDuration:Float = 4;
	
	public var animSuffix:String = '';
	public var animSuffixExclusions = ['idle', 'danceLeft', 'danceRight', 'miss'];
	
	/**
	 * if true, character uses `danceLeft` and `danceRight` instead of `idle`
	 */
	public var danceIdle:Bool = false;
	
	public var stopIdle:Bool = false;
	
	public var skipDance:Bool = false;
	
	/**
	 * if an idle animation goes over a certain amount of frames, it wont play every couple of beats. set this to `true` to force the idle to play even if the animation isnt' complete
	**/
	public var forceDance:Bool = false;
	
	/**
	 * The characters health icon
	 */
	public var healthIcon:String = 'face';
	
	public var animations:Array<AnimationInfo> = [];
	
	// gameover suttffs
	public var gameoverCharacter:Null<String> = null;
	
	public var gameoverInitialDeathSound:Null<String> = null;
	
	public var gameoverLoopDeathSound:Null<String> = null;
	
	public var gameoverConfirmDeathSound:Null<String> = null;
	
	public var animationsArray:Array<AnimationInfo> = [];
	
	public var isPsychPlayer:Null<Bool>;
	
	/**
	 * Character offsets defined by the json
	 */
	public var positionArray:Array<Float> = [0, 0];
	
	public var playerPositionArray:Array<Float> = [0, 0];
	
	/**
	 * Camera offsets defined by the json
	 */
	public var cameraPosition:Array<Float> = [0, 0];
	
	public var playerCameraPosition:Array<Float> = [0, 0];
	
	/**
	 * how much the ghost anims move when played
	 */
	public var ghostDisplacement:Float = 40;
	
	/**
	 *	if enabled, ghosts will show on double notes for the character
	 */
	public var ghostsEnabled:Bool = false;
	
	/**
	 * Array of all ghosts
	 */
	public var doubleGhosts:Array<FunkinSprite> = [];
	
	/**
	 * Array of all ghosts tweens
	 */
	public var ghostTweenGrp:Array<FlxTween> = [];
	
	/**
	 * Alpha that the ghosts doubles appear at
	 */
	public var ghostAlpha:Float = 0.6;
	
	/**
	 * Last hit row index
	 */
	public var mostRecentRow:Int = 0; // for ghost anims n shit
	
	// Used on Character Editor
	public var isPlayerInEditor:Null<Bool> = null;
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	
	/**
	 * disables some functionality for use out of play
	 * 
	 * used in the Character editor
	 */
	public var debugMode:Bool = false;
	
	/**
	 * The Characters health bar colours stored as `[r,g,b]`
	 */
	public var healthColorArray:Array<Int> = [255, 0, 0];
	
	public var iconColor:String;
	
	public var curColor:FlxColor = 0xFFFFFFFF; // i was thinking about using this but nvm
	
	public var hasMissAnimations:Bool = false;
	
	public var healthColour:Int = FlxColor.RED;
	
	/**
	 *	If enabled, the character's singing animation will stop at the last frame while holding a sustain note
	 */
	public var vSliceSustains = false;
	
	public var doMissThing:Bool = false;
	
	public function new(x:Float = 0, y:Float = 0, character:String = 'bf', isPlayer:Bool = false)
	{
		super(x, y);
		
		// animOffsets = new Map<String, Array<Dynamic>>();
		// animPlayerOffsets = new Map<String, Array<Dynamic>>();
		this.curCharacter = character;
		this.isPlayer = isPlayer;
		
		genGhosts();
		
		loadFile(CharacterParser.fetchInfo(curCharacter));
	}
	
	public function resetCharacter(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false) // beta
	{
		this.x = x;
		this.y = y;
		
		resetVariables();
		
		this.isPlayer = isPlayer;
		
		changeCharacter(character);
	}
	
	public function changeCharacter(character:String)
	{
		// Reset existing animation and offset maps to prevent data carryover [cite: 127]
		animationsArray = [];
		// animOffsets = [];
		// animPlayerOffsets = [];
		curCharacter = character;
		pastCharacter = character;
		isPsychPlayer = false;
		
		curColor = 0xFFFFFFFF;
		
		// Attempt to parse the JSON content and load the character data [cite: 131]
		try
		{
			loadFile(CharacterParser.fetchInfo(curCharacter));
		}
		catch (e:Dynamic)
		{
			trace('Error loading character file of "$character": $e');
		}
		
		// Reset character state flags [cite: 132]
		for (i in ['flipMode', 'stopIdle', 'skipDance', 'specialAnim', 'stunned'])
		{
			Reflect.setProperty(this, i, false);
		}
		
		// Determine if the character has unique "miss" animations [cite: 133]
		hasMissAnimations = hasAnim('singLEFTmiss') || hasAnim('singDOWNmiss') || hasAnim('singUPmiss') || hasAnim('singRIGHTmiss');
		
		// Refresh the dancing logic and trigger the first dance frame [cite: 133]
		// recalculateDanceIdle();
		dance();
	}
	
	public function resetVariables()
	{
		// missingCharacter = false;
		// if (missingText != null) missingText.kill();
		
		for (i in ['flipMode', 'stopIdle', 'skipDance', 'specialAnim', 'stunned'])
			Reflect.setProperty(this, i, false);
			
		idleSuffix = '';
		
		setZoom(1);
		
		this.cameras = [FlxG.camera];
		this.alpha = 1;
		this.visible = true;
		this.active = true;
		this.exists = true;
		this.alive = true;
		
		this.angle = 0;
		this.scale.set(1, 1);
		this.offset.set(0, 0);
		this.origin.set(0, 0);
		
		this.velocity.set(0, 0);
		this.acceleration.set(0, 0);
		this.drag.set(0, 0);
		this.maxVelocity.set(10000, 10000);
		
		this.angularVelocity = 0;
		this.angularAcceleration = 0;
		this.angularDrag = 0;
		
		this.color = 0xFFFFFF;
		this.blend = null;
		this.shader = null;
		this.antialiasing = true;
		
		this.flipX = false;
		this.flipY = false;
		
		this.scrollFactor.set(1, 1);
		
		if (this.animation != null)
		{
			this.animation.stop();
			this.animation.curAnim = null;
		}
		
		this.clipRect = null;
		
		this.updateHitbox();
		
		this.moves = true;
		this.immovable = false;
	}
	
	public function setZoom(Zoom:Float)
	{
		set_daZoom(Zoom);
	}
	
	function genGhosts()
	{
		for (i in 0...4)
		{
			final ghost = new FunkinSprite();
			ghost.visible = false;
			ghost.useRenderTexture = true;
			ghost.antialiasing = true;
			ghost.alpha = ghostAlpha;
			doubleGhosts.push(ghost);
		}
	}
	
	// clean this up
	public function loadFile(json:CharacterInfo)
	{
		/*
			animOffsets.clear();
			scale.set(1, 1);
			updateHitbox();
		 */
		
		if (json.isPlayerChar || json.is_player_char)
		{
			isPsychPlayer = json.isPlayerChar || json.is_player_char;
		}
		
		this.jsonScale = json.scale;
		
		var playerPosition:Array<Float> = CharacterFileUtil.getPlayerPosition(json);
		
		this.positionArray = ((!debugMode && isPlayer && playerPosition != null) ? playerPosition : json.position);
		this.playerPositionArray = (playerPosition != null ? playerPosition : json.position);
		
		this.cameraPosition = (isPlayer && json.player_camera_position != null ? json.player_camera_position : json.camera_position);
		this.playerCameraPosition = (json.player_camera_position != null ? json.player_camera_position : json.camera_position);
		
		this.healthIcon = json.healthicon;
		this.vSliceSustains = json.vslice_sustains;
		this.singDuration = json.sing_duration;
		this.noAntialiasing = json.no_antialiasing;
		
		// this.flipX = (json.flip_x != isPlayer);
		this.flipX = !!json.flip_x;
		this.originalFlipX = (json.flip_x == true);
		this.imageFile = json.image;
		
		this.antialiasing = !noAntialiasing && ClientPrefs.globalAntialiasing;
		
		this.danceEveryNumBeats = json.dance_every ?? 2;
		
		this.gameoverCharacter = json.gameover_character;
		this.gameoverConfirmDeathSound = json.gameover_confirm_sound;
		this.gameoverLoopDeathSound = json.gameover_loop_sound;
		this.gameoverInitialDeathSound = json.gameover_intial_sound;
		
		this.scalableOffsets = json.scalableOffsets ?? false;
		
		this.isPlayerInEditor = json._editor_isPlayer;
		
		var itHasPlayerOfs:Bool = false;
		
		loadAtlas(imageFile);
		
		if (jsonScale != 1)
		{
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}
		
		if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
		{
			// temp keep
			this.healthColorArray = json.healthbar_colors;
			
			this.healthColour = FlxColor.fromRGB(json.healthbar_colors[0], json.healthbar_colors[1], json.healthbar_colors[2]);
		}
		else
		{
			this.healthColour = json.healthbar_colour;
		}
		
		this.animations = json.animations;
		if (animations != null && animations.length > 0)
		{
			for (a in animations)
			{
				final animAnim:String = '' + a.anim;
				final animName:String = '' + a.name;
				final animFps:Int = a.fps;
				final animLoop:Bool = !!a.loop; // Bruh
				final animIndices:Array<Int> = a.indices ?? [];
				
				final flipX = a.flipX ?? false;
				final flipY = a.flipY ?? false;
				
				if (animIndices.length > 0)
				{
					addAnimByIndices(animAnim, animName, animIndices, animFps, animLoop, flipX, flipY);
				}
				else
				{
					addAnimByPrefix(animAnim, animName, animFps, animLoop, flipX, flipY);
				}
				
				var offsets:Array<Int> = a.offsets;
				var playerOffsets:Array<Int> = (a.playerOffsets != null && a.playerOffsets.length > 1) ? a.playerOffsets : a.offsets;
				var swagOffsets:Array<Int> = offsets;
				
				if (isPlayer && playerOffsets != null && playerOffsets.length > 1)
				{
					swagOffsets = playerOffsets;
				}
				
				if (swagOffsets != null && swagOffsets.length > 1) addOffset(a.anim, swagOffsets[0], swagOffsets[1]);
				else addOffset(a.anim, 0, 0);
				
				if (playerOffsets != null && playerOffsets.length > 1) addPlayerOffset(a.anim, playerOffsets[0], playerOffsets[1]);
				else addPlayerOffset(a.anim, 0, 0);
			}
		}
		else
		{
			addAnimByPrefix('idle', 'BF idle dance', 24, false);
		}
		
		dance(forceDance);
		
		if (isPlayer)
		{
			flipX = !flipX;
			
			// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf') && !isPsychPlayer) flipAnims();
		}
		
		if (!isPlayer)
		{
			// Flip for just bf
			if (curCharacter.startsWith('bf') || isPsychPlayer) flipAnims();
		}
		
		// if (isPlayer && !curCharacter.startsWith('bf') && !itHasPlayerOfs) flipAnims(); // fuck it.
	}
	
	@:allow(states.editors.CharacterEditorState)
	public var isAnimateAtlas(default, null):Bool = false;
	
	override function update(elapsed:Float)
	{
		if (debugMode || isAnimNull())
		{
			super.update(elapsed);
			return;
		}
		
		if (animTimer > 0 && !getAnimName().endsWith('-end'))
		{
			animTimer -= elapsed;
			if (animTimer <= 0)
			{
				animTimer = 0;
				dance(forceDance);
			}
		}
		
		if (specialAnim && isAnimFinished())
		{
			specialAnim = false;
			dance(forceDance);
		}
		else if (getAnimName().endsWith('miss') && isAnimFinished())
		{
			dance(forceDance);
			finishAnim();
		}
		else if (getAnimName().endsWith('-end') && isAnimFinished())
		{
			dance(forceDance);
		}
		
		if (getAnimName().startsWith('sing'))
		{
			holdTimer += elapsed;
		}
		else if (isPlayer) holdTimer = 0;
		
		if (holdTimer >= Conductor.stepCrotchet * 0.0011 * singDuration)
		{
			if (hasAnim(getAnimName() + '-end'))
			{
				playAnim(getAnimName() + '-end', true);
			}
			else
			{
				dance(forceDance);
			}
			
			holdTimer = 0;
		}
		
		if (isAnimFinished() && hasAnim(getAnimName() + '-loop')) playAnim(getAnimName() + '-loop');
		
		if (ghostsEnabled)
		{
			for (ghost in doubleGhosts)
				ghost.update(elapsed);
		}
		
		super.update(elapsed);
	}
	
	inline function predictCharacterIsPlayer(name:String)
	{ // if i remove this later, is because people didn't liked it. -Ryiuu
		if (name.startsWith('bf') || name.startsWith('bf-') || name.endsWith('-player') || name.endsWith('-playable')) return true;
		else return false;
	}
	
	override function draw()
	{
		if (ghostsEnabled)
		{
			for (ghost in doubleGhosts)
			{
				if (ghost.visible) ghost.draw();
			}
		}
		super.draw();
	}
	
	/**
	 * Plays the characters idle animation
	 */
	override function dance(forced:Bool = false)
	{
		if (debugMode || specialAnim) return;
		super.dance(forced);
	}
	
	var missed:Bool = false;
	
	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		var useFallbackMiss:Bool = false;
		
		// Reimplemented the fall back for the alt sprites
		if (AnimName.endsWith('alt') && !hasAnim(AnimName))
		{
			AnimName = AnimName.split('-')[0];
		}
		
		if (AnimName.endsWith('miss') && !hasAnim(AnimName))
		{
			AnimName = AnimName.substr(0, AnimName.length - 4);
			useFallbackMiss = true;
		}
		
		// trace(anim.exists(AnimName));
		
		animation.play(AnimName, Force, Reversed, Frame);
		_lastPlayedAnimation = AnimName;
		
		if (hasAnim(AnimName))
		{
			var daOffset = animOffsets.get(AnimName);
			if (isPlayer) daOffset = animPlayerOffsets.get(AnimName);
			
			if ((animOffsets.exists(AnimName) && !isPlayer) || (animPlayerOffsets.exists(AnimName) && isPlayer)) offset.set(daOffset[0] * daZoom, daOffset[1] * daZoom);
			else offset.set(0, 0);
			
			if (curCharacter.startsWith('gf-') || curCharacter == 'gf')
			{
				if (AnimName == 'singLEFT') danced = true;
				else if (AnimName == 'singRIGHT') danced = false;
				
				if (AnimName == 'singUP' || AnimName == 'singDOWN') danced = !danced;
			}
			
			if (useFallbackMiss)
			{
				var realCurColor:FlxColor = curColor;
				color = CoolUtil.blendColors(curColor, 0xFFCFAFFF);
				curColor = realCurColor;
			}
			else if (color != curColor && !hasMissAnimations)
			{
				color = curColor;
			}
			
			// super.playAnim(AnimName, Force, Reversed, Frame);
		}
	}
	
	public function quickAnimAdd(name:String, anim:String)
	{
		addAnimByPrefix(name, anim, 24, false);
	}
	
	override function onBeatHit(beat:Int)
	{
		if (stunned || getAnimName().startsWith('sing')) return;
		super.onBeatHit(beat);
	}
	
	public function getSingDisplacement():FlxPoint
	{
		return switch (getAnimName().substr(4).split('-')[0].toLowerCase())
		{
			case 'up':
				FlxPoint.weak(0, -camDisplacement);
			case 'down':
				FlxPoint.weak(0, camDisplacement);
			case 'left':
				FlxPoint.weak(-camDisplacement, 0);
			case 'right':
				FlxPoint.weak(camDisplacement, 0);
			default:
				FlxPoint.weak();
		}
	}
	
	public function playGhostAnim(ghostID = 0, animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		var ghost:FunkinSprite = doubleGhosts[ghostID];
		ghost.scale.copyFrom(scale);
		ghost.frames = frames;
		ghost.animation.copyFrom(animation);
		ghost.antialiasing = antialiasing;
		ghost.x = x;
		ghost.y = y;
		ghost.flipX = flipX;
		ghost.flipY = flipY;
		ghost.alpha = alpha * ghostAlpha;
		ghost.visible = true;
		ghost.color = healthColour;
		ghost.animation.play(animName, force, reversed, frame);
		
		ghostTweenGrp[ghostID]?.cancel();
		
		final direction:String = animName.substring(4).split('-')[0];
		
		inline function resolveDir(xDir:Bool = false):Float
		{
			var output:Float = 0;
			switch (direction)
			{
				case 'UP':
					if (!xDir) output = -ghostDisplacement;
				case 'DOWN':
					if (!xDir) output = ghostDisplacement;
				case 'RIGHT':
					if (xDir) output = ghostDisplacement;
				case 'LEFT':
					if (xDir) output = -ghostDisplacement;
			}
			
			return output;
		}
		
		final moveX = x + resolveDir(true);
		final moveY = y + resolveDir(false);
		
		ghostTweenGrp[ghostID] = FlxTween.tween(ghost, {alpha: 0, x: moveX, y: moveY}, 0.75,
			{
				onComplete: (twn) -> {
					ghost.visible = false;
					ghostTweenGrp[ghostID] = null;
				}
			});
			
		if (animOffsets.exists(animName))
		{
			final daOffset = animOffsets.get(animName);
			ghost.animOffset.set(daOffset[0] * scale.x, daOffset[1] * scale.y);
		}
	}
	
	public function flipAnims()
	{
		if (isAnimateAtlas)
		{
			for (anim in animations)
			{
				if (anim.anim.contains("singRIGHT"))
				{
					var suffix = anim.anim.split('singRIGHT')[1];
					var singRightName = 'singRIGHT' + suffix;
					var singLeftName = 'singLEFT' + suffix;
					
					@:privateAccess {
						// FlxAnimate uses a different internal map structure
						var oldRightAnim = this.anim._animations.get(singRightName);
						var oldLeftAnim = this.anim._animations.get(singLeftName);
						
						if (oldRightAnim != null && oldLeftAnim != null)
						{
							this.anim._animations.set(singRightName, oldLeftAnim);
							this.anim._animations.set(singLeftName, oldRightAnim);
						}
					}
				}
			}
		}
		else
		{
			for (anim in animations)
			{
				if (anim.anim.contains("singRIGHT"))
				{
					var suffix = anim.anim.split('singRIGHT')[1];
					var rightAnim = 'singRIGHT' + suffix;
					var leftAnim = 'singLEFT' + suffix;
					
					if (animation.getByName(rightAnim) != null && animation.getByName(leftAnim) != null)
					{
						var oldRightFrames = animation.getByName(rightAnim).frames;
						animation.getByName(rightAnim).frames = animation.getByName(leftAnim).frames;
						animation.getByName(leftAnim).frames = oldRightFrames;
					}
				}
			}
		}
	}
	
	var _lastPlayedAnimation:String;
	
	inline public function getAnimationName():String
	{
		return _lastPlayedAnimation;
	}
	
	override function destroy()
	{
		if (ghostTweenGrp != null && ghostTweenGrp.length > 0)
		{
			for (i in ghostTweenGrp)
				i?.cancel();
		}
		
		ghostTweenGrp = FlxDestroyUtil.destroyArray(ghostTweenGrp);
		
		doubleGhosts = FlxDestroyUtil.destroyArray(doubleGhosts);
		
		super.destroy();
	}
}

class CharacterFileUtil
{
	public static function getPlayerPosition(charData:CharacterInfo):Array<Float>
	{
		return charData.player_position != null ? charData.player_position : charData.player_position;
	}
}
