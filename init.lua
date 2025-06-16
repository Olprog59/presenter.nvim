local M = {}

local namespace = vim.api.nvim_create_namespace "presenter"
local highlight_group = "PresenterFocus"
local dim_group = "PresenterDim"

local state = {
  is_focused = false,
  selected_zones = {}, -- Zones sélectionnées manuellement
  buffer = 0,
  save_history = {}, -- Historique des 2 derniers enregistrements
  max_history = 2,
}

-- Default configuration
M.config = {
  keymaps = {
    toggle = "<leader>pp",
    add = "<leader>pa",
    reset = "<leader>pr",
  },
  dim_highlight = { fg = "#6c7086" },
  highlight = {},
}

function M.setup(opts)
  -- Works for both AstroNvim and LazyVim
  if M.config then
    -- LazyVim style: merge with default config
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    opts = M.config
  else
    -- AstroNvim style: use opts directly
    opts = opts or {}
  end

  local function setup_highlights()
    -- Pour le focus : on ne surcharge rien, on garde les couleurs normales du code
    -- Pour le dim : on applique une couleur grise subtile

    local comment_hl = vim.api.nvim_get_hl(0, { name = "Comment" })

    -- Couleur grise par défaut pour le dim
    local default_dim = {
      fg = comment_hl.fg or 0x6c7086, -- Gris basé sur les commentaires
      -- Pas de bg pour garder la transparence
    }

    -- Le focus n'a pas besoin de highlight spécial - on garde les couleurs normales
    -- On crée quand même un groupe vide au cas où l'utilisateur veuille personnaliser
    local focus_highlight = opts.highlight or {} -- Vide par défaut = couleurs normales
    local dim_highlight = opts.dim_highlight or default_dim

    -- Configure les highlights
    if next(focus_highlight) ~= nil then
      -- Seulement si l'utilisateur a spécifié des couleurs custom pour le focus
      vim.api.nvim_set_hl(0, highlight_group, focus_highlight)
    else
      -- Pas de highlight pour le focus = garde les couleurs normales
      vim.api.nvim_set_hl(0, highlight_group, {})
    end

    vim.api.nvim_set_hl(0, dim_group, dim_highlight)
  end

  -- Configure les highlights au démarrage
  setup_highlights()

  -- Déclarations forward pour éviter les problèmes de scope
  local show_changes
  local save_to_history

  local function detect_changes()
    if #state.save_history < 2 then return {} end

    -- Compare toujours les 2 dernières sauvegardes
    local old_content = state.save_history[2].content -- Avant-dernier save
    local new_content = state.save_history[1].content -- Dernier save
    local changes = {}

    -- Algorithme de diff par blocs contigus
    local old_len = #old_content
    local new_len = #new_content

    -- Si taille identique, comparaison ligne par ligne simple
    if old_len == new_len then
      for i = 1, new_len do
        if old_content[i] ~= new_content[i] then
          table.insert(changes, i - 1) -- 0-indexed
        end
      end
      return changes
    end

    -- Trouve le point de divergence du début
    local start_same = 0
    for i = 1, math.min(old_len, new_len) do
      if old_content[i] == new_content[i] then
        start_same = i
      else
        break
      end
    end

    -- Trouve le point de divergence de la fin
    local end_same = 0
    for i = 1, math.min(old_len - start_same, new_len - start_same) do
      if old_content[old_len - i + 1] == new_content[new_len - i + 1] then
        end_same = i
      else
        break
      end
    end

    -- Les lignes modifiées sont entre start_same et (new_len - end_same)
    for i = start_same + 1, new_len - end_same do
      table.insert(changes, i - 1) -- 0-indexed
    end

    return changes
  end

  local function add_visual_selection()
    -- Force la mise à jour des marks de sélection
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    vim.schedule(function()
      local start_pos = vim.fn.getpos "'<"
      local end_pos = vim.fn.getpos "'>"

      if start_pos[2] == 0 or end_pos[2] == 0 then
        vim.notify "No visual selection found"
        return
      end

      local start_line = start_pos[2] - 1 -- 0-indexed
      local end_line = end_pos[2] - 1

      -- Assure que start <= end
      if start_line > end_line then
        start_line, end_line = end_line, start_line
      end

      table.insert(state.selected_zones, { start_line, end_line })

      if start_line == end_line then
        vim.notify(string.format("Line %d added (total: %d zones)", start_line + 1, #state.selected_zones))
      else
        vim.notify(
          string.format("Lines %d-%d added (total: %d zones)", start_line + 1, end_line + 1, #state.selected_zones)
        )
      end

      -- Met à jour automatiquement le focus si activé
      if state.is_focused then
        vim.schedule(function()
          show_changes(true) -- auto_update = true
        end)
      end
    end)
  end

  local function clear_highlights() vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1) end

  show_changes = function(auto_update)
    -- If manual toggle and already focused, turn off
    if not auto_update and state.is_focused then
      clear_highlights()
      state.is_focused = false
      vim.notify "Focus disabled"
      return
    end

    local current_buf = vim.api.nvim_get_current_buf()

    -- Take initial snapshot if needed
    if #state.save_history == 0 then
      state.buffer = current_buf
      save_to_history()
      -- If no manual selections, just notify and return
      if #state.selected_zones == 0 then
        if not auto_update then vim.notify "First save recorded - save again to see changes" end
        return
      end
      -- Otherwise continue to show manual selections
    end

    if current_buf ~= state.buffer then
      if not auto_update then vim.notify "Different buffer - reinitializing" end
      state.buffer = current_buf
      save_to_history()
      return
    end

    -- Détecte les changements automatiquement
    local auto_changes = detect_changes()

    -- Combine changements automatiques et sélections manuelles
    local focus_lines = {}

    -- Ajoute les changements automatiques
    for _, line in ipairs(auto_changes) do
      focus_lines[line] = true
    end

    -- Ajoute les zones sélectionnées manuellement
    for _, zone in ipairs(state.selected_zones) do
      local start_line, end_line = zone[1], zone[2]
      for line = start_line, end_line do
        focus_lines[line] = true
      end
    end

    if next(focus_lines) == nil then
      if not auto_update then
        if #state.save_history < 2 then
          vim.notify "Need 2 saves minimum or add selections"
        else
          vim.notify "No changes between last 2 saves"
        end
      end
      return
    end

    clear_highlights()

    local total_lines = vim.api.nvim_buf_line_count(0)

    -- Applique le surlignage : seules les lignes NON-focus sont grisées
    for line = 0, total_lines - 1 do
      if focus_lines[line] then
        -- Lignes en focus : on applique le highlight focus (qui peut être vide = couleurs normales)
        if next(opts.highlight or {}) ~= nil then
          local line_text = vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
          vim.api.nvim_buf_set_extmark(0, namespace, line, 0, {
            end_row = line,
            end_col = #line_text,
            hl_group = highlight_group,
            hl_eol = true,
          })
        end
        -- Sinon on ne fait rien = garde les couleurs normales du code
      else
        -- Lignes pas en focus : on les grise
        local line_text = vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
        vim.api.nvim_buf_set_extmark(0, namespace, line, 0, {
          end_row = line,
          end_col = #line_text,
          hl_group = dim_group,
          hl_eol = true,
        })
      end
    end

    state.is_focused = true
    local changes_count = #auto_changes
    local selections_count = #state.selected_zones

    if not auto_update then
      vim.notify(string.format("Focus: %d changes + %d selections", changes_count, selections_count))
    end
  end

  -- Maintenant on peut définir save_to_history qui utilise show_changes
  save_to_history = function()
    local current_buf = vim.api.nvim_get_current_buf()
    state.buffer = current_buf

    local current_content = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
    local timestamp = os.time()

    -- Ajoute au début de l'historique
    table.insert(state.save_history, 1, {
      content = current_content,
      timestamp = timestamp,
      buffer = current_buf,
    })

    -- Garde seulement les 2 derniers
    while #state.save_history > state.max_history do
      table.remove(state.save_history)
    end

    -- Met à jour automatiquement le focus si activé
    if state.is_focused then
      vim.schedule(function()
        show_changes(true) -- auto_update = true
      end)
    end
  end

  -- Commandes principales
  vim.api.nvim_create_user_command("Presenter", show_changes, {})
  vim.api.nvim_create_user_command("PresenterAdd", add_visual_selection, {})

  vim.api.nvim_create_user_command("PresenterReset", function()
    state.selected_zones = {}
    state.save_history = {}
    state.buffer = 0
    clear_highlights()
    state.is_focused = false
    vim.notify "Presenter reset complete"
  end, {})

  vim.api.nvim_create_user_command("PresenterStatus", function()
    local auto_changes = detect_changes()
    local focus_text = state.is_focused and "enabled" or "disabled"

    local history_text = ""
    if #state.save_history >= 2 then
      local time1 = os.date("%H:%M:%S", state.save_history[1].timestamp)
      local time2 = os.date("%H:%M:%S", state.save_history[2].timestamp)
      history_text = string.format("\n- Saves: %s → %s", time2, time1)
    elseif #state.save_history == 1 then
      local time1 = os.date("%H:%M:%S", state.save_history[1].timestamp)
      history_text = string.format("\n- Saves: %s (need 1 more)", time1)
    else
      history_text = "\n- Saves: none"
    end

    vim.notify(
      string.format(
        "Presenter:\n- Focus: %s\n- Changes: %d\n- Selections: %d%s",
        focus_text,
        #auto_changes,
        #state.selected_zones,
        history_text
      )
    )
  end, {})

  -- Raccourcis clavier configurables
  local keymaps = opts.keymaps or {
    toggle = "<leader>pp",
    add = "<leader>pa",
    reset = "<leader>pr",
  }

  if keymaps.toggle then vim.keymap.set("n", keymaps.toggle, show_changes, { desc = "Presenter: Toggle focus" }) end

  if keymaps.add then vim.keymap.set("v", keymaps.add, add_visual_selection, { desc = "Presenter: Add selection" }) end

  if keymaps.reset then
    vim.keymap.set("n", keymaps.reset, function()
      state.selected_zones = {}
      clear_highlights()
      state.is_focused = false
      vim.notify "Selections and focus reset"
    end, { desc = "Presenter: Reset soft" })
  end

  -- Autocommands (à la fin après les définitions de fonctions)
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("PresenterColors", { clear = true }),
    callback = setup_highlights,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("PresenterAutoSave", { clear = true }),
    callback = save_to_history,
  })
end

return M
