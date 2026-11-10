package mobile;

import flixel.FlxG;
import haxe.Timer;

enum HapticStyle
{
	LIGHT;
	MEDIUM;
	HEAVY;
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
	public static var maxDuration:Int = 400;

	static var lastTick:Int = -1;
	static var lastTimes:Map<String, Float> = new Map();

	public static var enabled(get, never):Bool;

	static function get_enabled():Bool
	{
		#if mobile
		return ClientPrefs.haptics && ClientPrefs.hapticsIntensity > 0;
		#else
		return false;
		#end
	}

	public static function menu():Void
	{
		if (lastTick == FlxG.game.ticks)
			return;
		lastTick = FlxG.game.ticks;
		play('menu', 8, 0.5, LIGHT, 0.03);
	}

	public static function confirm():Void
	{
		lastTick = FlxG.game.ticks;
		play('confirm', 70, 1, HEAVY, 0.1);
	}

	public static function note():Void
	{
		play('note', 14, 0.8, MEDIUM, 0.02);
	}

	public static function sustain():Void
	{
		play('sustain', 6, 0.3, LIGHT, 0.07);
	}

	public static function rumble():Void
	{
		play('rumble', 35, 0.7, HEAVY, 0.12);
	}

	public static function play(id:String, duration:Float, strength:Float = 1, style:HapticStyle = LIGHT, interval:Float = 0.02):Void
	{
		#if mobile
		if (!enabled)
			return;

		var now:Float = Timer.stamp();
		var last:Null<Float> = lastTimes.get(id);
		if (last != null && now - last < interval)
			return;
		lastTimes.set(id, now);

		var intensity:Float = Math.min(5, Math.max(0, ClientPrefs.hapticsIntensity));

		#if android
		var time:Int = Std.int(Math.min(maxDuration, Math.round(duration * intensity)));
		if (time > 0)
		{
			try
			{
				lime.ui.Haptic.vibrate(0, time);
			}
			catch (e:Dynamic) {}
		}
		#elseif ios
		var amount:Float = Math.min(1, strength * intensity * 0.5);
		if (amount > 0)
			impact(style.getIndex(), amount);
		#end
		#end
	}

	#if ios
	static function impact(style:Int, intensity:Float):Void
	{
		untyped __cpp__('hapticsImpact({0}, {1})', style, intensity);
	}
	#end
}
