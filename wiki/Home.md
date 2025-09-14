# endpoint.nvim Wiki

Welcome to the comprehensive documentation for endpoint.nvim!

## 📖 Documentation Pages

### For Users
- [⚙️ Advanced Configuration](Advanced-Configuration) - Detailed picker options, UI customization, and framework-specific settings
- [📈 Performance & Caching](Performance-and-Caching) - Cache modes, optimization tips, and performance tuning
- [🐛 Troubleshooting](Troubleshooting) - Common issues, debugging tips, and how to report problems

### For Developers
- [🧪 Development & Testing](Development-and-Testing) - Running tests, debugging, and development workflow
- [🔧 Adding New Frameworks](Adding-New-Frameworks) - Complete guide to implementing framework support
- [📝 Contributing Guidelines](Contributing-Guidelines) - How to contribute code, tests, and documentation

## 🚀 Quick Links

- **Main Repository**: [endpoint.nvim](https://github.com/zerochae/endpoint.nvim)
- **Issues**: [Report bugs or request features](https://github.com/zerochae/endpoint.nvim/issues)
- **Discussions**: [Ask questions and share ideas](https://github.com/zerochae/endpoint.nvim/discussions)

## 📊 Current Support

**10 Frameworks Supported:**
- Spring Boot (Java) - Controllers with @GetMapping, @PostMapping, etc.
- Java Servlet (Java) - @WebServlet annotations and URL patterns
- NestJS (TypeScript/JavaScript) - @Get(), @Post(), @Controller() decorators
- Symfony (PHP) - @Route annotations and attributes
- FastAPI (Python) - @app.get(), @app.post(), @router.* patterns
- Rails (Ruby) - Controller actions and routes.rb parsing
- Express (Node.js) - app.method(), router.method() patterns
- Ktor (Kotlin) - get(), post(), route() blocks with nested routing
- .NET Core (C#) - [HttpGet], Minimal API, endpoint routing
- React Router - <Route> components with smart component resolution

**3 Picker Interfaces:**
- Telescope - Rich fuzzy search with preview
- vim.ui.select - Native Neovim interface
- Snacks.nvim - Modern picker with enhanced features