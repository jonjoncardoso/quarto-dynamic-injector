# Quarto Dynamic Injector

[![Quarto Extension](https://img.shields.io/badge/Quarto-Extension-blue?style=flat&logo=quarto)](https://quarto.org/docs/extensions/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://github.com/jonjoncardoso/quarto-dynamic-injector/releases)

A Quarto extension that injects HTML content into specific pages based on URL paths. Perfect for adding course-specific branding, archive notices, or contextual content to different sections of your website.

## Author

**Jon Cardoso-Silva** - [@jonjoncardoso](https://github.com/jonjoncardoso)

This extension was developed to solve content injection challenges in multi-section educational websites, particularly for the [DS105 course at LSE](https://lse-dsi.github.io/DS105/).

## Quick Links

- [Installation](#installation)
- [Usage](#usage)
- [Examples](#examples)
- [Configuration Options](#configuration-options)

## What It Does

The Dynamic Injector extension lets you automatically add content to specific pages or sections of your Quarto website. This is ideal for:

- **Educational websites** where you want different branding for different terms
- **Multi-course sites** that need course-specific icons or notices
- **Archive sections** that need different styling or content
- **Any website** where you want content to appear only on specific pages

## Installation

```bash
quarto install extension jonjoncardoso/quarto-dynamic-injector@v0.1.0
```

## Usage

### Basic Setup

Add the filter to your document or `_quarto.yml`:

```yaml
---
filters:
  - quarto-dynamic-injector
---
```

### Configuration

Configure what content to inject on different pages:

```yaml
filters:
  - quarto-dynamic-injector

quarto-dynamic-injector:
  contentMapping:
    # Add autumn term branding to all autumn term pages
    "/2024-2025/autumn-term/":
      figure:
        - selector: "main > header"
          position: "afterend"
          imageSrc: "/figures/icons/autumn-icon.png"
          altText: "Autumn Term 2024"
          className: "autumn-term-figure"
    
    # Add winter term branding to all winter term pages
    "/2024-2025/winter-term/":
      figure:
        - selector: "main > header"
          position: "afterend"
          imageSrc: "/figures/icons/winter-icon.png"
          altText: "Winter Term 2024"
          className: "winter-term-figure"
```

### Potential Questions:

**Q: How do you know how to specify the `selector`?**

A: You'll need to inspect the HTML of your rendered HTML page (using your browser's developer tools) to figure out where you want the content to be injected. 

**Q: How do you know what to put in the `className`?**

A: You can use any existing CSS class you want that is visible to Quarto webpages. 

* By default, Quarto ships with the [Bootstrap](https://getbootstrap.com/) framework and so any [Bootstrap CSS classes](https://www.w3schools.com/bootstrap/bootstrap_ref_all_classes.asp) should work.
* Any CSS class that is exposed in the [Quarto theme](https://quarto.org/docs/output-formats/html-themes.html) you are using should work.
* Any CSS class you define yourself in your own [custom theme](https://quarto.org/docs/output-formats/html-themes.html#custom-themes) should work.

**Q: Can I just pass an inline CSS style definition?**

A: Yes, instead of the `className` attribute, you can explicitly define the CSS style you want to apply to the element:

  ```yaml
  figure:
    - selector: "main > header"
      position: "afterend"
      imageSrc: "/figures/icons/autumn-2024.png"
      altText: "Autumn Term 2024"
      style: "width: 100px; height: 100px;"
  ```

## Examples

### University Course Website

Imagine you have an educational website like the [Quarto Template for University Courses](https://github.com/jonjoncardoso/quarto-template-for-university-courses) and want to:

- Show current term branding prominently
- Add archive notices to old material
- Keep course-specific icons visible on relevant pages

```yaml
quarto-dynamic-injector:
  contentMapping:
    # Current term gets full branding
    "/2024-2025/autumn-term/":
      class-injection:
        selector: "body"
        className: "current-term"
      figure:
        - selector: "main > header"
          position: "afterend"
          imageSrc: "/figures/icons/autumn-2024.png"
          altText: "Autumn Term 2024"
          className: "term-banner"
```

## Configuration Options

### Content Types

- **`figure`**: Inject images with custom styling
- **`class-injection`**: Add CSS classes to elements

### Positioning

- **`selector`**: CSS selector for where to inject content
- **`position`**: Where relative to the target element:
  - `"afterend"` (default): After the element
  - `"beforebegin"`: Before the element
  - `"afterbegin"`: Inside the element, at start
  - `"beforeend"`: Inside the element, at end

### Figure Properties

- **`imageSrc`**: Path to the image
- **`altText`**: Alt text for accessibility
- **`className`**: CSS class for styling
- **`style`**: Inline CSS styles

## How It Works

1. **Build time**: The extension reads your configuration
2. **Path matching**: Matches current page URL to your rules
3. **Content injection**: Adds the matching content to your HTML
4. **Runtime positioning**: JavaScript handles precise placement

## License

MIT License 