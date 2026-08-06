extends RefCounted
class_name ObjMeshLoader
## Minimal OBJ → ArrayMesh loader (first-class runtime meshes, no editor import required).


static func load_mesh(path: String) -> ArrayMesh:
	if path == "" or not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var positions: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var faces: Array = []  # each face = array of [vi, vti, vni] 1-based indices

	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var parts := line.split(" ", false)
		if parts.is_empty():
			continue
		match parts[0]:
			"v":
				if parts.size() >= 4:
					positions.append(Vector3(parts[1].to_float(), parts[2].to_float(), parts[3].to_float()))
			"vt":
				if parts.size() >= 3:
					uvs.append(Vector2(parts[1].to_float(), parts[2].to_float()))
			"vn":
				if parts.size() >= 4:
					normals.append(Vector3(parts[1].to_float(), parts[2].to_float(), parts[3].to_float()))
			"f":
				var face: Array = []
				for i in range(1, parts.size()):
					var tok := parts[i].split("/")
					var vi := tok[0].to_int()
					var vti := tok[1].to_int() if tok.size() > 1 and tok[1] != "" else 0
					var vni := tok[2].to_int() if tok.size() > 2 and tok[2] != "" else 0
					face.append([vi, vti, vni])
				if face.size() >= 3:
					# fan triangulate
					for t in range(1, face.size() - 1):
						faces.append([face[0], face[t], face[t + 1]])

	if positions.is_empty() or faces.is_empty():
		return null

	var out_pos := PackedVector3Array()
	var out_nrm := PackedVector3Array()
	var out_uv := PackedVector2Array()
	var indices := PackedInt32Array()

	var has_n := normals.size() > 0
	var has_uv := uvs.size() > 0
	var i := 0
	for tri in faces:
		for corner in tri:
			var vi: int = corner[0]
			if vi < 0:
				vi = positions.size() + vi + 1
			var p := positions[vi - 1]
			out_pos.append(p)
			if has_uv and corner[1] != 0:
				var vti: int = corner[1]
				if vti < 0:
					vti = uvs.size() + vti + 1
				out_uv.append(uvs[vti - 1])
			else:
				out_uv.append(Vector2(p.x * 0.5 + 0.5, p.z * 0.5 + 0.5))
			if has_n and corner[2] != 0:
				var vni: int = corner[2]
				if vni < 0:
					vni = normals.size() + vni + 1
				out_nrm.append(normals[vni - 1].normalized())
			else:
				out_nrm.append(Vector3.UP)
			indices.append(i)
			i += 1

	# Recompute flat normals if none
	if not has_n:
		for t in range(0, indices.size(), 3):
			var a := out_pos[indices[t]]
			var b := out_pos[indices[t + 1]]
			var c := out_pos[indices[t + 2]]
			var n := (b - a).cross(c - a).normalized()
			out_nrm[indices[t]] = n
			out_nrm[indices[t + 1]] = n
			out_nrm[indices[t + 2]] = n

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = out_pos
	arrays[Mesh.ARRAY_NORMAL] = out_nrm
	arrays[Mesh.ARRAY_TEX_UV] = out_uv
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func make_mesh_instance(path: String, mat: Material = null) -> MeshInstance3D:
	var mesh := load_mesh(path)
	if mesh == null:
		return null
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if mat:
		mi.material_override = mat
	return mi
