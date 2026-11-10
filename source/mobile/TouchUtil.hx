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
	public static var tapDistanceMM:Float = 4;
	public static var swipeDistanceMM:Float = 7;
	public static var scrollStepMM:Float = 8;
	public static var flingMinSpeedMM:Float = 45;
	public static var flingFactor:Float = 0.12;
	public static var flingMaxSteps:Int = 8;
	public static var flingStepDelay:Float = 0.04;
	public static var swipeRatio:Float = 1.5;
	public static var tapMarginMM:Float = 1.5;

	public static var tapDistance(get, never):Float;
	public static var swipeDistance(get, never):Float;
	public static var scrollStep(get, never):Float;

	static function get_tapDistance():Float
		return mmToGame(tapDistanceMM);

	static function get_swipeDistance():Float
		return mmToGame(swipeDistanceMM);

	static function get_scrollStep():Float
		return mmToGame(scrollStepMM);

	public static function mmToGame(mm:Float):Float
	{
		var dpi:Float = openfl.system.Capabilities.screenDPI;
		if (Math.isNaN(dpi) || dpi < 120)
			dpi = 160;
		else if (dpi > 640)
			dpi = 640;

		var scale:Float = (FlxG.scaleMode != null && FlxG.scaleMode.scale.y > 0) ? FlxG.scaleMode.scale.y : 1;
		return mm / 25.4 * dpi / scale;
	}

	static var consumedTick:Int = -1;
	static var refreshedTick:Int = -1;
	static var draggedTouches:Map<Int, Bool> = new Map();
	static var scrollTouchID:Int = -1;
	static var scrollAnchorY:Float = 0;
	static var scrollStartY:Float = 0;
	static var scrolling:Bool = false;
	static var scrollSamples:Array<{time:Float, y:Float}> = [];
	static var pendingSteps:Int = 0;
	static var pendingTotal:Int = 0;
	static var lastPendingTime:Float = 0;

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

	public static function acceptTapped():Bool
	{
		if (!justTapped())
			return false;
		Haptics.menu();
		return true;
	}

	public static function justTappedOn(object:FlxBasic, ?camera:FlxCamera):Bool
	{
		refresh();
		if (object == null || isConsumed())
			return false;

		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
		{
			if (isTouchTap(touch) && overlaps(touch, object, camera, mmToGame(tapMarginMM)))
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
				Haptics.menu();
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
			if (touch.pressed && overlaps(touch, object, camera) && (!ignoreButtons || !MobileButton.isOverAny(touch)))
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
		var now:Float = haxe.Timer.stamp();
		var touch:FlxTouch = null;
		for (t in FlxG.touches.list)
		{
			if (t.touchPointID == scrollTouchID && (t.pressed || t.justReleased))
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
					scrollStartY = t.justPressedPosition.y;
					scrollAnchorY = scrollStartY;
					scrolling = false;
					scrollSamples = [];
					pendingSteps = 0;
					break;
				}
			}
		}

		if (touch == null)
			return popPendingStep(now);

		pendingSteps = 0;
		scrollSamples.push({time: now, y: touch.viewY});
		while (scrollSamples.length > 0 && now - scrollSamples[0].time > 0.1)
			scrollSamples.shift();

		var result:Int = 0;
		if (!scrolling)
		{
			var moved:Float = touch.viewY - scrollStartY;
			if (Math.abs(moved) > tapDistance)
			{
				scrolling = true;
				scrollAnchorY = scrollStartY + (moved > 0 ? tapDistance : -tapDistance);
				draggedTouches.set(touch.touchPointID, true);
			}
		}

		if (scrolling)
		{
			var dragSpeed:Float = getSampleSpeed();
			var speedMM:Float = Math.abs(dragSpeed) / mmToGame(1);
			if (speedMM > 220)
				step *= 0.5;
			else if (speedMM > 110)
				step *= 0.7;

			var steps:Int = Std.int((touch.viewY - scrollAnchorY) / step);
			if (steps != 0)
			{
				scrollAnchorY += steps * step;
				result = -steps;
			}
		}

		if (touch.justReleased)
		{
			if (scrolling && scrollSamples.length > 1)
			{
				var speed:Float = getSampleSpeed();
				if (Math.abs(speed) >= mmToGame(flingMinSpeedMM))
				{
					var extra:Int = Std.int(Math.min(flingMaxSteps, Math.round(Math.abs(speed) * flingFactor / scrollStep)));
					pendingSteps = speed > 0 ? -extra : extra;
					pendingTotal = extra;
					lastPendingTime = now;
				}
			}
			scrollTouchID = -1;
			scrolling = false;
			scrollSamples = [];
		}

		if (result != 0)
			Haptics.menu();
		return result;
		#else
		return 0;
		#end
	}

	static function getSampleSpeed():Float
	{
		if (scrollSamples.length < 2)
			return 0;

		var first = scrollSamples[0];
		var last = scrollSamples[scrollSamples.length - 1];
		var time:Float = last.time - first.time;
		return time > 0 ? (last.y - first.y) / time : 0;
	}

	static function popPendingStep(now:Float):Int
	{
		if (pendingSteps == 0)
			return 0;

		var done:Int = pendingTotal - Std.int(Math.abs(pendingSteps));
		var delay:Float = flingStepDelay * (1 + done * 0.35);
		if (now - lastPendingTime < delay)
			return 0;

		lastPendingTime = now;
		var dir:Int = pendingSteps > 0 ? 1 : -1;
		pendingSteps -= dir;
		Haptics.menu();
		return dir;
	}

	public static function swiped(direction:SwipeDirection):Bool
	{
		refresh();
		if (isConsumed())
			return false;

		for (swipe in FlxG.swipes)
		{
			if (!draggedTouches.exists(swipe.ID) && getDirection(swipe) == direction)
			{
				Haptics.menu();
				return true;
			}
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
	public static function overlaps(touch:FlxTouch, basic:FlxBasic, ?camera:FlxCamera, margin:Float = 0):Bool
	{
		if (touch == null || basic == null || !basic.exists || !basic.visible)
			return false;

		if (camera == null)
			camera = FlxG.camera;
		if (camera == null || camera.scroll == null)
			return false;

		var group = @:privateAccess flixel.group.FlxGroup.FlxTypedGroup.resolveGroup(basic);
		if (group != null)
		{
			if (group.members == null)
				return false;
			for (member in group.members)
			{
				if (overlaps(touch, member, camera, margin))
					return true;
			}
			return false;
		}

		var object:flixel.FlxObject = Std.downcast(basic, flixel.FlxObject);
		if (object == null || object.scrollFactor == null)
			return false;

		var world:flixel.math.FlxPoint = touch.getWorldPosition(camera);
		var screen:flixel.math.FlxPoint = object.getScreenPosition(null, camera);
		var px:Float = world.x - camera.scroll.x;
		var py:Float = world.y - camera.scroll.y;
		var result:Bool = px >= screen.x - margin && px < screen.x + object.width + margin && py >= screen.y - margin && py < screen.y + object.height + margin;
		world.put();
		screen.put();
		return result;
	}

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
