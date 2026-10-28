# Aseprite MCP cheat sheet — exact calls, no discovery needed

Read this once. Everything below is verified signature. **Do not spend turns searching the tool
catalog.** Copy a call, change the numbers.

## How to call

Every call goes inside one `execute` block:

```js
const a = tools["aseprite"];
const r = await a.create_canvas({ width: 24, height: 30, filename: "D:/beyond-the-void/assets/art_src/player/down.aseprite" });
return JSON.stringify(r);
```

Batch freely. One `execute` call can do a whole layer, a whole frame, or a whole export pass.
Do not make one `execute` per pixel row. Do not `return` an awaited tool object; stringify it.

## Core signatures

```js
a.create_canvas({ width, height, filename })
a.add_group({ filename, group_name })
a.add_layer({ filename, layer_name, group })
a.create_cel({ filename, layer_name, frame_index, x, y })
a.add_frames({ filename, count, duration_ms })
a.copy_frame({ filename, source_frame, target_frame, overwrite })
a.set_frame_duration({ filename, frame_index, duration_ms })

a.set_palette({ filename, colors: ["#0B0F14", "#1C2A33"] })
a.get_palette({ filename })
a.generate_color_ramp({ base_color: "#4E6B6B", steps: 5, hue_shift_degrees: 18, lightness_range: 0.45 })

a.draw_rows({ filename, layer_name, frame_index, x, y, rows: ["..KK.."], legend: { K: "#1A1C2C" }, outline })
a.read_rows({ filename, x, y, width, height, frame_index, layer_name })
a.fill_area_at({ filename, layer_name, frame_index, x, y, color })
a.draw_line_at({ filename, layer_name, frame_index, x1, y1, x2, y2, color, thickness })
a.draw_rectangle_at({ filename, layer_name, frame_index, x, y, width, height, color, fill })
a.draw_ellipse_at({ filename, layer_name, frame_index, center_x, center_y, radius_x, radius_y, color, fill })
a.replace_color({ filename, layer_name, frame_index, from_color, to_color, tolerance })
a.erase_region({ filename, layer_name, frame_index, x, y, width, height })
a.clear_cel({ filename, layer_name, frame_index })
a.copy_cel({ filename, layer_name, source_frame, target_frame, replace })
a.outline_cel({ filename, layer_name, frame_index, color, include_diagonals, region })
a.set_cel_position({ filename, layer_name, frame_index, x, y })
a.offset_cel_positions({ filename, layer_name, start_frame, end_frame, dx, dy })

a.get_sprite_info({ filename })
a.get_bounds({ filename, layer_name, frames })
a.get_color_stats({ filename, frame_index, top })
a.lint_sprite({ filename, frame_index, layer_name })
a.compare_frames({ filename, frame_a, frame_b, layer_name, region })
a.validate_scene({ filename, required_layers, start_frame, end_frame })

a.export_frame({ filename, frame_index, output_filename, scale })
a.export_sprite({ filename, output_filename, format })
a.export_animation({ filename, output_filename, tag, scale, background })
a.render_onion_skin({ filename, frame_index, output_filename, before, after, scale })
```

`export_frame`'s `scale` **is** the temporary upscale. `scale: 32` on a 24×30 sprite writes
768×960. No separate resize step exists or is needed.

## draw_rows

```js
a.draw_rows({
  filename: "D:/beyond-the-void/assets/art_src/player/down.aseprite",
  layer_name: "body", frame_index: 1, x: 0, y: 0,
  rows: [
    "......KKKKKK......",
    ".....KSSSSSSK.....",
  ],
  legend: { K: "#12181D", S: "#C9B98A" },
  outline: "#080B0E",
});
```

- `.` or a char missing from `legend` leaves the pixel untouched. `"#00000000"` erases.
- Rows must be equal width. Row 1 starts at `y`, first char at `x`.
- `outline` adds a 1 px side outline around the drawn pixels — use it on the final pass only,
  never on an intermediate pass.

## The loop for one asset

1. `create_canvas` at the exact contract size.
2. `add_layer` for `body`, `detail`, `outline` (skip groups unless you need them).
3. `create_cel` on each layer, frame 1.
4. `draw_rows` the silhouette in one flat colour, in 6–10 rows per call, several calls per
   `execute`.
5. `export_frame` at the preview scale into
   `D:/beyond-the-void/build/reports/overhaul/art/previews/<group>/<asset>_full_<scale>x.png`.
6. `read` that exact file. **One image per turn.** Name the defects you see.
7. Fix with `draw_rows` / `replace_color`, export the next transform, `read` again.

Game-ready file: `export_frame` with `scale: 1` (or `export_sprite`) to
`D:/beyond-the-void/assets/sprites/...`. Never let a preview overwrite a game file.

## Non-negotiables

- `view_sprite` is banned. It does not return pixels in this harness.
- Never `read` a raw 1× PNG: export at the scale that puts the long side at 768–1024 px.
- Previews live under `build/reports/overhaul/art/previews/`. They are disposable.
- Report each finished asset in your own report file, with the preview paths and dimensions.
