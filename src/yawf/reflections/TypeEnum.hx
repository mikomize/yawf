
package yawf.reflections;

enum TypeEnum {
	Bool;
	Int;
	String;
	Float;
	Enum(e:Enum<Dynamic>);
	Array(t:TypeEnum);
	Map(t:TypeEnum);
	Class(c:Class<Dynamic>);
	Function(args:List<FuncArg>, ret:TypeEnum);
	Null;
}