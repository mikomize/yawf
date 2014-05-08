
package yawf;

import js.Node;
import yawf.typedefs.Express;
import yawf.typedefs.ExpressHttpServerReq;
import yawf.typedefs.ExpressHttpServerResp;
import yawf.typedefs.Nconf;
import yawf.reflections.*;
import minject.Injector;


class WebApp extends App
{
	public function register(controllerClass:Class<Controller>):Void {

		var classInfo:ClassInfo = Reflection.getClassInfo(controllerClass);

		var paths:Map<String, String> = new Map<String, String>();
		var prefixFunc:ClassFieldInfo = classInfo.getFieldsByMeta("prefix").shift();
		var beforeFunc:ClassFieldInfo = classInfo.getFieldsByMeta("before").shift();
		var afterFunc:ClassFieldInfo = classInfo.getFieldsByMeta("after").shift();

		var paths:Array<ClassFieldInfo> = classInfo.getFieldsByMeta("path");


		logger.verbose("registering paths:");
		for (pathFunc in paths) {
			var method:Method = Method.GET;
			if (null != pathFunc.getMeta("method")) {
				var m:String = pathFunc.getMeta("method")[0];
				method = Type.createEnum(Method, m);
			}
			var path:String = "";
			if (null != prefixFunc) {
				path += prefixFunc.getMeta("prefix")[0];
			}
			path += pathFunc.getMeta("path")[0];
			logger.verbose(Std.string(method) + " " + path);

			Reflect.callMethod(express, Reflect.field(express, Std.string(method).toLowerCase()), [path, function (req:ExpressHttpServerReq, res:ExpressHttpServerResp) {
				var requestData:RequestData = createRequestData(req, res);
				var injector:Injector = createInjector(requestData);
				var controller:Controller = injector.instantiate(controllerClass);

				if (beforeFunc != null) {
					Reflect.callMethod(controller, Reflect.field(controller, beforeFunc.name), [pathFunc.name]);
				}
				if (prefixFunc != null) {
					call(controller, prefixFunc, requestData);
				}
				call(controller, pathFunc, requestData);
				if (afterFunc != null) {
					Reflect.callMethod(controller, Reflect.field(controller, afterFunc.name), [pathFunc.name]);
				}
			}]);

		}

	}



}