
package yawf.reflections;

import haxe.rtti.*;
import haxe.rtti.CType;
import haxe.Json;

class ClassFieldInfo 
{
	public var type:TypeEnum;

	public var name:String;

	public var meta:Map<String, Array<String>>;

	public function new (classField:ClassField) {
		meta = new Map<String, Array<String>>();
		name = classField.name;
		type = Reflection.getType(classField.type);
		for (m in classField.meta) {
			var tmp:Array<String> = new Array<String>();
			for(param in m.params) {
				tmp.push(Json.parse(param));
			}
			meta.set(m.name, tmp);
		}
	}

	public function getMeta(name:String):Array<String> {
		return meta.get(name);
	}

}
