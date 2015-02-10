
package yawf.typedefs;

extern class ExpressHttpServerReq {
	public var params:Dynamic;
	public var body:Dynamic;
	public var query:Dynamic;
	public var ip:String;
	public var secure:Bool;
	public var protocol:String;
	public var hostname:String;
	public function param(name:String):String;
	public function header(name:String):String;
}