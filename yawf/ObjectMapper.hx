
package yawf;

import js.Node;
import yawf.reflections.*;

class ObjectMapper 
{

	@:generic public static function fromJson<T>(json:String, c:Class<T>):T {
		var data:Dynamic = Node.parse(json);
		return fromPlainObject(data, c);
	}

	public static function fromJsonUntyped(json:String, t:TypeEnum, notNull:Bool = false):Dynamic {
		var data:Dynamic = Node.parse(json);
		return fromPlainObjectUntyped(data, t, notNull);
	}

	public static function fromPlainObjectUntyped(data:Dynamic, t:TypeEnum, notNull:Bool = false):Dynamic {
		if (data == null && notNull == false) {
			return null;
		}
		switch (t) {
			case Int:
				return Std.parseInt(data);
			case Float:
				return Std.parseFloat(data);
			case String:
				return Std.string(data);
			case Bool:
				return !!data;
			case Null:
				return null;
			case Function(args, ret):
				throw "dunno how to map function, call some wizard or shit";
			case Enum(e):
				return Type.createEnum(e, Std.string(data));
			case Map(t):
				var res:Map<String, Dynamic> = new Map<String, Dynamic>();
				for(field in Reflect.fields(data)) {
					res.set(field, fromPlainObjectUntyped(Reflect.field(data, field), t));
				}
				return res;
			case Array(t):
				var res:Array<Dynamic> = new Array<Dynamic>();
				if (data == null) {
					return res;
				}
				for (field in cast(data, Array<Dynamic>)) {
					res.push(fromPlainObjectUntyped(field, t));
				}
				return res;
			case Class(c): 
				var obj:Dynamic = Type.createInstance(c, []);
				var classInfo:ClassInfo = Reflection.getClassInfo(c);
				var fields:Array<ClassFieldInfo> = classInfo.getFieldsByMeta("param");
				for (field in fields) {

					var fieldName:String = field.name;
					if (field.getMeta("param").length > 0) {
						fieldName = field.getMeta("param")[0];
					}
					var fieldData:Dynamic = Reflect.field(data, fieldName);
					var notNull:Bool = field.getMeta("notNull") != null;
					Reflect.setField(obj, field.name, fromPlainObjectUntyped(fieldData, field.type, notNull));
				}
				return obj;

		}
	}


	@:generic public static function fromPlainObject<T>(data:Dynamic, c:Class<T>):T {
		return fromPlainObjectUntyped(data, TypeEnum.Class(c));
	}

	public static function toPlainObjectUntyped(obj:Dynamic, t:TypeEnum):Dynamic {
		if (obj == null) {
			return null;
		}
		switch (t) {
			case Int:
				return obj;
			case Float:
				return obj;
			case String:
				return obj;
			case Bool:
				return obj;
			case Null:
			 return obj;
			case Enum(e):
				return Std.string(e);
			case Map(t):
				var res:Dynamic = {};
				var todo:Map<String, Dynamic> = obj;
				for(field in todo.keys()) {
					Reflect.setField(res, field, toPlainObjectUntyped(todo.get(field), t));
				}
				return res;
			case Array(t):
				var res:Array<Dynamic> = new Array<Dynamic>();
				for (field in cast(obj, Array<Dynamic>)) {
					res.push(toPlainObjectUntyped(field, t));
				}
				return res;
			case Class(c): 
				var res:Dynamic = {};
				var classInfo:ClassInfo = Reflection.getClassInfo(c);
				var fields:Array<ClassFieldInfo> = classInfo.getFieldsByMeta("param");
				for (field in fields) {
					var fieldName:String = field.name;
					if (field.getMeta("param").length > 0) {
						fieldName = field.getMeta("param")[0];
					}
					var fieldData:Dynamic = Reflect.field(obj, field.name);
					Reflect.setField(res, fieldName, toPlainObjectUntyped(fieldData, field.type));
				}
				//maybe some "additional data" annotation flag?
				//prefix annotatnion data to change "_"?
				for (meta in classInfo.meta.keys()) {
					Reflect.setField(res, "_" + meta, classInfo.meta.get(meta)[0]);
				}
				return res;
			case Function(args, ret):
				throw "dunno how to map function, call some wizard or shit";
		}
	}

	public static function toPlainObject(obj:Dynamic):Dynamic {
		var c:Class<Dynamic> = Type.getClass(obj);
		return toPlainObjectUntyped(obj, TypeEnum.Class(c));
	}

	public static function toJson(obj:Dynamic):String {
		return Node.stringify(toPlainObject(obj));
	}

	public static function toJsonUntyped(obj:Dynamic, t:TypeEnum):String {
		return Node.stringify(toPlainObjectUntyped(obj, t));
	}

}