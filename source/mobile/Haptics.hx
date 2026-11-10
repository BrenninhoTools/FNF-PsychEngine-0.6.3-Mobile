package mobile;

import flixel.FlxG;
import haxe.Timer;

#if ios
@:cppFileCode('
#include <objc/runtime.h>
#include <objc/message.h>

static void hapticsImpact(int style, double intensity)
{
	Class generatorClass = objc_getClass("UIImpactFeedbackGenerator");
	if (generatorClass == nil)
		return;

	id generator = ((id (*)(id, SEL))objc_msgSend)((id)generatorClass, sel_registerName("alloc"));
	generator = ((id (*)(id, SEL, long))objc_msgSend)(generator, sel_registerName("initWithStyle:"), (long)style);
	if (generator == nil)
		return;

	SEL withIntensity = sel_registerName("impactOccurredWithIntensity:");
	if (class_respondsToSelector(generatorClass, withIntensity))
		((void (*)(id, SEL, double))objc_msgSend)(generator, withIntensity, intensity);
	else
		((void (*)(id, SEL))objc_msgSend)(generator, sel_registerName("impactOccurred"));

	((void (*)(id, SEL))objc_msgSend)(generator, sel_registerName("release"));
}
')
#end
class Haptics
{
	public static var menuDuration:Float = 8;
	public static var noteDuration:Float = 14;
	public static var sustainDuration:Float = 6;
	public static var sustainInterval:Float = 0.07;

	static var lastTick:Int = -1;
	static var lastTime:Float = 0;
	static var lastSustainTime:Float = 0;

	public static function menu():Void
	{
		if (lastTick == FlxG.game.ticks)
			return;
		lastTick = FlxG.game.ticks;
		play(menuDuration, 0.6, 0);
	}

	public static function note():Void
	{
		play(noteDuration, 1, 1);
	}

	public static function sustain():Void
	{
		var now:Float = Timer.stamp();
		if (now - lastSustainTime < sustainInterval)
			return;
		lastSustainTime = now;
		play(sustainDuration, 0.35, 0);
	}

	public static function play(duration:Float, strength:Float = 1, style:Int = 0):Void
	{
		#if mobile
		if (!ClientPrefs.haptics || ClientPrefs.hapticsIntensity <= 0)
			return;

		var now:Float = Timer.stamp();
		if (now - lastTime < 0.02)
			return;
		lastTime = now;

		#if android
		var time:Int = Math.round(duration * ClientPrefs.hapticsIntensity);
		if (time > 0)
			lime.ui.Haptic.vibrate(0, time);
		#elseif ios
		var intensity:Float = Math.min(1, strength * ClientPrefs.hapticsIntensity * 0.5);
		if (intensity > 0)
			impact(style, intensity);
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
