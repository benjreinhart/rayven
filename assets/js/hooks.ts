import { sha256 } from "./crypto/crypto";
import { encrypt, decrypt } from "./crypto";
import { Base16, Base58, Base64, UTF8 } from "./encoding";

function isBlankString(value: any) {
  const isPresent = typeof value === "string" && /\S+/.test(value);
  return !isPresent;
}

interface HookContext {
  el: HTMLElement;
  pushEvent(event: string, data?: any, callback?: (data: any) => {}): void;
}

export function mountCreateFormHook(window: Window, context: HookContext) {
  const document = window.document;

  const body = document.querySelector("body") as HTMLBodyElement;

  const createForm = context.el as HTMLDivElement;

  const plaintextInput = createForm.querySelector(
    "#plaintext"
  ) as HTMLInputElement;

  const maxViewsInput = createForm.querySelector(
    "#max-views"
  ) as HTMLSelectElement;

  const maxDaysInput = createForm.querySelector(
    "#max-days"
  ) as HTMLSelectElement;

  createForm.addEventListener("submit", async (e) => {
    const plaintext = plaintextInput.value;

    // DO NOT allow an empty string, but DO allow a whitespace-only (blank) string.
    if (typeof plaintext !== "string" || plaintext === "") {
      plaintextInput.focus();
      return;
    }

    const {
      id,
      passphrase,
      passphraseSalt,
      passphraseDigest,
      aesIV,
      ciphertext,
    } = await encrypt(UTF8.decode(plaintextInput.value));

    // We're building *end-to-end* encrypted storage here, so it is imperative
    // that the passphrase is secure and NEVER touches the server. With that...
    //
    // When creating a new link of encrypted content, we create the link and
    // THEN navigate to the share form. We need to keep the passphrase somewhere
    // accessible temporarily because it is needed to construct the share link
    // that is presented to the user. Navigating to the share form happens
    // live, so the entire page isn't refreshed. This allows us to store the
    // passphrase *in the DOM* rather than in the URL hash, cookies, localStorage, etc.
    // This is the safest method because it reduces the likelihood that the passphrase
    // ends up lingering somewhere not intended, like the user's local storage,
    // cookies, or browser history.
    body.dataset.passphrase = Base58.encode(passphrase);

    context.pushEvent("submit", {
      link: {
        id: Base58.encode(id),
        passphrase_salt: Base64.encode(passphraseSalt),
        passphrase_digest: Base16.encode(passphraseDigest),
        aes_iv: Base64.encode(aesIV),
        ciphertext: Base64.encode(ciphertext),
        max_views: maxViewsInput.value,
        max_days: maxDaysInput.value,
      },
    });
  });
}

export function mountShareFormHook(window: Window, context: HookContext) {
  const document = window.document;

  const body = document.querySelector("body") as HTMLBodyElement;
  const shareForm = context.el as HTMLDivElement;

  const passphrase = body.dataset.passphrase;
  const linkId = shareForm.dataset.linkId;
  const input = shareForm.querySelector("input") as HTMLInputElement;
  const origin = window.location.origin.replace(/\/*$/, "");

  if (isBlankString(passphrase)) {
    input.value = "TODO: error state when passphrase is not present";
  } else {
    // The passphrase must be in the URI hash so that browsers DO NOT send it to the server.
    input.value = `${origin}/s/${linkId}#${passphrase}`;
  }

  input.onfocus = () => {
    input.select();
  };
}

export function mountViewButtonHook(window: Window, context: HookContext) {
  const viewButton = context.el as HTMLButtonElement;

  viewButton.addEventListener("click", async () => {
    const passphraseFromHash = window.location.hash.replace(/^#/, "");
    const passphrase = Base58.decode(passphraseFromHash);
    const passphraseDigest = await sha256(passphrase);
    context.pushEvent("view", {
      passphrase_digest: Base16.encode(passphraseDigest),
    });
  });
}

export async function mountViewFormHook(window: Window, context: HookContext) {
  const idFromURL = window.location.pathname.replace(/^\/s\//, "");
  const id = Base58.decode(idFromURL);

  const passphraseFromHash = window.location.hash.replace(/^#/, "");
  const passphrase = Base58.decode(passphraseFromHash);

  const viewForm = context.el as HTMLDivElement;

  const passphraseSaltFromEl = viewForm.dataset.passphraseSalt as string;
  const passphraseSalt = Base64.decode(passphraseSaltFromEl);

  const aesIVFromEl = viewForm.dataset.aesIv as string;
  const aesIV = Base64.decode(aesIVFromEl);

  const ciphertextFromEl = viewForm.dataset.ciphertext as string;
  const ciphertext = Base64.decode(ciphertextFromEl);

  const plaintext = await decrypt(
    id,
    passphrase,
    passphraseSalt,
    aesIV,
    ciphertext
  );

  const plaintextInput = viewForm.querySelector(
    "#plaintext"
  ) as HTMLTextAreaElement;

  // Reveal the plaintext to the user
  plaintextInput.value = UTF8.encode(plaintext);
}
