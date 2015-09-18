package yawf.node;

import yawf.typedefs.MomentDate;
import js.Node;

class MomentDateUtil {
	public static var module:Dynamic;

	public static function initModule():Void {
		if (module == null) {
			module = Node.require("moment-timezone");
		}
	}

	public static function ofMilliseconds(ms:Int):MomentDate {
		initModule();
		return module(ms).tz("Europe/Warsaw");
	}

	public static function ofIso(isoString:String):MomentDate {
		initModule();
		return module(isoString).tz("Europe/Warsaw");
	}
}
