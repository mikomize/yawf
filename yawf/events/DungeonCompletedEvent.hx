
package events;

import framework.events.Event;

class DungeonCompletedEvent extends Event
{
	public var won:Bool;

	public function new(won:Bool) {
		this.won = won;
		super();
	}
}