/// Whether a listing photo entry is a real network URL (existing mock data)
/// versus a local on-device file path (freshly picked when creating a
/// listing — there's no upload backend yet, so the path is stored as-is).
/// Screens that render `Listing.imageUrls` branch on this to pick between
/// `CachedNetworkImage` and `Image.file`.
bool isNetworkImage(String source) => source.startsWith('http://') || source.startsWith('https://');
