package mobile;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.input.FlxSwipe;
#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end

enum SwipeDirection
{
	UP;
	DOWN;
	LEFT;
	RIGHT;
}

class TouchUtil
{
	public static var tapDistance:Float = 40;
	public static var swipeDistance:Float = 70;
	public static var swipeRatio:Float = 1.5;
	public static var scrollStep:Float = 90;

	static var consumedTick:Int = -1;
	static var refreshedTick:Int = -1;
	static var draggedTouches:Map<Int, Bool> = new Map();
	static var scrollTouchID:Int = -1;
	static var scrollAnchorY:Float = 0;

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
		refresh();
		if (isConsumed())
			return false;

		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
		{
			if (isTouchTap(touch) && !MobileButton.isOverAny(touch))
				return true;
		}
		#end
		return false;
	}

	public static function justTappedOn(object:FlxBasic, ?camera:FlxCamera):Bool
	{
		refresh();
		if (object == null || isConsumed())
			return false;

		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
		{
			if (isTouchTap(touch) && touch.overlaps(object, camera))
				return true;
		}
		#end
		#if (FLX_MOUSE && !mobile)
		if (FlxG.mouse.justReleased && FlxG.mouse.overlaps(object, camera))
			return true;
		#end
		return false;
	}

	public static function tappedIndex<T:FlxBasic>(items:Array<T>, ?camera:FlxCamera, consumeTap:Bool = true):Int
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
				if (consumeTap)
					consume();
				return i;
			}
		}
		return -1;
	}

	public static function checkListTap<T:FlxBasic>(items:Array<T>, selected:Int, ?camera:FlxCamera):Int
	{
		if (!justTapped())
			return -1;

		var index:Int = tappedIndex(items, camera, false);
		if (index == selected)
			return -1;
		consume();
		return index;
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

	public static function scroll(?step:Float):Int
	{
		refresh();
		if (step == null)
			step = scrollStep;

		#if FLX_TOUCH
		var touch:FlxTouch = null;
		for (t in FlxG.touches.list)
		{
			if (t.touchPointID == scrollTouchID && t.pressed)
			{
				touch = t;
				break;
			}
		}

		if (touch == null)
		{
			scrollTouchID = -1;
			for (t in FlxG.touches.list)
			{
				if (t.pressed && !MobileButton.isOverAny(t))
				{
					touch = t;
					scrollTouchID = t.touchPointID;
					scrollAnchorY = t.justPressedPosition.y;
					break;
				}
			}
		}

		if (touch == null)
			return 0;

		var delta:Float = touch.viewY - scrollAnchorY;
		var steps:Int = Std.int(delta / step);
		if (steps != 0)
		{
			scrollAnchorY += steps * step;
			draggedTouches.set(touch.touchPointID, true);
			return -steps;
		}
		#end
		return 0;
	}

	public static function swiped(direction:SwipeDirection):Bool
	{
		refresh();
		if (isConsumed())
			return false;

		for (swipe in FlxG.swipes)
		{
			if (!draggedTouches.exists(swipe.ID) && getDirection(swipe) == direction)
				return true;
		}
		return false;
	}

	public static function anySwipe():Bool
	{
		refresh();
		if (isConsumed())
			return false;

		for (swipe in FlxG.swipes)
		{
			if (!draggedTouches.exists(swipe.ID) && getDirection(swipe) != null)
				return true;
		}
		return false;
	}

	static function refresh():Void
	{
		if (refreshedTick == FlxG.game.ticks)
			return;
		refreshedTick = FlxG.game.ticks;

		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
				draggedTouches.remove(touch.touchPointID);
		}
		#end
	}

	static function getDirection(swipe:FlxSwipe):Null<SwipeDirection>
	{
		if (swipe.distance < swipeDistance)
			return null;

		var dx:Float = swipe.endPosition.x - swipe.startPosition.x;
		var dy:Float = swipe.endPosition.y - swipe.startPosition.y;
		var ax:Float = Math.abs(dx);
		var ay:Float = Math.abs(dy);
		if (ax >= ay * swipeRatio)
			return dx > 0 ? RIGHT : LEFT;
		if (ay >= ax * swipeRatio)
			return dy > 0 ? DOWN : UP;
		return null;
	}

	#if FLX_TOUCH
	static function isTouchTap(touch:FlxTouch):Bool
	{
		if (!touch.justReleased || draggedTouches.exists(touch.touchPointID))
			return false;

		var dx:Float = touch.viewX - touch.justPressedPosition.x;
		var dy:Float = touch.viewY - touch.justPressedPosition.y;
		return Math.sqrt(dx * dx + dy * dy) <= tapDistance;
	}
	#end
}
