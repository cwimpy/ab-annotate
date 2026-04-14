-- ab-annotate.lua
-- Pandoc/Quarto Lua filter for annotated bibliographies.
--
-- Reads abstract and annotation/annote fields from the .bib file
-- and appends them after each bibliography entry in the rendered
-- output. Works with HTML, PDF (LaTeX), Typst, and Word formats.
--
-- IMPORTANT: This filter runs citeproc internally, so you MUST
-- disable Quarto's built-in citeproc:
--
--   citeproc: false
--   filters:
--     - ab-annotate.lua
--
--   ab-annotate:
--     show-abstract: true
--     show-annotation: true
--     show-labels: true
--     abstract-label: "Abstract"
--     annotation-label: "Annotation"

-- ── Minimal .bib parser ───────────────────────────────────────

local function extract_field(text, field_name)
  local lower = text:lower()
  local pattern = field_name:lower() .. "%s*=%s*%{"
  local start = lower:find(pattern)
  if not start then return nil end

  local brace_start = text:find("{", start)
  if not brace_start then return nil end

  local depth = 1
  local pos = brace_start + 1
  while pos <= #text and depth > 0 do
    local ch = text:sub(pos, pos)
    if ch == "{" then depth = depth + 1
    elseif ch == "}" then depth = depth - 1
    end
    if depth > 0 then pos = pos + 1 end
  end

  local value = text:sub(brace_start + 1, pos - 1)
  value = value:gsub("%s+", " "):match("^%s*(.-)%s*$")
  value = value:gsub("%-%-%-", "\u{2014}")
  value = value:gsub("%-%-", "\u{2013}")
  if value == "" then return nil end
  return value
end

local function parse_bib(content)
  local result = {}
  content = content .. "\n@sentinel{end,"

  for entry_block in content:gmatch("@%w+%s*%{(.-)%f[@]") do
    local key = entry_block:match("^%s*([^,%s]+)")
    if key and key ~= "end" then
      local abstract = extract_field(entry_block, "abstract")
      local annotation = extract_field(entry_block, "annotation")
      local annote = extract_field(entry_block, "annote")
      result[key] = {
        abstract = abstract,
        annotation = annotation or annote,
      }
    end
  end
  return result
end

-- ── Build annotation blocks ───────────────────────────────────

local function make_block(label, text, is_abstract, show_labels)
  local inlines = pandoc.List()

  if show_labels then
    inlines:insert(pandoc.Strong(pandoc.Str(label .. ":")))
    inlines:insert(pandoc.Space())
  end

  if is_abstract then
    inlines:insert(pandoc.Emph(pandoc.Str(text)))
  else
    inlines:insert(pandoc.Str(text))
  end

  local para = pandoc.Para(inlines)
  local class = is_abstract and "ab-abstract" or "ab-annotation"
  return pandoc.Div(para, pandoc.Attr("", {class, "ab-annotate-block"}))
end

-- ── Main filter ───────────────────────────────────────────────

function Pandoc(doc)
  -- Step 1: Run citeproc to populate the bibliography
  doc = pandoc.utils.citeproc(doc)

  local meta = doc.meta

  -- Step 2: Read configuration
  local show_abstract = true
  local show_annotation = true
  local show_labels = true
  local abstract_label = "Abstract"
  local annotation_label = "Annotation"

  local ab = meta["ab-annotate"]
  if ab then
    if ab["show-abstract"] ~= nil then
      show_abstract = pandoc.utils.stringify(ab["show-abstract"]) ~= "false"
    end
    if ab["show-annotation"] ~= nil then
      show_annotation = pandoc.utils.stringify(ab["show-annotation"]) ~= "false"
    end
    if ab["show-labels"] ~= nil then
      show_labels = pandoc.utils.stringify(ab["show-labels"]) ~= "false"
    end
    if ab["abstract-label"] then
      abstract_label = pandoc.utils.stringify(ab["abstract-label"])
    end
    if ab["annotation-label"] then
      annotation_label = pandoc.utils.stringify(ab["annotation-label"])
    end
  end

  -- Step 3: Parse bibliography files
  local entries = {}
  local bib = meta.bibliography
  if bib then
    local bib_files = {}
    local bib_type = pandoc.utils.type(bib)
    if bib_type == "Inlines" then
      table.insert(bib_files, pandoc.utils.stringify(bib))
    elseif bib_type == "List" then
      for _, b in ipairs(bib) do
        table.insert(bib_files, pandoc.utils.stringify(b))
      end
    else
      table.insert(bib_files, pandoc.utils.stringify(bib))
    end

    for _, bib_file in ipairs(bib_files) do
      local f = io.open(bib_file, "r")
      if f then
        local content = f:read("*a")
        f:close()
        local parsed = parse_bib(content)
        for k, v in pairs(parsed) do
          entries[k] = v
        end
      end
    end
  end

  -- Step 4: Walk the document looking for the #refs div
  local function process_blocks(blocks)
    local new_blocks = pandoc.List()
    for _, block in ipairs(blocks) do
      if block.t == "Div" and block.identifier == "refs" then
        local new_content = pandoc.List()
        for _, item in ipairs(block.content) do
          new_content:insert(item)
          if item.t == "Div" and item.identifier:match("^ref%-") then
            local key = item.identifier:sub(5)
            local entry = entries[key]
            if entry then
              if show_abstract and entry.abstract then
                new_content:insert(make_block(
                  abstract_label, entry.abstract, true, show_labels
                ))
              end
              if show_annotation and entry.annotation then
                new_content:insert(make_block(
                  annotation_label, entry.annotation, false, show_labels
                ))
              end
            end
          end
        end
        block.content = new_content
        new_blocks:insert(block)
      elseif block.t == "Div" then
        block.content = process_blocks(block.content)
        new_blocks:insert(block)
      else
        new_blocks:insert(block)
      end
    end
    return new_blocks
  end

  doc.blocks = process_blocks(doc.blocks)
  return doc
end
