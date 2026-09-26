# JokerFix — 微信 8.0.75 发图修改插件 v0.4

## 为什么这个版本不需要微信类名
不 hook 微信任何类，只 hook UIKit 的稳定 C 函数
（UIImageJPEGRepresentation / UIImagePNGRepresentation），
所以微信改名任何内部类都不影响，8.0.75 直接可用。

## v0.4 修复
- 修复 callerIsWeChat 取错返回地址导致误判、后台线程重绘闪退
- 重绘改用纯 CGContext，后台线程安全
- 启动通知改用 NSNotificationCenter
- 用 dlsym 取符号，避免直接引用导致 dylib 加载失败
- 兼容 rootless /var/jb 路径
- 增加 @try 异常保护

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
编辑设备上的：
- 普通越狱：/var/mobile/Library/Preferences/com.jokerfix.plist
- rootless：/var/jb/var/mobile/Library/Preferences/com.jokerfix.plist

| 键           | 含义                                             | 默认值 |
|--------------|--------------------------------------------------|--------|
| Enabled      | 总开关                                           | true   |
| ReplaceImage | 替换图绝对路径（jpg/png），设置后发出的图变成它  | 自动   |
| Scale        | 等比缩放，0 或 1 = 不改                          | 0      |
| Quality      | JPEG 质量 0~1，负数 = 用微信原参数               | -1     |
| StripMeta    | 去 EXIF/GPS                                      | true   |

替换图默认放：
- 普通越狱：/var/mobile/Library/Preferences/JokerFix_replace.jpg
- rootless：/var/jb/var/mobile/Library/Preferences/JokerFix_replace.jpg

改完后执行（或装 PreferenceLoader 后自动生效）：
  killall -9 WeChat

## 已知限制
- 只对 JPEG/PNG 编码路径生效。若某个发送入口（如原图 HEIC 直传）没走到
  这两个函数，改动不生效。
- 去 EXIF 会同时丢掉方向信息，横拍图可能方向变化。
- 如果替换图路径无效，会自动回退到原图。

## 如果微信闪退
1. 先卸载本插件自救（Filza 删除）：
   - 普通越狱：
     /Library/MobileSubstrate/DynamicLibraries/JokerFix.dylib
     /Library/MobileSubstrate/DynamicLibraries/JokerFix.plist
   - rootless：
     /var/jb/Library/MobileSubstrate/DynamicLibraries/JokerFix.dylib
     /var/jb/Library/MobileSubstrate/DynamicLibraries/JokerFix.plist
   然后 respring（或重启微信）。
2. 抓崩溃日志：
   设置 → 隐私与安全性 → 分析与改进 → 分析数据 →
   最新的 WeChat-*.ips，把 "Termination Reason" 和崩溃线程前 10 行发出来。
3. 告知越狱类型（Dopamine / palera1n / 其他）和 iOS 版本。

## 调试建议
如果还闪退，先把配置里 Enabled 设为 false，确认是否还崩：
- 还崩：问题在 dylib 加载 / hook 安装 / plist 过滤。
- 不崩：问题在 applyModify / redraw / 替换图逻辑。
再把 applyModify 临时改成 `return img;`，只保留 hook 转发，逐步定位。
