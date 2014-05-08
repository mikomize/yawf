
package yawf.redis;

import yawf.typedefs.Redis;

interface IRedisCacheable
{
	public function getKey():String;
	public function store(callback:Err -> Dynamic -> Void):Void;
	public function isDirty():Bool;
}