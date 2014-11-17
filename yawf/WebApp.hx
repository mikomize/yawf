
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
	override public function start() {
		var bodyParser = Node.require('body-parser');
		express.use(bodyParser.urlencoded());
		express.use(function (err, req, res, next) {
			if (err == null) {
				next(null);
			} else {
				res.send(500, "Unhandled internal server error");
				throw err;
			}
		});
		super.start();
	}


	public function register(controllerClass:Class<Controller>):Void {

		var classInfo:ClassInfo = Reflection.getClassInfo(controllerClass);

		var paths:Map<String, String> = new Map<String, String>();
		var prefixFunc:ClassFieldInfo = classInfo.getFieldsByMeta("prefix").shift();
		var beforeFunc:ClassFieldInfo = classInfo.getFieldsByMeta("before").shift();

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

				var toRun:Void -> Void = function () {
					var beforeCb:Void -> Void = function () {
						var prefixCb:Void -> Void = function () {
							Reflect.callMethod(controller, Reflect.field(controller, pathFunc.name), getArgs(pathFunc, requestData, null));
						}

						if (prefixFunc != null) {
							Reflect.callMethod(controller, Reflect.field(controller, prefixFunc.name), getArgs(prefixFunc, requestData, prefixCb));
						} else {
							prefixCb();
						}
					}

					if (beforeFunc != null) {
						Reflect.callMethod(controller, Reflect.field(controller, beforeFunc.name), [pathFunc.name, beforeCb]);
					} else {
						beforeCb();
					}
				}
				var d = Node.require('domain').create();
				d.on('error', function(err) {
					try {
						throw(err);
					} catch (e:String) {
						logger.error(e);
						requestData.res.send(500, e);
					} catch (e:Dynamic) {
						var msg:String = "Unhandled error";
						logger.error(msg);
						requestData.res.send(500, msg);
						throw (e);
					}
				});
				d.run(toRun);
			}]);

		}

	}

	private function getArgs(func:ClassFieldInfo, reqData:RequestData, ret:Void -> Void):Array<Dynamic> {
		var res:Array<Dynamic> = new Array<Dynamic>();
		var args:List<FuncArg> = Reflection.getFuncArgs(func);
		if (args == null) {
			throw func.name + " should be a function";
		} else {
			for(arg in args) {
				switch(arg.type) {
					case Function(a, r):
						res.push(ret);
					default:
						res.push(ObjectMapper.fromPlainObjectUntyped(reqData.req.param(arg.name), arg.type));
				}
			}
		}
		return res;
	}



}