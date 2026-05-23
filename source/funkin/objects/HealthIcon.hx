package funkin.objects;

import funkin.game.IUiSprite;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var isPlayer:Bool = false;
	public var hasWinning:Bool = true;
	public var char:String = '';
	
	public function new(char:String = 'face', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
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
	
	public function changeIcon(char:String)
	{
		if (this.char != char)
		{
			var curAnimation:Int = 0;
			if (this.animation.curAnim != null) curAnimation = this.animation.curAnim.curFrame; // quick patch so icons doesn't return to their default animation after changing it
			var hasWin:Bool = false;
			var singleIcon:Bool = false;
			
			var name:String = '${Paths.UI_PREFIX}icons/$char';
			if (!Paths.fileExists('images/' + name + '.png')) name = '${Paths.UI_PREFIX}icons/icon-' + char; // Older versions of psych engine's support
			if (!Paths.fileExists('images/' + name + '.png')) name = '${Paths.UI_PREFIX}icons/icon-face'; // Prevents crash from missing icon
			if (!Paths.fileExists('images/' + name + '.png')) name = 'UI/icons/icon-face'; // ultimate fallback incase icon-face doesnt exist in ur custom UI folder
			
			var graphic = Paths.image(name, null, false);
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
	
	@:allow(funkin.states.editors.ChartEditorState)
	public var updateOffset:Bool = true;
	
	override function updateHitbox()
	{
		super.updateHitbox();
		if (updateOffset)
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
