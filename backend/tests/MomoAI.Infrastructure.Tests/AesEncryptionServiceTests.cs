using System.Security.Cryptography;
using Microsoft.Extensions.Options;
using MomoAI.Infrastructure.Services;

namespace MomoAI.Infrastructure.Tests;

/// <summary>
/// Unit tests for AesEncryptionService verifying AES-256 encryption/decryption for memories at rest.
/// Validates requirement 13.2: THE Momo_System SHALL encrypt memories at rest using AES-256.
/// </summary>
public class AesEncryptionServiceTests
{
    private readonly AesEncryptionService _service;
    private readonly string _validKey;

    public AesEncryptionServiceTests()
    {
        // Generate a valid 256-bit key for testing
        _validKey = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        var options = Options.Create(new EncryptionOptions { AesKey = _validKey });
        _service = new AesEncryptionService(options);
    }

    [Fact]
    public void Encrypt_WithValidText_ReturnsNonEmptyBase64()
    {
        var plainText = "Hello, this is a secret memory!";

        var encrypted = _service.Encrypt(plainText);

        Assert.NotEmpty(encrypted);
        Assert.NotEqual(plainText, encrypted);
        // Verify it's valid Base64
        Assert.NotNull(Convert.FromBase64String(encrypted));
    }

    [Fact]
    public void Decrypt_AfterEncrypt_ReturnsOriginalText()
    {
        var plainText = "Momo remembers: user likes pizza and coding.";

        var encrypted = _service.Encrypt(plainText);
        var decrypted = _service.Decrypt(encrypted);

        Assert.Equal(plainText, decrypted);
    }

    [Fact]
    public void Encrypt_SameTextTwice_ProducesDifferentCiphertexts()
    {
        // Each encryption uses a unique IV, so same plaintext produces different ciphertext
        var plainText = "Same message encrypted twice";

        var encrypted1 = _service.Encrypt(plainText);
        var encrypted2 = _service.Encrypt(plainText);

        Assert.NotEqual(encrypted1, encrypted2);
    }

    [Fact]
    public void Decrypt_BothDifferentCiphertexts_ProduceSamePlaintext()
    {
        var plainText = "Same message encrypted twice";

        var encrypted1 = _service.Encrypt(plainText);
        var encrypted2 = _service.Encrypt(plainText);

        Assert.Equal(plainText, _service.Decrypt(encrypted1));
        Assert.Equal(plainText, _service.Decrypt(encrypted2));
    }

    [Fact]
    public void Encrypt_EmptyString_ReturnsEmptyString()
    {
        var result = _service.Encrypt(string.Empty);
        Assert.Equal(string.Empty, result);
    }

    [Fact]
    public void Encrypt_Null_ReturnsNull()
    {
        var result = _service.Encrypt(null!);
        Assert.Null(result);
    }

    [Fact]
    public void Decrypt_EmptyString_ReturnsEmptyString()
    {
        var result = _service.Decrypt(string.Empty);
        Assert.Equal(string.Empty, result);
    }

    [Fact]
    public void Decrypt_Null_ReturnsNull()
    {
        var result = _service.Decrypt(null!);
        Assert.Null(result);
    }

    [Fact]
    public void Encrypt_UnicodeText_RoundTripsCorrectly()
    {
        var plainText = "Momo bilang: こんにちは! 你好! Привет! 🎉✨";

        var encrypted = _service.Encrypt(plainText);
        var decrypted = _service.Decrypt(encrypted);

        Assert.Equal(plainText, decrypted);
    }

    [Fact]
    public void Encrypt_LargeContent_RoundTripsCorrectly()
    {
        var plainText = new string('A', 2000); // Max content length

        var encrypted = _service.Encrypt(plainText);
        var decrypted = _service.Decrypt(encrypted);

        Assert.Equal(plainText, decrypted);
    }

    [Fact]
    public void Constructor_WithInvalidKeyLength_ThrowsException()
    {
        // Key too short (16 bytes instead of 32)
        var shortKey = Convert.ToBase64String(RandomNumberGenerator.GetBytes(16));
        var options = Options.Create(new EncryptionOptions { AesKey = shortKey });

        Assert.Throws<InvalidOperationException>(() => new AesEncryptionService(options));
    }

    [Fact]
    public void Constructor_WithEmptyKey_ThrowsException()
    {
        var options = Options.Create(new EncryptionOptions { AesKey = "" });

        Assert.Throws<InvalidOperationException>(() => new AesEncryptionService(options));
    }

    [Fact]
    public void Decrypt_WithWrongKey_ThrowsCryptographicException()
    {
        var plainText = "Secret message";
        var encrypted = _service.Encrypt(plainText);

        // Create a service with a different key
        var differentKey = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        var differentOptions = Options.Create(new EncryptionOptions { AesKey = differentKey });
        var differentService = new AesEncryptionService(differentOptions);

        // Decrypting with wrong key should throw
        Assert.ThrowsAny<Exception>(() => differentService.Decrypt(encrypted));
    }

    [Fact]
    public void Decrypt_WithTamperedCiphertext_ThrowsException()
    {
        var plainText = "Tamper-proof test";
        var encrypted = _service.Encrypt(plainText);

        // Tamper with the ciphertext
        var bytes = Convert.FromBase64String(encrypted);
        bytes[bytes.Length - 1] ^= 0xFF; // Flip bits in last byte
        var tampered = Convert.ToBase64String(bytes);

        Assert.ThrowsAny<Exception>(() => _service.Decrypt(tampered));
    }
}
