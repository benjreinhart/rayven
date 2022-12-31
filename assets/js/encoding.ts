import base from "../vendor/base-x";
import { Base64 as _base64 } from "../vendor/base64.mjs";

const utf8Decoder = new TextDecoder();
const utf8Encoder = new TextEncoder();

export const UTF8 = {
  encode(data: Uint8Array): string {
    return utf8Decoder.decode(data);
  },

  decode(data: string): Uint8Array {
    return utf8Encoder.encode(data);
  },
};

const BASE_58_ALPHABET =
  "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
const _Base58 = base(BASE_58_ALPHABET);

export const Base58 = {
  encode(data: Uint8Array): string {
    return _Base58.encode(data);
  },

  decode(data: string): Uint8Array {
    return _Base58.decode(data);
  },
};

export const Base64 = {
  encode(data: Uint8Array, urlsafe: boolean = false): string {
    return _base64.fromUint8Array(data, urlsafe);
  },

  decode(data: string): Uint8Array {
    // Handles both URL safe and non-URL safe base64.
    return _base64.toUint8Array(data);
  },
};

export const Base16 = {
  encode(data: Uint8Array): string {
    let result = "";
    for (const byte of data) {
      result += byte.toString(16).padStart(2, "0");
    }
    return result;
  },

  decode(data: string): Uint8Array {
    if (data.length % 2 !== 0) {
      throw new Error("Hex string must have an even length");
    }
    const bufferLength = data.length / 2;
    const buffer = new Uint8Array(bufferLength);
    for (let i = 0; i < bufferLength; ++i) {
      const hex = data.substring(i * 2, i * 2 + 2);
      const byte = parseInt(hex, 16);
      if (Number.isNaN(byte) || byte < 0 || byte > 255) {
        throw new Error(`Invalid hex "${hex}" at index ${i * 2}`);
      }
      buffer[i] = byte;
    }
    return buffer;
  },
};
