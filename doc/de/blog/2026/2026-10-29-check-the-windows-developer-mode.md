<!--
@license
Copyright (c) ggsuite

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# gg prüft den Windows-Entwicklermodus

## Motivation

- gg legt symbolische Links an, etwa beim Kopieren von Repos in ein Ticket
  oder beim Lokalisieren von Referenzen.
- Unter Windows darf ein normaler Benutzer symbolische Links nur anlegen,
  wenn der Entwicklermodus aktiv ist.
- Ohne ihn brach gg mitten in einem Befehl ab, mit einem Fehler, der nicht
  sagte, was fehlt.
- gg prüft den Entwicklermodus jetzt vorab und sagt, wie man ihn
  einschaltet.

## Strategie

- Einmal prüfen, am Anfang von `runGg`, bevor ein Befehl läuft.
- Die Einstellung aus der Registry lesen, statt einen Link zu testen.
- Bei ausgeschaltetem Modus mit klarem Hinweis und Exit-Code 1 stoppen.
- Ein kaputter Check darf gg nie blockieren: Ist die Registry nicht
  lesbar, warnt gg und macht weiter.
- Den Check überall auslassen, wo er nicht passt.

## Entwicklermodus auslesen

- Neue Datei `lib/src/windows_developer_mode.dart` mit
  `checkWindowsDeveloperMode(args:, ggLog:)`.
- Sie ruft `reg query` auf
  `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock`, Wert
  `AllowDevelopmentWithoutDevLicense`.
- `0x1` heißt aktiv. `0x0` oder ein fehlender Wert (reg endet mit 1) heißt
  aus — ein frisches Windows hat den Wert gar nicht.
- reg läuft über `ggRunProcess`, die Plattform kommt von `ggPlatform`.
  Tests tauschen beide Delegates statt neuer Parameter.

## Der Hinweis

- Ist der Modus aus, schreibt gg in Rot:

  ```
  gg needs the Windows developer mode, it creates symbolic links.
  Enable it: Settings → System → For developers → Developer Mode
  (or run: start ms-settings:developers), then run gg again.
  ```

- Der Befehl ist mit `cCmd` eingefärbt, wie in den anderen gg-Hinweisen.
- Registry nicht lesbar oder unbekannte Ausgabe: gelbe Warnung, gg läuft
  weiter.

## Wann der Check entfällt

- Außerhalb von Windows.
- Unter einem installierten `GgHost`: der Einbetter legt die Links selbst
  an.
- Auf GitHub Actions (`isGitHub`): die Runner laufen mit Adminrechten.
- Bei Aufrufen, die nur die Hilfe wollen: kein Befehl, `help`, `--help`,
  `-h` sowie `--version`.

## Hilfe-Aufrufe an einer Stelle

- Neu: `isUsageOnly(args)` in `project_detector.dart`.
- Auch `checkArgsForProjectMode` nutzt es. `gg do commit --help` zeigt
  außerhalb eines Workspace jetzt die Hilfe, statt einen Workspace zu
  verlangen.

## Weitere Änderungen

- README: der Abschnitt zur Installation nennt den Entwicklermodus.
- Neue `index.jsonc`, die das Repo beschreibt.

## Offene Punkte

- Wer Links auch ohne Entwicklermodus anlegen darf (Admin-Shell,
  Gruppenrichtlinie, andere CI-Systeme als GitHub Actions), wird ebenfalls
  blockiert.
- Jeder gg-Aufruf unter Windows startet einen `reg`-Prozess (etwa
  20-30 ms).
