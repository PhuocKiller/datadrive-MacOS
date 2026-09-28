# Dọn những gì DataDrive tự ghi ra lúc chạy. Bộ gỡ cài đặt của NSIS chỉ biết xoá thứ nó
# đã cài, nên nếu thiếu bước này thì Explorer vẫn còn mục DataDrive trỏ vào phần mềm đã biến mất.
#
# Về thư mục đồng bộ: file placeholder chỉ là con trỏ tới đám mây, chiếm 0 byte, và không thể
# mở được nữa một khi phần mềm hydrat hoá chúng đã bị gỡ. Xoá chúng không đụng tới dữ liệu trên
# server. File đã tải về thật thì giữ lại, vì đó mới là bản sao cục bộ duy nhất người dùng có.
$ErrorActionPreference = "SilentlyContinue"

$appName = "DataDrive"
$configDir = Join-Path $env:APPDATA $appName
$configFile = Join-Path $configDir "datadrive.cfg"

# FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS | FILE_ATTRIBUTE_OFFLINE
$placeholderMask = 0x400000 -bor 0x1000

# 1. Dọn placeholder trong từng thư mục đồng bộ ghi trong cấu hình.
if (Test-Path $configFile) {
    $syncFolders = Select-String -Path $configFile -Pattern '^\s*localPath\s*=\s*(.+)$' |
        ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() } |
        Sort-Object -Unique

    foreach ($folder in $syncFolders) {
        if (-not (Test-Path -LiteralPath $folder)) { continue }

        Get-ChildItem -LiteralPath $folder -Recurse -File -Force |
            Where-Object { $_.Attributes -band $placeholderMask } |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }

        # Sổ sách của chính ứng dụng nằm lẫn trong thư mục người dùng: nhật ký đồng bộ, database
        # journal, và Desktop.ini mà ứng dụng ghi ra để đặt icon thư mục. Không phải tài liệu,
        # và vô dụng một khi ứng dụng đã bị gỡ.
        $ownBookkeeping = @(".sync_*.db*", "._sync_*.db*", ".*sync.log", ".*permissions.log", "Desktop.ini")
        Get-ChildItem -LiteralPath $folder -Recurse -File -Force -Include $ownBookkeeping |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }

        # Thư mục rỗng còn lại sau khi placeholder biến mất cũng không còn ý nghĩa gì.
        # Lặp vì xoá thư mục con có thể làm thư mục cha thành rỗng theo.
        for ($pass = 0; $pass -lt 8; $pass++) {
            $empty = Get-ChildItem -LiteralPath $folder -Recurse -Directory -Force |
                Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Force) }
            if (-not $empty) { break }
            $empty | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
        }

        # Thư mục gốc chỉ xoá khi đã hoàn toàn trống, tức không còn file nào từng được tải về.
        if (-not (Get-ChildItem -LiteralPath $folder -Force)) {
            Remove-Item -LiteralPath $folder -Force
        }
    }
}

# 2. Cấu hình và cookie.
Remove-Item -LiteralPath $configDir -Recurse -Force
Remove-Item -LiteralPath (Join-Path $env:LOCALAPPDATA $appName) -Recurse -Force

# 3. Shell extension và mục Explorer. CLSID của mục điều hướng do ứng dụng sinh ngẫu nhiên cho
#    mỗi thư mục đồng bộ, nên phải quét theo tên chứ không liệt kê cứng được.
$registryRoots = @(
    "HKCU:\SOFTWARE\Classes\CLSID",
    "HKCU:\SOFTWARE\Classes\AppID",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace"
)
foreach ($root in $registryRoots) {
    Get-ChildItem $root | ForEach-Object {
        $name = (Get-ItemProperty $_.PSPath).'(default)'
        if ($name -like "*$appName*") { Remove-Item -LiteralPath $_.PSPath -Recurse -Force }
    }
}

# 4. Mật khẩu trong Windows Credential Manager.
cmdkey /list | Select-String "Target:" | ForEach-Object {
    $target = ($_ -replace "^\s*Target:\s*", "").Trim() -replace "^LegacyGeneric:target=", ""
    if ($target -like "*$appName*") { cmdkey /delete:$target }
}
