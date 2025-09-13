using Microsoft.AspNetCore.Mvc;
using WebApi.Models;

namespace WebApi.Controllers;

public class OrdersController : ControllerBase
{
    [Route("api/orders")]
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Order>>> GetOrders()
    {
        // Get orders logic
        return Ok(new List<Order>());
    }

    [Route("api/orders/{orderId:int}")]
    [HttpGet]
    public async Task<ActionResult<Order>> GetOrder(int orderId)
    {
        // Get order logic
        return Ok(new Order { Id = orderId });
    }

    [Route("api/orders")]
    [HttpPost]
    public async Task<ActionResult<Order>> CreateOrder([FromBody] CreateOrderDto dto)
    {
        // Create order logic
        var order = new Order { Id = Random.Shared.Next(1000, 9999) };
        return CreatedAtAction(nameof(GetOrder), new { orderId = order.Id }, order);
    }

    [Route("api/orders/{orderId:int}/cancel")]
    [HttpPatch]
    public async Task<IActionResult> CancelOrder(int orderId)
    {
        // Cancel order logic
        return NoContent();
    }

    [Route("api/orders/{orderId:int}")]
    [HttpDelete]
    public async Task<IActionResult> DeleteOrder(int orderId)
    {
        // Delete order logic
        return NoContent();
    }
}