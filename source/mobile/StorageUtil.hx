package mobile;

import haxe.io.Path;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if android
import extension.androidtools.Permissions;
import extension.androidtools.Settings;
import extension.androidtools.content.Context;
import extension.androidtools.os.Build.VERSION;
import extension.androidtools.os.Environment;
#end

using StringTools;

class StorageUtil
{
	public static final storageTypes:Array<String> = ['Data', 'External', 'Media', 'Obb'];

	public static function getStorageDirectory():String
	{
		#if android
		var directory:String = switch (getStorageType())
		{
			case 'External':
				Environment.getExternalStorageDirectory() + '/.' + lime.app.Application.current.meta.get('file');
			case 'Media':
				Environment.getExternalStorageDirectory() + '/Android/media/' + lime.app.Application.current.meta.get('packageName');
			case 'Obb':
				Context.getObbDir();
			default:
				Context.getExternalFilesDir();
		}

		if (directory == null || directory.length == 0)
			directory = Context.getExternalFilesDir();
		if (directory == null || directory.length == 0)
			directory = Context.getFilesDir();

		directory = Path.addTrailingSlash(directory);
		try
		{
			createDirectory(directory);
		}
		catch (e:Dynamic)
		{
			directory = Path.addTrailingSlash(Context.getExternalFilesDir());
		}
		return directory;
		#elseif ios
		return Path.addTrailingSlash(lime.system.System.documentsDirectory);
		#elseif sys
		return Path.addTrailingSlash(Sys.getCwd());
		#else
		return '';
		#end
	}

	public static function getStorageType():String
	{
		#if android
		try
		{
			var file:String = getStorageTypeFile();
			if (FileSystem.exists(file))
			{
				var type:String = File.getContent(file).trim();
				if (storageTypes.contains(type))
					return type;
			}
		}
		catch (e:Dynamic) {}
		#end
		return 'Data';
	}

	public static function setStorageType(type:String):Void
	{
		#if android
		if (!storageTypes.contains(type))
			return;

		try
		{
			File.saveContent(getStorageTypeFile(), type);
		}
		catch (e:Dynamic) {}

		if (type == 'External')
			requestPermissions();
		#end
	}

	public static function requestPermissions():Void
	{
		#if android
		if (VERSION.SDK_INT >= 30)
		{
			if (!Environment.isExternalStorageManager())
				Settings.requestSetting('MANAGE_ALL_FILES_ACCESS_PERMISSION');
		}
		else
		{
			var granted:Array<String> = Permissions.getGrantedPermissions();
			if (!granted.contains('android.permission.READ_EXTERNAL_STORAGE') || !granted.contains('android.permission.WRITE_EXTERNAL_STORAGE'))
				Permissions.requestPermissions(['android.permission.READ_EXTERNAL_STORAGE', 'android.permission.WRITE_EXTERNAL_STORAGE']);
		}
		#end
	}

	public static function createDirectory(path:String):Void
	{
		#if sys
		if (path != null && path.length > 0 && !FileSystem.exists(path))
			FileSystem.createDirectory(path);
		#end
	}

	#if android
	static function getStorageTypeFile():String
	{
		return Path.addTrailingSlash(Context.getFilesDir()) + 'storagetype.txt';
	}
	#end
}
