# Cryptographic Protocol

This document explains the cryptographic protocol used to implement end-to-end encryption for share links.

### When creating a new share link

* User enters `plaintext`, chooses expiration details (`max_views` and `max_days`), and clicks submit to create a new share link.
* Client uses a CSPRNG to generate a new, random 64-byte `passphrase`.
* Client uses a CSPRNG to generate a new, random 64-byte `passphrase_salt`.
* Client uses a CSPRNG to generate a new, random 12-byte `aes_iv` (initialization vector).
* Client computes `HMAC_SIGN(plaintext, passphrase)` to derive the `id` of this share link. In addition to serving as the primary key, this will later be used as a final authenticity check when decrypting.
* Client computes `SHA256(passphrase)` to derive the `passphrase_digest`. This will later be used to authenticate a request to view the share link's content.
* Client computes `HKDF(passphrase, passphrase_salt)` to derive the 32-byte symmetric encryption `key`.
* Client computes `AES_GCM_ENCRYPT(plaintext, aes_iv, key)` to derive the `ciphertext`.
* Client sends a request to Server. The request contains the `id`, `passphrase_salt`, `passphrase_digest`, `aes_iv`, `ciphertext`, `max_views`, and `max_days`. **NOTE: `key`, `passphrase`, and `plaintext` are NEVER sent to Server.**
* Server validates the share link parameters included in the request and creates a new record for this share link in the database if valid.
* On success, Client reveals the share link URL, i.e., `https://<host>/s/<id>#<passphrase>`, to the user. NOTE: The `passphrase` is in the URL hash so that browsers do not send it to Server.
* User can copy the link and share it with whomever.

### When viewing an existing share link

* User visits the view page using the previously generated share link, i.e., `https://<host>/s/<id>#<passphrase>`.
* Server verifies the share link with this `id` exists.
    * IF it exists and is not considered expired, THEN Server responds with the view page content.
    * ELSE, user is redirected to home page.
* User clicks 'View Secret' button.
* Client takes the `passphrase` from the URL hash and computes `SHA256(passphrase)` to derive the `passphrase_digest`.
* Client sends a request to Server to view this share link. The request includes the `passphrase_digest`.
    * IF the share link is not considered expired AND the `passphrase_digest` matches the entry in the database (thereby authenticating the request), THEN Server increments the share link's `views` and its response includes the `passphrase_salt`, `aes_iv`, and `ciphertext`.
    * ELSE user is notified of an error.
* Client computes `HKDF(passphrase, passphrase_salt)` to derive the 32-byte symmetric encryption `key`.
* Client computes `AES_GCM_DECRYPT(ciphertext, aes_iv, key)` to derive the `plaintext`.
* Using the decrypted `plaintext`, Client verifies that the `id` from the URL is in fact the result of `HMAC_SIGN(plaintext, passphrase)` by computing `HMAC_VERIFY(id, plaintext, passphrase)`.
    * IF HMAC verification fails, something is terribly wrong, and an error will be shown to the user. NOTE: This should never happen.
    * While somewhat redundant with authenticated encryption, this helps ensure the authenticity and integrity of the overall process.
* The `plaintext` is revealed to the user.

### Notes

* The `id` is Base58-encoded.
* The `passphrase` in the URL hash is Base58-encoded.
* The `passphrase_digest` is Base16-encoded.
* The `passphrase_salt`, `aes_iv`, and `ciphertext` are all Base64-encoded.
* Computing the `id` from the `passphrase` and `plaintext` is not strictly necessary. The `id` consists of two secret values: `passphrase` and `plaintext`. This means we're accessing the data by an identifier that corresponds to the underlying content, essentially making the data in the system **content-addressible**. This is a desirable property for this system. While this may be redundant due to use of authenticated encryption, it's nice that it also serves as a final authenticity check that the protocol was executed properly.