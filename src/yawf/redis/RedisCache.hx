 
package yawf.redis;

import yawf.node.Util;
import minject.Injector;

class RedisCache 
{
	@inject
	public var injector:Injector;

	public var client:RedisClient;

	private var cache:Map<String, IRedisCacheable>;

	public function new(r:RedisClient) {
		cache = new Map<String, IRedisCacheable>();
		client = r;
	}

	@:generic private function doWork<T:IRedisCacheable>(obj:T):T {
		injector.injectInto(obj);
		var key:String = obj.getKey();
		if (cache.exists(key)) {
			var tmp:T = cast cache.get(key);
			return tmp;
		}
		cache.set(key, obj);
		return obj;
	}

	@:generic public function get<T:IRedisCacheable>(redisCacheableClass:Class<T>, args:Array<Dynamic> = null):T {
		if (args == null) {
			args = [];
		}
		var cacheable:T = Type.createInstance(redisCacheableClass, args);
		return doWork(cacheable);
	}

	@:generic public function use<T:IRedisCacheable>(redisCacheable:T):T {
		return doWork(redisCacheable);
	}

	public function storeAllDirty(cb:Void -> Void) {
		var toDo:Array<IRedisCacheable> = new Array<IRedisCacheable>();
		for (storable in cache) {
			if (storable.isDirty()) {
				toDo.push(storable);
			}
		}

		if (toDo.length == 0) {
			cb();
		}

		var onComplete:Void -> Void = yawf.Util.after(toDo.length, cb);

		for (storable in toDo) {
			trace("storing: " + storable.getKey());
			storable.store(function (Dynamic, Dynamic) {
				trace("stored dirty key: " + storable.getKey() );
				onComplete();
			});
		}

	}

}