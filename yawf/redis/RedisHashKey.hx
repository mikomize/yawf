
package yawf.redis;

import minject.Injector;
import yawf.reflections.*;
import yawf.typedefs.Redis;

@:generic
class RedisHashKey<T> extends RedisKey implements IRedisCacheable
{
	@inject
	public var redis:RedisLayer;

	@inject
	public var injector:Injector;

	private var cache:Map<String, T>;

	private var checks:Map<String, String>;

	private var data:T;

	public function new(key:String) {
		cache = new Map<String, T>();
		checks = new Map<String, String>();
		super(key);
	}

	public function get(id:String, callback:T -> Void):Void {
		var data:T = cache.get(id);
		if (data == null) {
			redis.client.hget(key, id, function (err:Err, res:String) {
				if (res != null) {
					data = deserialize(res);
					cache.set(id, data);
					clean(id);
					callback(data);
				} else {
					callback(null);
				}

			});
		} else {
			callback(data);
		}
	}

	public function getKeys(callback:Array<String> -> Void) {
		redis.client.hkeys(key, function (err:Err, res:Array<String>) {
			callback(res);
		});
	}

	public function remove(id:String) {
		cache.set(id, null);
	}

	public function set(id:String, data:T) {
		cache.set(id, data);
	}

	public function store(callback:Err -> Dynamic -> Void) {
		var i:Int = 0;
		var e:Err = null;

		var toDo:Array<String> = new Array<String>();
		for (id in cache.keys()) {
			if (isFieldDirty(id)) {
				toDo.push(id);
			}
			
		}

		if (toDo.length == 0) {
			callback(e, null);
			return;
		} 

		var onComplete:Void -> Void = Util.after(toDo.length, function () {
			callback(e, null);
		});

		for (id in toDo) {
			var data:T = cache.get(id);
			redis.client.hset(key, id, serialize(data), function (err:Err, res:Int) {
				e = err;
				clean(id);
				onComplete();
			});
		}

	}

	public function isDirty():Bool {
		var dirty:Bool = false;
		for (id in cache.keys()) {
			dirty = dirty || isFieldDirty(id);
		}
		return dirty;
	}

	private function clean(id:String) {
		checks.set(id, serialize(cache.get(id)));
	}

	private function isFieldDirty(id:String):Bool {
		return checks.get(id) != serialize(cache.get(id));
	}

	private function serialize(item:T):String {
		return ObjectMapper.toJsonUntyped(item, classInfo.getField("data").type);
	}

	private function deserialize(json:String):T {
		return ObjectMapper.fromJsonUntyped(json, classInfo.getField("data").type);
	}
}