
package yawf.redis;

interface IRedisCacheable
{
	public function getKey():String;
	public function store(callback:Dynamic -> Dynamic -> Void):Void;
	public function isDirty():Bool;
}