# Industrial map skin v1

Runtime entry: `map_skin.tres`, using `gd/map_skin.gd`. All texture paths live in
the resource; gameplay collision and tile HP remain in simulation.

Source images, prompts and processing reports: `assets/generated/map/industrial/`.
`manifest.json` records runtime sizes, source SHA-256 and alpha bounds. Damage
decals are hand-authored SVGs, separate from generated masonry artwork.

Replacement, repro steps and QA: [map-art](../features/map/art.md).

## Scene và atlas sau refactor

Layout hiện hành là `scenes/maps/industrial_yard.tscn`; TileSet `assets/maps/industrial/terrain.tres` dùng atlas dẫn xuất 40 units từ bộ PNG này. Script tái tạo ở `assets/maps/industrial/source/build_atlas.gd`. Object hiện hành là PNG alpha ở `assets/map_objects/industrial/`, có Resource/scene dùng lại và flags riêng; machinery/robot wreck chặn di chuyển/đạn, pipes chỉ chặn di chuyển, drink can không chặn gì. Xem [object môi trường](../features/map/environment-objects.md). Bộ nguồn generation và manifest PNG hiện có vẫn được giữ vì atlas và overlay đang phụ thuộc chúng. Xem [biên soạn map](../features/map/authoring.md) và [artwork runtime](../features/map/art.md).

Bố cục hiện tại ở [thiết kế nhà máy](../features/map/industrial-layout.md): ống đơn dọc nối bơm thay cho các object lặp, không còn cell grass trong scene. PNG/TileSet/source grass vẫn được giữ cho map khác.
