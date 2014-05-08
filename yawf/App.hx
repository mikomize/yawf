
package yawf;

import yawf.typedefs.Express;
import yawf.typedefs.ExpressHttpServerReq;
import yawf.typedefs.ExpressHttpServerResp;
import yawf.typedefs.Redis;
import yawf.typedefs.Nconf;
import yawf.typedefs.Winston;
import yawf.reflections.*;
import yawf.redis.*;
import minject.Injector;
import js.Node;

class App 
{

	private var express:Express;

	private var conf:Nconf;

	private var redisClient:RedisClient;

	private var logger:WinstonLogger;

	private function getDirName() {
		return Node.path.dirname(Node.process.argv[1]);
	}

	private function getDefaults():Dynamic {
		return {
			"ip": "127.0.0.1",
			"port": 2999,
			"redis": {
				"db": 3,
				"ip": "127.0.0.1",
				"port": 6379,
				"options": {}
			},
			"loggers": {
				"Console": {
					"level": "silly",
					"colorize": true,
					"timestamp": true
				}
			}
		};
	}

	private function resolvePath(to:String):String {
		var res:String;
		if (to.charAt(0) != "/") {
			res = getDirName() + '/' + to;
		} else {
			res = to;
		}
		return res;
	}

	private function setUpConf():Void {
		conf = Node.require("nconf");
		conf.argv();
		var env:String = conf.get("env");
		var configs:String = conf.get("configs");
		if (configs == null) {
			configs = "configs/";
		}
		conf.add("env", {type: "file", file: resolvePath(configs + env + ".json")});
		conf.add("main", {type: "file", file: resolvePath(configs + "main.json")});
		conf.defaults(getDefaults());
		
	}

	private function setUpRedis(cb:Void -> Void):Void {
		if (conf.get("redis") != null) {
			redisClient = Redis.newClient(conf.get("redis:port"), conf.get("redis:ip"), conf.get("redis:options"));
			logger.info("redis connected to: " + conf.get("redis:ip") + ":" + conf.get("redis:port"));
			var redisDb:Int = conf.get("redis:db"); 
			if (redisDb != null) {
				redisClient.select(redisDb, function(err:Err, res:String) {
					logger.info("redis db set to: " + redisDb);
					cb();
				});
				return;
			} 
		} 
		cb();
	}

	//@see: https://github.com/flatiron/winston
	//@see: https://github.com/indexzero/winston-syslog
	private function createLogger():Void {
		var winston:Winston = Node.require('winston');
		Node.require('winston-syslog').Syslog;
		var transports:Array<Dynamic> = new Array<Dynamic>();
		var loggers:Dynamic = conf.get('loggers');
		for (field in Reflect.fields(loggers)) {
			var loggerClass:Class<Dynamic> = Reflect.field(winston.transports, field);
			var loggerConf:Dynamic = Reflect.field(loggers, field);
			//resolving path in config
			if (Reflect.hasField(loggerConf, "filename")) {
				var filename:String = Reflect.field(loggerConf, "filename");
				filename = resolvePath(filename);
				Reflect.setField(loggerConf, "filename", filename);
			}
			transports.push(Type.createInstance(loggerClass, [loggerConf]));
		}
		logger = Type.createInstance(winston.Logger, [{
			transports : transports
		}]);
	}

	public function new() {
	}

	public function init(onComplete:Void -> Void) {
		setUpConf();
		createLogger();
		logger.info("initializing");
		express = Type.createInstance(Node.require("express"), []);
		
		setUpRedis(function () {
			onComplete();
		});
		
	}

	public function start() {
		express.listen(conf.get("port"), conf.get("ip"));
		logger.info("listening at: " + conf.get("ip") + ":" + conf.get("port"));
	}

	private function call(controller:Dynamic, func:ClassFieldInfo, requestData:RequestData) {
		var callArgs:Array<Dynamic> = new Array<Dynamic>();

		switch(func.type) {
			case Function(args, ret):
				var i:Int = 0;
				for (arg in args) {
					var argForCall:Dynamic = getArgForCall(i, arg.name, arg.type, requestData);
					switch (arg.type) {
						case Int: 
							callArgs.push(Std.parseInt(argForCall));
						case Float: 
							callArgs.push(Std.parseFloat(argForCall));
						case String:
							callArgs.push(argForCall);
						case Class(c):
							callArgs.push(ObjectMapper.fromPlainObjectUntyped(argForCall, TypeEnum.Class(c)));
						default:
							throw "unsuported type of argument " + arg.name + " in function " + func.name;
					}
					i++;
				}
			default:
				throw func.name + " should be a function";

		}

		Reflect.callMethod(controller, Reflect.field(controller, func.name), callArgs);
	}

	private function getArgForCall(index:Int, name:String, type:TypeEnum, requestData:RequestData):Dynamic {
		return requestData.req.param(name);
	}

	private function createInjector(requestData:RequestData):Injector {
		var injector:Injector = new Injector();
		injector.mapValue(Injector, injector);
		injector.mapValue(RequestData, requestData);
		injector.mapValue(IConfig, conf);
		injector.mapValue(ILogger, logger);
		var r:RedisLayer = new RedisLayer(redisClient);
		injector.injectInto(r);
		injector.mapValue(RedisLayer, r);
		return injector;
	}

	private function createRequestData(req:ExpressHttpServerReq, res:ExpressHttpServerResp):RequestData {
		return new RequestData(req, res);
	}

}