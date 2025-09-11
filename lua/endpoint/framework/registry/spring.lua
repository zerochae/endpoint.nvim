-- Spring Boot framework implementation
local base = require "endpoint.framework.base"
local spring_config = require "endpoint.framework.config.spring"

local function strip_inline_comments(s)
  -- 간단히 // 주석만 제거. 필요시 /* ... */ 처리도 추가 가능.
  return (s:gsub("%s*//.*$", ""))
end

local function concat_lines(lines, start_i, stop_i)
  local buf = {}
  for i = start_i, stop_i do
    if not lines[i] then
      break
    end
    table.insert(buf, strip_inline_comments(lines[i]))
  end
  return table.concat(buf, " ")
end

-- 괄호 포함/미포함, 단일/키-값/배열 형식 모두 커버
local function extract_first_path_from_str(s)
  if not s or s == "" then
    return ""
  end
  s = strip_inline_comments(s)

  -- 1) 만약 아직 괄호가 포함돼 있다면, 일단 괄호 안만 추출해서 단순화
  local inner = s:match "%((.*)%)"
  if inner and inner ~= "" then
    s = inner
  end

  -- 2) 가장 단순한 형태: 그냥 "경로" 하나만 있는 경우 (예: s == "\"/foo/bar\"")
  --    또는 여러 인자 중 하나지만 먼저 등장하는 따옴표를 잡는다.
  local direct = s:match '^%s*"([^"]+)"%s*$' or s:match '"([^"]+)"'
  if direct and direct ~= "" then
    return direct
  end

  -- 3) 키-값 형태: path="...", value="..."
  local kv = s:match 'path%s*=%s*"([^"]+)"' or s:match 'value%s*=%s*"([^"]+)"'
  if kv and kv ~= "" then
    return kv
  end

  -- 4) 배열 형태: path={"a","b"} 또는 value={"a","b"} → 첫 원소
  local arr = s:match "path%s*=%s*{%s*([^}]+)%s*}" or s:match "value%s*=%s*{%s*([^}]+)%s*}"
  if arr then
    local first = arr:match '"%s*([^"]-)%s*"'
    if first and first ~= "" then
      return first
    end
  end

  -- 5) (예외) 따옴표가 없지만 슬래시로 시작하는 단일 토큰일 때
  local bare = s:match "^%s*([^,%s]+)%s*$"
  if bare and bare:sub(1, 1) == "/" then
    return bare
  end

  return ""
end

local function find_enclosing_class_decl_index(lines, start_line)
  -- Find the outermost public class that could be a controller
  -- Spring controllers are typically public classes with @RequestMapping or @RestController
  local candidates = {}
  
  for i = start_line, 1, -1 do
    local L = lines[i] or ""
    -- Look for class declarations
    if L:match "%f[%w]class%f[%W]" or L:match "%f[%w]interface%f[%W]" or L:match "%f[%w]record%f[%W]" then
      -- Check if this is a public class (likely controller)
      if L:match "%f[%w]public%f[%W]" then
        table.insert(candidates, i)
      end
    end
    -- 패키지 선언 만나면 중단
    if L:match "^package%s+" then
      break
    end
  end
  
  -- Return the outermost public class (last in our backwards search)
  -- This should be the controller class, not inner classes
  if #candidates > 0 then
    return candidates[#candidates]
  end
  
  return nil
end

local function find_annotation_block_start(lines, class_decl_idx)
  -- 클래스 선언 바로 위에서부터 연속된 어노테이션 블록 시작을 찾는다
  local i = class_decl_idx - 1
  while i >= 1 do
    local L = lines[i] or ""
    -- @로 시작하는 어노테이션 줄이거나, 완전 공백 아닌 한 블록에 포함
    if L:match "^%s*@" then
      i = i - 1
    elseif L:match "^%s*$" then
      -- 완전 공백이면 블록 경계
      return i + 1
    else
      -- 어노테이션이 아닌 다른 코드 만나면 그 다음 줄이 블록 시작
      return i + 1
    end
  end
  return 1
end

local function build_annotation_blob(lines, block_start, class_decl_idx)
  -- block_start ~ (class_decl_idx - 1) 를 합쳐서 하나의 블롭으로
  local stop_i = class_decl_idx - 1
  return concat_lines(lines, block_start, stop_i)
end

-- =========================
-- 구현체
-- =========================
local M = base.new {}

function M:get_patterns(method)
  return spring_config.patterns[method:lower()] or {}
end

function M:get_file_patterns()
  return spring_config.file_patterns
end

function M:get_exclude_patterns()
  return spring_config.exclude_patterns
end

-- 메서드 레벨 매핑을 라인 기준으로 (멀티라인 포함) 파싱
function M:_extract_method_mapping(file_path, line_number)
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return ""
  end

  local i = line_number
  local line = lines[i] or ""
  
  -- Match all mapping annotations, but handle @RequestMapping specially
  if not line:match "@[%a]+Mapping" then
    -- 바로 위 줄이 어노테이션일 수도 있음
    if i > 1 and (lines[i - 1] or ""):match "@[%a]+Mapping" then
      i = i - 1
      line = lines[i] or ""
    end
  end
  if not line:match "@[%a]+Mapping" then
    return ""
  end
  
  -- If this is @RequestMapping, treat it as class-level (return empty for method mapping)
  if line:match "@RequestMapping" then
    return ""
  end

  -- Check if the annotation line has parentheses
  if not line:match "%(" then
    -- No parentheses, so no parameters - return empty string
    return ""
  end

  -- 괄호가 닫힐 때까지 아래로 확장
  local open = 0
  local start_i = i
  local stop_i = i
  while stop_i <= #lines do
    local L = lines[stop_i] or ""
    for ch in L:gmatch "." do
      if ch == "(" then
        open = open + 1
      end
      if ch == ")" then
        open = math.max(0, open - 1)
      end
    end
    if open == 0 and L:match "%)" then
      break
    end
    stop_i = stop_i + 1
  end

  local blob = concat_lines(lines, start_i, math.min(stop_i, #lines))
  local result = extract_first_path_from_str(blob)
  
  return result
end

-- 클래스 레벨 @RequestMapping 추출 (멀티라인/배열/코멘트 대응)  
function M:get_base_path(file_path, line_number)
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok or not lines then
    return ""
  end

  -- First, check if the given line itself is a @RequestMapping
  local current_line = lines[line_number] or ""
  if current_line:match "@RequestMapping" then
    local args = current_line:match "@RequestMapping%s*%((.*)%)"
    if args then
      local base_path = extract_first_path_from_str(args)
      return base_path or ""
    end
  end

  -- 이 메서드가 속한 클래스 선언 라인
  local class_decl_idx = find_enclosing_class_decl_index(lines, line_number)
  if not class_decl_idx then
    return ""
  end

  -- 클래스 선언 바로 위 어노테이션 블록 시작
  local block_start = find_annotation_block_start(lines, class_decl_idx)
  if not block_start or block_start >= class_decl_idx then
    return ""
  end

  -- 블록을 하나의 문자열로 결합
  local blob = build_annotation_blob(lines, block_start, class_decl_idx)
  if not blob or blob == "" then
    return ""
  end

  -- blob 안에서 가장 가까운(마지막) @RequestMapping(...) 찾기
  local last_match
  for s in blob:gmatch "@RequestMapping%s*%b()" do
    last_match = s
  end
  if not last_match then
    return ""
  end

  -- 괄호 안만 추출 후 path/value/배열 첫 원소 추출
  local args = last_match:match "%((.*)%)"
  local base_path = extract_first_path_from_str(args or "")
  
  return base_path or ""
end

-- rg 명령어 생성 (싱글패턴: 가장 구체적인 첫 패턴만)
function M:get_grep_cmd(method, config)
  local patterns = self:get_patterns(method)
  if not patterns or #patterns == 0 then
    error("No patterns defined for method: " .. method)
  end

  local file_patterns = self:get_file_patterns()
  local exclude_patterns = self:get_exclude_patterns()

  local cmd = "rg --line-number --column --no-heading --color=never --case-sensitive"

  for _, pattern in ipairs(file_patterns) do
    cmd = cmd .. " --glob '" .. pattern .. "'"
  end
  for _, ex in ipairs(exclude_patterns) do
    cmd = cmd .. " --glob '!" .. ex .. "'"
  end
  if config and config.rg_additional_args and config.rg_additional_args ~= "" then
    cmd = cmd .. " " .. config.rg_additional_args
  end

  -- 싱글 패턴: @GetMapping / @PostMapping 등만 먼저 긁어온다
  cmd = cmd .. " '" .. patterns[1] .. "'"
  return cmd
end

-- ripgrep 한 줄 "path:line:col:content" → 구조로 파싱
function M:parse_line(line, method, _config)
  -- Debug: parse_line 호출 확인
  local log = require("endpoint.utils.log")
  log.info("Spring parse_line called with line: " .. line)
  
  local file_path, line_number, column, content = line:match "([^:]+):(%d+):(%d+):(.*)"
  if not file_path then
    log.info("Spring parse_line failed to parse line format")
    return nil
  end
  
  log.info("Spring parse_line parsed - file: " .. file_path .. ", line_num: " .. line_number .. ", content: " .. content)

  line_number = tonumber(line_number) or 1
  column = tonumber(column) or 1

  local endpoint_path = self:_extract_method_mapping(file_path, line_number)
  local base_path = self:get_base_path(file_path, line_number)
  local full_path = self:combine_paths(base_path, endpoint_path)
  
  -- Debug: path combination 확인
  local log = require("endpoint.utils.log")
  log.info("Spring parse_line - base: '" .. (base_path or "nil") .. "', endpoint: '" .. (endpoint_path or "nil") .. "', full: '" .. (full_path or "nil") .. "'")

  return {
    file_path = file_path,
    line_number = line_number,
    column = column,
    endpoint_path = full_path,
    method = method:upper(),
    raw_line = line,
    content = content,
  }
end

return M
