
package yawf.redis;

import minject.Injector;
import yawf.typedefs.Redis;

class RedisLayer
{
	@inject
	public var injector:Injector;

	public var cache:RedisCache;

	public var client:RedisClient;

	public function new (r:RedisClient) {
		client = r;
	}

	@:generic public function create<T:RedisKey>(c:Class<T>, args:Array<Dynamic> = null):T {
		if (args == null) {
			args = [];
		}
		var obj:T = Type.createInstance(c, args);
		injector.injectInto(obj);
		return obj;
	}

	@post
	public function init() {
		cache = new RedisCache(client);
		injector.injectInto(cache);
	}

}