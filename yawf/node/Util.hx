
package yawf.node;

import js.Node;

class Util
{

	public static function trace(obj:Dynamic) {
		var util = Node.require('util');
		trace(util.inspect(obj, { depth: 99 })); //problems but a bitch ain't one!
	}

	public static function fileExists(path:String):Bool {
		var fs:Dynamic = Node.require("fs");
		return fs.existsSync(path);
	}
	
	public static function getDirName():String {
		return untyped __dirname;
	}

	public static function resolvePath(to:String):String {
		var res:String;
		if (to.charAt(0) != "/") {
			res = getDirName() + '/' + to;
		} else {
			res = to;
		}
		return res;
	}

}