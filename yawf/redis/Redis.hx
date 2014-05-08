
package yawf.redis;

import js.Node;

class Redis {
  
 public static function newClient(port:Int = 6379, host:String = "127.0.0.1", options:Dynamic = null):RedisClient 
 {
 	 var c:Dynamic = Node.require('redis');
 	 if (options == null) {
 	 	options = {};
 	 }
    return c.createClient(port, host, options);
  }

}