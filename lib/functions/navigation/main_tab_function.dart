abstract final class MainTabFunction {
  static int? indexForPage(String page) => switch (page) {
    'Dashboard' => 0,
    'Borrowed' => 1,
    'Items' => 2,
    'Reports' => 3,
    'More' => 4,
    _ => null,
  };
}
