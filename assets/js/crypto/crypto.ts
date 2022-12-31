// https://developer.mozilla.org/en-US/docs/Web/API/AesKeyGenParams
// https://developer.mozilla.org/en-US/docs/Web/API/AesGcmParams
// https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/encrypt#iv
const AES_GCM = "AES-GCM";
const AES_KEY_LENGTH_256_BITS = 256;

// https://developer.mozilla.org/en-US/docs/Web/API/CryptoKey
// https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/importKey
// https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/deriveKey
// https://developer.mozilla.org/en-US/docs/Web/API/HmacImportParams
const RAW_FORMAT = "raw";
const HKDF = "HKDF";
const HMAC = "HMAC";
const NOT_EXTRACTABLE = false;
const ENCRYPT_AND_DECRYPT_ONLY: KeyUsage[] = ["encrypt", "decrypt"];
const SIGN_AND_VERIFY_ONLY: KeyUsage[] = ["sign", "verify"];
const DERIVE_KEY_ONLY: KeyUsage[] = ["deriveKey"];

// https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/digest
const SHA_256 = "SHA-256";
const SHA_512 = "SHA-512";

// https://developer.mozilla.org/en-US/docs/Web/API/AesGcmParams
function aesGCMParams(iv: Uint8Array): AesGcmParams {
  return { iv: iv, name: AES_GCM };
}

// https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/importKey
// https://developer.mozilla.org/en-US/docs/Web/API/HmacImportParams
function importHMACKey(key: Uint8Array): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    RAW_FORMAT,
    key,
    { name: HMAC, hash: SHA_256 },
    NOT_EXTRACTABLE,
    SIGN_AND_VERIFY_ONLY
  );
}

// https://developer.mozilla.org/en-US/docs/Web/API/Crypto/getRandomValues
export function getRandomBytes(numberOfBytes: number): Uint8Array {
  return crypto.getRandomValues(new Uint8Array(numberOfBytes));
}

// https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/digest
export async function sha256(data: Uint8Array): Promise<Uint8Array> {
  const buffer = await crypto.subtle.digest(SHA_256, data);
  return new Uint8Array(buffer);
}

// https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/deriveKey#hkdf
export async function hkdf(
  sourceKeyMaterial: Uint8Array,
  salt: Uint8Array
): Promise<CryptoKey> {
  const sourceKey = await crypto.subtle.importKey(
    RAW_FORMAT,
    sourceKeyMaterial,
    HKDF,
    NOT_EXTRACTABLE,
    DERIVE_KEY_ONLY
  );

  return crypto.subtle.deriveKey(
    {
      name: HKDF,
      salt: salt,
      info: new Uint8Array(0), // We're only using this function for generating a single key from single-use, random inputs. No domain separation needed.
      hash: SHA_512,
    },
    sourceKey,
    { name: AES_GCM, length: AES_KEY_LENGTH_256_BITS },
    NOT_EXTRACTABLE,
    ENCRYPT_AND_DECRYPT_ONLY
  );
}

// https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/sign
export async function hmacSign(
  data: Uint8Array,
  key: Uint8Array
): Promise<Uint8Array> {
  const buffer = await crypto.subtle.sign(HMAC, await importHMACKey(key), data);
  return new Uint8Array(buffer);
}

// https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/verify
export async function hmacVerify(
  signature: Uint8Array,
  data: Uint8Array,
  key: Uint8Array
): Promise<boolean> {
  return crypto.subtle.verify(HMAC, await importHMACKey(key), signature, data);
}

// https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/encrypt
export async function aesGCMEncrypt(
  plaintext: Uint8Array,
  iv: Uint8Array,
  key: CryptoKey
): Promise<Uint8Array> {
  const buffer = await crypto.subtle.encrypt(aesGCMParams(iv), key, plaintext);
  return new Uint8Array(buffer);
}

// https://developer.mozilla.org/en-US/docs/Web/API/SubtleCrypto/decrypt
export async function aesGCMDecrypt(
  ciphertext: Uint8Array,
  iv: Uint8Array,
  key: CryptoKey
): Promise<Uint8Array> {
  const buffer = await crypto.subtle.decrypt(aesGCMParams(iv), key, ciphertext);
  return new Uint8Array(buffer);
}
