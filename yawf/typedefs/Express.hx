
package yawf.typedefs;

import js.Node;

extern class Express
{
	public function enable(what:String):Void;
	public function get(path:String, fn:ExpressHttpServerReq ->  ExpressHttpServerResp -> Void):Void;
	public function post(path:String, fn:ExpressHttpServerReq ->  ExpressHttpServerResp -> Void):Void;
	@:overload(function(d:Dynamic):Void{})
	public function use(path:String, fn:ExpressHttpServerReq ->  ExpressHttpServerResp -> (Void -> Void) -> Void):Void;
	@:overload(function(path:String, ?callback:Void->Void):Void{})
	public function listen(port:Int, ?host:String, ?callback:Void->Void):Void;
}