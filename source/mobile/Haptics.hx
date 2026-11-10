package mobile;

import flixel.FlxG;
import haxe.Timer;

enum HapticStyle
{
	LIGHT;
	MEDIUM;
	HEAVY;
}

typedef HapticEffect =
{
	var id:String;
	var time:Float;
	var duration:Float;
	var interval:Float;
	var lastPulse:Float;
	var style:HapticStyle;
	var curve:Float->Float;
}

#if ios
@:cppFileCode('
#include <objc/runtime.h>
#include <objc/message.h>

static id hapticsGenerators[3] = {nil, nil, nil};

static void hapticsImpact(int style, double intensity)
{
	if (style < 0 || style > 2)
		style = 0;

	Class generatorClass = objc_getClass("UIImpactFeedbackGenerator");
	if (generatorClass == nil)
		return;

	if (hapticsGenerators[style] == nil)
	{
		id generator = ((id (*)(id, SEL))objc_msgSend)((id)generatorClass, sel_registerName("alloc"));
		generator = ((id (*)(id, SEL, long))objc_msgSend)(generator, sel_registerName("initWithStyle:"), (long)style);
		if (generator == nil)
			return;
		((void (*)(id, SEL))objc_msgSend)(generator, sel_registerName("prepare"));
		hapticsGenerators[style] = generator;
	}

	id generator = hapticsGenerators[style];
	SEL withIntensity = sel_registerName("impactOccurredWithIntensity:");
	if (class_respondsToSelector(generatorClass, withIntensity))
		((void (*)(id, SEL, double))objc_msgSend)(generator, withIntensity, intensity);
	else
		((void (*)(id, SEL))objc_msgSend)(generator, sel_registerName("impactOccurred"));
	((void (*)(id, SEL))objc_msgSend)(generator, sel_registerName("prepare"));
}
')
#end
class Haptics
{
	public static var maxDuration:Int = 500;

	static var initialized:Bool = false;
	static var lastTick:Int = -1;
	static var lastTimes:Map<String, Float> = new Map();
	static var effects:Array<HapticEffect> = [];

	static var trainActiveUntil:Float = 0;
	static var trainLastPulse:Float = 0;
	static var trainLastClack:Float = 0;
	static var trainClackCount:Int = 0;

	static var sustainActiveUntil:Float = 0;
	static var sustainStart:Float = 0;
	static var sustainLastPulse:Float = 0;
	static var sustainLastTug:Float = 0;

	public static var enabled(get, never):Bool;

	public static var allEnabled(get, never):Bool;

	static function get_allEnabled():Bool
	{
		#if mobile
		return enabled && ClientPrefs.hapticsType != 'Notes';
		#else
		return false;
		#end
	}

	static function get_enabled():Bool
	{
		#if mobile
		return ClientPrefs.haptics && ClientPrefs.hapticsIntensity > 0;
		#else
		return false;
		#end
	}

	public static var intensity(get, never):Float;

	static function get_intensity():Float
	{
		#if mobile
		return Math.min(5, Math.max(0, ClientPrefs.hapticsIntensity));
		#else
		return 0;
		#end
	}

	public static function init():Void
	{
		if (initialized)
			return;
		initialized = true;
		FlxG.signals.postUpdate.add(update);
		FlxG.signals.preStateSwitch.add(stopAll);
		FlxG.signals.focusLost.add(stopAll);
	}

	public static function menu():Void
	{
		if (!allEnabled || lastTick == FlxG.game.ticks)
			return;
		lastTick = FlxG.game.ticks;
		pulse('menu', 10, 0.45, LIGHT, 0.035);
	}

	public static function confirm():Void
	{
		if (!allEnabled)
			return;
		lastTick = FlxG.game.ticks;
		if (pulse('confirm', 45, 1, HEAVY, 0.1))
			startEffect('confirm', 0.35, 0.09, HEAVY, function(t:Float) return t < 0.3 ? 0 : 1 - t);
	}

	public static function note():Void
	{
		pulse('note', 16, 0.75, MEDIUM, 0.025);
	}

	public static function sustain():Void
	{
		if (!enabled)
			return;
		init();

		var now:Float = Timer.stamp();
		if (now > sustainActiveUntil)
		{
			sustainStart = now;
			sustainLastPulse = 0;
			sustainLastTug = now;
		}
		sustainActiveUntil = now + 0.2;
	}

	public static function thunder():Void
	{
		if (!allEnabled)
			return;
		lastTimes.remove('thunder');
		pulse('thunder', 120, 1, HEAVY, 0.1);
		startEffect('thunder', 1.6, 0.05, HEAVY, function(t:Float)
		{
			if (t < 0.08)
				return 0;
			var flicker:Float = 0.75 + 0.25 * Math.sin(t * 60);
			return Math.max(0, (1 - t) * flicker);
		});
	}

	public static function carPass():Void
	{
		if (!allEnabled)
			return;
		startEffect('car', 1.5, 0.045, HEAVY, function(t:Float)
		{
			if (t < 0.2)
				return 0.25 + (t / 0.2) * 0.75;
			if (t < 0.35)
				return 1;
			return Math.max(0, 1 - (t - 0.35) / 0.65);
		});
	}

	public static function trainPassing():Void
	{
		if (!allEnabled)
			return;
		trainActiveUntil = Timer.stamp() + 0.15;
	}

	public static function stopAll():Void
	{
		effects = [];
		trainActiveUntil = 0;
		trainClackCount = 0;
		sustainActiveUntil = 0;
	}

	public static function startEffect(id:String, duration:Float, interval:Float, style:HapticStyle, curve:Float->Float):Void
	{
		if (!enabled)
			return;
		init();

		for (effect in effects)
		{
			if (effect.id == id)
			{
				effect.time = 0;
				effect.lastPulse = -interval;
				return;
			}
		}
		effects.push({id: id, time: 0, duration: duration, interval: interval, lastPulse: -interval, style: style, curve: curve});
	}

	public static function pulse(id:String, duration:Float, strength:Float = 1, style:HapticStyle = LIGHT, interval:Float = 0.02):Bool
	{
		if (!enabled)
			return false;

		var now:Float = Timer.stamp();
		var last:Null<Float> = lastTimes.get(id);
		if (last != null && now - last < interval)
			return false;
		lastTimes.set(id, now);

		#if android
		vibrate(0, Math.round(duration * strength * intensity));
		#elseif ios
		impact(style, strength * intensity * 0.5);
		#end
		return true;
	}

	static function update():Void
	{
		if (!enabled)
		{
			stopAll();
			return;
		}

		var elapsed:Float = FlxG.elapsed;
		var i:Int = effects.length - 1;
		while (i >= 0)
		{
			var effect:HapticEffect = effects[i];
			effect.time += elapsed;
			if (effect.time >= effect.duration)
			{
				effects.splice(i, 1);
			}
			else if (effect.time - effect.lastPulse >= effect.interval)
			{
				effect.lastPulse = effect.time;
				var strength:Float = effect.curve(effect.time / effect.duration);
				if (strength > 0.02)
					continuous(effect.interval, strength, effect.style);
			}
			i--;
		}

		updateTrain();
		updateSustain();
	}

	static function updateSustain():Void
	{
		var now:Float = Timer.stamp();
		if (now > sustainActiveUntil)
			return;

		var held:Float = now - sustainStart;
		var tension:Float = Math.min(1, 0.7 + held * 0.4);

		if (now - sustainLastTug >= 0.22)
		{
			sustainLastTug = now;
			sustainLastPulse = now;
			#if android
			vibrate(0, Math.round(Math.min(maxDuration, 90 * Math.max(0.6, Math.min(2.5, intensity)))));
			#elseif ios
			impact(HEAVY, Math.min(1, tension * intensity * 0.65));
			#end
		}
		else if (now - sustainLastPulse >= 0.05)
		{
			sustainLastPulse = now;
			continuous(0.05, tension, MEDIUM);
		}
	}

	static function updateTrain():Void
	{
		var now:Float = Timer.stamp();
		if (now > trainActiveUntil)
		{
			trainClackCount = 0;
			return;
		}

		if (now - trainLastClack >= 0.24)
		{
			trainLastClack = now;
			trainLastPulse = now;
			trainClackCount++;
			#if android
			vibrate(trainClackCount % 2 == 0 ? 50 : 36, Math.round(Math.min(maxDuration, 200 * Math.max(0.5, Math.min(2, intensity)))));
			#elseif ios
			impact(HEAVY, Math.min(1, intensity * 0.6));
			#end
		}
		else if (now - trainLastPulse >= 0.08 && now - trainLastClack >= 0.2)
		{
			trainLastPulse = now;
			continuous(0.08, 0.85, HEAVY);
		}
	}

	static function continuous(interval:Float, strength:Float, style:HapticStyle):Void
	{
		#if android
		var length:Float = interval * 1000 * Math.min(1.25, strength * Math.max(0.6, intensity));
		vibrate(0, Math.round(length));
		#elseif ios
		impact(style, strength * intensity * 0.5);
		#end
	}

	static function vibrate(period:Int, duration:Int):Void
	{
		#if android
		if (duration <= 0)
			return;
		try
		{
			lime.ui.Haptic.vibrate(period, Std.int(Math.min(maxDuration, duration)));
		}
		catch (e:Dynamic) {}
		#end
	}

	#if ios
	static function impact(style:HapticStyle, amount:Float):Void
	{
		amount = Math.min(1, Math.max(0, amount));
		if (amount <= 0)
			return;
		var styleIndex:Int = style.getIndex();
		untyped __cpp__('hapticsImpact({0}, {1})', styleIndex, amount);
	}
	#end
}
