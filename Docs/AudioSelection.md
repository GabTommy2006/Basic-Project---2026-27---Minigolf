# Bộ âm thanh đã duyệt

Đã duyệt và tích hợp **13 file âm thanh** vào `Assets/Audio/`. Bản nghe thử và nguồn gốc vẫn được giữ trong `ArtDrafts/AudioReview/Selected/`. Mọi file giữ nguyên nội dung gốc; tên file được đổi cho dễ nhận biết.

Nhấn **F5** để chơi có âm thanh. Nhạc nền Sherwood lặp xuyên suốt menu và các màn, chuyển nhỏ dần khi chơi, pause hoặc hiện kết quả. Settings chỉnh riêng Music và Sound; đặt về 0 để tắt từng nhóm.

`Game/audio_director.gd` giới hạn tối đa 12 tiếng hiệu ứng đồng thời, chống phát dồn khi va tường/bumper/cổng. Tiếng gameplay tạm dừng cùng pause; UI và nhạc vẫn hoạt động. Cổng ở cách bóng hơn 128 pixel thế giới không phát tiếng để tránh làm ồn sân. Đổi màn không khởi động lại bản nhạc.

## Nghe thử

Mở **`Tools/Audio/Review.tscn`** trong Godot và nhấn **F6**. Bấm tên âm thanh để nghe; Stop dừng phát, thanh âm lượng dành riêng cho nghe thử. Đây là scene công cụ riêng, không nằm trong menu game.

Các ứng viên:

1. `menu_click.ogg` — bấm nút: Kenney Interface Sounds, click_003.
2. `menu_back.ogg` — quay lại: Kenney Interface Sounds, back_002.
3. `golf_shot.ogg` — đánh bóng: Kenney Impact Sounds, impactWood_light_000.
4. `wall_contact.ogg` — va chạm tường: Kenney Impact Sounds, impactSoft_medium_000.
5. `bumper_hit.ogg` — bumper: Kenney Impact Sounds, impactMetal_medium_000.
6. `arrow_boost.ogg` — tăng tốc mũi tên: Kenney Interface Sounds, maximize_004.
7. `portal_travel.ogg` — dịch chuyển: Kenney Interface Sounds, open_003.
8. `gate_switch.ogg` — cổng đóng/mở: Kenney RPG Audio, metalLatch.
9. `water_splash.ogg` — rơi nước: rubberduck, splash_02.
10. `hole_capture.ogg` — vào lỗ: Kenney Interface Sounds, drop_003.
11. `star_reward.ogg` — nhận sao: Kenney Interface Sounds, confirmation_002.
12. `course_complete.ogg` — hoàn thành màn: Kenney Music Jingles, jingles_PIZZI00.
13. `music_sherwood.ogg` — nhạc nền thử: Sherwood, Chris Murphy/zesona; bản nhạc được tác giả mô tả là loop nhẹ nhàng.

Các hiệu ứng có mức âm lượng riêng: va tường, bumper và cổng được đặt nhỏ hơn tiếng đánh bóng. Ghi công và giấy phép được chép kèm vào `Assets/Audio/CREDITS.md` và `Assets/Audio/Licenses/`.

## Nguồn và giấy phép

Từng trang nguồn dưới đây công bố **CC0**; cho phép dùng trong dự án thương mại. Bản license gốc Kenney và ghi nhận nguồn OpenGameArt nằm trong `ArtDrafts/AudioReview/Licenses/`. Dù CC0 không bắt buộc ghi công, nên giữ các tên tác giả trong Credits.

- [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds)
- [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds)
- [Kenney RPG Audio](https://kenney.nl/assets/rpg-audio)
- [Kenney Music Jingles](https://kenney.nl/assets/music-jingles)
- [40 CC0 water / splash / slime SFX — rubberduck](https://opengameart.org/content/40-cc0-water-splash-slime-sfx)
- [Sherwood — Chris Murphy/zesona](https://opengameart.org/content/sherwood)
- [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)

Đã xác minh/tải và duyệt ngày 28/10/2026. `Assets/Audio/manifest.json` ghi nguồn, tên gốc, SHA-256 và trạng thái đã duyệt của từng file. Các ZIP và bản gốc được giữ trong `ArtDrafts/AudioReview/`, bên dưới `.gdignore` của ArtDrafts; chỉ bộ được chọn trong Assets được game sử dụng.
