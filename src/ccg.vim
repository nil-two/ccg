let b:app = {}

function! b:app.start() abort
  setlocal shortmess+=I
  setlocal t_ve=

  highlight EndOfBuffer ctermfg=0
  call popup_clear()
  let popup_winid = popup_create('', {})
  call win_execute(popup_winid, 'set wincolor=none')
  call win_execute(popup_winid, 'highlight AppText   ctermfg=green ctermbg=none')
  call win_execute(popup_winid, 'highlight AppFrame  ctermfg=green ctermbg=green')
  call win_execute(popup_winid, 'highlight AppCursor ctermfg=green ctermbg=gray')
  call win_execute(popup_winid, 'syntax match AppText  /\S/')
  call win_execute(popup_winid, 'syntax match AppFrame /#/')

  let self.scene            = v:null
  let self.n_wins_by_player = {'o': 0, 'x': 0}
  let self.popup_winid      = popup_winid
  let self.canvas           = s:new_canvas(33, 9)
  let self.first_turn       = v:null
  let self.current_turn     = v:null
  let self.board            = v:null
  let self.board_cursor_x   = v:null
  let self.board_cursor_y   = v:null
  let self.current_result   = v:null
  let self.continue_game    = v:null

  call self.switch_to_game('o')
  call self.update_screen()
endfunction

function! b:app.switch_to_game(first_turn) abort
  let self.scene          = 'game'
  let self.first_turn     = a:first_turn
  let self.current_turn   = a:first_turn
  let self.board          = map(range(3), {_ -> map(range(3), {_ -> ' '})})
  let self.board_cursor_x = 2
  let self.board_cursor_y = 2

  mapclear <buffer>
  call s:disable_allkeys_in_buffer_as_far_as_possible()
  nnoremap <silent><buffer><Left>  :<C-u>call b:app.game_move_cursor(-1, 0)<CR>
  nnoremap <silent><buffer>h       :<C-u>call b:app.game_move_cursor(-1, 0)<CR>
  nnoremap <silent><buffer><Down>  :<C-u>call b:app.game_move_cursor(0,  1)<CR>
  nnoremap <silent><buffer>j       :<C-u>call b:app.game_move_cursor(0,  1)<CR>
  nnoremap <silent><buffer><Up>    :<C-u>call b:app.game_move_cursor(0,  -1)<CR>
  nnoremap <silent><buffer>k       :<C-u>call b:app.game_move_cursor(0,  -1)<CR>
  nnoremap <silent><buffer><Right> :<C-u>call b:app.game_move_cursor(1,  0)<CR>
  nnoremap <silent><buffer>l       :<C-u>call b:app.game_move_cursor(1,  0)<CR>
  nnoremap <silent><buffer><CR>    :<C-u>call b:app.game_mark_cell()<CR>
  nnoremap <silent><buffer><Space> :<C-u>call b:app.game_mark_cell()<CR>
  nnoremap <silent><buffer>q       :<C-u>call b:app.exit()<CR>
  nnoremap <silent><buffer><C-c>   :<C-u>call b:app.exit_emergent()<CR>
endfunction

function! b:app.game_move_cursor(dx, dy) abort
  let self.board_cursor_x = min([max([self.board_cursor_x + a:dx, 1]), 3])
  let self.board_cursor_y = min([max([self.board_cursor_y + a:dy, 1]), 3])
  call self.update_screen()
endfunction

function! b:app.game_mark_cell() abort
  call self.mark_cell()
  call self.update_screen()
endfunction

function! b:app.switch_to_result(result) abort
  let self.scene          = 'result'
  let self.current_result = a:result
  let self.continue_game  = v:true
  if has_key(a:result, 'winner')
    let self.n_wins_by_player[a:result.winner] += 1
  endif

  mapclear <buffer>
  call s:disable_allkeys_in_buffer_as_far_as_possible()
  nnoremap <silent><buffer><Left>  :<C-u>call b:app.result_toggle_select()<CR>
  nnoremap <silent><buffer>h       :<C-u>call b:app.result_toggle_select()<CR>
  nnoremap <silent><buffer><Right> :<C-u>call b:app.result_toggle_select()<CR>
  nnoremap <silent><buffer>l       :<C-u>call b:app.result_toggle_select()<CR>
  nnoremap <silent><buffer><CR>    :<C-u>call b:app.result_select()<CR>
  nnoremap <silent><buffer><Space> :<C-u>call b:app.result_select()<CR>
  nnoremap <silent><buffer>q       :<C-u>call b:app.exit()<CR>
  nnoremap <silent><buffer><C-c>   :<C-u>call b:app.exit_emergent()<CR>
endfunction

function! b:app.result_toggle_select() abort
  let self.continue_game = !self.continue_game
  call self.update_screen()
endfunction

function! b:app.result_select() abort
  if self.continue_game
    let next_first_turn = v:null
    if self.first_turn ==# 'o'
      let next_first_turn = 'x'
    elseif self.first_turn ==# 'x'
      let next_first_turn = 'o'
    endif
    call self.switch_to_game(next_first_turn)
    call self.update_screen()
  else
    call self.exit()
  endif
endfunction

function! b:app.mark_cell() abort
  if self.board[self.board_cursor_y-1][self.board_cursor_x-1] !=# ' '
    return
  endif
  let self.board[self.board_cursor_y-1][self.board_cursor_x-1] = self.current_turn

  let result = self.check_board()
  if !has_key(result, 'continue')
    call self.switch_to_result(result)
    return
  endif

  if self.current_turn ==# 'o'
    let self.current_turn = 'x'
  elseif self.current_turn ==# 'x'
    let self.current_turn = 'o'
  endif
endfunction

function! b:app.check_board() abort
  for player in ['o', 'x']
    let won = 
    \ (self.board[0][0] ==# player && self.board[1][0] ==# player && self.board[2][0] ==# player) ||
    \ (self.board[0][1] ==# player && self.board[1][1] ==# player && self.board[2][1] ==# player) ||
    \ (self.board[0][2] ==# player && self.board[1][2] ==# player && self.board[2][2] ==# player) ||
    \ (self.board[0][0] ==# player && self.board[0][1] ==# player && self.board[0][2] ==# player) ||
    \ (self.board[1][0] ==# player && self.board[1][1] ==# player && self.board[1][2] ==# player) ||
    \ (self.board[2][0] ==# player && self.board[2][1] ==# player && self.board[2][2] ==# player) ||
    \ (self.board[0][0] ==# player && self.board[1][1] ==# player && self.board[2][2] ==# player) ||
    \ (self.board[0][2] ==# player && self.board[1][1] ==# player && self.board[2][0] ==# player)
    if won
      return {'winner': player}
    endif
  endfor
  let drew = v:true
  for x in range(3)
    for y in range(3)
      if self.board[y][x] ==# ' '
        let drew = v:false
      endif
    endfor
  endfor
  if drew
    return {'draw': v:true}
  endif
  return {'continue': v:true}
endfunction

function! b:app.update_screen() abort
  call self.canvas.clear()
  call self.canvas.draw_text(9, 1, 'Circle Cross Game')
  call self.canvas.draw_text(4, 4, 'Circle:')
  call self.canvas.draw_text(12, 4, printf('%2d', min([self.n_wins_by_player['o'], 99])))
  call self.canvas.draw_text(5, 6, 'Cross:')
  call self.canvas.draw_text(12, 6, printf('%2d', min([self.n_wins_by_player['x'], 99])))
  for fdx in range(5)
    call self.canvas.draw_char(15+fdx, 3, '#')
    call self.canvas.draw_char(15+fdx, 7, '#')
  endfor
  for fdy in range(5)
    call self.canvas.draw_char(15, 3+fdy, '#')
    call self.canvas.draw_char(19, 3+fdy, '#')
  endfor
  for bdy in range(3)
    for bdx in range(3)
      call self.canvas.draw_char(16+bdx, 4+bdy, self.board[bdy][bdx])
    endfor
  endfor
  if self.scene ==# 'game'
    call self.canvas.draw_text(21, 4, 'Circle')
    call self.canvas.draw_text(21, 6, 'Cross')
    if self.current_turn ==# 'o'
      call self.canvas.draw_text(28, 4, '(Turn)')
    elseif self.current_turn ==# 'x'
      call self.canvas.draw_text(28, 6, '(Turn)')
    endif
    call self.canvas.draw_text(9, 9, '(Press q to quit)')
  elseif self.scene ==# 'result'
    if has_key(self.current_result, 'winner') && self.current_result.winner ==# 'o'
      call self.canvas.draw_text(21, 5, 'Circle win!')
    elseif has_key(self.current_result, 'winner') && self.current_result.winner ==# 'x'
      call self.canvas.draw_text(21, 5, 'Cross win!')
    elseif has_key(self.current_result, 'draw')
      call self.canvas.draw_text(21, 5, 'Draw...')
    endif
    call self.canvas.draw_text(10, 9, 'Replay')
    call self.canvas.draw_text(19, 9, 'Quit')
  endif
  call popup_settext(self.popup_winid, self.canvas.to_lines())

  call clearmatches(self.popup_winid)
  if self.scene ==# 'game'
    call win_execute(self.popup_winid, printf('call matchaddpos(''AppCursor'', [[%d, %d]])', 4+self.board_cursor_y-1, 16+self.board_cursor_x-1))
  elseif self.scene ==# 'result'
    if self.continue_game
      call win_execute(self.popup_winid, printf('call matchaddpos(''AppCursor'', [[%d, %d, %d]])', 9, 10, 6))
    else
      call win_execute(self.popup_winid, printf('call matchaddpos(''AppCursor'', [[%d, %d, %d]])', 9, 19, 4))
    end
  endif
endfunction

function! b:app.exit() abort
  setlocal t_ve&
  quit!
endfunction

function! b:app.exit_emergent() abort
  setlocal modifiable
  setlocal t_ve&
  call popup_clear()
  mapclear <buffer>
endfunction

let s:canvas = {}
function! s:new_canvas(width, height) abort
  let canvas        = deepcopy(s:canvas)
  let canvas.width  = a:width
  let canvas.height = a:height
  let canvas.cells  = map(range(a:height), {_ -> map(range(a:width), {_ -> ' '})})
  return canvas
endfunction

function! s:canvas.clear() abort
  for y in range(self.height)
    for x in range(self.width)
      let self.cells[y][x] = ' '
    endfor
  endfor
endfunction

function! s:canvas.draw_char(x, y, char) abort
  if 1 <= a:x && a:x <= self.width && 1 <= a:y && a:y <= self.height
    let self.cells[a:y-1][a:x-1] = a:char
  endif
endfunction

function! s:canvas.draw_text(x, y, text) abort
  let chars = split(a:text, '\zs')
  for dx in range(len(chars))
    call self.draw_char(a:x+dx, a:y, chars[dx])
  endfor
endfunction

function! s:canvas.to_lines() abort
  return map(copy(self.cells), {_, a -> join(a, '')})
endfunction

function! s:disable_allkeys_in_buffer_as_far_as_possible()
  let keys = []
  call extend(keys, ['<CR>', '<Space>', '<Tab>', '<BS>', '<Del>', '<Up>', '<Down>', '<Left>', '<Right>'])
  call extend(keys, map(range(33, 126),                    {_, nr -> escape(nr2char(nr), '|')}))
  call extend(keys, map(range(33, 126),                    {_, nr -> printf('g%s', escape(nr2char(nr), '|'))}))
  call extend(keys, map(range(char2nr('a'), char2nr('z')), {_, nr -> printf('<C-%s>', escape(nr2char(nr), '|'))}))
  for key in keys
    execute printf('nnoremap <silent><buffer>%s <NOP>', key)
  endfor
endfunction

call b:app.start()
