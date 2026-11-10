package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.FlxCamera;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	#if mobile
	public var mobileCamera:FlxCamera;
	public var backButton:mobile.MobileButton;
	#end

	public function addBackButton():Void
	{
		#if mobile
		if (backButton != null)
			return;

		if (mobileCamera == null)
		{
			mobileCamera = new FlxCamera();
			mobileCamera.bgColor = 0x00000000;
			FlxG.cameras.add(mobileCamera, false);
		}

		backButton = new mobile.MobileButton(0, 0, 'backButton', 'back', 0.75);
		backButton.setPosition(FlxG.width - backButton.width - 10, FlxG.height - backButton.height - 10);
		backButton.isBackButton = true;
		backButton.cameras = [mobileCamera];
		add(backButton);
		#end
	}

	override function create()
	{
		super.create();
		#if mobile
		mobile.ScreenUtil.fitBackgrounds(this);
		#end
	}

	override function destroy()
	{
		#if mobile
		if (mobileCamera != null && FlxG.cameras.list.contains(mobileCamera))
			FlxG.cameras.remove(mobileCamera);
		mobileCamera = null;
		#end
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();


		super.update(elapsed);
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
}
