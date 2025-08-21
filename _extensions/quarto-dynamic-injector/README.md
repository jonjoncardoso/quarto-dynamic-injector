# Quarto Dynamic Injector

A Quarto extension for dynamically injecting content into websites based on URL paths and hierarchical structures.

## Features

- **Dynamic Content Injection**: Inject figures, CSS, and other content based on URL paths
- **Hierarchical Mapping**: Map content to specific paths in your website structure
- **Build-time Injection**: Configuration is automatically injected during Quarto build
- **No CORS Issues**: Build-time injection eliminates runtime fetch problems
- **Flexible Configuration**: Easy YAML-based configuration system

## Installation

The extension is already installed in this project. To install in other projects:

```bash
quarto add joncardoso/quarto-dynamic-injector
```

## Configuration

### In `_quarto.yml`

```yaml
filters:
  - quarto-dynamic-injector

quarto-dynamic-injector:
  excludePaths:
    - "/slides.qmd"
    - "/slides"
  contentMapping:
    "/2024/autumn-term/":
      imageSrc: "/figures/icons/DS105A_person_icon.jpeg"
      altText: "DS105 Autumn Term Icon"
      title: "DS105 Autumn Term Icon"
      style: "object-fit: cover;width:5em;height:5em;border-radius: 50%;margin-bottom:1em;"
      className: "autumn-term-figure"
```

### Configuration Structure

The `contentMapping` key maps URL paths to content configurations. You can specify multiple items of the same type using arrays:

```yaml
contentMapping:
  "/path/to/section/":
    # Single content item
    class-injection:
      selector: "body"
      className: "archive-page"
    
    # Multiple figures using array syntax
    figure:
      - selector: "main > header"
        position: "afterend"
        imageSrc: "path/to/image1.png"
        altText: "First image"
        title: "First Image Title"
        className: "first-figure"
      - selector: ".navbar-title"
        position: "afterbegin"
        imageSrc: "path/to/image2.png"
        altText: "Second image"
        title: "Second Image Title"
        className: "second-figure"
```

### Content Item Configuration

Each content item supports these properties:

- `selector`: CSS selector for injection target (required)
- `position`: Injection position relative to target (default: "afterend")
- `imageSrc`: Image source URL (for figures)
- `altText`: Image alt text (for figures)
- `title`: Image title attribute (for figures)
- `style`: Inline CSS styles (for figures)
- `className`: CSS class name (for figures and class-injection)

### Path Matching

The extension matches the current document's URL path against the configured paths:

- **Exact matches**: `/2024/autumn-term/` matches pages in that section
- **Partial matches**: `/2023/` matches all pages under 2023
- **Exclusions**: Use `excludePaths` to skip specific pages or sections
- **Single match**: Only the first matching path configuration is applied per page

### Selector Configuration

The `selector` option specifies where to inject content in the HTML document:

- **Default**: `"main > header"` (injects after the main header)
- **Custom selectors**: Use any valid CSS selector
- **Examples**:
  - `"body > header"` - After the body header
  - `".sidebar"` - After the sidebar element
  - `"#content"` - After the content div
  - `"main"` - After the main element

### Element Selection Behavior

- **Single element**: Only the first element matching the CSS selector is targeted
- **Multiple elements**: If multiple elements match the selector, only the first one is used
- **No elements**: If no elements match the selector, the injection is skipped gracefully

### Position Configuration

The `position` option specifies where to inject content relative to the target element:

- **Default**: `"afterend"` (after the target element)
- **Available positions**:
  - `"beforebegin"` - Before the target element
  - `"afterbegin"` - Inside the target element, at the beginning
  - `"beforeend"` - Inside the target element, at the end
  - `"afterend"` - After the target element
- **Examples**:
  - `"afterend"` - Content appears after the header
  - `"beforebegin"` - Content appears before the header
  - `"afterbegin"` - Content appears at the start of the main element
  - `"beforeend"` - Content appears at the end of the main element

### ID System

The extension generates unique IDs for injected elements to ensure proper targeting:

- **Format**: `quarto-dynamic-injector-{content-type}-{className}-{index}`
- **Examples**: 
  - `quarto-dynamic-injector-figure-term-icon-1`
  - `quarto-dynamic-injector-figure-sidebar-banner-2`
- **Uniqueness**: Each injected element gets a unique ID per page
- **Cleanup**: IDs are removed after elements are positioned to avoid conflicts

### Example Use Cases

**Term-specific branding with multiple elements:**
```yaml
contentMapping:
  "/2024/autumn-term/":
    class-injection:
      selector: "body"
      className: "archive-page"
    figure:
      - selector: "main > header"
        position: "afterend"
        imageSrc: "/figures/icons/autumn-icon.png"
        altText: "Autumn Term 2024"
        className: "autumn-term-figure"
      - selector: ".navbar-title"
        position: "afterbegin"
        imageSrc: "/figures/icons/autumn-favicon.png"
        altText: "Autumn Term Favicon"
        className: "autumn-favicon"
  
  "/2024/winter-term/":
    class-injection:
      selector: "body"
      className: "archive-page"
    figure:
      - selector: "main > header"
        position: "afterend"
        imageSrc: "/figures/icons/winter-icon.png"
        altText: "Winter Term 2024"
        className: "winter-term-figure"
      - selector: ".navbar-title"
        position: "afterbegin"
        imageSrc: "/figures/icons/winter-favicon.png"
        altText: "Winter Term Favicon"
        className: "winter-favicon"
```

**Course-specific content:**
```yaml
contentMapping:
  "/DS105/":
    figure:
      - selector: "main > header"
        position: "afterend"
        imageSrc: "/figures/icons/ds105-icon.png"
        altText: "DS105 Course"
        className: "ds105-figure"
      - selector: ".sidebar"
        position: "afterbegin"
        imageSrc: "/figures/icons/ds105-sidebar.png"
        altText: "DS105 Sidebar"
        className: "ds105-sidebar"
  
  "/DS106/":
    figure:
      - selector: ".sidebar"
        position: "afterbegin"
        imageSrc: "/figures/icons/ds106-icon.png"
        altText: "DS106 Course"
        className: "ds106-figure"
```

## How It Works

1. **Build Time**: The Lua filter reads the YAML configuration during Quarto build
2. **Path Matching**: Matches the current document's URL against configured paths
3. **Content Injection**: Injects matching content into the HTML document
4. **Runtime**: JavaScript handles precise positioning and styling

## Benefits

- ✅ **No CORS Issues**: Configuration injected at build time
- ✅ **Version Controlled**: YAML configuration can be version controlled
- ✅ **Reusable**: Extension can be used across multiple projects
- ✅ **Simple CLI**: Easy archiving and management tools
- ✅ **Clean Separation**: Configuration separate from code

## Development

To modify the extension:

1. Edit `_extensions/quarto-dynamic-injector/quarto-dynamic-injector.lua`
2. Update `_quarto.yml` for configuration changes
3. Rebuild with `quarto render`

## License

MIT License - see LICENSE file for details. 