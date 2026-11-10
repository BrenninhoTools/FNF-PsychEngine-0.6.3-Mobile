package options;

class MobileOptionsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Mobile Options';
		rpcTitle = 'Mobile Options Menu';

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

	#if android
	function onChangeStorageType()
	{
		mobile.StorageUtil.setStorageType(ClientPrefs.storageType);
	}
	#end
}
