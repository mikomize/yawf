
package yawf;

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


	//wont work if field is null
	public static function recursiveReplaceAnnotatedFieldInObject(obj:Dynamic, toReplace:Dynamic, annotation:String, visited:Array<Dynamic> = null):Void {
		if (visited == null) {
			visited = new Array<Dynamic>();
		}
		var c:Class<Dynamic> = Type.getClass(obj);
		if (c == null) {//XXX dont ask
			return;
		}
		var m = haxe.rtti.Meta.getFields(c);
		for (field in Reflect.fields(obj)) {
			var hasAnnotation:Bool = Reflect.field(m, field) != null && Reflect.hasField(Reflect.field(m, field), annotation);
			var tmp:Dynamic = Reflect.field(obj, field);
			if (tmp == null) {
				continue;
			}
			if (hasAnnotation && Std.is(tmp, Type.getClass(toReplace))) {
				Reflect.setField(obj, field, toReplace);
			} else if (Reflect.isObject(tmp)) {
				visited.push(obj);
				if (hasAnnotation && visited.indexOf(tmp) == -1) {
					recursiveReplaceAnnotatedFieldInObject(tmp, toReplace, annotation, visited);
				}
			}
		}

	}

	public static function trace(obj:Dynamic) {
		trace(obj);
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
		if (count == 0) {
			func();
			return null;
		}
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

}	
