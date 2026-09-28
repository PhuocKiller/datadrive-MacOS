<!--
SPDX-FileCopyrightText: 2026 Tran Huy Phuoc
SPDX-License-Identifier: GPL-2.0-or-later
-->

# Dựng lại môi trường đóng gói DataDrive

Thư mục này giữ những file **nằm ngoài repo** mà bản build DataDrive phụ thuộc vào.
Craft đặt chúng trong `C:\CraftRoot` và tự đồng bộ bằng git, nên bản sửa của chúng ta
có thể bị ghi đè bất cứ lúc nào. Đây là bản gốc để chép lại.

Mất máy, cài lại Windows, hay craft ghi đè blueprint — chỉ cần repo này là dựng lại được.

## Nguồn thật nằm ở đâu

| Thư mục | Vai trò | Cần sao lưu? |
|---|---|---|
| `C:\projects\datadrive` | **Mã nguồn.** Repo git này | **Có** — đây là thứ duy nhất không thể tạo lại |
| `C:\CraftRoot` | Bộ công cụ + thư viện + sản phẩm build. ~10 GB | Không. Craft tải lại được, trừ 2 file trong thư mục này |

## File trong thư mục này

| File | Chép tới đâu |
|---|---|
| `nextcloud-client.py` | `C:\CraftRoot\windows-msvc2022_64-cl\etc\blueprints\locations\craft-blueprints-nextcloud\nextcloud-client\` |
| `blacklist.txt` | cùng thư mục trên |
| `craft.ps1` | chạy từ bất cứ đâu |
| `lowmem-override.ini` | cạnh `craft.ps1` |
| `make-installer-art.py` | chạy để sinh lại ảnh bộ cài từ `Logo/` và `BackGround/` |

## Vì sao phải vá blueprint

Blueprint gốc của Nextcloud có năm chỗ không dùng được cho bản branding:

1. **Thiếu `import os`** — lỗi thật của upstream, khiến đóng gói chết ngay với `NameError`.
2. **`applicationExecutable`** là thuộc tính craft không còn đọc. Thiếu `defines["executable"]`
   thì bộ cài **không tạo shortcut nào**.
3. **Chuỗi thương hiệu** (`appname`, `company`, `displayName`, `webpage`) hardcode tên Nextcloud.
4. **`blacklist.txt`** lọc executable bằng whitelist ngược
   `bin/(?!(nextcloud|nextcloudcmd|QtWebEngineProcess)).*\.exe` — sau khi đổi tên thì chính
   `datadrive.exe` bị loại khỏi gói, cài xong không có app để mở.
5. **`icon` và `version`** mặc định là `craft.ico` và tên nhánh git.

Ngoài ra thêm: tự mở app sau khi cài, shortcut ngoài Desktop, và gỡ shortcut đó khi uninstall.

## Dựng lại từ đầu trên máy mới

```powershell
# 1. Công cụ nền
#    - Visual Studio Build Tools 2022 kèm toolset v143 (VS 2026 KHÔNG đủ, craft
#      lọc theo -version [17,18) và component VC.Tools.x86.x64)
#    - Python 3.12 cài vào C:\Python312-x64 (đường dẫn craftmaster.ini yêu cầu)
#    - Inkscape (cmake cần nó sinh icon PNG từ SVG)
#    - pip install clang-format pillow

# 2. Craft
git clone https://invent.kde.org/packaging/craftmaster.git C:\CraftMaster

# 3. Blueprint
.\craft.ps1 --add-blueprint-repository "https://github.com/nextcloud/craft-blueprints-kde.git|stable-34.0|"
.\craft.ps1 --add-blueprint-repository "https://github.com/nextcloud/craft-blueprints-nextcloud.git|stable-34.0|"
.\craft.ps1 craft
.\craft.ps1 --install-deps nextcloud-client
.\craft.ps1 nsis

# 4. CHÉP HAI FILE VÁ ĐÈ LÊN BLUEPRINT VỪA TẢI VỀ
#    nextcloud-client.py và blacklist.txt

# 5. Build và đóng gói
.\craft.ps1 --src-dir C:\projects\datadrive --configure --compile --install --qmerge nextcloud-client
.\craft.ps1 --package --src-dir C:\projects\datadrive nextcloud-client
```

## Hai cái bẫy đã mất thời gian, đừng vấp lại

**CMake cache không bao giờ ghi đè giá trị cũ.** `APPLICATION_SERVER_URL` khai báo bằng
`set(... CACHE STRING ...)`. Sửa `NEXTCLOUD.cmake` mà build dir cũ còn tồn tại thì giá trị cũ
vẫn được dùng. Phải xoá `C:\_\<hash>\build` rồi configure lại.

**Craft bỏ qua khi tưởng đã xong.** Chạy `craft nextcloud-client` sau khi sửa code có thể ra
`*** nextcloud-client is up to date, nothing to do ***` và không biên dịch gì. Phải liệt kê
hành động rõ ràng: `--configure --compile --install --qmerge`.
