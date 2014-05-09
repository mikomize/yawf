
package yawf.typedefs;

import js.Node;

extern class Express
{
	public function get(path:String, fn:ExpressHttpServerReq ->  ExpressHttpServerResp -> Void):Void;
	public function post(path:String, fn:ExpressHttpServerReq ->  ExpressHttpServerResp -> Void):Void;
	public function use(?path:String, fn:Dynamic -> ExpressHttpServerReq ->  ExpressHttpServerResp -> (Dynamic -> Void) -> Void):Void;
	public function listen(port:Int, ?host:String):Void;
}