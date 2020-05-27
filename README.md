# TankEvents WoW addon

TankEvents concisely displays "important" combat log events in a log frame of
its own. The frame is movable (click-drag) and resizable (right-click-drag) by
default, and can be locked with the command `/tev`.

The events displayed by TankEvents are not configurable. They are:
 * Player health changes that exceed 2.5% hit points in value
 * Spells interrupted by player

Events in the TankEvents frame can be interacted with using the mouse. On
mouseover, the corresponding text from the combat log is displayed. On click, a
tooltip window for the spell associated with the event is opened (if any), and
shift-click creates a chat link for that spell. Control-click inserts the text
of the original combat log event into the chat input field.
