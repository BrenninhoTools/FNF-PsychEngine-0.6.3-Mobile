package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var warnText:FlxText;
	#if mobile
	var yesText:Alphabet;
	var noText:Alphabet;
	#end
	override function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		#if mobile
		warnText = new FlxText(0, 0, FlxG.width,
			"Hey, watch out!\n
			This Mod contains some flashing lights!\n
			Do you want to disable them now?\n
			You can change it later in the Options Menu.\n
			You've been warned!",
			32);
		#else
		warnText = new FlxText(0, 0, FlxG.width,
			"Hey, watch out!\n
			This Mod contains some flashing lights!\n
			Press ENTER to disable them now or go to Options Menu.\n
			Press ESCAPE to ignore this message.\n
			You've been warned!",
			32);
		#end
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);

		#if mobile
		warnText.y -= 60;

		yesText = new Alphabet(0, FlxG.height - 140, 'Yes', true);
		yesText.x = FlxG.width * 0.25 - yesText.width / 2;
		add(yesText);

		noText = new Alphabet(0, FlxG.height - 140, 'No', true);
		noText.x = FlxG.width * 0.75 - noText.width / 2;
		add(noText);
		#end
	}

	override function update(elapsed:Float)
	{
		if(!leftState) {
			#if mobile
			var accept:Bool = mobile.TouchUtil.justTappedOn(yesText, FlxG.camera);
			var back:Bool = controls.BACK || mobile.TouchUtil.justTappedOn(noText, FlxG.camera);
			#else
			var accept:Bool = controls.ACCEPT;
			var back:Bool = controls.BACK;
			#end
			if (accept || back) {
				leftState = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				if(!back) {
					ClientPrefs.flashing = false;
					ClientPrefs.saveSettings();
					FlxG.sound.play(Paths.sound('confirmMenu'));
					#if mobile
					FlxFlicker.flicker(yesText, 1, 0.1, false, true);
					noText.visible = false;
					#end
					FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(flk:FlxFlicker) {
						new FlxTimer().start(0.5, function (tmr:FlxTimer) {
							MusicBeatState.switchState(new TitleState());
						});
					});
				} else {
					FlxG.sound.play(Paths.sound('cancelMenu'));
					#if mobile
					FlxTween.tween(yesText, {alpha: 0}, 1);
					FlxTween.tween(noText, {alpha: 0}, 1);
					#end
					FlxTween.tween(warnText, {alpha: 0}, 1, {
						onComplete: function (twn:FlxTween) {
							MusicBeatState.switchState(new TitleState());
						}
					});
				}
			}
		}
		super.update(elapsed);
	}
}
