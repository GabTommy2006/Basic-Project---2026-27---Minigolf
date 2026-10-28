# SummerUI v2 — khung sắt, lưới 16 px

Bản này thay giao diện gỗ dày bằng khung sắt gọn, dùng đúng các màu đang có trong SummerTile. Không thay scene, script hoặc tài nguyên đang dùng trong game.

## Thiết kế

- Viền ngoài **1 px** màu `#2A2D36`, nét sáng/tối **1 px**. Tổng bề dày bảo vệ khi kéo giãn: **2 px mỗi cạnh**.
- Mặt thép `#A1A1AA` / `#E4E4E7`, bóng `#6C717D` / `#484C57`.
- Đỏ `#B91C1C` dùng cho nút chính và trạng thái chọn, đồng bộ chi tiết đỏ–trắng trong SummerTile. Sao và lực đánh giữ màu vàng riêng để phân biệt chức năng.
- Không có họa tiết vân gỗ, viền kem dày hoặc hoạt ảnh trang trí.
- Background giữ bố cục bản v1 bạn chọn; chỉ đổi phần khung sân từ gỗ sang thép. Hình 320 × 180 được thêm **12 px trong suốt ở dưới** để canvas thành 320 × 192, không kéo giãn hoặc đổi vị trí hình. AtlasTexture background đã cắt đúng phần 320 × 180 khi dùng làm nền màn hình.

## Quy chuẩn tile

SummerTile gốc có grid 16 × 16 px. Bản v2 dùng đúng grid đó trong Aseprite và khi xuất atlas:

- Tọa độ **x/y** của mọi vùng là bội số của **16**.
- Chiều rộng/cao của mọi PNG là bội số của **16**.
- Các vùng cách nhau ít nhất một ô trống 16 px, không trim từng trạng thái.
- Trạng thái của cùng một món có cùng canvas và vị trí neo.
- Những hình nhỏ như sao 8 px hoặc khóa 12 px nằm giữa một ô 16 px. `content_rect` trong JSON ghi rõ phần hình thật, không cần phóng méo để lấp đầy ô.

Các kích thước mới: nút 96 × 16; nút icon 16 × 16; panel 32 × 32; HUD 96 × 32; ô level 48 × 48; logo 112 × 32; vỏ/ruột lực và âm lượng 96 × 16; tay nắm, checkbox, khóa, sao và icon đều dùng canvas 16 × 16; hướng dẫn 48 × 32; bảng tiêu đề 112 × 32; background 320 × 192 có vùng hình 320 × 180.

## File nguồn

- `SummerUI-v2.aseprite`: master sheet **512 × 512**, grid **16 × 16**, mỗi hình/trạng thái trên một layer riêng.
- `sources/`: **24 file Aseprite** theo từng nhóm. Các frame/tag normal/hover/pressed… là trạng thái chọn, không phải animation tự chạy.
- `png/`: **55 PNG** kích thước gốc 1×, giữ khoảng trong suốt cần thiết.
- `SummerUI-v2.png` / `SummerUI-v2.json`: atlas và tọa độ pixel/tile, số cột/hàng mỗi hình, phần hình thật và lề NinePatch.
- `SummerTile.gpl`: đủ 43 màu có trong file SummerTile gốc.
- `previews/`: ảnh ghép để xem hình và sheet có phủ lưới 16 px. Đường lưới, chữ/số minh họa không nằm trong PNG dùng cho game.

## Dùng trong Godot

1. Khi muốn tích hợp, chép cả thư mục **SummerUI-v2** vào **`Assets/UI/SummerUI-v2`** của project. Không chép vào thư mục có `.gdignore`. Chưa có bước này trong game hiện tại.
2. `godot/regions/*.tres` là các **AtlasTexture** đã cắt đúng vùng. Các đường dẫn đã đặt theo vị trí ở bước 1.
3. `godot/styles/*.tres` là **StyleBoxTexture** cho nút/panel: texture margin **2 px** mỗi cạnh. Có thể gắn normal/hover/pressed/disabled vào Theme của Button.
4. Dùng **Control, Button, TextureButton, NinePatchRect** cho UI. UI không cần đặt bằng TileMap chỉ vì dùng ảnh theo lưới 16 px; vị trí Control vẫn có thể căn giữa bằng container/anchor.
5. Nếu cần dùng như TileSet, mở **`godot/tileset_16.tres`**: ô texture 16 × 16, margins 0, separation 0, mỗi món đã được định nghĩa theo số ô mà nó chiếm. Ô trống giữa các món đã nằm trong ảnh, không nhập separation 16.
6. Giữ **Nearest**, scale nguyên; không bật filter Linear hoặc mipmap cho bộ pixel art này.
7. Ruột lực/âm lượng có cùng canvas với vỏ; ghép chúng cùng tọa độ, cắt phần ruột theo tỷ lệ rồi vẽ vỏ lên trên. Các `content_rect` trong JSON chỉ rõ phần ruột 92 × 12 hoặc 92 × 4.
8. Chữ/số nằm trong Godot Label/font; chỉ logo có chữ vẽ sẵn. Hình hướng dẫn, đầu ngắm, vòng bóng và thanh lực vẫn tùy chọn, không thay cơ chế kéo–thả đang có.

Các file `.tres` được kiểm tra bằng một project Godot riêng; không cần sửa project chính để duyệt bộ hình.

Đã kiểm tra trong **Godot 4.7.2**: nạp đủ **55 AtlasTexture, 21 StyleBoxTexture và 55 tile nhiều ô**; kích thước và lề viền đều đúng. Palette, alpha, canvas trạng thái, khoảng cách và tọa độ trên lưới 16 px được kiểm tra thêm độc lập bằng script.
