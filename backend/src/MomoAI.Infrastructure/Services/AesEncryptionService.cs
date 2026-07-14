using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;
using MomoAI.Application.Interfaces;

namespace MomoAI.Infrastructure.Services;

/// <summary>
/// AES-256-CBC encryption service for encrypting memories at rest.
/// Uses a unique IV per encryption operation for semantic security.
/// The encrypted payload format is: [16-byte IV][ciphertext], Base64 encoded.
/// </summary>
public class AesEncryptionService : IEncryptionService
{
    private readonly byte[] _key;

    public AesEncryptionService(IOptions<EncryptionOptions> options)
    {
        var keyString = options.Value.AesKey;

        if (string.IsNullOrWhiteSpace(keyString))
        {
            // Generate a random key for development mode (non-persistent)
            _key = RandomNumberGenerator.GetBytes(32);
            return;
        }

        _key = Convert.FromBase64String(keyString);

        if (_key.Length != 32)
        {
            throw new InvalidOperationException(
                "AES-256 requires a 256-bit (32-byte) key. The configured key has an invalid length.");
        }
    }

    /// <inheritdoc />
    public string Encrypt(string plainText)
    {
        if (string.IsNullOrEmpty(plainText))
            return plainText;

        using var aes = Aes.Create();
        aes.KeySize = 256;
        aes.Mode = CipherMode.CBC;
        aes.Padding = PaddingMode.PKCS7;
        aes.Key = _key;
        aes.GenerateIV(); // Unique IV per encryption

        using var encryptor = aes.CreateEncryptor(aes.Key, aes.IV);
        var plainBytes = Encoding.UTF8.GetBytes(plainText);
        var cipherBytes = encryptor.TransformFinalBlock(plainBytes, 0, plainBytes.Length);

        // Prepend IV to ciphertext: [IV (16 bytes)][ciphertext]
        var result = new byte[aes.IV.Length + cipherBytes.Length];
        Buffer.BlockCopy(aes.IV, 0, result, 0, aes.IV.Length);
        Buffer.BlockCopy(cipherBytes, 0, result, aes.IV.Length, cipherBytes.Length);

        return Convert.ToBase64String(result);
    }

    /// <inheritdoc />
    public string Decrypt(string cipherText)
    {
        if (string.IsNullOrEmpty(cipherText))
            return cipherText;

        var fullCipher = Convert.FromBase64String(cipherText);

        using var aes = Aes.Create();
        aes.KeySize = 256;
        aes.Mode = CipherMode.CBC;
        aes.Padding = PaddingMode.PKCS7;
        aes.Key = _key;

        // Extract IV from the first 16 bytes
        var iv = new byte[16];
        Buffer.BlockCopy(fullCipher, 0, iv, 0, iv.Length);
        aes.IV = iv;

        // Extract ciphertext after IV
        var cipherBytes = new byte[fullCipher.Length - iv.Length];
        Buffer.BlockCopy(fullCipher, iv.Length, cipherBytes, 0, cipherBytes.Length);

        using var decryptor = aes.CreateDecryptor(aes.Key, aes.IV);
        var plainBytes = decryptor.TransformFinalBlock(cipherBytes, 0, cipherBytes.Length);

        return Encoding.UTF8.GetString(plainBytes);
    }
}

/// <summary>
/// Configuration options for encryption services.
/// </summary>
public class EncryptionOptions
{
    public const string SectionName = "Security";

    /// <summary>
    /// Base64-encoded 256-bit AES key for memory encryption at rest.
    /// Generate with: Convert.ToBase64String(RandomNumberGenerator.GetBytes(32))
    /// </summary>
    public string AesKey { get; set; } = string.Empty;
}
