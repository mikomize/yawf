package yawf.redis;

class RedisInt extends RedisKey {

	@inject
	public var redis:RedisLayer;

	public function incr(amount:Int, cb:Int -> Void) {
		redis.client.incrby(key, amount, function(err:Dynamic, current:Int) {
			cb(current);
		});
	}

	public function decr(amount:Int, cb:Int -> Void) {
		redis.client.decrby(key, amount, function(err:Dynamic, current:Int) {
			cb(current);
		});
	}

	public function init(defaultValue:Int, cb:Bool -> Void) {
		redis.client.setnx(key, Std.string(defaultValue), function(err:Dynamic, res:Bool) {
			cb(res);
		});
	}

	public function get(cb:Int -> Void) {
		redis.client.get(key, function (err:Dynamic, res:String) {
			cb(Std.parseInt(res));
		});
	}
	
}