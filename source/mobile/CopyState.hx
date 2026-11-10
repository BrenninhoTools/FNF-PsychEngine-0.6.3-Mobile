package mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.io.Path;
import lime.utils.AssetLibrary;
import lime.utils.Assets as LimeAssets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class CopyState extends FlxState
{
	static final ignoredExtensions:Array<String> = ['png', 'jpg', 'jpeg', 'ogg', 'mp3', 'wav', 'ttf', 'otf'];
	static final filesPerFrame:Int = 25;

	var queue:Array<{library:AssetLibrary, id:String}> = [];
	var total:Int = 0;
	var copied:Int = 0;
	var failed:Int = 0;

	var loadingText:FlxText;
	var progressBar:FlxSprite;

	public static function getMissingFiles():Array<{library:AssetLibrary, id:String}>
	{
		var missing:Array<{library:AssetLibrary, id:String}> = [];
		#if sys
		var libraries:Map<String, AssetLibrary> = @:privateAccess LimeAssets.libraries;
		var seen:Map<String, Bool> = new Map();
		for (library in libraries)
		{
			if (library == null)
				continue;

			for (id in library.list(null))
			{
				if (seen.exists(id) || !shouldCopy(id))
					continue;

				seen.set(id, true);
				if (!FileSystem.exists(id))
					missing.push({library: library, id: id});
			}
		}
		#end
		return missing;
	}

	static function shouldCopy(id:String):Bool
	{
		if (id.startsWith('mods/'))
			return true;
		if (!id.startsWith('assets/'))
			return false;
		return !ignoredExtensions.contains(Path.extension(id).toLowerCase());
	}

	override function create()
	{
		super.create();

		queue = getMissingFiles();
		total = queue.length;
		StorageUtil.createDirectory('mods');

		if (total == 0)
		{
			finish();
			return;
		}

		loadingText = new FlxText(0, FlxG.height - 120, FlxG.width, '', 28);
		loadingText.setFormat(null, 28, FlxColor.WHITE, CENTER);
		add(loadingText);

		var barBG:FlxSprite = new FlxSprite(100, FlxG.height - 70).makeGraphic(FlxG.width - 200, 20, 0xFF333333);
		add(barBG);

		progressBar = new FlxSprite(barBG.x, barBG.y).makeGraphic(Std.int(barBG.width), 20, FlxColor.WHITE);
		progressBar.origin.set(0, 0);
		progressBar.scale.x = 0;
		add(progressBar);

		updateText();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (total == 0)
			return;

		var count:Int = 0;
		while (queue.length > 0 && count < filesPerFrame)
		{
			copyFile(queue.shift());
			count++;
		}
		updateText();

		if (queue.length == 0)
		{
			total = 0;
			finish();
		}
	}

	function copyFile(entry:{library:AssetLibrary, id:String}):Void
	{
		#if sys
		try
		{
			var directory:String = Path.directory(entry.id);
			if (directory.length > 0 && !FileSystem.exists(directory))
				FileSystem.createDirectory(directory);

			var bytes = entry.library.getBytes(entry.id);
			if (bytes != null)
			{
				File.saveBytes(entry.id, bytes);
				copied++;
			}
			else
				failed++;
		}
		catch (e:Dynamic)
		{
			failed++;
		}
		#end
	}

	function updateText():Void
	{
		if (loadingText == null)
			return;

		var done:Int = copied + failed;
		loadingText.text = 'Copying files... $done/$total';
		progressBar.scale.x = total > 0 ? done / total : 1;
	}

	function finish():Void
	{
		FlxG.switchState(() -> new TitleState());
	}
}
