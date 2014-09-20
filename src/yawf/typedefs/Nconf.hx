package yawf.typedefs;

extern class Nconf {
	function argv(?opt:Dynamic):Nconf;
	function env(?opt:Dynamic):Nconf;
	function file(?opt:Dynamic):Nconf;
	function defaults(?opt:Dynamic):Nconf;
	function overrides(?opt:Dynamic):Nconf;

	function set(name:String, val:Dynamic):Void;
	function get(name:String):Dynamic;

	function add(name:String, ?opt:Dynamic):Void;
	function use(name:String, ?opt:Dynamic):Void;
	function remove(name:String):Void;
}