package funkin.objects;

import flixel.FlxSprite;

import funkin.game.IUiSprite;

@:nullSafety
class HealthIcon extends FlxSprite implements IUiSprite
{
	public var sprTracker:Null<FlxSprite> = null;
	public var isPlayer:Bool = false;
	public var hasWinning:Bool = true;
	public var char:String = '';
	
	@:allow(funkin.states.editors.ChartEditorState)
	var updateOffset:Bool = true;
	
	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}
	
	public var alphaMultipler(default, set):Float = 1;
	
	function set_alphaMultipler(v:Float):Float
	{
		alphaMultipler = FlxMath.bound(v, 0, 1);
		set_alpha(alpha);
		return alphaMultipler;
	}
	
	override function set_alpha(v:Float)
	{
		v = FlxMath.bound(v, 0, 1);
		v *= alphaMultipler;
		return super.set_alpha(v);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (sprTracker != null)
		{
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
		}
	}
	
	private var iconOffsets:Array<Float> = [0, 0];
	
	public function changeIcon(char:String, ?forced:Bool = false)
	{
		if (this.char != char)
		{
			var curAnimation:Int = 0;
			if (this.animation.curAnim != null) curAnimation = this.animation.curAnim.curFrame; // quick patch so icons doesn't return to their default animation after changing it
			var hasWin:Bool = false;
			var singleIcon:Bool = false;
			
			var name:String = 'icons/' + char;
			if (!Paths.fileExists('images/' + name + '.png')) name = '${Paths.UI_PREFIX}icons/icon-' + char; // Older versions of psych engine's support
			if (!Paths.fileExists('images/' + name + '.png')) name = '${Paths.UI_PREFIX}icons/icon-face'; // Prevents crash from missing icon
			if (!Paths.fileExists('images/' + name + '.png')) name = 'UI/icons/icon-face';
			
			var graphic = Paths.image(name);
			if (graphic.width == 450) hasWin = true;
			else if (graphic.width == 150) singleIcon = true;
			var iSize:Float = Math.round(graphic.width / graphic.height);
			var realSize:Float = (hasWin ? 3 : (singleIcon ? 1 : iSize));
			loadGraphic(graphic, true, Math.floor(graphic.width / realSize), Math.floor(graphic.height));
			iconOffsets[0] = (width - 150) / realSize;
			iconOffsets[1] = (height - 150) / iSize;
			updateHitbox();
			
			var animArray:Array<Int> = [];
			for (i in 0...3)
				animArray.push((i <= frames.frames.length - 1 ? i : 0)); // 0: Default | 1: Losing | 2: Winning
			animation.add(char, animArray, 0, false, isPlayer);
			animation.play(char);
			this.animation.curAnim.curFrame = curAnimation;
			this.char = char;
			this.hasWinning = hasWin;
			
			if (char.endsWith('-pixel')) antialiasing = false;
			else antialiasing = ClientPrefs.globalAntialiasing;
		}
	}
	
	public var autoAdjustOffset:Bool = true;
	
	override function updateHitbox()
	{
		super.updateHitbox();
		if (autoAdjustOffset)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
	}
	
	public function getCharacter():String
	{
		return char;
	}
}
