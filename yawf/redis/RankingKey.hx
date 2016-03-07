
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

/* Floating point stuff */
	public function addf(score:Float, member:T, callback:Dynamic -> Float-> Void) {
		redis.client.zadd(key, score, serialize(member), callback);
	}

	public function incrementScoref(score:Float, member:T, callback:Dynamic -> Float-> Void) {
		redis.client.zincrby(key, score, serialize(member), callback);
	}

	public function removef(member:T, callback:Dynamic -> Float-> Void) {
		redis.client.zrem(key, serialize(member), callback);
	}

	public function scoref(member:T, callback:Dynamic->Float->Void):Void {
		redis.client.zscore(key, serialize(member), callback);
	}

	public function rangeByScoref(min:Float, max:Float, offset:Int, count:Int, callback:Array<Pair<T, Float>> -> Void) {
		redis.client.zrangebyscore(key, Std.string(min), Std.string(max), "WITHSCORES", "LIMIT", offset, count, function (err:Dynamic, res:Array<Dynamic>) {
			callback(formatf(res));
		});
	}

	private function formatf(res:Array<Dynamic>):Array<Pair<T, Float>> {
		var tmp:Array<Pair<T, Float>> = new Array<Pair<T, Float>>();
		while (res.length != 0) {
			var pair:Pair<T, Float> = new Pair<T, Float>(deserialize(cast(res.shift(), String)), Std.parseFloat(res.shift()));
			tmp.push(pair);
		}
		return tmp;
	}

/* Integer stuff */
	public function rank(member:T, callback:Dynamic -> Int -> Void) {
		redis.client.zrank(key, serialize(member), callback);
	}

	public function revRank(member:T, callback:Dynamic -> Int -> Void) {
		redis.client.zrevrank(key, serialize(member), callback);
	}

	public function add(score:Int, member:T, callback:Dynamic -> Int -> Void) {
		redis.client.zadd(key, score, serialize(member), callback);
	}

	public function incrementScore(amount:Int, member:T, callback:Dynamic -> Int -> Void):Void {
		redis.client.zincrby(key, amount, serialize(member), callback);
	}

	public function remove(member:T, callback:Dynamic -> Int -> Void) {
		redis.client.zrem(key, serialize(member), callback);
	}

	public function score(member:T, callback:Dynamic->Int->Void):Void {
		redis.client.zscore(key, serialize(member), callback);
	}

	public function scoreOpt(member:T, callback:Dynamic->Dynamic->Void):Void {
		redis.client.zscore(key, serialize(member), callback);
	}

	public function rangeByScore(min:Int, max:Int, offset:Int, count:Int, callback:Array<Pair<T, Int>> -> Void) {
		redis.client.zrangebyscore(key, Std.string(min), Std.string(max), "WITHSCORES", "LIMIT", offset, count, function (err:Dynamic, res:Array<Dynamic>) {
			callback(format(res));
		});
	}

	public function revRangeByScore(max:Int, min:Int, offset:Int, count:Int, callback:Array<Pair<T, Int>> -> Void) {
		redis.client.zrevrangebyscore(key, Std.string(max), Std.string(min), "WITHSCORES", "LIMIT", offset, count, function (err:Dynamic, res:Array<Dynamic>) {
			callback(format(res));
		});
	}

	public function getAll(callback:Array<Pair<T, Int>> -> Void) {
		redis.client.zrangebyscore(key, '-inf', '+inf', "WITHSCORES", "LIMIT", 0, -1, function (err:Dynamic, res:Array<Dynamic>) {
			callback(format(res));
		});
	}

	public function revRange(start:Int, end:Int, callback:Array<Pair<T, Int>> -> Void) {
		redis.client.zrevrange(key, start, end, "WITHSCORES", function (err:Dynamic, res:Array<Dynamic>) {
			callback(format(res));
		});
	}

	public function getAllReversed(callback:Array<Pair<T, Int>> -> Void) {
		redis.client.zrevrangebyscore(key, '+inf', '-inf', "WITHSCORES", "LIMIT", 0, -1, function (err:Dynamic, res:Array<Dynamic>) {
			callback(format(res));
		});
	}

	public function getCardinality(callback:Dynamic->Int->Void) {
		redis.client.zcard(key, callback);
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
