import {
  getRandomBytes,
  sha256,
  hkdf,
  hmacSign,
  hmacVerify,
  aesGCMEncrypt,
  aesGCMDecrypt,
} from "./crypto";

/**
 * Encrypt plaintext.
 *
 * @param plaintext Data to encrypt.
 * @returns A promise that resolves to an object containing id, passphrase, passphraseSalt, passphraseDigest, aesIV, and ciphertext.
 */
export async function encrypt(plaintext: Uint8Array) {
  const passphrase = getRandomBytes(64);
  const passphraseSalt = getRandomBytes(64);
  const aesIV = getRandomBytes(12);

  const [id, passphraseDigest, key] = await Promise.all([
    // Create the object's ID
    hmacSign(plaintext, passphrase),

    // Create the passphrase digest
    sha256(passphrase),

    // Derive the AES encryption key using the passphrase and passphrase salt
    hkdf(passphrase, passphraseSalt),
  ]);

  // Encrypt the plaintext with the derived key and random iv
  const ciphertext = await aesGCMEncrypt(plaintext, aesIV, key);

  return {
    id,
    passphrase,
    passphraseSalt,
    passphraseDigest,
    aesIV,
    ciphertext,
  };
}

/**
 * Decrypt ciphertext.
 *
 * @param id ID of this encrypted share link.
 * @param passphrase 64-byte passphrase used to derive the encryption key.
 * @param passphraseSalt 64-byte passphrase salt used to derive encryption key and id.
 * @param aesIV Initialization vector used to encrypt the data.
 * @param ciphertext Encrypted data.
 * @returns A promise that resolves to the plaintext.
 */
export async function decrypt(
  id: Uint8Array,
  passphrase: Uint8Array,
  passphraseSalt: Uint8Array,
  aesIV: Uint8Array,
  ciphertext: Uint8Array
) {
  // Derive the encryption key
  const key = await hkdf(passphrase, passphraseSalt);

  // Decrypt the ciphertext with the derived key and iv
  const plaintext = await aesGCMDecrypt(ciphertext, aesIV, key);

  // Verify the signature (id) is the result of HMAC(plaintext, passphrase)
  const isVerified = await hmacVerify(id, plaintext, passphrase);

  // Final integrity check
  if (!isVerified) {
    // This should never happen! It's either a terrible bug or possibly malicious activity.
    throw new Error("Decrpyted data failed integrity check");
  }

  return plaintext;
}
