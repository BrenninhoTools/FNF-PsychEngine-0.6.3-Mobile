package mobile;

import haxe.io.Path;
#if sys
import sys.FileSystem;
#end

class StorageUtil
{
	public static function getStorageDirectory():String
	{
		#if android
		var directory:String = extension.androidtools.content.Context.getExternalFilesDir();
		if (directory == null || directory.length == 0)
			directory = extension.androidtools.content.Context.getFilesDir();
		return Path.addTrailingSlash(directory);
		#elseif ios
		return Path.addTrailingSlash(lime.system.System.documentsDirectory);
		#elseif sys
		return Path.addTrailingSlash(Sys.getCwd());
		#else
		return '';
		#end
	}

	public static function createDirectory(path:String):Void
	{
		#if sys
		if (path != null && path.length > 0 && !FileSystem.exists(path))
			FileSystem.createDirectory(path);
		#end
	}
}
