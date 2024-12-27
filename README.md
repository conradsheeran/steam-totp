# steam-totp

使用 ArkTS 语言开发的实现获取 Steam 手机令牌验证码的库

## 注意：

1. **最低API要求**：API 12（5.0.0.102）
2. **权限要求**: ohos.permission.INTERNET ( 用于获取服务器时间 )

- 关于系统权限申请, 请参考 [HarmonyOS 开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/declare-permissions-V5)

## 安装指南：

### 方法一：从 ohpm 安装 (推荐)
1. 通过 DevEco Studio 打开您的项目
2. 在 DevEco Studio 的终端运行：

```bash
ohpm install steam-totp
```

### 方法二：从 Github Release 安装
1. 从 [Github Release](https://github.com/conradsheeran/steam-totp/releases) 下载所需 HAR 共享包
2. 在 DevEco Studio 的终端运行：

```bash
ohpm install path/to/steam-totp.har
```

### 方法三: 在 oh-package.json5 中设置依赖

```json
{
  "dependencies": {
    "steam-totp": "^1.0.1"
  }
}
```

## 使用方法

### 1. generateAuthCode(secret: buffer.Buffer | string, timeOffset: number = 0)

```typescript
import { SteamTOTP } from "steam-totp"

const code: string = await SteamTOTP.generateAuthCode(your_secret)

// 通过获取服务器时间以传入 timeOffset
const timeOffset: number = (await getTimeOffset()).offset
const code: string = await SteamTOTP.generateAuthCode(your_secret, timeOffset)
```

### 2. generateConfirmationCode(identitySecret: buffer.Buffer | string, time: number, tag: string)

```typescript
const timeOffset: number = (await getTimeOffset()).offset
const time: number = SteamTOTP.time(timeOffset)
const tag: string = "allow"
const code: string = await SteamTOTP.generateConfirmationCode(your_identitySecret, time, tag)
```

### 3. getDeviceID(steamID: string)

```typescript
const deviceID: string = await SteamTOTP.getDeviceID(your_steamID)
```