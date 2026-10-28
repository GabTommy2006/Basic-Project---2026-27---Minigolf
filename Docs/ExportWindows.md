# Bản Windows chạy độc lập

Đầu ra hiện tại: `output/Windows/SummerMinigolf.exe` (Windows x64, Release).
Tài nguyên game được nhúng trong EXE, không cần file PCK riêng hoặc cài Godot.
Gói gửi đi: `output/SummerMinigolf-Windows-x64.zip`, kèm hướng dẫn và giấy phép.

## Xuất lại sau khi sửa game

Mở **Project → Export → Windows Desktop → Export Project**, bỏ chọn **Export With Debug**.
Preset và đường dẫn đầu ra đã được lưu trong `export_presets.cfg`.

Hoặc chạy từ thư mục project:

```powershell
& 'C:\Program Files\Godot_v4.7.2-stable_win64.exe' --headless --path . --export-release 'Windows Desktop' 'output/Windows/SummerMinigolf.exe'
```

Preset dùng template chính thức 4.7.2 trong `tmp/export-templates/4.7.2.stable/`.
Nếu chuyển project sang máy khác hoặc xóa tmp, cài export template đúng phiên bản Godot,
rồi xóa hai đường dẫn Custom Template trong preset để dùng template đã cài trên máy đó.
Nguồn tải và checksum của các thành phần đã tải nằm trong `tmp/export-templates/4.7.2.stable/source.json`.

`Game/courses.json` được đưa vào gói để giữ luật sao. Bản xuất không kèm Tests, Tools,
ArtDrafts, Docs, file lưu cá nhân hoặc các bản xem thử. Khi đóng gói lại ZIP, giữ thư mục Licenses
đã chép kèm trong output/Windows.

Bản EXE dùng cùng tên ứng dụng và thư mục lưu như khi chạy F5 trên cùng máy.
Không đổi tên ứng dụng trong project chỉ để đổi tên file EXE, vì có thể làm đổi thư mục lưu.

## Kiểm tra bản xuất

Đã chạy EXE Release bằng renderer D3D12 mặc định, tải cả 10 map, đánh thắng màn 1,
ghi sao/kỷ lục, mở lại từ một tiến trình khác và xác nhận New Game/Cancel.
Kiểm tra dùng bản sao EXE trong `tmp/export-check/` và hồ sơ QA riêng.

`Tests/export_build_smoke.gd` được gắn vào scene QA bên ngoài qua override.cfg cạnh bản sao EXE.
Template Release không hỗ trợ --script; không dùng tùy chọn đó để kết luận rằng bài test đã chạy.
Các lần chạy phải có marker `EXPORT_BUILD_RESULT ... failures=0` và không có lỗi trong stderr.
Không chép override.cfg hoặc scene QA vào thư mục phát hành.

Tài liệu chính thức: [Windows export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_windows.html),
[Godot 4.7.2](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable).
