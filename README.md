# JokerFix — 微信 8.0.75 发图修改插件

## 为什么这个版本不需要微信类名
不 hook 微信任何类，只 hook UIKit 的稳定 C 函数
（UIImageJPEGRepresentation / UIImagePNGRepresentation），
所以微信改名任何内部类都不影响，8.0.75 直接可用。

## 编译（在一台 Mac 上，约 10 分钟）
1. 安装依赖：
   brew install ldid dpkg
2. 拉 theos：
   git clone --recursive https://github.com/theos/theos ~/theos
3. 编译打包：
   cd JokerFix
   make package        # 产物在 packages/*.deb
4. 安装（设备已越狱、装了 OpenSSH，和 Mac 同一局域网）：
   make install
   或把 .deb 拷到设备用 Filza 安装。

## 配置
编辑设备上的 /var/mobile/Library/Preferences/com.jokerfix.plist：

| 键          | 含义                                        | 默认值 |
|-------------|---------------------------------------------|--------|
| Enabled     | 总开关                                      | true   |
| ReplaceImage| 替换图绝对路径（jpg/png），设置后发出的图变成它 | ...JokerFix_replace.jpg |
| Scale       | 等比缩放，0 或 1 = 不改                     | 0      |
| Quality     | JPEG 质量 0~1，负数 = 用微信原参数          | -1     |
| StripMeta   | 去 EXIF/GPS                                 | true   |

改完后执行（或装 PreferenceLoader 后自动生效）：
  killall -9 WeChat  # 通知是即时监听，不杀也行，但建议重启微信确认

替换图放到 /var/mobile/Library/Preferences/JokerFix_replace.jpg

## 已知限制
- 只对 JPEG/PNG 编码路径生效。若某个发送入口（如原图 HEIC 直传）没走到
  这两个函数，改动不生效——用 Frida hook UIImageJPEGRepresentation
  打回溯栈确认编码点后，把 hook 点挪过去即可（改两行）。

## 如果微信闪退
1. 先卸载本插件自救（在 Filza 删除）：
     /var/jb/Library/MobileSubstrate/DynamicLibraries/JokerFix.dylib
     /var/jb/Library/MobileSubstrate/DynamicLibraries/JokerFix.plist
   然后 respring（或重启微信）。
2. 抓取崩溃日志反馈：设置 → 隐私与安全性 → 分析与改进 → 分析数据 →
   最新的 WeChat-*.ips，把 "Termination Reason" 和崩溃线程前 10 行发出来。
3. 告知越狱类型（Dopamine / palera1n / 其他）和 iOS 版本。
