class_name PressOverlay
extends Node2D
## Zeichnet den Kopf der STILO60-Presse.


func _draw() -> void:
	# 480px Breite, 10px Höhe.
	# Zuerst füllen mit Intercable-Rot: #E30613
	var rect := Rect2(0, 0, 480, 10)
	draw_rect(rect, Color("#E30613"), true)

	# Dann weißen Rand zeichnen
	draw_rect(rect, Color.WHITE, false, 1.0)
