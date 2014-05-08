import yawf.*;
import yawf.reflections.TypeEnum;
import js.Node;

class Test {
	public static function main() {
		var app:JsonRpcApp = new JsonRpcApp();
		app.init(function () {
			app.register(TestService);
			app.start();
		});
	}
}