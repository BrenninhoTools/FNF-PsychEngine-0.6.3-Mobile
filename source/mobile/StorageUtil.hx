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
import extension.androidtools.widget.Toast;
#end

using StringTools;

class StorageUtil
{
	public static final storageTypes:Array<String> = ['Data', 'External', 'Media', 'Obb'];

	static var cachedDirectory:String = null;
	static var cachedType:String = null;

	public static function getStorageDirectory(force:Bool = false):String
	{
		if (cachedDirectory != null && !force)
			return cachedDirectory;

		#if android
		var type:String = getStorageType();
		var directory:String = getDirectoryForType(type);

		if (!prepareDirectory(directory))
		{
			if (type != 'Data')
				showToast('Could not use $type storage, using Data instead.');
			directory = getDirectoryForType('Data');
			if (!prepareDirectory(directory))
				directory = Path.addTrailingSlash(Context.getFilesDir());
		}

		cachedDirectory = directory;
		#elseif ios
		cachedDirectory = Path.addTrailingSlash(lime.system.System.documentsDirectory);
		#elseif sys
		cachedDirectory = Path.addTrailingSlash(Sys.getCwd());
		#else
		cachedDirectory = '';
		#end
		return cachedDirectory;
	}

	public static function getDirectoryForType(type:String):String
	{
		#if android
		var directory:String = switch (type)
		{
			case 'External':
				Environment.getExternalStorageDirectory() + '/.' + getAppFile();
			case 'Media':
				Environment.getExternalStorageDirectory() + '/Android/media/' + getPackageName();
			case 'Obb':
				Context.getObbDir();
			default:
				Context.getExternalFilesDir();
		}

		if (directory == null || directory.length == 0 || directory.startsWith('null'))
			directory = Context.getFilesDir();
		return Path.addTrailingSlash(directory);
		#else
		return getStorageDirectory();
		#end
	}

	public static function getStorageType():String
	{
		if (cachedType != null)
			return cachedType;

		cachedType = 'Data';
		#if android
		try
		{
			var file:String = getStorageTypeFile();
			if (FileSystem.exists(file))
			{
				var type:String = File.getContent(file).trim();
				if (storageTypes.contains(type))
					cachedType = type;
			}
		}
		catch (e:Dynamic) {}
		#end
		return cachedType;
	}

	public static function setStorageType(type:String):Void
	{
		#if android
		if (!storageTypes.contains(type))
			return;

		try
		{
			File.saveContent(getStorageTypeFile(), type);
			cachedType = type;
		}
		catch (e:Dynamic) {}

		if (type == 'External' && !hasExternalPermissions())
			requestPermissions();
		#end
	}

	public static function hasExternalPermissions():Bool
	{
		#if android
		try
		{
			if (VERSION.SDK_INT >= 30)
				return Environment.isExternalStorageManager();

			var granted:Array<String> = Permissions.getGrantedPermissions();
			return granted.contains('android.permission.READ_EXTERNAL_STORAGE') && granted.contains('android.permission.WRITE_EXTERNAL_STORAGE');
		}
		catch (e:Dynamic) {}
		return false;
		#else
		return true;
		#end
	}

	public static function requestPermissions():Void
	{
		#if android
		try
		{
			if (VERSION.SDK_INT >= 30)
			{
				if (!Environment.isExternalStorageManager())
					Settings.requestSetting('MANAGE_ALL_FILES_ACCESS_PERMISSION');
			}
			else
				Permissions.requestPermissions(['android.permission.READ_EXTERNAL_STORAGE', 'android.permission.WRITE_EXTERNAL_STORAGE']);
		}
		catch (e:Dynamic) {}
		#end
	}

	public static function createDirectory(path:String):Void
	{
		#if sys
		if (path != null && path.length > 0 && !FileSystem.exists(path))
			FileSystem.createDirectory(path);
		#end
	}

	public static function isWritable(path:String):Bool
	{
		#if sys
		try
		{
			var testFile:String = Path.addTrailingSlash(path) + '.write_test';
			File.saveContent(testFile, '');
			FileSystem.deleteFile(testFile);
			return true;
		}
		catch (e:Dynamic) {}
		#end
		return false;
	}

	static function prepareDirectory(path:String):Bool
	{
		if (path == null || path.length == 0)
			return false;

		try
		{
			createDirectory(path);
			createDirectory(Path.addTrailingSlash(path) + 'mods');
			return isWritable(path);
		}
		catch (e:Dynamic) {}
		return false;
	}

	static function getAppFile():String
	{
		var file:String = lime.app.Application.current != null ? lime.app.Application.current.meta.get('file') : null;
		return file != null ? file : 'PsychEngine063';
	}

	static function getPackageName():String
	{
		var packageName:String = lime.app.Application.current != null ? lime.app.Application.current.meta.get('packageName') : null;
		return packageName != null ? packageName : 'com.shadowmario.psychengine063';
	}

	static function showToast(message:String):Void
	{
		#if android
		try
		{
			Toast.makeText(message, Toast.LENGTH_LONG);
		}
		catch (e:Dynamic) {}
		#end
	}

	#if android
	static function getStorageTypeFile():String
	{
		return Path.addTrailingSlash(Context.getFilesDir()) + 'storagetype.txt';
	}
	#end
}
