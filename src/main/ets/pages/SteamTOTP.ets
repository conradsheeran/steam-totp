/*
 * Copyright (c) 2024 Yang He
 *
 * TickAuth is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

import { GenerateHMAC } from "./GenerateHMAC"
import { http } from '@kit.NetworkKit';
import buffer from '@ohos.buffer';
import { util } from '@kit.ArkTS';
import hash from "@ohos.file.hash";

interface ITimeOffsetInfo {
  offset: number;
  latency: number;
}

interface IResponse {
  server_time: string;
  skew_tolerance_seconds: string;
  large_time_jink: string;
  probe_frequency_seconds: number;
  adjusted_time_probe_frequency_seconds: number,
  hint_probe_frequency_seconds: number,
  sync_timeout: number,
  try_again_seconds: number,
  max_attempts: number
}

export class SteamTOTP {
  /**
   * 返回当前的 Unix 时间戳
   * @param timeOffset - 与 Steam 服务器的时间偏移量，单位为秒
   * @returns {number}
   */
  public static time(timeOffset: number = 0): number {
    return Math.floor(Date.now() / 1000) + timeOffset;
  }

  /**
   * 生成 Steam 的 TOTP 身份验证代码
   * @param secret - TOTP 的 shared_secret，可以是 Buffer、hex 或 base64
   * @param timeOffset - 时间偏移量，单位为秒
   * @returns {string}
   */
  public static async generateAuthCode(secret: buffer.Buffer | string, timeOffset: number = 0): Promise<string> {
    const secretBuffer: buffer.Buffer = SteamTOTP.SecretToBuffer(secret);

    const time = SteamTOTP.time(timeOffset);
    const Buffer = buffer.alloc(8);

    Buffer.writeBigUInt64BE(BigInt(Math.floor(time / 30)), 0);

    const hmac = await GenerateHMAC(secretBuffer.buffer, Buffer.buffer, "SHA1")

    const start = hmac[19] & 0x0f;
    const codeBuffer = buffer.from(hmac.subarray(start, start + 4))

    let fullcode = codeBuffer.readUInt32BE(0) & 0x7fffffff;
    const map = '23456789BCDFGHJKMNPQRTVWXY';

    let code = '';
    for (let i = 0; i < 5; i++) {
      code += map.charAt(fullcode % map.length);
      fullcode = Math.floor(fullcode / map.length);
    }

    return code;
  }

  /**
   * 生成用于移动交易确认的 base64 确认密钥。该密钥只能使用一次。
   * @param identitySecret - 启用双重身份验证时获得的 identity_secret
   * @param time - 生成 secret 的 Unix 时间戳，通常为当前时间
   * @param tag - 标识请求的标签，例如 "conf"、"details"、"allow"、"cancel"
   * @returns {string}
   */
  public static async generateConfirmationKey(identitySecret: buffer.Buffer | string, time: number, tag: string = ''): Promise<string> {
    const secretBuffer: buffer.Buffer = SteamTOTP.SecretToBuffer(identitySecret);

    const data = buffer.alloc(8 + buffer.byteLength(tag));
    data.writeBigUInt64BE(BigInt(time), 0);
    if (tag) {
      data.write(tag, 8);
    }

    const hmac = await GenerateHMAC(secretBuffer.buffer, data.buffer, "SHA1");
    return new util.Base64Helper().encodeToStringSync(hmac);
  }

  /**
   * 从 Steam 服务器获取时间偏移量
   * @returns {Promise<{ offset: number; latency: number; }>}
   */
  public static async getTimeOffset(): Promise<ITimeOffsetInfo> {
    const start = Date.now();

    return new Promise((resolve, reject) => {
      let https = http.createHttp()

      https.request(
        "http://api.steampowered.com/ITwoFactorService/QueryTime/v1/",
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Length': '0'
          }
        },
        (e: Error, req: http.HttpResponse) => {
          if (!e) {
            try {

              const parsedResponse: IResponse = JSON.parse(req.result as string).response;
              if (!parsedResponse || !parsedResponse.server_time) {
                throw new Error('响应格式错误');
              }

              const end = Date.now();
              const offset = Number(parsedResponse.server_time) - SteamTOTP.time();
              const value: ITimeOffsetInfo = { offset: offset, latency: end - start }

              resolve(value);
            } catch (e) {
              reject(new Error('响应解析失败'));
            }
          } else {
            //
          }
      });
    });
  }

  /**
   * 基于 SteamID 获取标准化的设备 ID
   * @param steamID - 你的 SteamID
   * @returns {string}
   */
  public static async getDeviceID(steamID: string): Promise<string> {
    const hs = hash.createHash('sha1');
    hs.update(SteamTOTP.SecretToBuffer(steamID).buffer)
    const hashed = hs.digest().toLowerCase()
    const id = [
      hashed.slice(0, 8),
      hashed.slice(8, 12),
      hashed.slice(12, 16),
      hashed.slice(16, 20),
      hashed.slice(20, 32),
    ].join('-');

    return `android:${id}`;
  }

  /**
   * 如果 secret 是字符串格式，则将其转换为 Buffer
   * @param secret - 作为 Buffer、hex 或 base64 字符串的 secret
   * @returns {Buffer}
   */
  private static SecretToBuffer(secret: buffer.Buffer | string): buffer.Buffer {
    if (buffer.isBuffer(secret)) {
      return secret as buffer.Buffer;
    } else if (/^[0-9a-f]{40}$/i.test(secret as string)) {
      return buffer.from(secret as string, 'hex');
    } else {
      return buffer.from(secret as string, 'base64');
    }
  }
}