# BÁO CÁO ĐỒ ÁN CƠ SỞ

## XÂY DỰNG GAME MINI-GOLF 2D BẰNG GODOT ENGINE

**Sinh viên thực hiện:** GabTommy2006  
**Môn học:** Đồ án cơ sở  
**Năm học:** 2026–2027  
**Công cụ phát triển:** Godot Engine 4.7.2, GDScript, Aseprite  
**Nền tảng mục tiêu:** Windows x64  

---

# LỜI CAM ĐOAN

Em cam đoan báo cáo này trình bày quá trình phân tích, thiết kế, triển khai và kiểm thử sản phẩm game Mini-golf 2D được thực hiện trong khuôn khổ đồ án cơ sở. Các nội dung mô tả về mã nguồn, cấu trúc thư mục, cơ chế gameplay, tài nguyên âm thanh, tài nguyên giao diện và kết quả kiểm thử được đối chiếu với repository của dự án tại thời điểm hoàn thiện báo cáo. Những kiến thức lý thuyết, tài liệu kỹ thuật và nguồn tham khảo của các tác giả khác đều được ghi nhận bằng hình thức trích dẫn IEEE trong nội dung và danh mục tài liệu tham khảo.

# LỜI CẢM ƠN

Em xin cảm ơn giảng viên phụ trách học phần đã hướng dẫn phương pháp thực hiện đồ án, xây dựng báo cáo và đánh giá sản phẩm theo hướng kỹ thuật. Em cũng xin cảm ơn cộng đồng Godot, các tác giả tài nguyên âm thanh và các tác giả tài liệu chuyên ngành đã cung cấp những nguồn tham khảo cần thiết cho quá trình nghiên cứu. Trong quá trình thực hiện, dự án được phát triển và kiểm thử nhiều lần; những sai sót còn tồn tại trong báo cáo và sản phẩm là trách nhiệm của người thực hiện.

# TÓM TẮT

Đề tài trình bày quá trình xây dựng một game Mini-golf 2D bằng Godot Engine và GDScript. Người chơi điều khiển bóng bằng thao tác kéo chuột ngược hướng mong muốn, sau đó thả chuột để tạo cú đánh. Hệ thống mô phỏng chuyển động của bóng, sự giảm tốc trên các loại địa hình, phản xạ với vật cản, hiệu ứng bumper, ô mũi tên, vùng nước, portal, lỗ golf và các vật cản chuyển động. Sản phẩm gồm mười course được thiết kế thủ công, có cơ chế mở khóa tuần tự, chấm điểm bằng số gậy và số sao, giao diện menu, HUD, pause, settings, màn hình kết quả, âm thanh và lưu tiến trình.

Về mặt kỹ thuật, đề tài áp dụng mô hình vòng lặp game, cập nhật vật lý theo bước thời gian, biểu diễn chuyển động bằng vector, phản xạ vector theo pháp tuyến, Continuous Collision Detection, máy trạng thái hữu hạn, kiến trúc hướng sự kiện, thiết kế dựa trên dữ liệu và cơ chế lưu có bản sao phục hồi. Tài nguyên giao diện được thiết kế bằng Aseprite theo lưới cơ sở 16×16 pixel, sau đó tích hợp vào Godot bằng AtlasTexture và StyleBoxTexture. Hệ thống được kiểm thử bằng các script headless với 13 nhóm kiểm thử, 8 giai đoạn kiểm tra khởi động lại, 80 phiên mô phỏng và 301 cú đánh trong các kịch bản đã định nghĩa.

**Từ khóa:** game 2D, mini-golf, Godot, GDScript, vật lý 2D, pixel-art, Aseprite, máy trạng thái, kiểm thử game.

# DANH MỤC HÌNH

Hình 1.1. Quy trình tương tác cơ bản của người chơi với game.  
Hình 2.1. Mô hình vòng lặp game và vòng lặp vật lý.  
Hình 2.2. Quan hệ giữa vector kéo, hướng đánh và vận tốc bóng.  
Hình 3.1. Kiến trúc tổng quát của hệ thống.  
Hình 3.2. Luồng xử lý một cú đánh.  
Hình 3.3. Máy trạng thái của blinking gate.  
Hình 3.4. Luồng xử lý portal theo cơ chế deferred physics.  
Hình 4.1. Giao diện menu chính.  
Hình 4.2. Giao diện chọn course.  
Hình 4.3. HUD trong quá trình chơi.  
Hình 4.4. Màn hình kết quả course.  
Hình 4.5. Quy trình từ Aseprite đến resource Godot.  
Hình 4.6. Sơ đồ bus âm thanh Music và SFX.  
Hình 5.1. Quy trình chạy bộ kiểm thử headless.  
Hình 6.1. Mô hình mở rộng dự kiến của hệ thống.

# DANH MỤC BẢNG

Bảng 1.1. Phạm vi chức năng của đề tài.  
Bảng 2.1. Các khái niệm lý thuyết được áp dụng.  
Bảng 3.1. Các module chính của hệ thống.  
Bảng 3.2. Các trạng thái của blinking gate.  
Bảng 4.1. Các thông số vật lý chính của bóng.  
Bảng 4.2. Kích thước tiêu biểu của bộ giao diện SummerUI v2.  
Bảng 4.3. Các nhóm tài nguyên âm thanh.  
Bảng 5.1. Các nhóm kiểm thử của project.  
Bảng 5.2. Kết quả kiểm thử tổng hợp.  
Bảng 6.1. Hạn chế và hướng phát triển.

# DANH MỤC TỪ VIẾT TẮT

**API**: Application Programming Interface.  
**CCD**: Continuous Collision Detection.  
**CPU**: Central Processing Unit.  
**FPS**: Frames Per Second.  
**HUD**: Heads-Up Display.  
**JSON**: JavaScript Object Notation.  
**NPC**: Non-Player Character.  
**QA**: Quality Assurance.  
**SFX**: Sound Effects.  
**UI**: User Interface.  
**URL**: Uniform Resource Locator.  
**VFX**: Visual Effects.

# CHƯƠNG 1. GIỚI THIỆU

## 1.1. Đặt vấn đề

Game là một loại phần mềm có yêu cầu đặc thù vì chương trình không chỉ xử lý dữ liệu mà còn phải phản hồi liên tục với thao tác của người dùng, cập nhật trạng thái theo thời gian thực và tạo ra phản hồi trực quan bằng hình ảnh, âm thanh và chuyển động. Một game 2D quy mô nhỏ vẫn đòi hỏi sự kết hợp giữa lập trình, đồ họa máy tính, mô phỏng vật lý, thiết kế giao diện, quản lý tài nguyên và kiểm thử. Vì vậy, việc xây dựng một sản phẩm game hoàn chỉnh là môi trường phù hợp để vận dụng kiến thức lập trình vào một hệ thống có tính tương tác cao.

Mini-golf là một thể loại trò chơi có luật chơi dễ tiếp cận nhưng chứa nhiều vấn đề kỹ thuật đáng nghiên cứu. Người chơi phải xác định hướng đánh, điều chỉnh lực và dự đoán kết quả dựa trên địa hình cũng như vị trí vật cản. Trong phiên bản số, thao tác kéo-thả cần được chuyển thành vector vận tốc; bóng phải giảm tốc ổn định; va chạm phải tạo ra phản xạ hợp lý; bóng không được xuyên qua tường khi vận tốc cao; các cơ chế như bumper, portal và nước phải được xử lý theo đúng thứ tự trong vòng lặp vật lý.

Đề tài “Xây dựng game Mini-golf 2D bằng Godot Engine” được thực hiện nhằm tạo ra một sản phẩm game có thể chạy độc lập trên Windows x64, đồng thời làm rõ cách áp dụng các nguyên lý kỹ thuật vào quá trình phát triển. Sản phẩm được xây dựng bằng Godot Engine 4.7.2 và GDScript, gồm mười course thiết kế thủ công, các loại địa hình cỏ và cát, vùng nước, ô mũi tên, bumper tròn và tam giác, vật cản quay, vật cản di chuyển, blinking gate, portal liên kết, giao diện quản lý game, âm thanh và hệ thống lưu tiến trình.

## 1.2. Mục tiêu

Mục tiêu tổng quát của đề tài là xây dựng một game mini-golf 2D có gameplay rõ ràng, phản hồi điều khiển ổn định và kiến trúc đủ tách biệt để có thể mở rộng. Mục tiêu cụ thể là triển khai cơ chế kéo-thả để tạo cú đánh, mô phỏng chuyển động và giảm tốc của bóng, xử lý va chạm và phản xạ, xây dựng course có mức độ khó tăng dần, cung cấp hệ thống chấm điểm bằng số gậy và sao, tích hợp giao diện, âm thanh, lưu dữ liệu và kiểm thử hồi quy.

Đề tài đồng thời nghiên cứu quy trình tạo asset pixel-art bằng Aseprite. Các thành phần giao diện được thiết kế theo lưới cơ sở 16×16 pixel, nhưng kích thước canvas được thay đổi theo loại asset. Sau khi xuất ảnh, tài nguyên được đưa vào Godot dưới dạng texture region, atlas và style box để có thể tái sử dụng trong nhiều màn hình.

## 1.3. Câu hỏi nghiên cứu

Đề tài trả lời câu hỏi làm thế nào để chuyển thao tác kéo-thả chuột thành một cú đánh có hướng và lực phù hợp; làm thế nào để mô phỏng sự khác biệt giữa cỏ và cát bằng mô hình giảm tốc đơn giản; làm thế nào để xử lý phản xạ của bóng theo pháp tuyến va chạm; và làm thế nào để hạn chế lỗi xuyên vật cản khi bóng di chuyển nhanh. Bên cạnh đó, đề tài nghiên cứu cách tổ chức các cơ chế độc lập bằng signal, máy trạng thái và thiết kế dựa trên dữ liệu; cách xử lý việc dịch chuyển bóng qua portal trong đúng bước vật lý; cũng như cách lưu dữ liệu có checksum, file tạm và bản sao phục hồi.

## 1.4. Đối tượng và phạm vi

Đối tượng nghiên cứu là một game 2D dành cho một người chơi, trong đó quả bóng là đối tượng vật lý trung tâm. Phạm vi của sản phẩm bao gồm mười course, menu chính, chọn course, HUD, pause, settings, màn hình kết quả, âm thanh, lưu tiến trình và bộ kiểm thử tự động. Phiên bản hiện tại chưa bao gồm multiplayer trực tuyến, bảng xếp hạng online, replay, trí tuệ nhân tạo, trình chỉnh sửa course tích hợp trong game hoặc mô phỏng đầy đủ độ dốc của sân ngoài đời thực.

## 1.5. Đóng góp của đề tài

Đóng góp chính của đề tài là một sản phẩm game hoàn chỉnh có thể chạy trên Windows x64 và một quy trình triển khai có thể dùng làm tài liệu tham khảo cho các dự án game 2D tương tự. Đề tài thể hiện việc áp dụng vòng lặp vật lý, vector, phản xạ, CCD, máy trạng thái, signal, data-driven design, audio bus, pixel-art pipeline và kiểm thử headless trong cùng một hệ thống. Những kết quả này được mô tả dựa trên mã nguồn và tài liệu của repository thay vì chỉ trình bày ở mức ý tưởng.

# CHƯƠNG 2. CƠ SỞ LÝ THUYẾT

## 2.1. Godot Engine và mô hình Scene/Node

Godot là một game engine mã nguồn mở hỗ trợ phát triển game 2D và 3D. Thành phần cơ bản của Godot là Node. Nhiều Node có thể được tổ chức thành một Scene, trong đó Scene có thể được lưu lại, tái sử dụng và tạo instance ở nhiều vị trí khác nhau [1]. Mô hình này phù hợp với project vì các đối tượng như bóng, lỗ, bumper, portal và vật cản có thể được xây dựng độc lập, sau đó đặt vào nhiều course.

Trong project, mã nguồn được chia thành các nhóm tương ứng với trách nhiệm của hệ thống. Thư mục `Objects` chứa bóng, lỗ, bumper, portal và vật cản. Thư mục `Maps/Courses` chứa mười course. Thư mục `UI` chứa menu, HUD, settings và màn hình kết quả. Thư mục `Game` chứa course catalog, save system và audio director. Sự phân chia này thể hiện nguyên tắc tách trách nhiệm, làm cho việc thay đổi một module ít ảnh hưởng đến các module còn lại.

## 2.2. Vòng lặp game và bước thời gian

Game thời gian thực thường lặp lại quá trình nhận input, cập nhật trạng thái và kết xuất hình ảnh. Tuy nhiên, cập nhật vật lý cần có bước thời gian ổn định để kết quả không phụ thuộc quá mạnh vào tốc độ khung hình. Godot phân biệt xử lý frame thông thường bằng `_process(delta)` và xử lý vật lý bằng `_physics_process(delta)` hoặc `_integrate_forces(state)`. Glenn Fiedler chỉ ra rằng việc sử dụng bước thời gian cố định giúp mô phỏng vật lý ổn định hơn và hạn chế sự phụ thuộc vào FPS [5].

Project sử dụng `_integrate_forces(state)` trong `ball.gd` để thay đổi vận tốc, vị trí và trạng thái của `RigidBody2D` tại thời điểm phù hợp. Các thao tác từ chuột chỉ tạo ra một vận tốc chờ; vận tốc này được áp dụng trong bước vật lý kế tiếp. Cách làm này tránh việc thay đổi trạng thái vật lý trực tiếp trong callback của giao diện hoặc trong thời điểm không an toàn.

## 2.3. Vector và mô hình cú đánh

Vector là công cụ toán học dùng để biểu diễn đại lượng có hướng và độ lớn. Trong game mini-golf, vector kéo được hình thành từ vị trí chuột hiện tại và vị trí bắt đầu kéo. Với \(\vec{p}_0\) là vị trí bắt đầu và \(\vec{p}_1\) là vị trí hiện tại, vector kéo được xác định bởi:

\[
\vec{d}=\vec{p}_1-\vec{p}_0.
\]

Để bóng đi ngược hướng kéo, vận tốc được tính theo:

\[
\vec{v}=-\frac{\operatorname{limit}(\vec{d},d_{\max})}{d_{\max}}v_{\max}.
\]

Trong đó \(d_{\max}\) là khoảng kéo tối đa và \(v_{\max}\) là vận tốc cú đánh tối đa. Project giới hạn khoảng kéo bằng `max_drag_distance` và giới hạn vận tốc bằng `max_shot_speed`. Cú kéo dưới hai pixel được xem là thao tác nhấp chuột và không tạo ra cú đánh.

## 2.4. Giảm tốc và địa hình

Bóng không sử dụng damping tự động của `RigidBody2D`; thay vào đó, script chủ động đưa vận tốc về vector không bằng hàm `move_toward`. Mô hình được biểu diễn bởi:

\[
\vec{v}_{t+\Delta t}=
\operatorname{MoveToward}(\vec{v}_t,\vec{0},a\Delta t).
\]

Đối với cỏ, project sử dụng mức giảm tốc mặc định 40 pixel/giây². Đối với cát, mức giảm tốc mặc định là 240 pixel/giây², tức lớn hơn sáu lần so với cỏ. Đây là mô hình đơn giản hóa ma sát, nhưng tạo ra khác biệt gameplay rõ ràng và dễ điều chỉnh. TileMap lưu loại mặt sân trong Custom Data với trường `surface_layer`, nhờ đó code không cần gắn script riêng cho từng ô.

## 2.5. Va chạm và phản xạ

Khi một vật thể va chạm với bề mặt, hướng chuyển động sau va chạm phụ thuộc vào pháp tuyến của bề mặt. Công thức phản xạ vector là:

\[
\vec{r}=\vec{v}-2(\vec{v}\cdot\vec{n})\vec{n}.
\]

Trong đó \(\vec{v}\) là vận tốc trước va chạm, \(\vec{n}\) là pháp tuyến đơn vị và \(\vec{r}\) là vector sau phản xạ. Công thức này là nền tảng của nhiều hệ thống phản xạ trong game vật lý [2], [6]. Project lấy thông tin tiếp xúc thật từ `PhysicsDirectBodyState2D`, sau đó sử dụng pháp tuyến để xử lý bumper tròn và bumper tam giác.

Bumper còn có hệ số tăng tốc, giới hạn vận tốc nhỏ nhất và lớn nhất, cùng cooldown để tránh việc một tiếp xúc kéo dài tạo ra nhiều lần tăng lực. Dictionary `_bumper_contacts` và `_bumper_cooldowns` được sử dụng để phân biệt một lần chạm mới với trạng thái bóng đang rung tại cùng một cạnh.

## 2.6. Continuous Collision Detection

Mô phỏng va chạm rời rạc có thể bỏ qua một vật cản nếu bóng đi quá xa giữa hai bước vật lý. Hiện tượng này thường được gọi là tunneling. Continuous Collision Detection giải quyết vấn đề bằng cách kiểm tra quãng đường quét của vật thể thay vì chỉ kiểm tra vị trí ở cuối bước [2], [6]. Project bật CCD cast shape cho quả bóng, đặc biệt cần thiết khi vận tốc cú đánh cao hoặc khoảng cách giữa các collider nhỏ.

## 2.7. Máy trạng thái hữu hạn

Máy trạng thái hữu hạn mô tả một đối tượng bằng tập trạng thái hữu hạn và các điều kiện chuyển đổi. Blinking gate trong project có các trạng thái ẩn, fading in, solid và fading out. Mỗi trạng thái quyết định mức hiển thị và trạng thái collider. Khi gate đang mờ dần hoặc hiện dần, hình ảnh có thể thay đổi nhưng collider chưa nhất thiết được bật. Khi đạt trạng thái solid, gate mới thực sự chặn bóng.

Cách triển khai này gần với State Pattern, trong đó hành vi của đối tượng được phân chia theo trạng thái thay vì tập trung toàn bộ điều kiện vào một hàm lớn [4]. Nó giúp tránh lỗi collider xuất hiện trước hình ảnh và làm cho chu kỳ đóng mở có thể kiểm thử độc lập.

## 2.8. Kiến trúc hướng sự kiện

Signal của Godot cung cấp cơ chế để một đối tượng phát thông báo mà không cần biết trực tiếp đối tượng nhận. Trong project, bóng phát `stroke_count_changed` để HUD cập nhật số gậy và phát `sound_requested` để Audio Director phát hiệu ứng. Cách tổ chức này làm giảm sự phụ thuộc giữa gameplay và giao diện hoặc âm thanh.

Event-driven architecture phù hợp với các hệ thống có nhiều phản hồi liên quan đến cùng một sự kiện. Một cú đánh có thể đồng thời làm tăng số gậy, phát âm thanh, cập nhật thanh Power và thay đổi trạng thái camera; signal giúp các thành phần xử lý các phản hồi riêng mà không cần đưa toàn bộ logic vào `Ball`.

## 2.9. Âm thanh trong game

Âm thanh trong game có vai trò cung cấp phản hồi cho hành động, xác nhận trạng thái và tạo nhịp điệu trải nghiệm. Karen Collins phân biệt âm thanh tương tác, âm thanh môi trường, hiệu ứng và âm nhạc trong thiết kế game [8]. Project tách bus Music và SFX, cho phép điều chỉnh âm lượng độc lập. Audio Director dùng danh sách effect players có giới hạn và cooldown để tránh phát dồn quá nhiều âm thanh trong một thời điểm.

## 2.10. Pixel-art và quản lý tài nguyên

Pixel-art yêu cầu sự nhất quán về lưới, kích thước pixel, màu sắc và điểm neo. Project dùng Aseprite để thiết kế bộ SummerUI v2 theo lưới cơ sở 16×16 pixel. Master sheet `SummerUI-v2.aseprite` có kích thước 512×512 pixel. Kích thước asset có thể là 16×16, 32×32, 48×48, 96×16 hoặc các kích thước lớn hơn nhưng vẫn được căn theo bội số của 16.

Asset sau khi xuất được tích hợp vào Godot bằng AtlasTexture và StyleBoxTexture. Atlas giúp nhiều vùng ảnh được quản lý trong cùng một bộ tài nguyên, còn StyleBoxTexture phù hợp với panel và khung có thể kéo giãn. Việc dùng nearest filtering và scale nguyên giúp hạn chế hiện tượng làm mờ hoặc lệch pixel.

# CHƯƠNG 3. PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG

## 3.1. Yêu cầu chức năng

Hệ thống phải cho phép người chơi mở game, xem menu, chọn course đã mở khóa, điều khiển bóng, tạm dừng, khởi động lại, hoàn thành course và xem kết quả. Khi hoàn thành một course, game phải tính số gậy, số sao, mở khóa course tiếp theo và lưu kết quả tốt nhất. Người chơi có thể điều chỉnh âm lượng và chế độ fullscreen.

Hệ thống phải hỗ trợ các cơ chế gameplay gồm cỏ, cát, nước, mũi tên, bumper, vật cản quay, vật cản di chuyển, blinking gate, portal và lỗ golf. Bóng phải không nhận cú đánh mới khi đang di chuyển, đang chìm, đã vào lỗ hoặc đang trong hiệu ứng đặc biệt.

## 3.2. Yêu cầu phi chức năng

Game cần phản hồi thao tác với độ trễ thấp, giữ hình ảnh pixel-art sắc nét, không làm mất dữ liệu tiến trình khi quá trình ghi bị gián đoạn và có thể chạy trong nhiều kích thước cửa sổ. Mã nguồn cần được tổ chức theo module, có thể kiểm thử độc lập và không phụ thuộc vào dữ liệu save thật của người chơi trong quá trình QA.

## 3.3. Kiến trúc tổng quát

Kiến trúc được chia thành lớp điều phối game, lớp gameplay, lớp giao diện, lớp âm thanh, lớp lưu dữ liệu và lớp tài nguyên. `GameApp` điều phối chuyển màn hình và course. `Ball` là trung tâm của mô phỏng vật lý. `Hole`, `Bumper`, `Portal` và các obstacle cung cấp các cơ chế tương tác riêng. `ProgressStore` lưu tiến trình. `AudioDirector` nhận cue từ gameplay và phát nhạc hoặc hiệu ứng.

Sự phân chia này không phải là mô hình MVC thuần túy, nhưng có cùng mục tiêu tách dữ liệu, logic và hiển thị. Các course chứa dữ liệu bố trí object, còn logic chung nằm trong scene và script được tái sử dụng.

## 3.4. Luồng xử lý một cú đánh

Khi người chơi nhấn chuột gần bóng, hệ thống kiểm tra bóng đã đứng yên, chưa vào lỗ, chưa chìm nước và không có cú đánh chờ hay chưa. Nếu hợp lệ, hệ thống lưu vị trí bắt đầu kéo. Trong quá trình rê chuột, vector kéo được cập nhật và giới hạn chiều dài. Khi thả chuột, nếu khoảng kéo đủ lớn, hệ thống tạo `_pending_shot`.

Trong bước vật lý kế tiếp, `_integrate_forces` lưu vị trí trước cú đánh, áp dụng vận tốc, xóa vận tốc chờ, tăng `stroke_count`, phát signal và yêu cầu Audio Director phát tiếng đánh bóng. Sau đó bóng tiếp tục được xử lý giảm tốc, va chạm, bumper, tường và mũi tên.

## 3.5. Điều kiện nhận bóng vào lỗ

Hole không nhận bóng chỉ dựa vào việc bóng đi vào vùng `Area2D`. Script kiểm tra tâm bóng nằm trong polygon miệng lỗ và vận tốc nhỏ hơn `max_capture_speed`. Điều kiện tốc độ giúp bóng không bị hút vào lỗ khi chỉ lướt ngang qua với vận tốc cao. Khi hợp lệ, bóng được đánh dấu `is_sunk`, vận tốc được đưa về không, phát hiệu ứng và chuyển sang màn hình kết quả.

## 3.6. Xử lý nước

Khi tâm bóng đi vào vùng nước đủ sâu, bóng được đánh dấu đang xử lý nước, vận tốc bị khóa, gậy phạt được cộng và hiệu ứng chìm được chạy bằng Tween. Vị trí trước cú đánh gần nhất được dùng làm vị trí hồi. Sau khi Tween hoàn tất, bóng được đưa về vị trí đó trong bước vật lý kế tiếp.

Cờ `_was_in_water` ngăn việc cộng phạt ở mọi frame trong khi bóng còn nằm trong nước. Khi bóng trở về khu vực an toàn, cờ được xóa để chuẩn bị cho lượt tương tác sau.

## 3.7. Xử lý portal

Portal dùng `Area2D` để phát hiện bóng. Khi điều kiện hợp lệ, portal không thay đổi vị trí bóng ngay trong callback. Thay vào đó, portal gọi hàm queue travel trên bóng. Hàm này lưu vị trí ra, vận tốc ra, portal nguồn và portal đích. Trong `_integrate_forces`, yêu cầu được kiểm tra lại rồi mới thay đổi transform và vận tốc.

Cơ chế deferred physics bảo đảm việc dịch chuyển xảy ra trong ngữ cảnh vật lý an toàn. Sau khi dịch chuyển, lịch sử mũi tên, tiếp xúc bumper, âm thanh tường và mốc lăn được xóa để không tạo ra một đường di chuyển giả giữa hai vị trí cách xa nhau. Cooldown ngắn ngăn hai portal kéo bóng qua lại vô hạn.

## 3.8. Thiết kế blinking gate

Blinking gate được biểu diễn bằng máy trạng thái. Khi ẩn, sprite không hiển thị và collider không chặn bóng. Khi fading in, sprite tăng alpha nhưng collider vẫn chưa bật. Khi solid, sprite đạt alpha đầy đủ và collider hoạt động. Khi fading out, gate giảm alpha rồi trở về ẩn.

Nếu bóng đang ở vùng gate khi gate chuyển trạng thái, hệ thống phải chờ bóng ra khỏi vùng trước khi đóng collider. Quy tắc này tránh việc gate xuất hiện chồng lên bóng và tạo ra lực đẩy bất thường.

## 3.9. Course catalog và chấm sao

Thông tin course được lưu trong `Game/courses.json` và được đọc bởi `course_catalog.gd`. Mười mục tiêu ba sao lần lượt là 2, 3, 3, 4, 5, 4, 5, 5, 6 và 7 gậy. Người chơi đạt ba sao khi số gậy không vượt mục tiêu; đạt hai sao khi vượt tối đa hai gậy; các kết quả hoàn thành khác nhận một sao.

Khi course hoàn thành, hệ thống chỉ thay thế kỷ lục nếu kết quả mới tốt hơn. Sao đã đạt không bị giảm khi người chơi chơi lại với kết quả kém hơn.

# CHƯƠNG 4. TRIỂN KHAI

## 4.1. Môi trường và cấu trúc project

Project sử dụng Godot 4.7.2, GDScript, renderer Forward+ và Direct3D 12 trên Windows. Game được khởi chạy từ `UI/Main.tscn`. Mười course nằm trong `Maps/Courses/Map1.tscn` đến `Map10.tscn`. Các scene phát triển như `Maps/TestMap.tscn` và `Maps/MechanicsPlayground.tscn` được dùng để kiểm tra cơ chế riêng.

Tài nguyên được chia thành texture, TileSet, font, UI atlas và audio trong thư mục `Assets`. Các script điều phối đặt trong `Game`, giao diện trong `UI`, đối tượng gameplay trong `Objects`, kiểm thử trong `Tests` và công cụ trong `Tools`.

## 4.2. Triển khai quả bóng

`Objects/Ball/ball.gd` kế thừa `RigidBody2D`. Script tắt damping tự động, khóa xoay, bật CCD cast shape và bật contact monitoring. Các thuộc tính export cho phép điều chỉnh vận tốc cú đánh, khoảng kéo, giảm tốc cỏ, giảm tốc cát, bán kính bắt đầu kéo, phạt nước, thời gian chìm và cooldown portal.

Việc dùng thuộc tính export giúp người thiết kế có thể cân bằng gameplay trong Inspector. Tuy nhiên, logic cốt lõi vẫn được giữ trong script, nhờ đó mọi course sử dụng cùng một quy tắc vật lý.

## 4.3. Triển khai TileMap Custom Data

TileSet lưu loại mặt sân trong trường `surface_layer` và hướng mũi tên trong trường `arrow_direction`. Khi bóng di chuyển, script đọc ô tại tâm bóng. Đối với mũi tên, hệ thống không chỉ kiểm tra ô ở vị trí cuối frame mà còn quét đoạn từ vị trí trước đến vị trí hiện tại. Cách làm này bảo đảm bóng nhanh không bỏ qua mũi tên chỉ vì đi qua toàn bộ tile giữa hai frame.

Mũi tên chỉ được kích hoạt khi toàn bộ bóng đã vào tile. Sau khi kích hoạt, vận tốc được đổi hướng và nhân với `arrow_speed_multiplier`. Cờ trạng thái ngăn cùng một mũi tên tăng tốc nhiều lần trong cùng lượt đi.

## 4.4. Triển khai bumper và obstacle

Bumper được thiết kế bằng collider riêng với phần hình ảnh, đặc biệt đối với bumper tam giác. Phần phản xạ sử dụng pháp tuyến tiếp xúc thực tế thay vì dùng vector từ tâm bumper đến bóng. Vật cản quay và di chuyển sử dụng `AnimatableBody2D`, bảo đảm chuyển động của collider được đồng bộ với hệ thống vật lý.

Moving obstacle lưu điểm đầu và điểm cuối, di chuyển qua lại và có thể tạm dừng. Rotating obstacle cập nhật góc quay trong bước vật lý. Blinking gate quản lý riêng sprite, collider và trạng thái chuyển tiếp.

## 4.5. Triển khai UI và camera

Giao diện gồm menu chính, chọn course, HUD, pause, settings, help và result screen. HUD hiển thị số gậy, Power meter, course hiện tại và các thao tác cần thiết. `Maps/course_follow_camera.gd` theo dõi bóng trong giới hạn của course, điều chỉnh zoom và giữ các thành phần quan trọng trong vùng nhìn.

Project sử dụng font `Assets/Minecraft.otf` và bộ SummerUI v2. Tài nguyên được tải thông qua `UI/ui_assets.gd`, trong đó texture region và style box được truy cập từ `Assets/UI/SummerUI-v2/godot/`.

## 4.6. Quy trình asset bằng Aseprite

Asset được thiết kế trong Aseprite trên lưới cơ sở 16×16 pixel. Bộ master sheet có kích thước 512×512 pixel. Các asset nhỏ như icon có thể chiếm một ô 16×16; panel, HUD, nút, ô level và logo sử dụng nhiều ô liền nhau.

Sau khi thiết kế, asset được kiểm tra alpha, màu sắc, kích thước canvas, vị trí neo và trạng thái hover hoặc pressed. PNG được xuất ở tỉ lệ gốc. File JSON mô tả vùng atlas. Trong Godot, các vùng ảnh được tạo thành AtlasTexture và các panel có thể kéo giãn được tạo thành StyleBoxTexture. Quy trình này bảo đảm tài nguyên sử dụng trong runtime tương ứng với bản thiết kế.

Repository ghi nhận bộ SummerUI v2 có 55 PNG, 55 AtlasTexture, 21 StyleBoxTexture và 55 tile nhiều ô theo tài liệu thiết kế. Các con số này được dùng để mô tả phiên bản asset tại thời điểm viết báo cáo, không nên xem là số lượng bất biến nếu bộ tài nguyên tiếp tục được cập nhật.

## 4.7. Triển khai âm thanh

Audio Director quản lý hai bus Music và SFX. Nhạc nền `music_sherwood.ogg` được phát lặp. Các cue gameplay gồm menu click, menu back, golf shot, wall contact, bumper hit, arrow boost, portal travel, gate switching, water splash, hole capture, star reward và course complete.

Manifest của project ghi nhận 13 file âm thanh, nguồn tác giả, URL, giấy phép CC0-1.0, tên file gốc và SHA-256. Các hiệu ứng chủ yếu đến từ Kenney và rubberduck; nhạc nền Sherwood do Chris Murphy, còn được ghi nhận với tên zesona. Việc lưu thông tin license trong repository giúp bảo đảm khả năng truy xuất nguồn tài nguyên.

## 4.8. Triển khai lưu và phục hồi dữ liệu

`Game/progress_store.gd` lưu course đã mở khóa, course gần nhất, điểm tốt nhất, sao, âm lượng nhạc, âm lượng hiệu ứng và trạng thái fullscreen. File chính có dạng `user://summer_golf.cfg`. Khi lưu, hệ thống ghi vào file `.tmp`, đọc lại để xác minh, đổi tên thành file chính và sao chép thành `.bak`.

Payload được ghi kèm version, revision và checksum SHA-256. Khi tải, hệ thống kiểm tra file chính, file backup và file tạm; nếu file chính hỏng nhưng bản backup hợp lệ, bản có revision mới nhất được chọn. Nếu dữ liệu thuộc version tương lai, hệ thống chuyển sang chế độ read-only thay vì ghi đè không an toàn. Cách tiếp cận này thể hiện nguyên tắc fail-safe trong quản lý dữ liệu.

# CHƯƠNG 5. KIỂM THỬ VÀ ĐÁNH GIÁ

## 5.1. Chiến lược kiểm thử

Project sử dụng kiểm thử tự động bằng các script Godot chạy ở chế độ headless. Mỗi script khởi tạo scene hoặc đối tượng cần thiết, mô phỏng thao tác, kiểm tra điều kiện và in kết quả PASS hoặc FAIL. Bộ kiểm thử không sử dụng save thật của người chơi mà sử dụng profile QA riêng.

Các nhóm kiểm thử bao phủ gameplay physics, surface, bumper, obstacle, portal, portal effects, course, UI, camera, audio, player data, edge case và stress shot. Runner `Tools/run_tests.ps1` có thể chạy toàn bộ suite và thêm `-CheckRestart` để kiểm tra nhiều tiến trình độc lập.

## 5.2. Kết quả kiểm thử

Repository ghi nhận 13 nhóm kiểm thử chính và 8 giai đoạn kiểm tra save/restart. Bộ stress test thực hiện 80 phiên vật lý độc lập trên các course, với tổng cộng 301 cú đánh mô phỏng trong các kịch bản đã định nghĩa. Camera được kiểm tra ở nhiều kích thước cửa sổ và tốc độ 30, 60 và 144 FPS. Bộ course test kiểm tra mười course, vị trí xuất phát, lỗ, vật cản, portal hai chiều và các tuyến di chuyển quan trọng.

Các kiểm tra vật lý xác minh vận tốc và vị trí luôn hữu hạn, bóng không thoát khỏi biên map, bóng chỉ được đánh tiếp khi đã dừng, nước chỉ cộng phạt một lần, lỗ chỉ nhận bóng dưới ngưỡng tốc độ và mũi tên chỉ tăng tốc khi điều kiện vào tile được thỏa mãn. Các kiểm tra portal xác minh khóa chống lặp, vị trí ra an toàn, vận tốc, chiều đi hai hướng, hủy yêu cầu khi portal đích bị xóa và không tạo ảnh hiệu ứng mồ côi.

## 5.3. Kiểm thử giao diện và camera

Kiểm thử giao diện mô phỏng luồng menu, chọn course, kéo-thả qua viewport chính, HUD, pause, settings, restart, result screen, mở khóa và lưu tải tiến trình. Các edge case kiểm tra việc nhấn và thả chuột qua GUI, hủy thoát, lỗi ghi dữ liệu và tránh việc kết quả cũ ghi đè kết quả mới.

Kiểm thử camera kiểm tra các course có kích thước khác nhau trong năm kích thước cửa sổ. Mục tiêu là bảo đảm HUD bám mép, không che khuất vùng chơi, nhìn thấy toàn bộ sân và lỗ, camera bám mượt và không zoom nhấp nhô.

## 5.4. Kiểm thử âm thanh và tài nguyên

Kiểm thử âm thanh xác minh tài nguyên tồn tại, nhạc phát lặp, cue được phát từ cú đánh thật, hiệu ứng không bị phát dồn, pause/resume hoạt động, âm lượng Music và SFX được áp dụng, và nhạc không khởi động lại không cần thiết khi chuyển màn.

Kiểm thử asset xác minh kích thước atlas, alpha, StyleBoxTexture, vị trí neo, nearest filtering và khả năng hiển thị ở nhiều độ phân giải. Các tài nguyên âm thanh được đối chiếu với manifest và thông tin license.

## 5.5. Đánh giá kết quả

Kết quả kiểm thử cho thấy các cơ chế chính của project hoạt động đúng trong phạm vi các scenario đã xây dựng. Hệ thống có khả năng xử lý những tình huống dễ gây lỗi như bóng chạy nhanh, portal bị xóa, bóng rơi vào nước, gate thay đổi trạng thái khi bóng ở gần, save bị gián đoạn và chuyển màn hình trong khi nhạc đang phát.

Tuy nhiên, kiểm thử tự động không thay thế hoàn toàn playtest. Các yếu tố như độ thú vị của course, độ dễ hiểu của giao diện, cảm giác lực đánh và sự cân bằng mục tiêu sao vẫn cần được đánh giá bằng người chơi. Vì vậy, số liệu kiểm thử trong báo cáo nên được hiểu là bằng chứng về tính ổn định của các scenario kỹ thuật, không phải là tuyên bố rằng game không còn lỗi.

# CHƯƠNG 6. KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN

## 6.1. Kết luận

Đề tài đã xây dựng được một game Mini-golf 2D hoàn chỉnh bằng Godot Engine và GDScript. Sản phẩm có mười course, cơ chế đánh bóng, mô phỏng giảm tốc, phản xạ va chạm, địa hình, nước, mũi tên, bumper, obstacle, blinking gate, portal, hole, UI, audio và save system.

Về mặt lý thuyết, đề tài đã vận dụng vector, bước thời gian vật lý, phản xạ theo pháp tuyến, Continuous Collision Detection, máy trạng thái hữu hạn, kiến trúc hướng sự kiện và thiết kế dựa trên dữ liệu. Về mặt quy trình, đề tài thể hiện chuỗi từ thiết kế asset trong Aseprite, xuất tài nguyên, tích hợp atlas vào Godot, lập trình gameplay, xây dựng UI, thêm âm thanh, lưu dữ liệu và kiểm thử hồi quy.

Việc tách module giúp project dễ bảo trì hơn so với cách viết toàn bộ logic trong một script. Việc dùng TileMap Custom Data giúp course được cấu hình bằng dữ liệu. Việc sử dụng signal giúp gameplay không phụ thuộc trực tiếp vào HUD và Audio Director. Cơ chế file tạm, backup, revision và checksum làm tăng độ tin cậy của lưu tiến trình.

## 6.2. Hạn chế

Project hiện chưa có multiplayer trực tuyến, bảng xếp hạng, replay, trình chỉnh sửa course cho người dùng, mô phỏng độ dốc đầy đủ và hệ thống nội dung tải từ máy chủ. Số lượng course vẫn còn giới hạn và việc cân bằng mục tiêu sao chủ yếu được thực hiện thủ công. Các kết quả kiểm thử tập trung vào những scenario đã định nghĩa, do đó chưa bao phủ toàn bộ hành vi người chơi thực tế.

## 6.3. Hướng phát triển

Trong các phiên bản tiếp theo, hệ thống có thể bổ sung multiplayer cục bộ hoặc trực tuyến, ghost replay, bảng xếp hạng, thành tích, nhiều loại địa hình hơn, hiệu ứng thời tiết, course editor và cơ chế chia sẻ map. Hệ thống vật lý có thể được mở rộng để hỗ trợ độ dốc, lực hấp dẫn cục bộ và vật liệu có hệ số ma sát khác nhau. Bộ kiểm thử có thể tích hợp thêm property-based testing, snapshot hình ảnh và playtest có thu thập dữ liệu.

# TÀI LIỆU THAM KHẢO

[1] Godot Engine, “Godot Engine documentation, version 4.7,” Godot Foundation, 2026. [Online]. Available: https://docs.godotengine.org/en/stable/. [Accessed: Nov. 12, 2026].

[2] I. Millington, *Game Physics Engine Development*, 2nd ed. Boca Raton, FL, USA: CRC Press, 2010.

[3] C. Ericson, *Real-Time Collision Detection*. San Francisco, CA, USA: Morgan Kaufmann, 2005.

[4] R. Nystrom, *Game Programming Patterns*. Genever Benning, 2014. [Online]. Available: https://gameprogrammingpatterns.com/. [Accessed: Nov. 12, 2026].

[5] G. Fiedler, “Fix Your Timestep!,” 2004. [Online]. Available: https://gafferongames.com/post/fix_your_timestep/. [Accessed: Nov. 12, 2026].

[6] J. Gregory, *Game Engine Architecture*, 3rd ed. Boca Raton, FL, USA: CRC Press, 2018.

[7] E. Lengyel, *Foundations of Game Engine Development, Volume 1: Mathematics*. Terathon Software, 2016.

[8] K. Collins, *Game Sound: An Introduction to the History, Theory, and Practice of Video Game Music and Sound Design*. Cambridge, MA, USA: MIT Press, 2008.

[9] Aseprite, “Aseprite documentation,” Igara Studio S.A. [Online]. Available: https://www.aseprite.org/docs/. [Accessed: Nov. 12, 2026].

[10] IEEE, “IEEE editorial style manual,” IEEE. [Online]. Available: https://journals.ieeeauthorcenter.ieee.org/submit-your-article-for-peer-review/about-your-article/ieee-editorial-style-manual/. [Accessed: Nov. 12, 2026].

[11] Kenney, “Interface sounds,” Kenney. [Online]. Available: https://kenney.nl/assets/interface-sounds. [Accessed: Nov. 12, 2026].

[12] Kenney, “Impact sounds,” Kenney. [Online]. Available: https://kenney.nl/assets/impact-sounds. [Accessed: Nov. 12, 2026].

[13] rubberduck, “40 CC0 water splash, slime SFX,” OpenGameArt. [Online]. Available: https://opengameart.org/content/40-cc0-water-splash-slime-sfx. [Accessed: Nov. 12, 2026].

[14] C. Murphy, “Sherwood,” OpenGameArt. [Online]. Available: https://opengameart.org/content/sherwood. [Accessed: Nov. 12, 2026].

[15] G. Tom, *Basic Project 2026–2027: Minigolf*, GitHub repository, 2026. [Online]. Available: https://github.com/GabTommy2006/Basic-Project---2026-27---Minigolf. [Accessed: Nov. 12, 2026].

# PHỤ LỤC A. HƯỚNG DẪN CÀI ĐẶT VÀ CHẠY PROJECT

Project yêu cầu Godot 4.7.2. Người dùng có thể clone repository, mở `project.godot` bằng Godot và nhấn F5 để chạy toàn bộ game từ `UI/Main.tscn`. Để kiểm tra riêng từng course, người dùng mở scene tương ứng trong `Maps/Courses` và nhấn F6. Các scene `Maps/TestMap.tscn` và `Maps/MechanicsPlayground.tscn` phục vụ kiểm tra cơ chế.

Đối với bản phát hành Windows, người dùng tải file ZIP từ GitHub Releases, giải nén và chạy `SummerMinigolf.exe`. Không cần cài Godot khi sử dụng bản build. Chế độ fullscreen được bật trong Settings.

# PHỤ LỤC B. HƯỚNG DẪN ĐIỀU KHIỂN

Người chơi nhấn và giữ chuột trái gần quả bóng, kéo chuột ngược hướng muốn đánh rồi thả chuột. Khoảng kéo càng lớn thì lực đánh càng mạnh cho đến giới hạn tối đa. Phím Esc dùng để tạm dừng hoặc tiếp tục game. Phím R mở hộp thoại restart trong khi đang chơi. Người chơi cần chờ bóng dừng trước khi thực hiện cú đánh tiếp theo.

# PHỤ LỤC C. ĐẶC TẢ THÔNG SỐ VẬT LÝ

Các thông số mặc định quan trọng của bóng gồm vận tốc cú đánh tối đa 180 pixel/giây, khoảng kéo tối đa 50 pixel, giảm tốc trên cỏ 40 pixel/giây², giảm tốc trên cát 240 pixel/giây², bán kính bắt đầu kéo 7 pixel, hệ số tăng tốc mũi tên 1,2, thời gian chìm nước 0,55 giây và thời gian cooldown portal 0,2 giây. Hole sử dụng ngưỡng vận tốc nhận bóng 160 pixel/giây theo các kiểm tra surface của project.

Các giá trị này là thông số thiết kế, không phải hằng số vật lý ngoài đời thực. Chúng được lựa chọn để tạo cảm giác điều khiển dễ hiểu và hỗ trợ cân bằng course.

# PHỤ LỤC D. QUY TRÌNH THIẾT KẾ ASSET BẰNG ASEPRITE

Quy trình bắt đầu bằng việc xác định loại asset, kích thước canvas và vùng sử dụng theo lưới 16×16 pixel. Sau đó người thiết kế tạo hình với bảng màu nhất quán, kiểm tra các trạng thái bình thường, hover và pressed, căn chỉnh điểm neo rồi kiểm tra nền trong suốt. Asset được xuất thành PNG ở tỉ lệ gốc, không làm mờ và không nội suy.

Master sheet `SummerUI-v2.aseprite` có kích thước 512×512 pixel. Sau khi xuất, metadata atlas được lưu trong `SummerUI-v2.json`. Các vùng texture được nhập vào Godot thành AtlasTexture. Panel và thành phần có thể kéo giãn sử dụng StyleBoxTexture. Font giao diện là `Assets/Minecraft.otf`.

Nguyên tắc quan trọng là không mô tả mọi asset có kích thước đúng 16×16 pixel. Cách diễn đạt chính xác là asset được thiết kế trên lưới cơ sở 16×16 pixel và kích thước canvas thay đổi theo loại thành phần. Icon nhỏ có thể là 16×16, còn panel, HUD, nút, ô level và logo có thể chiếm nhiều ô lưới.

# PHỤ LỤC E. DANH MỤC TÀI NGUYÊN ÂM THANH

Project có 13 file âm thanh được manifest ghi nhận. Nhóm giao diện gồm `menu_click.ogg` và `menu_back.ogg`. Nhóm gameplay gồm `golf_shot.ogg`, `wall_contact.ogg`, `bumper_hit.ogg`, `arrow_boost.ogg`, `portal_travel.ogg`, `gate_switch.ogg`, `water_splash.ogg` và `hole_capture.ogg`. Nhóm phần thưởng gồm `star_reward.ogg` và `course_complete.ogg`. Nhạc nền là `music_sherwood.ogg`.

Các file của Kenney được lấy từ Interface Sounds, Impact Sounds, RPG Audio và Music Jingles. `water_splash.ogg` được ghi nhận từ rubberduck trên OpenGameArt. `music_sherwood.ogg` được ghi nhận cho Chris Murphy, còn có tên zesona. Manifest lưu creator, URL, license, original filename, SHA-256 và trạng thái phê duyệt. Tất cả tài nguyên được ghi nhận trong project ở dạng CC0-1.0 theo tài liệu credit hiện tại.

# PHỤ LỤC F. HỆ THỐNG LƯU VÀ PHỤC HỒI

File lưu chính có đường dẫn Windows tương đương `%APPDATA%\Godot\app_userdata\Minigolf Basic Project\summer_golf.cfg`. Dữ liệu gồm course đã mở khóa, course gần nhất, trạng thái đã bắt đầu, điểm tốt nhất, sao, âm lượng nhạc, âm lượng hiệu ứng và fullscreen.

Khi ghi, hệ thống tạo file `.tmp`, đọc lại để kiểm tra payload rồi đổi tên thành file chính. Bản sao `.bak` được tạo sau khi file chính hợp lệ. Mỗi payload có version, revision và checksum SHA-256. Khi tải, hệ thống xét file chính, backup và temporary file; bản hợp lệ có revision cao nhất được chọn. Khi file chính hỏng, trạng thái được đánh dấu recovered hoặc damaged tùy kết quả đọc.

New Game xóa điểm, sao và tiến trình mở khóa nhưng giữ lại cài đặt âm thanh và hiển thị. Nếu thao tác reset không thể lưu thành công, trạng thái trước đó được khôi phục để tránh mất dữ liệu.

# PHỤ LỤC G. QUY TRÌNH KIỂM THỬ

Các script smoke test chạy bằng Godot ở chế độ headless. Mỗi script khởi tạo scene, chạy scenario, kiểm tra assert và thoát với mã khác 0 nếu có lỗi. `obstacles_smoke.gd` kiểm tra obstacle quay, obstacle di chuyển và blinking gate. `bumper_smoke.gd` kiểm tra phản xạ, tăng tốc, cooldown và bumper tam giác. `portal_smoke.gd` kiểm tra kết nối hai chiều, điểm ra, vận tốc, cooldown, nước và lỗ. `portal_effects_smoke.gd` kiểm tra hiệu ứng hình ảnh, scale, màu, parent transform và dọn node.

`game_ui_smoke.gd` kiểm tra menu, course selection, HUD, pause, settings, restart, result và lưu tải. `course_camera_smoke.gd` kiểm tra framing ở nhiều độ phân giải và FPS. `game_audio_smoke.gd` kiểm tra tài nguyên, nhạc, cue, chống phát dồn, pause/resume và volume. `player_data_smoke.gd` kiểm tra save, recovery, migration và New Game. `shot_stress.gd` chạy nhiều phiên vật lý độc lập và xác minh vị trí, vận tốc, biên map và điều kiện đánh tiếp.

Lệnh chạy toàn bộ suite là:

```powershell
./Tools/run_tests.ps1 -CheckRestart
```

Kết quả log được ghi trong `tmp/test-results/`. Các profile kiểm thử được tách khỏi profile người chơi thật.

# PHỤ LỤC H. GỢI Ý ĐƯA BÁO CÁO VÀO GOOGLE DOCS

Khi chuyển báo cáo sang Google Docs, nội dung nên được dán theo từng chương và áp dụng Heading 1 cho tên chương, Heading 2 cho mục lớn và Heading 3 cho mục nhỏ. Mục lục được tạo bằng Insert, Table of contents. Với hình ảnh, cần chèn ảnh chụp trực tiếp từ game hoặc ảnh trong `Docs/Previews`, đặt caption thống nhất theo dạng “Hình x.y. Tên hình” và ghi nguồn “Nguồn: Tác giả, trích xuất từ project”. Với bảng, đặt tên ở phía trên bảng theo dạng “Bảng x.y. Tên bảng”. Danh mục hình và bảng có thể tạo thủ công bằng cách sao chép các caption sau khi nội dung ổn định hoặc dùng bookmark và liên kết nội bộ.

Hình chụp nên bao gồm menu chính, course selection, HUD, gameplay có vật cản, portal, water hazard, màn hình kết quả, settings, master sheet Aseprite và cửa sổ kết quả kiểm thử. Không nên đưa toàn bộ source code vào nội dung chính; chỉ nên chèn các đoạn code ngắn minh họa cho vector cú đánh, giảm tốc, phản xạ hoặc lưu dữ liệu, còn phần còn lại để trong repository và mô tả ở phụ lục.

