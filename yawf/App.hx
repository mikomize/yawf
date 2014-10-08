
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
import yawf.node.Util;

class App 
{

	private var express:Express;

	private var conf:Nconf;

	private var redisClient:RedisClient;

	private var logger:WinstonLogger;

	private var mainConfigPath:String;
	private var envConfigPath:String;

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
				var resolvedPath:String = Util.resolvePath(s[1]);
				logger.info("mounted dir: " + resolvedPath + " at " + s[0]);
				express.use(s[0], serve(resolvedPath));
			}
		}
	}

	//@see https://github.com/flatiron/nconf
	private function setUpConf():Void {
		conf = Node.require("nconf");
		conf.env();
		var env:String = conf.get("APP_CONFIG");
		var configs:String = conf.get("APP_CONFIGS_DIR");
		if (configs == null) {
			configs = "configs/";
		}
		if (env != null) {
			envConfigPath = Util.resolvePath(configs + env + ".json");
			if(Util.fileExists(envConfigPath)) {
				conf.add("env", {type: "file", file: envConfigPath});
			} else {
				throw "specified config: " + envConfigPath + " does not exists";
			}
		}

		mainConfigPath = Util.resolvePath(configs + "main.json");
		conf.add("main", {type: "file", file: mainConfigPath});
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
				filename = Util.resolvePath(filename);
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
		logger.info("configs loaded from: " + Util.resolvePath(conf.get("configs")));
		if (envConfigPath != null) {
			logger.info("specified config loaded from: " + envConfigPath);
	 	}
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
		express.enable('trust proxy');
		var ssl:Dynamic = conf.get("ssl");

		var server:NodeHttpServer;
		if (ssl == null) {
			server = Node.http.createServer(untyped express);
		} else {
			logger.info("using ssl");
			var toRead:Array<String> = ["pfx", "key", "cert", "ca"];
			for (r in toRead) {
				var field:String = Reflect.field(ssl, r);
				if (field != null) {
					logger.info(r + ", reading file: " + Util.resolvePath(field));
					var tmp:String = Node.fs.readFileSync(Util.resolvePath(field));
					Reflect.setField(ssl, r, tmp);
				}
			}
			server = Node.https.createServer(untyped ssl, untyped express);
		}
		logger.info("listening at: " + conf.get("ip") + ":" + conf.get("port"));
		server.listen(conf.get("port"), conf.get("ip"));
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