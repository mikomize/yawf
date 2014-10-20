
package yawf.redis;

import yawf.*;
import yawf.reflections.*;

@:rtti
class PackedDataObject 
{
	@param
	public var data:String;

	@param
	public var className:String;

	public function new(className:String, data:String) {
		this.data = data;
		this.className = className;
	}

}

class RedisObjectListKey<T>  extends RedisListKey<PackedDataObject> {

	public function new(key:String) {
		super(key);
	}

	public function pushFront(obj:T, callback:Void -> Void) {
		lpush(pack(obj), callback);
	}

	public function pushBack(obj:T, callback:Void -> Void) {
		rpush(pack(obj), callback);
	}

	public function popFront(callback:T -> Void) {
		lpop(function (packed:PackedDataObject) {
			if (packed == null) {
				callback(null);
			} else {
				callback(unpack(packed));
			}
		});
	}

	public function popBack(callback:T -> Void) {
		rpop(function (packed:PackedDataObject) {
			if (packed == null) {
				callback(null);
			} else {
				callback(unpack(packed));
			}
		});
	}

	public function getAll(callback:Array<T> -> Void) {
		super.all(function (packedAll:Array<PackedDataObject>) {
			var res:Array<T> = new Array<T>();
			for (packed in packedAll) {
				res.push(unpack(packed));
			}
			callback(res);
		});
	}

	private function unpack(packed:PackedDataObject):T {
		var packedClass:Class<Dynamic> = Type.resolveClass(packed.className);
		return ObjectMapper.fromJsonUntyped(packed.data, TypeEnum.Class(packedClass));
	}

	private function pack(obj:T):PackedDataObject {
		var className:String = Type.getClassName(Type.getClass(obj));
		var packed:PackedDataObject = new PackedDataObject(className, ObjectMapper.toJson(obj));
  		return packed;
	}
	

}