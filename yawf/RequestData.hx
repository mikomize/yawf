
package yawf;

import yawf.typedefs.ExpressHttpServerReq;
import yawf.typedefs.ExpressHttpServerResp;

class RequestData
{

	public var req:ExpressHttpServerReq;
	public var res:ExpressHttpServerResp;

	public function new(req:ExpressHttpServerReq, res:ExpressHttpServerResp) {
		this.req = req;
		this.res = res;
	}

}