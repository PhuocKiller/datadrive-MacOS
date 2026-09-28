<!--
SPDX-FileCopyrightText: 2026 Tran Huy Phuoc
SPDX-License-Identifier: GPL-2.0-or-later
-->

# Nhật ký đổi thương hiệu DataDrive

Ghi lại mọi thay đổi trong quá trình rebrand Nextcloud desktop client thành DataDrive.
Nhánh làm việc: `branding/datadrive`. Không commit vào `master`.

---

## ⚠️ CẦN BẠN ĐỌC TRƯỚC — các điểm tôi đã gắn cờ

Đây là chỗ bạn hỏi "flag ở đâu". Tất cả nằm trong mục này. Mỗi mục ghi rõ vấn đề,
quyết định tôi đã chọn (theo nguyên tắc an toàn nhất), và hệ quả nếu bạn muốn đổi ý.

### A. Cây làm việc KHÔNG sạch — mâu thuẫn với Bước 1

Bước 1 giả định cây git sạch. Thực tế lúc bắt đầu có **9 file đã sửa, chưa commit**,
là phần việc của phiên trước (khoá URL server, ép đăng nhập trong app, nút Home page,
kèm 8 test). Nhánh `branding/datadrive` cũng đã tồn tại sẵn và đang được chọn.

**Quyết định:** giữ nguyên phần việc đó, commit thành commit riêng đầu tiên trên nhánh
này trước khi rebrand, để hai nhóm thay đổi tách bạch khi bạn review.

### B. GUID shell extension BẮT BUỘC phải sinh mới

`NEXTCLOUD.cmake:134` ghi rõ bằng tiếng Anh: *"IMPORTANT: Generate new GUIDs for custom
builds"*. Có 6 GUID (1 context menu, 5 overlay) cộng 1 MSI upgrade code.

Nếu giữ nguyên, DataDrive và Nextcloud gốc đăng ký **trùng CLSID** trong registry
Windows. Cài cả hai trên một máy thì chúng ghi đè nhau, overlay icon và menu chuột phải
của cả hai đều hỏng.

**Quyết định:** sinh GUID mới hoàn toàn. Đây là dữ liệu registry, tức NHÓM 3 theo cách
bạn phân loại, nhưng thuộc diện *bắt buộc phải đổi* chứ không phải *giữ nguyên*.

### C. Đổi `APPLICATION_REV_DOMAIN` làm mất cấu hình của bản cài cũ

Đổi `com.nextcloud.desktopclient` → `vn.datadrive.desktopclient` kéo theo đổi đường dẫn
thư mục cấu hình và khoá registry của shell extension CfAPI. Ai đã cài bản build trước
sẽ **mất tài khoản đã thiết lập**, phải đăng nhập lại.

**Quyết định:** đổi theo đúng yêu cầu của bạn. Với sản phẩm mới phát hành lần đầu thì
không ảnh hưởng ai. Chỉ cần biết trước để không hoảng khi test trên máy đã cài bản cũ.

### D. Tắt auto-update = vĩnh viễn không có bản vá bảo mật tự động

Bạn yêu cầu tắt hẳn. Tôi sẽ đặt `BUILD_UPDATER=OFF` và xoá rỗng `APPLICATION_UPDATE_URL`.

**Hệ quả thật:** mọi lỗi bảo mật phát hiện về sau đều phải tự phát hành bản mới và tự
thông báo cho người dùng cài lại bằng tay. Client sẽ không bao giờ tự nhắc.

**Quyết định:** làm theo yêu cầu. Khi nào bạn có server cập nhật riêng thì bật lại.

### E. Bước 6 — "không còn chuỗi Nextcloud nào lọt ra" KHÔNG thể đạt 100%

Thư mục `translations/` có **64 file ngôn ngữ**, bên trong vẫn chứa chuỗi "Nextcloud"
đã dịch sẵn (tiếng Pháp 18 lần, tiếng Đức 18, tiếng Nhật 17). `AGENTS.md:61` quy định
thư mục này **"Do not modify"** vì nó được đồng bộ tự động từ Transifex.

Không có file tiếng Việt (`client_vi.ts` không tồn tại).

**Quyết định:** không đụng vào `translations/`. Kết quả thực tế: chạy app ở tiếng Anh
thì sạch hoàn toàn; chạy ở tiếng Pháp/Đức/Nhật... vẫn lọt vài chuỗi "Nextcloud" từ
catalog dịch. Đây là kênh lọt duy nhất còn lại và tôi cố ý không bịt.

*Nếu bạn muốn bịt luôn:* phải tự sinh lại file dịch, tức rời khỏi quy trình Transifex
của dự án gốc. Đó là quyết định của bạn, không phải việc tôi tự làm.

### F. Bước 7 `buildTests=False` xung đột với AGENTS.md và với test đã viết

`AGENTS.md` bắt buộc mọi thay đổi phải có test được **chạy thật**. Phiên trước tôi đã
viết 8 test và chúng pass. Nếu build với `buildTests=False` thì 8 test đó không được
biên dịch, cũng không chạy.

**Quyết định:** chia hai lượt.
1. Lượt xác minh: `buildTests=True`, chạy `ctest` để chứng minh không vỡ gì.
2. Lượt đóng gói: `buildTests=False` như bạn yêu cầu, cho bộ cài nhẹ và build nhanh.

### G. `APPLICATION_VIRTUALFILE_SUFFIX` đang là "nextcloud"

Đây là đuôi file placeholder mà người dùng **nhìn thấy trực tiếp** trong Explorer
(ví dụ `báo-cáo.docx.nextcloud`). Thuộc NHÓM 1, nhưng đổi thì placeholder của bản cũ
thành mồ côi.

**Quyết định:** đổi thành `datadrive`. Lý do: đây là sản phẩm mới, chưa có người dùng
cũ, và để nguyên thì lộ thương hiệu gốc ngay trên màn hình.

### H. Cần cài thêm Pillow (thư viện Python)

Máy chưa có công cụ nào tạo được file `.ico` đa kích thước và `.bmp` đúng chuẩn NSIS.

**Quyết định:** cài `pillow` bằng pip vào Python 3.12 đã có. Đây là thư viện xử lý ảnh
phổ biến, chỉ dùng lúc build, không nhúng vào sản phẩm.

### I. Thư mục logo lồng hai lớp và chưa được git theo dõi

Thực tế là `Logo/Logo/...` và `BackGround/BackGround/...` chứ không phải `Logo/...`.

**Quyết định:** copy tài nguyên cần dùng vào đúng vị trí trong repo (`theme/`,
`admin/win/nsi/`) và commit những file đó. Hai thư mục gốc giữ nguyên, không commit,
để bạn còn file nguồn.

### J. Phiên bản hiển thị đang lấy theo tên nhánh git

Bản cài trước ghi `DisplayVersion = master` vì craft lấy tên nhánh làm version. Giờ
nhánh tên `branding/datadrive` nên nhiều khả năng thành chuỗi xấu hơn.

**Quyết định:** đặt version cố định qua `MIRALL_VERSION_SUFFIX` để bộ cài hiển thị số
phiên bản tử tế thay vì tên nhánh.

### K. Quy tắc 1 (không đụng `src/common/`) có thể bị chạm

Hằng số CLSID của shell extension CfAPI được sinh từ `APPLICATION_REV_DOMAIN`. Nếu
chuỗi đó xuất hiện trong `src/common/`, tôi buộc phải chạm tới ở mức tối thiểu.

**Quyết định:** nếu xảy ra sẽ ghi rõ vào mục "Ngoại lệ quy tắc 1" bên dưới, sửa ít nhất
có thể, và không đụng bất cứ thứ gì liên quan ssl/certificate/crypto.

### L. Yêu cầu bạn nêu ở đầu tin nhắn không nằm trong Bước 0–10

Bạn phản ánh: trang nhập server *loé qua* rồi mới vào trang đăng nhập, và trang đăng
nhập vẫn còn nút **Back** dù không còn chỗ nào để lùi về.

Đây là việc sửa giao diện, không thuộc 11 bước bạn đánh số.

**Quyết định:** tôi coi đây là việc phải làm và xử lý trước khi rebrand, vì nó thuộc
cùng vùng code với phần việc phiên trước.

---

## Phân loại chuỗi "Nextcloud" (Bước 2)

*(cập nhật khi chạy xong grep phân loại)*

---

## Nhật ký thay đổi theo bước

*(cập nhật liên tục)*

---

## Ngoại lệ quy tắc 1 — các file bị chạm ngoài dự kiến

*(trống nếu không có)*

---

## Giải pháp tạm — chỗ cần bạn xem lại

*(cập nhật liên tục)*

---

## Bổ sung cho các cờ đã nêu

**Cờ H đã giải quyết tốt hơn dự kiến.** Craft đã tự cài sẵn `clang-format.exe`,
`clang-tidy.exe` và `run-clang-tidy.exe` vào `C:\CraftRoot\windows-msvc2022_64-cl\bin`
(gói `libs/llvm`). Nghĩa là yêu cầu bắt buộc của `AGENTS.md` mà phiên trước tôi phải
bỏ qua, nay chạy được.

Nhưng bản của craft là 20.1.7, còn `.clang-format` của repo dùng khoá `EnumTrailingComma`
cần clang-format 21 trở lên. Tôi cài `clang-format` 23.1.1 và `pillow` 12.3.0 qua pip vào
Python 3.12. Hai thứ này chỉ dùng lúc build, không nhúng vào sản phẩm.

**Hook pre-commit của repo bắt buộc format.** Commit bị chặn cho tới khi chạy
`git clang-format --staged`. Đây là hành vi đúng của dự án, không phải lỗi.

---

## Nhật ký thay đổi theo bước (chi tiết)

### Bước 2 — kết quả phân loại

Grep toàn repo cho "nextcloud" ra hơn 1200 file, nhưng phần lớn là header bản quyền và
định danh nội bộ. Lọc theo chuỗi **dịch được** (`tr()` / `qsTr()`) chỉ còn **3 chỗ**:

| File | Chuỗi | Nhóm | Xử lý |
|---|---|---|---|
| `src/gui/assistant/qml/AssistantMessageList.qml:50` | "Start a conversation with Nextcloud Assistant." | 1 | Đổi thành "the Assistant" |
| `src/gui/systray_mac_usernotifications.mm:155` | "Send a Nextcloud Talk reply" | 1 | Đổi thành "Send a Talk reply" |
| `src/gui/legalnotice.cpp:47` | Copyright 2017-2026 Nextcloud GmbH | 2 | **GIỮ NGUYÊN** — bắt buộc theo GPL |

Lý do chỉ có 3: mọi chỗ khác lấy tên qua `Theme::instance()->appNameGUI()`, tức đổi ở
`NEXTCLOUD.cmake` là ăn toàn bộ.

**Bổ sung vào legalnotice.cpp:** thêm một câu nói rõ đây là bản sửa đổi của Nextcloud
desktop client, phát hành bởi bên khác. Đây không phải xoá bản quyền mà ngược lại —
GPL-2 mục 2(a) *yêu cầu* bản đã sửa phải ghi rõ điều này.

### NHÓM 3 — những thứ cố ý GIỮ NGUYÊN

| Thứ | Ở đâu | Lý do giữ |
|---|---|---|
| Token `mirall/` trong User-Agent | `src/common/utility.cpp:157` | Server Nextcloud nhận diện client qua token này. Đổi là mất khả năng đồng bộ. Ngoài ra file nằm trong `src/common/` — vùng cấm theo Quy tắc 1 |
| `/remote.php/dav/...`, `/ocs/v1.php`, `/ocs/v2.php` | `src/libsync/account.cpp` và nhiều nơi | Đường dẫn API của giao thức Nextcloud, không chứa chữ "nextcloud", đổi là hỏng hết |
| `THEME_CLASS = "NextcloudTheme"` | `NEXTCLOUD.cmake:107` | Tên class C++ nội bộ, NHÓM 2, không hiển thị |
| Thư mục `theme/colored/nextcloud/` | resource | Chứa icon **trạng thái** (ok/sync/error), không phải logo thương hiệu. Tên thư mục không hiển thị. Đổi tên phải sửa ~60 dòng `theme.qrc` mà không được lợi gì |
| `translations/` | toàn bộ 64 file | `AGENTS.md:61` cấm sửa. Xem cờ E |

**Ghi chú hành vi:** `src/libsync/configfile.cpp:1128` so sánh `APPLICATION_NAME` với
chuỗi "Nextcloud" để quyết định mặc định dùng icon đơn sắc. Sau khi đổi tên, so sánh này
thành false. Nhưng toàn bộ khối nằm trong `#ifdef Q_OS_MACOS` nên **không ảnh hưởng bản
Windows**. Không sửa, chỉ ghi lại.

### Bước 3 — NEXTCLOUD.cmake

Tên app, executable, domain, vendor, reverse domain, đuôi file ảo, tên gói Linux, màu
nền `#0A93E0` (lấy từ logo), `BUILD_UPDATER=OFF`, `APPLICATION_UPDATE_URL` để rỗng,
và **7 GUID sinh mới** (6 shell extension + 1 MSI upgrade code) theo đúng cảnh báo ở
dòng 136 của chính file đó.

### Bước 4 — icon và logo

| Đích | Nguồn |
|---|---|
| `theme/colored/DataDrive-icon.svg` | `Logo/Logo/datadrive-icon.svg` |
| `theme/colored/DataDrive-w10startmenu.svg` | như trên |
| `theme/colored/DataDrive-icon-square.svg` | `datadrive-icon-simple.svg` |
| `theme/colored/icons/DataDrive-icon-win-folder.svg` | như trên — **TẠM THỜI** |
| `theme/colored/wizard_logo.svg` | `Logo/Logo/datadrive-logo.svg` |

`theme.qrc` đổi toàn bộ `Nextcloud-icon` → `DataDrive-icon`. Bắt buộc phải làm, vì build
sinh PNG theo tên `${APPLICATION_ICON_NAME}` còn `.qrc` thì hardcode tên cũ; không sửa là
build gãy vì thiếu file resource.

### Bước 5 — bộ cài NSIS

**Ảnh** sinh bằng script Python + Pillow, đúng kích thước MUI2 yêu cầu:
`installer.ico` (16/32/48/64/128/256), `welcome.bmp` 164×314 (cắt dọc từ ảnh nền của bạn,
logo đặt giữa), `page_header.bmp` 150×57 (icon + chữ trên nền trắng).

**Chữ** không nằm trong repo. `admin/win/nsi/NSIS.template.in` mà `README.md` ở đó nhắc
tới **đã bị xoá khỏi repo từ trước**, nên craft dùng template mặc định của nó và lấy chữ
từ blueprint. Đã vá blueprint trong `C:\CraftRoot` (xem mục Vá ngoài repo).

---

## Vá ngoài repo — sẽ mất nếu craft fetch lại blueprint

Ba bản vá trong
`C:\CraftRoot\windows-msvc2022_64-cl\etc\blueprints\locations\craft-blueprints-nextcloud\nextcloud-client\nextcloud-client.py`.
Thư mục này craft tự đồng bộ bằng git, nên có thể bị ghi đè bất cứ lúc nào.

| Dòng | Sửa gì | Vì sao |
|---|---|---|
| 4 | thêm `import os` | Lỗi thật của upstream: file dùng `os.path.join` mà không import |
| 100 | thêm `defines["executable"] = "bin/datadrive.exe"` | Craft không còn đọc `applicationExecutable`; thiếu dòng này thì bộ cài **không tạo shortcut nào** |
| 25-27, 94-96 | description / displayName / webpage / appname / company | Chữ thương hiệu trong bộ cài |

**Dấu hiệu bị ghi đè:** bộ cài mất shortcut, hoặc đóng gói báo `NameError: name 'os' is
not defined`, hoặc tên trong Control Panel quay về "Nextcloud". Cách sửa: vá lại y hệt.

---

## Giải pháp tạm — cần bạn xem lại

1. **`theme/colored/icons/DataDrive-icon-win-folder.svg`** đang là bản sao của icon thường.
   Bản gốc Nextcloud dùng biến thể logo *lồng trong hình thư mục Windows*, dùng cho icon
   thư mục đồng bộ trong Explorer. Tôi không tự vẽ được biến thể đó. Hệ quả: thư mục đồng
   bộ hiện icon DataDrive thường thay vì icon hình thư mục. Không ảnh hưởng chức năng.

2. **`theme/colored/DataDrive-w10startmenu.svg`** cũng là bản sao icon thường. Bản gốc là
   biến thể riêng cho ô vuông Start Menu Windows 10 (thường có lề rộng hơn). Có thể hơi
   sát viền trên tile.

3. **Ảnh `welcome.bmp`** tôi tự bố cục: cắt dọc từ `datadrive-login-bg-light-1920x1080.png`
   rồi đặt icon vào giữa. Nếu bạn có thiết kế riêng cho cột này thì thay thẳng file đó.

### Bổ sung vá blueprint — icon và phiên bản của bộ cài

Đọc `bin/Packager/PackagerBase.py` của craft ra hai mặc định gây hại cho bản branding:

```python
defines.setdefault("icon", craftBin / "data/icons/craft.ico")
defines.setdefault("version", self.sourceRevision() if hasSvnTarget() else self.version)
```

- **`icon`** mặc định là `craft.ico`. Đây chính là lý do bộ cài trước đó dùng logo craft và
  thả `craft.ico` vào `C:\Program Files\...`. Đã trỏ sang `admin/win/nsi/installer.ico`.
- **`version`** với target git chính là revision/tên nhánh, nên bản trước ghi
  `DisplayVersion = master`. Đã đặt cứng `34.0.50` (khớp `MIRALL_VERSION` trong
  `VERSION.cmake`).

**Cần nhớ:** số `34.0.50` là hằng số trong file blueprint ngoài repo. Khi nâng phiên bản
thật thì phải sửa cả hai chỗ, hoặc bỏ dòng đó để craft tự suy ra sau khi nhánh có upstream.

### Bước 6 — kết quả kiểm tra các kênh hiển thị

| Kênh | Kết quả |
|---|---|
| Chuỗi `tr()`/`qsTr()` | Sạch, chỉ còn copyright (bắt buộc giữ) |
| File `.ui` Qt Designer | Sạch. `advancedsettings.ui:203` có link `github.com/nextcloud/notify_push` — **cố ý giữ**: chữ hiện ra là "Client Push", còn URL trỏ tới dự án thật cung cấp tính năng đó. Đổi đi là link chết và mất thông tin đúng |
| Thuộc tính `text:`/`title:` trong QML | Không có chuỗi hardcode nào |
| Thư mục đồng bộ mặc định | `Theme::defaultClientFolder()` trả về `appName()` = `APPLICATION_SHORTNAME` → **"DataDrive"** tự động, không cần sửa |
| Tên công cụ dòng lệnh | `${APPLICATION_EXECUTABLE}cmd` → **`datadrivecmd`** tự động |
| Icon tray | Lấy qua `themeIcon(APPLICATION_ICON_NAME "-icon")` → resource `DataDrive-icon-*` đã đổi trong `theme.qrc` |

Lý do ít chỗ phải sửa tay: dự án đã tập trung toàn bộ thương hiệu vào `NEXTCLOUD.cmake`
và lớp `Theme`. Đây là thiết kế tốt của upstream, không phải tôi bỏ sót.

---

## Bước 7 — nhật ký các lần build

### Lần 1 — THẤT BẠI tại [77/801]

```
theme.cpp(634): error C2065: 'APPLICATION_UPDATE_URL': undeclared identifier
```

**Nguyên nhân:** `#cmakedefine` chỉ định nghĩa macro khi biến CMake **khác rỗng**. Tôi đặt
`APPLICATION_UPDATE_URL ""` theo yêu cầu tắt hẳn auto-update, nên macro không tồn tại, còn
`Theme::updateCheckUrl()` lại dùng nó không có guard.

**Sửa:** bọc `#ifdef APPLICATION_UPDATE_URL` trong `src/libsync/theme.cpp`, trả về chuỗi
rỗng khi không có. Đây là câu trả lời đúng ngữ nghĩa cho bản build không có server cập nhật.
Đã kiểm tra: `updateCheckUrl()` hiện **không có nơi nào gọi** (updater đã tắt), nên không
ảnh hưởng hành vi nào khác.

### Lần 2 — biên dịch XONG (726/726), thất bại ở bước install

```
CMake Error at src/gui/cmake_install.cmake:53 (file):
  file INSTALL cannot find "C:/projects/Datadrive/theme/datadrive.VisualElementsManifest.xml"
```

**Nguyên nhân:** `src/gui/CMakeLists.txt:647` cài file
`${theme_dir}/${APPLICATION_EXECUTABLE}.VisualElementsManifest.xml`. Đổi executable thành
`datadrive` thì nó tìm `theme/datadrive.VisualElementsManifest.xml`, trong khi repo chỉ có
bản cũ `theme/nextcloud.VisualElementsManifest.xml`.

File này khai báo ô vuông (live tile) của Start Menu Windows.

**Sửa:** tạo `theme/datadrive.VisualElementsManifest.xml`, trỏ tới hai PNG mà build tự sinh
là `150-DataDrive-w10startmenu.png` và `70-DataDrive-w10startmenu.png`.

*Khác bản gốc:* manifest cũ trỏ tới `Nextcloud-w10starttile.png` — một file tile riêng có
sẵn trong repo. Bản DataDrive dùng thẳng PNG sinh từ SVG, nên không cần thêm file tile.

### Lần 3 — BUILD THÀNH CÔNG, nhưng 5/86 test hỏng

Binary ra đúng tên: `datadrive.exe`, `datadrivecmd.exe`, `datadrivesync.dll`,
`datadrive_csync.dll`, `datadrivesync_vfs_cfapi.dll`, `datadrivesync_vfs_suffix.dll`.

Phân tích 5 test hỏng:

| Test | Nguyên nhân | Có phải do rebrand? |
|---|---|---|
| `AccountWizardControllerTest` (6 case) | Các test giả định wizard mở ở `ServerStep`. Bản này ghim server nên mở thẳng `BasicAuthStep` | **Có** — hệ quả trực tiếp của cờ L |
| `UpdateChannelTest` | `Theme::isBranded()` giờ trả `true` (vì `appNameGUI() != "Nextcloud"`), nên `ConfigFile::currentUpdateChannel()` luôn trả kênh mặc định, bỏ qua toàn bộ logic mà test kiểm tra | **Có** — hệ quả của đổi tên |
| `NextcloudCmdProvisioningTest` | `testnextcloudcmdprovisioning.cpp:160` hardcode `"nextcloudcmd"`/`"nextclouddevcmd"` trong chuỗi trợ giúp mong đợi | **Có** — hệ quả của đổi tên executable |
| `CfApiShellExtensionsIPCTest` | Chạy riêng thì **4 passed, 0 failed**. Hỏng khi chạy chung trong ctest → xung đột IPC giữa các test chạy song song | **Không** — chập chờn do môi trường |
| `RemoteDiscoveryTest` (SEGFAULT) | Chưa rõ, không liên quan vùng code đã sửa | Chưa kết luận |

**Cách sửa đã áp dụng:**

1. `testaccountwizardcontroller.cpp`: thêm hàm `useSelectableServer()` — tạm đưa `Theme` về
   trạng thái "cho chọn server" rồi khôi phục bằng `qScopeGuard`. Hai test kiểm tra trang
   nhập server dùng nó. Cách này **giữ nguyên độ phủ** thay vì xoá test đi.
2. `testupdatechannel.cpp`: `QSKIP` khi `isBranded()`. Hành vi mà test kiểm tra không tồn
   tại trong bản branding, nên skip là câu trả lời trung thực.
3. `testnextcloudcmdprovisioning.cpp`: đổi khẳng định sang `APPLICATION_EXECUTABLE "cmd"`
   thay vì tên hardcode — test giờ đúng cho mọi thương hiệu.

### Lần 4 — sửa xong 3/5 test, truy ra gốc rễ 2 test còn lại

`AccountWizardControllerTest`, `UpdateChannelTest`, và một phần `NextcloudCmdProvisioningTest`
đã pass. Nhưng 5 test provisioning khác vẫn hỏng với mã thoát `-1073740791`
(`STATUS_STACK_BUFFER_OVERRUN`) — tức **crash thật**, không phải sai kỳ vọng.

Chạy `datadrivecmd --userid alice --logdebug` ra nguyên nhân:

```
Discovered legacy config at "C:/Users/tranh/AppData/Roaming/Nextcloud"
Migrate: checking old config
[fatal] QWidget: Cannot create a QWidget without QApplication
```

**Chuỗi nhân quả:**
1. Đổi tên app → client coi thư mục cấu hình `Roaming\Nextcloud` còn sót trên máy này
   (do chính các bản tôi cài thử trước đó) là "cấu hình cũ cần di trú".
2. Đường dẫn di trú mở một **hộp thoại** (QWidget).
3. `datadrivecmd` là app console chạy với `QCoreApplication`, không có `QApplication` → chết.

Đây là code có sẵn từ trước, nhưng chỉ **bị kích hoạt** bởi việc đổi tên cộng với sự tồn tại
của thư mục Nextcloud cũ. Trên máy sạch thì không xảy ra — nên CI của upstream không bắt được.

**Sửa:** bật `DISABLE_ACCOUNT_MIGRATION` và tắt `APPLICATION_DISPLAY_LEGACY_IMPORT_DIALOG`
trong `NEXTCLOUD.cmake`. Đây là lựa chọn đúng về mặt sản phẩm chứ không phải chữa cháy:
DataDrive là sản phẩm mới, không có phiên bản tiền nhiệm để nhập tài khoản sang, và chắc chắn
không nên tự ý đọc cấu hình của phần mềm khác nằm trong hồ sơ người dùng.

Hai công tắc này `CMakeLists.txt:62-63` khai báo bằng `option()`, nhưng `NEXTCLOUD.cmake` được
include ở dòng 30 tức trước đó, và chính sách CMP0077 để yên biến đã được đặt.

### Lần 5 — 85/86 test PASS. Test còn lại đã chứng minh là lỗi upstream

Sau khi tắt di trú tài khoản: **85/86 pass**. Chỉ còn `RemoteDiscoveryTest` (SEGFAULT).

**Không phải do rebrand — đã chứng minh bằng thực nghiệm, không suy đoán:**

Dựng một git worktree tại commit gốc `812334d8f5` (bản Nextcloud chưa sửa một dòng nào),
cấu hình bằng cmake thuần trỏ vào `C:\CraftRoot`, build riêng `RemoteDiscoveryTest` rồi chạy:

| Bản | Kết quả |
|---|---|
| DataDrive (đã rebrand) | crash 4/4 lần, `exit=-1073741819` |
| **Nextcloud gốc, chưa sửa gì** | **crash 3/3 lần, cùng mã lỗi** |

Kết luận: lỗi có sẵn trong upstream trên cấu hình máy này.

**Bản chất lỗi:** `csync_vio_local_readdir()` truy cập bộ nhớ đã giải phóng (0xC0000005).
Log cho thấy crash xảy ra **sau khi** sync đã kết thúc ("Sync run took 5 ms", "Closing DB"),
tức một `DiscoverySingleLocalDirectoryJob` trên thread pool còn sống sót qua lúc dọn dẹp
rồi chạm vào dữ liệu đã chết. Đây là race condition lúc teardown, tái hiện đều đặn trên máy
2 nhân này còn CI nhiều nhân của upstream thì thắng cuộc đua nên không lộ.

**Không sửa.** `csync_vio_local_readdir` nằm trong `src/csync/` — vùng cấm theo Quy tắc 1,
và sửa race trong sync engine nằm ngoài phạm vi đổi thương hiệu.

---

# BÁO CÁO TỔNG KẾT

## Sản phẩm

| Thứ | Đường dẫn |
|---|---|
| **Bộ cài** | `C:\Users\tranh\nextcloud-build\DataDrive-Setup.exe` (42.5 MB) |
| **Shortcut** | `CAI DAT DataDrive` trên màn hình |
| Ứng dụng đã deploy | `C:\CraftRoot\windows-msvc2022_64-cl\bin\datadrive.exe` (10.7 MB) |
| Công cụ dòng lệnh | `datadrivecmd.exe` |

Binary đổi tên đầy đủ: `datadrive.exe`, `datadrivecmd.exe`, `datadrivesync.dll`,
`datadrive_csync.dll`, `datadrivesync_vfs_cfapi.dll`, `datadrivesync_vfs_suffix.dll`.

## Git

Nhánh `branding/datadrive`, **không** đụng `master`. Hai commit:

- `60edd9eee4` — ghim server, ép đăng nhập trong app, nút Home page (9 file)
- `42aa26feb9` — đổi thương hiệu DataDrive (46 file, +812 −30)

## Kiểm chứng

- Build: 5 lần, lần cuối thành công cả 4 bước configure/compile/install/qmerge, 0 lỗi
- Test: **85/86 pass**. Test còn lại (`RemoteDiscoveryTest`) đã chứng minh bằng thực nghiệm
  là lỗi có sẵn của upstream — bản Nextcloud gốc chưa sửa gì crash y hệt
- `clang-format` đã chạy qua hook pre-commit của repo, không còn gì để format
- Chuỗi thương hiệu đã nằm trong binary, xác nhận bằng cách quét `nextcloudsync.dll`

## Chưa làm / cần bạn xem lại

1. **Chưa kiểm chứng bằng mắt.** Chưa ai mở app xem giao diện thật. Test chứng minh logic
   đúng, không thay cho việc nhìn.
2. **`run-clang-tidy` chưa chạy.** `AGENTS.md` yêu cầu. Công cụ đã có trong CraftRoot nhưng
   cần `./build` được cấu hình, trong khi craft build ở `C:\_\<hash>\build`.
3. **Ba icon tạm** — xem mục "Giải pháp tạm".
4. **Ba bản vá ngoài repo** trong `C:\CraftRoot` — xem mục "Vá ngoài repo". Craft có thể ghi đè.
5. **Chuỗi "Nextcloud" còn trong 64 file dịch** — cờ E, cố ý không sửa.
6. **Tài khoản bật 2FA sẽ không đăng nhập được** — hệ quả của việc bỏ luồng trình duyệt.

## Bước tiếp theo nên làm

1. Gỡ bản Nextcloud cũ trong Settings → Apps, rồi chạy `DataDrive-Setup.exe`, kiểm tra:
   tên/icon trong bộ cài, shortcut Start Menu, app mở thẳng trang đăng nhập, nút Home page.
2. Đăng nhập thử tài khoản thật trên `storage.datadrive.vn` (tài khoản **không** bật 2FA).
3. Thiết kế hai icon còn tạm: biến thể lồng thư mục Windows và biến thể tile Start Menu.
4. Cân nhắc đưa ba bản vá blueprint vào một repo blueprint riêng của bạn, thay vì vá tay
   trong `C:\CraftRoot` mỗi lần craft ghi đè.

---

## Sao lưu: đưa file ngoài repo vào `packaging/craft/`

Năm file mà bản build phụ thuộc nhưng trước đó chỉ tồn tại trong `C:\CraftRoot` hoặc thư mục
tạm, nay đã nằm trong repo kèm `README.md` hướng dẫn dựng lại. Mất máy ảo cũng không mất gì.

### Lỗi thứ 5 của blueprint — phát hiện sau khi cài thử

Cài xong không có app để mở. Nguyên nhân: `blacklist.txt` lọc executable bằng whitelist ngược

```
bin/(?!(nextcloud|nextcloudcmd|QtWebEngineProcess)).*\.exe
```

Sau khi đổi tên, `datadrive.exe` rơi vào diện bị loại khỏi gói. Bộ cài vẫn chép đủ 2155 file
và vẫn tạo shortcut, nhưng shortcut trỏ tới file không tồn tại.

**Tôi đã bỏ sót** vì chỉ kiểm tra binary trong `CraftRoot\bin` (nơi build ra, có đủ) mà không
kiểm tra bên trong gói đã đóng. Từ nay phải xác minh ở cả hai chỗ.

### Ba yêu cầu mới, đã làm

| Việc | Cách | Xác nhận trong `.nsi` |
|---|---|---|
| Phiên bản 1.0.0 | `defines["version"]` | `!define version "1.0.0"` |
| Tự mở app sau khi cài | `MUI_FINISHPAGE_RUN` chèn qua placeholder `sections_page` (nằm trước `MUI_PAGE_FINISH`) | `!define MUI_FINISHPAGE_RUN "$INSTDIR\bin\datadrive.exe"` |
| Shortcut ngoài Desktop | `registry_hook`, chạy trong install section | `CreateShortCut "$DESKTOP\DataDrive.lnk"` |

Thêm `Section un.DesktopShortcut` để gỡ cài đặt không để lại shortcut chết — bộ gỡ chỉ biết
dọn thư mục Start Menu.

## Khả năng chạy trên máy Windows khác — đã kiểm chứng

| Yếu tố | Kết quả |
|---|---|
| Runtime MSVC | **Đóng gói kèm** 12 DLL (`msvcp140`, `vcruntime140`...). Máy đích **không cần** cài VC++ Redistributable |
| Kiến trúc | x64 (`machine=0x8664`). Windows ARM64 chạy được qua giả lập |
| Windows tối thiểu | **Windows 10**. `CMakeLists.txt:294` đặt `_WIN32_WINNT=0x0A00`. Windows 7/8 không chạy |
| Dung lượng | Bộ cài 45.8 MB, cài xong chiếm 249 MB |
| Chữ ký số | **KHÔNG CÓ** (`NotSigned`) |

### Vấn đề thật khi phát hành: bộ cài chưa ký

`craftmaster.ini` để `CRAFT_CODESIGN_CERTIFICATE` rỗng và `SIGN_PACKAGE = False`.

Hệ quả trên máy người dùng: Windows SmartScreen chặn với thông báo *"Windows protected your
PC"*, phải bấm "More info" → "Run anyway" mới cài được. Nhiều người sẽ bỏ cuộc ngay tại đó,
và một số phần mềm diệt virus sẽ cách ly file.

Khắc phục: mua chứng thư Code Signing (OV khoảng 200-400 USD/năm, EV khoảng 300-600 USD/năm
nhưng qua SmartScreen ngay lập tức, OV phải tích luỹ uy tín dần). Sau đó ký bằng `signtool`
hoặc đặt `CRAFT_CODESIGN_CERTIFICATE` trong craftmaster.ini.

Đây là việc cần tiền và giấy tờ doanh nghiệp, không phải việc kỹ thuật tôi tự làm được.

---

## Icon khay hệ thống — và một cái bẫy im lặng

### Icon khay là icon *trạng thái*, không phải logo

`Theme::syncStateIcon()` chọn file theo trạng thái đồng bộ. Trong 16 pixel, người dùng cần
biết *đang đồng bộ hay đã xong*, nên vẽ logo suông là không đủ. Bản gốc dùng đĩa tròn xanh
Nextcloud kèm ký hiệu; bản này dùng chữ DD kèm huy hiệu ở góc.

Chỉ 2/6 file bộ màu dính màu thương hiệu cũ (`state-ok`, `state-sync` với gradient
`#0082C9 → #1CAFFF`). Bốn file còn lại dùng đỏ/vàng/xám — đó là màu **ngữ nghĩa trạng thái**,
giữ nguyên vì người dùng đã quen.

Bộ mono `theme/black/` và `theme/white/` hoá ra **không hề mang thương hiệu Nextcloud** — chỉ
là glyph chung (dấu kiểm, dấu nhân, hai vạch). Tôi từng nói ngược lại, đó là nhận định sai.
Việc làm lại chúng không phải sửa rò rỉ mà là *thêm nhận diện* DataDrive.

Cả 3 bộ (20 file SVG) sinh bằng `packaging/craft/make-state-icons.py`. Đổi logo hay bảng màu
thì chạy lại script, không vẽ tay.

### BẪY: đổi SVG không có tác dụng nếu PNG cũ còn tồn tại

`cmake/modules/GenerateIconsUtils.cmake:40`

```cmake
if (EXISTS "${icon_name_dir}/${output_icon_full_name_wle}.png")
  return()
endif()
```

Hàm sinh PNG **bỏ qua khi PNG đã tồn tại**, không so ngày với SVG nguồn. Upstream làm vậy vì
họ commit sẵn PNG vào repo. Ở đây PNG là rác từ build trước, nên mọi thay đổi SVG bị nuốt im
lặng — build vẫn chạy, vẫn đóng gói thành công, chỉ là icon cũ.

Phát hiện bằng cách so ngày: PNG ghi `2026-09-20 15:49`, SVG ghi `2026-09-21 07:27`.

**Quy tắc bắt buộc:** đổi bất kỳ SVG nào trong `theme/` thì phải xoá PNG tương ứng trước khi
build. 200 file PNG trạng thái không nằm trong git, xoá thoải mái.

```bash
find theme/colored theme/black theme/white -name "state-*-*.png" -delete
```

### Lỗi rò rỉ thương hiệu bắt thêm được

`src/gui/folder.cpp:1773` hardcode `.nextcloudsync.log` và `.nextcloudpermissions.log`. Hai file
này ứng dụng tạo **ngay trong thư mục đồng bộ của người dùng**, tức người dùng nhìn thấy. Đã
đổi sang lấy tên từ `Theme::appName()`.

### Ba GUID CfAPI còn sót

`CMakeLists.txt:38,41,45` giữ nguyên GUID của Nextcloud cho AppID, Custom State Handler và
Thumbnail Handler. Lần trước tôi chỉ soi khối `WIN_SHELLEXT` trong `NEXTCLOUD.cmake` nên bỏ sót.
Dùng chung CLSID nghĩa là cài cả hai sản phẩm trên một máy sẽ đè lên nhau. Đã sinh mới cả ba.
