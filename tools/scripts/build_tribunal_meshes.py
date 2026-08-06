import bpy
from pathlib import Path


def clear():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def mat(name, col):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs[0].default_value = (*col, 1)
    return m


def add_cube(name, loc, scale, color):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    o.data.materials.append(mat(name, color))
    return o


def build_humanoid(path: Path, color):
    clear()
    add_cube("torso", (0, 0, 1.1), (0.45, 0.25, 0.55), color)
    add_cube("head", (0, 0, 1.7), (0.28, 0.28, 0.28), (min(1, color[0] * 1.1), min(1, color[1] * 1.1), min(1, color[2] * 1.1)))
    add_cube("leg_l", (-0.15, 0, 0.45), (0.14, 0.14, 0.45), color)
    add_cube("leg_r", (0.15, 0, 0.45), (0.14, 0.14, 0.45), color)
    add_cube("arm_l", (-0.4, 0, 1.15), (0.12, 0.12, 0.4), color)
    add_cube("arm_r", (0.4, 0, 1.15), (0.12, 0.12, 0.4), color)
    bpy.ops.object.select_all(action="SELECT")
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.obj_export(filepath=str(path), export_selected_objects=True)
    print("wrote", path)


def main():
    root = Path("/home/buidl/ForgeStudio/games/tribunal/assets/models")
    build_humanoid(root / "characters" / "tribunal_hunter.obj", (0.25, 0.4, 0.7))
    build_humanoid(root / "characters" / "tribunal_enemy.obj", (0.75, 0.12, 0.08))
    clear()
    add_cube("blade", (0, 0, 0.7), (0.04, 0.02, 0.9), (0.7, 0.72, 0.8))
    add_cube("guard", (0, 0, 0.25), (0.25, 0.05, 0.05), (0.3, 0.3, 0.32))
    add_cube("hilt", (0, 0, 0.1), (0.05, 0.05, 0.2), (0.2, 0.12, 0.08))
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.wm.obj_export(
        filepath=str(root / "weapons" / "tribunal_sword.obj"),
        export_selected_objects=True,
    )
    print("done")


if __name__ == "__main__":
    main()
