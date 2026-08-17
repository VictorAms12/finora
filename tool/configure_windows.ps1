$ErrorActionPreference = 'Stop'

$cmake = 'windows/CMakeLists.txt'
if (Test-Path $cmake) {
  $text = Get-Content $cmake -Raw
  $text = $text.Replace('set(BINARY_NAME "finora")', 'set(BINARY_NAME "Finora")')

  if ($text -notmatch '_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS') {
    $text = $text.Replace(
      'project(finora LANGUAGES CXX)',
      "project(finora LANGUAGES CXX)`r`n`r`n# Compatibilidade com local_auth_windows no MSVC atual.`r`nadd_compile_definitions(_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)"
    )
  }

  Set-Content $cmake $text
}

$runner = 'windows/runner/main.cpp'
if (Test-Path $runner) {
  $text = Get-Content $runner -Raw
  $text = $text.Replace('L"finora"', 'L"Finora"')
  Set-Content $runner $text
}

Write-Host 'Windows configurado para o Finora.'
