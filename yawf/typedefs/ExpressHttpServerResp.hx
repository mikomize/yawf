
package yawf.typedefs;

extern class ExpressHttpServerResp {
	function send(?status:Int, value : Dynamic) : Void;
	function json(?status:Int, value : Dynamic) : Void;
}