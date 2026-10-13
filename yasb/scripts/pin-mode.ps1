# ─────────────────────────────────────────────────────────────
#  CavalariDev · modo fixar
#  Os apps não fixados ficam escondidos na barra (largura zero).
#  Este script liga/desliga um modo em que os apps abertos aparecem
#  (com fundo âmbar), pra você clicar com o botão direito e fixar.
#  Uso: rode uma vez pra ligar, fixe os apps, rode de novo pra desligar.
# ─────────────────────────────────────────────────────────────
$css   = Join-Path $env:USERPROFILE '.config\yasb\styles.css'
$start = '/* MODO FIXAR (temporário) */'
$end   = '/* FIM MODO FIXAR */'
$block = @"
$start
.taskbar-widget .app-container {
    min-width: 30px;
    max-width: 30px;
    min-height: 30px;
    max-height: 30px;
    margin: 0 2px;
    border-radius: 8px;
    background-color: rgba(227, 180, 120, 0.22);
}
$end

"@
$anchor = '.taskbar-widget .app-container.pinned,'

$text = [IO.File]::ReadAllText($css)
if ($text.Contains($start)) {
    $i = $text.IndexOf($start)
    $j = $text.IndexOf($end, $i) + $end.Length
    while ($j -lt $text.Length -and "`r`n".Contains($text[$j])) { $j++ }
    $text = $text.Remove($i, $j - $i)
    $state = 'DESLIGADO: só os apps fixados aparecem.'
} else {
    $i = $text.IndexOf($anchor)
    if ($i -lt 0) { Write-Error "Não achei o bloco dos apps fixados no styles.css."; exit 1 }
    $text = $text.Insert($i, $block)
    $state = 'LIGADO: os apps abertos aparecem com fundo âmbar. Clique com o botão direito > Pin to taskbar.'
}
[IO.File]::WriteAllText($css, $text, (New-Object Text.UTF8Encoding $false))

# o tamanho dos ícones só é recalculado num reload completo
& "$env:ProgramFiles\YASB\yasbc.exe" reload | Out-Null
Write-Host "Modo fixar $state"
