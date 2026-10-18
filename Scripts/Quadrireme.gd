extends Ship
class_name Quadrireme

## Quadrireme oars may rise or drop by 1 in a Command phase.
func get_ship_kind() -> SpeedCalculator.ShipKind:
	return SpeedCalculator.ShipKind.QUADRIREME
