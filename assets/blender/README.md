# Blender 角色与场景资产

最新全员更新见 [cast/README.md](cast/README.md)：23 名角色的实际游戏造型已调整，并提供对应的独立 Blender 工程。下列目录根部的澜音是早期概念稿，全员新版澜音请打开 `cast/character_02.blend`。

这些文件由 Blender 4.5.10 LTS 的无界面构建脚本生成，都是可继续编辑的原始 `.blend` 文件，同时提供 glTF 导出：

- `lanyin.blend` / `lanyin.glb`：澜音的长发、长裙、珍珠饰品和月潮法器示例。
- `sea_chamber.blend` / `sea_chamber.glb`：水下钟庭的拱廊、钟座、环形声纹和珊瑚模块。
- `../../tools_blender_build.py`：可重复运行的 Blender 建模脚本。

当前 Godot 战斗和对话仍使用带动画分组的程序化模型，避免导入外部网格时破坏已有动画；这些 Blender 资产作为高精度可编辑源，用于后续逐个替换角色或制作过场模型。
本目录保存可编辑的 Blender 源文件和 Godot 运行时使用的 GLB 导出文件。

## Godot 导入设置

如果 Godot 弹出“导入 `.blend` 文件需要至少 Blender 3.0”的提示，请在编辑器设置中将 Blender 可执行文件设为：

`<PROJECT_PATH>

对应设置项：

- `filesystem/import/blender/blender_path`
- `filesystem/external_programs/3d_model_editor`

修改后重启 Godot 编辑器。项目也提供 `.glb` 文件，在无法使用 Blender 导入器时可以直接使用。
