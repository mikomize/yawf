
package yawf.redis;

import minject.Injector;
import yawf.reflections.*;

import yawf.node.Util;

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
		trace("called redis hash key constr: " + key);
		cache = new Map<String, T>();
		checks = new Map<String, String>();
		super(key);
	}

	public function get(id:String, callback:T -> Void):Void {
		var data:T = cache.get(id);
		if (data == null) {
			redis.client.hget(key, id, function (err:Dynamic, res:String) {
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
		redis.client.hkeys(key, function (err:Dynamic, res:Array<String>) {
			callback(res);
		});
	}

	public function remove(id:String) {
		cache.set(id, null);
	}

	public function set(id:String, data:T) {
		cache.set(id, data);
	}

	public function store(callback:Dynamic -> Dynamic -> Void) {
		var i:Int = 0;
		var e:Dynamic = null;

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

		var onComplete:Void -> Void = yawf.Util.after(toDo.length, function () {
			callback(e, null);
		});

		for (id in toDo) {
			var data:T = cache.get(id);
			redis.client.hset(key, id, serialize(data), function (err:Dynamic, res:Int) {
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
		return ObjectMapper.toJson(item);
	}

	private function deserialize(json:String):T {
		return ObjectMapper.fromJsonUntyped(json, classInfo.getField("data").type);
	}
}