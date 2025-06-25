# Gotod Vehicle Test

## Project Structure

```
.
├── vehicle-test/
│   ├── scenes/
│   │   ├── objects/
│   │   │   └── cone/
│   │   │       ├── assets/
│   │   │       │   ├── .gdignore
│   │   │       │   └── cone.blend
│   │   │       ├── cone.tscn
│   │   │       ├── cone.glb
│   │   │       ├── cone_tex_d.png
│   │   │       ├── cone_tex_n.png
│   │   │       └── cone_mat.tres
│   │   ├── vehicles/
│   │   │   └── sedan/
│   │   │       └── ...
│   │   ├── characters/
│   │   │   └── chracter1/
│   │   │       ├── character1.tscn
│   │   │       ├── character1.gd
│   │   │       └── ...
│   │   └── world/
│   │       └── main/
│   │           ├── main.tscn
│   │           └── main.gd
│   └── scripts/
│       └── economy/
│           └── economy.gd 
├── subproject1/
│   ├── scenes/
│   │   └── ...
│   └── scripts/
│       └── ...
└── zamotany/
    ├── scenes/
    │   └── ...
    └── scripts/
        └── ...
```

## File naming convention

File naming convetion follows the following pattern:

```
<base_name>_<asset_type>_<asset_variant>.<extension>
```

If the variant doesn't exist for a given asset type (because it doesn't make sense) it should be omitted from file name,
shortening the pattern to `<bane_name>_<asset_type>.<extension>`.

Here's a table of common asset types and their variants:

| Asset type | Variant           | Suffix | Example       |
|------------|-------------------|--------|---------------|
| Texture    | Diffuse / Albedo  | tex_d  | bob_tex_d.png |
|            | Alpha / Opacity   | tex_a  | bob_tex_a.png |
|            | Normal            | tex_n  | bob_tex_n.png |
|            | Roughness         | tex_r  | bob_tex_r.png |
|            | Emissive          | tex_e  | bob_tex_e.png |
|            | Ambient Occlusion | tex_o  | bob_tex_o.png |
|            | Metalic           | tex_m  | bob_tex_m.png |
| Material   |                   | mat    | bob_mat.tres  |
