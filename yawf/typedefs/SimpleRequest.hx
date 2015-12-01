package yawf.typedefs;

typedef RequestReply = Dynamic -> {statusCode: Int, headers: Map<String, String> } -> Dynamic -> Void; //err , httpResponse, body

typedef RequestOptions = {
	var url:String;
	@:optional var baseUrl:String;
	@:optional var body:Dynamic;
	@:optional var json:Bool;
};

typedef SimpleRequest = {
	function get(options:RequestOptions, reply:RequestReply):SimpleRequest;
}