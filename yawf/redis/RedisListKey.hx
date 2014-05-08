
package yawf.redis;

import minject.Injector;
import yawf.ObjectMapper;
import yawf.typedefs.Redis;

@:generic
class RedisListKey<T> extends RedisKey
{
	@inject
	public var redis:RedisLayer;

	@inject
	public var injector:Injector;

	private var data:T;

	public function new(key:String) {
		super(key);
	}

	public function lpush(elem:T, callback:Void -> Void) {
		lpushMulti([elem], callback);
	}

	public function lpushMulti(elems:Array<T>, callback:Void -> Void) {
		elems.reverse();
		var z:List<Dynamic> = makeArray(elems);
		z.push(key);
		z.add(callback);
		Reflect.callMethod(redis.client, redis.client.lpush, Lambda.array(z));
	}

	public function rpush(elem:T, callback:Void -> Void) {
		rpushMulti([elem], callback);
	}

	public function rpushMulti(elems:Array<T>, callback:Void -> Void) {
		var z:List<Dynamic> = makeArray(elems);
		z.push(key);
		z.add(callback);
		Reflect.callMethod(redis.client, redis.client.rpush, Lambda.array(z));
	}

	public function lpop(callback:T -> Void) {
		redis.client.lpop(key, function (err:Err, res:String) {
			if (res == null) {
				callback(null);
			} else {
				callback(deserialize(res));
			}
		});
	}

	public function rpop(callback:T -> Void) {
		redis.client.rpop(key, function (err:Err, res:String) {
			if (res == null) {
				callback(null);
			} else {
				callback(deserialize(res));
			}
		});
	}

	public function range(start:Int, end:Int, callback:Array<T> -> Void) {
		redis.client.lrange(key, start, end, function (err:Err, res:Array<Dynamic>) {
			var z:Array<T> = new Array<T>();
			for(item in res) {
				z.push(deserialize(Std.string(item)));
			}
			callback(z);
		});
	}

	public function all(callback:Array<T> -> Void) {
		range(0, -1, callback);
	}

	public function length(callback:Int -> Void) {
		redis.client.llen(key, function (err:Err, res:Int) {
			callback(res);
		});
	}

	private function serialize(item:T):String {
		return ObjectMapper.toJsonUntyped(item, classInfo.getField("data").type);
	}

	private function deserialize(json:String):T {
		return ObjectMapper.fromJsonUntyped(json, classInfo.getField("data").type);
	}

	private function makeArray(items:Array<T>):List<String> {
		var z:List<String> = new List<String>();
		Lambda.foreach(items, function(item:T):Bool {
			z.add(serialize(item));
			return true;
		});
		return z;
	}

}