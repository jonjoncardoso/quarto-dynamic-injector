-- Archive Configuration Filter
-- Reads configuration from _quarto.yml metadata and injects figures and JavaScript into HTML documents

function Pandoc(doc)
  -- Only process HTML documents
  if not quarto.doc.is_format("html") then
    -- quarto.log.output("Skipping non-HTML document")
    return doc
  end
  

  
  -- Get configuration from document metadata
  local config = doc.meta["quarto-dynamic-injector"]
  if not config then
    return doc
  end
  
  -- Extract values from Pandoc objects if needed (defined at top level for reuse)
  local function extract_string(obj)
    if type(obj) == "string" then
      return obj
    elseif type(obj) == "userdata" or type(obj) == "table" then
      -- Use Pandoc's stringify function to properly extract text from AST objects
      local success, result = pcall(pandoc.utils.stringify, obj)
      if success and result then
        return result
      end
    end
    return tostring(obj)
  end
  
  -- Build HTML attributes conditionally (only include if value exists and is not empty)
  local function build_html_attributes(attributes)
    local attr_parts = {}
    for attr_name, attr_value in pairs(attributes) do
      if attr_value and attr_value ~= "" and attr_value ~= "nil" then
        table.insert(attr_parts, string.format('%s="%s"', attr_name, attr_value))
      end
    end
    return table.concat(attr_parts, " ")
  end
  
  -- Get current document path for matching
  local current_path = ""
  
  if quarto.doc.input_file then
    local full_path = tostring(quarto.doc.input_file)
    
    -- Convert file system path to web path using Quarto's project structure
    local function extract_web_path(fs_path)
      -- Normalize path separators to forward slashes
      local normalized_path = string.gsub(fs_path, "\\", "/")
      
      -- Get the project directory (where _quarto.yml is located)
      local project_dir = quarto.project.directory
      
      if project_dir then
        -- Normalize project directory path
        local normalized_project_dir = string.gsub(project_dir, "\\", "/")
        
        -- Find the relative path from project root to current file
        -- Use pattern matching to find the project directory in the path
        local relative_path = normalized_path
        if string.find(normalized_path, normalized_project_dir, 1, true) then
          relative_path = string.sub(normalized_path, #normalized_project_dir + 1)
        end
        -- Remove leading slash if present
        relative_path = string.gsub(relative_path, "^/+", "")
        
        -- Convert file path to web path
        -- Remove file extension and add trailing slash for directories
        relative_path = string.gsub(relative_path, "%.%w+$", "") -- Remove file extension
        if relative_path ~= "" then
          local web_path = "/" .. relative_path .. "/"
          return web_path
        else
          return "/"
        end
      else
        -- Could not determine project directory, use fallback
        return "/"
      end
    end
    
    current_path = extract_web_path(full_path)
  end
  
  -- If we don't have a path yet, try other approaches
  if current_path == "" then
    if doc.meta["url"] then
      current_path = tostring(doc.meta["url"])
    elseif doc.meta["output-file"] then
      current_path = tostring(doc.meta["output-file"])
    elseif doc.meta["title"] then
      current_path = tostring(doc.meta["title"])
    end
  end
  
  -- If we still don't have a path, try to infer from the document structure
  if current_path == "" then
    -- Try to get any information about the current document
    if doc.meta["bibliography"] then
      local bib_path = tostring(doc.meta["bibliography"])
      -- Extract path from bibliography by removing common reference patterns
      local path_parts = {}
      for part in string.gmatch(bib_path, "[^/]+") do
        -- Skip reference directories and bibliography files
        if part ~= "references" and not string.match(part, "%.%w+$") then
          table.insert(path_parts, part)
        end
      end
      if #path_parts > 0 then
        current_path = "/" .. table.concat(path_parts, "/") .. "/"
      end
    end
    
    -- If still no path, try to infer from other metadata
    if current_path == "" and doc.meta["csl"] then
      local csl_path = tostring(doc.meta["csl"])
      local path_parts = {}
      for part in string.gmatch(csl_path, "[^/]+") do
        -- Skip reference directories and CSL files
        if part ~= "references" and not string.match(part, "%.%w+$") then
          table.insert(path_parts, part)
        end
      end
      if #path_parts > 0 then
        current_path = "/" .. table.concat(path_parts, "/") .. "/"
      end
    end
    
    -- If still no path, try to infer from include-before metadata (navigation)
    if current_path == "" and doc.meta["include-before"] then
      local include_before = doc.meta["include-before"]
      if include_before and type(include_before) == "table" then
        for i, item in ipairs(include_before) do
          if item and item.text then
            local text = tostring(item.text)
            -- Look for active navigation links which indicate current page
            if string.find(text, "active") then
              -- Extract path from active navigation
              for path_pattern in string.gmatch(text, "href=\"([^\"]+)\"") do
                -- Convert any file path to directory path
                current_path = string.gsub(path_pattern, "%.%w+$", "/")
                break
              end
              break
            end
          end
        end
      end
    end
    
    -- If still no path, default to root
    if current_path == "" then
      current_path = "/"
    end
  end
  
  -- Check if current page should be excluded
  local should_exclude = false
  if config.excludePaths then
    for _, path_obj in ipairs(config.excludePaths) do
      local path_str = extract_string(path_obj)
      if string.find(current_path, path_str, 1, true) then
        should_exclude = true
        break
      end
    end
  end
  
  if should_exclude then
    return doc
  end
  
  -- Find matching content configuration
  local content_config = nil
  if config.contentMapping and not should_exclude then
    for path_key, content_config_item in pairs(config.contentMapping) do
      local path_str = extract_string(path_key)
      if string.find(current_path, path_str, 1, true) then
        content_config = content_config_item
        break
      end
    end
  end
  
  -- Process multiple content items if configuration exists
  if content_config then
    
    -- Initialize include-before if it doesn't exist
    if not doc.meta["include-before"] then
      doc.meta["include-before"] = pandoc.List({})
    elseif type(doc.meta["include-before"]) ~= "table" then
      -- Convert to pandoc.List if it's not already
      doc.meta["include-before"] = pandoc.List({doc.meta["include-before"]})
    end
    
    -- Process each content type in the configuration
    local content_index = 0
    for content_type, content_data in pairs(content_config) do
      content_index = content_index + 1
      
      -- Check if content_data is an array (multiple items of same type)
      if type(content_data) == "table" and content_data[1] then
        -- Process array of content items
        for i, item_data in ipairs(content_data) do
          content_index = content_index + 1
          if content_type == "figure" then
            -- Process figure content
            local className = extract_string(item_data.className)
            local imageSrc = extract_string(item_data.imageSrc)
            local altText = extract_string(item_data.altText)
            local title = extract_string(item_data.title)
            local style = extract_string(item_data.style)
            local selector = extract_string(item_data.selector)
            local position = extract_string(item_data.position) or "afterend"
            
            -- Build figure attributes conditionally
            local figure_attrs = build_html_attributes({
              class = className,
              id = string.format("quarto-dynamic-injector-%s-%s-%d", content_type, className or "", content_index)
            })
            
            -- Build image attributes conditionally
            local img_attrs = build_html_attributes({
              src = imageSrc,
              alt = altText,
              title = title,
              role = "presentation",
              style = style
            })
            
            -- Create figure with JavaScript repositioning for precise placement
            local unique_id = string.format("quarto-dynamic-injector-%s-%s-%d", content_type, className or "", content_index)
            local precise_figure_html = string.format([[
              <figure %s>
                <img %s>
              </figure>
              <script>
                (function() {
                  const figure = document.getElementById('%s');
                  if (figure) {
                    const repositionFigure = function() {
                      const targetElement = document.querySelector('%s');
                      if (targetElement) {
                        targetElement.insertAdjacentElement('%s', figure);
                        figure.removeAttribute('id');
                        return true;
                      }
                      return false;
                    };
                    
                    if (!repositionFigure()) {
                      document.addEventListener('DOMContentLoaded', repositionFigure);
                    }
                  }
                })();
              </script>
            ]], 
            figure_attrs, img_attrs, unique_id, selector, position
            )
            
            -- Inject the figure
            doc.meta["include-before"]:insert(pandoc.RawBlock("html", precise_figure_html))
            
          elseif content_type == "class-injection" then
            -- Process class injection content
            local selector = extract_string(item_data.selector)
            local className = extract_string(item_data.className)
            
            -- Create JavaScript to add class to existing element
            local class_injection_html = string.format([[
              <script>
                (function() {
                  const addClassToElement = function() {
                    const targetElement = document.querySelector('%s');
                    if (targetElement) {
                      targetElement.classList.add('%s');
                      return true;
                    }
                    return false;
                  };
                  
                  if (!addClassToElement()) {
                    document.addEventListener('DOMContentLoaded', addClassToElement);
                  }
                })();
              </script>
            ]], selector, className)
            
            -- Inject the class injection script
            doc.meta["include-before"]:insert(pandoc.RawBlock("html", class_injection_html))
          end
        end
      else
        -- Process single content item (existing logic)
        if content_type == "figure" then
          -- Process figure content
          local className = extract_string(content_data.className)
          local imageSrc = extract_string(content_data.imageSrc)
          local altText = extract_string(content_data.altText)
          local title = extract_string(content_data.title)
          local style = extract_string(content_data.style)
          local selector = extract_string(content_data.selector)
          local position = extract_string(content_data.position) or "afterend"
          
          -- Build figure attributes conditionally
          local figure_attrs = build_html_attributes({
            class = className,
            id = string.format("quarto-dynamic-injector-%s-%s-%d", content_type, className or "figure", content_index)
          })
          
          -- Build image attributes conditionally
          local img_attrs = build_html_attributes({
            src = imageSrc,
            alt = altText,
            title = title,
            role = "presentation",
            style = style
          })
          
          -- Create figure with JavaScript repositioning for precise placement
          local unique_id = string.format("quarto-dynamic-injector-%s-%s-%d", content_type, className or "figure", content_index)
          local precise_figure_html = string.format([[
            <figure %s>
              <img %s>
            </figure>
            <script>
              (function() {
                const figure = document.getElementById('%s');
                if (figure) {
                  const repositionFigure = function() {
                    const targetElement = document.querySelector('%s');
                    if (targetElement) {
                      targetElement.insertAdjacentElement('%s', figure);
                      figure.removeAttribute('id');
                      return true;
                    }
                    return false;
                  };
                  
                  if (!repositionFigure()) {
                    document.addEventListener('DOMContentLoaded', repositionFigure);
                  }
                }
              })();
            </script>
          ]], 
          figure_attrs, img_attrs, unique_id, selector, position
          )
          
          -- Inject the figure
          doc.meta["include-before"]:insert(pandoc.RawBlock("html", precise_figure_html))
          
        elseif content_type == "class-injection" then
          -- Process class injection content
          local selector = extract_string(content_data.selector)
          local className = extract_string(content_data.className)
          
          -- Create JavaScript to add class to existing element
          local class_injection_html = string.format([[
            <script>
              (function() {
                const addClassToElement = function() {
                  const targetElement = document.querySelector('%s');
                  if (targetElement) {
                    targetElement.classList.add('%s');
                    return true;
                  }
                  return false;
                };
                
                if (!addClassToElement()) {
                  document.addEventListener('DOMContentLoaded', addClassToElement);
                }
              })();
            </script>
          ]], selector, className)
          
          -- Inject the class injection script
          doc.meta["include-before"]:insert(pandoc.RawBlock("html", class_injection_html))
        end
      end
    end
  end
  
  return doc
end 