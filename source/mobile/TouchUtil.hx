package mobile;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.input.FlxSwipe;

enum SwipeDirection
{
	UP;
	DOWN;
	LEFT;
	RIGHT;
}

class TouchUtil
{
	public static var tapDistance:Float = 30;
	public static var swipeDistance:Float = 80;
	public static var tapDuration:Float = 0.5;

	static var consumedTick:Int = -1;

	public static function consume():Void
	{
		consumedTick = FlxG.game.ticks;
	}

	public static inline function isConsumed():Bool
	{
		return consumedTick == FlxG.game.ticks;
	}

	public static function justTapped():Bool
	{
		if (isConsumed())
			return false;

		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
		{
			if (touch.justReleased && isTap(touch.justPressedPosition.x, touch.justPressedPosition.y, touch.viewX, touch.viewY, touch.justPressedTimeInTicks)
				&& !MobileButton.isOverAny(touch))
				return true;
		}
		#end
		return false;
	}

	public static function justTappedOn(object:FlxBasic, ?camera:FlxCamera):Bool
	{
		if (object == null || isConsumed())
			return false;

		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
		{
			if (touch.justReleased && isTap(touch.justPressedPosition.x, touch.justPressedPosition.y, touch.viewX, touch.viewY, touch.justPressedTimeInTicks)
				&& touch.overlaps(object, camera))
				return true;
		}
		#end
		#if (FLX_MOUSE && !mobile)
		if (FlxG.mouse.justReleased && FlxG.mouse.overlaps(object, camera))
			return true;
		#end
		return false;
	}

	public static function checkListTap<T:FlxBasic>(items:Array<T>, selected:Int, ?camera:FlxCamera):Int
	{
		if (!justTapped())
			return -1;

		if (camera == null)
			camera = FlxG.camera;

		for (i in 0...items.length)
		{
			var item:T = items[i];
			if (item != null && item.exists && item.visible && justTappedOn(item, camera))
			{
				if (i == selected)
					return -1;
				consume();
				return i;
			}
		}
		consume();
		return -1;
	}

	public static function pressedOn(object:FlxBasic, ?camera:FlxCamera, ignoreButtons:Bool = false):Bool
	{
		if (object == null)
			return false;

		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
		{
			if (touch.pressed && touch.overlaps(object, camera) && (!ignoreButtons || !MobileButton.isOverAny(touch)))
				return true;
		}
		#end
		return false;
	}

	public static function swiped(direction:SwipeDirection):Bool
	{
		if (isConsumed())
			return false;

		for (swipe in FlxG.swipes)
		{
			if (getDirection(swipe) == direction)
				return true;
		}
		return false;
	}

	public static function anySwipe():Bool
	{
		if (isConsumed())
			return false;

		for (swipe in FlxG.swipes)
		{
			if (getDirection(swipe) != null)
				return true;
		}
		return false;
	}

	static function getDirection(swipe:FlxSwipe):Null<SwipeDirection>
	{
		if (swipe.distance < swipeDistance)
			return null;

		var dx:Float = swipe.endPosition.x - swipe.startPosition.x;
		var dy:Float = swipe.endPosition.y - swipe.startPosition.y;
		if (Math.abs(dx) > Math.abs(dy))
			return dx > 0 ? RIGHT : LEFT;
		return dy > 0 ? DOWN : UP;
	}

	static function isTap(startX:Float, startY:Float, endX:Float, endY:Float, startTicks:Int):Bool
	{
		var dx:Float = endX - startX;
		var dy:Float = endY - startY;
		var duration:Float = (FlxG.game.ticks - startTicks) / 1000;
		return Math.sqrt(dx * dx + dy * dy) <= tapDistance && duration <= tapDuration;
	}
}
