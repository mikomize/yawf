
package yawf.typedefs;

typedef WinstonLogger = {
	function log(level:String, msg:String, ?meta:Dynamic):Void;
	function info(msg:String, ?meta:Dynamic):Void;
	function warn(msg:String, ?meta:Dynamic):Void;
	function error(msg:String, ?meta:Dynamic):Void;
	function verbose(msg:String, ?meta:Dynamic):Void;
}

typedef Winston = {
	var Logger:Class<WinstonLogger>;
	var transports:Dynamic;
}
