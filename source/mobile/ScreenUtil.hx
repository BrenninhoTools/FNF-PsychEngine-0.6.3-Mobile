package mobile;

import flixel.FlxG;
import openfl.Lib;
import openfl.events.Event;

class ScreenUtil
{
	public static final styles:Array<String> = ['Original', 'Full'];
	public static final baseWidth:Int = 1280;
	public static final baseHeight:Int = 720;

	static var listening:Bool = false;

	public static function apply(?style:String):Void
	{
		if (style == null)
			style = ClientPrefs.screenStyle;

		var stage = Lib.current.stage;
		if (stage == null || FlxG.game == null)
			return;

		var width:Int = baseWidth;
		if (style == 'Full' && stage.stageHeight > 0)
			width = Std.int(Math.max(baseWidth, Math.ceil(baseHeight * stage.stageWidth / stage.stageHeight)));

		if (width != FlxG.width)
		{
			@:privateAccess
			{
				FlxG.width = width;
				FlxG.initialWidth = width;
			}
			FlxG.worldBounds.set(-10, -10, FlxG.width + 20, FlxG.height + 20);

			for (camera in FlxG.cameras.list)
			{
				if (camera != null && camera.x == 0 && camera.y == 0)
					camera.width = FlxG.width;
			}
		}

		FlxG.resizeGame(stage.stageWidth, stage.stageHeight);

		if (!listening)
		{
			listening = true;
			stage.addEventListener(Event.RESIZE, function(_) apply());
		}
	}

	public static function fitBackgrounds(group:flixel.group.FlxGroup):Void
	{
		if (group == null || FlxG.width <= baseWidth)
			return;

		for (member in group.members)
		{
			var sprite:flixel.FlxSprite = Std.downcast(member, flixel.FlxSprite);
			if (sprite == null || sprite.graphic == null || sprite.graphic.key == null)
				continue;

			var key:String = sprite.graphic.key;
			if (key.indexOf('menuDesat') == -1 && key.indexOf('menuBG') == -1)
				continue;

			if (sprite.width < FlxG.width + 2)
			{
				var ratio:Float = (FlxG.width + 2) / sprite.width;
				sprite.scale.x *= ratio;
				sprite.scale.y *= ratio;
				sprite.updateHitbox();
			}
			sprite.screenCenter(X);
		}
	}
}
