$ErrorActionPreference = 'Stop'
$root = Join-Path $PSScriptRoot '..\content'
$root = (Resolve-Path $root).Path

$map = @(
  @{path='items/items.json'; type='items'},
  @{path='recipes/recipes.json'; type='recipes'},
  @{path='species/flora.json'; type='flora'},
  @{path='species/fauna.json'; type='fauna'},
  @{path='species/ecologies.json'; type='ecologies'},
  @{path='world/systems.json'; type='systems'},
  @{path='world/planets.json'; type='planets'},
  @{path='world/settlements.json'; type='settlements'},
  @{path='economy/markets.json'; type='markets'},
  @{path='ships/hulls.json'; type='hulls'},
  @{path='ships/modules.json'; type='ship_modules'},
  @{path='buildings/modules.json'; type='buildings'},
  @{path='tech/multitool_modes.json'; type='multitool_modes'},
  @{path='missions/quests.json'; type='quests'},
  @{path='dialogue/dialogues.json'; type='dialogues'}
)

$files = @()
foreach ($entry in $map) {
  $full = Join-Path $root $entry.path
  $data = Get-Content -Raw -LiteralPath $full | ConvertFrom-Json
  $ids = @()
  foreach ($record in $data.records) { $ids += $record.content_id }
  $files += [ordered]@{ path = $entry.path; type = $entry.type; added_ids = $ids }
}

$loc = @()
Get-ChildItem (Join-Path $root 'localization/en') -Filter *.json |
  Sort-Object Name |
  ForEach-Object {
    $loc += [ordered]@{ locale = 'en'; path = ('localization/en/' + $_.Name) }
  }

$manifest = [ordered]@{
  schema_version = 1
  pack_id = 'btv.core'
  content_version = '0.1.0'
  game_min_version = '0.1.0'
  generator_version = 1
  files = $files
  localization = $loc
}

$target = Join-Path $root 'manifests/base_content.json'
New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
$json = $manifest | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($target, $json + "`n", (New-Object System.Text.UTF8Encoding($false)))
Write-Output "wrote $target"
