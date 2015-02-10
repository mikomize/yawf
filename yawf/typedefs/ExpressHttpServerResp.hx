
package yawf.typedefs;

extern class ExpressHttpServerResp {
	function send(?status:Int, value : Dynamic) : Void;
	function json(?status:Int, value : Dynamic) : Void;
	function redirect(?status:Int, value : Dynamic) : Void;
	function set(k:Dynamic, v:Dynamic):Void;
}