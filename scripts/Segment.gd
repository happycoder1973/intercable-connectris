class_name Segment
extends RefCounted
## Datenklasse für ein Kabelsegment.

# Segment-Typen:
# - ISOLATED: Isoliertes Kabel (Rot, Ausgangszustand)
# - BARE: Abisoliertes Kabel (Grau, nach Laser/Abisolierer)
# - CRIMP_LUG: Gecrimpter Kabelschuh (Grün, nach Crimper)
enum Type { ISOLATED, BARE, CRIMP_LUG }

var type: Type = Type.ISOLATED

var color: Color = Color.WHITE


func _init(p_type: Type = Type.ISOLATED, p_color: Color = Color.WHITE) -> void:
	type = p_type
	color = p_color
