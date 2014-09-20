
package yawf;

import yawf.typedefs.ExpressHttpServerReq;
import yawf.typedefs.ExpressHttpServerResp;

class JsonRpcRequestData extends RequestData
{
	public var method:String;

	public var params:Array<Dynamic>;

	public var id:String;
	
	public function new(req:ExpressHttpServerReq, res:ExpressHttpServerResp) {
		super(req, res);
		method = req.body.method;
		params = req.body.params;
		id = req.body.id;
	}

}