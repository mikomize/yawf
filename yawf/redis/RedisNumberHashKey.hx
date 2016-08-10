package yawf.redis;

class RedisNumberHashKey extends RedisKey {

	@inject
	public var redis:RedisLayer;


	public function incr(field:String, amount:Int, cb:Int->Void) {
		redis.client.hincrby(key, field, amount, function (err, current:Int) {
			cb(current);
		});
	}

	public function get(field:String, cb:Int->Void) {
		redis.client.hget(key, field, function (err, current:Int) {
			if (current == null) {
				current = 0;
			}
			cb(current);
		});
	}

	public function getAll(cb:Map<String, Int>->Void) {
		redis.client.hgetall(key, function (err:Dynamic, all:Dynamic) {
			var res:Map<String, Int> = new Map<String, Int>();
			for (field in Reflect.fields(all)) {
					res.set(field, Reflect.field(all, field));
			}
			cb(res);
		});
	}
}