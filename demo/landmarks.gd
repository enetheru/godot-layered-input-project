extends Node3D

## Yard the cube drives through. The shapes are landmarks so a turn and a reset are visible.


const GROUND:Color = Color( 0.30, 0.32, 0.34, 1 )
const PAD:Color = Color( 0.46, 0.48, 0.42, 1 )
const WALL:Color = Color( 0.72, 0.42, 0.28, 1 )


func _ready() -> void:
	_box( Vector3( 0.0, -0.1, 0.0 ), Vector3( 80.0, 0.2, 80.0 ), GROUND )
	_box( Vector3( 0.0, 0.03, 0.0 ), Vector3( 4.0, 0.06, 4.0 ), PAD )

	_pillar( Vector3( -18.0, 2.6, -18.0 ), Color( 0.86, 0.38, 0.28, 1 ) )
	_pillar( Vector3( 18.0, 2.6, -18.0 ), Color( 0.36, 0.72, 0.42, 1 ) )
	_pillar( Vector3( -18.0, 2.6, 16.0 ), Color( 0.86, 0.74, 0.32, 1 ) )
	_pillar( Vector3( 18.0, 2.6, 16.0 ), Color( 0.52, 0.40, 0.82, 1 ) )
	_pillar( Vector3( 0.0, 4.0, -24.0 ), Color( 0.90, 0.90, 0.92, 1 ) )

	for slot:int in 4:
		var x:float = -6.0 + float( slot ) * 4.0
		_box( Vector3( x, 0.7, -12.0 ), Vector3( 3.0, 1.4, 1.2 ), WALL )

	for step:int in 8:
		var angle:float = TAU * float( step ) / 8.0
		var at:Vector3 = Vector3( sin( angle ) * 8.0, 0.4, cos( angle ) * 8.0 )
		var tint:Color = Color( 0.35 + 0.07 * float( step ), 0.45, 0.62, 1 )
		_box( at, Vector3( 0.8, 0.8, 0.8 ), tint )


func _box( at:Vector3, size:Vector3, color:Color ) -> void:
	var mesh:BoxMesh = BoxMesh.new()
	mesh.size = size
	_place( mesh, at, color )


func _pillar( at:Vector3, color:Color ) -> void:
	var mesh:CylinderMesh = CylinderMesh.new()
	mesh.top_radius = 0.7
	mesh.bottom_radius = 0.7
	mesh.height = 5.2
	_place( mesh, at, color )


func _place( mesh:Mesh, at:Vector3, color:Color ) -> void:
	var mat:StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	var inst:MeshInstance3D = MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = at
	add_child( inst )
