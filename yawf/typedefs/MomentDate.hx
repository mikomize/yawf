
package yawf.typedefs;

extern class MomentDate {
	function new(timestamp:Int);
	function unix():Int;
	function set(what:String, amount:Int):MomentDate;
	function get(what:String):Int;
	function tz(timezone:String):MomentDate;

	// it returns changed MomentDate, but calling instance gets changed too!
	function startOf(startOf:String):Void;
	function endOf(startOf:String):Void;

	function subtract(amount:Int, what:String):MomentDate;

	function add(amount:Int, what:String):MomentDate;
	function min(otherMoment:String):MomentDate;
	function max(otherMoment:String):MomentDate;
	function format(f:String):String;

	@:overload(function(otherMoment:MomentDate, units:String, float:Bool):Float{})
	@:overload(function(otherMoment:MomentDate, units:String):Int{})
	function diff(otherMoment:MomentDate):Int;

	@:overload(function(day:Int):MomentDate{})
	function isoWeekday():Int;

	function weekday():Int;

}

