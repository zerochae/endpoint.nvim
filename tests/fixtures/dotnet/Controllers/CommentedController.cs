using Microsoft.AspNetCore.Mvc;

namespace TestApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CommentedController : ControllerBase
    {
        // Single line commented endpoints - should be filtered
        // [HttpGet("single-line-comment")]
        // public IActionResult GetSingleLineComment() { return Ok("filtered"); }

        // [HttpPost("another-single-line")]
        // public IActionResult PostAnotherSingleLine() { return Ok("filtered"); }

        /* Block commented endpoints - should be filtered */
        /* [HttpPut("block-comment")] */
        /* public IActionResult PutBlockComment() { return Ok("filtered"); } */

        /*
         * Multi-line block commented endpoints - should be filtered
         * [HttpDelete("multi-line-block")]
         * public IActionResult DeleteMultiLineBlock() { return Ok("filtered"); }
         */

        /// <summary>
        /// XML doc commented endpoints - should be filtered
        /// [HttpPatch("xml-doc-comment")]
        /// public IActionResult PatchXmlDocComment() { return Ok("filtered"); }
        /// </summary>

        // Active endpoints - should NOT be filtered
        [HttpGet("active")]
        public IActionResult GetActive()
        {
            return Ok("active");
        }

        [HttpPost("users")]
        public IActionResult CreateUser()
        {
            return Ok("created");
        }

        // Mixed scenarios
        /*
        [HttpGet("mixed-block")]
        public IActionResult GetMixedBlock()
        {
            return Ok("filtered");
        }
        */

        // [HttpGet("commented-inline")] // This should be filtered

        [HttpPatch("active-after-comment")]
        public IActionResult PatchActiveAfterComment()
        {
            return Ok("active"); // This should NOT be filtered
        }

        // Route attribute variations
        // [Route("commented-route", Name = "CommentedRoute")]
        // [HttpGet]
        // public IActionResult GetCommentedRoute() { return Ok("filtered"); }

        [Route("active-route", Name = "ActiveRoute")]
        [HttpGet]
        public IActionResult GetActiveRoute()
        {
            return Ok("active");
        }
    }
}