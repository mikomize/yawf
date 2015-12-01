package yawf;

import js.Node;
import yawf.typedefs.SimpleRequest;
import yawf.typedefs.SimpleRequest.RequestReply;

class JsonRpcClient {
	static public function call(url:String, method:String, params:Dynamic, cb:RequestReply):Void {
		var request:SimpleRequest = Node.require("request");
		request.get({url: url, json: true, body: {method: method, params:params}}, cb);
	}
}