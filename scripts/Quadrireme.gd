extends Ship
class_name Quadrireme

## Quadrireme speed changes are +1 or -1.
func get_ship_kind() -> SpeedCalculator.ShipKind:
	return SpeedCalculator.ShipKind.QUADRIREME
