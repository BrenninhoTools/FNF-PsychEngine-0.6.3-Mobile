package mobile;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Matrix;

class Hitbox extends FlxTypedSpriteGroup<HitboxHint>
{
	public static var colors:Array<FlxColor> = [0xFFC24B99, 0xFF00FFFF, 0xFF12FA05, 0xFFF9393F];

	public var pressed(default, null):Array<Bool> = [false, false, false, false];
	public var justPressed(default, null):Array<Bool> = [false, false, false, false];
	public var justReleased(default, null):Array<Bool> = [false, false, false, false];

	public var hintCamera:FlxCamera;

	public function new(?camera:FlxCamera)
	{
		super();

		hintCamera = camera;
		var hintWidth:Int = Std.int(FlxG.width / 4);
		for (i in 0...4)
		{
			var hint:HitboxHint = new HitboxHint(hintWidth * i, 0, hintWidth, FlxG.height, colors[i]);
			add(hint);
		}

		scrollFactor.set();
		if (camera != null)
			cameras = [camera];
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		for (i in 0...members.length)
		{
			var hint:HitboxHint = members[i];
			var isPressed:Bool = visible && alive && TouchUtil.pressedOn(hint, hintCamera, true);
			justPressed[i] = isPressed && !pressed[i];
			justReleased[i] = !isPressed && pressed[i];
			pressed[i] = isPressed;
			hint.setPressed(isPressed);
		}
	}

	public function clearInput():Void
	{
		for (i in 0...members.length)
		{
			justPressed[i] = false;
			justReleased[i] = pressed[i];
			pressed[i] = false;
			members[i].setPressed(false);
		}
	}
}

class HitboxHint extends FlxSprite
{
	public static var idleAlpha:Float = 0.15;
	public static var pressedAlpha:Float = 0.6;

	public function new(x:Float, y:Float, width:Int, height:Int, color:FlxColor)
	{
		super(x, y);

		loadGraphic(createGraphic(width, height, color));
		alpha = idleAlpha;
		scrollFactor.set();
		moves = false;
		active = true;
	}

	public function setPressed(value:Bool):Void
	{
		alpha = value ? pressedAlpha : idleAlpha;
	}

	static function createGraphic(width:Int, height:Int, color:FlxColor):FlxGraphic
	{
		var key:String = 'hitbox_hint_${width}_${height}_${color.toHexString()}';
		var cached:FlxGraphic = FlxG.bitmap.get(key);
		if (cached != null)
			return cached;

		var shape:Shape = new Shape();
		var matrix:Matrix = new Matrix();
		matrix.createGradientBox(width, height, 0, 0, 0);
		shape.graphics.beginGradientFill(LINEAR, [color.rgb, color.rgb, color.rgb], [0.6, 0, 0.6], [0, 127, 255], matrix);
		shape.graphics.drawRect(0, 0, width, height);
		shape.graphics.endFill();
		shape.graphics.lineStyle(4, color.rgb, 1);
		shape.graphics.drawRect(2, 2, width - 4, height - 4);

		var bitmap:BitmapData = new BitmapData(width, height, true, 0);
		bitmap.draw(shape, null, null, null, null, true);

		var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		graphic.persist = true;
		graphic.destroyOnNoUse = false;
		return graphic;
	}
}
