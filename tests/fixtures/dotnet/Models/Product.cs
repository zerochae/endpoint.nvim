namespace WebApi.Models;

public class Product
{
    public Guid Id { get; set; }
    public required string Name { get; set; }
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public bool IsFeatured { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public record CreateProductDto(string Name, string? Description, decimal Price);
public record UpdateProductDto(string Name, string? Description, decimal Price);