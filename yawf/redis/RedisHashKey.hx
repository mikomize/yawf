
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

	private var toRemove:Array<String>;

	private var checks:Map<String, String>;

	private var data:T;

	public function new(key:String) {
		cache = new Map<String, T>();
		checks = new Map<String, String>();
		toRemove = new Array<String>();
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


	public function getAll(callback:Map<String, T>->Void) {
		redis.client.hgetall(key, function (err:Dynamic, res:Dynamic) {
			for (field in Reflect.fields(res)) {
				if (cache.get(field) == null) {
					cache.set(field, deserialize(Reflect.field(res, field)));
					clean(field);
				}
			}
			callback(cache);
		});
	}

	public function getKeys(callback:Array<String> -> Void) {
		redis.client.hkeys(key, function (err:Dynamic, res:Array<String>) {
			callback(res);
		});
	}

	public function remove(id:String) {
		cache.remove(id);
		toRemove.push(id);
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

		trace("store");
		trace(toRemove.length);
		var onComplete:Void -> Void = yawf.Util.after(toDo.length + toRemove.length, function () {
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

		for (id in toRemove) {
			trace("removing: " + id);
			redis.client.hdel(key, id, function (err:Dynamic, res:Int) {
				e = err;
				checks.remove(id);
				onComplete();
			});
		}

	}

	public function isDirty():Bool {
		if (toRemove.length > 0) {
			return true;
		}
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