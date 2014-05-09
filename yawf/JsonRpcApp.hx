
package yawf;

import js.Node;
import yawf.typedefs.Express;
import yawf.typedefs.ExpressHttpServerReq;
import yawf.typedefs.ExpressHttpServerResp;
import yawf.typedefs.Nconf;
import yawf.reflections.*;
import minject.Injector;

class JsonRpcApp extends App
{
	private var endpoints:Map<String, ExpressHttpServerReq -> ExpressHttpServerResp -> Void>;

	public function register(serviceClass:Class<Service>) {
		var classInfo:ClassInfo = Reflection.getClassInfo(serviceClass);

		var serviceName:String = classInfo.meta.get("service")[0];

		var startFunc:ClassFieldInfo = classInfo.getFieldsByMeta("start").shift();
		var beforeFunc:ClassFieldInfo = classInfo.getFieldsByMeta("before").shift();

		var endpointsFuncs:Array<ClassFieldInfo> = classInfo.getFieldsByMeta("endpoint");


		logger.verbose("registering endpoints:");
		for (endpointFunc in endpointsFuncs) {
			var key:String = serviceName +  "."  +endpointFunc.getMeta("endpoint")[0];
			logger.verbose(key);


			var func:ExpressHttpServerReq -> ExpressHttpServerResp -> Void;
			func = function (req:ExpressHttpServerReq, res:ExpressHttpServerResp) {
				var requestData:JsonRpcRequestData = cast(createRequestData(req, res), JsonRpcRequestData);
				logger.verbose("called: " + key + Std.string(requestData.params));
				var injector:Injector = createInjector(requestData);
				var service:Service = injector.instantiate(serviceClass);
				var d = Node.require('domain').create();

				var toRun:Void -> Void = function () {
					var beforeCb:Void -> Void = function () {
						var startCb:Void -> Void = function () {
							Reflect.callMethod(service, Reflect.field(service, endpointFunc.name), getArgs(endpointFunc, requestData, null));
						}

						if (startFunc != null) {
							Reflect.callMethod(service, Reflect.field(service, startFunc.name), getArgs(startFunc, requestData, startCb));
						} else {
							startCb();
						}
					}

					if (beforeFunc != null) {
						Reflect.callMethod(service, Reflect.field(service, beforeFunc.name), [endpointFunc.name, beforeCb]);
					} else {
						beforeCb();
					}
				}

				if (conf.get("debug") == true) {
					toRun();
				} else {
					d.on('error', function(err) {
						try {
							throw(err);
						} catch (e:String) {
							logger.error(e);
							service.error(e);
						} catch (e:Dynamic) {
							var msg:String = "Unhandled error";
							logger.error(msg);
							service.error(msg);
							throw (e);
						}
						
					});
					d.run(toRun);
				}
			}
			endpoints.set(key, func);
		}
	}

	private function getArgs(func:ClassFieldInfo, reqData:JsonRpcRequestData, ret:Void -> Void):Array<Dynamic> {
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
						res.push(ObjectMapper.fromPlainObjectUntyped(reqData.params.shift(), arg.type));
				}
			}
		}
		return res;
	}

	public function new() {
		endpoints = new Map<String, ExpressHttpServerReq -> ExpressHttpServerResp -> Void>();
		super();
	}

	override public function start() {
		var bodyParser = Node.require('body-parser');
		express.use("/", bodyParser());

		express.post("/", function (req:ExpressHttpServerReq, res:ExpressHttpServerResp) {
			var name:String = Std.string(req.body.method);
			var func:ExpressHttpServerReq -> ExpressHttpServerResp -> Void = endpoints.get(name); 
			if (func == null) {
				throw "theres is no: " + name + " defined";
			} else {
				func(req,res);
			}
		});
		express.use("/", function (err, req, res, next) {
			if (err == null) {
				next(null);
			} else {
				res.json(500, "Unhandled internal server error");
				throw err;
			}
		});
		super.start();
	}

	override private function getArgForCall(index:Int, name:String, type:TypeEnum, requestData:RequestData):Dynamic {
		var data:JsonRpcRequestData = cast(requestData, JsonRpcRequestData);
		return data.params.shift();
	}

	override private function createRequestData(req:ExpressHttpServerReq, res:ExpressHttpServerResp):RequestData {
		return new JsonRpcRequestData(req, res);
	}
}