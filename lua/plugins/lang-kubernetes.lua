-- lints Kubernetes YAML with kubeconform; other YAML gets yamllint.
-- skips Helm templates and sops-encrypted files.
vim.fn.mkdir(vim.fn.stdpath 'cache' .. '/kubeconform', 'p')

local function is_helm_path(path)
  return path:find '/templates/' ~= nil
end

local function is_sops_file(lines)
  for _, line in ipairs(lines) do
    if line:find '^sops:' or line:find('ENC[AES256_GCM', 1, true) then
      return true
    end
  end
  return false
end

local function looks_like_kubernetes(lines)
  local has_api_version, has_kind = false, false
  for _, line in ipairs(lines) do
    if line:find '^apiVersion:' then
      has_api_version = true
    elseif line:find '^kind:' then
      has_kind = true
    end
    if has_api_version and has_kind then
      return true
    end
  end
  return false
end

local function read_file_lines(path)
  local f = io.open(path, 'r')
  if not f then
    return nil
  end
  local lines = {}
  for line in f:lines() do
    table.insert(lines, line)
  end
  f:close()
  return lines
end

local function is_helm_or_sops(ctx)
  if is_helm_path(ctx.filename) then
    return true
  end
  local lines = read_file_lines(ctx.filename)
  return lines == nil or is_sops_file(lines)
end

local function resource_message(resource)
  local parts = {}
  for _, err in ipairs(resource.validationErrors or {}) do
    if err.msg then
      local prefix = (err.path and err.path ~= '') and (err.path .. ': ') or ''
      table.insert(parts, prefix .. err.msg)
    end
  end
  if #parts > 0 then
    return table.concat(parts, '; ')
  end
  return resource.msg or 'failed validation'
end

-- kubeconform reports JSON-Pointer paths (e.g. /spec/selector), not line
-- numbers. Walk those paths down the yaml treesitter tree to find the node.
local PUNCTUATION = {
  [','] = true,
  ['['] = true,
  [']'] = true,
  ['{'] = true,
  ['}'] = true,
  [':'] = true,
  ['-'] = true,
  ['?'] = true,
}

local function node_text(node, bufnr)
  if not node then
    return nil
  end
  local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
  return ok and text or nil
end

local function strip_quotes(text)
  if not text then
    return nil
  end
  return text:match '^"(.*)"$' or text:match "^'(.*)'$" or text
end

local function unwrap(node)
  while node and (node:type() == 'block_node' or node:type() == 'flow_node') and node:child_count() > 0 do
    node = node:child(0)
  end
  return node
end

local function parse_pointer(pointer)
  local segments = {}
  for segment in (pointer or ''):gmatch '[^/]+' do
    segments[#segments + 1] = segment:gsub('~1', '/'):gsub('~0', '~')
  end
  return segments
end

local function pair_key(node, bufnr)
  local key = node:field('key')[1]
  return key and strip_quotes(node_text(key, bufnr)) or nil
end

local function find_pair(mapping, name, bufnr)
  for i = 0, mapping:child_count() - 1 do
    local child = mapping:child(i)
    if pair_key(child, bufnr) == name then
      return child
    end
  end
  return nil
end

local function is_item(node)
  local t = node:type()
  return not PUNCTUATION[t] and t ~= 'comment'
end

local function sequence_item(sequence, index)
  local seen = 0
  for i = 0, sequence:child_count() - 1 do
    local child = sequence:child(i)
    if is_item(child) then
      if seen == index then
        if child:type() ~= 'block_sequence_item' then
          return child, unwrap(child)
        end
        for j = 0, child:child_count() - 1 do
          local inner = child:child(j)
          if inner:type() ~= '-' then
            return child, unwrap(inner)
          end
        end
        return child, nil
      end
      seen = seen + 1
    end
  end
  return nil, nil
end

-- Walk a JSON-Pointer down the tree, returning the deepest matched node.
local function descend(node, segments, depth, bufnr, last)
  if not node or depth > #segments then
    return last
  end
  local segment = segments[depth]
  local t = node:type()
  if t == 'block_mapping' or t == 'flow_mapping' then
    local pair = find_pair(node, segment, bufnr)
    if not pair then
      return last
    end
    return descend(unwrap(pair:field('value')[1]), segments, depth + 1, bufnr, pair)
  elseif t == 'block_sequence' or t == 'flow_sequence' then
    local index = tonumber(segment)
    if not index then
      return last
    end
    local item, value = sequence_item(node, index)
    if not item then
      return last
    end
    return descend(value, segments, depth + 1, bufnr, item)
  end
  return last
end

local function doc_meta(document, bufnr)
  local entry = { bufnr = bufnr, lnum = document:start() }
  for i = 0, document:child_count() - 1 do
    local child = document:child(i)
    if child:type() == 'block_node' then
      entry.root = unwrap(child)
      break
    end
  end
  if not entry.root then
    return entry
  end

  local kind = find_pair(entry.root, 'kind', bufnr)
  entry.kind = kind and strip_quotes(node_text(unwrap(kind:field('value')[1]), bufnr)) or nil
  entry.kind_line = kind and kind:start() or entry.lnum

  local metadata = find_pair(entry.root, 'metadata', bufnr)
  local metadata_value = metadata and unwrap(metadata:field('value')[1])
  local name = metadata_value and find_pair(metadata_value, 'name', bufnr)
  entry.name = name and strip_quotes(node_text(unwrap(name:field('value')[1]), bufnr)) or nil

  return entry
end

local function build_doc_entries(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'yaml')
  if not ok or not parser then
    return nil
  end
  local ok_parse, trees = pcall(function()
    return parser:parse()
  end)
  local tree = ok_parse and trees and (trees[1] or trees[#trees])
  if not tree then
    return nil
  end

  local entries = {}
  local root = tree:root()
  for i = 0, root:child_count() - 1 do
    local doc = root:child(i)
    if doc:type() == 'document' then
      entries[#entries + 1] = doc_meta(doc, bufnr)
    end
  end
  return entries
end

local function find_entry(entries, resource)
  if not entries then
    return nil
  end
  local kind = resource.kind ~= '' and resource.kind or nil
  local name = resource.name ~= '' and resource.name or nil
  if kind and name then
    for _, entry in ipairs(entries) do
      if entry.kind == kind and entry.name == name then
        return entry
      end
    end
  end
  if kind then
    for _, entry in ipairs(entries) do
      if entry.kind == kind then
        return entry
      end
    end
  end
  return nil
end

local function pointer_line(pointer, entry)
  if not entry or not entry.root then
    return nil
  end
  local segments = parse_pointer(pointer)
  if #segments == 0 then
    return { lnum = entry.lnum, col = 0, keylen = 0 }
  end
  local hit = descend(entry.root, segments, 1, entry.bufnr, nil)
  if not hit then
    return nil
  end
  local row, col = hit:start()
  local key = pair_key(hit, entry.bufnr)
  return { lnum = row, col = col, keylen = key and #key or 0 }
end

-- kubeconform reports "additional properties" at the parent path and only
-- names the offending keys in the message, so refine the pointer with them.
local function refine_pointer(err)
  local path = err.path or ''
  local added = (err.msg or ''):match 'additional propert%a* (.-) not allowed'
  if added then
    local name = added:match "'([^']+)'"
    if name then
      return path .. '/' .. name
    end
  end
  return path
end

return {
  'mfussenegger/nvim-lint',
  opts = {
    linters_by_ft = {
      yaml = { 'kubeconform', 'yamllint' },
    },
    linters = {
      kubeconform = {
        cmd = 'kubeconform',
        stdin = true,
        args = {
          '-output',
          'json',
          '-strict',
          '-kubernetes-version',
          '1.33.0',
          '-schema-location',
          'default',
          '-schema-location',
          'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json',
          '-cache',
          vim.fn.stdpath 'cache' .. '/kubeconform',
          '-ignore-missing-schemas',
        },
        stream = 'stdout',
        ignore_exitcode = true,
        -- LazyVim extension: skip spawning kubeconform for non-K8s YAML
        condition = function(ctx)
          if is_helm_or_sops(ctx) then
            return false
          end
          local lines = read_file_lines(ctx.filename)
          return lines ~= nil and looks_like_kubernetes(lines)
        end,
        -- safety net for direct try_lint() calls
        parser = function(output, bufnr)
          local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
          if is_sops_file(lines) or not looks_like_kubernetes(lines) then
            return {}
          end

          local ok, result = pcall(vim.json.decode, output)
          if not ok or not result.resources then
            return {}
          end

          local problems = {}
          for _, resource in ipairs(result.resources) do
            local is_invalid = resource.status == 'statusInvalid' or resource.status == 'INVALID'
            local is_error = resource.status == 'statusError' or resource.status == 'ERROR'
            if is_invalid or is_error then
              problems[#problems + 1] = { resource = resource, is_invalid = is_invalid }
            end
          end
          if #problems == 0 then
            return {}
          end

          local entries = build_doc_entries(bufnr)
          local diagnostics = {}
          for _, problem in ipairs(problems) do
            local resource = problem.resource
            local kind = resource.kind ~= '' and resource.kind or 'Kubernetes resource'
            local severity = problem.is_invalid and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN
            local entry = find_entry(entries, resource)
            local errors = resource.validationErrors or {}

            if #errors == 0 then
              local lnum = entry and entry.kind_line or 0
              diagnostics[#diagnostics + 1] = {
                lnum = lnum,
                col = 0,
                end_lnum = lnum,
                end_col = 0,
                severity = severity,
                source = 'kubeconform',
                message = string.format('%s: %s', kind, resource_message(resource)),
              }
            else
              for _, err in ipairs(errors) do
                local pointer = refine_pointer(err)
                local hit = pointer_line(pointer, entry)
                if not hit and pointer ~= (err.path or '') then
                  hit = pointer_line(err.path, entry)
                end
                local lnum = hit and hit.lnum or (entry and entry.kind_line) or 0
                local col = hit and hit.col or 0
                diagnostics[#diagnostics + 1] = {
                  lnum = lnum,
                  col = col,
                  end_lnum = lnum,
                  end_col = hit and (col + hit.keylen) or 0,
                  severity = severity,
                  source = 'kubeconform',
                  message = string.format('%s: %s%s', kind, (err.path and err.path ~= '') and (err.path .. ': ') or '', err.msg or 'failed validation'),
                }
              end
            end
          end

          return diagnostics
        end,
      },
      yamllint = {
        -- LazyVim extension: merged into nvim-lint's built-in yamllint
        condition = function(ctx)
          return not is_helm_or_sops(ctx)
        end,
      },
    },
  },
}
