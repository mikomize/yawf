
package yawf.redis;

import yawf.ObjectMapper;

@:generic
class RedisSet<T> extends RedisKey {

	@inject
	public var redis:RedisLayer;

	private var data:T;

	public function new(key:String) {
		super(key);
	}

	public function add(members:Array<T>, callback:Dynamic->Int->Void):Void {
		redis.client.sadd(key, untyped serializeArray(members), callback);
	}

	public function rem(members:Array<T>, callback:Dynamic->Int->Void):Void {
		redis.client.srem(key, untyped serializeArray(members), callback);
	}

	public function contains(member:T, callback:Dynamic->Int->Void):Void {
		redis.client.sismember(key, untyped serialize(member), callback);
	}

	public function clear(callback:Dynamic->Int->Void):Void {
		members(function (err, members) {
			if (err == null) {
				rem(members, callback);
			}
		});
	}

	public function members(callback:Dynamic->Array<T>->Void):Void {
		redis.client.smembers(key, function(error:Dynamic, arrayOfStrings:Dynamic):Void {
			callback(error, deserializeArray(arrayOfStrings));
		});
	}

	public function getRandom(count:Int ,callback:Dynamic->Array<T>->Void):Void {
		redis.client.srandmember(key, count, function(error:Dynamic, arrayOfStrings:Dynamic):Void {
			callback(error, deserializeArray(arrayOfStrings));
		});
	}

	public function getCardinality(callback:Dynamic->Int->Void) {
		redis.client.scard(key, callback);
	}


	private function serializeArray(items:Array<T>):Array<String> {
		return Lambda.array(Lambda.map(items, function(t:T):String {
			return serialize(t);
		}));
	}

	private function deserializeArray(items:Array<String>):Array<T> {
		return Lambda.array(Lambda.map(items, function(s:String):T {
			return deserialize(s);
		}));
	}

	private function serialize(item:T):String {
		return ObjectMapper.toJson(item);
	}

	private function deserialize(json:String):T {
		return ObjectMapper.fromJsonUntyped(json, classInfo.getField("data").type);
	}

}
