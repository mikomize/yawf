
package yawf.node;

import js.Node;

class Util extends yawf.Util
{

	public static function trace(obj:Dynamic) {
		var util = Node.require('util');
		trace(util.inspect(obj, { depth: 99 })); //problems but a bitch ain't one!
	}

	public static function fileExists(path:String):Bool {
		var fs:Dynamic = Node.require("fs");
		return fs.existsSync(path);
	}
	

}