
package yawf;

import js.Node;
import yawf.reflections.*;


class Util
{
	public static function getType(obj:Dynamic):TypeEnum {
		switch(Type.typeof(obj)) {
			case TBool:
				return TypeEnum.Bool;
			case TClass(c): 
				var name:String = Type.getClassName(c);
				if(name == "String") {
					return TypeEnum.String;
				} else if (name == "haxe.ds.StringMap") {
					return TypeEnum.Map(null);
				} else if (name == "Array") {
					return TypeEnum.Array(null);
				}
				return TypeEnum.Class(c);
			case TEnum(e):
				return TypeEnum.Enum(e);
			case TInt:
				return TypeEnum.Int;
			case TFunction:
				return TypeEnum.Function(null, null); //weird as fuck
			case TNull:
				return TypeEnum.Null;
			case TFloat:
				return TypeEnum.Float;
			case TObject:
				trace("TObject");
				trace("whaat");
				return TypeEnum.Null;
			case TUnknown:
				trace("TUnknown");
				return TypeEnum.Null;
		}
	}

	public static function trace(obj:Dynamic) {
		var util = Node.require('util');
		trace(util.inspect(obj, { depth: 99 })); //problems but a bitch ain't one!
	}

	public static function max(a:Int, b:Int) {
		if (a > b) {
			return a;
		}
		return b;
	}

	public static function min(a:Int, b:Int) {
		if (a < b) {
			return a;
		}
		return b;
	}

	public static function after(count:Int , func:Void -> Void):Void -> Void {
		var done:Int = 0;
		return function () {
			done++;
			if (done == count) {
				func();
			}
		}
	}

	public static function pairFirsts<T, K>(a:Array<Pair<T, K>>):Array<T> {
		var res:Array<T> = new Array<T>();
		for (pair in a) {
			res.push(pair.first);
		}
		return res;
	}

	public static function pairSeconds<T, K>(a:Array<Pair<T, K>>):Array<K> {
		var res:Array<K> = new Array<K>();
		for (pair in a) {
			res.push(pair.second);
		}
		return res;
	}

	public static function keys<T>(m:Map<T, Dynamic>):Array<T> {
		var res:Array<T> = new Array<T>();
		for (x in m.keys()) {
			res.push(x);
		}
		return res;
	}

	public static function sleep(seconds:Float) {
		var tmp:Float = Date.now().getTime();
		while(Date.now().getTime() < tmp + seconds * 1000 ) {

		}
 	}

 	public static function now():Int {
 		return Math.floor(Date.now().getTime());
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