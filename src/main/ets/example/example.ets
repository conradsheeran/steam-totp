import { SteamTOTP } from "../pages/SteamTOTP"
import { BusinessError } from "@kit.BasicServicesKit";
import { util } from "@kit.ArkTS";

interface ISteamSecret {
  shared_secret: string;
  serial_number: string;
  revocation_code: string;
  uri: string;
  server_time: number;
  account_name: string;
  token_gid: string;
  identity_secret: string;
  secret_1: string;
  status: number;
  device_id: string;
  fully_enrolled: boolean;
  Session: string;
  SessionID: number;
}

getContext(this).resourceManager.getRawFileContent("765122925.maFile").then(async (content) => {
  let steamSecret = JSON.parse(bufferToString(content)) as ISteamSecret;
  console.info(`code: ${(await SteamTOTP.generateAuthCode(steamSecret.shared_secret))}`)
}).catch((e: BusinessError) => {
  console.error(`fatal: ${e.message}, ${e.code}`)
})

function bufferToString(buffer: Uint8Array): string {
  let textDecoder = util.TextDecoder.create('utf-8', {
    ignoreBOM: true
  });
  let resultPut = textDecoder.decodeToString(buffer);
  return resultPut;
}