
package yawf.redis;

import js.Node;
import yawf.reflections.*;

@:generic
class RedisSimpleKey<T>  extends RedisKey implements IRedisCacheable
{

	@inject
	public var redis:RedisLayer;

	private var data:T = null;

	private var check:String = null;

	public function new(key:String) {
		super(key);
	}

	public function get(callback:T -> Void) {
		if (data == null) {
			redis.client.get(key, function (err:Dynamic, res:String) {
				data = ObjectMapper.fromJsonUntyped(res, classInfo.getField("data").type);
				clean();
				callback(data);
			});
		} else {
			callback(data);
		}
		
	}

	public function set(data:T) {
		this.data = data;
	}

	public function store(callback:Dynamic -> Dynamic -> Void):Void {
		var serialized:String = serialize();
		redis.client.set(key, serialized, function (err:Dynamic, res:Bool) {
			trace("stroing simple key");
			trace(key);
			trace(serialized);
			trace(err);
			trace(res);
			clean();
			callback(err, res);
		});
	}

	private function clean() {
		check = serialize();
	}

	public function isDirty():Bool {
		return check != serialize();
	}

	private function serialize():String {
		return ObjectMapper.toJson(data, classInfo.getField("data").type);
	}

}