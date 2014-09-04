
package yawf.typedefs; ;

extern class MomentDate {
	function new(timestamp:Int);
	function unix():Int;
	function tz(timezone:String):MomentDate;
	function startOf(startOf:String):MomentDate;
	function add(amount:Int, what:String):MomentDate;
	function substract(amount:Int, what:String):MomentDate;
	function format(f:String):String;
}