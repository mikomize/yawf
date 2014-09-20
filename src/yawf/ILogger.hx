
package yawf;

interface ILogger {
	public function log(level:String, msg:String, ?meta:Dynamic):Void;
	public function info(msg:String, ?meta:Dynamic):Void;
	public function warn(msg:String, ?meta:Dynamic):Void;
	public function error(msg:String, ?meta:Dynamic):Void;
	public function verbose(msg:String, ?meta:Dynamic):Void;
}