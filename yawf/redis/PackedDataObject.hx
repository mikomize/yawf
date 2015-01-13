package yawf.redis;

@:rtti
class PackedDataObject 
{
	@param
	public var data:String;

	@param
	public var className:String;

	public function new(className:String, data:String) {
		this.data = data;
		this.className = className;
	}

}