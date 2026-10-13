# ─────────────────────────────────────────────────────────────
#  CavalariDev · popup de sistema (CPU / GPU / RAM)
#  Aberto pelo ícone de PC no YASB. Clicar de novo no ícone,
#  clicar fora ou apertar Esc fecha. Só consome RAM enquanto aberto.
# ─────────────────────────────────────────────────────────────
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, Microsoft.VisualBasic

# ── Toggle: clicar no ícone com o popup aberto tira o foco dele (fecha);
#    se acabou de fechar, este clique era pra fechar, então não reabre ──
$stamp = Join-Path $env:TEMP 'cavalaridev-sysmon.closed'
if (Test-Path $stamp) {
    $closedAt = [datetime]::FromBinary([long](Get-Content $stamp -Raw))
    if (((Get-Date) - $closedAt).TotalMilliseconds -lt 1500) { exit }
}

# ── Instância única: se já estiver aberto, pede pra fechar e sai ──
$created = $false
$closeSignal = New-Object System.Threading.EventWaitHandle($false, 'AutoReset', 'CavalariDevSysmonClose', [ref]$created)
if (-not $created) { [void]$closeSignal.Set(); exit }

# ── Paleta Nocturne ──
$C = @{
    Bg = '#161826'; Surface = '#232532'; Text = '#e9e9ed'; Muted = '#9397ab'; Dim = '#595d6c'; Edge = '#2c2f3d'
    Cpu = '#9184d9'; Gpu = '#8ed6a8'; Ram = '#8fb9e8'; Amber = '#e3b478'; Rose = '#e89a9a'
}
$Mono = 'JetBrainsMono NFP, Cascadia Mono, Consolas'

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        ShowInTaskbar="False" Topmost="True" ResizeMode="NoResize"
        SizeToContent="WidthAndHeight" FontFamily="Segoe UI" UseLayoutRounding="True">
  <Border x:Name="Shell" CornerRadius="12" BorderThickness="1" BorderBrush="$($C.Edge)" Padding="18,16,18,14" Width="340">
    <Border.Background>
      <SolidColorBrush Color="$($C.Bg)" Opacity="0.94"/>
    </Border.Background>
    <StackPanel>
      <Grid Margin="0,0,0,12">
        <TextBlock Text="Sistema" Foreground="$($C.Text)" FontSize="14" FontWeight="SemiBold"/>
        <TextBlock x:Name="Uptime" HorizontalAlignment="Right" Foreground="$($C.Muted)" FontSize="11" VerticalAlignment="Center" FontFamily="$Mono"/>
      </Grid>

      <!-- CPU -->
      <Grid Margin="0,0,0,4">
        <StackPanel>
          <TextBlock Text="CPU" Foreground="$($C.Cpu)" FontSize="12" FontWeight="SemiBold"/>
          <TextBlock x:Name="CpuName" Foreground="$($C.Muted)" FontSize="11" Margin="0,1,0,0"/>
        </StackPanel>
        <TextBlock x:Name="CpuVal" HorizontalAlignment="Right" Foreground="$($C.Text)" FontSize="20" FontFamily="$Mono" VerticalAlignment="Center"/>
      </Grid>
      <Border Height="54" CornerRadius="6" Background="#0fe9e9ed" ClipToBounds="True">
        <Canvas x:Name="CpuGraph"/>
      </Border>
      <TextBlock x:Name="CpuInfo" Foreground="$($C.Muted)" FontSize="11" FontFamily="$Mono" Margin="0,6,0,14"/>

      <!-- GPU -->
      <Grid Margin="0,0,0,4">
        <StackPanel>
          <TextBlock Text="GPU" Foreground="$($C.Gpu)" FontSize="12" FontWeight="SemiBold"/>
          <TextBlock x:Name="GpuName" Foreground="$($C.Muted)" FontSize="11" Margin="0,1,0,0"/>
        </StackPanel>
        <TextBlock x:Name="GpuVal" HorizontalAlignment="Right" Foreground="$($C.Text)" FontSize="20" FontFamily="$Mono" VerticalAlignment="Center"/>
      </Grid>
      <Border Height="54" CornerRadius="6" Background="#0fe9e9ed" ClipToBounds="True">
        <Canvas x:Name="GpuGraph"/>
      </Border>
      <TextBlock x:Name="GpuInfo" Foreground="$($C.Muted)" FontSize="11" FontFamily="$Mono" Margin="0,6,0,14"/>

      <!-- RAM -->
      <Grid Margin="0,0,0,4">
        <StackPanel>
          <TextBlock Text="RAM" Foreground="$($C.Ram)" FontSize="12" FontWeight="SemiBold"/>
          <TextBlock x:Name="RamName" Foreground="$($C.Muted)" FontSize="11" Margin="0,1,0,0"/>
        </StackPanel>
        <TextBlock x:Name="RamVal" HorizontalAlignment="Right" Foreground="$($C.Text)" FontSize="20" FontFamily="$Mono" VerticalAlignment="Center"/>
      </Grid>
      <Border Height="54" CornerRadius="6" Background="#0fe9e9ed" ClipToBounds="True">
        <Canvas x:Name="RamGraph"/>
      </Border>
      <TextBlock x:Name="RamInfo" Foreground="$($C.Muted)" FontSize="11" FontFamily="$Mono" Margin="0,6,0,12"/>

      <Border BorderBrush="$($C.Edge)" BorderThickness="0,1,0,0" Padding="0,10,0,0">
        <Grid>
          <TextBlock Text="atualiza a cada 1 s · Esc fecha" Foreground="$($C.Dim)" FontSize="11" VerticalAlignment="Center"/>
          <Button x:Name="TaskMgr" HorizontalAlignment="Right" Content="Gerenciador de Tarefas" Cursor="Hand"
                  Foreground="$($C.Muted)" Background="Transparent" BorderThickness="0" FontSize="11" Padding="0">
            <Button.Template>
              <ControlTemplate TargetType="Button">
                <TextBlock x:Name="t" Text="{TemplateBinding Content}" Foreground="{TemplateBinding Foreground}"/>
                <ControlTemplate.Triggers>
                  <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="t" Property="Foreground" Value="#d2cefd"/>
                  </Trigger>
                </ControlTemplate.Triggers>
              </ControlTemplate>
            </Button.Template>
          </Button>
        </Grid>
      </Border>
    </StackPanel>
  </Border>
</Window>
"@

$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$ui = @{}
foreach ($n in 'Uptime','CpuName','CpuVal','CpuGraph','CpuInfo','GpuName','GpuVal','GpuGraph','GpuInfo','RamName','RamVal','RamGraph','RamInfo','TaskMgr') {
    $ui[$n] = $win.FindName($n)
}

# ── Fontes de dados ──
$cpuInfo  = Get-CimInstance Win32_Processor | Select-Object -First 1
$cpuUtil  = New-Object System.Diagnostics.PerformanceCounter('Processor Information', '% Processor Utility', '_Total')
$cpuPerf  = New-Object System.Diagnostics.PerformanceCounter('Processor Information', '% Processor Performance', '_Total')
[void]$cpuUtil.NextValue(); [void]$cpuPerf.NextValue()
$compInfo = New-Object Microsoft.VisualBasic.Devices.ComputerInfo
$boot     = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$ui.CpuName.Text = ($cpuInfo.Name -replace '\s+Processor', '' -replace '\s{2,}', ' ').Trim()
$ui.RamName.Text = '{0:N0} GB instalados' -f ($compInfo.TotalPhysicalMemory / 1GB)

# GPU: um único nvidia-smi em loop, lido sem travar a interface
$gpu = $null; $gpuRead = $null; $gpuLast = $null
$smi = (Get-Command nvidia-smi -ErrorAction SilentlyContinue).Source
if ($smi) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $smi
    $psi.Arguments = '--query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,clocks.gr --format=csv,noheader,nounits -lms 1000'
    $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.CreateNoWindow = $true
    $gpu = [System.Diagnostics.Process]::Start($psi)
    $gpuRead = $gpu.StandardOutput.ReadLineAsync()
} else {
    $ui.GpuName.Text = 'nvidia-smi não encontrado'
}

# ── Gráficos (60 s de histórico) ──
$N = 60
$hist = @{ Cpu = New-Object System.Collections.Generic.List[double]; Gpu = New-Object System.Collections.Generic.List[double]; Ram = New-Object System.Collections.Generic.List[double] }

function New-Brush([string]$hex, [double]$opacity = 1) {
    $b = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.ColorConverter]::ConvertFromString($hex))
    $b.Opacity = $opacity; $b
}

function Draw-Graph($canvas, $values, [string]$hex) {
    $canvas.Children.Clear()
    $w = 302.0; $h = 54.0
    if ($values.Count -lt 1) { return }
    $step = $w / ($N - 1)
    $x0 = $w - ($values.Count - 1) * $step
    $line = New-Object System.Windows.Shapes.Polyline
    $area = New-Object System.Windows.Shapes.Polygon
    $area.Points.Add((New-Object System.Windows.Point($x0, $h)))
    for ($i = 0; $i -lt $values.Count; $i++) {
        $v = [Math]::Max(0, [Math]::Min(100, $values[$i]))
        $pt = New-Object System.Windows.Point(($x0 + $i * $step), ($h - 3 - ($v / 100.0) * ($h - 8)))
        $line.Points.Add($pt); $area.Points.Add($pt)
    }
    $area.Points.Add((New-Object System.Windows.Point($w, $h)))
    $grad = New-Object System.Windows.Media.LinearGradientBrush
    $grad.StartPoint = '0,0'; $grad.EndPoint = '0,1'
    $top = [System.Windows.Media.ColorConverter]::ConvertFromString($hex); $top.A = 90
    $bot = [System.Windows.Media.ColorConverter]::ConvertFromString($hex); $bot.A = 0
    $grad.GradientStops.Add((New-Object System.Windows.Media.GradientStop($top, 0)))
    $grad.GradientStops.Add((New-Object System.Windows.Media.GradientStop($bot, 1)))
    $area.Fill = $grad
    $line.Stroke = New-Brush $hex; $line.StrokeThickness = 1.6
    $line.StrokeLineJoin = 'Round'
    [void]$canvas.Children.Add($area); [void]$canvas.Children.Add($line)
}

function Push($key, [double]$v) {
    $hist[$key].Add($v)
    if ($hist[$key].Count -gt $N) { $hist[$key].RemoveAt(0) }
}

function Color-For([double]$v, [string]$base) {
    if ($v -ge 90) { return $C.Rose } elseif ($v -ge 70) { return $C.Amber } else { return $C.Text }
}

function Update-Stats {
    # CPU
    $u = [Math]::Min(100, $cpuUtil.NextValue())
    $mhz = $cpuInfo.MaxClockSpeed * $cpuPerf.NextValue() / 100
    Push 'Cpu' $u
    $ui.CpuVal.Text = '{0:N0}%' -f $u
    $ui.CpuVal.Foreground = New-Brush (Color-For $u)
    $ui.CpuInfo.Text = '{0:N2} GHz · {1} núcleos / {2} threads' -f ($mhz / 1000), $cpuInfo.NumberOfCores, $cpuInfo.NumberOfLogicalProcessors
    Draw-Graph $ui.CpuGraph $hist.Cpu $C.Cpu

    # GPU
    if ($gpuRead -and $gpuRead.IsCompleted) {
        $line = $gpuRead.Result
        if ($line) { $script:gpuLast = $line.Split(',') | ForEach-Object { $_.Trim() } }
        if (-not $gpu.HasExited) { $script:gpuRead = $gpu.StandardOutput.ReadLineAsync() }
    }
    if ($gpuLast) {
        $g = [double]$gpuLast[1]
        Push 'Gpu' $g
        $ui.GpuName.Text = $gpuLast[0] -replace '^NVIDIA\s+', ''
        $ui.GpuVal.Text = '{0:N0}%' -f $g
        $ui.GpuVal.Foreground = New-Brush (Color-For $g)
        $ui.GpuInfo.Text = 'VRAM {0:N1}/{1:N0} GB · {2}°C · {3:N0} W · {4} MHz' -f ([double]$gpuLast[2] / 1024), ([double]$gpuLast[3] / 1024), $gpuLast[4], [double]$gpuLast[5], $gpuLast[6]
        Draw-Graph $ui.GpuGraph $hist.Gpu $C.Gpu
    }

    # RAM
    $total = $compInfo.TotalPhysicalMemory; $avail = $compInfo.AvailablePhysicalMemory
    $r = ($total - $avail) * 100.0 / $total
    Push 'Ram' $r
    $ui.RamVal.Text = '{0:N0}%' -f $r
    $ui.RamVal.Foreground = New-Brush (Color-For $r)
    $ui.RamInfo.Text = '{0:N1} GB em uso · {1:N1} GB livres' -f (($total - $avail) / 1GB), ($avail / 1GB)
    Draw-Graph $ui.RamGraph $hist.Ram $C.Ram

    $up = (Get-Date) - $boot
    $ui.Uptime.Text = 'ligado há {0}h {1:D2}m' -f [int][Math]::Floor($up.TotalHours), $up.Minutes
}

# ── Posição: centralizado sob o ícone clicado, logo abaixo da barra ──
$cursor = [System.Windows.Forms.Cursor]::Position
$screen = [System.Windows.Forms.Screen]::FromPoint($cursor)
$win.Add_SourceInitialized({
    $src = [System.Windows.PresentationSource]::FromVisual($win)
    $sx = $src.CompositionTarget.TransformToDevice.M11
    $sy = $src.CompositionTarget.TransformToDevice.M22
    $win.UpdateLayout()
    $wpx = $win.ActualWidth * $sx
    $x = [Math]::Min([Math]::Max($cursor.X - $wpx / 2, $screen.Bounds.Left + 10), $screen.Bounds.Right - $wpx - 10)
    $win.Left = $x / $sx
    $win.Top = ($screen.Bounds.Top + 52) / $sy
})

# ── Fechar: clicar fora, Esc, ou novo clique no ícone ──
$closing = $false
$close = {
    if (-not $script:closing) {
        $script:closing = $true
        (Get-Date).ToBinary() | Set-Content -Path $stamp -NoNewline
        $win.Close()
    }
}
$win.Add_Deactivated($close)
$win.Add_KeyDown({ if ($_.Key -eq 'Escape') { & $close } })
$ui.TaskMgr.Add_Click({ Start-Process taskmgr; & $close })

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(1000)
$timer.Add_Tick({
    if ($closeSignal.WaitOne(0)) { & $close; return }
    Update-Stats
})

$win.Add_ContentRendered({ $win.Activate(); Update-Stats; $timer.Start() })
$win.Add_Closed({
    $timer.Stop()
    if ($gpu -and -not $gpu.HasExited) { try { $gpu.Kill() } catch {} }
    $closeSignal.Dispose()
})

Update-Stats
[void]$win.ShowDialog()
