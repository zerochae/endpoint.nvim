using Microsoft.AspNetCore.Mvc;
using WebApi.Models;

namespace WebApi.Controllers;

[ApiController]
[Route("api/v1/products")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    [Route("")]
    public async Task<ActionResult<IEnumerable<Product>>> GetAllProducts()
    {
        // Get all products logic
        return Ok(new List<Product>());
    }

    [HttpGet]
    [Route("featured")]
    public async Task<ActionResult<IEnumerable<Product>>> GetFeaturedProducts()
    {
        // Get featured products logic
        return Ok(new List<Product>());
    }

    [HttpGet("{productId:guid}")]
    public async Task<ActionResult<Product>> GetProductById(Guid productId)
    {
        // Get product by ID logic
        return Ok(new Product { Id = productId });
    }

    [HttpPost]
    public async Task<ActionResult<Product>> CreateProduct([FromBody] CreateProductDto dto)
    {
        // Create product logic
        var product = new Product { Id = Guid.NewGuid(), Name = dto.Name };
        return CreatedAtAction(nameof(GetProductById), new { productId = product.Id }, product);
    }

    [HttpPut("{productId:guid}")]
    public async Task<IActionResult> UpdateProduct(Guid productId, [FromBody] UpdateProductDto dto)
    {
        // Update product logic
        return NoContent();
    }

    [HttpDelete("{productId:guid}")]
    public async Task<IActionResult> DeleteProduct(Guid productId)
    {
        // Delete product logic
        return NoContent();
    }

    [HttpPatch("{productId:guid}/price")]
    public async Task<IActionResult> UpdateProductPrice(Guid productId, [FromBody] decimal price)
    {
        // Update product price logic
        return NoContent();
    }
}