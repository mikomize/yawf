
package yawf.redis;

import yawf.reflections.*;

@:rtti
class RedisKey 
{
	private var key:String;

	private var classInfo:ClassInfo;

	public function new(key:String) {
		classInfo = Reflection.getClassInfo(Type.getClass(this));
		this.key = key;
	}

	public function getKey():String {
		return key;
	}
}