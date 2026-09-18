local function buffer_lines()
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local function is_sops_buffer()
  for _, line in ipairs(buffer_lines()) do
    if line:match '^sops:' or line:find('ENC[AES256_GCM', 1, true) then
      return true
    end
  end
  return false
end

local function is_kubernetes_buffer()
  local has_api_version, has_kind = false, false
  for _, line in ipairs(buffer_lines()) do
    if line:match '^%-%-%-%s*$' then
      has_api_version, has_kind = false, false
    else
      has_api_version = has_api_version or line:match '^%s*apiVersion:' ~= nil
      has_kind = has_kind or line:match '^%s*kind:' ~= nil
    end
    if has_api_version and has_kind then
      return true
    end
  end
  return false
end

local function unquote(value)
  return value and (value:match '^"(.*)"$' or value:match "^'(.*)'$" or value)
end

local function resource_locations()
  local locations = {}
  local resource = nil

  local function finish()
    if resource and resource.kind then
      locations[#locations + 1] = resource
    end
  end

  for line_number, line in ipairs(buffer_lines()) do
    if line:match '^%-%-%-%s*$' then
      finish()
      resource = nil
    else
      resource = resource or {}
      local kind = line:match '^%s*kind:%s*(.-)%s*$'
      local name = line:match '^%s*name:%s*(.-)%s*$'
      local namespace = line:match '^%s*namespace:%s*(.-)%s*$'
      if kind and not resource.kind then
        resource.kind = unquote(kind)
        resource.kind_line = line_number - 1
      elseif name and not resource.name then
        resource.name = unquote(name)
      elseif namespace and not resource.namespace then
        resource.namespace = unquote(namespace)
      end
    end
  end
  finish()

  return locations
end

local function kube_linter_parser(output)
  local ok, result = pcall(vim.json.decode, output)
  if not ok or type(result) ~= 'table' then
    return {}
  end

  local locations = resource_locations()
  local diagnostics = {}
  local reports = type(result.Reports) == 'table' and result.Reports or {}
  for _, report in ipairs(reports) do
    local object = report.Object and report.Object.K8sObject or {}
    local gvk = object.GroupVersionKind or {}
    local location
    for _, candidate in ipairs(locations) do
      if candidate.kind == gvk.Kind and candidate.name == object.Name then
        if not object.Namespace or object.Namespace == '' or object.Namespace == candidate.namespace then
          location = candidate
          break
        end
      end
    end

    local diagnostic = report.Diagnostic or {}
    diagnostics[#diagnostics + 1] = {
      lnum = location and location.kind_line or 0,
      col = 0,
      severity = vim.diagnostic.severity.WARN,
      source = 'kube-linter',
      code = report.Check,
      message = diagnostic.Message or report.Check or 'Kubernetes policy violation',
    }
  end

  return diagnostics
end

return {
  {
    'cwrau/yaml-schema-detect.nvim',
    opts = {},
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    ft = { 'yaml', 'helm' },
  },
  {
    'mason.nvim',
    opts = {
      ensure_installed = {
        'kube-linter',
      },
    },
  },
  {
    'mfussenegger/nvim-lint',
    optional = true,
    opts = {
      linters_by_ft = {
        yaml = { 'yamllint', 'kube_linter' },
        helm = { 'yamllint' },
      },
      linters = {
        yamllint = {
          condition = function()
            return not is_sops_buffer()
          end,
        },
        kube_linter = {
          cmd = 'kube-linter',
          stdin = true,
          args = { 'lint', '-', '--format', 'json', '--with-color=false' },
          stream = 'stdout',
          ignore_exitcode = true,
          condition = function()
            return not is_sops_buffer() and is_kubernetes_buffer()
          end,
          parser = kube_linter_parser,
        },
      },
    },
  },
}
