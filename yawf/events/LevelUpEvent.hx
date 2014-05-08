package events;

import framework.events.Event;

class LevelUpEvent extends Event
{
	public var level:Int;

	public function new(level:Int) {
		this.level = level;
		super();
	}
}