# cavalaridev-windows-setup

Configuração do meu Windows no tema **CavalariDev**: a barra de status [YASB](https://github.com/amnweb/yasb) e o tiling window manager [komorebi](https://github.com/LGUG2Z/komorebi), na paleta Nocturne da marca.

| Token | Cor |
|---|---|
| Fundo | `#161826` |
| Superfície | `#232532` |
| Texto | `#e9e9ed` |
| Acento | `#9184d9` |
| Verde / Azul / Âmbar | `#8ed6a8` / `#8fb9e8` / `#e3b478` |

## Estrutura

```
yasb/
  config.yaml        barras e widgets
  styles.css         tema (tokens no :root)
  assets/            indicadores de app aberto / em foco
  scripts/           popup de sistema (CPU/GPU/RAM)
  preview/           mockup interativo das barras (abre no navegador)
komorebi/
  komorebi.json      bordas, gaps, workspaces e regras de apps
  applications.json  regras por aplicativo
  whkdrc             atalhos de teclado (whkd)
```

## O que tem

**Monitor principal**, uma barra de ponta a ponta com acrylic:

- **Esquerda:** marca "C" (menu do komorebi), workspaces em pontos (o ativo vira uma barra blurple), layout atual, abas de stack, pomodoro e apps fixados. Os apps fixados mostram uma linha cinza quando o app está aberto e uma linha blurple quando está em foco.
- **Centro:** a ilha dinâmica, com visualizador de áudio, capa do que está tocando, data e hora. Clicar na capa abre o player com o app de origem.
- **Direita:** uso do Claude e do Codex, ícone de PC (abre um popup com CPU, GPU e RAM em gráficos), brilho via DDC/CI por monitor, volume, notificações, não perturbe e energia.

**Demais monitores** ficam com uma barra leve: workspaces, apps fixados, data e hora, brilho e volume.

**komorebi:** borda de 2 px arredondada, blurple na janela em foco e cinza nas outras, gaps de 10 px. O Claude desktop está cadastrado como app *layered* e *tray*, pra ser organizado.

## Instalação

Requisitos: YASB 2.0.7+, komorebi 0.1.41+ com whkd e a fonte JetBrainsMono Nerd Font. O popup de GPU usa o `nvidia-smi`, que vem com o driver NVIDIA.

```powershell
# YASB
Copy-Item -Recurse -Force .\yasb\* "$env:USERPROFILE\.config\yasb\"

# komorebi + whkd
Copy-Item -Force .\komorebi\komorebi.json, .\komorebi\applications.json "$env:USERPROFILE\"
Copy-Item -Force .\komorebi\whkdrc "$env:USERPROFILE\.config\whkdrc"

komorebic start --whkd
yasbc reload
```

Pra o komorebi subir junto com o Windows:

```powershell
komorebic enable-autostart --whkd
```

### Ajustes depois de instalar

- **Caminhos absolutos.** O `config.yaml` e o `styles.css` apontam pra `C:/Users/felip/.config/yasb/...` (scripts do popup e imagens dos indicadores). Em outra máquina, troque `felip` pelo seu usuário.
- **Apps fixados.** Ficam salvos pelo YASB, não neste repositório. Clique com o botão direito num app aberto na barra e escolha fixar.
- **Brilho.** O controle precisa de DDC/CI ligado no menu do monitor.
- **Uso do Claude.** O widget lê o login do `claude` CLI (`~/.claude/.credentials.json`).

## Notas técnicas

- Os apps fixados são selecionados no CSS por `.app-container[pinned="true"]`: quando o app está aberto, o YASB tira a classe `pinned` do ícone, mas mantém essa propriedade. Os não fixados ficam com largura zero.
- No popup de mídia (`media_lite`), o padding precisa ir nos containers internos (`header`, `media-timeline-container`, `controls`); na janela do popup ele não tem efeito.
- O komorebi compara o nome do executável em minúsculas (`claude.exe`). Por isso a regra do Claude usa a regex `(?i)^claude\.exe$`.
- O popup de sistema é um script WPF à parte (`scripts/sysmon.ps1`), aberto pelo `sysmon.vbs` sem piscar console. Ele só consome memória enquanto está aberto.
