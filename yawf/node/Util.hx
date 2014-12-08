
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

	public static function preciseNow(from:Array<Int> = null):Array<Int> {
		var now = Node.process.hrtime();
		if (from == null) {
			return now;
		} else {
			return preciseTimeDelta(now, from);
		}
	}

	public static function preciseTimeDelta(now:Array<Int>, from:Array<Int>):Array<Int> {
		var ns:Int = now[1] - from[1];
		var s:Int;
		if (ns < 0) {
			ns = 1000000000 + ns;
			s = now[0] - from[0] - 1;
		} else {
			s = now[0] - from[0];
		}
		return [s, ns];
	}

	public static function preciseTimeSum(time:Array<Int>, delta:Array<Int>):Array<Int> {
		var ns:Int = time[1] + delta[1];
		var s:Int = time[0] + delta[0];
		if (ns >= 1000000000) {
			s += 1;
			ns -= 1000000000;
		}
		return [s, ns];
	}

	public static function prettyPreciseTime(time:Array<Int>):String {
		return time[0] + "s and " + (Std.int(time[1]/1000000)) + "ms";
	}

}