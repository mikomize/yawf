
package yawf.redis;

import yawf.ObjectMapper;

@:generic
class RankingKey<T> extends RedisKey {

	@inject
	public var redis:RedisLayer;

	private var data:T;

	public function new(key:String) {
		super(key);
	}

	public function add(score:Int, member:T, callback:Dynamic -> Int -> Void):Void {
		redis.client.zadd(key, score, serialize(member), callback);
	}

	public function incrementScore(amount:Int, member:T, callback:Dynamic -> Int -> Void):Void {
		redis.client.zincrby(key, amount, serialize(member), callback);
	}

	public function remove(member:T, callback:Dynamic -> Int -> Void) {
		redis.client.zrem(key, serialize(member), callback);
	}

	public function rangeByScore(min:Int, max:Int, offset:Int, count:Int, callback:Array<Pair<T, Int>> -> Void) {
		redis.client.zrangebyscore(key, Std.string(min), Std.string(max), "WITHSCORES", "LIMIT", offset, count, function (err:Dynamic, res:Array<Dynamic>) {
			callback(format(res));
		});
	}

	public function getAll(callback:Array<Pair<T, Int>> -> Void) {
		redis.client.zrangebyscore(key, '-inf', '+inf', "WITHSCORES", "LIMIT", 0, -1, function (err:Dynamic, res:Array<Dynamic>) {
			callback(format(res));
		});
	}

	private function format(res:Array<Dynamic>):Array<Pair<T, Int>> {
		var tmp:Array<Pair<T, Int>> = new Array<Pair<T, Int>>();
		while (res.length != 0) {
			var pair:Pair<T, Int> = new Pair<T, Int>(deserialize(cast(res.shift(), String)), Std.parseInt(res.shift()));
			tmp.push(pair);
		}
		return tmp;
	}

	private function serialize(item:T):String {
		return ObjectMapper.toJson(item);
	}

	private function deserialize(json:String):T {
		return ObjectMapper.fromJsonUntyped(json, classInfo.getField("data").type);
	}

}