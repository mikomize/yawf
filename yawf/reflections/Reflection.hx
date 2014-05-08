
package yawf.reflections;

import haxe.rtti.*;
import haxe.rtti.CType;

class Reflection 
{
	public static function getClassInfo(c:Class<Dynamic>):ClassInfo {
		return new ClassInfo(c);

	}

	public static function getType(type:CType):TypeEnum {
		if(type == null) {
			return TypeEnum.Null;
		}
		switch(type) {
			case CDynamic(t):
				return getType(t);
			case CFunction(funcArgs, ret):
	    		var argsList:List<FuncArg> = new List<FuncArg>();
				for (arg in funcArgs) {
					argsList.push({type: getType(arg.t), name: arg.name, opt:arg.opt});
				}
				return TypeEnum.Function(argsList, getType(ret));
			case CEnum(path, params): 
				return TypeEnum.Enum(Type.resolveEnum(path));
			case CClass(path, params):
				if (path == "Array") {
					if (params.length > 0) {
						var en:TypeEnum = getType(params.first());
						return TypeEnum.Array(en);
					} else {
						trace("no params?");
						return TypeEnum.Array(null);
					}
				}
				if (path == "String") {
					return TypeEnum.String;
				}
				return TypeEnum.Class(cast Type.resolveClass(path));
    		case CAbstract(path, params):
	    		if (path == "Map") {
	    			if (params.length > 1) {
						var en:TypeEnum = getType(params.last());
						return TypeEnum.Map(en);
					} else {
						trace("no params?");
						return TypeEnum.Map(null);
					}
	    			
	    		} else if (path == "Int") {
	    			return TypeEnum.Int;
	    		} else if (path == "Float") {
	    			return TypeEnum.Float;
	    		} else if (path =="Bool") {
	    			return TypeEnum.Bool;
	    		} else if (path == "Void") {
	    			return TypeEnum.Null;
	    		}else {
	    			trace(path);
	    			return TypeEnum.Null;
	    		}
			default:
				return TypeEnum.Null;
		}
	}


}