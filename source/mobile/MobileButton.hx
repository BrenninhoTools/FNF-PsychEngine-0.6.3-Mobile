package mobile;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end

class MobileButton extends FlxSprite
{
	static var activeButtons:Array<MobileButton> = [];

	public var isBackButton:Bool = false;

	var pressAnim:Bool = false;

	public function new(x:Float = 0, y:Float = 0, image:String, ?prefix:String, scale:Float = 1)
	{
		super(x, y);

		if (prefix != null)
		{
			frames = Paths.getSparrowAtlas('mobile/' + image, 'shared');
			animation.addByPrefix('idle', prefix + '0000', 0, false);
			animation.addByPrefix('press', prefix, 24, false);
			animation.play('idle');
			animation.onFinish.add(function(name:String)
			{
				if (name == 'press')
					animation.play('idle');
			});
			pressAnim = true;
		}
		else
			loadGraphic(Paths.image('mobile/' + image, 'shared'));

		this.scale.set(scale, scale);
		updateHitbox();
		scrollFactor.set();
		antialiasing = ClientPrefs.globalAntialiasing;
		activeButtons.push(this);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (justPressed())
		{
			Haptics.menu();
			if (pressAnim)
				animation.play('press', true);
		}
	}

	public function justPressed():Bool
	{
		return exists && visible && alive && TouchUtil.justTappedOn(this, getButtonCamera());
	}

	public function getButtonCamera():FlxCamera
	{
		return (cameras != null && cameras.length > 0) ? cameras[0] : FlxG.camera;
	}

	override function destroy()
	{
		activeButtons.remove(this);
		super.destroy();
	}

	public static function backJustPressed():Bool
	{
		for (button in activeButtons)
		{
			if (button != null && button.isBackButton && button.justPressed())
				return true;
		}
		return false;
	}

	#if FLX_TOUCH
	public static function isOverAny(touch:FlxTouch):Bool
	{
		for (button in activeButtons)
		{
			if (button != null && button.exists && button.visible && button.alive && touch.overlaps(button, button.getButtonCamera()))
				return true;
		}
		return false;
	}
	#end
}
