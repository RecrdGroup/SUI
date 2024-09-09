import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";

export type AddressEntry = {
  address: string;
  secretKey: string;
};

export const generate = (size: number) => {
  const addresses: AddressEntry[] = [];
  for (let i = 0; i < size; i++) {
    const signer = new Ed25519Keypair();
    const address = signer.toSuiAddress();
    const secretKey = signer.getSecretKey();
    addresses.push({ address, secretKey });
  }
  return addresses;
};
