
package yawf.reflections;

import haxe.rtti.*;
import haxe.rtti.CType;
import js.Node;

class ClassInfo 
{
	public var c:Class<Dynamic>;

	private var fields:Map<String, ClassFieldInfo>;

	private var fieldsMetas:Map<String, Array<ClassFieldInfo>>;

	public var path:String = null;

	public var meta:Map<String, Array<String>>;

	public function new(c:Class<Dynamic>) {
		fields = new Map<String, ClassFieldInfo>();
		fieldsMetas = new Map<String, Array<ClassFieldInfo>>();
		meta = new Map<String, Array<String>>();
		this.c = c;
		processClass(c);	
	}

	public function getField(name:String):ClassFieldInfo {
		return fields.get(name);
	}

	public function getFieldsByMeta(name:String):Array<ClassFieldInfo> {
		var tmp:Array<ClassFieldInfo> = fieldsMetas.get(name);
		if (null == tmp) {
			tmp = new Array<ClassFieldInfo>();
		}
		return tmp;
	}

	private function processClass(c:Class<Dynamic>):Void {
		var rtti = untyped c.__rtti; 

		var x = Xml.parse(rtti).firstElement(); 
		var parsed:TypeTree = new haxe.rtti.XmlParser().processElement(x);
		var classDef:Classdef = parsed.getParameters()[0];


		for (m in classDef.meta) {
			var tmp:Array<String> = new Array<String>();
			for(param in m.params) {
				tmp.push(Node.parse(param));
			}
			meta.set(m.name, tmp);
		}

		for(field in classDef.fields) {
			var fieldInfo:ClassFieldInfo = new ClassFieldInfo(field);
			fields.set(fieldInfo.name, fieldInfo);
			for (metaName in fieldInfo.meta.keys()) {
				var tmp:Array<ClassFieldInfo> = fieldsMetas.get(metaName);
				if (null == tmp) {
					tmp = new Array<ClassFieldInfo>();
					fieldsMetas.set(metaName, tmp);
				}
				tmp.push(fieldInfo);
			}
		}

		if(path == null) {
			path = classDef.path;
		}

		var sc:Class<Dynamic> = Type.getSuperClass(c);
		if (sc != null) {
			processClass(sc);
		}
	}

}