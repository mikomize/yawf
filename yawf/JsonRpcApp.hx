
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
		var afterFunc:ClassFieldInfo = classInfo.getFieldsByMeta("after").shift();

		var endpointsFuncs:Array<ClassFieldInfo> = classInfo.getFieldsByMeta("endpoint");


		logger.verbose("registering endpoints:");
		for (endpointFunc in endpointsFuncs) {
			var key:String = serviceName +  "." +endpointFunc.getMeta("endpoint")[0];
			logger.verbose(key);


			var func:ExpressHttpServerReq -> ExpressHttpServerResp -> Void;
			func = function (req:ExpressHttpServerReq, res:ExpressHttpServerResp) {
				var requestData:RequestData = createRequestData(req, res);
				var injector:Injector = createInjector(requestData);
				var service:Service = injector.instantiate(serviceClass);

				if (beforeFunc != null) {
					Reflect.callMethod(service, Reflect.field(service, beforeFunc.name), [endpointFunc.name]);
				}
				if (startFunc != null) {
					call(service, startFunc, requestData);
				}
				call(service, endpointFunc, requestData);
				if (afterFunc != null) {
					Reflect.callMethod(service, Reflect.field(service, afterFunc.name), [endpointFunc.name]);
				}
			}
			endpoints.set(key, func);
		}
	}

	public function new() {
		endpoints = new Map<String, ExpressHttpServerReq -> ExpressHttpServerResp -> Void>();
		super();
	}

	override public function start() {
		var bodyParser = Node.require('body-parser');
		express.use("/", bodyParser());
		express.use("/", function (req:ExpressHttpServerReq, res:ExpressHttpServerResp) {
			var name:String = Std.string(req.body.method);
			logger.verbose("calling: " + name);
			var func:ExpressHttpServerReq -> ExpressHttpServerResp -> Void = endpoints.get(name); 
			if (func == null) {
				throw "theres is no: " + name + " defined";
			}
			endpoints.get(name)(req,res);
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