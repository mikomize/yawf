
package yawf;

import js.Node;

import yawf.node.Util

class XMLParser 
{

	public static var baseFilesPath:String = ".";

	public static function parse(xml, callback:Dynamic -> Void) {
		var xml2js = Node.require('xml2js');
    	var parser = xml2js.Parser({
      		explicitArray: false,
      		mergeAttrs: true,
    	});

    	parser.parseString(xml, function (err, result) {
			if (err != null) {
				Util.trace(err);
			}
        	result = pleaseDo(result);
        	callback(result);
        });
	}

	public static function pleaseDo(jsonFromXml:Dynamic) {
		iterateObj(jsonFromXml);
		return jsonFromXml;
	}

	private static function iterateObj(obj:Dynamic):Void {
		for (field in Reflect.fields(obj)) {
            var value:Dynamic = Reflect.field(obj, field);
            if (Std.is(value, Array)) {
            	iterateArr(value);
            } else if (!Std.is(value, Int) && !Std.is(value, String)) {
            	if (Reflect.hasField(value, "_")) {
            		Reflect.setField(obj,field, Reflect.field(value, "_"));
            	} else {
					Reflect.setField(obj, field, processObj(value));
					iterateObj(Reflect.field(obj, field));
				}
			}
		}

		for (field in Reflect.fields(obj)) {
			var value:Dynamic = Reflect.field(obj, field);
			if (!Std.is(value, Array) &&!Std.is(value, Int) && !Std.is(value, String)) {
				Reflect.setField(obj, field, processInheritance(value, obj));
			}
		}
	}

	private static function iterateArr(arr:Array<Dynamic>):Void {
		for (i in 0...arr.length) {
			if (Std.is(arr[i], Array)) {
				iterateArr(arr[i]);
			} else if (!Std.is(arr[i], Int) && !Std.is(arr[i], String)) {
				arr[i] = processObj(arr[i]);
				iterateObj(arr[i]);
			}
		}
	}

	private static function processInheritance(obj:Dynamic, parent:Dynamic):Dynamic {
		var extendsField:String = Reflect.field(obj, 'extends');
		if (extendsField != null) {
			var baseObj:Dynamic = Reflect.field(parent, extendsField);
			for (field in Reflect.fields(baseObj)) {
				if (Reflect.field(obj, field) == null) {
					Reflect.setField(obj, field, Reflect.field(baseObj, field));
				}
			}
		}
		return obj;
	}


	private static function processObj(obj:Dynamic):Dynamic {
		var hashField:String = Reflect.field(obj, 'map');
		var arrField:String = Reflect.field(obj, 'array');
		var fileField:String = Reflect.field(obj, 'file');
		if (hashField != null) {
			var id:String = Reflect.field(obj, 'indexId');
			if (id == null) {
				id = 'id';
			}
			var res:Dynamic = {};
			if (!Reflect.hasField(obj, hashField)) {
				return {};
			}
			var tmp = Reflect.field(obj, hashField);
			var values:Array<Dynamic> = tmp;
			if (!Std.is(tmp, Array)) {
				values = new Array<Dynamic>();
				values.push(tmp);
			}

			for (value in values) {
				Reflect.setField(res, Reflect.field(value, id), value);
			}
			return res;
		} else if (arrField != null) {
			if (!Reflect.hasField(obj, arrField)) {
				return [];
			}
			var tmp = Reflect.field(obj, arrField);
			if (!Std.is(tmp, Array)) {
				var ra:Array<Dynamic> = new Array<Dynamic>();
				ra.push(tmp);
				return ra;
			}

			return tmp;
		} else if (fileField != null) {
			var result = Node.fs.readFileSync(Util.resolvePath(baseFilesPath) + "/" + fileField);
			return result;
		}
		
		return obj;
	}

}
