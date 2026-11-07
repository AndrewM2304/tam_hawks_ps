extends RefCounted
## Existing native-route drivers now send the owner's fore/aft manual controls.
## Reads authoritative state and sends actions; never assigns motion/balance.

static func correct(rider: Node, correction: float) -> void:
	Input.action_release("push")
	Input.action_release("brake")
	var fore_aft: float = correction * rider._manual_balance_input_sign()
	if fore_aft > 0.0: Input.action_press("push", minf(fore_aft, 1.0))
	elif fore_aft < 0.0: Input.action_press("brake", minf(-fore_aft, 1.0))


static func hold(rider: Node, threshold: float = 0.05, strength: float = 1.0) -> void:
	var correction := 0.0
	if rider.manual_balance > threshold: correction = -strength
	elif rider.manual_balance < -threshold: correction = strength
	correct(rider, correction)
