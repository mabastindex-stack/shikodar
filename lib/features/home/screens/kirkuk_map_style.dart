import 'package:flutter/material.dart';

/// One hue per zone, all inside the same emerald/jade family so distinct
/// zones read as clearly different without introducing a second brand
/// colour anywhere on the map.
const zonePalette = <Color>[
  Color(0xFF0E554A), // emerald
  Color(0xFF3FAE8F), // jade
  Color(0xFF2D7569), // emerald light
  Color(0xFF6C9987), // sage
  Color(0xFF12746A), // teal-forest
  Color(0xFF1F6E5C), // deep forest
  Color(0xFF57917B), // muted mint
];

Color zoneColor(int index) => zonePalette[index % zonePalette.length];

/// Recolours the pale grayscale basemap into Shikodar's own emerald family —
/// a duotone tint that replaces hue & saturation while leaving every tile's
/// original lightness untouched, so roads/parks/water keep exactly the same
/// contrast the cartographer drew; only the colour becomes ours.
///
/// A full colour-matrix tint was tried first but washed the already-pale
/// tiles out to near-white (streets became unreadable against the cream
/// background) — `BlendMode.color` avoids that because it never touches
/// luminance.
const kirkukTileFilter = ColorFilter.mode(Color(0xFF0E554A), BlendMode.color);
