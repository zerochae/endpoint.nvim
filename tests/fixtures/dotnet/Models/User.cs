namespace WebApi.Models;

public class User
{
    public int Id { get; set; }
    public required string Name { get; set; }
    public required string Email { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string Status { get; set; } = "Active";
}

public record CreateUserDto(string Name, string Email);
public record UpdateUserDto(string Name, string Email);