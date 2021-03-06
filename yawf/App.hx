	
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
import haxe.Json;

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

	private function setStaticCustomHeadersHandler(params:Dynamic) {
		params.setHeaders = function (res, path) {
			logger.verbose("[served static] " + path);
		};
	}

    //@see https://github.com/expressjs/serve-static/blob/master/index.js
	private function setStatics():Void {
		logger.info("Setting statics");
		var statics:Dynamic = conf.get("statics");
		var serve = Node.require("serve-static");
		var ba = Node.require("basic-auth");
		if (statics != null) {
			for (label in Reflect.fields(statics)) {
				trace(label);
				var info:{uri: String, dirPath:String, auth: {login: String, pass: String}, params:Dynamic} = Reflect.field(statics, label);
				var resolvedPath:String = Util.resolvePath(info.dirPath);
				var uri:String = info.uri;
				logger.info("[ " +  label + " ] mounted dir: " + resolvedPath + " at " + uri);
				var auth = info.auth;
				if (auth != null) {
					logger.info("[ " +  label + " ] with auth");
					express.use(uri, function (req, res, next) {
						var objUser = ba(req);
						if (objUser == null || objUser.name != auth.login || objUser.pass != auth.pass) {
					        res.set("WWW-Authenticate", "Basic realm=Authorization Required");
					        untyped res.status(401).end();
					    } else {
					    	next();
					    }

					});
				}
				logger.info("[ " + label + " ] param " + info.params);
				info.params = info.params == null ? {} : info.params;
				setStaticCustomHeadersHandler(info.params);
				express.use(uri, serve(resolvedPath, info.params));
			}
		}
		logger.info("Done.");
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
				conf.add("env_config", {type: "file", file: envConfigPath});
			} else {
				throw "specified config: " + envConfigPath + " does not exists";
			}
		}

		mainConfigPath = Util.resolvePath(configs + "main.json");
		conf.add("main", {type: "file", file: mainConfigPath});
		conf.defaults(getDefaults());
		conf.set("configs", configs);
		
	}

	private function setUpRedis(redisCfg:Dynamic, cb:RedisClient -> Void):Void {
		var res:RedisClient;
		if (redisCfg.socket != null) {
			res = Redis.newClientSocket(redisCfg.socket, redisCfg.options);
			logger.info("redis connected to: " + redisCfg.socket);
		} else {
			res = Redis.newClient(redisCfg.port, redisCfg.ip, redisCfg.options);
			logger.info("redis connected to: " + redisCfg.ip + ":" + redisCfg.port);
		}
		
		var redisDb:Int = redisCfg.db; 
		if (redisDb != null) {
			res.select(redisDb, function(err:Dynamic, r:String) {
				logger.info("redis db set to: " + redisDb);
				cb(res);
			});
		} else {
			cb(res);
		}
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

		if (conf.get("useCors")) {
			express.use(Node.require("cors")());
		}

		var bodyParser = Node.require('body-parser');
		var compress = Node.require('compression');

		express.use(bodyParser.json({
			verify: function (res, req, raw, enc) {
				try {
					Json.parse(raw.toString(enc));
				} catch(e:Dynamic) {
					logger.error(raw.toString(enc));
					throw "Request is not a valid json";
				}
			}
		}));

		express.use(compress());

		express.use(bodyParser.urlencoded({
  			extended: true
		}));

		setStatics();
		
		setUpRedis(conf.get("redis"), function (rc:RedisClient) {
			redisClient = rc;
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
			//not tested at all
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
		var socket:String = conf.get("socket");
		if (socket != null) {
			socket = Util.resolvePath(socket);
			if (Node.fs.existsSync(socket)) {
				logger.verbose("file: " + socket + " found, removing");
				Node.fs.unlinkSync(socket);
			}
			server.listen(socket, function () {
				Node.require("fs").chmodSync(socket, '777');
				logger.info("listening on: " + socket);
			});
		} else {
			server.listen(conf.get("port"), conf.get("ip"), function () {
				logger.info("listening at: " + conf.get("ip") + ":" + conf.get("port"));
			});
		}
		
		
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