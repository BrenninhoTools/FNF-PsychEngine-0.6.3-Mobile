package options;

class MobileOptionsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Mobile Options';
		rpcTitle = 'Mobile Options Menu';

		var option:Option = new Option('Hitbox Mode',
			'Four Lanes: the screen is split in four lanes.\nArrows: the strums go to the bottom, tap them to hit notes.',
			'hitboxMode',
			'string',
			'Four Lanes',
			mobile.Hitbox.modes);
		addOption(option);

		var option:Option = new Option('Invisible Hitbox',
			'If checked, the hitbox will be invisible\nbut it will still work.',
			'invisibleHitbox',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Invisible Pause Button',
			'If checked, the pause button will be invisible\nbut it will still work.',
			'invisiblePauseButton',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Chart Editor in Pause',
			'If checked, a Chart Editor option will be\nadded to the pause menu.',
			'chartEditorInPause',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Haptics',
			'If checked, the device will vibrate\nin the menus and when hitting notes.',
			'haptics',
			'bool',
			true);
		option.onChange = onChangeHaptics;
		addOption(option);

		var option:Option = new Option('Haptics Type',
			'All: vibrates for everything.\nNotes: vibrates only for notes and sustains.',
			'hapticsType',
			'string',
			'All',
			['All', 'Notes']);
		option.onChange = onChangeHaptics;
		addOption(option);

		var option:Option = new Option('Haptics Intensity',
			'How strong the vibration is.',
			'hapticsIntensity',
			'float',
			1);
		option.scrollSpeed = 1;
		option.minValue = 0.0;
		option.maxValue = 5.0;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = onChangeHaptics;
		addOption(option);

		#if mobile
		var option:Option = new Option('Screen Style',
			'Original: the classic 16:9 screen.\nFull: uses the whole screen without stretching.',
			'screenStyle',
			'string',
			'Original',
			mobile.ScreenUtil.styles);
		option.onChange = onChangeScreenStyle;
		addOption(option);
		#end

		#if android
		ClientPrefs.storageType = mobile.StorageUtil.getStorageType();
		var option:Option = new Option('Storage Type',
			'Where the game files and mods are stored.\nRestart the game to apply.',
			'storageType',
			'string',
			'Data',
			mobile.StorageUtil.storageTypes);
		option.onChange = onChangeStorageType;
		addOption(option);
		#end

		super();
	}

	#if mobile
	function onChangeScreenStyle()
	{
		mobile.ScreenUtil.apply(ClientPrefs.screenStyle);
	}
	#end

	function onChangeHaptics()
	{
		mobile.Haptics.note();
	}

	#if android
	function onChangeStorageType()
	{
		mobile.StorageUtil.setStorageType(ClientPrefs.storageType);
	}
	#end
}
