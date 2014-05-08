
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

	public function success(msg:Dynamic):Void {
		var res:Dynamic = getResponseData();
		res.result = msg;
		sendResponse(res);
	}

	public function error(msg:Dynamic):Void {
		var res:Dynamic = getResponseData();
		res.error = msg;
		sendResponse(res);
	}

	private function getResponseData():Dynamic {
		var resData = {
	    	'id': cast(requestData, JsonRpcRequestData).id,
	      	'error': null,
	      	'result': null
	    };
	    return resData;
	}

	private function sendResponse(responseData:Dynamic) {
		logger.verbose("Response:", responseData.result);
  		//requestData.res.writeHead(200, {"Content-Type": "text/plain"});
	    requestData.res.json(Node.stringify(responseData));
  	}	

}