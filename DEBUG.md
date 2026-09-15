# TRY HACKING ME NOW — Debug System

## Teste normal

Abra o projeto normalmente pelo Godot.

Ao iniciar, o jogo mostra o painel **DEBUG DIAGNOSTICS** no canto direito.

Pressione **F9** para esconder/mostrar o painel.

O painel verifica automaticamente:

- Main scene
- Player
- Player.visible
- Player modulate/alpha
- Player z-index
- Player position
- Player script
- CollisionShape2D
- Camera
- Camera enabled
- World
- Ground
- Street pole

Os resultados também aparecem no **Output** do Godot.

## Teste completo com log

Na raiz do projeto existe:

`tools/DEBUG_RUN.bat`

Execute esse arquivo no Windows.

Ele procura o executável do Godot, inicia o projeto com `--verbose` e salva stdout/stderr em:

`godot_debug.log`

Isso é especialmente importante quando existe um erro de sintaxe/parser que impede um script de carregar. Nesse caso o diagnóstico dentro do jogo pode nem conseguir iniciar, mas o BAT ainda registra a mensagem do Godot.

## Se o personagem ficar invisível

1. Execute `tools/DEBUG_RUN.bat`.
2. Deixe o jogo abrir.
3. Se o painel DEBUG aparecer, veja se existe `[ERROR]`.
4. Pressione F9 se quiser esconder o painel.
5. Feche o jogo.
6. Envie `godot_debug.log` para análise.

## Regra de segurança

O sistema de diagnóstico é somente observação. Ele não altera:

- física do Player
- input
- câmera
- posição inicial
- colisões
- `_draw()`
- assets do personagem

A finalidade é descobrir o erro real antes de fazer novas alterações no personagem.
