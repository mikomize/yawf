
package yawf;

import minject.Injector;
import js.Node;

@:rtti
class Service 
{
	@inject
	public var injector:Injector;

	@inject
	public var requestData:RequestData;

	@inject
	public var conf:IConfig;

	@inject
	public var logger:ILogger;

	public function success(msg:Dynamic, verbose:Bool = true):Void {
		var res:Dynamic = getResponseData();
		res.result = ObjectMapper.toPlainObject(msg);
		sendResponse(res, verbose);
	}

	public function error(msg:Dynamic):Void {
		var res:Dynamic = getResponseData();
		res.error = ObjectMapper.toPlainObject(msg);
		sendResponse(res, true);
	}

	private function getResponseData():Dynamic {
		var resData = {
	    	'id': cast(requestData, JsonRpcRequestData).id,
	      	'error': null,
	      	'result': null
	    };
	    return resData;
	}

	private function sendResponse(responseData:Dynamic, verbose:Bool = false) {
		if (verbose) {
			if (responseData.error == null) {
				logger.verbose("OK#" + Node.stringify(responseData.result));
			} else {
				logger.verbose("ERROR#", Node.stringify(responseData.error));
			}
		}
	    requestData.res.json(200, responseData);
  	}	

}