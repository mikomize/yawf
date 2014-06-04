
package yawf;

import yawf.typedefs.Express;
import yawf.typedefs.ExpressHttpServerReq;
import yawf.typedefs.ExpressHttpServerResp;
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
		return untyped __dirname;
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
			},
			"debug": false,
			"statics": []
		};
	}


    //@see https://github.com/expressjs/serve-static/blob/master/index.js
	private function setStatics():Void {
		var statics:Array<Array<String>> = conf.get("statics");
		var serve = Node.require("serve-static");
		if (statics != null) {
			for (s in statics) {
				var resolvedPath:String = resolvePath(s[1]);
				logger.info("mounted dir: " + resolvedPath + " at " + s[0]);
				express.use(s[0], serve(resolvedPath));
			}
		}
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

	//@see https://github.com/flatiron/nconf
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
		conf.set("configs", configs);
		
	}

	private function setUpRedis(cb:Void -> Void):Void {
		if (conf.get("redis") != null) {
			redisClient = Redis.newClient(conf.get("redis:port"), conf.get("redis:ip"), conf.get("redis:options"));
			logger.info("redis connected to: " + conf.get("redis:ip") + ":" + conf.get("redis:port"));
			var redisDb:Int = conf.get("redis:db"); 
			if (redisDb != null) {
				redisClient.select(redisDb, function(err:Dynamic, res:String) {
					logger.info("redis db set to: " + redisDb);
					cb();
				});
				return;
			} 
		} 
		cb();
	}

	//@see https://github.com/flatiron/winston
	//@see https://github.com/indexzero/winston-syslog
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
		logger.info("configs loaded from: " + resolvePath(conf.get("configs")));
		var env:String = conf.get("env");
		if (env != null) {
			logger.info("env: " +  env);
		}
		if (conf.get("debug")) {
			logger.info("running in debug mode");
		}
		
		express = Type.createInstance(Node.require("express"), []);
		setStatics();
		
		setUpRedis(function () {
			onComplete();
		});
		
	}

	public function start() {
		express.listen(conf.get("port"), conf.get("ip"));
		logger.info("listening at: " + conf.get("ip") + ":" + conf.get("port"));
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