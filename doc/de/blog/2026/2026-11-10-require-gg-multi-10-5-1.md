<!--
@license
Copyright (c) ggsuite

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# gg_multi 10.5.1 voraussetzen

## Motivation

- gg bezieht seine Workspace-Befehle aus gg_multi, das seine
  Unterpakete in einer Bibliothek weiter exportiert.
- Zwischen gg_multi_do_publish 4.7.1 (6. November) und der Korrektur
  (10. November) deklarierten zwei dieser Unterpakete jeweils einen Typ
  `ReadSettings`. gg_multi ließ sich dann nicht mehr kompilieren, und mit
  ihm gg:
  `Failed to build gg:gg: … 'ReadSettings' is exported from both …`
- gg 17.7.0 erlaubt `gg_multi: ^10.4.0`, und gg_multi 10.5.0 lässt die
  fehlerhaften Unterpaket-Versionen noch zu. Eine frische Auflösung ist in
  Ordnung, weil sie die neuesten Versionen wählt. Eine Auflösung, die eine
  ältere Lock-Datei behält, ist es nicht.
- gg_multi 10.5.1 lässt nur die korrigierten Unterpakete zu. Wenn gg es
  voraussetzt, kompiliert jede Auflösung von gg.

## Strategie

- Die Einschränkung auf gg_multi auf das Release anheben, das die
  korrigierten Unterpakete festlegt
- Keinen Code ändern
- Prüfen, dass gg die korrigierten Versionen auflöst und seine Prüfungen
  besteht

## Realisierung

- `pubspec.yaml`: aus `gg_multi: ^10.4.0` wird `gg_multi: ^10.5.1`
- Damit löst gg gg_multi_core 4.18.0, gg_multi_do_publish 4.7.2 und
  gg_multi_workspace 4.24.2 auf
- `dart analyze` meldet nichts, und `gg can commit` läuft durch

## Aktualisierte Abhängigkeiten

- gg_multi 10.5.1: setzt gg_multi_core `^4.18.0`, gg_multi_commit
  `^4.9.2`, gg_multi_do_publish `^4.7.2` und gg_multi_workspace
  `^4.24.2` voraus. `ReadSettings` ist einmal deklariert, in
  gg_multi_core
- `gg_one`, `gg_process`, `gg_is_github`, `gg_create_repo` und
  `dna_ggsuite`: vom regulären Abhängigkeits-Upgrade auf ihre aktuellen
  Versionen angehoben

## Ergebnis

- Ein gg, das ab dieser Version installiert wird, kann die
  kollidierenden Unterpakete nicht mehr auflösen
- Veröffentlicht als Patch-Version

## Offene Punkte

- Eine Installation, die die fehlerhaften Versionen schon enthält, behält
  sie: gg baut aus der Lock-Datei neu, mit der es aktiviert wurde.
  `dart pub global activate gg` einmal ausführen, um neu aufzulösen.
