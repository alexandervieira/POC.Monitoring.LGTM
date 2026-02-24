namespace APIContagem.GDPR;

public class UserMapping
{
    public string UserHash { get; set; } = string.Empty;
    public byte[] CpfEncrypted { get; set; } = Array.Empty<byte>();
    public DateTime CreatedAt { get; set; }
    public DateTime RetentionUntil { get; set; }
}
