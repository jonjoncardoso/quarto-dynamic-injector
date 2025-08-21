# TODO: Quarto Dynamic Injector - Multi-Content Evolution

Transform the extension to support multiple content injections per path mapping with structured content types.

## Goals

- [x] Refactor configuration structure to support multiple content items per path
- [x] Add support for different content types (figure, class-injection, html, etc.)
- [x] Update Lua code to process multiple content items per path
- [x] Update JavaScript to handle multiple injections per page
- [x] Implement class-injection functionality (add CSS classes to existing elements)
- [x] Update documentation with new multi-content structure
- [x] Test with complex multi-content configurations
- [x] Add validation for content type structure
- [x] Support for content ordering within each path mapping

## Completed ✅

The extension now supports:
- Multiple figures per path mapping using array syntax
- Multiple class injections per path mapping
- Backward compatibility with single item configurations
- Proper unique ID generation for each injected element 