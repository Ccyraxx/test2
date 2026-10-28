-- TESTE DE BOTOES para o console Lupi.
-- Lista as constantes numericas que a SDK define (BTN_Z, LEFT, ...) e acende a que voce apertar.
-- Serve para descobrir o nome de cada botao do seu controle (SNES, teclado, etc.).
require "palette"
require "sprites"

local W, H = 480, 270
local safe = pcall or function(f, ...) return true, f(...) end

local names, vals, bad = {}, {}, {}
local down, was = {}, {}
local log = {}
local ready, crashed = false, nil
local extra = ""

local function col(rgb) return Palette.hex(rgb) end   -- so usa cores exatas da DB32
local GOLD, WHITE, DIM, RED, BLUE, INK, LINE = 0xfbf236, 0xffffff, 0x9badb7, 0xd95763, 0x639bff, 0x222034, 0x595652

local function text(s, x, y, c) ui.print(s, x, y, col(c)) end
local function fill(x, y, w, h, c) ui.rectfill(x, y, x + w - 1, y + h - 1, col(c)) end

-- coleta as constantes numericas em MAIUSCULAS definidas pela SDK
local function collect()
  local all = {}
  safe(function()
    for k, v in pairs(_G) do
      if type(k) == "string" and type(v) == "number" and k ~= "Frame" then all[#all + 1] = k end
    end
  end)
  local filtered = {}
  local ok = safe(function()
    for i = 1, #all do
      local k = all[i]
      if k == k:upper() and #k >= 2 then filtered[#filtered + 1] = k end
    end
  end)
  local list = ok and filtered or all
  -- ordena (insercao) sem usar a biblioteca table
  for i = 2, #list do
    local k, j = list[i], i - 1
    while j >= 1 and list[j] > k do list[j + 1] = list[j]; j = j - 1 end
    list[j + 1] = k
  end
  for i = 1, #list do
    names[i] = list[i]
    local _, v = safe(function() return _G[list[i]] end)
    vals[i] = v
  end
end

local function pressed_now(i)
  if bad[i] then return false end
  local ok, r = safe(ui.btn, vals[i])
  if not ok then bad[i] = true; return false end
  return r ~= nil and r ~= false and r ~= 0
end

local function step(frame)
  local now = ""
  local first = nil
  for i = 1, #names do
    local p = pressed_now(i)
    down[i] = p
    if p then
      now = now .. " " .. names[i]
      if not first then first = i end
      if not was[i] then               -- acabou de apertar: guarda no historico
        log[#log + 1] = names[i]
        if #log > 6 then for k = 1, 6 do log[k] = log[k + 1] end log[7] = nil end
      end
    end
    was[i] = p
  end
  extra = ""
  if first then
    local ok, r = safe(ui.btn, vals[first], 1)       -- sonda: existe um 2o controle por argumento?
    extra = ok and ("ui.btn(" .. names[first] .. ", 1) = " .. tostring(r)) or "ui.btn(b, 1): da erro (sem 2o argumento)"
  end

  ui.cls(col(0x000000))
  text("TESTE DE BOTOES", 8, 6, GOLD)
  text("APERTE CADA BOTAO DO CONTROLE E ANOTE O NOME QUE ACENDE", 8, 18, DIM)
  text("AGORA:" .. (now == "" and " (nada)" or now), 8, 32, WHITE)
  local hist = ""
  for i = 1, #log do hist = hist .. (i > 1 and ", " or "") .. log[i] end
  text("ULTIMOS: " .. hist, 8, 44, BLUE)
  if extra ~= "" then text(extra, 8, 56, DIM) end
  -- grade de nomes: 5 colunas x 17 linhas
  local perCol, y0 = 17, 72
  for i = 1, #names do
    local c, r = math.floor((i - 1) / perCol), (i - 1) % perCol
    if c <= 4 then
      local x, y = 6 + c * 95, y0 + r * 10
      if down[i] then fill(x - 2, y - 1, 92, 10, 0x3f3f74) end
      text(names[i], x, y, down[i] and GOLD or DIM)
    end
  end
  text(#names .. " CONSTANTES ENCONTRADAS", 8, 254, DIM)
end

function loop(frame)
  for i = 1, #Palette do ui.palset(i - 1, Palette[i]) end
  ui.clip(0, 0, W, H)
  ui.camera(0, 0)
  if crashed then
    ui.cls(col(0x000000)); text("ERRO: " .. crashed, 8, 8, RED); return
  end
  if not ready then
    local ok, err = safe(collect)
    if not ok then crashed = tostring(err); text("ERRO: " .. crashed, 8, 8, RED); return end
    ready = true
  end
  local ok, err = safe(step, frame)
  if not ok then crashed = tostring(err) end
end
