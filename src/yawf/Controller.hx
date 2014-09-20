
package yawf;

import minject.Injector;

/* 
	@path
	@prefix
	@before
	@after
	
*/

@:rtti
class Controller 
{
	@inject
	public var injector:Injector;

	@inject
	public var requestData:RequestData;

	@inject
	public var conf:IConfig;

}