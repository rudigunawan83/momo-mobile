namespace MomoAI.Application.Interfaces;

/// <summary>
/// Provides AES-256 encryption/decryption for data at rest (memories).
/// </summary>
public interface IEncryptionService
{
    /// <summary>
    /// Encrypts plaintext content using AES-256.
    /// Returns a Base64-encoded string containing IV + ciphertext.
    /// </summary>
    /// <param name="plainText">The text to encrypt.</param>
    /// <returns>Base64-encoded encrypted payload (IV prepended).</returns>
    string Encrypt(string plainText);

    /// <summary>
    /// Decrypts an AES-256-encrypted Base64 payload back to plaintext.
    /// </summary>
    /// <param name="cipherText">Base64-encoded encrypted payload (IV prepended).</param>
    /// <returns>The original plaintext.</returns>
    string Decrypt(string cipherText);
}
